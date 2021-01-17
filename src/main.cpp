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

using namespace std::literals::string_literals;
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
            output.push_back(x_path);
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
 *  @brief  Records a new entry to the database.
 *  @param  open_database  An open database file.
 *  @param  database_new_entry The entry to record to the database.
 */
bool database_add_records(std::fstream& open_database,
                          std::vector<std::string> database_new_entries) noexcept
{
    int successful_entries = 0;
    for (std::string& x_entry : database_new_entries)
    {
        open_database << x_entry << std::endl;
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
        std::cout << "No entries were recorded \n";
    }
    return true;
}
int main(int argc, char** argv) try
{
    std::fstream database;
    std::string blink_primary_database_dir = "";
    std::string blink_primary_database_filename = "record";
    bool blink_archive_database_exists = false;
#if defined(WIN32) || defined(_WIN32) || defined(__WIN32__) || defined(__NT__)
    std::cerr << "This program is not ready for windows yet";
#elif defined(linux)
// generate default directory
    blink_primary_database_dir = std::getenv("HOME");
    if (blink_primary_database_dir.length())
    {
        blink_primary_database_dir += "/.local/share/blink"s;
        bool database_dir_exists = std::filesystem::exists(blink_primary_database_dir);
        if (!database_dir_exists)
        {
            std::filesystem::create_directory(blink_primary_database_dir);
            std::filesystem::create_directory(blink_primary_database_dir +
                                              "/archive");
        }
        database_dir_exists = std::filesystem::exists(blink_primary_database_dir);
        // create file
        if (!std::filesystem::exists(blink_primary_database_dir+"/"+
                                     blink_primary_database_filename))
        {
            database.open(blink_primary_database_dir+"/"+blink_primary_database_filename,
                      std::fstream::out);
            database.flush();
            database.close();
        }
    }

#endif
    database.open(blink_primary_database_dir+"/"+blink_primary_database_filename,
                  std::fstream::ate|std::fstream::out|std::fstream::in);
    if (!database.is_open())
    {
        throw std::runtime_error("could not open database file");
    }
    // argument handling
    cxxopts::Options arguments("Blink(placeholder name)",
                               "A program to help you record files you want to save");
    arguments.add_options()
        ("file", "A list of arguments unspecified by an leading argument, this "
         "assumes a list of files, the command should support globbing",
         cxxopts::value<std::vector<std::string>>())
        ("h,help", "Print this help page")
        ("r,record", "Record an entry in the database with an optional note")
        ("i,ignore",
         "Ignore an entry in the database, essentially removing it permanantly");
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
        database_add_records(database, existing_entries);
    }
    if (options.count("ignore"))
    {
    }
    std::cout.flush();
    database.flush();
    database.close();
    return 0;
}
catch (std::exception& irrecoverable_error)
{
    std::cout << irrecoverable_error.what() << std::endl;
}
