.text
.org 0x0
.section .iv,"a"

@Configurações do GPT
.set GPT_CR,                   0x53FA0000
.set GPT_PR,                   0x53FA0004
.set GPT_OCR1,                 0x53FA0010
.set GPT_IR,                   0x53FA000C
.set GPT_SR,                   0x53FA0008

@ Constantes para os registradores do TZIC
.set TZIC_BASE,                0x0FFFC000
.set TZIC_INTCTRL,             0x0
.set TZIC_INTSEC1,             0x84
.set TZIC_ENSET1,              0x104
.set TZIC_PRIOMASK,            0xC
.set TZIC_PRIORITY9,           0x424

@Constantes com os resgistradores do GPIO
.set GPIO_DR,                  0x53F84000
.set GPIO_GDIR,                0x53F84004
.set GPIO_PSR,                 0x53F84008

@Constantes de configuração do GPIO
.set GPIO_INIT,                0xFFFC003E

@Stack Pointers para o usuario e o superusuario
.set USER_STK,                 0x78802000
.set SUPER_STK,                0x7A802000

@Endereço de onde vai começar o codigo do usuario
.set USER_CODE,                0x77802000

@Numero das System Calls
.set GET_TIME_NUMBER,          120
.set SET_TIME_NUMBER,          121
.set SET_ALARM_NUMBER,         122
.set READ_SONAR_NUMBER,        123
.set SET_MOTOR_SPEED_NUMBER,   124
.set SET_MOTORS_SPEED_NUMBER,  125

@Constantes do Alarme
.set MAX_ALARMS,               10

_start:

interrupt_vector:

	b RESET_HANDLER

.org 0x04
	b INTERRUPTION_HANDLER

.org 0x08
	b SUPERVISOR_HANDLER

.org 0x0C
	b INTERRUPTION_HANDLER

.org 0x10
	b INTERRUPTION_HANDLER

.org 0x18
	b IRQ_HANDLER

.org 0x1C
	b INTERRUPTION_HANDLER

.org 0x100

	@ Zera o contador
	ldr r2, =CONTADOR  @lembre-se de declarar esse contador em uma secao de dados!
	mov r0,#0
	str r0,[r2]

RESET_HANDLER:


	@Set interrupt table base address on coprocessor 15.
	ldr r0, =interrupt_vector
	mcr p15, 0, r0, c12, c0, 0

SET_GPT:
	@Configura o GPT

	ldr r0, =GPT_CR
	mov r1, #0x00000041
	str r1, [r0]

	ldr r0, =GPT_PR
	mov r1, #0
	str r1, [r0]

	ldr r0, =GPT_OCR1
	mov r1, #64
	str r1, [r0]

	ldr r0, =GPT_IR
	mov r1, #1
	str r1, [r0]

SET_TZIC:

	@ Liga o controlador de interrupcoes
	@ R1 <= TZIC_BASE

	ldr r1, =TZIC_BASE

	@ Configura interrupcao 39 do GPT como nao segura
	mov r0, #(1 << 7)
	str r0, [r1, #TZIC_INTSEC1]

	@ Habilita interrupcao 39 (GPT)
	@ reg1 bit 7 (gpt)

	mov r0, #(1 << 7)
	str r0, [r1, #TZIC_ENSET1]

	@ Configure interrupt39 priority as 1
	@ reg9, byte 3

	ldr r0, [r1, #TZIC_PRIORITY9]
	bic r0, r0, #0xFF000000
	mov r2, #1
	orr r0, r0, r2, lsl #24
	str r0, [r1, #TZIC_PRIORITY9]

	@ Configure PRIOMASK as 0
	eor r0, r0, r0
	str r0, [r1, #TZIC_PRIOMASK]

	@ Habilita o controlador de interrupcoes
	mov r0, #1
	str r0, [r1, #TZIC_INTCTRL]

	@instrucao msr - habilita interrupcoes
	msr  CPSR_c, #0x13       @ SUPERVISOR mode, IRQ/FIQ enabled


SET_GPIO:

	@Configura quais pinos são de entrada e quais são de saida
	ldr r0, =GPIO_GDIR        @Move para r0 o endereço do registrador DIR  do GPIO
	ldr r1, =GPIO_INIT        @Move para r1 a configuração de entradas e saidas do GPIO
	str r1, [r0]

SET_STK_POINTERS:

	@Configura as stack
	ldr r13, =SUPER_STK

	@Altera o usuario de Supervisor para System
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #0x1F
	msr CPSR_c, r0

	@Configura a stack do usuario
	ldr r13, =USER_STK

	@Altera para modo de usuario
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #0x10
	msr CPSR_c, r0

	@Pula para o endereço correspondente ao começo do codigo do usuario
	ldr r0, =USER_CODE
	bx r0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SUPERVISOR_HANDLER:

	@Confere qual system call foi feita
	cmp r7, GET_TIME_NUMBER
	beq GET_TIME

	cmp r7, SET_TIME_NUMBER
	beq SET_TIME

	cmp r7, SET_ALARM_NUMBER
	beq SET_ALARM

	cmp r7, READ_SONAR_NUMBER
	beq READ_SONAR

	cmp r7, SET_MOTOR_SPEED_NUMBER
	beq SET_MOTOR_SPEED

	cmp r7, SET_MOTORS_SPEED_NUMBER
	beq SET_MOTORS_SPEED

GET_TIME:

	@Pega o tempo da memoria
	ldr r1, =CONTADOR
	ldr r0, [r1]

	movs pc, lr

SET_TIME:

	ldr r1, =CONTADOR
	str r0, [r1]

	movs pc, lr

SET_ALARM:

	stmfd sp!, {r4 - r12}



	ldmfd sp!, {r4 - r12}

	movs pc, lr

READ_SONAR:

	stmfd sp!, {r4 - r12}



	ldmfd sp!, {r4 - r12}

	movs pc, lr

SET_MOTOR_SPEED:

	stmfd sp!, {r4 - r12}



	ldmfd sp!, {r4 - r12}

	movs pc, lr

SET_MOTORS_SPEED:

	stmfd sp!, {r4 - r12}



	ldmfd sp!, {r4 - r12}

	movs pc, lr

IRQ_HANDLER:

	ldr r0, =GPT_SR
	mov r1, #0x1
	str r1, [r0]

	ldr r1, =CONTADOR
	ldr r0, [r1]
	add r0, r0, #1
	str r0, [r1]
	sub lr, lr, #4
	movs pc, lr

INTERRUPTION_HANDLER:


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
.data

.org 0xFFF

CONTADOR:
	.skip 4

ACTIVE_ALARMS:
	.skip 4
