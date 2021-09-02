#!/usr/bin/env lua
-- GPL3 License
-- Copyright (c) 2021 Mallchad
-- This source provides the right to be freely used in any form, so long as modified
-- variations remain available publically, or open request.
-- Modified versions must be marked as such.
-- The source comes with no warranty of any kind.

-- Helper functions

--- Check if a file or directory exists in this path
local function file_exists(file)
   local success, err, code = os.rename(file, file)
   if not success then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return success, err, code
end
--- Check if a directory exists in this path
local function dir_exists(path)
   -- "/" works on both Unix and Windows
   return file_exists(path.."/")
end
--- Recursively remove everything in the directory
local function remove_directories(...)
   -- the "-E" switch provides cross-platform tools provided by CMake
   local doomed_directories = {...}
   local directories_string = ""
   local remove_failiure = 0
   local _
   for _, x_directory in pairs(doomed_directories) do
      directories_string = directories_string.." "..x_directory
      _, _, remove_failiure = os.execute("cmake -E rm -r "..directories_string)
      if remove_failiure == 1 then
         print(x_directory.." : Failed remove directory")
      else
         print(x_directory.." : Removed directory")
      end
   end
end

-- Variables
-- you will like the global variables and you will OWN them.
-- local arg_relative_directory = arg[0].subt4r
local arg_command = arg[0]
local arg_parsed_verb = arg[1]
local arg_parsed_positional = {}
local arg_verb_passed = false
local arg_help_passed = false

--- The keys describe action arguments which can be executed.
-- Each verb has a help string as its value
local arg_verbs =
   {
      build = [[regenerate the build system and compile the project
        The first argument is the a Build Type
        Example: 'run.lua build development']],
        clean = "remove local, non-critical untracked files where possible",
        init  = "setup local-only files that may be desirable",
        run   = "run the an executable from the project",
        help  = "display help string"
   }
--- A
local arg_positionals =
   {
      clean        = "Run the a clean target before building",
      debug        = "Build Type: Type with debugging symbols",
      development  = "Build Type: with no special settings or optimizations",
      testing      = "Build Type: with optimizations but also with development tools",
      release      = "Build Type: a project with optimizations on and no development tools"
   }
-- All used local-only project directories, relative to project root
local dirs =
   {
      build = "build",
      build_binaries = "build/bin",
      build_artifacts = "artifacts",
      build_debug = "build/debug",
   }
local help_string =
   {
      main = [[
usage: run.lua <verb> <args>

This is a helper tool to aid with working with the project.

Verbs:]],
verbs_documentation = "",
build = [[

The types valid for this project are:
debug - Build with debugging symbols
development - Build with no special settings or optimizations
testing - Build with optimizations but also with development tools
release - Build a project with optimizations on and no development tools

      ]],
      clean = [[Builds the project

type 'build.lua clean' to clean the files
before building (currently does nothing) ]]
   }
-- '-B' is build directory
local build_setup_command = "cmake -B build"
local build_binary_command = "cmake --build "..dirs.build
local build_clean_command = "cmake --build "..dirs.build.." --target=clean"
local build_primary_executable_name = "fering"
local build_primary_executable_path = dirs.build_binaries.."/"..build_primary_executable_name
local cmake_variables =
   {
      CMAKE_BUILD_TYPE = nil,
      FERING_BUILD_DIR = dirs.build,
      FERING_BINARY_DIR = dirs.build_binaries,
      FERING_LIBRARY_DIR = dirs.build_libraries,
      FERING_ARTIFACT_DIR = dirs.build_artifacts,
      FERING_DEBUG_DIR = dirs.build_debug,
      FERING_DEBUG = true,
   }
local help_target_alignment_column = 20

-- Operational Functions

-- Do any post-build setup required
local function init()
   -- Create any neccecary directories
   print("[Initializing Project]")
   for _, new_dir in pairs(dirs) do
      if dir_exists("build") == false then
         -- This should
         os.execute("mkdir "..new_dir)
         print("Created directory: "..new_dir)
      end
   end
   -- Generate helpful or neccecary local files
   os.execute("cmake -B "..dirs.build.. " -DCMAKE_EXPORT_COMPILE_COMMANDS")
end
local function clean(clean_method)
   print("[Clean Start]")
   os.execute("cmake -E rm --recursive build")
end
local function build(build_type, clean_build)
   build_type = build_type or "development"
   clean_build = clean_build or false

   local cmake_variables_string = ""
   for x_var_name, x_var_value in pairs(cmake_variables) do
      cmake_variables_string = "-D"..x_var_name.."="..tostring(x_var_value)
   end
   local build_setup_string = build_setup_command.." "..cmake_variables_string
   local build_binary_string = build_binary_command.." --config="..build_type

   print("[Pre-Build]")
   if arg_parsed_positional[1] == "clean" then
      print(help_string.clean)
   elseif clean_build then
      os.execute(build_clean_command)
   end
   print("[Build Start]")
   os.execute(build_setup_string)
   os.execute(build_binary_command)
   print("[Finishing Up]")
   print("[Done]")
end
local function run(build_first)
   build_first = build_first or false
   local executable_string = build_primary_executable_path

   -- Append any extra arguments
   for _, x_arg in ipairs(arg_parsed_positional) do
      executable_string = executable_string.." "..x_arg
   end
   os.execute(executable_string)
   print(executable_string)
end
-- Display the help text
local function help()
   local generated_help_string = help_string.main
   -- Padded to tab stops '\n'
   for k_name, x_help_string in pairs (arg_verbs) do
      local alignment_padding = help_target_alignment_column - #k_name
      local alignment_padding_string = string.rep(" ", alignment_padding)
      generated_help_string =
         generated_help_string.."\n"..
         k_name..alignment_padding_string..
         x_help_string.."\n"
   end
   -- Section break '\f'
   generated_help_string = generated_help_string.."\f"
   for k_name, x_help_string in pairs (arg_positionals) do
      local alignment_padding = help_target_alignment_column - #k_name
      local alignment_padding_string = string.rep(" ", alignment_padding)
      generated_help_string =
         generated_help_string..
         k_name..alignment_padding_string..
         x_help_string.."\n"
   end
   print(generated_help_string)
end
--- Parses the arguments
local function parse_arguments()
   -- Verb Arguments
   if arg_parsed_verb ~= nil then
      arg_verb_passed = true
   end
   if arg_parsed_verb == "--help" or
      arg_parsed_verb == "-h" or
      arg_parsed_verb == "help" then
      arg_help_passed = true
   end

   -- Positional Arguments
   for i_arg = 2, #arg do
      local x_arg = arg[i_arg]
      local hyphen_stripped_arg = ""
      -- NOTE: the hyphen being stripped is implied, but the stripped values are irrelevant
      if #x_arg > 2 then
         hyphen_stripped_arg = string.sub(x_arg, 3)
      end
      if hyphen_stripped_arg == "help" or x_arg == "-h" or x_arg == "help" then
         arg_help_passed = true
      elseif arg_positionals[x_arg] ~= nil then
         arg_parsed_positional[x_arg] = true
      end
      arg_parsed_positional[i_arg-1] = x_arg
   end

end

-- Program Start
local function main()
   parse_arguments()
   -- Determine and run action to run
   if arg_verb_passed == false then
      print("No command supplied, type 'run.lua --help' for commands")
      return 1
   end
   if arg_parsed_verb == "build" then
      if arg_parsed_positional.clean then
         local build_type = arg_parsed_positional[1]
         build(build_type, true)
      else
         local build_type = arg_parsed_positional[1]
         build(build_type)
      end
   elseif arg_parsed_verb == "run" then
      run()
   elseif arg_parsed_verb == "init" then
      init()
   elseif arg_parsed_verb == "clean" then
      print("[Clean File Tree Start]")
      for _, x_directory in pairs(dirs) do
         remove_directories(x_directory)
      end
   elseif arg_help_passed then
      help()
   else
      print("Unrecognized verb argument '"..arg_parsed_verb.."', type --help for commands")
   end

end
main()
