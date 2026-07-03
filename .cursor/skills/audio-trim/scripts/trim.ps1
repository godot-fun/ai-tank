#Requires -Version 5.1
<#
.SYNOPSIS
  Batch trim leading and/or trailing silence from audio files using FFmpeg silenceremove.

.PARAMETER Input
  Path to a single audio file or a directory.

.PARAMETER Threshold
  Silence threshold in dB (default: -50).

.PARAMETER TrimStart
  Trim silence at start (default: true).

.PARAMETER TrimEnd
  Trim silence at end (default: true).

.PARAMETER OutputDir
  Output directory. Default: "<input>/trimmed" or "<parent>/trimmed" for single files.

.PARAMETER Recurse
  Process subdirectories when Input is a folder.

.PARAMETER Overwrite
  Replace existing output files.

.PARAMETER DryRun
  List files that would be processed without writing output.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Input,

    [double] $Threshold = -50,
    [bool] $TrimStart = $true,
    [bool] $TrimEnd = $true,
    [string] $OutputDir = "",
    [switch] $Recurse,
    [switch] $Overwrite,
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"
$AudioExtensions = @(".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a", ".wma")

function Test-FFmpeg {
    $cmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Error "FFmpeg not found on PATH. Install: winget install Gyan.FFmpeg"
    }
}

function Get-AudioFiles {
    param([string] $Path, [bool] $Recursive)

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
        if ($AudioExtensions -contains $ext) {
            return @((Resolve-Path -LiteralPath $Path).Path)
        }
        Write-Error "Not a supported audio file: $Path"
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Error "Input path not found: $Path"
    }

    $root = (Resolve-Path -LiteralPath $Path).Path
    $params = @{
        LiteralPath = $root
        File        = $true
        Include     = $AudioExtensions
    }
    if ($Recursive) { $params["Recurse"] = $true }
    return @(Get-ChildItem @params | ForEach-Object { $_.FullName })
}

function Get-SilenceRemoveFilter {
    param(
        [double] $ThresholdDb,
        [bool] $Start,
        [bool] $End
    )

    if (-not $Start -and -not $End) {
        Write-Error "At least one of -TrimStart or -TrimEnd must be enabled."
    }

    $parts = @()
    if ($Start) {
        $parts += "start_periods=1"
        $parts += "start_duration=0"
        $parts += "start_threshold=${ThresholdDb}dB"
    }
    if ($End) {
        $parts += "stop_periods=1"
        $parts += "stop_duration=0"
        $parts += "stop_threshold=${ThresholdDb}dB"
    }
    return "silenceremove=$($parts -join ':')"
}

function Trim-AudioFile {
    param(
        [string] $FilePath,
        [string] $OutPath,
        [string] $Filter
    )

    $outParent = Split-Path -Parent $OutPath
    if ($outParent -and -not (Test-Path -LiteralPath $outParent)) {
        New-Item -ItemType Directory -Path $outParent -Force | Out-Null
    }

    & ffmpeg -hide_banner -nostats -y -i $FilePath -af $Filter $OutPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "FFmpeg trim failed for: $FilePath"
    }
}

Test-FFmpeg

$filter = Get-SilenceRemoveFilter -ThresholdDb $Threshold -Start $TrimStart -End $TrimEnd

$inputResolved = $Input
$files = Get-AudioFiles -Path $inputResolved -Recursive:$Recurse.IsPresent
if ($files.Count -eq 0) {
    Write-Host "No supported audio files found under: $Input"
    exit 0
}

$inputRoot = $Input
if ((Test-Path -LiteralPath $Input -PathType Leaf)) {
    $inputRoot = Split-Path -Parent (Resolve-Path -LiteralPath $Input).Path
    if (-not $inputRoot) { $inputRoot = (Get-Location).Path }
} else {
    $inputRoot = (Resolve-Path -LiteralPath $Input).Path
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $inputRoot "trimmed"
} else {
    $OutputDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
}

$trimSides = @()
if ($TrimStart) { $trimSides += "start" }
if ($TrimEnd) { $trimSides += "end" }

Write-Host "Input:     $Input"
Write-Host "Files:     $($files.Count)"
Write-Host "Threshold: $Threshold dB"
Write-Host "Trim:      $($trimSides -join ', ')"
Write-Host "Filter:    $filter"
Write-Host "Output:    $OutputDir"
if ($DryRun) { Write-Host "Mode:      DRY RUN" }
Write-Host ""

$ok = 0
$skip = 0
$fail = 0

foreach ($file in $files) {
    $relative = if ($file.StartsWith($inputRoot, [StringComparison]::OrdinalIgnoreCase)) {
        $file.Substring($inputRoot.Length).TrimStart("\", "/")
    } else {
        Split-Path -Leaf $file
    }

    $outPath = Join-Path $OutputDir $relative

    if ((Test-Path -LiteralPath $outPath) -and -not $Overwrite -and -not $DryRun) {
        Write-Host "[skip] $relative"
        $skip++
        continue
    }

    if ($DryRun) {
        Write-Host "[plan] $relative -> $outPath"
        $ok++
        continue
    }

    try {
        Write-Host "[run]  $relative"
        Trim-AudioFile -FilePath $file -OutPath $outPath -Filter $filter
        $ok++
    } catch {
        Write-Host "[fail] $relative"
        Write-Host $_.Exception.Message
        $fail++
    }
}

Write-Host ""
Write-Host "Done. processed=$ok skipped=$skip failed=$fail"
if ($fail -gt 0) { exit 1 }
