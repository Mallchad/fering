/*
 * <one line to give the program's name and a brief idea of what it does.>
 * Copyright (C) 2021 mallcahd
 * Contact through GitHub in emergency
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
#include <ctime>
#include <cxxopts.hpp>
#include <stdexcept>
#include <string>
#include <iostream>
#include <filesystem>
#include <exception>
#include <fstream>

#ifdef linux
#include <cstdlib>
// Constants
//the following are UBUNTU/LINUX, and MacOS ONLY terminal color codes.
#define RESET   "\033[0m"
#define BLACK   "\033[30m"      /* Black */
#define RED     "\033[31m"      /* Red */
#define GREEN   "\033[32m"      /* Green */
#define YELLOW  "\033[33m"      /* Yellow */
#define BLUE    "\033[34m"      /* Blue */
#define MAGENTA "\033[35m"      /* Magenta */
#define CYAN    "\033[36m"      /* Cyan */
#define WHITE   "\033[37m"      /* White */
#define BOLDBLACK   "\033[1m\033[30m"      /* Bold Black */
#define BOLDRED     "\033[1m\033[31m"      /* Bold Red */
#define BOLDGREEN   "\033[1m\033[32m"      /* Bold Green */
#define BOLDYELLOW  "\033[1m\033[33m"      /* Bold Yellow */
#define BOLDBLUE    "\033[1m\033[34m"      /* Bold Blue */
#define BOLDMAGENTA "\033[1m\033[35m"      /* Bold Magenta */
#define BOLDCYAN    "\033[1m\033[36m"      /* Bold Cyan */
#define BOLDWHITE   "\033[1m\033[37m"      /* Bold White */
#endif
using namespace std::literals::string_literals;
using std::string;

static bool verbose_output = false;
/**
 * @brief Iterates over file and directory paths and returns a list of files that exists.
 * @param path_arguments The user supplied list of files and direcorties to operate on.
 */
auto detect_file_presence(std::vector<std::string>& path_arguments) noexcept ->
    std::vector<std::string>
{
    std::vector<std::string> output {};
    output.reserve(path_arguments.size());
    int present_files = 0;
    for (std::string& x_path : path_arguments)
    {
        if (std::filesystem::exists(x_path))
        {
            ++present_files;
            output.push_back(std::filesystem::canonical(x_path));
        }
        else if (verbose_output)
        {
            std::cout << "File or directory does not appear to exist in filesystem: "
                      << x_path
                      << "\n";
        }
    }
    int rejected_files = (path_arguments.size()-present_files);
    if (rejected_files)
    {
        std::cout << "Rejected "
                  << rejected_files
                  << " arguments that were not found in the filesystem \n";
    }
    return output;
}
/**
 *  @brief  Records a new entry to the persistent_database.
 *  @param  open_persistent_database  An open persistent_database file.
 *  @param  persistent_database_new_entry The entry to record to the persistent_database.
 */
bool persistent_database_add_records(std::fstream& open_persistent_database,
                          std::vector<std::string> persistent_database_new_entries) noexcept
{
    int successful_entries = 0;
    for (std::string& x_entry : persistent_database_new_entries)
    {
        open_persistent_database << x_entry << std::endl;
        ++successful_entries;
    }
    if (successful_entries)
    {
        std::cout << "Successfully recorded "
                  << successful_entries
                  << " entries \n";
    }
    else
    {
        std::cout << RED "No entries were recorded \n" WHITE;
    }
    return true;
}
int main(int argc, char** argv) try
{
    // Variables
    std::fstream persistent_database;
    std::string blink_primary_persistent_database_dir = "";
    std::string blink_primary_persistent_database_filename = "record";
    bool blink_archive_persistent_database_exists = false;
#if defined(WIN32) || defined(_WIN32) || defined(__WIN32__) || defined(__NT__)
    std::cerr << "This program is not ready for windows yet";
#elif defined(linux)
    // generate default directory
    blink_primary_persistent_database_dir = std::getenv("HOME");
    if (blink_primary_persistent_database_dir.length())
    {
        blink_primary_persistent_database_dir += "/.local/share/blink"s;
        bool persistent_database_dir_exists = std::filesystem::exists(blink_primary_persistent_database_dir);
        if (!persistent_database_dir_exists)
        {
            std::filesystem::create_directory(blink_primary_persistent_database_dir);
            std::filesystem::create_directory(blink_primary_persistent_database_dir +
                                              "/archive");
        }
        persistent_database_dir_exists = std::filesystem::exists(blink_primary_persistent_database_dir);
        // create file
        if (!std::filesystem::exists(blink_primary_persistent_database_dir+"/"+
                                     blink_primary_persistent_database_filename))
        {
            persistent_database.open(blink_primary_persistent_database_dir+"/"+blink_primary_persistent_database_filename,
                      std::fstream::out);
            persistent_database.flush();
            persistent_database.close();
        }
    }

#endif
    persistent_database.open(blink_primary_persistent_database_dir+"/"+blink_primary_persistent_database_filename,
                             std::fstream::ate|std::fstream::out|std::fstream::in);
    if (!persistent_database.is_open())
    {
        throw std::runtime_error("could not open persistent_database file");
    }
    // argument handling
    cxxopts::Options arguments("Blink(placeholder name)",
                               "A program to help you record files you want to save");
    arguments.add_options()
        ("file", "A list of arguments unspecified by an leading argument, this "
         "assumes a list of files, the command should support globbing",
         cxxopts::value<std::vector<std::string>>())
        ("h,help", "Print this help page")
        ("r,record", "Record an entry in the persistent_database with an optional note")
        ("i,ignore",
         "Ignore an entry in the persistent_database, essentially removing it permanantly");
    arguments.parse_positional({"file"});
    auto options = arguments.parse(argc, argv);
    if (options.count("help"))
    {
        std::cout << arguments.help();
    }
    if (options.count("record"))
    {
        std::vector<std::string> options_data_entries =
            options["file"].as<std::vector<std::string>>();
        std::vector<std::string> existing_entries =
            detect_file_presence(options_data_entries);
        persistent_database_add_records(persistent_database, existing_entries);
    }
    if (options.count("ignore"))
    {
    }
    // Cleanup
    std::cout.flush();
    persistent_database.flush();
    persistent_database.close();
    return 0;
}
// Error Handling
catch (std::exception& irrecoverable_error)
{
    std::cout << irrecoverable_error.what() << std::endl;
}
