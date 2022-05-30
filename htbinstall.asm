%include "htbinstall.inc"
%include "data.asm"
%include "thread.asm"
;***************************************************************************
align 4
isMMX:
    push    ebx
    pushfd
    pop     eax
    mov     ebx, eax
    xor     eax, 00200000h
    push    eax
    popfd
    pushfd
    pop     eax
    cmp     eax, ebx
    jz      @F  ;NO cpuid - no MMX
    mov     eax,1   ; setup function 1
    CPUID       ; call the function
    test    edx,800000 ; test 23rd bit
    jz      @F
    xor     eax,eax
    inc     eax
    pop     ebx
    retn
@@
    xor eax,eax
    pop ebx
    retn
align 4
strcpy proc
    push    edi
    push    esi
    mov     edi,[esp+8+8] ;[lpSource]
    xor     eax,eax
    mov     esi,edi
    lea     ecx,[eax-1]
    repnz   scasb
    not     ecx
    mov     edi,[esp+4+8] ;[lpDest]
    lea     eax,[ecx-1]
    rep     movsb
    pop     esi
    pop     edi
    ret
strcpy  endp
align 4
_strcat:
    pop     ecx         ; adres powrotu
    pop     eax         ; wskaznik stringa wyjsciowego
    pop     edx         ; wskaznik stringa wejsciowego
    push    ecx         ; zapamietaj adres powrotu
    push    esi         ; zapamietaj wykorzystane rejestry
    push    edi
    push    eax         ; zapamietaj adres bufora wyjsciowego
    xchg    eax,edi     ; do edi offset striga, do ktorego ma
                        ; byc dolaczony 2
    sub     eax,eax     ; szukaj 00h w 1 stringu
@@
    scasb               ; skanuj string, az nie znajdziesz 00h
    jne     @B
    dec     edi         ; jesli znalezione 00h, edi ustawione na bajt
                        ; po 00h, czyli cofamy edi o 1 do tylu
    mov     esi,edx     ; string, ktory ma byc doklejony
@@
    lodsb               ; bajt ze stringa doklejanego
    stosb               ; dodaj do stringa wyjsciowego
    test    eax,eax     ; sprawdz czy kopiowany bajt to 00h
    jne     @B          ; jesli tak, zakoncz petle
    pop     eax         ; po wyjsciu z procki eax wskazuje na
                        ; string wyjsciowy
    pop     edi
    pop     esi
    retn
_strlen@4:
START:
    ;--set SEH
    push    .SEHProc
    push    D [fs:0]
    mov     [fs:0],esp
    jmp @F
.SEHProc:
    mov     esp,D [fs:0]
    mov     esp,[esp]
    pop     D [fs:0]
    FATAL   "Internal error, exiting!"
@@
    call    isMMX
    or      eax,eax
    jnz     @F
    FATAL   "No MMX no fun!"
@@
    call    ReadConfig
    mov     D [wc+WNDCLASSEX.hInstance],MYINSTANCE
    API     LoadIconA,MYINSTANCE,999
    mov     [wc+WNDCLASSEX.hIcon],eax
    API     LoadCursorA,NULL,IDC_ARROW
    mov     [wc+WNDCLASSEX.hCursor],eax
    mov     D [wc+WNDCLASSEX.hbrBackground],COLOR_WINDOWFRAME
    mov     D [wc+WNDCLASSEX.lpszClassName],szClassName
    mov     D [wc+WNDCLASSEX.lpszMenuName],NULL
    API     RegisterClassExA,wc         ;zarejestruj ja
    API     GetSystemMetrics,SM_CXSCREEN
    shr     eax,1
    sub     eax,SCREENX/2
    mov     ebx,eax
    API     GetSystemMetrics,SM_CYSCREEN
    shr     eax,1
    sub     eax,SCREENY/2
    cdq     ; edx==0
    API     CreateWindowExA,0,szClassName,szDisplayName,\
                WS_POPUP | WS_SYSMENU | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,\
                ebx,eax,SCREENX,SCREENY,edx,edx,MYINSTANCE,edx
    test    eax,eax
    jz      .exit
    API     ShowWindow,eax,SW_SHOW
    API     UpdateWindow,[hMainWnd]
    API     SetFocus,[hMainWnd]
    mov     esi,msg
@@
    sub     eax,eax
    API     GetMessageA,esi,eax,eax,eax
    or      eax,eax
    jz      .exit
    API     TranslateMessage,esi
    API     DispatchMessageA,esi
    jmp     short @B
.exit:
    API     UnregisterClassA,szClassName,MYINSTANCE
    API     ExitProcess,[msg+MSG.wParam]
;***************************************************************************
ALIGN 4
WndProc proc hWnd,uMsg,wParam,lParam
    enter
    mov     eax,[.uMsg]
    mov     edx,.casetab
.check_messages:
    movzx   ecx,word [edx]
    or      ecx,ecx
    jz      short .return
    cmp     eax,ecx
    jnz     short @F
    jmp     [edx+2]
@@
    lea     edx,[edx+6]
    jmp     short .check_messages
.casetab:
    dw WM_CREATE
    dd .wm_create
    dw WM_DESTROY
    dd .wm_destroy
    dw WM_GO
    dd .wm_go
    dw WM_LBUTTONDOWN
    dd .wm_lbuttondown
    dw WM_LBUTTONUP
    dd .wm_sizing
    dw WM_SIZING
    dd .wm_sizing
    dw WM_MOUSEMOVE
    dd .wm_mousefirst
    dw WM_COMMAND
    dd .wm_command
    dw WM_CTLCOLORBTN
    dd .wm_ctlcolorbtn
    dw WM_CTLCOLORSTATIC
    dd .wm_ctlcolorbtn
    dw WM_SETCURSOR
    dd .wm_setcursor
    dw WM_KEYDOWN
    dd .wm_keydown
    dw 0
.return:
    API     DefWindowProcA,[.hWnd],[.uMsg],[.wParam],[.lParam]
    ret
.wm_destroy:
    mov     D [fRemoveThread],1
    API     WaitForSingleObject,[hThread],-1
    API     CloseHandle,[hThread]
    push    'POTS'
    call    _mfmres
    pop     eax
    API     DeleteObject,[hFont]
    API     RemoveFontResourceA,szFontFileName
    API     DeleteFileA,szFontFileName
    API     PostQuitMessage,0
    jmp     .return
.wm_go:
    mov     esi,[__imp__EnableWindow@8]
    sc      esi,[hBtnInstall],TRUE
    sc      esi,[hBtnNfo],TRUE
    sc      esi,[hBtnExit],TRUE
    API     SetCursor,[wc+WNDCLASSEX.hCursor]
    API     ShowCursor,TRUE
    API     GetSystemMetrics,SM_CYSCREEN
    shr     eax,1
    push    eax
    API     GetSystemMetrics,SM_CXSCREEN
    shr     eax,1
    API     SetCursorPos,eax,EMPTY
    jmp     .return
.wm_lbuttondown:
    API     GetCursorPos,CursorOrg
    API     SetCapture,[.hWnd]
    mov     D [fMovingEnable],1
    jmp     .return
.wm_sizing:
    API     ReleaseCapture
    mov     D [fMovingEnable],0
    jmp     .return
.wm_mousefirst:
    cmp     D [fMovingEnable],1
    jnz     .return
    push    ebx
    push    esi
    push    edi
    mov     edi,lpPoint
    mov     ebx,CursorOrg
    mov     esi,lpRect2
    API     GetCursorPos,edi
    API     GetWindowRect,[.hWnd],esi
    mov     eax,[edi+POINT.x]
    sub     eax,[ebx+POINT.x]
    add     eax,[esi+RECT.left]
    mov     edx,[edi+POINT.y]
    sub     edx,[ebx+POINT.y]
    add     edx,[esi+RECT.top]
    push    D [edi+POINT.x]
    pop     D [ebx+POINT.x]
    push    D [edi+POINT.y]
    pop     D [ebx+POINT.y]
    mov     ecx,[esi+RECT.right]
    sub     ecx,[esi+RECT.left]
    mov     ebx,[esi+RECT.bottom]
    sub     ebx,[esi+RECT.top]
    API     MoveWindow,[.hWnd],eax,edx,ecx,ebx,1
    pop     edi
    pop     esi
    pop     ebx
    jmp     .return
.wm_command:
    mov     eax,[.lParam]
    cmp     eax,[hBtnInstall]
    jnz     @F
    API     CreateThread,NULL,NULL,Unpack,NULL,NULL,ThreadID
    jmp     .return
 @@
    cmp     eax,[hBtnNfo]
    jnz     @F
    API     GetWindowLongA,[hBtnNfo],GWL_USERDATA
    and     eax, -2 ;not 1
    API     SetWindowLongA,[hBtnNfo],GWL_USERDATA,eax
    call    ShowNfo
    jmp     .return
 @@
    cmp     eax,[hBtnExit]
    jnz     .return
    API     DestroyWindow,[.hWnd]
    jmp     .return
.wm_setcursor:
    mov     eax,[.wParam]
    cmp     eax,[.hWnd]
    jnz     @F
    API     GetWindowLongA,[hBtnInstall],GWL_USERDATA
    and     eax,-2 ;not 1
    API     SetWindowLongA,[hBtnInstall],GWL_USERDATA,eax
    API     GetWindowLongA,[hBtnNfo],GWL_USERDATA
    and     eax,-2 ;not 1
    API     SetWindowLongA,[hBtnNfo],GWL_USERDATA,eax
    API     GetWindowLongA,[hBtnExit],GWL_USERDATA
    and     eax,-2 ;not 1
    API     SetWindowLongA,[hBtnExit],GWL_USERDATA,eax
    jmp     .return
 @@
    API     GetWindowLongA,eax,GWL_USERDATA
    or      eax,1
    API     SetWindowLongA,[.wParam],GWL_USERDATA,eax
    jmp     .return
.wm_ctlcolorbtn:
    API     SetBkMode,[.wParam],TRANSPARENT
    API     SetTextColor,[.wParam],TEXTCOLOR
    API     GetStockObject,NULL_BRUSH
    ret
.wm_create:
    API     ShowCursor,FALSE
    push    0
    push    44100
    push    IDX_MUSIC
    push    'YALP' ;NASM treats that constant differently than MASM
    call    _mfmres
    add     esp,4*4
    call    AddFont
    push    D [.hWnd]
    pop     D [hMainWnd]
    API     CreateWindowExA,WS_EX_TRANSPARENT,szBtnClass,szBtn1,\
                WS_CHILD+BS_OWNERDRAW+WS_VISIBLE+WS_DISABLED,\
                [rectInstall+RECT.left],[rectInstall+RECT.top],\
                [rectInstall+RECT.right],[rectInstall+RECT.bottom],\
                [.hWnd],IDC_MENU,MYINSTANCE,0
    mov     [hBtnInstall],eax
    API     CreateWindowExA,WS_EX_TRANSPARENT,szBtnClass,szBtn2,\
                WS_CHILD+BS_OWNERDRAW+WS_VISIBLE+WS_DISABLED,\
                [rectNfo+RECT.left],[rectNfo+RECT.top],\
                [rectNfo+RECT.right],[rectNfo+RECT.bottom],\
                [.hWnd],IDC_MENU,MYINSTANCE,0
    mov     [hBtnNfo],eax
    API     CreateWindowExA,WS_EX_TRANSPARENT,szBtnClass,szBtn3,\
                WS_CHILD+BS_OWNERDRAW+WS_VISIBLE+WS_DISABLED,\
                [rectExit+RECT.left],[rectExit+RECT.top],\
                [rectExit+RECT.right],[rectExit+RECT.bottom],\
                [.hWnd],IDC_MENU,MYINSTANCE,0
    mov     [hBtnExit],eax
    API     CreateThread,NULL,NULL,RenderThread,[.hWnd],0,ThreadID
    mov     [hThread],eax
    xor     eax,eax
    ret
.wm_keydown:
    cmp     D [.wParam],VK_ESCAPE
    jnz     .return
    API     DestroyWindow,[.hWnd]
    jmp     .return
WndProc endp
;***************************************************************************
AddFont proc
szTempPath localb 256
    enter
    saveregs ebx,esi,edi
    lea     esi,[.szTempPath]
    API     GetTempPathA,256,esi
    API     GetTempFileNameA,esi,szPrefix,0,szFontFileName
    API     FindResourceA,MYINSTANCE,IDF_FONT,RT_RCDATA
    push    eax
    API     SizeofResource,MYINSTANCE,eax
    mov     ebx,eax
    pop     eax
    API     LoadResource,MYINSTANCE,eax
    API     LockResource,eax
    mov     esi,eax
    API     CreateFileA,szFontFileName,GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
    inc     eax
    jnz     @F
    FATAL   "Cannot create temporary file!"
@@
    dec     eax
    push    eax
    lea     edx,[iWritten]
    API     WriteFile,eax,esi,ebx,edx,0
    call    [__imp__CloseHandle@4]
    API     AddFontResourceA,szFontFileName
    API     GetDC,[hMainWnd]
    push    eax
    push    D [hMainWnd]
    API     GetDeviceCaps,eax,LOGPIXELSY
    API     MulDiv,FONT_SIZE,eax,72
    neg     eax
    API     CreateFontA,eax,0,0,0,0,0,0,0,DEFAULT_CHARSET,\
                OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,PROOF_QUALITY,\
                FIXED_PITCH,szFontName
    mov     [hFont],eax
    test    eax,eax
    jnz     @F
    FATAL "Cannot create font!"
@@
    call    [__imp__ReleaseDC@8]
    ret
AddFont endp
;***************************************************************************
ReadConfig proc
    mov     esi,buff
    API     GetPrivateProfileStringA,szSection,szAppKey,NULL,esi,\
                MAX_PATH,szConfig
    mov     edi,szAppName
    align 4
.next_char:
    lodsb
    or      al,al
    jz      .string_end
    cmp     al,'|'
    jnz     .store_char
    mov     word [edi],0a0dh
    inc     edi
    inc     edi
    jmp     .next_char
.store_char:
    stosb
    jmp     .next_char
.string_end:
    mov     ebx,[__imp__GetPrivateProfileStringA@24]
    sc      ebx,szSection,szNfoKey,NULL,szNfoFile,\
                MAX_PATH,szConfig
    sc      ebx,szSection,szArchKey,NULL,szArchiveFile,\
                MAX_PATH,szConfig
    sc      ebx,szSection,szDirKey,NULL,szDestDir,\
                MAX_PATH,szConfig
    sc      ebx,szSection,szRunKey,NULL,szRunAfterInstall,\
                MAX_PATH,szConfig
    mov     [fRunAfterInstall],eax
    API     GetPrivateProfileIntA,szSection,szRunInDirKey,0,szConfig
    mov     [fRunInDestDir],eax
    ret
ReadConfig  endp
;***************************************************************************
ShowNfo proc
    API     CreateFileA,szNfoFile,GENERIC_READ,0,0,OPEN_EXISTING,0,0
    inc     eax
    jz      @F
    push    esi
    push    edi
    push    ebx
    mov     esi,eax
    API     GetFileSize,eax,NULL
    mov     edi,eax
    API     GlobalAlloc,64,eax
    mov     ebx,eax
    mov     [lpNfo],eax
    API     ReadFile,esi,ebx,edi,iWritten,NULL
    API     CloseHandle,esi
    API     DialogBoxParamA,MYINSTANCE,1000,[hMainWnd],NfoProc,0
    pop     ebx
    pop     edi
    pop     esi
@@
    ret
ShowNfo endp
;***************************************************************************
align 4
MyEditWndProc proc  hWnd,uMsg,wParam,lParam
    enter
    mov     eax,[.uMsg]
    cmp     eax,WM_CHAR
    jz      near .ret0
    cmp     eax,WM_SETFOCUS
    jz      near .ret0
    cmp     eax,WM_SETCURSOR
    jz      .wm_setcursor
    cmp     eax,WM_KEYDOWN
    jz      .wm_keydown
    cmp     eax,WM_RBUTTONDOWN
    jz      .ret0
    API     CallWindowProcA,[lpOldEditProc],[.hWnd],[.uMsg],[.wParam],[.lParam]
.ret0:
    ret
.ret1:
    xor     eax,eax
    inc     eax
    ret
.wm_setcursor:
    API     SetCursor,[wc+WNDCLASSEX.hCursor]
    jmp     short .ret1
.wm_keydown:
    cmp     D [.wParam],VK_DELETE
    jz      short .ret0
    API     GetParent,[.hWnd]
    API     SendMessageA,eax,[.uMsg],[.wParam],[.lParam]
    API     CallWindowProcA,[lpOldEditProc],[.hWnd],[.uMsg],[.wParam],[.lParam]
    ret
MyEditWndProc endp
;***************************************************************************
align 4
NfoProc proc hWnd,uMsg,wParam,lParam
    enter
    mov     eax,[.uMsg]
    cmp     eax,WM_CLOSE
    jz      .wm_close
    cmp     eax,WM_CTLCOLOREDIT
    jz      .wm_ctlcoloredit
    cmp     eax,WM_INITDIALOG
    jz      .wm_initdialog
    cmp     eax,WM_KEYDOWN
    jz      near .wm_keydown
    cmp     eax,WM_TIMER
    jz      .wm_timer
.ret0:
    xor     eax,eax
    ret
.wm_timer:
    cmp     dword [kierunek],1
    jz      @F
    API     SendMessageA,[hEdit],EM_SCROLL,SB_LINEDOWN,0
    jmp     short .check_eax
@@
    API     SendMessageA,[hEdit],EM_SCROLL,SB_LINEUP,0
.check_eax:
    or      eax,eax ;succesfull?
    jnz     @F
    xor     dword [kierunek],1 ;change direction
@@
    jmp     short .ret0
.wm_close:
    API     KillTimer,[.hWnd],1
    API     DeleteObject,[NfoBrush]
    API     GlobalFree,[lpNfo]
    API     EndDialog,[.hWnd],0
    jmp     .ret0
.wm_ctlcoloredit:
    API     SetTextColor,[.wParam],0070d0h
    API     SetBkColor,[.wParam],0
    API     CreateSolidBrush,0
    mov     [NfoBrush],eax
    ret
.wm_initdialog:
    push    ebx
    API     GetDlgItem,[.hWnd],100
    mov     ebx,eax
    mov     [hEdit],eax
    API     SetWindowLongA,ebx,GWL_WNDPROC,MyEditWndProc
    mov     [lpOldEditProc],eax
    API     GetStockObject,OEM_FIXED_FONT
    API     SendMessageA,ebx,WM_SETFONT,eax,TRUE
    API     SendMessageA,ebx,WM_SETTEXT,0,[lpNfo]
    API     SetTimer,[.hWnd],1,500,NULL
    pop     ebx
    jmp     .ret0
.wm_keydown:
    cmp     D [.wParam],VK_ESCAPE
    jnz     @F
    API     GlobalFree,[lpNfo]
    API     EndDialog,[.hWnd],0
@@
    xor     eax,eax
    ret
NfoProc endp
;***************************************************************************
GetFolderName proc lpDir,lpTitle
lpMalloc    locald 1
bi          local  BROWSEINFOA_size
pidl        locald 1
    enter
    saveregs esi
    lea     eax,[.lpMalloc]
    API     SHGetMalloc,eax
    lea     esi,[.bi]
    xor     eax,eax
    mov     ecx,[hMainWnd]
    mov     [esi+BROWSEINFOA.hwndOwner],ecx
    mov     [esi+BROWSEINFOA.pidlRoot],eax
    mov     ecx,[.lpDir]
    mov     [esi+BROWSEINFOA.pszDisplayName],ecx
    push    D [.lpTitle]
    pop     D [esi+BROWSEINFOA.lpszTitle]
    mov     D [esi+BROWSEINFOA.ulFlags],BIF_RETURNONLYFSDIRS | BIF_DONTGOBELOWDOMAIN | BIF_STATUSTEXT
    mov     [esi+BROWSEINFOA.lpfn],eax
    mov     [esi+BROWSEINFOA.lParam],eax
    mov     [esi+BROWSEINFOA.iImage],eax
    API     SHBrowseForFolderA,esi
    test    eax,eax
    jz      @F
    mov     [.pidl],eax
    API     SHGetPathFromIDListA,eax,[.lpDir]
    API     LocalFree,[.pidl]
    mov     eax,1
@@
    ret
GetFolderName endp
;***************************************************************************
Unpack:
%define destdir ebp-MAX_PATH
%define curdir ebp-2*MAX_PATH
    push    ebp
    mov     ebp,esp
    sub     esp,2*MAX_PATH
    CLEAR   [szUnpackDir],MAX_PATH
    mov     esi,[__imp__EnableWindow@8]
    sc      esi,[hBtnInstall],FALSE
    sc      esi,[hBtnNfo],FALSE
    sc      esi,[hBtnExit],FALSE
    mov     D [fUnpacking],1
    lea     eax,[curdir]
    API     GetCurrentDirectoryA,MAX_PATH,eax
    push    szDestDir
    push    szChooseDir
    push    buff
    call    [__imp__wsprintfA]
    add     esp,3*4
    sc		GetFolderName,szUnpackDir,buff
    or      eax,eax
    jz      near .exit
    push    szUnpackDir
    lea     eax,[destdir]
    push    eax
    call    _strcpy
    add     esp,8
    cmp     byte [destdir+eax-1],'\'
    jz      @F
    lea     eax,[destdir]
    sc      _strcat,eax,szTrailing
@@
    lea     eax,[destdir]
    sc      _strcat,eax,szDestDir
    lea     eax,[destdir]
    API     CreateDirectoryA,eax,NULL
    test    eax,eax
    jnz     @F
    API     MessageBoxA,[hMainWnd],szAlready,szQ,MB_ICONQUESTION+MB_YESNO
    cmp     eax,IDYES
    jz      @F
    jmp     .exit
@@
    lea     eax,[destdir]
    push    eax
    push    szArchiveFile
    call    _unace_decompress@8
    or      eax,eax
    jnz     @F
    API     MessageBoxA,[hMainWnd],szFailed,NULL,MB_ICONERROR
    jmp     .exit
@@
    cmp     D [fRunAfterInstall],0
    jz      near .exit
    API     MessageBoxA,[hMainWnd],szQuestion,szQ,MB_ICONQUESTION+MB_YESNO
    cmp     eax,IDYES
    jnz     .exit
    cmp     D [fRunInDestDir],0
    jz      .my_dir
    API     SetCurrentDirectoryA,szUnpackDir
    jmp     .af_dir
.my_dir:
    lea     eax,[curdir]
    API     SetCurrentDirectoryA,eax
.af_dir:
    API     ShellExecuteA,[hMainWnd],szOpen,szRunAfterInstall,\
                0,0,SW_SHOW
    cmp     eax,32
    ja      .exit
    API     MessageBoxA,[hMainWnd],szCantRun,NULL,MB_ICONERROR
.exit:
    lea     eax,[curdir]
    API     SetCurrentDirectoryA,eax
    mov     D [fUnpacking],0
    mov     esi,[__imp__EnableWindow@8]
    sc      esi,[hBtnInstall],TRUE
    sc      esi,[hBtnNfo],TRUE
    sc      esi,[hBtnExit],TRUE
    push    0
    push    0
    jmp     [__imp__ExitThread@4]
section .drectve info
db '-entry:START -defaultlib:kernel32.lib -defaultlib:user32.lib'
db ' -defaultlib:gdi32.lib -defaultlib:winmm.lib'
db ' -defaultlib:d:\lib\minifmod\minifmod.lib -defaultlib:d:\lib\unace\unace.lib'
db ' -defaultlib:d:\lib\libc\libc.lib -defaultlib:d:\lib\jpeglib\jpeglib.lib'
db ' -defaultlib:shell32.lib',0
