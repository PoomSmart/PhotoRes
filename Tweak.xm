#import "Common.h"
#import "../PSPrefs.x"

BOOL tweakEnabled;
BOOL specificSize;
NSUInteger prWidth;
NSUInteger prHeight;
NSInteger ratioIndex;
CGSize specificRatioSize;

BOOL overrideRes;
NSInteger overrideWidth;
NSInteger overrideHeight;

static void readAspectRatio(NSInteger index){
    switch (index) {
        case 1:
            specificRatioSize = CGSizeMake(4, 3); // 1.33
            break;
        case 2:
            specificRatioSize = CGSizeMake(16, 9); // 1.78
            break;
        case 3:
            specificRatioSize = CGSizeMake(8, 5); // 1.6
            break;
        case 4:
            specificRatioSize = CGSizeMake(7, 3); // 2.33
            break;
        case 5:
            specificRatioSize = CGSizeMake(3, 2); // 1.5 (3.5-inches)
            break;
        case 6:
            specificRatioSize = CGSizeMake(5, 3); // 1.67
            break;
        case 7:
            specificRatioSize = CGSizeMake(5, 4); // 1.25
            break;
        case 8:
            specificRatioSize = CGSizeMake(11, 8); // 1.375
            break;
        case 9:
            specificRatioSize = CGSizeMake(1.618, 1);
            break;
        case 10:
            specificRatioSize = CGSizeMake(1.85, 1);
            break;
        case 11:
            specificRatioSize = CGSizeMake(2.39, 1);
            break;
        case 12:
            specificRatioSize = CGSizeMake(1.775, 1); // 4-inches
            break;
        case 13:
            specificRatioSize = CGSizeMake(1, 1);
            break;
    }
}

HaveCallback(){
    GetPrefs()
    GetBool(tweakEnabled, tweakKey, YES)
    GetBool(specificSize, specificSizeKey, NO)
    GetInt(prWidth, widthKey, 0)
    GetInt(prHeight, heightKey, 0)
    GetInt(ratioIndex, ratioIndexKey, 0)
    readAspectRatio(ratioIndex);
}

%group iOS10

%hook AVCapturePhotoOutput

- (FigCaptureIrisStillImageSettings *)_figCaptureIrisStillImageSettingsForAVCapturePhotoSettings: (FigCaptureStillImageSettings *)s delegate: (id)delegate connections: (NSArray *)connections
{
    BOOL square = [[self _sanitizedSettingsForSettings:s] isSquareCropEnabled];
    if (!square) {
        AVCaptureDeviceFormat *format = [(AVCaptureConnection *) connections[0] sourceDevice].activeFormat;
        CMVideoDimensions res = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        NSUInteger width = res.width;
        NSUInteger height = res.height;
        CGRect boundingOriginalRect = CGRectMake(0, 0, width, height);
        CGRect myRes = specificSize ? CGRectMake(0, 0, prWidth, prHeight) : boundingOriginalRect;
        if (ratioIndex != 0)
            myRes = AVMakeRectWithAspectRatioInsideRect(specificRatioSize, myRes);
        if (specificSize || ratioIndex != 0) {
            overrideRes = YES;
            overrideWidth = myRes.size.width;
            overrideHeight = myRes.size.height;
            FigCaptureIrisStillImageSettings *settings = %orig;
            overrideRes = NO;
            return settings;
        }
    }
    return %orig;
}

%end

%end

%group iOS9Up

%hook FigCaptureIrisStillImageSettings

- (void)setOutputWidth: (NSInteger)width
{
    %orig(overrideRes ? overrideWidth : width);
}

- (void)setOutputHeight:(NSInteger)height {
    %orig(overrideRes ? overrideHeight : height);
}

%end

%end

%group iOS9

%hook AVCaptureIrisStillImageOutput

- (FigCaptureIrisStillImageSettings *)_figCaptureIrisStillImageSettingsForAVCaptureIrisStillImageSettings: (FigCaptureStillImageSettings *)s connections: (NSArray *)connections
{
    BOOL square = [self _sanitizedSettingsForSettings:s].squareCropEnabled;
    if (!square) {
        AVCaptureDeviceFormat *format = [(AVCaptureConnection *) connections[0] sourceDevice].activeFormat;
        CMVideoDimensions res = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        NSUInteger width = res.width;
        NSUInteger height = res.height;
        CGRect boundingOriginalRect = CGRectMake(0, 0, width, height);
        CGRect myRes = specificSize ? CGRectMake(0, 0, prWidth, prHeight) : boundingOriginalRect;
        if (ratioIndex != 0)
            myRes = AVMakeRectWithAspectRatioInsideRect(specificRatioSize, myRes);
        if (specificSize || ratioIndex != 0) {
            overrideRes = YES;
            overrideWidth = myRes.size.width;
            overrideHeight = myRes.size.height;
            FigCaptureIrisStillImageSettings *settings = %orig;
            overrideRes = NO;
            return settings;
        }
    }
    return %orig;
}

%end

%end


%group iOS8

%hook AVCaptureStillImageOutput

- (FigCaptureStillImageSettings *)_figCaptureStillImageSettingsForConnection: (AVCaptureConnection *)connection
{
    BOOL square = self.squareCropEnabled;
    if (!square) {
        AVCaptureDeviceFormat *format = [connection sourceDevice].activeFormat;
        CMVideoDimensions res = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        NSUInteger width = res.width;
        NSUInteger height = res.height;
        CGRect boundingOriginalRect = CGRectMake(0, 0, width, height);
        CGRect myRes = specificSize ? CGRectMake(0, 0, prWidth, prHeight) : boundingOriginalRect;
        if (ratioIndex != 0)
            myRes = AVMakeRectWithAspectRatioInsideRect(specificRatioSize, myRes);
        if (specificSize || ratioIndex != 0) {
            overrideRes = YES;
            overrideWidth = myRes.size.width;
            overrideHeight = myRes.size.height;
            FigCaptureStillImageSettings *settings = %orig;
            overrideRes = NO;
            return settings;
        }
    }
    return %orig;
}

%end

%hook FigCaptureStillImageSettings

- (void)setOutputWidth: (NSInteger)width
{
    %orig(overrideRes ? overrideWidth : width);
}

- (void)setOutputHeight:(NSInteger)height {
    %orig(overrideRes ? overrideHeight : height);
}

%end

%end

BOOL overridePreviewSize;
CGSize prPreviewSize = CGSizeZero;

NSMutableDictionary *hookCaptureOptions(NSMutableDictionary *orig){
    NSString *prefix = orig[@"OverridePrefixes"];
    if ([prefix isEqualToString:@"P:"]) {
        NSUInteger width = [[orig valueForKeyPath:@"LiveSourceOptions.Capture.Width"] integerValue];
        NSUInteger height = [[orig valueForKeyPath:@"LiveSourceOptions.Capture.Height"] integerValue];
        CGRect boundingOriginalRect = CGRectMake(0, 0, width, height);
        CGRect myRes = specificSize ? CGRectMake(0, 0, prWidth, prHeight) : boundingOriginalRect;
        if (ratioIndex != 0)
            myRes = AVMakeRectWithAspectRatioInsideRect(specificRatioSize, myRes);
        if (specificSize || ratioIndex != 0) {
            NSInteger newWidth = myRes.size.width;
            NSInteger newHeight = myRes.size.height;
            [orig setValue:@(newWidth) forKeyPath:@"LiveSourceOptions.Capture.Width"];
            [orig setValue:@(newHeight) forKeyPath:@"LiveSourceOptions.Capture.Height"];
            [orig setValue:@(newWidth) forKeyPath:@"LiveSourceOptions.Sensor.Width"];
            [orig setValue:@(newHeight) forKeyPath:@"LiveSourceOptions.Sensor.Height"];
        }
    }
    return orig;
}

%group iOS78

%hook AVCaptureSession

+ (NSMutableDictionary *)_createCaptureOptionsForPreset: (id)preset audioDevice: (id)audio videoDevice: (id)video errorStatus: (int *)error
{
    return hookCaptureOptions(%orig);
}

%end

%end

%group preiOS8

%hook AVCaptureStillImageOutput

- (void)configureAndInitiateCopyStillImageForRequest: (AVCaptureStillImageRequest *)request
{
    if ([self respondsToSelector:@selector(squareCropEnabled)])
        overrideRes = !self.squareCropEnabled;
    else
        overrideRes = YES;
    if (overrideRes) {
        AVCaptureDevice *captureDevice = [[self firstActiveConnection] sourceDevice];
        AVCaptureDeviceFormat *format = captureDevice.activeFormat;
        CMVideoDimensions res = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        NSUInteger width = res.width;
        NSUInteger height = res.height;
        CGRect boundingOriginalRect = CGRectMake(0, 0, width, height);
        CGRect myRes = specificSize ? CGRectMake(0, 0, prWidth, prHeight) : boundingOriginalRect;
        if (ratioIndex != 0)
            myRes = AVMakeRectWithAspectRatioInsideRect(specificRatioSize, myRes);
        if (specificSize || ratioIndex != 0) {
            CGRect previewRes = CGRectMake(0, 0, self.previewImageSize.width, self.previewImageSize.height);
            CGRect cropPreviewRes = AVMakeRectWithAspectRatioInsideRect(specificRatioSize, previewRes);
            self.previewImageSize = cropPreviewRes.size;
            prPreviewSize = cropPreviewRes.size;
            %orig;
            overrideRes = NO;
            return;
        }
    }
    %orig;
    overrideRes = NO;
}

%end

%end

%group iOS7

%hook PLAssetFormats

+ (CGSize)scaledSizeForSize: (CGSize)size format: (NSInteger)format capLength: (BOOL)capLength
{
    if (overridePreviewSize && !CGSizeEqualToSize(prPreviewSize, CGSizeZero))
        size = prPreviewSize;
    return %orig(size, format, capLength);
}

%end

%end

%group preiOS7

%hook AVCaptureSession

- (NSMutableDictionary *)_createCaptureOptionsForPreset: (id)preset audioDevice: (id)audio videoDevice: (id)video errorStatus: (int *)error
{
    return hookCaptureOptions(%orig);
}

%end

%hook PLAssetFormats

+ (CGSize)sizeForFormat: (NSInteger)format
{
    if (overridePreviewSize && !CGSizeEqualToSize(prPreviewSize, CGSizeZero)) {
        // kill a check from /System/Library/Lockdown/Checkpoint.xml !
        CGSize correctPreviewSize = CGSizeMake(0.5 * prPreviewSize.width, 0.5 * prPreviewSize.height);
        return correctPreviewSize;
    }
    return %orig;
}

%end

%hook PLCameraView

- (void)_preparePreviewWellImage: (UIImage *)image isVideo: (BOOL)isVideo
{
    %log;
    overridePreviewSize = !isVideo;
    %orig;
    overridePreviewSize = NO;
}

%end

%end

%group iOS71

%hook PLCameraController

- (void)_processCapturedPhotoWithDictionary: (id)dictionary error: (id)error HDRUsed: (BOOL)hdr
{
    overridePreviewSize = YES;
    %orig;
    overridePreviewSize = NO;
}

%end

%end

%group preiOS71

%hook PLCameraController

- (void)_processCapturedPhotoWithDictionary: (id)dictionary error: (id)error
{
    overridePreviewSize = YES;
    %orig;
    overridePreviewSize = NO;
}

%end

%end

%ctor
{
    if (IN_SPRINGBOARD && isiOS7Up)
        return;
    HaveObserver()
    callback();
    if (tweakEnabled) {
        if (isiOS8Up) {
            if (isiOS9Up) {
                if (isiOS10Up) {
                    %init(iOS10);
                }
                %init(iOS9Up);
                %init(iOS9);
            } else {
                %init(iOS8);
            }
        } else {
            %init(preiOS8);
            if (isiOS7Up) {
                %init(iOS7);
                if (isiOS71Up) {
                    %init(iOS71);
                } else {
                    %init(preiOS71);
                }
            } else {
                %init(preiOS7);
            }
        }
        if (isiOS78) {
            %init(iOS78);
        }
    }
}
