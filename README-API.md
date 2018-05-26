# Simple API examples

Query for name + offline date of *devices that have been offline for longer than 14 days*:

```powershell
$TwoWeeks = (Get-Date).AddDays(-14)
Get-CyDeviceList | Get-CyDeviceDetail | Where { $_.date_offline -ne $null -and $_.date_offline -lt $twoweeks } | select name, date_offline
```

Query for Windows computers that are *likely to be a member of ANY AD domain* (= where the last logged-on user is not local):

```powershell
PS C:\Users\Jan Tietze\Repos\cylance-cli> Get-CyDeviceList | Get-CyDeviceDetail | Where os_version -like "*Windows*" | Where { $domain = $_.host_name[0..14] -join "" ; $_.last_logged_in_user -notlike "$($domain)\*" -and $_.last_logged_in_user -ne $null }```

Query for Windows computers that are *likely not part of your domain*:

```powershell
Get-CyDeviceList | Get-CyDeviceDetail | Where os_version -like "*Windows*" | Where last_logged_in_user -notlike "YOURDOMAIN\*" 
```

