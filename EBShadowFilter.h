#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface EBShadowFilter : CIFilter
@property(nonatomic) CIImage *inputImage;
@property(nonatomic) CIColor *inputColor;
@property(nonatomic) CIVector *inputOffset;
@property(nonatomic) NSNumber *inputBlurRadius;
@property(nonatomic) NSNumber *inputIntensity;
@property(nonatomic) NSNumber *inputInvertShape;

@property(nonatomic) CIImage *outputImage;
@end