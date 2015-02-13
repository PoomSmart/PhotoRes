#import "Common.h"

BOOL tweakEnabled;
BOOL specificSize;
NSUInteger prWidth;
NSUInteger prHeight;
int ratioIndex;
CGSize specificRatioSize;

BOOL overrideRes;

static void readAspectRatio(int index)
{
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
			specificRatioSize = CGSizeMake(1.6180, 1);
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

%group iOS8

BOOL noCleanup;

%hook CAMImageWell

- (void)recoverFromFailedThumbnailUpdate
{
	if (noCleanup)
		return;
	%orig;
}

%end

%hook CAMCameraView

- (void)captureController:(id)arg1 didCompleteResponse:(CAMStillImageCaptureResponse *)response forStillImageRequest:(id)arg3 error:(id)arg4
{
	%log;
	noCleanup = [response thumbnailImage] == nil;
	%orig;
	if (noCleanup) {
		UIImage *thumbnail = [[%c(DCIMImageWellUtilities) cameraPreviewWellImage] retain];
		[[self _imageWell] setThumbnailImage:thumbnail animated:YES];
		[thumbnail release];
		noCleanup = NO;
	}
}

%end

%hook AVCaptureStillImageOutput

- (FigCaptureStillImageSettings *)_figCaptureStillImageSettingsForConnection:(AVCaptureConnection *)connection
{
	FigCaptureStillImageSettings *settings = %orig;
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
			settings.outputWidth = myRes.size.width;
			settings.outputHeight = myRes.size.height;
			BOOL thumbnail = settings.thumbnailEnabled;
			if (thumbnail) {
				CGSize previewImageSize = self.previewImageSize;
				CGRect boundingRect = CGRectMake(0, 0, previewImageSize.width, previewImageSize.height);
				CGRect imageFinalRect = AVMakeRectWithAspectRatioInsideRect(myRes.size, boundingRect);
				settings.thumbnailWidth = imageFinalRect.size.width;
				settings.thumbnailHeight = imageFinalRect.size.height;
			}
		}
	}
	return settings;
}

%end

%end

%group preiOS8

%hook AVCaptureStillImageOutput

- (void)configureAndInitiateCopyStillImageForRequest:(id)arg1
{
	if ([self respondsToSelector:@selector(squareCropEnabled)])
		overrideRes = !self.squareCropEnabled;
	else
		overrideRes = YES;
	%orig;
	overrideRes = NO;
}

%end
 
%end

MSHook(CFDictionaryRef, CGSizeCreateDictionaryRepresentation, CGSize photoResolution)
{
	if (overrideRes) {
		CGRect boundingOriginalRect = CGRectMake(0, 0, photoResolution.width, photoResolution.height);
		CGRect myRes = specificSize ? CGRectMake(0, 0, prWidth, prHeight) : boundingOriginalRect;
		if (ratioIndex != 0)
			myRes = AVMakeRectWithAspectRatioInsideRect(specificRatioSize, myRes);
		CGSize newResolution = myRes.size;
		return _CGSizeCreateDictionaryRepresentation(newResolution);
	}
	return _CGSizeCreateDictionaryRepresentation(photoResolution);
}

static void letsprefs()
{
	CFPreferencesAppSynchronize(CFSTR("com.PS.PhotoRes"));
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	tweakEnabled = prefs[tweakKey] ? [prefs[tweakKey] boolValue] : YES;
	specificSize = [prefs[specificSizeKey] boolValue];
	prWidth = prefs[widthKey] ? [prefs[widthKey] intValue] : 0;
	prHeight = prefs[heightKey] ? [prefs[heightKey] intValue] : 0;
	ratioIndex = prefs[ratioIndexKey] ? [prefs[ratioIndexKey] intValue] : 0;
	readAspectRatio(ratioIndex);
}

static void reloadSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	letsprefs();
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	letsprefs();
	if (tweakEnabled) {
		if (!isiOS8Up) {
			MSHookFunction(CGSizeCreateDictionaryRepresentation, MSHake(CGSizeCreateDictionaryRepresentation));
			%init(preiOS8);
		} else {
			%init(iOS8);
		}
	}
	[pool drain];
}
