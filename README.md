# Blink
The name is placeholder...
Suggestions are welcome...
# Forenote
This software relies on the neat `cxxopts` program written by jarro2783.
cxxopts is a header only file that provides clean and intuitive command 
line argument creation and parser.
See below if you want to see more for yourself.
https://github.com/jarro2783/cxxopts

# Synopsis
Blink is a project which aims to aid users with managing their system, system maintenance 
can be hard to achieve well on its own, doing it without tools is even worse.
This project aims to help alleviate this by providing simple yet effective tools to track 
files, directories, and in the future operate on such tracked items.

Currently the only support feature is recording items worth of note in a `record` file, 
by default this is located at `$HOME/.local/share/blink/record`

Yes it's a glorified list builder for the commander line. 
For now.

# Building
Requirements
- cmake
- a working C++14 compliant compiler on the path for cmake to find
- a build system on the path like make or ninja
Create a build directory like `build` and change the working directory to the build dir.
Then run cmake whilst specifying the project root directory.

example
`cd /data/repos/blink`
`mkdir build && cd build`
`cmake ..`

The binary should now be found in `./bin` from the build directory named `blink`.

# Usage
Getting help string for the command
`blink -h`

Adding a new record to the database 
`blink -r ~/documents/a_new_document`
Shell Expansion Globbing Support
`blink -r ~/.config/*`
