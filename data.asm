DATASEG
szClassName:    db  "Quasar's installer", 0
szDisplayName:  db "HTB Install System v1.0",0
wc:
istruc WNDCLASSEX
    at WNDCLASSEX.cbSize,       dd  WNDCLASSEX_size
    at WNDCLASSEX.style,        dd  CS_VREDRAW + CS_HREDRAW
    at WNDCLASSEX.lpfnWndProc,  dd  WndProc
    at WNDCLASSEX.cbClsExtra,   dd  0
    at WNDCLASSEX.cbWndExtra,   dd  0
    at WNDCLASSEX.hInstance,    dd  0
    at WNDCLASSEX.hIcon,        dd  0
    at WNDCLASSEX.hCursor,      dd  0
    at WNDCLASSEX.hbrBackground,dd  COLOR_WINDOW
    at WNDCLASSEX.lpszMenuName, dd  0
    at WNDCLASSEX.lpszClassName,dd  szClassName
    at WNDCLASSEX.hIconSm,      dd  0
iend
szFontName: db "amiga",0
szBtnClass: db "BUTTON",0
szBtn1: db  "Install",0
szBtn2: db  "Nfo",0
szBtn3: db  "Exit",0
szUnpacking: db "Installing...",0
szPrefix:   db "HTB",0
szSection:  db "installer",0
szConfig:   db ".\install.cfg",0
szAppKey:   db "appname",0
szNfoKey:   db "nfo",0
szArchKey:  db "archive",0
szDirKey:   db "dir",0
szRunKey:   db "runafterinstall",0
szRunInDirKey: db "runindestdir",0
szChooseDir: db 'Choose destination directory. Subdirectory "%s" will be created automatically...',0
szTrailing:  db '\',0
szOpen:     db 'open',0
szCantRun:  db "Cannot run file after install!",0
szQ: db "Question...",0
szAlready: db "Specified directory already exist.",CRLF,\
        "Do you want to continue?",0
szFailed:   db "Extraction failed!",0
szQuestion: db "Run installed app?",0
rectInstall:
istruc RECT
    at  RECT.left,  dd 5
    at  RECT.top,   dd 180
    at  RECT.right, dd  55
    at  RECT.bottom,dd  20
iend
rectNfo:
istruc RECT
    at  RECT.left,  dd 145
    at  RECT.top,   dd 180
    at  RECT.right, dd 25
    at  RECT.bottom,dd 20
iend
rectExit:
istruc RECT
    at  RECT.left,  dd 280
    at  RECT.top,   dd 180
    at  RECT.right, dd 30
    at  RECT.bottom,dd 20
iend
rectApp:
istruc RECT
    at  RECT.left,  dd 5
    at  RECT.top,   dd 120
    at  RECT.right, dd 315
    at  RECT.bottom,dd 100
iend
UnpRect:
istruc RECT
    at  RECT.left,  dd 5
    at  RECT.top,   dd 130
    at  RECT.right, dd 315
    at  RECT.bottom,dd 100
iend
UDATASEG
hMainWnd:       resd 1
hFont:          resd 1
lpNfo:          resd 1
hEdit:          resd 1
iWritten:       resd 1
hBtnInstall:    resd 1
hBtnNfo:        resd 1
hBtnExit:       resd 1
hThread:        resd 1
ThreadID:       resd 1
fRemoveThread:  resd 1
kierunek:       resd 1
szFontFileName: resb MAX_PATH
szUnpackDir:    resb MAX_PATH
szAppName:      resb MAX_PATH
szNfoFile:      resb MAX_PATH
szArchiveFile:  resb MAX_PATH
szDestDir:      resb MAX_PATH
szRunAfterInstall:  resb MAX_PATH
buff:           resb MAX_PATH
fRunInDestDir:  resd 1
fRunAfterInstall:   resd 1
fUnpacking:     resd 1
NfoBrush:       resd 1
CursorOrg:      resd POINT_size
lpPoint:        resd POINT_size
lpRect:         resd RECT_size
lpRect2:        resd RECT_size
fMovingEnable:  resd 1
msg:            resd MSG_size
lpOldEditProc:  resd 1

CODESEG
