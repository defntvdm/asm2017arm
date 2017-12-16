.globl main
.text

#define uart_base       0x01c28000
#define ccu_base        0x1c20000
#define rtc_base        0x01f00000

#ifndef SEC
#define uart_offset     0x400
#define uart_bit        17
#else
#define uart_offset     0x800
#define uart_bit        18
#endif

#define O_DSYNC         10000
#define O_RDWR          2
#define STDIN           0
#define PROT_READ       1
#define PROT_WRITE      2
#define MAP_SHARED      1
#define FIONREAD        0x541B
#define TCSANOW         0
#define ECHO            0000010
#define ICANON          0000002
#define STDIN           0

main:
    push    {lr}
    bl      set_start_name
    bl      get_terms
    bl      setup
    bl      ask_name
    bl      uncanon
    bl      send_sync
    bl      wait_connection
    bl      send_name
    bl      reflow
    bl      rewrite_data
    loop:
        bl      need_recieve
        cmp     r0, #1
        bleq    recieve
        bl      check_sync
        bl      kbhit
        cmp     r0, #0
        blne    process_stdin
        mov     r0, #100
        bl      usleep
        b       loop
    exit:
    bl      canon
    mov     r0, #0
    mov     r7, #1
    svc     #0
    pop     {pc}

process_stdin:
    push    {lr}
    mov     r4, r0
    kb_loop:
        push    {r4}
        bl      getchar
        cmp     r0, #0x0a
        beq     need_to_send
        cmp     r0, #0x7f
        beq     backspace
        cmp     r0, #0x1b
        beq     new_loop
        cmp     r0, #0x04
        beq     down_
        cmp     r0, #0x15
        beq     up_
        ldr     r3, =data_pointer
        ldr     r2, [r3]
        strb    r0, [r2], #1
        str     r2, [r3]
        mov     r0, #0
        str     r0, [r2]
        bl      rewrite_data
        b       new_loop
        need_to_send:
        bl      analyze_data
        b       new_loop
        backspace:
        ldr     r0, =data_pointer
        ldr     r1, [r0]
        ldr     r2, =data
        cmp     r1, r2
        beq     new_loop
        sub     r1, #1
        mov     r2, #0x20
        str     r2, [r1]
        push    {r0, r1, r2}
        bl      rewrite_data
        pop     {r0, r1, r2}
        mov     r2, #0
        str     r2, [r1]
        str     r1, [r0]
        bl      rewrite_data
        b       new_loop
        up_:
        ldr     r0, =offset
        ldr     r1, [r0]
        add     r1, #1
        str     r1, [r0]
        bl      reflow
        bl      rewrite_data
        b       new_loop
        down_:
        ldr     r0, =offset
        ldr     r1, [r0]
        sub     r1, #1
        cmp     r1, #0
        blt     not_valid_offset
        str     r1, [r0]
        bl      reflow
        bl      rewrite_data
        b       new_loop
        not_valid_offset:
        mov     r1, #0
        str     r1, [r0]
        b       new_loop
        new_loop:
        pop     {r4}
        subs    r4, #1
        bne     kb_loop
        pop     {pc}

rewrite_data:
    push    {lr}
    ldr     r1, =msg_cursor
    mov     r2, #msg_cursor_len
    mov     r0, #0
    mov     r7, #4
    svc     #0
    ldr     r1, =data
    ldr     r2, =data_pointer
    ldr     r2, [r2]
    sub     r2, r1
    mov     r0, #0
    mov     r7, #4
    svc     #0
    pop     {pc}

analyze_data:
    push    {lr}
    ldr     r0, =data
    ldr     r1, =start_name
    mov     r2, #6
    bl      strncmp
    cmp     r0, #0
    beq     name_in_data
    bl      time_to_send_data
    b       clear_data
    name_in_data:
    ldr     r0, =myname
    ldr     r1, =data
    add     r1, #6
    bl      strcpy
    bl      change_my_name
    ldr     r0, =data_pointer
    ldr     r1, =data
    str     r1, [r0]
    mov     r0, #0
    str     r0, [r1]
    clear_data:
    ldr     r0, =data_pointer
    ldr     r1, =data
    str     r1, [r0]
    mov     r0, #0
    ldr     r1, =msg_cursor
    mov     r2, #msg_cursor_len
    mov     r0, #0
    mov     r7, #4
    svc     #0
    pop     {pc}

time_to_send_data:
    push    {lr}
    ldr     r0, =msg_to_log
    ldr     r1, =fmt_msg
    ldr     r2, =colored_myname
    ldr     r3, =data
    bl      sprintf
    bl      add_to_log
    ldr     r0, =recieved
    ldr     r1, =msg_packet_fmt
    ldr     r2, =data
    bl      sprintf
    bl      send_packet
    pop     {pc}

send_packet:
    push    {lr}
    mov     r3, #0
    ldr     r0, =recieved
    ldr     r2, =uart_addr
    ldr     r2, [r2]
    mov     r3, #0
    send_name_for_char:
        send_name_wait_loop:
            ldr     r1, [r2, #uart_offset+0x14]
            and     r1, #1<<5
            cmp     r1, #0
            beq     send_name_wait_loop
        ldrb    r1, [r0], #1
        str     r1, [r2, #uart_offset]
        add     r3, r1
        cmp     r1, #0x0a
        beq     send_check_sum_name
        b       send_name_for_char
    send_check_sum_name:
        send_name_wait_loop1:
            ldr     r1, [r2, #uart_offset+0x14]
            and     r1, #1<<5
            cmp     r1, #0
            beq     send_name_wait_loop1
        and     r3, #0xff
        str     r3, [r2, #uart_offset]
    pop     {pc}

change_my_name:
    push    {lr}
    ldr     r0, =msg_to_log
    ldr     r1, =change_name_msg
    ldr     r2, =colored_myname
    add     r2, #7
    ldr     r3, =myname
    bl      sprintf
    bl      add_to_log
    bl      make_myname_colored
    bl      send_name
    pop     {pc}

send_name:
    push    {lr}
    ldr     r0, =recieved
    ldr     r1, =name_packet_fmt
    ldr     r2, =myname
    bl      sprintf
    bl      send_packet
    pop     {pc}

check_sync:
    push    {lr}
    ldr     r2, =rtc_addr
    ldr     r2, [r2]
    ldr     r2, [r2, #0x14]
    ldr     r1, =old_time
    ldr     r3, [r1]
    push    {r2}
    sub     r2, r3
    cmp     r2, #0
    pop     {r2}
    beq     done_check_sync
    str     r2, [r1]
    bl      send_sync
    done_check_sync:
    pop     {pc}

draw_messages:
    push    {lr}
    ldr     r0, =offset
    ldr     r0, [r0]
    mov     r1, #4
    mul     r0, r1
    ldr     r1, =log_pointer
    ldr     r1, [r1]
    ldr     r2, =len_pointer
    ldr     r2, [r2]
    sub     r1, r0
    sub     r2, r0
    mov     r3, #0
    loop_draw:
        push    {r1, r2, r3}
        mov     r0, #1
        ldr     r1, =to_left
        mov     r2, #to_left_len
        mov     r7, #4
        svc     #0
        pop     {r1, r2, r3}
        ldr     r5, =log_messages
        cmp     r1, r5
        ble     drawn
        ldr     r4, [r2, #-4]!
        add     r3, r4
        cmp     r3, #21
        bge     drawn
        push    {r4}
        up_loop1:
            push    {r1, r2, r3}
            mov     r0, #1
            ldr     r1, =up
            mov     r2, #up_len
            mov     r7, #4
            svc     #0
            pop     {r1, r2, r3}
            subs    r4, #1
            bne     up_loop1
        push    {r1, r2, r3}
        ldr     r0, [r1, #-4]
        bl      puts
        pop     {r1, r2, r3}
        sub     r1, #4
        pop     {r4}
        up_loop2:
            push    {r1, r2}
            mov     r0, #1
            ldr     r1, =up
            mov     r2, #up_len
            mov     r7, #4
            svc     #0
            pop     {r1, r2}
            subs    r4, #1
            bne     up_loop2
        b       loop_draw
    drawn:
    pop     {pc}

reflow:
    push    {lr}
    mov     r0, #1
    ldr     r1, =clear_msg
    mov     r2, #clear_len
    mov     r7, #4
    svc     #0
    bl      draw_messages
    pop     {pc}

parse:
    push    {lr}
    ldr     r0, =recieved
    ldr     r1, =start_msg
    mov     r2, #5
    bl      strncmp
    cmp     r0, #0
    beq     it_is_msg

    ldr     r0, =recieved
    ldr     r1, =start_sync
    mov     r2, #6
    bl      strncmp
    cmp     r0, #0
    beq     it_is_sync

    ldr     r0, =recieved
    ldr     r1, =start_ok
    mov     r2, #4
    bl      strncmp
    cmp     r0, #0
    beq     it_is_ok

    ldr     r0, =recieved
    ldr     r1, =start_name
    mov     r2, #6
    bl      strncmp
    cmp     r0, #0
    beq     it_is_name
    pop     {pc}

    it_is_ok:
    pop     {pc}

    it_is_sync:
    bl      on_sync
    pop     {pc}

    it_is_name:
    bl      on_change_name
    pop     {pc}

    it_is_msg:
    bl      on_msg
    pop     {pc}

on_change_name:
    push    {lr}
    bl      send_ok
    ldr     r0, =offset
    mov     r1, #0
    str     r1,[r0]
    ldr     r0, =frname
    ldr     r1, =recieved
    add     r1, #6
    bl      strcpy
    ldr     r0, =msg_to_log
    ldr     r1, =change_name_msg
    ldr     r2, =colored_frname
    add     r2, #7
    ldr     r3, =frname
    bl      sprintf
    bl      add_to_log
    bl      make_frname_colored
    bl      rewrite_data
    pop     {pc}

on_msg:
    push    {lr}
    bl      send_ok
    ldr     r0, =offset
    mov     r1, #0
    str     r1,[r0]
    ldr     r0, =msg_to_log
    ldr     r1, =fmt_msg
    ldr     r2, =colored_frname
    ldr     r3, =recieved
    add     r3, #5
    bl      sprintf
    bl      add_to_log
    bl      rewrite_data
    pop     {pc}

add_to_log:
    push    {lr}
    add     r0, #1
    push    {r0}
    bl      malloc
    ldr     r1, =log_pointer
    ldr     r2, [r1]
    str     r0, [r2], #4
    str     r2, [r1]
    ldr     r1, =msg_to_log
    pop     {r2}
    push    {r2}
    bl      memcpy
    pop     {r0}
    mov     r1, #80
    udiv    r0, r1
    add     r0, #1
    ldr     r1, =len_pointer
    ldr     r2, [r1]
    str     r0, [r2], #4
    str     r2, [r1]
    bl      reflow
    pop     {pc}

on_sync:
    push    {lr}
    ldr     r0, =sync_count
    mov     r1, #5
    str     r1, [r0]
    pop     {pc}

recieve:
    push    {lr}
    mov     r3, #0
    ldr     r2, =uart_addr
    ldr     r2, [r2]
    ldr     r0, =recieved
    wait_read_packet:
        ldr     r1, [r2, #uart_offset+0x14]
        and     r1, #1
        cmp     r1, #0
        beq     wait_read_packet
    ldrb    r1, [r2, #uart_offset]
    cmp     r1, #0x1b
    beq     skip_byte
    strb    r1, [r0], #1
    skip_byte:
    add     r3, r1
    cmp     r1, #0x0a
    bne     wait_read_packet
    sub     r0, #1
    mov     r1, #0
    strb    r1, [r0], #1
    wait_read_packet1:
        ldrb    r1, [r2, #uart_offset+0x14]
        and     r1, #1
        cmp     r1, #0
        beq     wait_read_packet1
    ldrb    r1, [r2, #uart_offset]
    and     r3, #0xff
    @cmp     r1, r3
    @beq     check_sum_is_ok
    @pop     {pc}
    check_sum_is_ok:
    bl      parse
    pop     {pc}

need_recieve:
    push    {lr}
    ldr     r2, =uart_addr
    ldr     r2, [r2]
    ldr     r1, [r2, #uart_offset+0x14]
    and     r1, #1
    cmp     r1, #0
    beq     nope_packet_not_exists
    mov     r0, #1
    pop     {pc}
    nope_packet_not_exists:
    mov     r0, #0
    pop     {pc}

wait_connection:
    push    {lr}
    wait_loop:
        ldr     r0, =100000
        bl      usleep
        bl  need_recieve
        cmp     r0, #1
        beq     connected
        b       wait_loop
    connected:
    pop     {pc}

send_ok:
    push    {r0, r1, r2, lr}
    ldr     r2, =uart_addr
    ldr     r2, [r2]
    ldr     r0, =ok
    send_ok_for_char:
        send_ok_wait_loop:
            ldr     r1, [r2, #uart_offset+0x14]
            and     r1, #1<<5
            cmp     r1, #0
            beq     send_ok_wait_loop
        ldrb    r1, [r0], #1
        cmp     r1, #0
        beq     ok_sent
        str     r1, [r2, #uart_offset]
        b       send_ok_for_char
    ok_sent:
    pop     {r0, r1, r2, pc}

send_sync:
    push    {lr}
    ldr     r2, =uart_addr
    ldr     r2, [r2]
    ldr     r0, =sync
    send_sync_for_char:
        send_sync_wait_loop:
            ldr     r1, [r2, #uart_offset+0x14]
            and     r1, #1<<5
            cmp     r1, #0
            beq     send_sync_wait_loop
        ldrb    r1, [r0], #1
        cmp     r1, #0
        beq     sync_sent
        str     r1, [r2, #uart_offset]
        b       send_sync_for_char
    sync_sent:
    ldr     r0, =sync_count
    ldr     r1, [r0]
    sub     r1, #1
    str     r1, [r0]
    cmp     r1, #0
    bgt     syncok 
    
    syncok:
    pop     {pc}


setup:
    push    {lr}
    @ открываем /dev/mem
    ldr     r0, =mem
    ldr     r1, =O_RDWR | O_DSYNC
    bl      open
    cmp     r0, #0
    blt     error
    @@@@@@@@@@@@@@@@@@@@@@@@@@@

    @ mmap rtc
    ldr     r1, =rtc_base
    push    {r1}
    push    {r0}
    mov     r0, #0
    mov     r1, #4096
    mov     r2, #PROT_READ | PROT_WRITE
    mov     r3, #MAP_SHARED
    bl      mmap
    ldr     r1, =rtc_addr
    str     r0, [r1]
    pop     {r0}
    pop     {r1}
    @@@@@@@@@@@@@@@@@@@@@@@@@

    @ mmap ccu
    ldr     r1, =ccu_base
    push    {r1}
    push    {r0}
    mov     r0, #0
    mov     r1, #4096
    mov     r2, #PROT_READ | PROT_WRITE
    mov     r3, #MAP_SHARED
    bl      mmap

    ldr     r1, [r0, #0x6c]
    orr     r1, #1<<uart_bit
    str     r1, [r0, #0x6c]
    ldr     r1, [r0, #0x2d8]
    orr     r1, #1<<uart_bit
    str     r1, [r0, #0x2d8]
    
    pop     {r0}
    pop     {r1}
    @@@@@@@@@@@@@@@@@@@@@@

    @ mmap uart
    ldr     r1, =uart_base
    push    {r1}
    push    {r0}
    mov     r0, #0
    mov     r1, #4096
    mov     r2, #PROT_READ | PROT_WRITE
    mov     r3, #MAP_SHARED
    bl      mmap
    ldr     r1, =uart_addr
    str     r0, [r1]

    @ настройка uart
    ldr     r1, [r0, #uart_offset+0x08]
    orr     r1, #0b00000111 @ включение и сброс FIFO
    str     r1, [r0, #uart_offset+0x08]
    ldr     r1, [r0, #uart_offset+0x0C]
    mov     r1, #0b10011011 @ 1 включаем доступ к латчам, 0 хз, 01 even, 1 parity en, 0 один стоп, 11 восемь бит
    str     r1, [r0, #uart_offset+0x0C]
    mov     r1, #13 @ 24000000/(16*13)=115200 Гц
    str     r1, [r0, #uart_offset]
    mov     r1, #0
    str     r1, [r0, #uart_offset+0x04]
    ldr     r1, [r0, #uart_offset+0x0C]
    and     r1, #~0b10000000 @ выключаем доступ к латчам
    str     r1, [r0, #uart_offset+0x0C]

    pop     {r0}
    pop     {r1}
    @@@@@@@@@@@@@@@@@@@@@@@
    pop     {pc}

get_terms:
    push    {lr}
    @ получаем состояние терминала
    mov     r0, #STDIN
    ldr     r1, =term1
    bl      tcgetattr
    @ сохраняем состояние в term2
    ldr     r0, =term1
    ldr     r1, =term2
    mov     r2, #60
    copy_cycle:
        ldrb    r3, [r0], #1
        strb    r3, [r1], #1
        subs    r2, #1
        bne     copy_cycle
    @ term1 для uncanon
    mov     r0, #~(ICANON | ECHO)
    ldr     r1, =term1
    ldr     r2, [r1, #12]
    and     r0, r2
    str     r0, [r1, #12]
    pop     {pc}

uncanon:
    push    {lr}
    mov     r0, #STDIN
    mov     r1, #TCSANOW
    ldr     r2, =term1
    bl      tcsetattr
    pop     {pc}

canon:
    push    {lr}
    mov     r0, #STDIN
    mov     r1, #TCSANOW
    ldr     r2, =term2
    bl      tcsetattr
    pop     {pc}

ask_name:
    push    {lr}
    mov     r0, #1
    ldr     r1, =ask_name_msg
    mov     r2, #ask_name_len
    mov     r7, #4
    svc     #0
    mov     r0, #0
    ldr     r1, =myname
    mov     r2, #100
    mov     r7, #3
    svc     #0
    sub     r0, #1
    mov     r2, #0
    strb    r2, [r1, r0]
    bl      make_myname_colored
    pop     {pc}

make_myname_colored:
    push    {lr}
    ldr     r0, =reset_color
    push    {r0}
    ldr     r0, =colored_myname
    ldr     r1, =colored_name_fmt
    ldr     r2, =mycolor
    ldr     r3, =myname
    bl      sprintf
    pop     {r0}
    pop     {pc}

make_frname_colored:
    push    {lr}
    ldr     r0, =reset_color
    push    {r0}
    ldr     r0, =colored_frname
    ldr     r1, =colored_name_fmt
    ldr     r2, =frcolor
    ldr     r3, =frname
    bl      sprintf
    pop     {r0}
    pop     {pc}

set_start_name:
    push    {lr}
    ldr     r0, =frname
    ldr     r1, =init_name
    bl      strcpy
    bl      make_frname_colored
    pop     {pc}

kbhit:
    push    {r1, r2, lr}
    mov     r0, #STDIN
    ldr     r1, =FIONREAD
    ldr     r2, =inbuf
    bl      ioctl
    ldr     r0, =inbuf
    ldr     r0, [r0]
    pop     {r1, r2, pc}

.data
offset:             .int    0
to_left:            .ascii  "\033[80D"
to_left_len = . - to_left
clear_msg:          .ascii  "\033[2J\033[21;0H================================================================================\033[21;0H"
clear_len = . - clear_msg
up:                 .ascii  "\033[A"
up_len = . - up
msg_cursor:         .ascii  "\033[22;0H"
msg_cursor_len = . - msg_cursor
change_name_msg:  .asciz  "\033[1;34msystem\033[0m: name changed %s -> %s"
sys_msg_fmt:        .asciz  "\033[1;34msystem\033[0m: %s"
fmt_msg:            .asciz  "%s: %s"
init_name:          .asciz  "anonymous"
colored_name_fmt:   .asciz  "%s%s%s"
mycolor:            .asciz  "\033[1;32m"
frcolor:            .asciz  "\033[1;31m"
reset_color:        .asciz  "\033[0m"
sync_count:         .int    6
sync:               .asciz  "/sync\x0a\xf6"
ok:                 .asciz  "/ok\0x0a\x13"
start_name:         .asciz  "/name "
start_msg:          .asciz  "/msg "
start_ok:           .asciz  "/ok"
start_sync:         .asciz  "/sync"
mem:                .asciz  "/dev/mem"
ask_name_msg:       .ascii  "\033[2J\033[HEnter your name: "
ask_name_len = . - ask_name_msg
name_packet_fmt:    .asciz  "/name %s\n"
msg_packet_fmt:     .asciz  "/msg %s\n"
log_pointer:        .int    log_messages
len_pointer:        .int    len_messages
data_pointer:       .int    data
old_time:           .int    0
.bss
.comm   inbuf           4, 4
.comm   term1,          60, 4
.comm   term2,          60, 4
.comm   rtc_addr,       4, 4
.comm   uart_addr,      4, 4
.comm   myname,         100, 4
.comm   frname,         100, 4
.comm   colored_myname, 120, 4
.comm   colored_frname, 120, 4
.comm   recieved,       300, 4
.comm   msg_to_log,     400, 4
.comm   log_messages,   400000, 4
.comm   len_messages,   400000, 4
.comm   data,           200, 4
