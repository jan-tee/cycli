<#
    Calculates a SHA256 HMAC for the given message and secret. Returns a string with the Base64 URL encoded result.
#>
function Get-HMACSHA256 {
    Param(
        [parameter(Mandatory=$true)]
        [String]$message,
        [parameter(Mandatory=$true)]
        [String]$secret
    )
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::UTF8.GetBytes($secret)
    $messageBytes = [Text.Encoding]::UTF8.GetBytes($message)
    $signatureBytes = $hmacsha.ComputeHash($messageBytes)
    ConvertTo-Base64UrlEncoding $signatureBytes
}

<#
    Creates a JWT Token to authenticate to the Cylance console API.

    Can accept additional claims to include in request.
#>
function Get-CyJWTToken {
    Param (
        [parameter(Mandatory=$True)]
        [Hashtable]$claims = @{},
        [parameter(Mandatory=$true)]
        [String]$secret,
        [parameter(Mandatory=$true)]
        [String]$iss,
        [parameter(Mandatory=$true)]
        [String]$APIid,
        [parameter(Mandatory=$true)]
        [String]$tid,
        [parameter(Mandatory=$true)]
        [int]$expirationSeconds
    )

    # calculate token mandatory fields
    $now = [int32](((Get-Date -Date ((Get-Date).ToUniversalTime()) -UFormat %s -Millisecond 0)) -Replace("[,\.]\d*", ""))
    $exp = $now + $expirationSeconds
    $guid = [guid]::newguid()
    $sub = $APIId
    $jti = $guid

    [pscustomobject]$registeredClaims = @{
        sub = $sub
        iss = $iss
        jti = $jti
        exp = $exp
        tid = $tid
        iat = $now
    }
    $payload = $registeredClaims

    # merge additional private claims into payload
    $claims.Keys | ForEach-Object {
        Add-Member -InputObject $payload -Name $_ -Value $claims[$_]
        # $payload.Add($_ , $claims[$_])
    }

    # header specifies algorithm + token typen
    [pscustomobject]$h = @{
        alg = "HS256"
        typ = "JWT"
    }

    # get compact JSON representation of header + payload
    $h_json = $h | ConvertTo-Json -Compress
    $p_json = $payload | ConvertTo-Json -Compress

    $h = ConvertTo-Base64UrlEncoding $h_json
    $p = ConvertTo-Base64UrlEncoding $p_json
    $s = Get-HMACSHA256 -Message "${h}.${p}" -secret $secret

    "${h}.${p}.${s}"
}

function Get-CyClaimsFromJwtToken {
    Param (
        [parameter(Mandatory=$true)]
        [String]$token
    )

    $elems = $token.Split(".")
    $null = ConvertFrom-Base64UrlEncoding($elems[0]) | ConvertFrom-Json
    $o = ConvertFrom-Base64UrlEncoding($elems[1]) | ConvertFrom-Json
    $null = $elems[2]

    $o
}