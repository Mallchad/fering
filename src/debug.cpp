#include "debug.h"
#include <iostream>

void debug::initialize()
{
    logfile_default_path = std::getenv("HOME");

}
outcome_code debug::log(std::string message, bool verbose)
{
    if (verbose)
    {
        std::cout << message << "\n";
    }

    return outcome::success;
}
