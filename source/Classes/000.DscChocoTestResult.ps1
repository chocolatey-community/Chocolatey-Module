using namespace system.collections
using namespace system.collections.generic
class DscChocoTestResult
{
    [bool] $Passed
    [List[string]] $CompliantProperties
    [List[string]] $NonCompliantProperties
}
