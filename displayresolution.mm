/*
displayresolution.mm
Author: Steven Rabulan
Website: https://stevenrabulan.com
Inspired by screenresolution by jhford: https://github.com/jhford/screenresolution
COMPILE:
   c++ -std=c++17 displayresolution.mm -framework ApplicationServices -o displayresolution
   chmod +x displayresolution
   (add to $PATH)
USE:
    displayresolution [shows current display dimensions]
  	displayresolution list
	displayresolution 1728x1080 1920x1080 1920x1080
 	 displayresolution skip 1920x1080 skip
*/

#include <ApplicationServices/ApplicationServices.h>
#include <stdio.h>
#include <string.h>
#include <set>
#include <vector>
#include <sstream>

bool displayresolutionSwitchToMode(CGDirectDisplayID display, CGDisplayModeRef mode);

std::pair<int, int> parseResolution(const std::string& res) {
    std::stringstream ss(res);
    int width, height;
    char x;
    ss >> width >> x >> height;
    return {width, height};
}

int main(int argc, const char * argv[]) {
    if (argc == 2 && strcmp(argv[1], "list") == 0) {
        uint32_t displayCount;
        CGGetActiveDisplayList(0, NULL, &displayCount);
        std::vector<CGDirectDisplayID> displays(displayCount);
        CGGetActiveDisplayList(displayCount, displays.data(), &displayCount);

        CFDictionaryRef options = CFDictionaryCreate(
            kCFAllocatorDefault,
            (const void *[]) { kCGDisplayShowDuplicateLowResolutionModes },
            (const void *[]) { kCFBooleanTrue },
            1,
            &kCFTypeDictionaryKeyCallBacks,
            &kCFTypeDictionaryValueCallBacks
        );

        for (uint32_t i = 0; i < displayCount; ++i) {
            CFArrayRef allModes = CGDisplayCopyAllDisplayModes(displays[i], options);
            if (allModes == NULL) {
                fprintf(stderr, "ERROR: Unable to get display modes for display %u.\n", i);
                CFRelease(options);
                return -1;
            }

            std::set<std::pair<int, int> > uniqueResolutions;
            for (CFIndex j = 0; j < CFArrayGetCount(allModes); j++) {
                CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, j);
                int width = (int)CGDisplayModeGetWidth(mode);
                int height = (int)CGDisplayModeGetHeight(mode);
                uniqueResolutions.insert(std::make_pair(width, height));
            }

            printf("Display %u available resolutions:\n", i);
            for (const auto& res : uniqueResolutions) {
                printf("%dx%d\n", res.first, res.second);
            }

            CFRelease(allModes);
        }

        CFRelease(options);
        return 0;
    }

    if (argc == 1) {
        uint32_t displayCount;
        CGGetActiveDisplayList(0, NULL, &displayCount);
        std::vector<CGDirectDisplayID> displays(displayCount);
        CGGetActiveDisplayList(displayCount, displays.data(), &displayCount);

        for (uint32_t i = 0; i < displayCount; ++i) {
            CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(displays[i]);
            if (currentMode != NULL) {
                printf("Display %u current resolution: %zux%zu\n", i, CGDisplayModeGetWidth(currentMode), CGDisplayModeGetHeight(currentMode));
                CGDisplayModeRelease(currentMode);
            } else {
                printf("Unable to get current display mode for display %u\n", i);
            }
        }
        return 0;
    }

    uint32_t displayCount;
    CGGetActiveDisplayList(0, NULL, &displayCount);
    std::vector<CGDirectDisplayID> displays(displayCount);
    CGGetActiveDisplayList(displayCount, displays.data(), &displayCount);

    CFDictionaryRef options = CFDictionaryCreate(
        kCFAllocatorDefault,
        (const void *[]) { kCGDisplayShowDuplicateLowResolutionModes },
        (const void *[]) { kCFBooleanTrue },
        1,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks
    );

    for (int i = 1; i < argc && i - 1 < displayCount; ++i) {
        std::string resolution = argv[i];
        if (resolution == "skip") continue;

        auto [width, height] = parseResolution(resolution);
        if (width <= 0 || height <= 0) {
            fprintf(stderr, "ERROR: Invalid resolution format: %s\n", argv[i]);
            CFRelease(options);
            return -1;
        }

        CFArrayRef allModes = CGDisplayCopyAllDisplayModes(displays[i - 1], options);
        if (allModes == NULL) {
            fprintf(stderr, "ERROR: Unable to get display modes for display %u.\n", i - 1);
            CFRelease(options);
            return -1;
        }

        CGDisplayModeRef switchMode = NULL;
        for (CFIndex j = 0; j < CFArrayGetCount(allModes); j++) {
            CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, j);
            if (CGDisplayModeGetWidth(mode) == width && CGDisplayModeGetHeight(mode) == height) {
                switchMode = mode;
                break;
            }
        }

        if (switchMode == NULL) {
            fprintf(stderr, "ERROR: No suitable mode found for resolution %dx%d on display %u.\n", width, height, i - 1);
            CFRelease(allModes);
            CFRelease(options);
            return 1;
        }

        if (!displayresolutionSwitchToMode(displays[i - 1], switchMode)) {
            fprintf(stderr, "ERROR: Failed to change resolution to %dx%d on display %u.\n", width, height, i - 1);
            CFRelease(allModes);
            CFRelease(options);
            return 1;
        }

        printf("Successfully changed resolution to %dx%d on display %u.\n", width, height, i - 1);
        CFRelease(allModes);
    }

    CFRelease(options);
    return 0;
}

bool displayresolutionSwitchToMode(CGDirectDisplayID display, CGDisplayModeRef mode) {
    CGDisplayConfigRef config;
    if (CGBeginDisplayConfiguration(&config) == kCGErrorSuccess) {
        CGConfigureDisplayWithDisplayMode(config, display, mode, NULL);
        if (CGCompleteDisplayConfiguration(config, kCGConfigureForSession) == kCGErrorSuccess) {
            return true;
        }
    }
    return false;
}
