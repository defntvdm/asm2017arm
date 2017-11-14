.globl main
.text
main:
    push    {lr}
    cmp     r0, #3
    ldr     r2, [r1]
    ldr     r3, =name_addr
    str     r2, [r3]
    bne     error
    @ само число
    ldr     r0, [r1, #4]
    push    {r1}
    bl      atoi
    pop     {r1}
    ldr     r2, =number
    str     r0, [r2]
    @ система счисления
    ldr     r0, [r1, #8]
    bl      atoi
    cmp     r0, #32
    bgt     error
    cmp     r0, #2
    blt     error 
    ldr     r1, =ns
    str     r0, [r1]
    
    ldr     r0, =number
    ldr     r0, [r0] @ Число
    ldr     r1, =ns
    ldr     r1, [r1] @ Система счисления
    mov     r4, #0   @ Счётчик цифр
digits_to_stack:
    mov     r2, r0
    udiv    r0, r0, r1
    mul     r3, r0, r1
    sub     r2, r2, r3
    push    {r2}
    add     r4, r4, #1
    cmp     r0, #0
    bne     digits_to_stack

printuem:
    pop     {r1}
    ldr     r2, =symbols
    add     r1, r2, r1
    ldrb    r1, [r1]
    ldr     r0, =print_format
    push    {r4}
    bl      printf
    pop     {r4}
    subs    r4, r4, #1
    bne     printuem

    ldr     r0, =end_line
    bl      printf
    mov     r0, #0
    pop     {pc}

error:
    ldr     r0, =usage
    ldr     r1, =name_addr
    ldr     r1, [r1]
    bl      printf
    pop     {pc}

.data
symbols:
    .asciz  "0123456789ABCDEFGHIJKLMNOPQRSTUV"
usage:
    .asciz  "Usage: %s number number_system\n\nnumber          Число для перевода(от -2147483648 до 2147483647)\nnumber_system   Система счисления(от 2 до 32)\n"
number:
    .long   0
ns:
    .int    0
print_format:
    .asciz  "%c"
end_line:
    .asciz  "\n"
name_addr:
    .int    0
