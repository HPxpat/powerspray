#powerspray

##Invoke-PasswordSpray
Perform a password spraying attack with powershell.

Required Parameters can either a single item, a comma delimited list of items, or an http/https link to a comma delimited list of items.

### Required Parameters:
    -Targets    The remote machines to attempt to log into
    -Users      The usernames to attempt to log in with
    -Passwords  The passwords to attempt to log in with
### Optional Parameters:
    -Split      Login attempts will be equally distributed among each target
    -Delay      A delay between each login attempt
    -Jitter     Increase the range of randomness in the delay
