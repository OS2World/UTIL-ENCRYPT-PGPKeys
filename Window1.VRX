/*:VRX         Main
*/
/*  Main
*/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    parse source . calledAs .
    parent = ""
    argCount = arg()
    argOff = 0
    if( calledAs \= "COMMAND" )then do
        if argCount >= 1 then do
            parent = arg(1)
            argCount = argCount - 1
            argOff = 1
        end
    end; else do
        call VROptions 'ImplicitNames'
        call VROptions 'NoEchoQuit'
    end
    call rxfuncadd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
    call SysLoadFuncs
    CALL RxFuncAdd 'FileLoadFuncs', 'FILEREXX', 'FileLoadFuncs' 
    CALL FileLoadFuncs     
    kommando = VRGet( "Application", "Commandline" )
    if kommando = 'DE' then kommando = 'de'
    if kommando = 'US' then kommando = 'us'
    ok = VRRedirectStdIO( "Off" )    
    env='OS2ENVIRONMENT'
    temp=value('TMP',,env)
    pgppath=value('PGPPATH',,env)
    pgpd=substr(pgppath,1,1)
    spos=pos(';',pgppath)
    if spos = 0 then pgpp=pgppath
    else pgpp=substr(pgppath,1,spos-1)
    olddrive = VRChDrive( pgpd )
    ApplDir=VRGet( "Application", "Program" )
    spos=lastpos('\',ApplDir)
    if spos=0 then ApplDir=Directory( "" )
    else ApplDir=substr(ApplDir,1,spos-1)
    ToolsExist = VRFileExists( ApplDir'\pgptools.ini' )
    if ToolsExist = 1 then do
        kserver = VRGetIni( "PGPTools", "SendKeyServer", ApplDir'\pgptools.ini' )
        if substr(kserver,1,3) <> 'hkp' then do
            ToolsKeyServer = 0
            kserver = VRGetIni( "PGPKeys", "SendKeyServer", ApplDir'\pgpkeys.ini' )
            if substr(kserver,1,3) <> 'hkp' then do
                kServer='hkp://wwwkeys.pgp.net'
                ok = VRSetIni( "PGPKeys", "SendKeyServer", kserver, ApplDir'\pgpkeys.ini' )
            end
        end
        else ToolsKeyServer = 1
    end
    else do
        kserver = VRGetIni( "PGPKeys", "SendKeyServer", ApplDir'\pgpkeys.ini' )
        if substr(kserver,1,3) <> 'hkp' then do
            kServer='hkp://wwwkeys.pgp.net'
            ok = VRSetIni( "PGPKeys", "SendKeyServer", kserver, ApplDir'\pgpkeys.ini' )
        end
    end
/*    if pgpp="" then pgpp = ApplDir */
    if temp = '' then temp = pgpp
    Pkey=ApplDir'\pgpkk.cmd /N 'pgpp'\pgpk.exe'
    PkeyP=ApplDir'\pgpkk.cmd /P 'pgpp'\pgpk.exe'
    PgpCfg=pgpp'\pgp.cfg'
    if kommando = '' then call Ini_Sprache 
    call Sprache
    CfgExist = VRFileExists( PgpCfg )
    if (CfgExist <> 1) | (pgpp="") then do
       Buttons.1='Cancel'
       Buttons.0=1
       if kommando = 'de' then ok = VRMessage( '','PGPPATH  nicht gesetzt bzw. PGP.CFG nicht gefunden, bitte erst PGP installieren !', 'Fehler', 'E', "Buttons." )
       else ok = VRMessage( "", 'PGPPATH or PGP.CFG not found, install PGP first !', 'Error', 'E', "Buttons." )
       signal _VRELeaveMain
    end
    ZeigeRevKeys = VRGetIni( "PGPKeys", "ShowRevKeys", ApplDir'\pgpkeys.ini' )
    if ZeigeRevKeys = '' then ZeigeRevKeys = 1
    ShowRevKeys = ZeigeRevKeys
    ZeigeRevSigns = VRGetIni( "PGPKeys", "ShowRevSigns", ApplDir'\pgpkeys.ini' )
    if ZeigeRevSigns = '' then ZeigeRevSigns = 1
    ShowRevSigns = ZeigeRevSigns
    SchlLoeWarnung = VRGetIni( "PGPKeys", "KeyDelWarning", ApplDir'\pgpkeys.ini' )
    if SchlLoeWarnung = '' then SchlLoeWarnung = 1
    KeyDelWarning = SchlLoeWarnung
    SchlServer = kserver
    hintergrund = VRGetIni( "PGPKeys", "BackColor", ApplDir'\pgpkeys.ini' )
    schrift = VRGetIni( "PGPKeys", "Font", ApplDir'\pgpkeys.ini' )
    farbe = VRGetIni( "PGPKeys", "ForeColor", ApplDir'\pgpkeys.ini' )
    LB2_hinter = VRGetIni( "PGPKeys", "PropBackColor", ApplDir'\pgpkeys.ini' )
    LB2_schrift = VRGetIni( "PGPKeys", "PropFont", ApplDir'\pgpkeys.ini' )
    LB2_farbe = VRGetIni( "PGPKeys", "PropForeColor", ApplDir'\pgpkeys.ini' )

    InitArgs.0 = argCount
    if( argCount > 0 )then do i = 1 to argCount
        InitArgs.i = arg( i + argOff )
    end
    drop calledAs argCount argOff

/*  Load the windows
*/
    call VRInit
    parse source . . spec
    _VREPrimaryWindowPath = ,
        VRParseFileName( spec, "dpn" ) || ".VRW"
    _VREPrimaryWindow = ,
        VRLoad( parent, _VREPrimaryWindowPath )
    drop parent spec
    if( _VREPrimaryWindow == "" )then do
        call VRMessage "", "Cannot load window:" VRError(), ,
            "Error!"
        _VREReturnValue = 32000
        signal _VRELeaveMain
    end

/*  Process events
*/
    call Init
    signal on halt
    do while( \ VRGet( _VREPrimaryWindow, "Shutdown" ) )
        _VREEvent = VREvent()
        interpret _VREEvent
    end
_VREHalt:
    _VREReturnValue = Fini()
    call VRDestroy _VREPrimaryWindow
_VRELeaveMain:
    call VRFini
exit _VREReturnValue

VRLoadSecondary:
    __vrlsWait = abbrev( 'WAIT', translate(arg(2)), 1 )
    if __vrlsWait then do
        call VRFlush
    end
    __vrlsHWnd = VRLoad( VRWindow(), VRWindowPath(), arg(1) )
    if __vrlsHWnd = '' then signal __vrlsDone
    if __vrlsWait \= 1 then signal __vrlsDone
    call VRSet __vrlsHWnd, 'WindowMode', 'Modal' 
    __vrlsTmp = __vrlsWindows.0
    if( DataType(__vrlsTmp) \= 'NUM' ) then do
        __vrlsTmp = 1
    end
    else do
        __vrlsTmp = __vrlsTmp + 1
    end
    __vrlsWindows.__vrlsTmp = VRWindow( __vrlsHWnd )
    __vrlsWindows.0 = __vrlsTmp
    do while( VRIsValidObject( VRWindow() ) = 1 )
        __vrlsEvent = VREvent()
        interpret __vrlsEvent
    end
    __vrlsTmp = __vrlsWindows.0
    __vrlsWindows.0 = __vrlsTmp - 1
    call VRWindow __vrlsWindows.__vrlsTmp 
    __vrlsHWnd = ''
__vrlsDone:
return __vrlsHWnd

/*:VRX         About_Click
*/
About_Click: 
    MTitel = "About..."
    MText = "PGPKeys V 1.01 (c) Thomas Bohn 1999-2002, e-mail: Thomas@Bohn-Stralsund.de, Homepage: http://Bohn-Stralsund.de"
    call Meldung
return

/*:VRX         Check_Click
*/
Check_Click:
    ok = VRSet( "Window1", "HelpTag", check ) 
    value = VRGet( "LB_1", "SelectedString" )
    if value <> '' then do
    	anfang = pos("(",value)+1
    	laenge = pos(")",value)-anfang
    	user = substr(value,anfang,laenge)
        'start /C /WIN 'PkeyP' -c "'user'"'
	do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
            call SysSleep 1
        end
    end
    else do
    	MText = UIDText
	MTitel = UIDTitel
	call Meldung
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" )
return
/*:VRX         Contents_Click
*/
Contents_Click: 
     obj = VRInfo( "object" )
     call VRMethod obj, "InvokeHelp"
return

/*:VRX         CreateList
*/
CreateList: 
/* This function fills the following struct:
 *
 * pgpkeys.0                           ( == number of keys )
 * pgpkeys.i.__type                    ( == pub, sec+ (sub is ignored) )
 * pgpkeys.i.__bits
 * pgpkeys.i.__keyid
 * pgpkeys.i.__created
 * pgpkeys.i.__expire
 * pgpkeys.i.__algorithm               ( == RSA, DSS )
 * pgpkeys.i.__use                     ( == Sign only, Sign & Encrypt )
 * pgpkeys.i.__fingerprint
 * pgpkeys.i.__uid.0                   ( == number of uids )
 * pgpkeys.i.__uid.i.__userid
 * pgpkeys.i.__uid.i.__sig.0           ( == number of signatures )
 * pgpkeys.i.__uid.i.__sig.i.__type    ( == known, unknown, own )
 * pgpkeys.i.__uid.i.__sig.i.__keyid
 * pgpkeys.i.__uid.i.__sig.i.__sigdate
 * pgpkeys.i.__uid.i.__sig.i.__userid
 *
 * pgpkeys.<key>                       ( == pointer into pgpkeys.i.* )
 */

  pgpkeys.0 = 0
  curkey    = 0
  curuid    = 0

  i = 0
  Pkey' -ll | RXQUEUE'
  if queued() <> 0 then do
      DO UNTIL queued() = 0
         i=i+1
         RLine = LINEIN('QUEUE:')
         if ShowRevKeys = 1 then Zeile.i=RLine
         else if pos( '*REVOKED*', RLine ) = 0 then Zeile.i=RLine
         else i=i-1
      END
      Zeile.0=i

      j=1
      do while j <= Zeile.0
        parse var Zeile.j id rest

        select
        when id == "pub" | id == "sec+" | ((id == "sec") & (ShowRevKeys = 1)) then do
            curkey = pgpkeys.0 + 1
            curuid = 0
            parse var rest bits keyid created expire algorithm use
            keyid = Strip(keyid)
            pgpkeys.curkey.__type      = id
            pgpkeys.curkey.__bits      = Strip(bits)
            pgpkeys.curkey.__keyid     = keyid
            pgpkeys.curkey.__created   = Strip(created)
            pgpkeys.curkey.__expire    = Strip(expire)
            pgpkeys.curkey.__algorithm = Strip(algorithm)
            pgpkeys.curkey.__use       = Strip(use)
            pgpkeys.curkey.__uid.0     = 0
            pgpkeys.0 = curkey
            pgpkeys.keyid = curkey
        end

          when id == "sub" then do
            /* ignore next line which is the fingerprint of the internal key */
            j=j+1
            end

          when id == "f16" then do
            parse var rest "Fingerprint16 =" fingerprint
            pgpkeys.curkey.__fingerprint = Strip(fingerprint)
          end

          when id == "f20" then do
            parse var rest "Fingerprint20 =" fingerprint
            pgpkeys.curkey.__fingerprint = Strip(fingerprint)
          end

          when id == "uid" then do
            curuid = pgpkeys.curkey.__uid.0 + 1
            parse var rest userid
            pgpkeys.curkey.__uid.curuid.__userid = Strip(userid)
            pgpkeys.curkey.__uid.curuid.__sig.0  = 0
            pgpkeys.curkey.__uid.0 = curuid
          end

          when id == "sig" | id == "SIG" | id == "sig?" | id == "sig!" | id == "ret" then do
            cursig = pgpkeys.curkey.__uid.curuid.__sig.0 + 1
            parse var rest keyid sigdate userid
            select
              when id == "sig" | id == "sig!" then
                pgpkeys.curkey.__uid.curuid.__sig.cursig.__type = "known"
              when id == "sig?" then
                pgpkeys.curkey.__uid.curuid.__sig.cursig.__type = "unknown"
              when id == "SIG" then
                pgpkeys.curkey.__uid.curuid.__sig.cursig.__type = "own"
              when id == "ret" then
                pgpkeys.curkey.__uid.curuid.__sig.cursig.__type = "revoked"
            end
            pgpkeys.curkey.__uid.curuid.__sig.cursig.__keyid   = Strip(keyid)
            pgpkeys.curkey.__uid.curuid.__sig.cursig.__sigdate = Strip(sigdate)
            pgpkeys.curkey.__uid.curuid.__sig.cursig.__userid  = Strip(userid)
            pgpkeys.curkey.__uid.curuid.__sig.0 = cursig
          end
    
          otherwise nop
        end
        j=j+1
      end
   END
return

/*:VRX         Del_Click
*/
Del_Click:
        if KeyDelWarning = 1 then do
          ok= VRLoadSecondary( "Warning" )
          ok= VRMethod( "Warning", "Activate" )
        end        
        else call Del_Key
return
/*:VRX         Del_Key
*/
Del_Key: 
    ok = VRSet( "Window1", "HelpTag", del ) 
    value = VRGet( "LB_1", "SelectedString" )
    if value <> '' then do
    	anfang = pos("(",value)+1
    	laenge = pos(")",value)-anfang
    	user = substr(value,anfang,laenge)
	'start /C /WIN 'Pkey' -r "'user'"'
	do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
            call SysSleep 1
        end
        call Refresh_Click
    end
    else do
    	MText = UIDText
	MTitel = UIDTitel
	call Meldung
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" )
return

/*:VRX         Delown_Click
*/
Delown_Click:
    ok = VRSet( "Window1", "HelpTag", delown ) 
    typzeile = VRMethod( "LB_2", "GetString", 1 )
    value = VRGet( "LB_1", "SelectedString" )
    if value <> '' then do
    	anfang = pos("(",value)+1
    	laenge = pos(")",value)-anfang
    	user = substr(value,anfang,laenge)
	typstring = substr(typzeile,8,3)
        if typstring = 'sec' then do
            'start /C /WIN 'Pkey' --revoke "'user'"'
	    do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
                call SysSleep 1
            end
            call Refresh_Click
        end
	else do
    	    MText = SECText
	    MTitel = SECTitel
	    call Meldung
	end
    end
    else do
    	MText = SECText
	MTitel = SECTitel
	call Meldung
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" )
return

/*:VRX         EF_2_KeyPress
*/
EF_2_KeyPress: 
    keystring = VRGet( "EF_2", "KeyString" )
    if keystring = "{Newline}" then call PB_6_Click
return

/*:VRX         Export_Click
*/
Export_Click:
    ok = VRSet( "Window1", "HelpTag", export )  
    typ.0=1
    typ.1='*.asc' 
    value = VRGet( "LB_1", "SelectedString" )
    if value <> '' then do
    	anfang = pos("(",value)+1
    	laenge = pos(")",value)-anfang
    	user = substr(value,anfang,laenge)
        if kommando = 'de' then fileName = VRFileDialog( VRWindow(), "Dateiname zum Speichern", "Save" , "*.asc",,,typ.)
        else fileName = VRFileDialog( VRWindow(), "Filename to Export", "Save" , "*.asc",,,typ.)
        if filename <> '' then do
            'start /C /WIN 'Pkey' -xa "'user'" -o "'filename'"'
	    do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
                call SysSleep 1
            end
        end
    end
    else do
    	MText = UIDText
	MTitel = UIDTitel
	call Meldung
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" ) 
return
/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return 0

/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         Import_Click
*/
Import_Click:
    ok = VRSet( "Window1", "HelpTag", import )  
    typ.0=1
    typ.1='*.asc'
    if kommando = 'de' then fileName = VRFileDialog( VRWindow(), "Datei zum Importieren", "Open" , "*.asc",,,typ.)
    else fileName = VRFileDialog( VRWindow(), "File to Import", "Open" , "*.asc",,,typ.)
    if filename <> '' then do
        'start /C /WIN 'pkey' -a "'filename'"'
	do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
            call SysSleep 1
        end
        call Refresh_Click
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" ) 
return
/*:VRX         Ini_Sprache
*/
Ini_Sprache: 
    handle = FileOpen(PgpCfg, 'rs', 'e')
    IF handle <> 0 THEN DO
        DO FOREVER
            RLine = FileGets(handle)
            if FileErr=0 then leave
            testzeile = translate(RLine)
            if substr(testzeile,1,10) = 'LANGUAGE =' then do
                kommando = substr(RLine, 12, 2)
                leave   
            end
        end
        err = FileClose(handle)   
    END
return

/*:VRX         Init
*/
Init:
    window = VRWindow()
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window
return

/*:VRX         IPB_10_Click
*/
IPB_10_Click: 
    call Send_Click
return

/*:VRX         IPB_12_Click
*/
IPB_12_Click: 
    call Import_Click
return

/*:VRX         IPB_13_Click
*/
IPB_13_Click: 
    call Export_Click
return

/*:VRX         IPB_1_Click
*/
IPB_1_Click: 
    call New_Click
return

/*:VRX         IPB_5_Click
*/
IPB_5_Click: 
    call Revokes_Click
return

/*:VRX         IPB_6_Click
*/
IPB_6_Click: 
    call Sign_Click
return

/*:VRX         IPB_7_Click
*/
IPB_7_Click: 
    call Del_Click
return

/*:VRX         IPB_9_Click
*/
IPB_9_Click: 
    call Search_Click
return

/*:VRX         LB_1_Click
*/
LB_1_Click:
    ok = VRMethod( "LB_2", "Clear" ) 
    i = VRGet( "LB_1", "Selected" )
    m=1
    LB_2liste.m = "Type: " pgpkeys.i.__type pgpkeys.i.__algorithm
    if kommando = 'de' then do
      if pos('pub', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||' (îffentlich'
      if pos('sec+', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||' (privat, vertraut'
      if pos('sec ', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||' (privat, NICHT vertraut'
      if pos('DSS', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||', DSS-VerschlÅsselung)' 
      if pos('RSA', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||', RSA-VerschlÅsselung)' 
    end
    else
    do
      if pos('pub', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||' (public'
      if pos('sec+', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||' (secret, trusted'
      if pos('sec ', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||' (secret, NOT trusted'
      if pos('DSS', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||', DSS encryption)' 
      if pos('RSA', LB_2liste.m) <> 0 then LB_2liste.m = LB_2liste.m||', RSA encryption)' 
    end
    m=m+1
    LB_2liste.m = "Use: " pgpkeys.i.__use
    m=m+1
    LB_2liste.m = "Expire: " pgpkeys.i.__expire
    m=m+1
    do j=1 to pgpkeys.i.__uid.0    
        LB_2liste.m = "User-ID: "  pgpkeys.i.__uid.j.__userid
        m=m+1
        do k=1 to pgpkeys.i.__uid.j.__sig.0
            if ShowRevSigns = 1 then do
              LB_2liste.m = "Signature: " pgpkeys.i.__uid.j.__sig.k.__type " ("pgpkeys.i.__uid.j.__sig.k.__keyid") " pgpkeys.i.__uid.j.__sig.k.__sigdate " " pgpkeys.i.__uid.j.__sig.k.__userid
              m=m+1
            end
            else do
              if pgpkeys.i.__uid.j.__sig.k.__type \= 'revoked' then do
                LB_2liste.m = "Signature: " pgpkeys.i.__uid.j.__sig.k.__type " ("pgpkeys.i.__uid.j.__sig.k.__keyid") " pgpkeys.i.__uid.j.__sig.k.__sigdate " " pgpkeys.i.__uid.j.__sig.k.__userid
                m=m+1
              end
            end
        end
    end
    LB_2liste.m = "Fingerprint: " pgpkeys.i.__fingerprint
    LB_2liste.0=m
    ok = VRMethod( "LB_2", "AddStringList", LB_2liste.,  )
return
/*:VRX         LB_1_ContextMenu
*/
LB_1_ContextMenu: 
    call VRMethod "Keys", "Popup"    
return

/*:VRX         LB_1_KeyPress
*/
LB_1_KeyPress: 
    call LB_1_Click
return

/*:VRX         Meldung
*/
Meldung:
    ok= VRLoadSecondary( "Message" )
    ok = VRSet( "DT_1", "Caption", MText )
    ok = VRSet( "Message", "Caption", MTitel )
    ok= VRMethod( "Message", "Activate" )
return
/*:VRX         Menu_Sprache
*/
Menu_Sprache:
    if kommando = 'de' then do 
        ok = VRSet( "File", "Caption", "~Datei" )
        ok = VRSet( "File", "HintText", "Liste aktualisieren oder Programm beenden" )
        ok = VRSet( "Refresh", "Caption", "~Aktualisieren" )
        ok = VRSet( "Refresh", "HintText", "Liste aktualisieren" )
        ok = VRSet( "Options", "Caption", "~Optionen" )
        ok = VRSet( "Options", "HintText", "Optionen einstellen" )
        ok = VRSet( "Quit", "Caption", "~Ende" )
        ok = VRSet( "Quit", "HintText", "Programm beenden" )
        ok = VRSet( "Keys", "Caption", "~SchlÅssel" )
        ok = VRSet( "Keys", "HintText", "Funktionen zur SchlÅsselmanipulation" )
        ok = VRSet( "Import", "Caption", "~Import îffentl. SchlÅssel" )
        ok = VRSet( "Import", "HintText", "ôffentlichen SchlÅssel aus .ASC-Datei importieren" )
        ok = VRSet( "IPB_12", "HintText", "ôffentlichen SchlÅssel aus .ASC-Datei importieren" )
        ok = VRSet( "Export", "Caption", "~Export îffentl. SchlÅssel" )
        ok = VRSet( "Export", "HintText", "ôffentlichen SchlÅssel in .ASC-Datei schreiben" )
        ok = VRSet( "IPB_13", "HintText", "ôffentlichen SchlÅssel in .ASC-Datei schreiben" )
        ok = VRSet( "Sign", "Caption", "SchlÅssel ~unterschreiben" )
        ok = VRSet( "Sign", "HintText", "SchlÅssel mit eigener Unterschrift versehen" )
        ok = VRSet( "IPB_6", "HintText", "SchlÅssel mit eigener Unterschrift versehen" )
        ok = VRSet( "Trust", "Caption", "~Vertrauenstellung / Parameter" )
        ok = VRSet( "Trust", "HintText", "Vertrauensstellung fÅr îffentl. SchlÅssel bzw. Parameter fÅr privaten SchlÅssel Ñndern" )
        ok = VRSet( "Check", "Caption", "SchlÅssel ~prÅfen" )
        ok = VRSet( "Check", "HintText", "Unterschriften eines îffentlichen SchlÅssels prÅfen" )
        ok = VRSet( "Unsign", "Caption", "~Entfernen Unterschrift von einem SchlÅssel" )
        ok = VRSet( "Unsign", "HintText", "Unterschrift von einem SchlÅssel entfernen" )
        ok = VRSet( "Revokes", "Caption", "Eigene ~Unterschrift widerrufen" )
        ok = VRSet( "Revokes", "HintText", "Eigene Unterschrift von allen SchlÅsseln widerrufen" )
        ok = VRSet( "IPB_5", "HintText", "Eigene Unterschrift von allen SchlÅsseln widerrufen" )
        ok = VRSet( "Del", "Caption", "SchlÅssel ~lîschen" )
        ok = VRSet( "Del", "HintText", "SchlÅssel aus der Liste lîschen" )
        ok = VRSet( "IPB_7", "HintText", "SchlÅssel aus der Liste lîschen" )
        ok = VRSet( "Delown", "Caption", "Eigenen SchlÅssel ~widerrufen" )
        ok = VRSet( "Delown", "HintText", "Eigenen SchlÅssel aus priv./îffentl. Ring widerrufen" )
        ok = VRSet( "New", "Caption", "~Neues SchlÅsselpaar" )
        ok = VRSet( "New", "HintText", "Neuen privaten und îffentlichen SchlÅssel generieren" )
        ok = VRSet( "IPB_1", "HintText", "Neuen privaten und îffentlichen SchlÅssel generieren" )
        ok = VRSet( "Send", "Caption", "SchlÅssel ~senden" )
        ok = VRSet( "Send", "HintText", "ôffentlichen SchlÅssel an Server senden" )
        ok = VRSet( "IPB_10", "HintText", "ôffentlichen SchlÅssel an Server senden" )
        ok = VRSet( "Search", "Caption", "SchlÅssel suchen und ~Importieren" )
        ok = VRSet( "Search", "HintText", "SchlÅssel auf Server suchen und importieren wenn gefunden" )
        ok = VRSet( "IPB_9", "HintText", "SchlÅssel auf Server suchen und importieren wenn gefunden" )
        ok = VRSet( "Help", "Caption", "~Hilfe" )
        ok = VRSet( "Help", "HintText", "Hilfe und Kontaktinformation" )
        ok = VRSet( "Contents", "Caption", "~Inhalt" )
        ok = VRSet( "Contents", "HintText", "Inhalt der Hilfe" )
        ok = VRSet( "About", "Caption", "~Info" )
        ok = VRSet( "About", "HintText", "öber den Autor..." )
        ok = VRSet( "EF_2", "HintText", 'Suchfeld' )
        ok = VRSet( "PB_6", "HintText", 'Suchen' )
    end
return

/*:VRX         Message_Close
*/
Message_Close: 
    call Message_Fini
return

/*:VRX         Message_Create
*/
Message_Create: 
    call Message_Init
    if MTitel <> 'About...' then do
      ok =Beep(400,250)
      ok =Beep(700,250)
    end
    if kommando = 'de' then do
        ok = VRSet( "PB_5", "HintText", "Schlie·e dieses Fenster" )
    end
    if kommando = 'us' then do
        ok = VRSet( "PB_5", "HintText", "close this window" )
    end
return

/*:VRX         Message_Fini
*/
Message_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         Message_Init
*/
Message_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         New_Click
*/
New_Click:
    ok = VRSet( "Window1", "HelpTag", keypair )
    'start /C /WIN 'Pkey' -g'
     do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
         call SysSleep 1
     end
     ok = VRSet( "Window1", "HelpTag", help contents )
     call Refresh_Click
return
/*:VRX         Optionen_Close
*/
Optionen_Close: 
    ok = VRSet( "Window1", "HelpTag", help contents )
    call Optionen_Fini
return
/*:VRX         Optionen_Create
*/
Optionen_Create: 
    call Optionen_Init
    ok = VRSet( "EF_3", "Value", kserver )
    if ToolsKeyServer = 1 then ok = VRSet( "EF_3", "Enabled", 0 )
    ok = VRSet( "Window1", "HelpTag", Options )
    ok = VRSet( "CB_1", "Set", ShowRevKeys )
    ok = VRSet( "CB_2", "Set", ShowRevSigns )
    ok = VRSet( "CB_3", "Set", KeyDelWarning )
    if kommando = 'de' then do
      ok = VRSet( "CB_1", "Caption", "Zeige widerrufene SchlÅssel" )
      ok = VRSet( "CB_1", "HintText", "Widerrufene SchlÅssel in Liste zeigen oder nicht" )
      ok = VRSet( "CB_2", "Caption", "Zeige widerrufene Unterschriften" )
      ok = VRSet( "CB_2", "HintText", "Widerrufene Unterschriften anzeigen oder nicht" )
      ok = VRSet( "CB_3", "Caption", "Warnung vor Lîschen von SchlÅsseln" )
      ok = VRSet( "CB_3", "HintText", "Sicherheitsabfrage durchfÅhren oder nicht" )
      ok = VRSet( "PB_7", "Caption", "~Speichern" )
      ok = VRSet( "PB_7", "HintText", "speichert Einstellungen schliesst das Fenster" )
      ok = VRSet( "PB_8", "Caption", "~Abbruch" )
      ok = VRSet( "PB_8", "HintText", "ignoriert énderungen und schliesst das Fenster" )
      ok = VRSet( "Optionen", "Caption", "Optionen fÅr PGPKeys" )
      ok = VRSet( "EF_3", "HintText", "SchlÅsselserver (nur hkp://... erlaubt)" )
    end
return
/*:VRX         Optionen_Fini
*/
Optionen_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         Optionen_Init
*/
Optionen_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         Options_Click
*/
Options_Click: 
    ok= VRLoadSecondary( "Optionen" )
    ok= VRMethod( "Optionen", "Activate" )
return

/*:VRX         PB_10_Click
*/
PB_10_Click: 
    call Warning_Close
return

/*:VRX         PB_1_Click
*/
PB_1_Click:
    ok = VRSet( "Window1", "HelpTag", sign ) 
    value = VRGet( "SPIN_1", "Value" )
    anfang = pos("(",value)+1
    laenge = pos(")",value)-anfang
    sign = substr(value,anfang,laenge)
    'start /C /WIN 'PkeyP' -s "'user'" -u "'sign'"'
    do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
        call SysSleep 1
    end
    call Window2_Fini
    call Refresh_Click
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" ) 
return
/*:VRX         PB_2_Click
*/
PB_2_Click: 
    call Window2_Fini
return

/*:VRX         PB_3_Click
*/
PB_3_Click: 
    phrase = VRGet( "EF_1", "Value" )
    if phrase <> "" then do
        keyserver = translate(kserver,'##','//')
        cpos = pos('00'x,keyserver)
        if cpos <> 0 then keyserver = delstr(keyserver,cpos)
        do while pos(' ',phrase) <> 0
            cpos = pos(' ',phrase)
            phrase = delstr(phrase,cpos,1)
        end
        suche = keyserver||"#"||phrase
        'start /C /WIN 'PkeyP' -a 'suche
	do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
            call SysSleep 1
        end
        call Window3_Fini
        call Refresh_Click
    end
    ok = VRMethod( "LB_1", "SetFocus" )
return
/*:VRX         PB_4_Click
*/
PB_4_Click: 
    call Window3_Fini
return

/*:VRX         PB_5_Click
*/
PB_5_Click: 
    call Message_Close
return
/*:VRX         PB_6_Click
*/
PB_6_Click: 
    value = VRGet( "EF_2", "Value" )
    position = VRMethod( "LB_1", "FindString", value, 1, "Substring" )
    if position <> 0 then ok = VRSet( "LB_1", "Selected", position )
return
/*:VRX         PB_7_Click
*/
PB_7_Click: 
    ShowRevKeys = VRGet( "CB_1", "Set" )
    ShowRevSigns = VRGet( "CB_2", "Set" )
    KeyDelWarning = VRGet( "CB_3", "Set" )
    kserver = VRGet( "EF_3", "Value" )
    ok = VRSet( "Window1", "HelpTag", help contents )
    call Refresh_Click
    call Optionen_Fini
return

/*:VRX         PB_8_Click
*/
PB_8_Click: 
    ok = VRSet( "Window1", "HelpTag", help contents )
    call Optionen_Fini
return

/*:VRX         PB_9_Click
*/
PB_9_Click: 
    call Warning_Fini
    call Del_Key
return

/*:VRX         Quit
*/
Quit:
    if ShowRevKeys <> ZeigeRevKeys then ok = VRSetIni( "PGPKeys", "ShowRevKeys", ShowRevKeys, ApplDir'\pgpkeys.ini' )
    if ShowRevSigns <> ZeigeRevSigns then ok = VRSetIni( "PGPKeys", "ShowRevSigns", ShowRevSigns, ApplDir'\pgpkeys.ini' )
    if KeyDelWarning <> SchlLoeWarnung then ok = VRSetIni( "PGPKeys", "KeyDelWarning", KeyDelWarning, ApplDir'\pgpkeys.ini' )
    if kserver <> SchlServer then ok = VRSetIni( "PGPKeys", "SendKeyServer", kserver, ApplDir'\pgpkeys.ini' )        

    backcolor = VRGet( "LB_1", "BackColor" )
    if backcolor <> hintergrund then ok = VRSetIni( "PGPKeys", "BackColor", backcolor, ApplDir'\pgpkeys.ini' )
    font = VRGet( "LB_1", "Font" )
    if font <> schrift then ok = VRSetIni( "PGPKeys", "Font", font, ApplDir'\pgpkeys.ini' )
    color = VRGet( "LB_1", "ForeColor" )
    if color <> farbe then ok = VRSetIni( "PGPKeys", "ForeColor", color, ApplDir'\pgpkeys.ini' )

    backcolor = VRGet( "LB_2", "BackColor" )
    if backcolor <> LB2_hinter then ok = VRSetIni( "PGPKeys", "PropBackColor", backcolor, ApplDir'\pgpkeys.ini' )
    font = VRGet( "LB_2", "Font" )
    if font <> LB2_schrift then ok = VRSetIni( "PGPKeys", "PropFont", font, ApplDir'\pgpkeys.ini' )
    color = VRGet( "LB_2", "ForeColor" )
    if color <> LB2_farbe then ok = VRSetIni( "PGPKeys", "PropForeColor", color, ApplDir'\pgpkeys.ini' )
    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return
/*:VRX         Quit_Click
*/
Quit_Click: 
    call Quit;
return

/*:VRX         Refresh_Click
*/
Refresh_Click:
    LB1_selected = VRGet( "LB_1", "Selected" )
    if LB1_selected = 0 then LB1_selected = 1
    ok = VRMethod( "LB_1", "Clear" )
    call CreateList
    j = 0
    do key = 1 to pgpkeys.0
      do uid = 1 to pgpkeys.key.__uid.0
        Liste.key = pgpkeys.key.__bits pgpkeys.key.__algorithm "("pgpkeys.key.__keyid")" pgpkeys.key.__uid.1.__userid
        if substr(pgpkeys.key.__type,1,3) = 'sec' then do
          j = j+1
          priv.j =  pgpkeys.key.__bits pgpkeys.key.__algorithm "("pgpkeys.key.__keyid")" pgpkeys.key.__uid.uid.__userid
        end
      end
    end
    priv.0=j
    Liste.0=pgpkeys.0
    ok = VRMethod( "LB_1", "AddStringList", Liste.,  )
    ok = VRSet( "LB_1", "Selected", LB1_selected )
return
/*:VRX         Revokes_Click
*/
Revokes_Click:
    ok = VRSet( "Window1", "HelpTag", revokes )  
    typzeile = VRMethod( "LB_2", "GetString", 1 )
    value = VRGet( "LB_1", "SelectedString" )
    if value <> '' then do
    	anfang = pos("(",value)+1
    	laenge = pos(")",value)-anfang
    	user = substr(value,anfang,laenge)
	typstring = substr(typzeile,8,3)
        if typstring = 'sec' then do
            'start /C /WIN 'Pkey' --revokes "'user'"'
            do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
                call SysSleep 1
            end
            call Refresh_Click
        end
        else do
    	    MText = SECText
	    MTitel = SECTitel
	    call Meldung
        end
    end
    else do
    	MText = SECText
	MTitel = SECTitel
	call Meldung
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" ) 
return

/*:VRX         Search_Click
*/
Search_Click:
    ok = VRSet( "Window1", "HelpTag", search )  
    ok= VRLoadSecondary( "Window3" )
    ok= VRMethod( "Window3", "Activate" )
    ok = VRSet( "Window1", "HelpTag", help contents )
return
/*:VRX         Select_Priv
*/
Select_Priv: 
    ok= VRLoadSecondary( "Window2" )
    ok= VRMethod( "Window2", "Activate" ) 
    ok = VRMethod( "SPIN_1", "SetStringList", "priv." )
return
/*:VRX         Send_Click
*/
Send_Click:
    ok = VRSet( "Window1", "HelpTag", send )  
    value = VRGet( "LB_1", "SelectedString" )
    if value <> '' then do
    	anfang = pos("(",value)+1
    	laenge = pos(")",value)-anfang
    	user = substr(value,anfang,laenge)
        keyserver = translate(kserver,'##','//')
        'start /C /WIN 'PkeyP' -xa "'user'" -o 'keyserver
	do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
            call SysSleep 1
        end
    end
    else do
    	MText = UIDText
	MTitel = UIDTitel
	call Meldung
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" ) 
return
/*:VRX         Sign_Click
*/
Sign_Click:
    ok = VRSet( "Window1", "HelpTag", sign )  
    value = VRGet( "LB_1", "SelectedString" )
    if value <> '' then do
    	anfang = pos("(",value)+1
    	laenge = pos(")",value)-anfang
    	user = substr(value,anfang,laenge)
        call Select_Priv
    end
    else do
    	MText = UIDText
	MTitel = UIDTitel
	call Meldung
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
return
/*:VRX         Sprache
*/
Sprache:
    if kommando = 'de' then do
        UIDText = "Bitte einen SchlÅssel wÑhlen !"
        UIDTitel = "SchlÅssel nicht gewÑhlt"
        SECText = "Bitte einen privaten SchlÅssel wÑhlen !"
        SECTitel = "Privater SchlÅssel nicht gewÑhlt"
    end
    else do
        UIDText = "Please select a key !"
        UIDTitel = "Key not selected"
        SECText = "Please select a private key !"
        SECTitel = "Private key not selected"
    end
return
/*:VRX         Trust_Click
*/
Trust_Click:
    ok = VRSet( "Window1", "HelpTag", trust ) 
    typzeile = VRMethod( "LB_2", "GetString", 1 )
    value = VRGet( "LB_1", "SelectedString" )
    if value <> '' then do
    	anfang = pos("(",value)+1
    	laenge = pos(")",value)-anfang
    	user = substr(value,anfang,laenge)
	typstring = substr(typzeile,8,3)
        if typstring = 'sec' then do
            'start /C /WIN 'PkeyP' -e "'user'"'
            do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
                call SysSleep 1
            end
            call Refresh_Click
        end
        else do
            'start /C /WIN 'Pkey' -e "'user'"'
	    do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
                 call SysSleep 1
            end
        end
    end
    else do
    	MText = UIDText
	MTitel = UIDTitel
	call Meldung
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" ) 
return
/*:VRX         Unsign_Click
*/
Unsign_Click:
    ok = VRSet( "Window1", "HelpTag", unsign ) 
    value = VRGet( "LB_1", "SelectedString" )
    if value <> '' then do
    	anfang = pos("(",value)+1
    	laenge = pos(")",value)-anfang
    	user = substr(value,anfang,laenge)
        'start /C /WIN 'Pkey' -rs "'user'"'
        do while VRMethod( "Screen", "FindWindow", 'pgpkk.cmd','Desktop',,,'exact' ) <> ''
            call SysSleep 1
        end
        call Refresh_Click
    end
    else do
    	MText = UIDText
	MTitel = UIDTitel
	call Meldung
    end
    ok = VRSet( "Window1", "HelpTag", help contents )
    ok = VRMethod( "LB_1", "SetFocus" ) 
return
/*:VRX         Warning_Close
*/
Warning_Close: 
    call Warning_Fini
return

/*:VRX         Warning_Create
*/
Warning_Create: 
    call Warning_Init
    if kommando = 'de' then do
        ok = VRSet( "Warning", "Caption", "Warnung" )
        ok = VRSet( "DT_3", "Caption", "Sie lîschen einen SchlÅssel ! Wollen Sie das ?" )
        ok = VRSet( "PB_9", "Caption", "~Ja" )
        ok = VRSet( "PB_10", "Caption", "~Nein" )
        ok = VRSet( "PB_9", "HintText", "GewÑhlten SchlÅssel lîschen" )
        ok = VRSet( "PB_10", "HintText", "Schlie·t dieses Fenster" )
        ok = VRSet( "Window1", "HelpFile", "PGPKeysd.hlp" )
        ok = VRSet( "Window1", "HelpTitle", "Hilfe fÅr PGPKeys" )
    end
    ok =Beep(400,250)
    ok =Beep(700,250)
return

/*:VRX         Warning_Fini
*/
Warning_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         Warning_Init
*/
Warning_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         Window1_Close
*/
Window1_Close:
    call Quit
return

/*:VRX         Window1_Create
*/
Window1_Create:
    call Menu_Sprache 
    if kommando = 'de' then do
        ok = VRSet( "Window1", "Caption", "PGPKeys fÅr OS/2" )
        ok = VRSet( "Window1", "HelpFile", ApplDir"\PGPKeysd.hlp" )
        ok = VRSet( "Window1", "HelpTitle", "Hilfe fÅr PGPKeys" )
    end
    else do
        ok = VRSet( "Window1", "Caption", "PGPKeys for OS/2" )
        ok = VRSet( "Window1", "HelpFile", ApplDir"\PGPKeyse.hlp" )
        ok = VRSet( "Window1", "HelpTitle", "Help for PGPKeys" )
    end
    if hintergrund <> '' then ok = VRSet( "LB_1", "BackColor", hintergrund )
    if schrift <> '' then ok = VRSet( "LB_1", "Font", schrift )
    if farbe <> '' then ok = VRSet( "LB_1", "ForeColor", farbe )
    if LB2_hinter <> '' then ok = VRSet( "LB_2", "BackColor", LB2_hinter )
    if LB2_schrift <> '' then ok = VRSet( "LB_2", "Font", LB2_schrift )
    if LB2_farbe <> '' then ok = VRSet( "LB_2", "ForeColor", LB2_farbe )
    call Refresh_Click
return
/*:VRX         Window2_Close
*/
Window2_Close: 
    call Window2_Fini
return

/*:VRX         Window2_Create
*/
Window2_Create: 
    call Window2_Init
    if kommando = 'de' then do
        ok = VRSet( "Window2", "Caption", "UnterschriftsschlÅssel wÑhlen" )
        ok = VRSet( "PB_1", "Caption", "~Unterschreiben" )
        ok = VRSet( "PB_2", "Caption", "~Abbruch" )
        ok = VRSet( "PB_1", "HintText", "Unterschreiben" )
        ok = VRSet( "PB_2", "HintText", "Schlie·e dieses Fenster" )
        ok = VRSet( "SPIN_1", "HintText", "WÑhle SchlÅssel" )
        ok = VRSet( "Window2", "HelpFile", "PGPKeysd.hlp" )
        ok = VRSet( "Window2", "HelpTitle", "Hilfe fÅr PGPKeys" )
        ok = VRMethod( "SPIN_1", "SetFocus" )
    end
return

/*:VRX         Window2_Fini
*/
Window2_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         Window2_Init
*/
Window2_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         Window3_Close
*/
Window3_Close: 
    call Window3_Fini
return

/*:VRX         Window3_Create
*/
Window3_Create: 
    call Window3_Init
    if kommando = 'de' then do
        ok = VRSet( "Window3", "Caption", "SchlÅssel finden" )
        ok = VRSet( "DT_2", "Caption", "Bitte Suchbegriff oder e-mail-Adresse eingeben, zum Internet verbinden und 'Suchen' drÅcken !  Nach der Suche bitte die Liste kontrollieren." )
        ok = VRSet( "PB_3", "Caption", "~Suchen" )
        ok = VRSet( "PB_4", "Caption", "~Abbruch" )
        ok = VRSet( "PB_3", "HintText", "Starte die Suche" )
        ok = VRSet( "PB_4", "HintText", "Schlie·t dieses Fenster" )
        ok = VRSet( "EF_1", "HintText", "Suchbegriff oder e-mail-Adresse" )
        ok = VRSet( "Window1", "HelpFile", "PGPKeysd.hlp" )
        ok = VRSet( "Window1", "HelpTitle", "Hilfe fÅr PGPKeys" )
        ok = VRMethod( "EF_1", "SetFocus" )
    end
return
/*:VRX         Window3_Fini
*/
Window3_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         Window3_Init
*/
Window3_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

