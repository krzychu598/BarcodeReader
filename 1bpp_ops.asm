default rel
;=====================================================================
; ARKOC x86 - function converting line of given y to string of chars
; fixed when first line is to the right
;=====================================================================

; ImageInfo structure layout
img_width		EQU 0
img_height		EQU 4
img_linebytes	EQU 8
img_bitsperpel	EQU 12
img_pImg		EQU	16

section .data
chars db "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-._*"
loop_info db 0, 0, 0, 0, 0, 0, 0 ;space, first, second, num, offset, pos, end

section	.text
global  readcode_1bpp

                        
load_byte:
;(*(pPix + (x+y) / 8))              
;bh - x, bl - y, ch result byte, eax - address of first byte
    push rsi
    push rax
    push rdi
    mov     edi, eax
    mov     dh, [eax]

load:
    mov     al, bh              
    add     al, bl             
    movzx   eax, al             ;eax = x+y
    shr     eax, 3              ;eax - (x+y)/8
    add     edi, eax            ;ecx - pPix + ((x+y) / 8)
    mov     ch, [edi]      ;Load the byte at pPix + ((x+y) / 8) into ch
    not     ch
    pop rdi
    pop rax
    pop rsi

    ret

            
get_pixel:
;byte & (1 << (7 - x % 8)))
;bh - x, bl - y, ch byte, cl result bit
    push rbp
    mov rbp, rsp
    push rsi
    push rax

    mov     cl, bh
    add     cl, bl
    and     cl, 7              ;al = (x+y) % 8
    neg     cl                 ;al = - ((x+y) % 8)
    add     cl, 7              ;al = 7 - ((x+y)%8)
    mov     al, 1  
    shl     al, cl           ; cl = 1 << (7 - (x+y) % 8)
    and     al, ch           ; cl = byte & (1 << (7 - (x+y) % 8))

    mov     cl, al
    pop rax
    pop rsi
    mov rsp, rbp
    pop rbp
    ret

readcode_1bpp:
    sub     rsp, 8 
    push    rbx
    push    rdi
    push    rsi
    ;rcx                            ;pImg
    ;rdx                            ;height
    ;r8             	            ;result buffer;
    mov rax, img_linebytes[rcx] 
    mul rdx
    add rax, img_pImg[rcx]			; eax <- address of first char
    xor     rbx, rbx
    mov     bh, -1

get_first_line:
    add bh, 1
    test bh, 7
    jnz skip_load
    call load_byte
skip_load:
    call get_pixel
    test cl, cl
    jz  get_first_line

    mov bl, 0
    sub bh, 13
process_characters:                     ;main loop
    add     bh, 13                     ;jump every 13 pixels
    mov     [loop_info+ 0], byte 0           ;space loc
    mov     [loop_info+ 1], byte 0           ;first wide line loc
    mov     [loop_info+ 2], byte 0           ;second wide line loc
    mov     [loop_info+ 3], byte 0           ;what line are we at (num)
    mov     [loop_info+ 4], byte 0           ;offset to identify character
    xor     bl, bl                      ;bl - y
    xor     edx, edx                   ;what line in char we at (max 6)


next_character:                         ;inner loop
    inc     edx                         ;in ch - byte, in cl - pixel, bh - x - doesn't change, bl - y
    cmp     bl, 12
    jge     adjust_offsets
    call    load_byte                   


check_lines:
    call    get_pixel 
    inc     bl
    test    cl, cl
    jz      is_space

is_line:
    mov     cl, bl      ;if new byte, load it
    add     cl, bh
    and     cl, 7
    jnz     do_not_load
    call     load_byte 
do_not_load:
    call    get_pixel 
    inc     bl
    test    cl, cl
    jz      next_character
is_wide:
    inc     bl
    mov     cl, [loop_info +1]
    test    cl, cl
    jz      first_wide
    mov     [loop_info + 2], dl      ;second wide
    jmp     next_character
first_wide:
    mov     [loop_info + 1], dl        ;first wide
    jmp     next_character
is_space:
    mov     [loop_info], dl            ;space
    jmp     next_character


adjust_offsets:
    ; dl - space, cl - first, ch - second, bl - offset
    xor     bl, bl
    mov     dl, [loop_info]
    mov     cl, [loop_info+1]
    mov     ch, [loop_info+2]
    cmp     [loop_info], ch
    jg      space_adjust
    dec     ch
    cmp     [loop_info], cl
    jg      space_adjust
    dec     cl
    

space_adjust:
    cmp     dl, 4
    je      plus_ten
    cmp     dl, 5
    je      plus_twenty
    cmp     dl, 2
    jne     handle_first

plus_thirty:
    add     bl, 10
plus_twenty:
    add     bl, 10
plus_ten:
    add     bl, 10

handle_first:
    cmp     cl, 1
    je      switch_one
    cmp     cl, 2
    je      switch_two
    cmp     cl, 3
    je      switch_three

    ;pair 4-5
    add     bl, 6
    jmp     got

    ;3-4, 3-5
switch_three:
    cmp     ch, 4
    je      add_nine
    add     bl, 3
    jmp     got

    ;2-3, 2-4, 2-5
switch_two:
    cmp     ch, 3
    je      add_five
    cmp     ch, 4
    je      add_eight
    inc     bl
    jmp     got

    ;1-2, 1-3, 1-4, 1-5
switch_one:
    cmp     ch, 2
    je      add_two
    cmp     ch, 3
    je      add_four
    cmp     ch, 4
    je      add_seven
    jmp     got

add_nine:
    inc     bl
add_eight:
    inc     bl
add_seven:
    add     bl, 2
add_five:
    inc     bl
add_four:
    add     bl, 2
add_two:
    add     bl, 2

got:
    cmp     bl, 39
    jne     store_character

    mov     dl, byte [loop_info+6]
    test    dl, dl
    jnz      fin

    inc     dl               ; end = 1
    mov     [loop_info+6], dl
    jmp     process_characters

store_character:
    movzx   esi, bl
    mov     bl, [chars+esi]
    mov     byte [edi], bl
    inc     edi
    jmp     process_characters

fin:
    mov     byte [edi], 0
    mov     rax, r8
    mov     byte [loop_info+6], 0
        
    
    pop    rsi
    pop    rdi
    pop    rbx
    add    rsp, 8
    ret
