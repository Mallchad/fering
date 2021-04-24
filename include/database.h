#include <string>
#include <set>
#include <unordered_set>
#include <fstream>
#include <filesystem>
#include "debug.h"
using std::string;
using std::set;
using std::filesystem::path;

enum class tracking_category
{
    user_config,
    global_config,
    system_config,
    sensitive_files,
    tempalte_files,
    creative_files,
    backup_files,
    unsorted_files
};
class database
{
private:
    // Keeps track of any important files or folders the use is interested in
    set<string> important_paths {};
    // Keeps track of any config related directories the user may want to redeploy
    set<string> config_paths {};
    std::fstream persistent_database {};
    string persistent_database_default_path = "nil";
    std::fstream persistent_log {};
    std::unordered_multiset<string> log {};
public:
    database();
    outcome_code track_new_path(filesystem::path new_path, 
                                tracking_category path_category);
};
