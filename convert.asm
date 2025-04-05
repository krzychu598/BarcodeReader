default rel
;=====================================================================
; ARKOC x86 - function converting line on given height to string of chars
; based on code39 barcode
;=====================================================================

; ImageInfo structure layout
img_width		EQU 0
img_height		EQU 4
img_linebytes	EQU 8
img_bitsperpel	EQU 12
img_pImg		EQU	16

section .data
chars db "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-._*"
loop_info db 0, 0, 0, 0, 0, 0 ; space, first, second, num, offset, end

section .text
global convert

load_byte:
    xor     rax, rax
    mov     r9, r8
    mov     al, bh
    add     al, bl
    movzx   eax, al             ; eax = x + y
    shr     eax, 3              ; eax - (x + y) / 8
    add     r9, rax             ; r9 - pPix + ((x + y) / 8)
    mov     al, [r9]            ; Load the byte at pPix + ((x + y) / 8) into al
    mov     ch, al
    not     ch
    ret

get_pixel:
    mov     cl, bh
    add     cl, bl
    and     cl, 7              ; cl = (x + y) % 8
    neg     cl                 ; cl = - ((x + y) % 8)
    add     cl, 7              ; cl = 7 - ((x + y) % 8)
    mov     al, 1  
    shl     al, cl             ; al = 1 << (7 - (x + y) % 8)
    and     al, ch             ; al = byte & (1 << (7 - (x + y) % 8))
    mov     cl, al
    ret 

convert:                        ;rdi - result buffer, rsi - height, rdx - pointer
    push    rbp
    mov     rbp, rsp

    push    rbx
    xor     rax, rax
    mov     r10, rdx
    mov     al, [r10 + img_linebytes]
    mul     rsi
    add     rax, [r10 + img_pImg]
    mov     r8, rax             ; r8 - pointer to first byte in image
    mov     r10, rdi            ;r10 - result buffer
    xor     rbx, rbx 

get_first_line:
    test    bh, 7
    jnz     skip_load
    call    load_byte
skip_load:
    call    get_pixel
    add     bh, 1
    test    cl, cl
    jz      get_first_line
    
    
    xor     bl, bl
    sub     bh, 14

process_characters:             ; Main loop
    add     bh, 13              ; Jump every 13 pixels
    mov     [loop_info], byte 0 ; space loc
    mov     [loop_info + 1], byte 0 ; first wide line loc
    mov     [loop_info + 2], byte 0 ; second wide line loc
    mov     [loop_info + 3], byte 0 ; what line are we at (num)
    mov     [loop_info + 4], byte 0 ; offset to identify character
    xor     bl, bl              ; bl - y
    xor     edx, edx            ; what line in char we at (max 6)

next_character:                 ; Inner loop
    inc     edx
    cmp     bl, 12
    jge     adjust_offsets
    call    load_byte

check_lines:
    call    get_pixel
    inc     bl
    test    cl, cl
    jz      is_space

is_line:
    mov     cl, bl
    add     cl, bh
    and     cl, 7
    jnz     do_not_load
    call    load_byte
do_not_load:
    call    get_pixel
    inc     bl
    test    cl, cl
    jz      next_character
is_wide:
    inc     bl
    mov     cl, [loop_info + 1]
    test    cl, cl
    jz      first_wide
    mov     [loop_info + 2], dl ; second wide
    jmp     next_character
first_wide:
    mov     [loop_info + 1], dl ; first wide
    jmp     next_character
is_space:
    mov     [loop_info], dl     ; space
    jmp     next_character

adjust_offsets:
    xor     bl, bl
    mov     dl, [loop_info]
    mov     cl, [loop_info + 1]
    mov     ch, [loop_info + 2]
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

switch_three:
    cmp     ch, 4
    je      add_nine
    add     bl, 3
    jmp     got

switch_two:
    cmp     ch, 3
    je      add_five
    cmp     ch, 4
    je      add_eight
    inc     bl
    jmp     got

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

    mov     dl, byte [loop_info + 5]
    test    dl, dl
    jnz     fin

    inc     dl               ; end = 1
    mov     [loop_info + 5], dl
    jmp     process_characters

store_character:
    movzx   rsi, bl
    lea     r9, [rsi+chars]
    mov     bl, [r9]
    mov     [r10], bl
    inc     r10
    jmp     process_characters

fin:
    mov     byte [r10], 0
    lea     rax, [rdi]
    mov     byte [loop_info + 5], 0

    pop     rbx
    mov     rsp, rbp
    pop     rbp
    ret
