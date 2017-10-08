.globl main
.text

main:
	push 	{lr}

@Получаем ширину и высоту консоли
	ldr 	r0, =export
	bl 		system

	ldr 	r0, =rows
	bl 		getenv
	bl 		atoi
	ldr 	r1, =height
	str 	r0, [r1]

	ldr 	r0, =cols
	bl 		getenv
	bl 		atoi
	ldr 	r1, =width
	str 	r0, [r1]

@Чистим экран, ставим крусор
	ldr 	r0, =clear
	bl 		printf
	ldr 	r0, =up
	ldr 	r1, =height
	ldr 	r1, [r1]
	bl 		printf
	ldr 	r0, =left
	ldr		r1, =width
	ldr 	r1, [r1]
	bl 		printf
	ldr 	r0, =down
	ldr 	r1, =height
	ldr 	r1, [r1]
	mov 	r2, #2
	udiv 	r1, r1, r2
	bl 		printf
	ldr 	r0, =right
	ldr 	r1, =width
	ldr 	r1, [r1]
	mov 	r2, #2
	udiv 	r1, r1, r2
	subs 	r1, r1, #6
	bl 		printf

@Считаем факториал
	mov 	r1, #1
	mov 	r2, #12

factorial:
	muls 	r1, r1, r2
	subs 	r2, r2, #1
	bne 	factorial

	push 	{r1}
	ldr 	r0, =color
	bl 		printf
	pop 	{r1}

@Получение троек факториала в стэке
	mov 	r2, #1000   @Делитель (система счисления у нас 10)
	mov 	r4, #0    @счётчик
getDigitsInStack:
	mov 	r3, r1
	udiv 	r0, r1, r2
	mul 	r1, r0, r2
	sub 	r3, r3, r1
	push 	{r3}
	add 	r4, r4, #1
	mov 	r1, r0
	cmp 	r1, #0
	bne 	getDigitsInStack

printFirst:
	ldr 	r0, =firstDigit
	pop 	{r1}
	bl 		printf
	subs 	r4, r4, #1
	beq 	done

printLast:
	ldr 	r0, =digit
	pop 	{r1}
	bl 		printf
	subs 	r4, r4, #1
	bne 	printLast

done:
	ldr 	r0, =space
	bl 		printf
	ldr 	r0, =normal
	bl 		printf
	ldr 	r0, =down
	ldr 	r1, =height
	ldr 	r1, [r1]
	bl 		printf
	ldr 	r0, =left
	ldr 	r1, =width
	ldr 	r1, [r1]
	bl 		printf

wait_enter:
	bl 		getchar
	cmp 	r0, #10
	bne 	wait_enter

	ldr 	r0, =clear
	bl 		printf
	ldr 	r0, =up
	ldr 	r1, =height
	ldr 	r1, [r1]
	bl 		printf
	ldr 	r0, =left
	ldr 	r1, =width
	ldr 	r1, [r1]
	bl 		printf
	mov 	r0, #0
	pop 	{pc}

.data
export:
	.ascii "export LINES; export COLUMNS;\0"
rows:
	.ascii "LINES\0"
cols:
	.ascii "COLUMNS\0"
width:
	.int 	0
height:
	.int 	0
space:
	.ascii "\ \0"
color:
	.ascii "\033[1;3;31m\0"
normal:
	.ascii "\033[0m\0"
firstDigit:
	.ascii "\ %d\0"
digit:
	.ascii "\ %03d\0"
clear:
	.ascii "\033[2J\0"
left:
	.ascii "\033[%dD\0"
up:
	.ascii "\033[%dA\0"
down:
	.ascii "\033[%dB\0"
right:
	.ascii "\033[%dC\0"
debug_msg:
	.ascii "LIVE!!!\0"
