RenderThread proc hWnd
hBackBMP    locald 1
ppvBits1    locald 1
ppvBits2    locald 1
indexy      locald 1
pbmi        localb  BITMAPINFO_size
BMStruct    localb  JPEG_STRUCTURE_size
    enter
    lea     eax,[.BMStruct]
    API     Res2BMP,MYINSTANCE,104,eax

    mov     esi,[.BMStruct+JPEG_STRUCTURE.lpBitMap]

    API     GlobalAlloc,64,320*120*4
    mov     [.ppvBits2],eax
    mov     edi,eax
    mov     ecx,(320*120*4)>> 6
@@
    movq    mm0, [esi]
    add     edi, 64
    movq    mm1, [esi+8]
    add     esi, 64
    movq    mm2, [esi-48]
    movq    [edi-64], mm0
    movq    mm3, [esi-40]
    movq    [edi-56], mm1
    movq    mm4, [esi-32]
    movq    [edi-48], mm2
    movq    mm5, [esi-24]
    movq    [edi-40], mm3
    movq    mm6, [esi-16]
    movq    [edi-32], mm4
    movq    mm7, [esi-8]
    movq    [edi-24], mm5
    movq    [edi-16], mm6
    dec     ecx
    movq    [edi-8], mm7
    jnz     @B

    lea     eax,[.BMStruct]
    API     Kill_JPEG,eax

    API     GetDC,[.hWnd]
    mov     edi,eax
    API     CreateCompatibleDC,eax
    mov     esi,eax

    lea     edx,[.pbmi]
    sub     eax,eax
    mov     D [edx+BITMAPINFO.bmiHeader.biSize],BITMAPINFOHEADER_size
    mov     D [edx+BITMAPINFO.bmiHeader.biWidth],320
    mov     D [edx+BITMAPINFO.bmiHeader.biHeight],-201
    mov     W [edx+BITMAPINFO.bmiHeader.biPlanes],1
    mov     W [edx+BITMAPINFO.bmiHeader.biBitCount],32
    mov     D [edx+BITMAPINFO.bmiHeader.biCompression],BI_RGB
    mov     D [edx+BITMAPINFO.bmiHeader.biSizeImage],320*200*4
    mov     [edx+BITMAPINFO.bmiHeader.biXPelsPerMeter],eax
    mov     [edx+BITMAPINFO.bmiHeader.biYPelsPerMeter],eax
    mov     [edx+BITMAPINFO.bmiHeader.biClrUsed],eax
    mov     [edx+BITMAPINFO.bmiHeader.biClrImportant],eax
    mov     [edx+BITMAPINFO.bmiColors],eax
    lea     eax,[.ppvBits1]
    API     CreateDIBSection,esi,edx,DIB_RGB_COLORS,eax,NULL,NULL
    mov     [.hBackBMP],eax

    API     SelectObject,esi,eax
    API     SelectObject,esi,[hFont]
    API     SetBkMode,esi,TRANSPARENT

    mov     eax,00FFFFFFh
    ;fade in logo bitmap
    align 4
.fade_in:
    mov     ebx,[.ppvBits2]
    mov     edx,[.ppvBits1]
    mov     ecx,((SCREENX*120*4)>>3)-1
    movd    mm1,eax
    punpcklwd mm1,mm1
    punpckldq mm1,mm1
    align 4
@@
    movq mm0,[ebx+ecx*8] ;RGB | RGB | RGB | RGB
    psubusb mm0,mm1
    movq    [edx+ecx*8],mm0
    dec     ecx
    jns     @B
    push    eax
    API     BitBlt,edi,0,0,SCREENX,SCREENY,esi,0,0,SRCCOPY
    pop     eax
    sub     eax,10101h
    jns     .fade_in
    ;main loop
    API     SendMessageA,[.hWnd],WM_GO,0,0
    mov     D [.indexy],0
    align 4
.main_loop:
    cmp     D [fRemoveThread],1
    jz      near .exit
    API     Sleep,50

    API     GetStockObject,BLACK_BRUSH
    mov     D [lpRect+RECT.top],0
    mov     D [lpRect+RECT.left],0
    mov     D [lpRect+RECT.right],320
    mov     D [lpRect+RECT.bottom],240
    API     FillRect,esi,lpRect,eax
    ; do a scroll
    mov     eax,D [.indexy]
    test    eax,eax
    js      @F
    inc     eax
    inc     eax
    cmp     eax,20
    jna     short .endif
    or      eax,0x80000000
    jmp     short .endif
@@
    dec     eax
    dec     eax
    test    eax,0x7FFFFFFF
    jnz     .endif
    and     eax,0x7FFFFFFF
.endif:
    mov     D [.indexy],eax
;   and     eax,0x7FFFFFFF
    cdq
    mov     ecx,320*4
    mul     ecx
    mov     ecx,(320*120*4)
    sub     ecx,eax
    shr     ecx,6
    ; copy logo image to backbuffer
    add     eax,[.ppvBits2]
    mov     edx,[.ppvBits1]
    align 4
@@
    movq    mm0, [eax]
    add     edx, 64
    movq    mm1, [eax+8]
    add     eax, 64
    movq    mm2, [eax-48]
    movq    [edx-64], mm0
    movq    mm3, [eax-40]
    movq    [edx-56], mm1
    movq    mm4, [eax-32]
    movq    [edx-48], mm2
    movq    mm5, [eax-24]
    movq    [edx-40], mm3
    movq    mm6, [eax-16]
    movq    [edx-32], mm4
    movq    mm7, [eax-8]
    movq    [edx-24], mm5
    movq    [edx-16], mm6
    dec     ecx
    movq    [edx-8], mm7
    jnz     @B
    cmp     D [fUnpacking],1
    jnz     near .draw_btns

    mov     edx,[UnpRect+RECT.right]
    mov     ecx,[UnpRect+RECT.left]
    add     edx,ecx
    mov     [lpRect+RECT.right],edx
    mov     [lpRect+RECT.left],ecx
    mov     edx,[UnpRect+RECT.bottom]
    mov     ecx,[UnpRect+RECT.top]
    add     edx,ecx
    mov     [lpRect+RECT.bottom],edx
    mov     [lpRect+RECT.top],ecx
    push    TEXTCOLOR
    push    esi
    call    [__imp__SetTextColor@8]
    API     DrawTextA,esi,szUnpacking,-1,lpRect,\
                DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
    push    00A00000h
    push    esi
    call    [__imp__SetTextColor@8]
    inc     D [lpRect+RECT.left]
    inc     D [lpRect+RECT.top]
    API     DrawTextA,esi,szUnpacking,-1,lpRect,\
                DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
    jmp .blit_it
.draw_btns:
    ; buttony
    mov     edx,[rectInstall+RECT.right]
    mov     ecx,[rectInstall+RECT.left]
    add     edx,ecx
    mov     [lpRect+RECT.right],edx
    mov     [lpRect+RECT.left],ecx
    mov     edx,[rectInstall+RECT.bottom]
    mov     ecx,[rectInstall+RECT.top]
    add     edx,ecx
    mov     [lpRect+RECT.bottom],edx
    mov     [lpRect+RECT.top],ecx
    push    00A00000h
    push    esi
    call    [__imp__SetTextColor@8]
    API     DrawTextA,esi,szBtn1,-1,lpRect,\
            DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
    API     GetWindowLongA,[hBtnInstall],GWL_USERDATA
    test    eax,1
    jz      .normal1
    push    00ffffffh
    jmp     .setcolor1
.normal1:
    push    TEXTCOLOR
.setcolor1:
    push    esi
    call    [__imp__SetTextColor@8]
    inc     D [lpRect+RECT.left]
    inc     D [lpRect+RECT.top]
    API     DrawTextA,esi,szBtn1,-1,lpRect,\
            DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
    mov     edx,[rectNfo+RECT.right]
    mov     ecx,[rectNfo+RECT.left]
    add     edx,ecx
    mov     [lpRect+RECT.right],edx
    mov     [lpRect+RECT.left],ecx
    mov     edx,[rectNfo+RECT.bottom]
    mov     ecx,[rectNfo+RECT.top]
    add     edx,ecx
    mov     [lpRect+RECT.bottom],edx
    mov     [lpRect+RECT.top],ecx
    push    00A00000h
    push    esi
    call    [__imp__SetTextColor@8]
    API     DrawTextA,esi,szBtn2,-1,lpRect,\
                DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
    API     GetWindowLongA,[hBtnNfo],GWL_USERDATA
    test    eax,1
    jz      .normal2
    push    00ffffffh
    jmp     .setcolor2
.normal2:
    push    TEXTCOLOR
.setcolor2:
    push    esi
    call    [__imp__SetTextColor@8]
    inc     D [lpRect+RECT.left]
    inc     D [lpRect+RECT.top]
    API     DrawTextA,esi,szBtn2,-1,lpRect,\
                DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
    mov     edx,[rectExit+RECT.right]
    mov     ecx,[rectExit+RECT.left]
    add     edx,ecx
    mov     [lpRect+RECT.right],edx
    mov     [lpRect+RECT.left],ecx
    mov     edx,[rectExit+RECT.bottom]
    mov     ecx,[rectExit+RECT.top]
    add     edx,ecx
    mov     [lpRect+RECT.bottom],edx
    mov     [lpRect+RECT.top],ecx
    push    00A00000h
    push    esi
    call    [__imp__SetTextColor@8]
    API     DrawTextA,esi,szBtn3,-1,lpRect,\
                DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
    API     GetWindowLongA,[hBtnExit],GWL_USERDATA
    test    eax,1
    jz      .normal3
    push    00ffffffh
    jmp     .setcolor3
.normal3:
    push    TEXTCOLOR
.setcolor3:
    push    esi
    call    [__imp__SetTextColor@8]
    inc     D [lpRect+RECT.left]
    inc     D [lpRect+RECT.top]
    API     DrawTextA,esi,szBtn3,-1,lpRect,\
                DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
    mov     edx,[rectApp+RECT.right]
    mov     ecx,[rectApp+RECT.left]
    add     edx,ecx
    mov     [lpRect+RECT.right],edx
    mov     [lpRect+RECT.left],ecx
    mov     edx,[rectApp+RECT.bottom]
    mov     ecx,[rectApp+RECT.top]
    add     edx,ecx
    mov     [lpRect+RECT.bottom],edx
    mov     [lpRect+RECT.top],ecx
    push    TEXTCOLOR
    push    esi
    call    [__imp__SetTextColor@8]
    API     DrawTextA,esi,szAppName,-1,lpRect,\
                DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
    push    00A00000h
    push    esi
    call    [__imp__SetTextColor@8]
    inc     D [lpRect+RECT.left]
    inc     D [lpRect+RECT.top]
    API     DrawTextA,esi,szAppName,-1,lpRect,\
                DT_CENTER | DT_VCENTER | DT_NOCLIP | DT_NOPREFIX
        ; z backbuffera na screen
.blit_it:
    API     BitBlt,edi,0,0,320,240,esi,0,0,SRCCOPY
    jmp     .main_loop
.exit:
    emms
    API     DeleteObject,[.hBackBMP]
    API     DeleteDC,esi
    API     ReleaseDC,[.hWnd],edi
    API     GlobalFree,[.ppvBits2]
    API     ExitThread,0;no return because ExitThread never returns!
RenderThread    endp

