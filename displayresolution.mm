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
    displayresolution up
    displayresolution down
*/

#include <ApplicationServices/ApplicationServices.h>
#include <stdio.h>
#include <string.h>
#include <set>
#include <vector>
#include <sstream>
#include <algorithm>

bool displayresolutionSwitchToMode(CGDirectDisplayID display, CGDisplayModeRef mode);

std::pair<int, int> parseResolution(const std::string& res) {
    std::stringstream ss(res);
    int width, height;
    char x;
    ss >> width >> x >> height;
    return {width, height};
}

std::vector<std::pair<int, int>> getSortedResolutions(CGDirectDisplayID display, CFDictionaryRef options) {
    CFArrayRef allModes = CGDisplayCopyAllDisplayModes(display, options);
    std::vector<std::pair<int, int>> resolutions;

    if (allModes != NULL) {
        for (CFIndex i = 0; i < CFArrayGetCount(allModes); i++) {
            CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
            int width = (int)CGDisplayModeGetWidth(mode);
            int height = (int)CGDisplayModeGetHeight(mode);
            resolutions.push_back({width, height});
        }
        CFRelease(allModes);
        std::sort(resolutions.begin(), resolutions.end());
        resolutions.erase(std::unique(resolutions.begin(), resolutions.end()), resolutions.end());
    }

    return resolutions;
}

std::pair<int, int> getNextResolution(const std::vector<std::pair<int, int>>& resolutions, std::pair<int, int> current, bool up) {
    auto it = std::find(resolutions.begin(), resolutions.end(), current);
    if (it != resolutions.end()) {
        if (up) {
            if (it + 1 != resolutions.end()) return *(it + 1);
        } else {
            if (it != resolutions.begin()) return *(it - 1);
        }
    }
    return current; // Return current if next resolution is not found
}

int main(int argc, const char * argv[]) {
    if (argc == 2 && (strcmp(argv[1], "list") == 0 || strcmp(argv[1], "up") == 0 || strcmp(argv[1], "down") == 0)) {
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

        if (strcmp(argv[1], "list") == 0) {
            for (uint32_t i = 0; i < displayCount; ++i) {
                CFArrayRef allModes = CGDisplayCopyAllDisplayModes(displays[i], options);
                if (allModes == NULL) {
                    fprintf(stderr, "ERROR: Unable to get display modes for display %u.\n", i);
                    CFRelease(options);
                    return -1;
                }

                std::set<std::pair<int, int>> uniqueResolutions;
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

        if (strcmp(argv[1], "up") == 0 || strcmp(argv[1], "down") == 0) {
            bool up = (strcmp(argv[1], "up") == 0);

            CGDirectDisplayID display = displays[0]; // Assuming display 0 for now
            std::vector<std::pair<int, int>> resolutions = getSortedResolutions(display, options);
            CFRelease(options);

            CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(display);
            if (currentMode 
