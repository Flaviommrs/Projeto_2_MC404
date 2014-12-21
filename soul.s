.text
.org 0x0
.section .iv, "a"

@ Configuracoes do GPT
.set GPT_CR,                     0x53FA0000
.set GPT_PR,                     0x53FA0004
.set GPT_OCR1,                   0x53FA0010
.set GPT_IR,                     0x53FA000C
.set GPT_SR,                     0x53FA0008

@ Constantes para os registradores do TZIC
.set TZIC_BASE,                  0x0FFFC000
.set TZIC_INTCTRL,               0x0
.set TZIC_INTSEC1,               0x84
.set TZIC_ENSET1,                0x104
.set TZIC_PRIOMASK,              0xC
.set TZIC_PRIORITY9,             0x424

@ Constantes com os registradores do GPIO
.set GPIO_DR,                    0x53F84000
.set GPIO_GDIR,                  0x53F84004
.set GPIO_PSR,                   0x53F84008

@ Constantes de configuracao do GPIO
.set GPIO_INIT,                  0xFFFC003E

@ Stack Pointers para o usuario e o superusuario
.set USER_STK,                   0x78802000
.set SUPER_STK,                  0x7A802000
.set IRQ_STK,                    0x7FFFFFFF

@ Endereco de onde vai comecar o codigo de usuario
.set USER_CODE,                  0x77802000

@ Numero das System Calls
.set GET_TIME_NUMBER,            11
.set SET_TIME_NUMBER,            12
.set SET_ALARM_NUMBER,           13
.set READ_SONAR_NUMBER,          8
.set SET_MOTOR_SPEED_NUMBER,     9
.set SET_MOTORS_SPEED_NUMBER,    10
.set RETURN_TO_IRQ_NUMBER,       14

@ Constantes do alarme
.set MAX_ALARMS,                 16

@ Numeros dos usuarios
.set USER_NUMBER,                0x10
.set SYSTEM_NUMBER,              0x1F
.set IRQ_NUMBER,                 0x12
.set SUPERVISOR_NUMBER,          0x13

@ Mascaras para leitura e escrita no GPIO
.set SONAR_ID_SHIFT,             0x2
.set MUX_MASK,                   0x3C
.set TRIGGER_MASK,               0x2
.set FLAG_READ_MASK,             0xFFFFFFFE
.set SONAR_DATA_MASK,            0xFFFC003F
.set SET_MOTOR_ZERO_MASK,        0x1FC0000
.set SET_MOTOR_ONE_MASK,         0xFE000000
.set SET_MOTORS_MASK,            0xFFFC0000
.set MOTOR_ZERO_SPEED_SHIFT,     19
.set MOTOR_ONE_SPEED_SHIFT,      26

@ Delay
.set DELAY_ITERACTIONS,          20000

@ Motors
.set MAXIMUM_SPEED,              63

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
	ldr r2, =CONTADOR
	mov r0, #0
	str r0, [r2]

RESET_HANDLER:

	@ Set interrupt table base address on coprocessor 15.
	ldr r0, =interrupt_vector
	mcr p15, 0, r0, c12, c0, 0

SET_STACKS:

	@ Muda para modo de supervisor
	mrs r0, CPSR
	bic r0, r0, #SYSTEM_NUMBER
	orr r0, r0, #SUPERVISOR_NUMBER
	msr CPSR_c, r0

	@ Configura a stack do supervisor
	ldr r13, =SUPER_STK

	@ Altera para o modo IRQ
	mrs r0, CPSR
	bic r0, r0, #SYSTEM_NUMBER
	orr r0, r0, #IRQ_NUMBER
	msr CPSR_c, r0

	@ Configura a stack do Superusuario IRQ
	ldr r13, =IRQ_STK

	@ Altera para System
	mrs r0, CPSR
	orr r0, r0, #SYSTEM_NUMBER
	msr CPSR_c, r0

	@ Configura a stack do usuario
	ldr r13, =USER_STK

	@ Volta para supervisor para continuar as configuracoes
	mrs r0, CPSR
	bic r0, r0, #SYSTEM_NUMBER
	orr r0, r0, #SUPERVISOR_NUMBER
	msr CPSR_c, r0

SET_GPT:
	
	@ Configura GPT
	ldr r0, =GPT_CR
	mov r1, #0x41
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

	@ Instrucao msr - habilita interrupcoes
	msr CPSR_c, #SUPERVISOR_NUMBER

SET_GPIO:

	@ Configura quais pinos sao de entrada e quais sao de saida
	ldr r0, =GPIO_GDIR
	ldr r1, =GPIO_INIT
	str r1, [r0]

GO_TO_USER_CODE:

	@ Altera para modo de usuario
	mrs r0, CPSR
	bic r0, r0, #SYSTEM_NUMBER
	orr r0, r0, #USER_NUMBER
	msr CPSR_c, r0

	@ Pula para o endereco correspondente ao comeco do codigo do usuario
	ldr r0, =USER_CODE
	bx r0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SUPERVISOR_HANDLER:

	@ Confere qual syscall foi feita
	cmp r7, #GET_TIME_NUMBER
	beq GET_TIME

	cmp r7, #SET_TIME_NUMBER
	beq SET_TIME

	cmp r7, #SET_ALARM_NUMBER
	beq SET_ALARM

	cmp r7, #READ_SONAR_NUMBER
	beq READ_SONAR

	cmp r7, #SET_MOTOR_SPEED_NUMBER
	beq SET_MOTOR_SPEED

	cmp r7, #SET_MOTORS_SPEED_NUMBER
	beq SET_MOTORS_SPEED

	cmp r7, #RETURN_TO_IRQ_NUMBER
	beq RETURN_TO_IRQ

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

GET_TIME: @ verifica o tempo atual
	
	@ Pega o tempo da memoria
	ldr r1, =CONTADOR
	ldr r0, [r1]

	movs pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SET_TIME: @ configura um novo tempo

	@ Seta o tempo do sistema
	ldr r1, =CONTADOR
	str r0, [r1]

	movs pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SET_ALARM:  @ adiciona um alarme: programa um horario para a execucao d uma funcao

	stmfd sp!, {r4 - r6}

	@ Verifica se o tempo pedido para o alarme eh valido
	ldr r3, =CONTADOR
	ldr r3, [r3]

	cmp r3, r1
	bhi invalid_time

	@ Verifica se o numero maximo de alarmes foi atingido
	ldr r4, =ACTIVE_ALARMS
	ldr r5, [r4]
	cmp r5, #MAX_ALARMS
	beq max_alarm_number_reached

	@ Adiciona mais um no numero de alarmes ativos
	add r5, r5, #1
	str r5, [r4]

	@ Encontra a proxima posicao livre do vetor
	ldr r5, =ALARM_VECTOR @ endereco inicil do vetor de alarmes
	mov r2, #0            @ variavel de inducao
	
for_alarm_vector:
	cmp r2, #MAX_ALARMS
	beq end_of_for_alarm_vector

	ldr r6, [r5, #4]     @ carrega campo endereco da struct

	cmp r6, #0           @ verifica se o endereco eh zero, o que indica que a posicao esta livre
	beq store_alarm      @ se estiver livre, adiciona alarme

	add r5, r5, #8       @ vai para a proxima posicao no vetor de alarmes
	add r2, r2, #1       @ incrementa variavel de inducao
	b for_alarm_vector

store_alarm:
	str r1, [r5]
	str r0, [r5, #4]

end_of_for_alarm_vector:
	mov r0, #0           @ retorna 0 caso o alarme tenha sido adicionado corretamente
	b end_of_set_alarm

invalid_time:
	mov r0, #-2          @ retorna -2 caso o tempo seja invalido
	b end_of_set_alarm

max_alarm_number_reached:
	mov r0, #-1          @ retorna -1 cado o numero maximo de alarmes ativos tenha sido atingido

end_of_set_alarm:
	ldmfd sp!, {r4 - r6}

	movs pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

READ_SONAR: @ leitura do sonar

	stmfd sp!, {lr}

	@ Verifica se o id passado eh valido
	cmp r0, #15
	bhi invalid_id

	@ Coloca em r2 o valor atual do GPIO
	ldr r1, =GPIO_DR
	ldr r2, [r1]

	@ Coloca o id do sonar dentro do registrador DR
	lsl r0, r0, #SONAR_ID_SHIFT       @ desloca o id do sonar para a esquerda duas posicoes
	bic r2, r2, #MUX_MASK
	orr r2, r2, r0
	
	@ Seta o trigger para 0
	bic r2, r2, #TRIGGER_MASK
	str r2, [r1]

	bl delay

	@ Seta o trigger para 1
	ldr r2, [r1]
	orr r2, r2, #TRIGGER_MASK
	str r2, [r1]

	bl delay

	@ Seta o trigger para 0
	ldr r2, [r1]
	bic r2, r2, #TRIGGER_MASK
	str r2, [r1]

flag_check:
	@ Checa a flag
	ldr r1, =GPIO_DR
	ldr r2, [r1]
	bic r2, r2, #FLAG_READ_MASK
	cmp r2, #1

	@ Delay, caso a flag nao seja 1
	beq continue_reading
	bl delay
	b flag_check

continue_reading:
	@ Le a distancia pelo registrador DR
	ldr r1, =GPIO_DR
	ldr r2, [r1]
	ldr r3, =SONAR_DATA_MASK
	bic r2, r2, r3

	lsr r2, r2, #6
	mov r0, r2        @coloca a distancia no r0 para retorno

	b end_of_read_sonar

delay:
	stmfd sp!, {r4, r5}
	mov r4, #0
	ldr r5, =DELAY_ITERACTIONS

for_delay:
	cmp r4, r5
	beq end_of_for_delay
	add r4, r4, #1
	b for_delay

end_of_for_delay:
	ldmfd sp!, {r4, r5}
	mov pc, lr

invalid_id:
	mov r0, #-1       @ retorna -1 caso o id seja invalido

end_of_read_sonar:
	ldmfd sp!, {lr}
	movs pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SET_MOTOR_SPEED: @seta a velocidade de um motor

	@ Verifica se a velocidade eh valida
	cmp r1, #MAXIMUM_SPEED
	bhi invalid_speed

	@ Verifica se eh o motor 0
	cmp r0, #0
	beq set_motor_zero

	@Verifica se eh o motor 1
	cmp r0, #1
	beq set_motor_one

	b invalid_motor

invalid_speed:
	mov r0, #-2
	b end_set_motor_speed

set_motor_zero:
	@ Desloca a velocidade para ficar na posicao correta
	lsl r1, r1, #MOTOR_ZERO_SPEED_SHIFT

	@ Seta a velocidade do motor zero e write para zero
	ldr r3, =GPIO_DR
	ldr r2, [r3]
	bic r2, r2, #SET_MOTOR_ZERO_MASK
	orr r2, r2, r1
	str r2, [r3]

	mov r0, #0
	b end_set_motor_speed

set_motor_one:
	@ Desloca a velocidade para o lugar da velocidade do motor 1
	lsl r1, r1, #MOTOR_ONE_SPEED_SHIFT
	
	@ Seta a velocidade do motor um e write para zero
	ldr r3, =GPIO_DR
	ldr r2, [r3]
	bic r2, r2, #SET_MOTOR_ONE_MASK
	orr r2, r2, r1
	str r2, [r3]

	mov r0, #0
	b end_set_motor_speed
	
invalid_motor:
	mov r0, #-1

end_set_motor_speed:
	movs pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SET_MOTORS_SPEED: @ seta a velocidade dos dois motores

	cmp r0, #MAXIMUM_SPEED
	bhi invalid_speed2

	cmp r1, #MAXIMUM_SPEED
	bhi invalid_speed3

	lsl r0, r0, #MOTOR_ZERO_SPEED_SHIFT
	lsl r1, r1, #MOTOR_ONE_SPEED_SHIFT
	add r0, r0, r1

	@ Seta as velocidades e motor write para 0
	ldr r3, =GPIO_DR
	ldr r2, [r3]
	ldr r4, =SET_MOTORS_MASK
	bic r2, r2, r4
	orr r2, r2, r0
	str r2, [r3]

	mov r0, #0
	b end_of_set_motors

invalid_speed2:
	mov r0, #-1
	b end_of_set_motors
	
invalid_speed3:
	mov r0, #-2

end_of_set_motors:
	movs pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

RETURN_TO_IRQ:

	mov r3, lr
	
	@ Muda para modo IRQ
	mrs r5, CPSR
	bic r5, r5, #SYSTEM_NUMBER
	orr r5, r5, #IRQ_NUMBER
	msr CPSR_c, r5
	
	mov lr, r3
	
	mov pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

IRQ_HANDLER:

	stmfd sp!, {r0 - r12}

	ldr r0, =GPT_SR
	mov r1, #0x1
	str r1, [r0]

	@ Adiciona uma unidade de tempo no CONTADOR
	ldr r1, =CONTADOR
	ldr r0, [r1]
	add r0, r0, #1
	str r0, [r1]

	mov r2, #0                      @ variavel de indução
	ldr r3, =ALARM_VECTOR           @variavel contendo o endereço inicial do vetor de alarmes

for_check_alarms:

	cmp r2, #MAX_ALARMS             @ verifica se percorreu todo o vetor
	beq end_of_for_check_alarms

	@ Verifica se tem alarme na posição atual do vetor
	ldr r4, [r3, #4]
	cmp r4, #0x0
	beq continue_for_check_alarms   @ nao tem alarme

	ldr r4, [r3]                    @ tem alarme
	cmp r4, r0                      @ compara o tempo do alarme com o tempo atual
	bls run_alarm                   @ tem alarme no tempo atual

continue_for_check_alarms:
	add r2, r2, #1
	add r3, r3, #8

	b for_check_alarms

run_alarm:

	@ Coloca o endereço da função a ser chamada em r4
	ldr r4, [r3, #4]

	mrs r1, spsr               @ pega o SPSR e coloca em r1
	stmfd sp!, {r0 - r4, lr}

	@ Altera para modo de usuario
	mrs r5, CPSR
	bic r5, r5, #SYSTEM_NUMBER
	orr r5, r5, #USER_NUMBER
	msr CPSR_c, r5

	@ Executa a funcao do alarme
	blx r4

	@ Chama system call para voltar ao modo IRQ depois da execucao da funcao do alarme
	mov r7, #RETURN_TO_IRQ_NUMBER
	svc 0x0

	ldmfd sp!, {r0 - r4, lr}
	msr spsr, r1                @ Restaura o SPSR de antes do alarme

	@ Diminui o numero de alarmes ativos
	ldr r4, =ACTIVE_ALARMS
	ldr r6, [r4]
	sub r6, r6, #1
	str r6, [r4]

	@ Libera o espaço do alarme
	mov r6, #0x0
	str r6, [r3, #4]

	add r2, r2, #1
	add r3, r3, #8

	b for_check_alarms 

end_of_for_check_alarms:

	ldmfd sp!, {r0 - r12}

	sub lr, lr, #4
	movs pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

INTERRUPTION_HANDLER:

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.data
.org 0xFFF

CONTADOR:
	.skip 4

ACTIVE_ALARMS:
	.word 0x0

ALARM_VECTOR:
	.fill 16, 8, 0x0
