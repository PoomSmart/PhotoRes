GO_EASY_ON_ME = 1
SDKVERSION = 8.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk
TWEAK_NAME = PhotoRes
PhotoRes_FILES = Tweak.xm
PhotoRes_FRAMEWORKS = AVFoundation CoreGraphics CoreMedia UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = PhotoResSettings
PhotoResSettings_FILES = PhotoResPreferenceController.m
PhotoResSettings_INSTALL_PATH = /Library/PreferenceBundles
PhotoResSettings_PRIVATE_FRAMEWORKS = Preferences
PhotoResSettings_FRAMEWORKS = AVFoundation CoreGraphics Social UIKit

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PhotoRes.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
