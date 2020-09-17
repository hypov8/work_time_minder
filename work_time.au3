#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=D:\_code_\icon\star_icon.ico
#AutoIt3Wrapper_Outfile=work_time_minder.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Description=work time minder
#AutoIt3Wrapper_Res_Fileversion=0.0.0.4
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;work time minder
;by david smyth (hypov8)
;use freely


#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
Opt("GUIOnEventMode", 1)
#Region ### START Koda GUI section ### Form=C:\Programs\codeing\autoit-v3\SciTe\Koda\Dave\ki\work_time.kxf
Global $Form2 = GUICreate("Work Time Minder", 327, 272, -1, -1)
Global $Group1 = GUICtrlCreateGroup("Time (H:M)", 4, 8, 225, 153)
Global $Label1 = GUICtrlCreateLabel("00:00", 133, 26, 85, 32)
GUICtrlSetFont($Label1, 24, 400, 0, "MS Sans Serif")
Global $Label2 = GUICtrlCreateLabel("00:00", 133, 94, 85, 32)
GUICtrlSetFont($Label2, 24, 400, 0, "MS Sans Serif")
Global $Label3 = GUICtrlCreateLabel("Day: ", 12, 30, 91, 29)
GUICtrlSetFont($Label3, 18, 400, 0, "MS Sans Serif")
Global $Label4 = GUICtrlCreateLabel("Week: ", 12, 98, 91, 29)
GUICtrlSetFont($Label4, 18, 400, 0, "MS Sans Serif")
Global $Progress1 = GUICtrlCreateProgress(12, 63, 205, 21)
Global $Progress2 = GUICtrlCreateProgress(12, 131, 205, 21)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Global $Group3 = GUICtrlCreateGroup("Log", 4, 168, 317, 97)
Global $List1 = GUICtrlCreateList("", 12, 184, 301, 71, BitOR($GUI_SS_DEFAULT_LIST,$WS_HSCROLL))
GUICtrlCreateGroup("", -99, -99, 1, 1)
Global $Button1 = GUICtrlCreateButton("Info", 240, 16, 73, 33)
GUICtrlSetOnEvent($Button1, "Button1Click")
Global $Button2 = GUICtrlCreateButton("Pause", 240, 88, 77, 33)
GUICtrlSetOnEvent($Button2, "Button2Click")
Global $Button3 = GUICtrlCreateButton("Resume", 240, 128, 77, 33)
GUICtrlSetOnEvent($Button3, "Button3Click")
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###




#Region ;==> global
#include <Timers.au3>
#include <Date.au3>
#include <WinAPISys.au3>
#include <File.au3>
#include <GDIPlus.au3>
Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)

Global $iDailyTimeMin
Global $iWeeklyTimeMin
Global $iMinutes, $iHours, $iWeekDay, $iYearDay, $iDate, $iMonth, $iYear
Global $iProgStartTime = TimerInit()
Global $powerSaverStarted=False
Global $isPaused = False
Global $windowStateMin = False
Global Const $sFileName = @TempDir & "\work_time_state.txt"
Global Const $sFileNameLog = @TempDir & "\work_time_log.txt"

;Global Const $WM_POWERBROADCAST =   0x218
Global Const $PBT_APMRESUMEAUTOMATIC =  0x12
Global Const $PBT_APMQUERYSUSPEND   =   0x0000
Global Const $PBT_APMQUERYSTANDBY   =   0x0001
Global Const $PBT_APMQUERYSUSPENDFAILED =   0x0002
Global Const $PBT_APMQUERYSTANDBYFAILED =   0x0003
Global Const $PBT_APMSUSPEND    =   0x0004
Global Const $PBT_APMSTANDBY    =   0x0005
Global Const $PBT_APMRESUMECRITICAL =   0x0006
Global Const $PBT_APMRESUMESUSPEND  =   0x0007
Global Const $PBT_APMRESUMESTANDBY  =   0x0008
Global Const $PBTF_APMRESUMEFROMFAILURE =   0x00000001
Global Const $PBT_APMBATTERYLOW     =   0x0009
Global Const $PBT_APMPOWERSTATUSCHANGE =    0x000A
Global Const $PBT_APMOEMEVENT   =   0x000B

;used
Global Const $PBT_POWERSETTINGCHANGE = 0x8013
Global Const $tagPOWERBROADCAST_SETTING = "struct; ulong Data1;ushort Data2;ushort Data3;byte Data4[8]; endstruct;DWORD DataLength;DWORD Data;"

Global $isPC_inUse = True
Global $powerID = _WinAPI_RegisterPowerSettingNotification($Form2, $GUID_MONITOR_POWER_ON)

WriteToLog("Program start")
GUICtrlSetData($Progress1, 0)
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSE_UI")
GUIRegisterMsg($WM_POWERBROADCAST, "_Power_Event")
TraySetOnEvent(-8, "TrayWindow_reSize" ) ;$TRAY_EVENT_PRIMARYUP
TraySetOnEvent(-10, "TrayWindow_reSize" ) ;$TRAY_EVENT_SECONDARYUP

Global $aDPI = _GDIPlus_GraphicsGetDPIRatio()
ConsoleWrite("!GIU DPI= "&$aDPI[0] & @CRLF)

GUISetFont(8 * $aDPI[0])
GUICtrlSetFont($Label1, 24*$aDPI[0])
GUICtrlSetFont($Label2, 24*$aDPI[0])
GUICtrlSetFont($Label3, 18*$aDPI[0])
GUICtrlSetFont($Label4, 18*$aDPI[0])

Read_Session_FromTempFile()
#EndRegion ;==> global


Func _Power_Event($hWnd, $Msg, $wParam, $lParam)
	;ConsoleWrite("powerEvent. msg=" &$Msg&" wparam="&$wParam &" lparm="&$lParam&@CRLF)
    Switch $wParam
		Case $PBT_POWERSETTINGCHANGE
			ConsoleWrite("wMsg_0" &@CRLF)
			Local $tSetting = DllStructCreate($tagPOWERBROADCAST_SETTING, $lParam)
			Local $iSetting = DllStructGetData($tSetting, "Data")

			Switch $iSetting
				Case 2 ;The display is dimmed --> Win8 and above
					WriteToLog("Display is dimmed")
					$isPC_inUse = False ;?
				Case 1 ;The monitor in on
					WriteToLog("Display powered ON")
					$isPC_inUse = True ;?
				Case 0 ;The monitor in off
					WriteToLog("Display powered OFF")
					$isPC_inUse = False ;?
			EndSwitch

        Case $PBT_APMQUERYSTANDBY
            $isAway = True;?
			WriteToLog("wMsg_1", True)
		Case $PBT_APMRESUMEAUTOMATIC
            $isAway = False
			WriteToLog("wMsg_2", True)
		Case $PBT_APMRESUMEAUTOMATIC
			WriteToLog("wMsg_3", True)
		Case $PBT_APMQUERYSUSPEND
			WriteToLog("wMsg_4", True)
		Case $PBT_APMQUERYSTANDBY
			WriteToLog("wMsg_5", True)
		Case $PBT_APMQUERYSUSPENDFAILED
			WriteToLog("wMsg_6", True)
		Case $PBT_APMQUERYSTANDBYFAILED
			WriteToLog("wMsg_7", True)
		Case $PBT_APMSUSPEND
			WriteToLog("wMsg_8", True)
		Case $PBT_APMSTANDBY
			WriteToLog("wMsg_9", True)
		Case $PBT_APMRESUMECRITICAL
			WriteToLog("wMsg_10", True)
		Case $PBT_APMRESUMESUSPEND
			WriteToLog("wMsg_11", True)
		Case $PBT_APMRESUMESTANDBY
			WriteToLog("wMsg_12", True)
		Case $PBTF_APMRESUMEFROMFAILURE
			WriteToLog("wMsg_13", True)
		Case $PBT_APMBATTERYLOW
			WriteToLog("wMsg_14", True)
		Case $PBT_APMPOWERSTATUSCHANGE
			WriteToLog("wMsg_15", True)
		Case $PBT_APMOEMEVENT
			WriteToLog("wMsg_16", True)
     EndSwitch


    Return $GUI_RUNDEFMSG
EndFunc


;ToDo check locked
Func UpdateTimmers($isForcedUpdate = False)
	local $isTimeUpdateRequired = False
	Local $g_iHour, $g_iMins
	local $iMin_Counter = Int((TimerDiff($iProgStartTime)/1000)/60) ; get seconds

	If ($iYearDay = int(@YDAY)) Then ;==> check if we are on the same day. midnight?
		Local $ScreenSaverActive[4]
		$ScreenSaverActive[3] = 0

		If ($isPC_inUse = True) Then
			$ScreenSaverActive = DllCall("user32.dll","bool","SystemParametersInfoA", "uint", Dec('0072', 1),"uint", 0,"bool*", 0,"uint", 0)
		EndIf

		If ($powerSaverStarted = False) Then
			$isTimeUpdateRequired = True
			if ($ScreenSaverActive[3] = 1) or ($isPC_inUse = False) or ($isPaused = True) Then
				$powerSaverStarted = True
				$iProgStartTime = TimerInit() ; zero counter
				$iDailyTimeMin += $iMin_Counter ; add time since last reset
				$iWeeklyTimeMin+= $iMin_Counter ; add time since last reset
				$iMin_Counter = 0

				local $iHours, $iMinutes, $iSeconds
				local $iIdleTime = _Timer_GetIdleTime()
				_TicksToTime($iIdleTime, $iHours, $iMinutes, $iSeconds)
				$ScreenSaverTimeout = ($iHours*60) + $iMinutes
				$iDailyTimeMin-= Int($ScreenSaverTimeout); remove idle time from work time
				$iWeeklyTimeMin-=Int($ScreenSaverTimeout)
				WriteToLog(StringFormat( "Start idle..        (D=%.1fh W=%.1fh)", ($iDailyTimeMin/60), ($iWeeklyTimeMin/60)))
				ConsoleWrite("> screen not in use"&@CRLF)
			EndIf
		Else ;==> $powerSaverStarted = True
			If ($ScreenSaverActive[3] = 0) And ($isPC_inUse = True) And ($isPaused = False) Then
				$powerSaverStarted = False
				if ($isForcedUpdate = True) Then
					$isTimeUpdateRequired = True
				EndIf
				$iProgStartTime = TimerInit() ; zero counter
				WriteToLog(StringFormat( "Resume Work Time..  (D=%.1fh W=%.1fh)", ($iDailyTimeMin/60), ($iWeeklyTimeMin/60)))
			EndIf
		EndIf
	Else ;==> new day.
		; reset daily time
		WriteToLog(StringFormat( "Reset timmer..      (D=%.1fh W=%.1fh)", (($iDailyTimeMin+$iMin_Counter)/60), (($iWeeklyTimeMin+$iMin_Counter)/60)))
		ConsoleWrite("> reset daily time"&@CRLF)
		$iProgStartTime = TimerInit()
		$isTimeUpdateRequired = True
		$iDailyTimeMin=0

		; reset weekly time if monday
		If int(@WDAY) = 2 Then 	;2=monday
			$iWeeklyTimeMin=0
		EndIf
		$iYearDay = int(@YDAY)
	EndIf

	If $isTimeUpdateRequired = True Then
		local $dailyTotal = $iDailyTimeMin + $iMin_Counter
		local $g_iHour_d = int($dailyTotal/60)
		Local $g_iMins_d = $dailyTotal - ($g_iHour_d*60) ; remove hours from counter to get min

		local $weekTotal = $iWeeklyTimeMin + $iMin_Counter
		local $g_iHour_w = int($weekTotal/60)
		Local $g_iMins_w = $weekTotal - ($g_iHour_w*60) ; remove hours from counter to get min


		GUICtrlSetData($Label1, StringFormat("%02i:%02i", $g_iHour_d, $g_iMins_d))
		GUICtrlSetData($Label2, StringFormat("%02i:%02i", $g_iHour_w, $g_iMins_w))

		if ($isPaused = False) Then
			; set progressbar percent/color. red if +7.6 hours
			Local $WorkDayTime = $iDailyTimeMin + $iMin_Counter
			Local $isTrayTimeRed = False

			if  $WorkDayTime > (7.6*60) Then
				GUICtrlSetData($Progress1, 100)
				GUICtrlSetColor($Progress1, 0xFF0000) ;red
				GUICtrlSetColor($Label1, 0xFF0000) ;red
				$isTrayTimeRed = True
			Else
				GUICtrlSetData($Progress1, int(100.0/((7.6*60)/ $WorkDayTime)))
				GUICtrlSetColor($Progress1, 0x009900) ; green
				GUICtrlSetColor($Label1, 0x000000) ;black
			EndIf

			; set progressbar percent/color. red if +38 hours
			Local $WorkWeekTime = $iWeeklyTimeMin + $iMin_Counter
			if $WorkWeekTime > (38*60) Then
				GUICtrlSetData($Progress2, 100)
				GUICtrlSetColor($Progress2, 0xFF0000) ;red
				GUICtrlSetColor($Label2, 0xFF0000) ;red
				$isTrayTimeRed = True
			Else
				GUICtrlSetData($Progress2, int(100.0/((38*60)/ $WorkWeekTime)))
				GUICtrlSetColor($Progress2, 0x009900) ;
				GUICtrlSetColor($Label2, 0x000000) ;black
			EndIf

			if ($isTrayTimeRed = True) Then
				TraySetIcon( "stop")
			Else
				TraySetIcon()
			EndIf
		EndIf

		TraySetToolTip(StringFormat( "Daily: %.1fh\nWeekly: %.1fh", (($iDailyTimeMin+ $iMin_Counter)/60), _
																	 (($iWeeklyTimeMin+ $iMin_Counter)/60)))
	EndIf

EndFunc




Func TrayWindow_reSize()
	If ($windowStateMin = True) Then
		GUISetState(@SW_SHOW)
		GUISetState(@SW_RESTORE)
		$windowStateMin = False
	Else
		GUISetState(@SW_MINIMIZE)
		GUISetState(@SW_HIDE)
		$windowStateMin = True
	EndIf
EndFunc


#Region ;==> log
;program opened. get time/date
Func Read_Session_FromTempFile()

	$iDailyTimeMin = 0
	$iWeeklyTimeMin = 0

	If FileExists($sFileName) Then
		Local $aArray = FileReadToArray($sFileName)

		if @error Or Not IsArray($aArray) Then
			MsgBox(0,"File Error", "Can not read temp session file",5,$Form2)
			ConsoleWrite("!logFile ERROR" &@CRLF)
		Else
			If (UBound($aArray) >= 5) Then
				Local $line_dMin = int($aArray[0])	; daily min
				Local $line_wMin = int($aArray[1])	; weekly min

				Local $line_7day = int($aArray[2])	; 1-7 day (stored sun -> sat)
				Local $line_365d = int($aArray[3])	; 1-366 day
				Local $line_year = int($aArray[4])	; year 2020

				;test year
				if $line_year = int(@YEAR) Then
					$iYearDay = $line_365d ;set global value
					ConsoleWrite("Same Year. YearDay=" &$iYearDay&@CRLF)


					;get daily hour/min
					If $line_365d = int(@YDAY) Then
						$iDailyTimeMin = $line_dMin ;set global value
						ConsoleWrite("Same Day. DailyTimeMin=" &$iDailyTimeMin&@CRLF)
					EndIf

					;get weekly hour/min
					local $iDaysSinceRun = int(@YDAY) - $line_365d
					if $iDaysSinceRun < 7 and ($iDaysSinceRun + ($line_7day - 1)) < 7 Then
						$iWeeklyTimeMin = $line_wMin ;set global value
						ConsoleWrite("Same Week. WeeklyTimeMin=" &$iWeeklyTimeMin&@CRLF)
					EndIf
				EndIf

				WriteToLog(StringFormat( "Read session data.. (D=%.1fh W=%.1fh)", ($iDailyTimeMin/60), ($iWeeklyTimeMin/60)))
			Else
				ConsoleWrite("!ERROR: log file to short"&@CRLF)

			EndIf
		EndIf
	EndIf

;~ 	$iMinutes=@MIN 	;Seconds value of clock. Range is 00 to 59
;~ 	$iHours=@HOUR 	;Hours value of clock in 24-hour format. Range is 00 to 23
;~ 	$iWeekDay=@WDAY ;Numeric day of week. Range is 1 to 7 which corresponds to Sunday through Saturday.
;~ 	$iYearDay=@YDAY ;Current day of year. Range is 001 to 366
;~ 	$iDate=@MDAY 	;Current day of month. Range is 01 to 31
;~ 	$iMonth=@MON 	;Current month. Range is 01 to 12
;~ 	$iYear=@YEAR 	;Current four-digit year

EndFunc

; Program closed. write session data
Func Write_Session_ToTempFile()
	Local $aArray[5]
	Local $dayShifted = int(@WDAY)-1
	if $dayShifted <=0 Then $dayShifted += 7

	local $iMin_Counter = Int((TimerDiff($iProgStartTime)/1000)/60) ; get seconds
	$iDailyTimeMin += $iMin_Counter ; add time since last reset
	$iWeeklyTimeMin+= $iMin_Counter ; add time since last reset

	; build array
	$aArray[0] = $iDailyTimeMin & @TAB& "[daily min]"		; daily min
	$aArray[1] = $iWeeklyTimeMin & @TAB& "[weekly min]"	; weekly min
	$aArray[2] = $dayShifted & @TAB& "[week day 1-7]"	; 1-7 day (stored mon -> sat)
	$aArray[3] = @YDAY & @TAB& "[yearday 365 ]"			; 1-366 day
	$aArray[4] = @YEAR & @TAB& "[year xxxx]"			; year 2020

	; handle file
	if FileExists($sFileName) = 0 Then
		_FileCreate($sFileName)
	EndIf

	Local $hFile = FileOpen($sFileName, 2)
	If ($hFile = -1) Then
		MsgBox(0,"File Error", "Can not save session to temp folder",5,$Form2)
	Else
		_FileWriteFromArray($sFileName, $aArray)
		FileClose($hFile)
	EndIf
EndFunc

; Program closed. Write logfile
Func Write_Log_ToTempFile()
	Local $hFile = FileOpen($sFileNameLog, 1)
	If $hFile = -1 Then
		MsgBox(0,"File Error", "Can not save log to temp folder",5,$Form2)
		ConsoleWrite("!logFile ERROR" &@CRLF)
	Else
		Local $sTmpList =""
		ConsoleWrite("!log found" &@CRLF)
		For $i = 1 To _GUICtrlListBox_GetCount ($List1)
			$sTmpList = string($sTmpList &_GUICtrlListBox_GetText($List1,$i-1) & @CRLF)
		Next
		FileWrite($hFile, $sTmpList)
		FileClose($hFile)
	EndIf

EndFunc

Func WriteToLog($sReason, $writeToLog = True)
	local $sDateNow = string(@YEAR & "-" & @MON & "-" & @MDAY)
	local $sTimeNow = string (@HOUR & ":" & @MIN & ":" & @SEC)
	local $sMsg = $sDateNow & " " & $sTimeNow & " : " & $sReason
	ConsoleWrite("> " & $sMsg & @CRLF)
	if $writeToLog = True Then
		_GUICtrlListBox_InsertString($List1, $sMsg)
	EndIf
EndFunc
#EndRegion


Func _GDIPlus_GraphicsGetDPIRatio($iDPIDef = 96)
    _GDIPlus_Startup()
    Local $hGfx = _GDIPlus_GraphicsCreateFromHWND(0)
    If @error Then Return SetError(1, @extended, 0)
    Local $aResult
    #forcedef $__g_hGDIPDll, $ghGDIPDll

    $aResult = DllCall($__g_hGDIPDll, "int", "GdipGetDpiX", "handle", $hGfx, "float*", 0)

    If @error Then Return SetError(2, @extended, 0)
    Local $iDPI = $aResult[2]
    Local $aresults[2] = [$iDPIDef / $iDPI, $iDPI / $iDPIDef]
    _GDIPlus_GraphicsDispose($hGfx)
    _GDIPlus_Shutdown()
    Return $aresults
EndFunc   ;==>_GDIPlus_GraphicsGetDPIRatio


Func CLOSE_UI()
	_WinAPI_UnregisterPowerSettingNotification($powerID)
	Write_Session_ToTempFile()
	WriteToLog(StringFormat( "Program closed..    (D=%.1fh W=%.1fh)", ($iDailyTimeMin/60), ($iWeeklyTimeMin/60)))
	Write_Log_ToTempFile()
	Exit
EndFunc

#Region ;==>buttons
Func Button1Click() ;info
	MsgBox(0,"About", 	"Manage work time." & @CRLF & _
						"" & @CRLF & _
						"A work day is 7.6 hours, reset at midnight." & @CRLF & _
						"A work week is 38 hours, reset sunday at midnight" & @CRLF  & _
						"Progress bar will be red if you worked to long." & @CRLF  & _
						"" & @CRLF & _
						"If the pc enters a low power state, the time since last mouse/kb use will be deducted from working time." & @CRLF  & _
						"" & @CRLF  & _
						"Program stores a 'log' and 'state' values in users temp folder." & @CRLF  & _
						"" & @CRLF  & _
						"" & @CRLF  & _
						"", 0, $Form2)

EndFunc

Func Button2Click() ;pause
	GUICtrlSetData($Progress1, 100)
	GUICtrlSetColor($Progress1, 0x999999)
	GUICtrlSetColor($Label1, 0x9999999)
	GUICtrlSetData($Progress2, 100)
	GUICtrlSetColor($Progress2, 0x9999999)
	GUICtrlSetColor($Label2, 0x9999999)
	$isPaused = True
	UpdateTimmers()
EndFunc

Func Button3Click() ;resume
	$isPaused = False
	UpdateTimmers( True)
EndFunc
#EndRegion

While 1
	UpdateTimmers()
	Sleep(10000) ;10 second
WEnd

GUIDelete($Form2)
