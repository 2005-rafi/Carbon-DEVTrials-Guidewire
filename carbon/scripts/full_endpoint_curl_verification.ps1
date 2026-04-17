param(
  [string]$BaseUrl = 'http://107.22.146.33:80',
  [string]$ReportPath = 'ENDPOINT_CURL_CONTRACT_REPORT.md',
  [string]$SamplePhone = '9988776655',
  [string]$SampleSecret = 'carbon_pass123',
  [string]$SampleOtp = '123456'
)

$ErrorActionPreference = 'Stop'

function Invoke-CurlRequest {
  param(
    [string]$Method,
    [string]$Url,
    [string]$Body,
    [hashtable]$Headers
  )

  $args = @('-sS', '--connect-timeout', '4', '--max-time', '8', '-X', $Method, $Url, '-w', "`n__STATUS__:%{http_code}")

  if ($Headers -ne $null) {
    foreach ($key in $Headers.Keys) {
      $args += @('-H', "${key}: $($Headers[$key])")
    }
  }

  $hasBody = ($null -ne $Body -and $Body.Trim().Length -gt 0)
  if ($hasBody) {
    # In Windows PowerShell 5.1, native argument passing can strip JSON quotes.
    # Stream body via stdin to preserve exact JSON bytes for curl.exe.
    $args += @('--data-binary', '@-')
  }

  $raw = ''
  $exitCode = 0
  try {
    if ($hasBody) {
      $raw = ($Body | & curl.exe @args 2>&1 | Out-String)
    } else {
      $raw = (& curl.exe @args 2>&1 | Out-String)
    }
    $exitCode = $LASTEXITCODE
  } catch {
    $raw = $_.Exception.Message
    $exitCode = 1
  }

  $status = 0
  $responseBody = $raw
  if ($raw -match '__STATUS__:(\d{3})') {
    $status = [int]$Matches[1]
    $responseBody = ($raw -replace "(?s)`r?`n__STATUS__:\d{3}\s*$", '').Trim()
  }

  return [pscustomobject]@{
    StatusCode = $status
    ExitCode   = $exitCode
    Body       = $responseBody
    Raw        = $raw
  }
}

function Try-ParseJson {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) {
    return $null
  }

  try {
    return ($Text | ConvertFrom-Json)
  } catch {
    return $null
  }
}

function Convert-JsonCompact {
  param($Object)
  try {
    return ($Object | ConvertTo-Json -Depth 20)
  } catch {
    return ''
  }
}

function Get-FromTokenResponse {
  param($Json, [string]$Key)
  if ($null -eq $Json) { return '' }

  if ($Json.PSObject.Properties.Name -contains $Key) {
    return [string]$Json.$Key
  }

  if ($Json.PSObject.Properties.Name -contains 'data' -and $null -ne $Json.data) {
    if ($Json.data.PSObject.Properties.Name -contains $Key) {
      return [string]$Json.data.$Key
    }
  }

  return ''
}

function Contains-KeyDeep {
  param($Node, [string]$Key)
  if ($null -eq $Node) { return $false }

  if ($Node -is [System.Collections.IEnumerable] -and -not ($Node -is [string])) {
    foreach ($item in $Node) {
      if (Contains-KeyDeep -Node $item -Key $Key) { return $true }
    }
    return $false
  }

  $props = $Node.PSObject.Properties
  if ($null -eq $props) { return $false }

  foreach ($prop in $props) {
    if ($prop.Name -eq $Key) { return $true }
    if (Contains-KeyDeep -Node $prop.Value -Key $Key) { return $true }
  }

  return $false
}

function Build-CurlDisplay {
  param(
    [string]$Method,
    [string]$Url,
    [hashtable]$Headers,
    [string]$Body
  )

  $parts = @("curl -X $Method `"$Url`"")
  if ($Headers -ne $null) {
    foreach ($key in $Headers.Keys) {
      $value = $Headers[$key]
      if ($key -eq 'Authorization') {
        $value = 'Bearer <redacted>'
      }
      $parts += "-H `"${key}: $value`""
    }
  }
  if ($null -ne $Body -and $Body.Trim().Length -gt 0) {
    $parts += "-d '$Body'"
  }

  return ($parts -join ' ')
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ssK'
$ctx = [ordered]@{
  UserId       = '8031e51b-741a-4d43-8f0a-172183c5d799'
  AccessToken  = ''
  RefreshToken = ''
  ClaimId      = '00000000-0000-0000-0000-000000000001'
  EventId      = 'EVT-2024-001'
  PayoutId     = 'PAYOUT-TEST-001'
}

$results = New-Object System.Collections.Generic.List[object]

# Connectivity pre-check
$healthProbe = Invoke-CurlRequest -Method 'GET' -Url "$BaseUrl/" -Body '' -Headers $null
$connectivityOk = ($healthProbe.StatusCode -ge 200 -and $healthProbe.StatusCode -lt 500)

# Attempt auth bootstrap for bearer-protected endpoints.
$authHeaders = @{ 'Content-Type' = 'application/json' }
$loginBody = '{"login":"' + $SamplePhone + '","secret":"' + $SampleSecret + '"}'
$loginResp = Invoke-CurlRequest -Method 'POST' -Url "$BaseUrl/api/v1/auth/login" -Body $loginBody -Headers $authHeaders
$loginJson = Try-ParseJson -Text $loginResp.Body
$ctx.AccessToken = Get-FromTokenResponse -Json $loginJson -Key 'access_token'
$ctx.RefreshToken = Get-FromTokenResponse -Json $loginJson -Key 'refresh_token'
$loginUser = Get-FromTokenResponse -Json $loginJson -Key 'user_id'
if (-not [string]::IsNullOrWhiteSpace($loginUser)) {
  $ctx.UserId = $loginUser
}

if ([string]::IsNullOrWhiteSpace($ctx.AccessToken)) {
  $otpSendBody = '{"phone_number":"' + $SamplePhone + '"}'
  $null = Invoke-CurlRequest -Method 'POST' -Url "$BaseUrl/api/v1/auth/otp/send" -Body $otpSendBody -Headers $authHeaders
  $otpVerifyBody = '{"phone":"' + $SamplePhone + '","otp":"' + $SampleOtp + '"}'
  $verifyResp = Invoke-CurlRequest -Method 'POST' -Url "$BaseUrl/api/v1/auth/otp/verify" -Body $otpVerifyBody -Headers $authHeaders
  $verifyJson = Try-ParseJson -Text $verifyResp.Body
  $ctx.AccessToken = Get-FromTokenResponse -Json $verifyJson -Key 'access_token'
  $ctx.RefreshToken = Get-FromTokenResponse -Json $verifyJson -Key 'refresh_token'
  $verifyUser = Get-FromTokenResponse -Json $verifyJson -Key 'user_id'
  if (-not [string]::IsNullOrWhiteSpace($verifyUser)) {
    $ctx.UserId = $verifyUser
  }
}

$endpoints = @(
  @{ Key='general.health'; Service='GENERAL'; Name='GET /'; Method='GET'; Path='/'; Auth=$false; Contract='Health check endpoint.'; Body={ param($c) '' }; ExpectedKeys=@('status','message') },

  @{ Key='auth.login'; Service='AUTH'; Name='POST /api/v1/auth/login'; Method='POST'; Path='/api/v1/auth/login'; Auth=$false; Contract='Body: { login, secret }'; Body={ param($c) '{"login":"' + $SamplePhone + '","secret":"' + $SampleSecret + '"}' }; ExpectedKeys=@('access_token','refresh_token','user_id') },
  @{ Key='auth.register'; Service='AUTH'; Name='POST /api/v1/auth/register'; Method='POST'; Path='/api/v1/auth/register'; Auth=$false; Contract='Body: { phone, full_name, email }'; Body={ param($c) '{"phone":"' + $SamplePhone + '","full_name":"Carbon QA User","email":"qa+carbon@example.com"}' }; ExpectedKeys=@('access_token','refresh_token','user_id') },
  @{ Key='auth.logout'; Service='AUTH'; Name='POST /api/v1/auth/logout'; Method='POST'; Path='/api/v1/auth/logout'; Auth=$true; Contract='Logout current session.'; Body={ param($c) '{}' }; ExpectedKeys=@('status','message') },
  @{ Key='auth.otp.send'; Service='AUTH'; Name='POST /api/v1/auth/otp/send'; Method='POST'; Path='/api/v1/auth/otp/send'; Auth=$false; Contract='Body: { phone_number }'; Body={ param($c) '{"phone_number":"' + $SamplePhone + '"}' }; ExpectedKeys=@('status','message') },
  @{ Key='auth.otp.verify'; Service='AUTH'; Name='POST /api/v1/auth/otp/verify'; Method='POST'; Path='/api/v1/auth/otp/verify'; Auth=$false; Contract='Body: { phone, otp }'; Body={ param($c) '{"phone":"' + $SamplePhone + '","otp":"' + $SampleOtp + '"}' }; ExpectedKeys=@('access_token','refresh_token','user_id') },
  @{ Key='auth.refresh'; Service='AUTH'; Name='POST /api/v1/auth/refresh'; Method='POST'; Path='/api/v1/auth/refresh'; Auth=$false; Contract='Body: { refresh_token }'; Body={ param($c) '{"refresh_token":"' + $c.RefreshToken + '"}' }; ExpectedKeys=@('access_token') },
  @{ Key='auth.validate'; Service='AUTH'; Name='GET /api/v1/auth/validate'; Method='GET'; Path='/api/v1/auth/validate?access_token={token}'; Auth=$false; Contract='Query: access_token'; Body={ param($c) '' }; ExpectedKeys=@('user_id','valid') },

  @{ Key='workers.profile'; Service='WORKER'; Name='POST /api/v1/workers/profile'; Method='POST'; Path='/api/v1/workers/profile'; Auth=$true; Contract='Body: { user_id, name, phone, zone }'; Body={ param($c) '{"user_id":"' + $c.UserId + '","name":"Carbon QA User","phone":"' + $SamplePhone + '","zone":"MR-1"}' }; ExpectedKeys=@('status','data') },
  @{ Key='workers.get'; Service='WORKER'; Name='GET /api/v1/workers/{id}'; Method='GET'; Path='/api/v1/workers/{user_id}'; Auth=$true; Contract='Fetch worker profile by user id.'; Body={ param($c) '' }; ExpectedKeys=@('user_id','name','zone') },
  @{ Key='workers.status'; Service='WORKER'; Name='GET /api/v1/workers/status/{id}'; Method='GET'; Path='/api/v1/workers/status/{user_id}'; Auth=$true; Contract='Fetch worker eligibility status.'; Body={ param($c) '' }; ExpectedKeys=@('is_active','eligible_for_claim') },

  @{ Key='risk.evaluate'; Service='RISK'; Name='POST /api/v1/risk/evaluate'; Method='POST'; Path='/api/v1/risk/evaluate'; Auth=$true; Contract='Body: { user_id, location, activity_data }'; Body={ param($c) '{"user_id":"' + $c.UserId + '","location":"12.97,77.59","activity_data":{"avg_speed":45,"hours_active":12}}' }; ExpectedKeys=@('status','data') },
  @{ Key='risk.drift'; Service='RISK'; Name='GET /api/v1/risk/drift'; Method='GET'; Path='/api/v1/risk/drift'; Auth=$true; Contract='Risk model drift metrics.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='risk.feedback'; Service='RISK'; Name='POST /api/v1/risk/feedback'; Method='POST'; Path='/api/v1/risk/feedback'; Auth=$true; Contract='Ground-truth feedback payload.'; Body={ param($c) '{"user_id":"' + $c.UserId + '","feedback":"ground_truth","outcome":"safe"}' }; ExpectedKeys=@('status') },
  @{ Key='risk.health'; Service='RISK'; Name='GET /api/v1/risk/health'; Method='GET'; Path='/api/v1/risk/health'; Auth=$false; Contract='Risk service health.'; Body={ param($c) '' }; ExpectedKeys=@('status') },

  @{ Key='pricing.calculate'; Service='PRICING'; Name='POST /api/v1/pricing/calculate'; Method='POST'; Path='/api/v1/pricing/calculate'; Auth=$true; Contract='Body: { user_id, weekly_income, risk_zone }'; Body={ param($c) '{"user_id":"' + $c.UserId + '","weekly_income":1500,"risk_zone":"MR-1"}' }; ExpectedKeys=@('premium') },
  @{ Key='pricing.recalculate'; Service='PRICING'; Name='POST /api/v1/pricing/recalculate'; Method='POST'; Path='/api/v1/pricing/recalculate'; Auth=$true; Contract='Recalculate premium context.'; Body={ param($c) '{"user_id":"' + $c.UserId + '","risk_zone":"MR-1"}' }; ExpectedKeys=@('status') },

  @{ Key='policy.create'; Service='POLICY'; Name='POST /api/v1/policy/create'; Method='POST'; Path='/api/v1/policy/create'; Auth=$true; Contract='Body: { user_id, premium, plan }'; Body={ param($c) '{"user_id":"' + $c.UserId + '","premium":250,"plan":"Carbon Gold"}' }; ExpectedKeys=@('status','data') },
  @{ Key='policy.get'; Service='POLICY'; Name='GET /api/v1/policy/{user_id}'; Method='GET'; Path='/api/v1/policy/{user_id}'; Auth=$true; Contract='Fetch policy by user id.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='policy.validate'; Service='POLICY'; Name='POST /api/v1/policy/validate'; Method='POST'; Path='/api/v1/policy/validate'; Auth=$true; Contract='Validate policy for disruption time.'; Body={ param($c) '{"user_id":"' + $c.UserId + '"}' }; ExpectedKeys=@('status') },
  @{ Key='policy.cancel'; Service='POLICY'; Name='POST /api/v1/policy/cancel/{user_id}'; Method='POST'; Path='/api/v1/policy/cancel/{user_id}'; Auth=$true; Contract='Cancel policy by user id.'; Body={ param($c) '{}' }; ExpectedKeys=@('status') },

  @{ Key='trigger.mock'; Service='TRIGGER'; Name='POST /api/v1/trigger/mock'; Method='POST'; Path='/api/v1/trigger/mock'; Auth=$true; Contract='Body: { event_type, duration }'; Body={ param($c) '{"event_type":"RAIN","duration":"4h (Heavy Disruption)"}' }; ExpectedKeys=@('status','data') },
  @{ Key='trigger.weather'; Service='TRIGGER'; Name='POST /api/v1/trigger/weather'; Method='POST'; Path='/api/v1/trigger/weather'; Auth=$true; Contract='Body: { event_type, zone, intensity, location }'; Body={ param($c) '{"event_type":"RAIN","zone":"MR-1","intensity":18,"location":"12.97,77.59"}' }; ExpectedKeys=@('status') },
  @{ Key='trigger.active'; Service='TRIGGER'; Name='GET /api/v1/trigger/active'; Method='GET'; Path='/api/v1/trigger/active'; Auth=$true; Contract='List active disruptions.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='trigger.stop'; Service='TRIGGER'; Name='POST /api/v1/trigger/stop'; Method='POST'; Path='/api/v1/trigger/stop'; Auth=$true; Contract='Stop disruption event.'; Body={ param($c) '{"event_id":"' + $c.EventId + '"}' }; ExpectedKeys=@('status') },

  @{ Key='claims.auto'; Service='CLAIMS'; Name='POST /api/v1/claims/auto'; Method='POST'; Path='/api/v1/claims/auto'; Auth=$true; Contract='Body: { event_id }'; Body={ param($c) '{"event_id":"' + $c.EventId + '"}' }; ExpectedKeys=@('status') },
  @{ Key='claims.get'; Service='CLAIMS'; Name='GET /api/v1/claims/{user_id}'; Method='GET'; Path='/api/v1/claims/{user_id}'; Auth=$true; Contract='List user claims.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='claims.history'; Service='CLAIMS'; Name='GET /api/v1/claims/history/{user_id}'; Method='GET'; Path='/api/v1/claims/history/{user_id}'; Auth=$true; Contract='Claim history summary.'; Body={ param($c) '' }; ExpectedKeys=@('status') },

  @{ Key='fraud.check'; Service='FRAUD'; Name='POST /api/v1/fraud/check'; Method='POST'; Path='/api/v1/fraud/check'; Auth=$true; Contract='Body: { claim_id }'; Body={ param($c) '{"claim_id":"' + $c.ClaimId + '"}' }; ExpectedKeys=@('fraud_score','decision') },
  @{ Key='fraud.score'; Service='FRAUD'; Name='GET /api/v1/fraud/score/{user_id}'; Method='GET'; Path='/api/v1/fraud/score/{user_id}'; Auth=$true; Contract='User fraud score profile.'; Body={ param($c) '' }; ExpectedKeys=@('status') },

  @{ Key='payout.get'; Service='PAYOUT'; Name='GET /api/v1/payout/{user_id}'; Method='GET'; Path='/api/v1/payout/{user_id}'; Auth=$true; Contract='List user payouts.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='payout.process'; Service='PAYOUT'; Name='POST /api/v1/payout/process'; Method='POST'; Path='/api/v1/payout/process'; Auth=$true; Contract='Body: { claim_id }'; Body={ param($c) '{"claim_id":"' + $c.ClaimId + '"}' }; ExpectedKeys=@('status') },
  @{ Key='payout.retry'; Service='PAYOUT'; Name='POST /api/v1/payout/retry'; Method='POST'; Path='/api/v1/payout/retry'; Auth=$true; Contract='Retry payout.'; Body={ param($c) '{"payout_id":"' + $c.PayoutId + '"}' }; ExpectedKeys=@('status') },

  @{ Key='ledger.get'; Service='LEDGER'; Name='GET /api/v1/ledger/{user_id}'; Method='GET'; Path='/api/v1/ledger/{user_id}'; Auth=$true; Contract='User ledger entries.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='ledger.entry'; Service='LEDGER'; Name='POST /api/v1/ledger/entry'; Method='POST'; Path='/api/v1/ledger/entry'; Auth=$true; Contract='Body: { transaction_data }'; Body={ param($c) '{"transaction_data":{"type":"CONTRIBUTION","amount":50000,"source":"Government Grant"}}' }; ExpectedKeys=@('status') },
  @{ Key='ledger.audit'; Service='LEDGER'; Name='GET /api/v1/ledger/audit'; Method='GET'; Path='/api/v1/ledger/audit'; Auth=$true; Contract='Global ledger audit.'; Body={ param($c) '' }; ExpectedKeys=@('status') },

  @{ Key='notify.get'; Service='NOTIFY'; Name='GET /api/v1/notify/{user_id}'; Method='GET'; Path='/api/v1/notify/{user_id}'; Auth=$true; Contract='Notification history.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='notify.send'; Service='NOTIFY'; Name='POST /api/v1/notify/send'; Method='POST'; Path='/api/v1/notify/send'; Auth=$true; Contract='Body: { user_id, message }'; Body={ param($c) '{"user_id":"' + $c.UserId + '","message":"Heavy Rain detected in MR-1. Coverage is now ACTIVE."}' }; ExpectedKeys=@('status') },
  @{ Key='notify.retry'; Service='NOTIFY'; Name='POST /api/v1/notify/retry'; Method='POST'; Path='/api/v1/notify/retry'; Auth=$true; Contract='Body: { notification_id }'; Body={ param($c) '{"notification_id":"notif_001"}' }; ExpectedKeys=@('status') },

  @{ Key='analytics.dashboard'; Service='ANALYTICS'; Name='GET /api/v1/analytics/dashboard'; Method='GET'; Path='/api/v1/analytics/dashboard'; Auth=$true; Contract='Dashboard KPIs.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='analytics.timeseries'; Service='ANALYTICS'; Name='GET /api/v1/analytics/timeseries'; Method='GET'; Path='/api/v1/analytics/timeseries'; Auth=$true; Contract='Timeseries trends.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='analytics.zones'; Service='ANALYTICS'; Name='GET /api/v1/analytics/zones'; Method='GET'; Path='/api/v1/analytics/zones'; Auth=$true; Contract='Zone heatmap metrics.'; Body={ param($c) '' }; ExpectedKeys=@('status') },

  @{ Key='pool.status'; Service='POOL'; Name='GET /api/v1/pool/status'; Method='GET'; Path='/api/v1/pool/status'; Auth=$true; Contract='Pool status.'; Body={ param($c) '' }; ExpectedKeys=@('status') },
  @{ Key='pool.ledger'; Service='POOL'; Name='GET /api/v1/pool/ledger/{user_id}'; Method='GET'; Path='/api/v1/pool/ledger/{user_id}'; Auth=$true; Contract='Pool-worker ledger ratio.'; Body={ param($c) '' }; ExpectedKeys=@('status') }
)

foreach ($ep in $endpoints) {
  $resolvedPath = $ep.Path.Replace('{user_id}', $ctx.UserId)
  if ($resolvedPath -like '*{token}*') {
    $resolvedPath = $resolvedPath.Replace('{token}', [System.Uri]::EscapeDataString($ctx.AccessToken))
  }

  $url = if ($resolvedPath.StartsWith('/')) { "$BaseUrl$resolvedPath" } else { "$BaseUrl/$resolvedPath" }
  $body = (& $ep.Body $ctx)

  $headers = @{}
  if ($ep.Method -ne 'GET') {
    $headers['Content-Type'] = 'application/json'
  }
  if ($ep.Auth -and -not [string]::IsNullOrWhiteSpace($ctx.AccessToken)) {
    $headers['Authorization'] = "Bearer $($ctx.AccessToken)"
  }

  $resp = Invoke-CurlRequest -Method $ep.Method -Url $url -Body $body -Headers $headers
  $json = Try-ParseJson -Text $resp.Body

  $httpOk = ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300)
  $hasExpected = $true
  foreach ($key in $ep.ExpectedKeys) {
    if (-not (Contains-KeyDeep -Node $json -Key $key)) {
      $hasExpected = $false
      break
    }
  }

  $verdict = if ($resp.ExitCode -ne 0 -and $resp.StatusCode -eq 0) {
    'BLOCKED'
  } elseif ($httpOk -and $hasExpected) {
    'PASS'
  } elseif ($httpOk -and -not $hasExpected) {
    'WARN (shape mismatch)'
  } else {
    'FAIL'
  }

  if ($ep.Key -eq 'claims.get' -and $null -ne $json) {
    $claimIdCandidate = ''
    $containers = @($json, $json.data, $json.items, $json.results, $json.value, $json.claims)
    foreach ($container in $containers) {
      if ($container -is [System.Collections.IEnumerable] -and -not ($container -is [string])) {
        foreach ($item in $container) {
          if ($null -ne $item -and $item.PSObject.Properties.Name -contains 'claim_id') {
            $claimIdCandidate = [string]$item.claim_id
            break
          }
          if ($null -ne $item -and $item.PSObject.Properties.Name -contains 'id') {
            $claimIdCandidate = [string]$item.id
            break
          }
        }
      }
      if (-not [string]::IsNullOrWhiteSpace($claimIdCandidate)) { break }
    }
    if (-not [string]::IsNullOrWhiteSpace($claimIdCandidate)) {
      $ctx.ClaimId = $claimIdCandidate
    }
  }

  if ($ep.Key -eq 'trigger.active' -and $null -ne $json) {
    $eventIdCandidate = ''
    $containers = @($json, $json.data, $json.items, $json.results, $json.value, $json.events)
    foreach ($container in $containers) {
      if ($container -is [System.Collections.IEnumerable] -and -not ($container -is [string])) {
        foreach ($item in $container) {
          if ($null -ne $item -and $item.PSObject.Properties.Name -contains 'event_id') {
            $eventIdCandidate = [string]$item.event_id
            break
          }
          if ($null -ne $item -and $item.PSObject.Properties.Name -contains 'id') {
            $eventIdCandidate = [string]$item.id
            break
          }
        }
      }
      if (-not [string]::IsNullOrWhiteSpace($eventIdCandidate)) { break }
    }
    if (-not [string]::IsNullOrWhiteSpace($eventIdCandidate)) {
      $ctx.EventId = $eventIdCandidate
    }
  }

  if ($ep.Key -eq 'payout.get' -and $null -ne $json) {
    $payoutIdCandidate = ''
    $containers = @($json, $json.data, $json.items, $json.results, $json.value, $json.payouts, $json.transactions)
    foreach ($container in $containers) {
      if ($container -is [System.Collections.IEnumerable] -and -not ($container -is [string])) {
        foreach ($item in $container) {
          if ($null -ne $item -and $item.PSObject.Properties.Name -contains 'payout_id') {
            $payoutIdCandidate = [string]$item.payout_id
            break
          }
          if ($null -ne $item -and $item.PSObject.Properties.Name -contains 'id') {
            $payoutIdCandidate = [string]$item.id
            break
          }
        }
      }
      if (-not [string]::IsNullOrWhiteSpace($payoutIdCandidate)) { break }
    }
    if (-not [string]::IsNullOrWhiteSpace($payoutIdCandidate)) {
      $ctx.PayoutId = $payoutIdCandidate
    }
  }

  $results.Add([pscustomobject]@{
    Key          = $ep.Key
    Service      = $ep.Service
    Endpoint     = $ep.Name
    Method       = $ep.Method
    Path         = $resolvedPath
    Url          = $url
    Contract     = $ep.Contract
    RequiresAuth = [bool]$ep.Auth
    CurlCommand  = Build-CurlDisplay -Method $ep.Method -Url $url -Headers $headers -Body $body
    StatusCode   = $resp.StatusCode
    ExitCode     = $resp.ExitCode
    Verdict      = $verdict
    ResponseBody = $resp.Body
  })
}

$passCount = @($results | Where-Object { $_.Verdict -eq 'PASS' }).Count
$warnCount = @($results | Where-Object { $_.Verdict -like 'WARN*' }).Count
$failCount = @($results | Where-Object { $_.Verdict -eq 'FAIL' }).Count
$blockedCount = @($results | Where-Object { $_.Verdict -eq 'BLOCKED' }).Count

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# Full Endpoint cURL Verification Report')
$null = $sb.AppendLine('')
$null = $sb.AppendLine("Generated: $timestamp")
$null = $sb.AppendLine("Base URL: $BaseUrl")
$null = $sb.AppendLine('')
$null = $sb.AppendLine('## Execution Summary')
$null = $sb.AppendLine('')
$null = $sb.AppendLine("- Connectivity pre-check status: $($healthProbe.StatusCode) (curl exit: $($healthProbe.ExitCode))")
$null = $sb.AppendLine("- Auth token acquired: $([string]::IsNullOrWhiteSpace($ctx.AccessToken) -eq $false)")
$null = $sb.AppendLine("- Total endpoints tested: $($results.Count)")
$null = $sb.AppendLine("- PASS: $passCount")
$null = $sb.AppendLine("- WARN (shape mismatch): $warnCount")
$null = $sb.AppendLine("- FAIL: $failCount")
$null = $sb.AppendLine("- BLOCKED (transport): $blockedCount")
$null = $sb.AppendLine('')

$null = $sb.AppendLine('## Orchestration Chain Health (Contract Flow)')
$null = $sb.AppendLine('')
$orchestrationKeys = @('trigger.mock','trigger.active','claims.auto','fraud.check','payout.process','ledger.entry','notify.send')
foreach ($key in $orchestrationKeys) {
  $item = $results | Where-Object { $_.Key -eq $key } | Select-Object -First 1
  if ($null -ne $item) {
    $null = $sb.AppendLine("- $($item.Endpoint): $($item.Verdict) (status $($item.StatusCode), curl exit $($item.ExitCode))")
  }
}
$null = $sb.AppendLine('')

$null = $sb.AppendLine('## Endpoint Contract Matrix')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| Service | Endpoint | Method | Status | Verdict |')
$null = $sb.AppendLine('|---|---|---|---:|---|')
foreach ($item in $results) {
  $null = $sb.AppendLine("| $($item.Service) | $($item.Endpoint) | $($item.Method) | $($item.StatusCode) | $($item.Verdict) |")
}
$null = $sb.AppendLine('')

foreach ($item in $results) {
  $null = $sb.AppendLine("## $($item.Endpoint)")
  $null = $sb.AppendLine('')
  $null = $sb.AppendLine("- Service: $($item.Service)")
  $null = $sb.AppendLine("- Contract: $($item.Contract)")
  $null = $sb.AppendLine("- Method: $($item.Method)")
  $null = $sb.AppendLine("- Path: $($item.Path)")
  $null = $sb.AppendLine("- Requires auth: $($item.RequiresAuth)")
  $null = $sb.AppendLine("- HTTP status: $($item.StatusCode)")
  $null = $sb.AppendLine("- curl exit code: $($item.ExitCode)")
  $null = $sb.AppendLine("- Verdict: $($item.Verdict)")
  $null = $sb.AppendLine('')
  $null = $sb.AppendLine('### cURL command used')
  $null = $sb.AppendLine('```bash')
  $null = $sb.AppendLine($item.CurlCommand)
  $null = $sb.AppendLine('```')
  $null = $sb.AppendLine('')
  $null = $sb.AppendLine('### Final response')
  $null = $sb.AppendLine('```json')
  if ([string]::IsNullOrWhiteSpace($item.ResponseBody)) {
    $null = $sb.AppendLine('{}')
  } else {
    $null = $sb.AppendLine($item.ResponseBody)
  }
  $null = $sb.AppendLine('```')
  $null = $sb.AppendLine('')
}

$reportContent = $sb.ToString()
Set-Content -Path $ReportPath -Value $reportContent -Encoding UTF8
Write-Output "Report written to $ReportPath"
Write-Output "PASS=$passCount WARN=$warnCount FAIL=$failCount BLOCKED=$blockedCount"
