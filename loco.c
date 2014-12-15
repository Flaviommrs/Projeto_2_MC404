#include "api_robot2.h" /* Robot control API */

void turnR();
void turnL();
void dance();
void stop();
void straight();

/* main function */
void _start(void){

	unsigned int distances[16];
	
	add_alarm(dance, 30);
	/*
	
	while (1){
		distances[4] = read_sonar(4);
		distances[3] = read_sonar(3);
		if (distances[3] < 2000 || distances[4] < 2000){
			if (distances[3] < distances[4]){ // se a distancia da esq for menor...
				set_motors_speed(0,14); // ... vira para a direita
			} else {
				set_motors_speed(14,0); // se a dist da dir for menor, vira para a esq
			}
		} else {
			set_motors_speed(14,14); // andar em linha reta se nao tiver perto do obstaculo
		}  
	}
	*/
	while (1){}
}

void turnR(){
	set_motors_speed(40,0);
}

void turnL(){
	set_motors_speed(0,40);
}

void dance(){
	unsigned short time = get_time();
	add_alarm(turnR, time);
	add_alarm(turnL, time + 2);
	add_alarm(turnR, time + 4);
	add_alarm(turnL, time + 6);
	add_alarm(stop, time + 8);
	add_alarm(straight, time + 9);
	add_alarm(dance, time + 13);	
}

void stop(){
	set_motors_speed(0,0);
}

void straight(){
	set_motors_speed(15,15);
	
}
