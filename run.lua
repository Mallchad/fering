#!/usr/bin/env lua
-- GPL3 License
-- Copyright (c) 2021 Mallchad
-- This source provides the right to be freely used in any form, so long as modified
-- variations remain available publically, or open request.
-- Modified versions must be marked as such.
-- The source comes with no warranty of any kind.

-- Helper functions

--- Wrap a string in quotes
-- This is primarily a helper for Windows path compatibility
local function quote(str)
   return ("\""..str.."\"")
end
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
--- Create all directories listed recursively
-- Can accept a table as an argument
local function make_directories(...)
   local new_directories = {...}
   if type(new_directories[1]) == "table" then
      new_directories = new_directories[1]
   end

   local verbose_output = debug_verbose and not debug_silent
   verbose_output = true
   for _, new_dir in pairs(new_directories) do
      if dir_exists(new_dir)then
         print(new_dir.." : directory already exists")
      else
         -- Quote path for Windows compatibility
         os.execute("cmake -E make_directory "..quote(new_dir))
         if verbose_output then
            print(new_dir.." : created directory")
         end
      end

   end
end
--- Recursively remove everything in the directory
local function remove_directories(...)
   -- the "-E" switch provides cross-platform tools provided by CMake
   local doomed_directories = {...}
   local directories_string = ""
   local remove_failiure = 1
   local _
   local quoted_dir = quote("")

   for _, x_directory in pairs(doomed_directories) do
      quoted_dir = quote(x_directory)
      if dir_exists(x_directory) then
         _, _, remove_failiure = os.execute("cmake -E rm -r "..quote(quoted_dir))
         print(quoted_dir)
      end
      if remove_failiure == 1 then
         print(quoted_dir.." : Failed remove directory")
      else
         print(quoted_dir.." : Removed directory")
      end
   end
end
local function copy_file(source, destination)
   os.execute("cmake -E copy "..quote(source).." "..quote(destination))
   print(source, destination)
end
--- Find the last occurance of substring and return the 2 indicies of the position
function string.find_last(str, substr, search_from)
   search_from = search_from or 1
   local match_start, match_end = nil, nil
   local tmp_start, tmp_end = nil, nil
   repeat
      tmp_start, tmp_end = string.find(str, substr, search_from)
      if tmp_end ~= nil then
         search_from = tmp_end+1
         match_start = tmp_start
         match_end = tmp_end
      end
   until tmp_start == nil
   return match_start, match_end
end

-- Variables
-- you will like the global variables and you will OWN them.

local debug_verbose = true
local debug_silent = false

--- current working directory, relative to the helper script
-- This is the only realistic way of getting some kind of inkling of the
-- project root relative working directy without pulling in external
-- dependencies or scripts
local arg_relative_root = arg[0]
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
        configure  = "setup desirable local-only files and build enviornment",
        run   = "run the an executable from the project",
        help  = "display help string"
   }
--- Unordered arguments
-- The key is the argument name, the value is a help string
local arg_positionals =
   {
      clean = "Run the a clean target before building",
   }
--- Unordered arguments that can store a value
-- The key is the argument name, the value is a help string
-- Optionally, the value can be a table, with a list of mutually exclusive,
-- pre-determined values, each with their own help strings
local arg_positional_values =
   {
      build_type =
         {
         debug       = "Build Type: Type with debugging symbols",
         development = "Build Type: with no special settings or optimizations",
         testing     = "Build Type: with optimizations but also with development tools",
         release     = "Build Type: a project with optimizations on and no development tools"
         }
   }
local dirs =
   {
      root = ""
   }
--- All used local-only project directories, relative to project root
-- This is supposed to be temporary directories/files that are ok to delete
local local_dirs =
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
local build_configure_command = "cmake -B build"
local build_binary_command = "cmake --build "..local_dirs.build
local build_clean_command = "cmake --build "..local_dirs.build.." --target clean"
local build_primary_executable_name = "fering"
local build_primary_executable_path = local_dirs.build_binaries.."/"..build_primary_executable_name
local cmake_variables =
   {
      CMAKE_BUILD_TYPE = nil,
      FERING_MINIMUM_CXX_STANDARD = 17,
      FERING_BUILD_DIR = local_dirs.build,
      FERING_BINARY_DIR = local_dirs.build_binaries,
      FERING_LIBRARY_DIR = local_dirs.build_libraries,
      FERING_ARTIFACT_DIR = local_dirs.build_artifacts,
      FERING_DEBUG_DIR = local_dirs.build_debug,
      FERING_ENABLE_DEBUG = true,
      FERING_USE_CCACHE = true,
      FERING_USE_CLANG = true,
      FERING_TEST_VAR = "Hello, I'm an irrational value!"
   }

local help_target_alignment_column = 20

-- Operational Functions

-- Do any post-build setup required
local function configure()
   -- Create any neccecary directories
   print("[Configuring Project]")
   make_directories(local_dirs)

   -- Generate helpful or neccecary local files
   os.execute("cmake -S "..local_dirs.root.." -B "..local_dirs.build.. " -DCMAKE_EXPORT_COMPILE_COMMANDS=1")
   copy_file(local_dirs.build.."/compilation_commands.json", local_dirs.root.."/compile_commands.json")
end
local function clean(clean_method)
   print("[Clean Start]")
   for _, x_directory in pairs(local_dirs) do
      remove_directories(x_directory)
   end
   print("[Clean Done]")
end
local function build(build_type, clean_build)
   build_type = build_type or "development"
   clean_build = clean_build or false

   local cmake_variables_string = ""
   for x_var_name, x_var_value in pairs(cmake_variables) do
      if type(x_var_value) == "string" then
         -- String values should be quoted
         cmake_variables_string = cmake_variables_string..
            "-D"..x_var_name.."="..quote(tostring(x_var_value)).." "
      else
         cmake_variables_string = cmake_variables_string..
            "-D"..x_var_name.."="..tostring(x_var_value).." "
      end
   end
   local build_setup_string = build_configure_command.." "..cmake_variables_string
   local build_binary_string = build_binary_command.." --config="..build_type

   print("[Pre-Build]")
   if clean_build or arg_parsed_positional[1] == "clean" then
      print("Cleaning build area")
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
   local tmp_arg_name = ""

   -- Padded to tab stops '\n'
   for k_name, x_help_string in pairs (arg_verbs) do
      local alignment_padding = help_target_alignment_column - #k_name
      local alignment_padding_string = string.rep(" ", alignment_padding)
      tmp_arg_name = string.gsub(k_name, "_", "-") -- use more CLI friendly hyphen
      generated_help_string =
         generated_help_string.."\n"..
         tmp_arg_name..alignment_padding_string..
         x_help_string.."\n"
   end
   generated_help_string = generated_help_string.."\n"
   for k_name, x_help_string in pairs (arg_positionals) do
      local alignment_padding = help_target_alignment_column - #k_name
      local alignment_padding_string = string.rep(" ", alignment_padding)
      tmp_arg_name = string.gsub(k_name, "_", "-") -- use more
      generated_help_string =
         generated_help_string..
         tmp_arg_name..alignment_padding_string..
         x_help_string.."\n"
   end
   print(generated_help_string)
end
--- Parses the arguments
local function parse_arguments()
   -- Command non-argument '0'
   local _, path_end = string.find_last(arg_relative_root, "/")
   if path_end == nil then
      _, path_end = string.find_last(arg_relative_root, "\\")
   end
   if path_end ~= nil then
      arg_command = string.sub(arg_relative_root, path_end+1)
      -- Strip trailing slash with 'path_end-1'
      arg_relative_root = string.sub(arg_relative_root, 1, path_end-1)
   elseif path_end == nil then
      arg_relative_root = ""
   end
   local_dirs.build = arg_relative_root..local_dirs.build

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
      local stripped_arg = ""

      -- strip leading 2 hyphens then normalize to lua friendly keynames (_)
      if #x_arg > 2 then
         stripped_arg = string.sub(x_arg, 3)
      end
      stripped_arg = string.gsub(stripped_arg, "-", "_") -- use more
      if stripped_arg == "help" or x_arg == "-h" or x_arg == "help" then
         arg_help_passed = true
      elseif arg_positionals[x_arg] ~= nil then
         arg_parsed_positional[x_arg] = true
      end
      arg_parsed_positional[i_arg-1] = x_arg
   end

end

local function regenerate_variables()
   -- Table aliases
   local averb = arg_verbs
   local apos = arg_positionals
   local aval = arg_positional_values
   local dir = dirs
   local ldir = local_dirs
   local hstr = help_string
   local cvar = cmake_variables

   -- Everything set here should assume it might be run multiple times
   -- Additionally, this function not for setting default values, that's just confusing
   -- It should also be assumed that the user might have manually set a variable
   -- through this build tool
   dir.root = arg_relative_root
   ldir.build = dir.root.."/build"
   ldir.build_binaries = ldir.build.."/bin"
   ldir.build_artifacts = ldir.build.."/artifacts"
   ldir.build_libraries = ldir.build.."/lib"
   ldir.build_debug = ldir.build.."/debug"

   build_configure_command =
      "cmake -S "..quote(dir.root).." -B "..quote(ldir.build)
   build_binary_command = "cmake --build "..quote(ldir.build)
   build_clean_command = "cmake --build "..quote(ldir.build).. " --target clean"
   build_primary_executable_name = "fering"
   build_primary_executable_path = ldir.build_binaries.."/"..build_primary_executable_name

   cvar.FERING_BUILD_TYPE = cvar.FERING_BUILD_TYPE
   cvar.FERING_BUILD_DIR = ldir.build
   cvar.FERING_BINARY_DIR = ldir.build_binaries
   cvar.FERING_LIBRARY_DIR = ldir.build_libraries
   cvar.FERING_ARTIFACT_DIR = ldir.build_artifacts
   cvar.FERING_DEBUG_DIR = local_dirs.build_debug
   cvar.FERING_ENABLE_DEBUG = cvar.FERING_ENABLE_DEBUG
   cvar.FERING_ENABLE_DEBUG = cvar.FERING_ENABLE_DEBUG
   cvar.FERING_USE_CCACHE = cvar.FERING_USE_CCACHE
   cvar.FERING_USE_CLANG = cvar.FERING_USE_CLANG
   cvar.FERING_TEST_VAR = cvar.FERING_TEST_VAR

   help_target_alignment_column = 20

end
-- Program Start
local function main()
   parse_arguments()
   regenerate_variables()
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
   elseif arg_parsed_verb == "configure" then
      configure()
   elseif arg_parsed_verb == "clean" then
      clean()
   elseif arg_help_passed then
      help()
   else
      print("Unrecognized verb argument "..quote(arg_parsed_verb)..
            ", type --help for commands")
   end

end
main()
