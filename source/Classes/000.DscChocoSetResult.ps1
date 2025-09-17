using namespace system.collections
using namespace system.collections.generic
class DscChocoSetResult
{
    [ChocolateyBase] $After
    [string[]] $Messages
    [List[string]] $ChangedProperties
}
