.globl main
.text

#define O_RDWR      00000002
#define O_DSYNC     00010000
#define RTC_BASE    0x01f00000
#define PROT_READ   1
#define PROT_WRITE  2
#define MAP_SHARED  1

main:
    push    {lr}

    @clear
    ldr     r0, =clear
    bl      printf

    @открываем /dev/mem
    ldr     r0, =mem
    ldr     r1, =O_RDWR | O_DSYNC
    bl      open

    cmp     r0, #0
    blt     sudo_err

    @ммапим
    ldr     r1, =RTC_BASE
    push    {r1}
    push    {r0}
    mov     r0, #0
    mov     r1, #4096
    mov     r2, #PROT_READ | PROT_WRITE
    mov     r3, #MAP_SHARED
    bl      mmap

    @выставляем дату 7 ноября (дата сдачи) без года, потому что он нам не особо важен
    ldr     r1, =2823
    str     r1, [r0, #0x10]
    @чистим стэк от мусора
    pop     {r1}
    pop     {r1}

gogo:
    @в центр
    push    {r0}
    ldr     r0, =settocenter
    bl      printf
    pop     {r0}
    
    push    {r0}
    ldr     r0, [r0, #0x14]
    mov     r3, r0
    and     r3, #0x3f
    lsr     r0, #8
    mov     r2, r0
    and     r2, #0x3f
    lsr     r0, #8
    mov     r1, r0
    and     r1, #0x1f
    ldr     r0, =clocks
    push    {r1, r2, r3}
    bl      printf

    @спим для мигания
    ldr     r0, =100000
    bl      usleep

    @включаем двоеточия
    ldr     r0, =settocenter
    bl      printf
    pop     {r1, r2, r3}
    ldr     r0, =clocks_splited
    bl      printf

    ldr     r0, =400000
    bl      usleep

    @тут дату обновим, хотя она и не будет в нашей сдаче меняться
    pop     {r0}
    push    {r0}
    ldr     r0, [r0, #0x10]
    mov     r1, r0
    and     r1, #0x1F
    lsr     r0, #8
    mov     r3, r0
    and     r3, #0xf
    mov     r2, #4
    mul     r3, r2
    ldr     r2, =months
    add     r2, r3
    ldr     r2, [r2]
    ldr     r0, =date
    bl      printf 

    pop     {r0}
    b       gogo

    pop     {pc}

sudo_err:
    ldr     r0, =sudoerrmsg
    bl      printf
    pop     {pc}

.data
clear:          .asciz  "\033[2J"
num:            .asciz  "%08x\n"
mem:            .asciz  "/dev/mem"
settocenter:    .asciz  "\033[1;3;32m\033[25A\033[80D\033[11B\033[36C"
clocks_splited: .asciz  "%02d:%02d:%02d\n"
clocks:         .asciz  "%02d %02d %02d\n"
date:           .asciz  "\033[37C%d %s"
sudoerrmsg:     .asciz  "\033[31myou need to be root\033[0m\n"
months:         .int    0, jan, feb, mar, apr, may, jun, jul, aug, sept, oct, nov, dec
jan:            .asciz  "Jan"
feb:            .asciz  "Feb"
mar:            .asciz  "Mar"
apr:            .asciz  "Apr"
may:            .asciz  "May"
jun:            .asciz  "Jun"
jul:            .asciz  "Jul"
aug:            .asciz  "Aug"
sept:           .asciz  "Sept"
oct:            .asciz  "Oct"
nov:            .asciz  "Nov"
dec:            .asciz  "Dec"
