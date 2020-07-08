$service = Get-Service -Name csagent -ErrorAction SilentlyContinue
$filepath = "C:\Windows\Temp\CsInstall\" ## Custom folder where packages should be downloaded to
$filename = "WindowsSensor.exe"
$fullfilepath = $filepath + $filename
$CID="" ## CID available on https://falcon.crowdstrike.com/hosts/sensor-downloads
$client_id = "" ## Obtain API keys here https://falcon.crowdstrike.com/support/api-clients-and-keys
$client_secret = ""
$GetSensorsURL = "https://api.crowdstrike.com/sensors/combined/installers/v1?filter=platform%3A%22windows%22"
if ($service -eq $null) {
 ## Imports hash validation to comply with PS 2.0
 function Get-Hash{
    param (
    [string]
    $Path
    )

     $HashAlgorithm = New-Object -TypeName System.Security.Cryptography.SHA256CryptoServiceProvider;
     $Hash = [System.BitConverter]::ToString($hashAlgorithm.ComputeHash([System.IO.File]::ReadAllBytes($Path)));
     $Properties = @{'Algorithm' = 'SHA256';
                     'Path' = $Path;
                     'Hash' = $Hash.Replace('-', '');
                     };
     $Ret = New-Object –TypeName PSObject –Prop $Properties
     return $Ret;
}
  ## Imports JSON convertion to comply with PS 2.0
 function ConvertFrom-JsonString {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]
    $Json
  )

  Add-Type -AssemblyName System.Web.Extensions
  $jsSerializer = New-Object Web.Script.Serialization.JavaScriptSerializer
  return $jsSerializer.DeserializeObject($json)
 }
 ## Downloads Falcon Sensor one version below the latest available
 function DownloadFalconSensor {
 $requestUri = "https://api.crowdstrike.com/oauth2/token"
 $requestBody = "client_id=$client_id&client_secret=$client_secret"
 $InvokeWebRequest = New-Object System.Net.WebClient
 $InvokeWebRequest.Headers.add('Content-Type','application/x-www-form-urlencoded')
 $access_tokenjson = $InvokeWebRequest.UploadString($requestUri, $requestBody) | ConvertFrom-JsonString
 $accesstoken = $access_tokenjson.values | Select-Object -First 1
 $webClient = New-Object System.Net.WebClient
 $webClient.Headers.add('accept','application/json')
 $webClient.Headers.add('authorization','bearer ' + $accesstoken)
 $SensorVersionJSON = $webClient.DownloadString($GetSensorsURL) | ConvertFrom-JsonString
 $LatestVersion = $SensorVersionJSON.resources | Select -Skip 1 | Select -First 1
 $LatestVersionSHA256 = $LatestVersion.sha256
 Set-Content -Path "C:\CsInstall\sha256" -Value $LatestVersionSHA256
 $SensorURL = "https://api.crowdstrike.com/sensors/entities/download-installer/v1?id=$LatestVersionSHA256"
 $webClient.DownloadFile($SensorURL,$fullfilepath)
}
##Validates file hash to proceed with install, deletes if corrupted.
 function CheckInstallHash {
 $ExpectedSHA256 = Get-Content C:\CSInstall\sha256
 $DownloadedSHA256 = Get-Hash -Path $fullfilepath
 if ($DownloadedSHA256.Hash -eq $ExpectedSHA256) { 
 Start-Process -FilePath $fullfilepath -ArgumentList "/install /quiet /norestart CID=$CID"
  } else {
 Remove-Item $fullfilepath -Force
 }
 }
 if (Test-Path $fullfilepath) {
 CheckInstallHash
 }
 if (-not (Test-Path $filepath)) {
 New-Item -Path $filepath -ItemType Directory
 }
 if (-not (Test-Path $fullfilepath)) {
 DownloadFalconSensor
 CheckInstallHash
 }
}
