# Biddy
# Forenote
This software relies on the neat `cxxopts` program written by jarro2783.
cxxopts is a header only file that provides clean and intuitive command 
line argument creation and parser.
See below if you want to see more for yourself.
https://github.com/jarro2783/cxxopts

# Synopsis
Biddy does your bidding.
It is a general-purpose project which aims to aid users with managing their system, system maintenance can be hard to achieve well on its own, doing it without tools is even worse.
This project aims to help alleviate this by providing simple yet effective tools to track 
files, directories, and in the future operate on such tracked items

The scope of the project is fairly unbound and will do anything it needs to in order 
to achieve sane system and file management.
For this reason it cannot be considered a "does one thing well" program and will be 
somewhat monolithic by design and by nature.
The project already aims to provide optional integration with other projects to 
achieve the goal of the project, and splitting it up into multiple, focused projects 
would detract from both the goal of the project (being a general-purpose project and 
reducing work of system maintenance, rather than fragmenting the work).

Some of the plans or ideas for this project include:
- Crude user level supporting package management
- Recording the written files of specific applications so they can be operated on
  (even if the user manually intervenes, armed with knowledge)
- Sorting, copying, compressing, converting files as they are written
- Keeping track of important files and backing them up separately
  so the system can be modified or destroyed in the know that important things like 
  configuration files and personal documents and work is safe
- Setting up events like cron jobs to help perform regular actions

Currently the only support feature is recording items worth of note in a `record` file, 
by default this is located at `$HOME/.local/share/blink/record`

Yes it's a glorified list builder for the commander line. 
For now.

# Building
Requirements
- cmake
- a working C++17 compliant compiler on the path for cmake to find
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

# Requests
Please do make an issue if you have trouble compiling the project easily or if there 
are compatibility problems like too high a c++ version.
It's hard to gauge if the project works ok when the sample size is 1 or 2.
