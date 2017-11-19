.globl main
.text

#define uart_base       0x01c28000
#define uart2_offset    0x0800
#define uart_bit        1 << 18
#define ccu_base        0x01c20000
#define FIONREAD        0x541B
#define STDIN           0x0
#define TCSANOW         0x0
#define ECHO            0000010
#define ICANON          0000002
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
    @ Часики для UART2
    ldr     r1, [r0, #0x006C]
    ldr     r2, =uart_bit
    orr     r1, r2
    str     r1, [r0, #0x006C]
    @ Сброс UART2
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

    ldr     r1, [r0, #uart2_offset + 0x0C]
    mov     r2, #0b10000011
    orr     r1, r2
    str     r1, [r0, #uart2_offset + 0x0C]
    mov     r1, #13
    str     r1, [r0, #uart2_offset]
    mov     r1, #0
    str     r1, [r0, #uart2_offset + 0x04]
    ldr     r1, [r0, #uart2_offset + 0x0C]
    ldr     r2, =~0b10000000
    and     r1, r2
    str     r1, [r0, #uart2_offset + 0x0C]
    
    pop     {r0, r1}

    ldr     r5, =uart
    ldr     r5, [r5]

    bl      canon
 write:
    mov     r0, #1000
    bl      usleep
    bl      kbhit
    ldr     r0, =count
    ldr     r4, [r0]
    cmp     r4, #0
    bne     send_data
    b       write

send_data:
    wait_reader:
        ldr     r0, [r5, #uart2_offset + 0x14]
        ands    r0, #1 << 5
        beq     wait_reader
    mov     r0, #110
    bl      usleep
    bl      getchar
    cmp     r0, #4
    beq     good_exit
    str     r0, [r5, #uart2_offset]
    subs    r4, #1
    bne     send_data
    b       write

sudo_error:
    ldr     r0, =error_msg
    bl      printf
    mov     r0, #1
    pop     {pc}

good_exit:
    str     r0, [r5, #uart2_offset]
    bl      uncanon
    mov     r0, #10
    ldr     r1, =symbol
    str     r0, [r1]
    mov     r0, #1
    mov     r2, #1
    mov     r7, #4
    svc     #0
    mov     r0, #0
    mov     r7, #1
    svc     #0

canon:
    push    {lr}
    @ получаем состояние терминала
    mov     r0, #STDIN
    ldr     r1, =term1
    bl      tcgetattr
    @ сохраняем состояние в term2
    ldr     r0, =term1
    ldr     r1, =term2
    mov     r2, #60
    bl      copy_memory
    mov     r0, #~(ICANON | ECHO)
    ldr     r1, =term1
    ldr     r2, [r1, #12]
    and     r0, r2
    str     r0, [r1, #12]
    @ включаем canon
    mov     r0, #STDIN
    mov     r1, #TCSANOW
    ldr     r2, =term1
    bl      tcsetattr
    pop     {pc}

uncanon:
    push    {lr}
    mov     r0, #STDIN
    mov     r1, #TCSANOW
    ldr     r2, =term2
    bl      tcsetattr
    pop     {pc}

kbhit:
    push    {r1, r2, lr}
    mov     r0, #STDIN
    ldr     r1, =FIONREAD
    ldr     r2, =count
    bl      ioctl
    ldr     r0, =count
    ldr     r0, [r0]
    pop     {r1, r2, pc}

@ from *void, to *void, size_t
copy_memory:
    push    {lr}
    cpy_mem:
        ldrb    r3, [r0], #1
        strb    r3, [r1], #1
        subs    r2, #1
        bne     cpy_mem
    pop     {pc}

.data
count:      .int    0
symbol:     .byte   0
uart:       .int    0
mem:        .asciz  "/dev/mem"
error_msg:  .asciz  "Ask administrator about this action\n"
.bss
.comm   term1, 60, 4
.comm   term2, 60, 4
