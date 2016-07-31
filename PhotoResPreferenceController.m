#import <UIKit/UIKit.h>
#import <Cephei/HBListController.h>
#import <Cephei/HBAppearanceSettings.h>
#import <Social/Social.h>
#import <substrate.h>
#import "Common.h"
#import "../PSPrefs.x"
#import <dlfcn.h>

@interface PhotoResPreferenceController : HBListController
@end

static CGSize resolutionFromAVCaptureDeviceFormat(AVCaptureDeviceFormat *format)
{
	CGSize res = CGSizeZero;
	if (isiOS8Up) {
		CMVideoDimensions dimension8 = format.highResolutionStillImageDimensions;
		res = (CGSize){ dimension8.width, dimension8.height };
	} else if (isiOS7) {
		CMVideoDimensions dimension7 = [format sensorDimensions];
		res = (CGSize){ dimension7.width, dimension7.height };
	} else {
		AVCaptureDeviceFormatInternal *internal6;
		object_getInstanceVariable(format, "_internal", (void **)&internal6);
		NSDictionary *resDict6;
		object_getInstanceVariable(internal6, "formatDictionary", (void **)&resDict6);
		res = (CGSize){ [resDict6[@"Width"] floatValue], [resDict6[@"Height"] floatValue] };
	}
	return res;
}

static CGSize bestPhotoResolution()
{
	NSUInteger pixels = 0;
	NSUInteger index = 0;
	NSArray *formats = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo].formats;
	for (AVCaptureDeviceFormat *format in formats) {
		CGSize dimension = resolutionFromAVCaptureDeviceFormat(format);
		NSUInteger eachPixels = dimension.width * dimension.height;
		if (eachPixels > pixels) {
			eachPixels = pixels;
			index = [formats indexOfObject:format];
		}
	}
	AVCaptureDeviceFormat *bestFormat = formats[index];
	return resolutionFromAVCaptureDeviceFormat(bestFormat);
}

@implementation PhotoResPreferenceController

HavePrefs()

+ (NSString *)hb_specifierPlist
{
	return @"PhotoRes";
}

- (instancetype)init
{
	if (self == [super init]) {
		HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
		appearanceSettings.tintColor = UIColor.magentaColor;
		appearanceSettings.tableViewCellTextColor = UIColor.redColor;
		self.hb_appearanceSettings = appearanceSettings;
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"♥️" style:UIBarButtonItemStylePlain target:self action:@selector(love)] autorelease];
	}
	return self;
}

- (void)love
{
	SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
	twitter.initialText = @"#PhotoRes by @PoomSmart is really awesome!";
	[self.navigationController presentViewController:twitter animated:YES completion:nil];
	[twitter release];
}

- (void)setResValue:(id)value specifier:(PSSpecifier *)spec
{
	NSUInteger val = [value intValue];
	NSString *key = spec.properties[@"key"];
	CGSize bestRes = bestPhotoResolution();
	NSUInteger bestWidth = (NSUInteger)bestRes.width;
	NSUInteger bestHeight = (NSUInteger)bestRes.height;
	if ([key isEqualToString:widthKey]) {
		if (val > bestWidth)
			val = bestWidth;
	}
	else if ([key isEqualToString:heightKey]) {
		if (val > bestHeight)
			val = bestHeight;
	}
	[self setPreferenceValue:@(val) specifier:spec];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self reloadSpecifier:spec animated:NO];
}

HaveBanner2(@"PhotoRes", UIColor.magentaColor, @"Photos at any size", UIColor.redColor)

@end

__attribute__((constructor)) static void ctor()
{
	if (isiOS56)
		dlopen("/Library/Application Support/PhotoRes/Workaround_Cephei_iOS56.dylib", RTLD_LAZY);
}