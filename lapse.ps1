# PowerLapse!
# Create a timelapse of my desk

# The intention is for this to be triggered via Window's Task Scheduler, for example...
#
# action : <powershell.exe "-File C:\lapse\lapse.ps1"> (simply takes a capture and files away by time and date)
# trigger: At 6:00AM every day - After triggered, repeat every 5 minutes for a duration of 12 hours.
#
# action : <powershell.exe "-File C:\lapse\lapse.ps1" "-vid" "-zip"> (Combines all of today's pictures into a timelapse video, and then zips up the images)
# trigger: At 6:3PM every day
#
# action : <powershell.exe "-File C:\lapse\lapse.ps1" "-superlapse" "-amen"> (Combines all daily timelapses into one superlapse, and adds an amen break sample as background audio)
# trigger: At 6:30AM every Saturday of every week

# Robin Universe [D]
# 03 . 27 . 25

param(
    [string]$ffmpeg = "C:\ffmpeg\bin\ffmpeg.exe" ,  # FFMPEG binary location
    [string]$s      = "$PSScriptRoot"            ,  # Base install path
    [string]$sample = "amen.wav"                 ,  # Sample to use for Amen Break
    [string]$file   = "1.bmp"                    ,  # Manually specify file
    [string]$cam    = "2"                        ,  # Defines the default camera index to use
    [switch]$superlapse                          ,  # Combnine all timelapses into one superlapse video
    [switch]$amen                                ,  # Add amen break to the superlapse
    [switch]$zip                                 ,  # Zip up all of today's pictures to save space
    [switch]$vid                                    # Create a timelapse of all of the pictures from todays folder   
)

if ( ! (Test-Path "$ffmpeg"             ) ) { Write-Warning "ffmpeg not found at '$ffmpeg'!"    ;    Install-ffmpeg      }
if ( ! (Test-Path "$s\CommandCam.exe"   ) ) { Write-Warning "CommandCamera.exe not found in $s" ;    Install-CommandCam  } 
if ( ! (Test-Path "$s\res"              ) ) { mkdir "$s\res" -Force | Out-Null                                           }

# Name the files and folders based on the current time and date
$dateTime = ( ( (Get-Date).ToString("yyyy-MM-dd") ), ( (Get-Date).ToString("HH") ), ( (Get-Date).ToString("mm") ) )
$path = ( "$s\res\" + $dateTime[0] + "\" )
if ( !(Test-Path $path) ){ mkdir $path -Force | Out-Null }
if ( $file -eq "1.bmp" ) {
    $index = '{0:d4}' -f (Get-ChildItem -Path $path -Filter '*.png' | Measure-Object).Count
    if([int]$dateTime[1] -gt 12){ # Convert 24H time to 12H time
        $file = $index + "_" + ( [string]([int]$dateTime[1] - 12) + "-" + $dateTime[2] + "-PM.bmp" )
    } else { $file = $index + "_" + ( $dateTime[1] + "-" + $dateTime[2] + "-AM.bmp" ) } }

# Convert an image from a .BMP file to a .PNG file, return the new filename. use -ND to Not Delete the source file.
function Convert-BMP([string]$path, [string]$output=$path.Replace(".bmp",".png"), [switch]$nd){
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $bmp = [System.Drawing.Bitmap]::new($path); $bmp.Save($output, "png" ); $bmp.Dispose(); if(!$nd) { rm $path }
    Return $output
}

# Compile all captures from the current day into a time lapse video
function Update-Timelapse([string]$path, [string]$ext=".bmp"){
    mkdir "$path\lapse" -Force | Out-Null
    ls $path -Filter "*$ext" | Sort-Object Name | ForEach-Object -Begin { $i = 0 } -Process { $newName = ("img{0:D4}$ext" -f $i)
    cp $_.FullName -Destination (Join-Path "$path\lapse" $newName); $i++ }
    try   { & $ffmpeg -framerate 24 -y -i "$path\lapse\img%04d$ext" -c:v libx264 -pix_fmt yuv420p $path\$($dateTime[0]).mp4 > $null 2>&1 }
    catch { Write-Warning "Timelapse video generation failed: $_"; return  }
    rm "$path\lapse" -Recurse -Force # Cleanup 
}

# Combine all timelapse videos created so far into one superlapse
function Update-Superlapse(){
    $sl = "$s\res\superlapse"; mkdir $sl -Force | Out-Null; 
    $names = dir -Path "$s\res\" -Recurse -Filter '*.mp4' | Select-Object -ExpandProperty FullName
    $names
    if ($names.Count -lt 2) { Write-Warning "There are fewer than 2 total videos, so I can't make a superlapse yet..."; return }
    $i=0; foreach ($name in $names) { cp $name "$sl\" -Force; $names[$i] = ("file '$name'"); $i++ }
    $names | Out-File -FilePath "$sl\days.txt" -Encoding ASCII -Force # ffmpeg will spit this out if it's not encoded right
    try   { & $ffmpeg -safe 0 -f concat -i "$sl\days.txt" -c copy "$s\superlapse.mp4" -y > $null 2>&1 }
    catch { Write-Warning "Superlapse update failed: $_"; return  }
    rm "$sl\*" -Force -Recurse # Cleanup
}

# Main

if($vid) { ############## If -vid is invoked (expected to be once at the end of the day), create a timelapse of today 
    Update-Timelapse $path ".png" 
    if ($zip) {  # If -zip is added, zip all images from today into an archive
        Compress-Archive "$path*.png" "$path\$($dateTime[0]).zip" -Force
        rm "$path*.png" 
    } 
}

elseif ($superlapse) { ## if -superlapse is invoked, update the superlapse, expected to be run once at the end of the week
    Update-Superlapse
    if ($amen) { ######## if -amen is invoked, add amen break to the background audio of the superlapse
        if    ( !(Test-Path "$s\res\$sample") ) { Write-Warning "$s\res\$sample does not exist!"; exit }
        try   { & $ffmpeg -i "$s\superlapse.mp4" -i "$s\res\$sample" -map 0:v -map 1:a -c:v copy -shortest "$s\superlapse_amen.mp4" -y > $null 2>&1 }
        catch { Write-Warning "Amen Break Broke: $_ "; return  }
    } 
}

else { ################## If nothing in particular is invoked, just take a new picture to add to the pile - convert it from a BMP to a PNG (since CommandCam can't save .png files), and update latest.png
    try   { Start-Process "$s\CommandCam.exe" "/devnum", $cam, "/filename", "$path$file" -Wait -NoNewWindow | Out-Null }
    catch { Write-Warning "Capture failed: $_"; return  }
    $png = Convert-BMP "$path$file" 
    cp $png $s\latest.png 
}

# CommandCam.exe was created by Ted Burke and is licensed under the GNUv3 public license
# https://github.com/tedburke/CommandCam
#
# FFMPEG is licensed under the GNU Lesser General Public License v2.1
# https://www.ffmpeg.org/
#
# This script and its uses are licensed under the Do What The Fuck You Want Public License
# https://www.wtfpl.net/
#
# Never let your light burn out

# Installs Prereqs if needed...
function Install-ffmpeg{
    $install = $false; $t = 0; while ($t -lt 60) {
        Write-Host "`r [ $t ] I will blow myself up in 1 minute. Press Q to let me try to install ffmpeg for you :) i prommy i wont break anything :3c" -ForegroundColor Yellow -NoNewline; Start-Sleep 1; $t++
        if ([System.Console]::KeyAvailable) {$key = [System.Console]::ReadKey($true); if ($key.KeyChar -eq 'q'){$t=59; $install = $true}}
    } if ($install){
        Write-Host "Downloading ffmpeg..."
        Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile "ffmpeg.zip"
        Expand-Archive -Path "ffmpeg.zip" -DestinationPath "C:\"
        $ffmpegFolder = Get-ChildItem -Path "C:\" -Filter "ffmpeg-*" -Directory
        Rename-Item -Path $ffmpegFolder.FullName -NewName "ffmpeg"
    } else { exit }
}

function Install-CommandCam {
    $install = $false; $t = 0; while ($t -lt 60) {
        Write-Host " `r [ $t ] I will blow myself up in 1 minute. Press Q to let me try to install CommandCamera for you :) i prommy i wont break anything :3c" -ForegroundColor Yellow -NoNewline; Start-Sleep 1; $t++
        if ([System.Console]::KeyAvailable) {$key = [System.Console]::ReadKey($true); if ($key.KeyChar -eq 'q'){$t=59; $install = $true}}
    }
    if ($install){ Invoke-WebRequest -Uri "https://raw.githubusercontent.com/tedburke/CommandCam/refs/heads/master/CommandCam.exe" -OutFile "$s\CommandCam.exe" } else { exit }
}
