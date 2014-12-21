#include "api_robot2.h" /* Robot control API */

void dance();
void delay();
void turnR();
void turnL();
void straight();

/* main function */
void _start(void){

	unsigned int distances[16];
	int i;
	
	add_alarm(dance, 30);
	
	set_motors_speed(45, 45);

	while (1){
		distances[4] = read_sonar(4);
		distances[3] = read_sonar(3);
		
		if ((distances[3] < 1100) || (distances[4] < 1100)){
			if (distances[3] < distances[4]){ // se a distancia da esq for menor...
					set_motors_speed(20,35); // ... vira para a direita
			} else {
					set_motors_speed(35,20); // se a dist da dir for menor, vira para a esq
			}
			for (i = 0; i < 90; i++); // delay...
		} else {
			set_motors_speed(30,30); // andar em linha reta se nao tiver perto do obstaculo
		}  
	}
}

/* dancandooooooooooooooooooo \o/ */
void dance(){
	while (1){
		turnR(); // _o/
		delay(); // \o/
		turnL(); // \o_
		turnR(); // \o/
		delay(); 
		straight();
		delay();
		delay();
	}
}

void delay(){
	int i;
	for (i = 0; i < 4; i++){
		read_sonar(i);
	}
}

void turnR(){
	set_motors_speed(30,0);
}

void turnL(){
	set_motors_speed(0,30);
}

void straight(){
	set_motors_speed(15,15);
	
}
