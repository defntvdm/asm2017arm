.globl _start
.text
_start:
    mov     r0, #1
    ldr     r1, =clear
    mov     r2, #clear_len
    mov     r7, #4
    svc     #0

    ldr     r0, [sp]
    cmp     r0, #3
    bne     error_args

    ldr     r0, [sp, #12]
    bl      strlen
    ldr     r1, =len
    str     r0, [r1]

    ldr     r0, [sp, #8]
    mov     r1, #0
    mov     r7, #5
    svc     #0

    cmp     r0, #0
    blt     error_file

    ldr     r1, =handler
    str     r0, [r1]

    mov     r6, #0

read_row:
    ldr     r0, =buffer
    bl      strlen
    add     r6, r6, r0
    ldr     r1, =buffer
    read_row_loop:
        mov     r0, r1
        bl      read_byte
        cmp     r0, #0
        beq     file_ended
        ldrb    r0, [r1], #1
        cmp     r0, #10
        bne     read_row_loop
    read_done:
    mov     r0, #0
    strb    r0, [r1]

    ldr     r0, =buffer
    ldr     r1, [sp, #12]
    bl      strstr
    cmp     r0, #-1
    beq     read_row
@ Тут типа адекватный обработчик найденного (он не особо адекватный скорее всего)
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    bl      print_address
@ выводим часть где точно нет вхождения
@ в r0 у нас смещение substr относительно r1
@ r1 указатель на текущую часть строки
    ldr     r1, =buffer
    printer:
        cmp     r0, #-1
        beq     printed
        mov     r2, r0
        mov     r0, #1
        mov     r7, #4
        svc     #0

        push    {r0, r1}
        mov     r0, #1
        ldr     r1, =substr
        mov     r2, #substr_len
        mov     r7, #4
        svc     #0
        pop     {r0, r1}

        add     r1, r1, r0

        mov     r0, #1
        ldr     r2, =len
        ldr     r2, [r2]
        mov     r7, #4
        svc     #0

        push    {r0, r1}
        mov     r0, #1
        ldr     r1, =normalize
        mov     r2, #normalize_len
        mov     r7, #4
        svc     #0
        pop     {r0, r1}

        add     r1, r1, r0

        push    {r1}
        mov     r0, r1
        ldr     r1, [sp, #16]
        bl      strstr
        pop     {r1}
        b       printer

    printed:
        mov     r0, r1
        bl      strlen
        mov     r2, r0
        mov     r0, #1
        mov     r7, #4
        svc     #0


    @ldr     r0, =buffer
    @mov     r1, r0
    @bl      strlen
    @mov     r2, r0
    @ldr     r1, =buffer
    @mov     r0, #1
    @mov     r7, #4
    @svc     #0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    ldr     r0, =file_readed
    ldr     r0, [r0]
    cmp     r0, #0
    beq     search_end
    b       read_row

file_ended:
    ldr     r2, =buffer
    cmp     r1, r2
    mov     r0, #0
    beq     search_end
    mov     r0, #10
    strb    r0, [r1], #1
    ldr     r2, =file_readed
    mov     r0, #0
    str     r0, [r2]
    b       read_done

error_args:
    mov     r0, #1
    ldr     r1, =usage1
    mov     r2, #usage1_len
    mov     r7, #4
    svc     #0

    ldr     r0, [sp, #4]
    bl      strlen
    mov     r2, r0
    ldr     r1, [sp, #4]
    mov     r0, #1
    mov     r7, #4
    svc     #0

    mov     r0, #1
    ldr     r1, =usage2
    mov     r2, #usage2_len
    mov     r7, #4
    svc     #0

    mov     r0, #2
    b       exit

error_file:
    mov     r0,#1
    ldr     r1, =file_not_found
    mov     r2, #file_not_found_len
    mov     r7, #4
    svc     #0

    mov     r0, #2
    b       exit

search_end:
    mov     r0, #1
    ldr     r1, =sdone
    mov     r2, #sdone_len
    mov     r7, #4
    svc     #0

    mov     r0, #0

exit:
    mov     r7, #1
    svc     #0

@ r6 - адресс
print_address:
    push    {r0, r1, r2, r3, r6, lr}
    
    mov     r0, #1
    ldr     r1, =address
    mov     r2, #address_len
    mov     r7, #4
    svc     #0

    mov     r0, #16
    mov     r3, #8
    digits_to_stack:
        udiv    r2, r6, r0
        mul     r1, r2, r0
        sub     r6, r6, r1
        push    {r6}
        mov     r6, r2
        subs    r3, r3, #1
        bne     digits_to_stack
    mov     r3, #8
    print_digits:
        mov     r0, #1
        ldr     r1, =alph
        pop     {r2}
        add     r1, r1, r2
        mov     r2, #1
        mov     r7, #4
        svc     #0
        subs    r3, r3, #1
        bne     print_digits
    mov     r0, #1
    ldr     r1, =normalize
    mov     r2, #normalize_len
    mov     r7, #4
    svc     #0

    mov     r0, #1
    ldr     r1, =alph
    add     r1, r1, #16
    mov     r2, #1
    mov     r7, #4
    svc     #0
    pop     {r0, r1, r2, r3, r6, pc}

@ *str, *substr
strstr:
    push    {r1, r2, r3, r4, r5, lr}
    mov     r4, #0
    mov     r5, #0
    ldrb    r3, [r1]
    strstr_loop:
        ldrb    r2, [r0], #1
        add     r5, #1
        cmp     r2, #0
        beq     str_not_found
        cmp     r2, r3
        beq     first_letter
        sub     r0, r0, r4
        sub     r5, r5, r4
        mov     r4, #0
        ldrb    r3, [r1]
        b       strstr_loop
    first_letter:
        add     r4, r4, #1
        ldrb    r3, [r1, r4]
        cmp     r3, #0
        bne     strstr_loop
    str_found:
        sub     r5, r5, r4
        mov     r0, r5
        pop     {r1, r2, r3, r4, r5, pc}
    str_not_found:
        mov     r0, #-1
        pop     {r1, r2, r3, r4, r5, pc}
@ *memory
read_byte:
    push    {r1, r2, lr}
    mov     r1, r0
    ldr     r0, =handler
    ldr     r0, [r0]
    mov     r2, #1
    mov     r7, #3
    svc     #0
    pop     {r1, r2, pc}

@ *str
strlen:
    push    {r1, r2, lr}
    mov     r2, #0
    strlen_loop:
        ldrb     r1, [r0, r2]
        cmp     r1, #0
        beq     done
        add     r2, r2, #1
        b       strlen_loop
    done:
    mov     r0, r2
    pop     {r1, r2, pc}

.data
sdone: .ascii "Search done\n"
sdone_len = . - sdone
clear: .ascii "\033[2J\033[100A"
clear_len = . - clear
file_not_found: .ascii "\nFile not found!\n\n"
file_not_found_len = . - file_not_found
len: .int 0
alph: .ascii "0123456789ABCDEF:"
FOUND: .ascii "FOUND\n"
file_readed: .int  1
handler: .int   0
usage1: .ascii "\nUsage: "
usage1_len = . - usage1
usage2: .ascii " file_name substr\n\n"
usage2_len = . - usage2
address: .ascii "\033[32m"
address_len = . - address
substr: .ascii "\033[1;31m"
substr_len = . - substr
normalize: .ascii "\033[0m"
normalize_len = . - normalize
.comm   buffer, 10000, 4
