#import <AVFoundation/AVFoundation.h>
#import "../PS.h"

@interface AVCaptureConnection (Private)
- (AVCaptureDevice *)sourceDevice;
@end

@interface AVCaptureStillImageOutput (Private)
@property BOOL squareCropEnabled;
@property CGSize previewImageSize;
@end

@interface AVCaptureDeviceFormat (Private)
- (CMVideoDimensions)sensorDimensions;
@end

@interface AVCaptureDeviceFormatInternal : NSObject
@end
 
@interface FigCaptureStillImageSettings : NSObject
@property NSUInteger outputWidth;
@property NSUInteger outputHeight;
@property NSUInteger thumbnailWidth;
@property NSUInteger thumbnailHeight;
@property BOOL thumbnailEnabled;
@end

@interface DCIMImageWellUtilities : NSObject
+ (UIImage *)cameraPreviewWellImage;
@end

@interface CAMStillImageCaptureResponse : NSObject
- (UIImage *)thumbnailImage;
@end

@interface CAMImageWell : UIView
- (void)setThumbnailImage:(UIImage *)image animated:(BOOL)animated;
@end

@interface CAMCameraView : UIView
- (CAMImageWell *)_imageWell;
@end

NSString *const tweakKey = @"PREnabled";
NSString *const widthKey = @"PRWidth";
NSString *const heightKey = @"PRHeight";
NSString *const ratioIndexKey = @"PRRatioIndex";
NSString *const specificSizeKey = @"PRSpecificSize";
NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.PhotoRes.plist";
CFStringRef const PreferencesNotification = CFSTR("com.PS.PhotoRes.prefs");