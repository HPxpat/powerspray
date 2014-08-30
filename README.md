#powerspray

##Invoke-PasswordSpray
Perform a password spraying attack with powershell.

When more than one target is specified, multiple jobs are run in parrallel, and usernames are split among each target.  Assuming the second target isn't abnormally slow, this will result in a performance increase.

### Required Parameters:
    -Targets    The remote machine(s) to attempt to log into    [String]
    -Users      The user(s) to attempt to log in as             [String]
    -Passwords  The password(s) to attempt to log in with       [String]
### Optional Parameters:
    -Delay      A delay between each login attempt              [Double]
    -Jitter     Increase the range of randomness in the delay   [Double]
### Formats for Targets, Users, and Passwords:
    "http://example.com/users" (online lists are comma delimited)
    "https://example.com/users" (online lists are comma delimited)
    "user1,user2,user3,user4"
    "user1"
    "C:\users.txt"

### Performance Tests [10k Users, 1 Password]:
    Powershell For Loop
        1 minute 56 seconds
    Powershell Parallel Jobs [1 Target]
        1 minute 54 seconds
    Powershell Parallel Jobs [2 Targets]
        58 seconds
    Powershell Parallel Jobs [3 Targets]
        41 seconds
