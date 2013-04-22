#import "EBShadowFilter.h"
#import <EBFoundation/EBFoundation.h>

@implementation EBShadowFilter
static NSString *const kAlphaWithFillKernelSource = @"                                                                            \
    kernel vec4 alphaWithFill(sampler image, __color fillColor)                                                                   \
    {                                                                                                                             \
        return premultiply(vec4(fillColor.r, fillColor.g, fillColor.b, sample(image, samplerCoord(image)).a * fillColor.a));      \
    }";

static NSString *const kInvertAlphaWithFillKernelSource = @"                                                                              \
    kernel vec4 invertAlphaWithFill(sampler image, __color fillColor)                                                                     \
    {                                                                                                                                     \
        return premultiply(vec4(fillColor.r, fillColor.g, fillColor.b, (1.0 - sample(image, samplerCoord(image)).a) * fillColor.a));      \
    }";

static NSString *const kApplyIntensityKernelSource = @"                            \
    kernel vec4 applyIntensity(sampler image, float intensity)                     \
    {                                                                              \
        vec4 imageSample = unpremultiply(sample(image, samplerCoord(image)));      \
        imageSample.a = min(1.0, imageSample.a * intensity);                       \
        return premultiply(imageSample);                                           \
    }";

static CIKernel *gAlphaWithFillKernel = nil;
static CIKernel *gInvertAlphaWithFillKernel = nil;
static CIKernel *gApplyIntensityKernel = nil;

+ (void)initialize
{
    static dispatch_once_t initToken;
    dispatch_once(&initToken,
        ^{
            NSArray *kernels = [CIKernel kernelsWithString: kAlphaWithFillKernelSource];
                EBAssertOrRecover(kernels && [kernels count] == 1, return);
            gAlphaWithFillKernel = kernels[0];
            
            kernels = [CIKernel kernelsWithString: kInvertAlphaWithFillKernelSource];
                EBAssertOrRecover(kernels && [kernels count] == 1, return);
            gInvertAlphaWithFillKernel = kernels[0];
            
            kernels = [CIKernel kernelsWithString: kApplyIntensityKernelSource];
                EBAssertOrRecover(kernels && [kernels count] == 1, return);
            gApplyIntensityKernel = kernels[0];
        });
}

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
    _inputColor = [CIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1.0];
    _inputOffset = [CIVector vectorWithX: 0 Y: 0];
    _inputBlurRadius = @0;
    _inputIntensity = @1;
    _inputInvertShape = @NO;
    
    return self;
}

- (NSArray *)inputKeys
{
    return @[kCIInputImageKey, kCIInputColorKey, @"inputOffset", @"inputBlurRadius", kCIInputIntensityKey, @"inputInvertShape"];
}

- (NSArray *)outputKeys
{
    return [NSArray arrayWithObject: kCIOutputImageKey];
}

- (CIImage *)outputImage
{
        EBAssertOrBail(_inputImage);
        EBAssertOrBail(_inputColor);
        EBAssertOrBail(_inputOffset);
        EBAssertOrBail(_inputBlurRadius);
        EBAssertOrBail(_inputIntensity);
        EBAssertOrBail(_inputInvertShape);
    
    BOOL invertShape = [_inputInvertShape boolValue];
    CIImage *shapeImage = [self apply: (!invertShape ? gAlphaWithFillKernel : gInvertAlphaWithFillKernel),
        [CISampler samplerWithImage: _inputImage], _inputColor, nil];
    
    CIFilter *blurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [blurFilter setValue: shapeImage forKey: kCIInputImageKey];
    [blurFilter setValue: _inputBlurRadius forKey: kCIInputRadiusKey];
    
    NSAffineTransform *offsetTransform = [NSAffineTransform transform];
    [offsetTransform translateXBy: [_inputOffset X] yBy: [_inputOffset Y]];
    CIFilter *transformFilter = [CIFilter filterWithName: @"CIAffineTransform"];
    [transformFilter setValue: [blurFilter valueForKey: kCIOutputImageKey] forKey: kCIInputImageKey];
    [transformFilter setValue: offsetTransform forKey: kCIInputTransformKey];
    
    CIImage *shadowImage = [self apply: gApplyIntensityKernel, [CISampler samplerWithImage: [transformFilter valueForKey: kCIOutputImageKey]], _inputIntensity, nil];
    
    CIFilter *compositeFilter = nil;
    if (!invertShape)
    {
        compositeFilter = [CIFilter filterWithName: @"CISourceOverCompositing"];
        [compositeFilter setValue: _inputImage forKey: kCIInputImageKey];
        [compositeFilter setValue: shadowImage forKey: kCIInputBackgroundImageKey];
    }
    
    else
    {
        compositeFilter = [CIFilter filterWithName: @"CISourceAtopCompositing"];
        [compositeFilter setValue: shadowImage forKey: kCIInputImageKey];
        [compositeFilter setValue: _inputImage forKey: kCIInputBackgroundImageKey];
    }
    
    return [compositeFilter valueForKey: kCIOutputImageKey];
}

@end