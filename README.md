# display-resolution-manager

A command-line tool to manage and change display resolutions for multiple monitors on macOS (working on MacOS Sonoma 14.5 as of now). Gets and sets resolutions in the format "1728x1117" and allows skipping specific monitors in a multi-monitor setup.

## Installation
1. Compilation (requires xcode command line tools):
```
c++ -std=c++17 displayresolution.mm -framework ApplicationServices -o displayresolution
```
2. Set permissions:
```
chmod +x displayresolution
```
3. (Add to $PATH)

## Features & Usage

```sh
# Show current display dimensions
displayresolution

# List all available resolutions for each display
displayresolution list

# Change resolutions for multiple displays
displayresolution 1728x1080 1920x1080 1920x1080

# Change only the second monitor's resolution
displayresolution skip 1920x1080 skip
```

## Author
Steven Rabulan - [stevenrabulan.com](https://stevenrabulan.com)

## License
License
This project is licensed under the MIT License - see the LICENSE file for details.

## References
Inspired by [screenresolution](https://github.com/jhford/screenresolution) by jhford
