Import-Module AU
Import-Module Wormies-AU-Helpers

$Script:ErrorActionPreference = "Stop"

$releases = 'https://api.github.com/repos/starship/starship/releases/latest'

function global:au_GetLatest {
    $download_json = Invoke-RestMethod $releases
    $version = $download_json.tag_name
    $prelease = $download_json.prerelease
    $notes = $download_json.body

    $url32 = ($download_json.assets | Where-Object name -Like '*x86-*windows*.zip').browser_download_url
    $url64 = ($download_json.assets | Where-Object name -Like '*x86_64-*windows*.zip').browser_download_url
    $urlsum32 = ($download_json.assets | Where-Object name -Like '*x86-*windows*.zip.sha256').browser_download_url
    $urlsum64 = ($download_json.assets | Where-Object name -Like '*x86_64-*windows*.zip.sha256').browser_download_url

    if ($urlsum32) {
        $truesum32 = Invoke-RestMethod $urlsum32
    }

    if ($urlsum64) {
        $truesum64 = Invoke-RestMethod $urlsum64
    }
    
    $table = @{
        Version      = $version
        ReleaseNotes = $notes.Split("`n") | Select-Object -Skip 3
        URL32        = $url32
        URL64        = $url64
        TrueSum32    = $truesum32
        TrueSum64    = $truesum64
        FileType     = 'exe'
    }
    return $table
}

function global:au_BeforeUpdate {
    Get-RemoteFiles -Purge -NoSuffix
}

function global:au_AfterUpdate {
    if (
        $Latest.Checksum32 -eq $Latest.TrueSum32 -and 
        $Latest.Checksum64 -eq $Latest.TrueSum64
    ) {
        Write-Host "Checksum match."
    }

    Update-Metadata -data @{
        releaseNotes = $Latest.ReleaseNotes
    }
}

Update-Package -ChecksumFor none
