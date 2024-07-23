# display-resolution-manager

A command-line tool to manage and change display resolutions for multiple monitors on macOS. Supports resolutions in the format "1728x1117" and allows skipping specific monitors.

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
## Compilation
c++ -std=c++17 displayresolution.mm -framework ApplicationServices -o displayresolution
chmod +x displayresolution
(Add to $PATH)

## Author
Steven Rabulan - stevenrabulan.com

## License
License
This project is licensed under the MIT License - see the LICENSE file for details.
