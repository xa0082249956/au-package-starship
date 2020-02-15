Import-Module AU
Import-Module Wormies-AU-Helpers

$Script:ErrorActionPreference = "Stop"

$releases = 'https://api.github.com/repos/starship/starship/releases/latest'

function global:au_GetLatest {
    $download_json = Invoke-RestMethod $releases
    $version = $download_json.tag_name.Replace('v', '')
    $prelease = $download_json.prerelease
    $notes = $download_json.body

    $table = @{
        Version      = $version
        ReleaseNotes = $notes.Split("`n") | Select-Object -Skip 3
        PreRelease   = $prelease
        FileType     = 'zip'
    }

    $url32 = ($download_json.assets | Where-Object name -Like '*x86-*windows*.zip').browser_download_url
    $url64 = ($download_json.assets | Where-Object name -Like '*x86_64-*windows*.zip').browser_download_url

    if ($url32) {
        $urlsum32 = ($download_json.assets | Where-Object name -Like '*x86-*windows*.zip.sha256').browser_download_url
        $truesum32 = Invoke-RestMethod $urlsum32
        $table.Url32 = $url32
        $table.TrueSum32 = $truesum32
    }
    
    if ($url64) {
        $urlsum64 = ($download_json.assets | Where-Object name -Like '*x86_64-*windows*.zip.sha256').browser_download_url
        $truesum64 = Invoke-RestMethod $urlsum64
        $table.Url64 = $url64
        $table.TrueSum64 = $truesum64
    }
    
    Write-Host "Got latest."
    return $table
}

function global:au_SearchReplace {
    @{ }
}

function global:au_BeforeUpdate {
    Get-RemoteFiles -Purge -NoSuffix
}

function global:au_AfterUpdate {
    Write-Host "Checksum32: "$Latest.Checksum32"."
    Write-Host "Checksum64: "$Latest.Checksum64"."

    if ($Latest.TrueSum32) {
        if ($Latest.Checksum32.Trim() -like $Latest.TrueSum32.Trim()) {
            Write-Host "x86 Checksum match." -ForegroundColor Green
        } else {
            throw 'x86 Checksum mismatch.'
        }
    }

    if ($Latest.TrueSum64) {
        if ($Latest.Checksum64.Trim() -like $Latest.TrueSum64.Trim()) {
            Write-Host "x86_64 Checksum match." -ForegroundColor Green
        } else {
            throw 'x86_64 Checksum mismatch.'
        }
    }

    Update-Metadata -data @{
        releaseNotes = $Latest.ReleaseNotes
    }
}

Update-Package -ChecksumFor none -NoCheckChocoVersion -NoCheckUrl -Force
