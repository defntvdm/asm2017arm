.globl main
.text

#define uart_base       0x01c28000
#define uart1_offset    0x0400
#define uart_bit        1 << 17
#define ccu_base        0x01c20000
#define O_RDWR          00000002
#define O_DSYNC         00010000
#define MAP_SHARED      1
#define PROT_READ       1
#define PROT_WRITE      2

main:
    push    {lr}
    ldr     r0, =mem
    ldr     r1, =O_RDWR | O_DSYNC
    bl      open
    
    cmp     r0, #0
    blt     sudo_error

    ldr     r1, =ccu_base
    push    {r1}
    push    {r0}
    mov     r0, #0
    mov     r1, #4096
    mov     r2, #PROT_READ | PROT_WRITE
    mov     r3, #MAP_SHARED
    bl      mmap
    @ Часики для UART1
    ldr     r1, [r0, #0x006C]
    ldr     r2, =uart_bit
    orr     r1, r2
    str     r1, [r0, #0x006C]
    @ Сброс UART1
    ldr     r1, [r0, #0x02D8]
    orr     r1, r2
    str     r1, [r0, #0x02D8]

    pop     {r0}
    pop     {r1}

    ldr     r1, =uart_base
    push    {r1}
    push    {r0}
    mov     r0, #0
    mov     r1, #4096
    mov     r2, #PROT_READ | PROT_WRITE
    mov     r3, #MAP_SHARED
    bl      mmap

    ldr     r1, =uart
    str     r0, [r1]

    ldr     r1, [r0, #uart1_offset + 0x0C]
    mov     r2, #0b10000011
    orr     r1, r2
    str     r1, [r0, #uart1_offset + 0x0C]
    mov     r1, #13
    str     r1, [r0, #uart1_offset]
    mov     r1, #0
    str     r1, [r0, #uart1_offset + 0x04]
    ldr     r1, [r0, #uart1_offset + 0x0C]
    ldr     r2, =~0b10000000
    and     r1, r2
    str     r1, [r0, #uart1_offset + 0x0C]
    
    pop     {r0, r1}

    ldr     r5, =uart
    ldr     r5, [r5]
read:
    ldr     r0, [r5, #uart1_offset + 0x14]
    and     r0, #1
    cmp     r0, #0
    bne     symbol_exists
    b       read
symbol_exists:
    ldr     r0, [r5, #uart1_offset]
    cmp     r0, #4
    beq     good_exit
    ldr     r1, =symbol
    str     r0, [r1]
    mov     r0, #1
    mov     r2, #1
    mov     r7, #4
    svc     #0
    b       read

sudo_error:
    ldr     r0, =error_msg
    bl      printf
    mov     r0, #1
    pop     {pc}

good_exit:
    mov     r0, #10
    ldr     r1, =symbol
    str     r0, [r1]
    mov     r0, #1
    mov     r2, #1
    mov     r7, #4
    svc     #0
    pop     {pc}

.data
symbol:     .byte   0
uart:       .int    0
mem:        .asciz  "/dev/mem"
error_msg:  .asciz  "Ask administrator about this action\n"
