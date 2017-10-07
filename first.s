.globl main
.text

main:
	push 	{lr}
	ldr 	r0, =code
	ldr 	r1, =clear
	bl 		printf
	ldr 	r0, =code
	ldr 	r1, =set0up
	bl 		printf
	ldr 	r0, =code
	ldr		r1, =set0left
	bl 		printf
	ldr 	r0, =code
	ldr 	r1, =moveDown
	bl 		printf
	ldr 	r0, =code
	ldr 	r1, =moveRight
	bl 		printf

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
	ldr 	r0, =code
	ldr 	r1, =moveDown
	bl 		printf
	ldr 	r0, =code
	ldr 	r1, =set0left
	bl 		printf

wait_enter:
	bl 		getchar
	cmp 	r0, #10
	bne 	wait_enter

	ldr 	r0, =code
	ldr 	r1, =clear
	bl 		printf
	ldr 	r0, =code
	ldr 	r1, =set0up
	bl 		printf
	ldr 	r0, =code
	ldr 	r1, =set0left
	bl 		printf
	pop 	{pc}

.data
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
code:
	.ascii "\033[%s\0"
clear:
	.ascii "2J\0"
set0left:
	.ascii "80D\0"
set0up:
	.ascii "25A\0"
moveDown:
	.ascii "12B\0"
moveRight:
	.ascii "34C\0"
