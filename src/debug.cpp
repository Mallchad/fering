#include "debug.h"
#include <iostream>

error_code debug::log(std::string message, bool verbose)
{
    if (verbose)
    {
        std::cout << message << "\n";
    }

    return outcome::success;
}
