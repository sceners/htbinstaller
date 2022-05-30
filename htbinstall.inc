bits 32
%INCLUDE "windows.inc"
%include "api\kernel32.inc"
%include "api\user32.inc"
%include "api\gdi32.inc"
%include "api\shell32.inc"
;***************************************************************************
;GLOBALS
global _strlen@4
global _strcpy
;***************************************************************************
;EXTERNS
externdef mfmres
externdef unace_decompress@8
externdef Kill_JPEG@4
externdef Res2BMP@12
externdef _imp__wsprintfA
Kill_JPEG   PROTO 1
Res2BMP     PROTO 1,1,1
externdef _imp__EnableWindow@8
;***************************************************************************
;MACROS
%macro CLEAR 2
    lea edi,%1
    mov ecx,%2
    xor eax,eax
    rep stosb
%endmacro

%macro  FATAL 1+
    section .data
    %%msg:  db  %1, 0
    section .text
    API MessageBoxA,[hMainWnd],%%msg,NULL,MB_ICONERROR
    API ExitProcess,0
%endmacro
;***************************************************************************
;DEFINES
%define D dword
%define B byte
%define W word
;***************************************************************************
;STRUCURES
struc JPEG_STRUCTURE
.dwWidth:   resd 1      ;Width of the picture
.dwHeight:  resd 1      ;Height of the picture
.BMPWidth:  resd 1      ;Width of the bitmap
.BMPHeight: resd 1      ;Height of the bitmap
.lpBitMap:  resd 1      ;Bitmap address
endstruc
;***************************************************************************
;EQUATES
;%define DEBUG
%define CRLF 0dh,0ah

SCREENX     EQU 320
SCREENY     EQU 200
IDF_FONT    EQU 101
IDC_MENU    EQU 102
IDX_MUSIC   EQU 103
TEXTCOLOR   EQU 00FF0000h
FONT_SIZE   EQU 12
WM_GO       EQU WM_USER+1
MYINSTANCE  EQU 00400000h


