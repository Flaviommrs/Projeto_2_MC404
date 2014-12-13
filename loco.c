#include "api_robot2.h" /* Robot control API */

/* main function */
void _start(void){

	unsigned int distances[16];
	set_motors_speed(14,14);
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
}
