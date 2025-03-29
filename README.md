# PowerLapse!
Powershell script for creating time lapses with your webcam

## The intention is for this to be triggered via Window's Task Scheduler, for example...

![image](https://github.com/user-attachments/assets/e4e6fd13-72df-41d6-85b4-f199369d0c79)

---

### **ACTION:**
```pwsh
<powershell.exe "-File C:\lapse\lapse.ps1">
 ```
(simply takes a capture and files away by time and date)
 
### **TRIGGER:** 

At **6:00AM** every day - After triggered, repeat every 5 minutes for a duration of 12 hours.

---

### **ACTION:**  
```pwsh
<powershell.exe "-File C:\lapse\lapse.ps1" "-vid" "-zip">
```
(Combines all of today's pictures into a timelapse video, and then zips up the images)
 
### **TRIGGER:**  

At **6:30PM** every day

---

### **ACTION:**
```pwsh
<powershell.exe "-File C:\lapse\lapse.ps1" "-superlapse" "-amen">
```
(Combines all daily timelapses into one superlapse, and adds an amen break sample as background audio)
 
### **TRIGGER:**

At **6:30AM** every Saturday of every week

---

## PARAMETERS:
```pwsh
-ffmpeg  [string]    - ffmpeg binary location
-s       [string]    - Location of the working directory for script, defaults to the directory the script is located
-sample  [string]    - Location of the Amen Break audio file to add to the background of the video, defaults to <(Source)/res/amen.wav>
-file    [string]    - Manually define a filename for the image to save to. Must be a .BMP due to how CommandCam works
-cam     [int]       - The index of which camera to tell CommandCam to use
                       defaults to 2 because that works for me,
                       Use CommandCam.exe /devlist to find which camera you want to use
-vid                 - Create a timelapse of all pictures taken today so far
-zip                 - When used with -vid, will zip all images into an archive after the video is created
-superlapse          - Tell the script to create a superlapse of all videos created so far
-amen                - Add amen break to the superlapse
```

---

## Pre-Requisites:

This script makes use of both :

ffmpeg (expected to be in <C:\ffmpeg\bin\ffmpeg.exe>) 

and CommandCam.exe (expected to be in the root of the script) 

it has built in tools for downloading these things, but I would reccomend always making sure you get the latest packages...

---

[CommandCam.exe was created by Ted Burke and is licensed under the GNUv3 public license](https://github.com/tedburke/CommandCam)

[FFMPEG is licensed under the GNU Lesser General Public License v2.1](https://www.ffmpeg.org/)

[This script and its uses are licensed under the Do What The Fuck You Want Public License](https://www.wtfpl.net/)


Never let your light burn out
