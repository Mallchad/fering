#include <cxxopts.hpp>
#include <stdexcept>
#include <string>
#include <iostream>
#include <filesystem>
#include <exception>
#include <fstream>

using namespace std::literals::string_literals;
/**
 *  @brief  Records a new entry to the database.
 *  @param  open_database  An open database file.
 *  @param  database_new_entry The entry to record to the database.
 */
bool database_add_record(std::fstream& open_database, std::string database_new_entry)
{
    open_database << database_new_entry << std::endl;
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
    cxxopts::Options arguments("Blink(placeholder name)", "A program to help you record files you want to save");
    arguments.add_options()
        ("h,help", "Print this help page")
        ("r,record", "Record an entry in the database with an optional note",
         cxxopts::value<std::string>())
        ("i,ignore",
         "Ignore an entry in the database, essentially removing it permanantly",
         cxxopts::value<std::string>());
    auto options = arguments.parse(argc, argv);
    if (options.count("help"))
    {
        std::cout << arguments.help();
    }
    if (options.count("record"))
    {
        std::string new_entry = options["record"].as<std::string>();
        database_add_record(database, new_entry);
    }
    if (options.count("ignore"))
    {
    }
    database.flush();
    database.close();
    return 0;
}
catch (std::exception& irrecoverable_error)
{
    std::cout << irrecoverable_error.what() << std::endl;
}
