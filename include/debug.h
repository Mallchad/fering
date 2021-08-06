#include <cstdint>
#include <string>
#include <vector>
#include <fstream>
typedef std::int32_t outcome_code;
namespace outcome
{
    enum outcome_codes : int32_t
    {
        success = 0,
        nominal_error = 1,
        resolved_error = 2,
        unresolved_error = -1,
    };
}
class debug
{
    static std::string logfile_default_path;
    static std::fstream logfile;
public:
    static outcome_code initialize();
    static outcome_code log(std::string message, bool verbose = true);
};
