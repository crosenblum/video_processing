@echo off
setlocal enabledelayedexpansion
rem video post processing script
rem craig m. rosenblum

rem setup variables
set video_type_list=avi,mkv,mp4,wmv,mpg,vob
set video_path=YOUR_VIDEO_DOWNLOADS_FOLDER
set "ffprobe_found=0"
set "ffmpeg_found=0"

rem setup different folders for filtering video file processing
if not exist %video_path%\BACKUPS\*.* md %video_path%\BACKUPS
if not exist %video_path%\FIXED\*.* md %video_path%\FIXED
if not exist %video_path%\TESTING\*.* md %video_path%\TESTING

rem check if ffprobe is installed
for %%i in (ffprobe.exe) do (
    for %%e in (!PATH!) do (
        if exist "%%~e\%%~i" (
            set "ffprobe_path=%%~e\%%~i"
            set "ffprobe_found=1"
            goto :ffprobe
        )
    )
)

:ffprobe
rem check if ffprobe was found
if %ffprobe_found% neq 1 (

	rem ffprobe not found exit batch file
	echo -[ ffprobe is a required component of this script ]-
	goto :end
	
)

rem check if ffmpeg is installed
for %%i in (ffmpeg.exe) do (
    for %%e in (!PATH!) do (
        if exist "%%~e\%%~i" (
            set "ffmpeg_path=%%~e\%%~i"
            set "ffmpeg_found=1"
            goto :ffmpeg
        )
    )
)

:ffmpeg
rem check if ffmpeg was found
if %ffmpeg_found% neq 1 (

	rem ffmpeg not found exit batch file
	echo -[ ffmpeg is a required component of this script ]-
	goto :end
	
)


rem begin loop of videotypes
FOR %%e IN (!video_type_list!) DO (

	rem loop thru files with this extension
	for %%f in (!video_path!\*.%%e) do (

		rem start processing videos
		echo -[ %%~nxf ]-
		
		rem set source
		set source=%video_path%\%%~nxf
		
		rem set destination
		set dest=%video_path%\BACKUPS\%%~nxf
		
		rem check if destination exists
		if exist "%dest%" (
		
			rem compare source and dest file
			fc "%source%" "%dest%"
			
			rem check error level of fc compare
			if errorlevel 1 (

				rem checking dest file
				echo --[ Copying over backup file ]-
				
				rem copy file because they are different
				copy /y "%source%" "%dest%" >nul 2>&1
				
			)
		
		) else (

			rem checking dest file
			echo --[ Creating new backup file ]-

			rem copy file because it does not exist
			copy /y "%source%" "%dest%" >nul 2>&1
			
		)
		
		rem does this video file contain an english language
		echo --[ Checking Audio Track Languages ]-

		REM Initialize an index counter
		set /a index=0

		REM Run ffprobe to get the language and index of all audio streams
		for /f "tokens=1,2 delims==:" %%l in ('ffprobe -i "%%f" -select_streams a -show_entries stream=index:stream_tags^=language -of csv^=p^=0^:s^=^, -v error 2^>^&1') do (
			if "%%l"=="index" (
				set /a index=%%b
			) else if "%%l"=="language" (
				set "languages[!index!]=%%b"
			)
		)

		REM Check if "eng" (English) is present in the list of languages
		set "english_found=no"
		
		rem loop through found audio track indexes
		for /l %%i in (0,1,%index%) do (
			
			rem check if audio track named eng was found
			if "!languages[%%i]!"=="eng" (
				
				rem english audio track found
				echo ---[ English Audio Track Found ]-
				
				rem set english found as yes
				set "english_found=yes"
				
				rem modify video to make english audio track default
				echo ---[ Make English Audio Track Default ]-
				
				rem create modified video file with english audio track as default
				ffmpeg -i "%%~nxf" -c:v copy -c:a copy -map 0 -map 0:a:%%i "modified.%%e"  >nul 2>&1
				
				rem check if modified video file exists
				if exist "!video_path!\modified.%%e" (
				
					rem show new video file moved to FIXED folder
					echo ---[ Moving video file to FIXED folder ]-
					
					rem copy modified video file as old file name in fixed folder
					move /Y "!video_path!\modified.%%e" "!video_path!\FIXED\%%~nxf" >nul 2>&1
					
					rem check if modified.mp4 exists still
					if exist "!video_path!\modified.%%e" (
					
						rem delete modiefied video file
						del /f "!video_path!\modified.%%e" >nul 2>&1
						
					)
					
					rem check if fixed file exists
					if exist "!video_path!\FIXED\%%~nxf" (
					
						rem delete backup file
						del /f "!video_path!\BACKUPS\%%~nxf" >nul 2>&1

					)

				)
			)
		)
		rem end audio tracks loop

		rem check if english is not found moved to TESTING
		if "!english_found!" neq "yes" (
		
			rem no english audio track found
			echo ---[ No English Audio Track Found ]-

			rem show that this file is moved to testing folder because we can't find english audio tracks
			echo ---[ Moving file to TESTING FOLDER ]-
			
			rem setup variables
			set source="%video_path%\%%~nxf"
			set dest="%video_path%\TESTING\%%~nxf"

			rem move to TESTING FOLDER
			move !source! !dest! >nul 2>&1
			
			rem check if TESTING file exists
			if exist "!video_path!\TESTING\%%~nxf" (
			
				rem delete backup file
				echo ---[ Delete Backup File ]-
				
				rem delete backup file
				del /f "!video_path!\BACKUPS\%%~nxf" >nul 2>&1

			)


	    )

		rem add blank line after each file
		echo.

	)	
	rem end loop
  
	
)
rem end processing loop
:end
