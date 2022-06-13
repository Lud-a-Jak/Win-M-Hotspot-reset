#Funkcije Await i AwaitAction
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
Function Await($WinRtTask, $ResultType) 
{
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}
Function AwaitAction($WinRtAction) 
{
    $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and !$_.IsGenericMethod })[0]
    $netTask = $asTask.Invoke($null, @($WinRtAction))
    $netTask.Wait(-1) | Out-Null
}

#Config manager
$connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)

#Hotspot on/off
$onoff = $tetheringManager.TetheringOperationalState
	#Write-Output "onoff"

#default SSID i Password na koje ce vracati
$SSIDdefault = "*"
$PASSWORDdefault = "Chuprija2"

#Trenutni SSID i Password
$tetherConfig = $tetheringManager.GetCurrentAccessPointConfiguration();

$SSID = $tetherConfig.Ssid;
	#Write-Output "SSID: $SSID";
$PASSWORD = $tetherConfig.Passphrase
	#Write-Output "Password: $PASSWORD";

#Provjera SSID I Password vs. default
if (( $SSID -ne $SSIDdefault) -or ($PASSWORD -ne $PASSWORDdefault)) 
{
		#Write-Output "SSID : $SSID    --->              $SSIDdefault" 
		#Write-Output "Pass : $PASSWORD    --->       $PASSWORDdefault"
	#Ako nisu iste vraca na default
	$tetherConfig.Ssid = $SSIDdefault
	$tetherConfig.Passphrase = $PASSWORDdefault
	AwaitAction ($tetheringManager.ConfigureAccessPointAsync($tetherConfig));
}

#Provjera Hotspot on/off
if ( $onoff -ne "on") 
{
	#Ako je OFF --> ON
		#Write-Output "Startam hotspot...";
	Await ($tetheringManager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult]) | Out-Null;
		#Write-Output "upaljen";
}

#Ip adrese
	#$hotspotAdapterId = (Get-NetAdapter | Where-Object -Property DriverDescription -Match "Wi-Fi Direct").InterfaceIndex;
	#$hotspotIPv4 = (Get-NetIPAddress -InterfaceIndex $hotspotAdapterId).IPv4Address;
	#$hotspotIPv6 = (Get-NetIPAddress -InterfaceIndex $hotspotAdapterId).IPv6Address;
	#Write-Output "AP IPv4: $hotspotIPv4";
	#Write-Output "AP IPv6: $hotspotIPv6";
	#Write-Output "";
	#Write-Output "stisni nes.";
	#[Console]::ReadKey();
