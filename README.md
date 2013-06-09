# EBShadowFilter

EBShadowFilter is a CIFilter that composites highly-customizable shadows. EBShadowFilter's various mutable properties include color, offset, and blur radius. EBShadowFilter also supports adding inner-shadows via the 'invertShape' property.

## Requirements

- Mac OS 10.8. (Earlier platforms have not been tested.)
- Automatic reference counting (ARC) must be enabled for the source files.

## Integration

1. Integrate [EBFoundation](https://github.com/davekeck/EBFoundation) into your project.
2. Drag EBShadowFilter.xcodeproj into your project's file hierarchy.
3. In your target's "Build Phases" tab:
    * Add EBShadowFilter as a dependency ("Target Dependencies" section)
    * Link against EBShadowFilter ("Link Binary With Libraries" section)
4. Add `#import <EchoBravo/EBShadowFilter.h>` to your source files.