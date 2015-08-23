#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Social/Social.h>
#import <substrate.h>
#import "Common.h"

__attribute__((visibility("hidden")))
@interface PhotoResPreferenceController : PSListController
@end

static CGSize resolutionFromAVCaptureDeviceFormat(AVCaptureDeviceFormat *format)
{
	CGSize res = CGSizeZero;
	if (isiOS8Up) {
		CMVideoDimensions dimension8 = format.highResolutionStillImageDimensions;
		res = (CGSize){dimension8.width, dimension8.height};
	}
	else if (isiOS7) {
		CMVideoDimensions dimension7 = [format sensorDimensions];
		res = (CGSize){dimension7.width, dimension7.height};
	}
	else if (isiOS6) {
		AVCaptureDeviceFormatInternal *internal6;
		object_getInstanceVariable(format, "_internal", (void **)&internal6);
		NSDictionary *resDict6;
		object_getInstanceVariable(format, "formatDictionary", (void **)&resDict6);
		res = (CGSize){[resDict6[@"Width"] floatValue], [resDict6[@"Height"] floatValue]};
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

- (id)init
{
	if (self == [super init]) {
		UIButton *heart = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
		[heart setImage:[UIImage imageNamed:@"Heart" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/PhotoResSettings.bundle"]] forState:UIControlStateNormal];
		[heart sizeToFit];
		[heart addTarget:self action:@selector(love) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:heart] autorelease];
	}
	return self;
}

- (void)love
{
	SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
	[twitter setInitialText:@"#PhotoRes by @PoomSmart is awesome!"];
	if (twitter != nil)
		[[self navigationController] presentViewController:twitter animated:YES completion:nil];
	[twitter release];
}

- (void)apply:(id)param
{
	[[super view] endEditing:YES];
}

- (void)donate:(id)param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PS_DONATE_URL]];
}

- (void)twitter:(id)param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PS_TWITTER_URL]];
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

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"PhotoRes" target:self]];
		_specifiers = [specs copy];
	}
	return _specifiers;
}

@end
