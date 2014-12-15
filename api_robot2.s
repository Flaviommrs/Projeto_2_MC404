.text
.global set_motor_speed
.global set_motors_speed
.global read_sonar
.global read_sonars
.global add_alarm
.global get_time
.global set_time
	
.align 4

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
set_motor_speed:

	stmfd sp!, {r4,r7, lr} 
	
	mov r4, r1
	mov r1, r0
	mov r0, r4

	mov r7, #9
	svc 0x0
	
 	ldmfd sp!, {r4,r7, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
set_motors_speed:

	stmfd sp!, {r7, lr}
	
	mov r7, #10
	svc 0x0

	ldmfd sp!, {r7, pc}
	
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
read_sonar:

	stmfd sp!, {r7, lr}

	mov r7, #8
	svc 0x0

	ldmfd sp!, {r7, pc}
	
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
read_sonars:	

	stmfd sp!, {r4-r5, lr}
	mov r4, #0
	mov r5, r0
loop:
	cmp r4, #15
	bhi end_of_loop

	mov r0, r4
	bl read_sonar

	str r0, [r5], #4
	add r4, r4, #1
	
	b loop

end_of_loop:	
	
	ldmfd sp!, {r4-r5, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
add_alarm:

	stmfd sp!, {r7, lr}
	
	mov r7, #13

	svc 0x0

	ldmfd sp!, {r7, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
get_time:

	stmfd sp!, {r7, lr}
	
	mov r7, #11

	svc 0x0

	ldmfd sp!, {r7, pc}
	
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
set_time:

	stmfd sp!, {r7, lr}
	
	mov r7, #12

	svc 0x0

	ldmfd sp!, {r7, pc}
