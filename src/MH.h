/*
 * MH.h - A header file qui contient les structures pour des messages multihop
 *
 */

#ifndef _TOS_MH_H
#define _TOS_MH_H

#include "AM.h"

uint16_t total_node = 100;
uint16_t total_ch = 10;
//uint16_t K;         //c'est le nombre désiré de CH pour chaque round
//uint16_t N = 10;      //le nombre de noeuds que l'utilisateur a introduit

enum{
	AM_MHMESSAGE = 250,
	AM_MEMBRE = 200,
	AM_ORGANISATION = 210,
	AM_SLOT = 220,
	AM_AGGREGATION = 230,
	
	BASE_STATION_ADDRESS = 0,
	//TOS_BCAST_ADDR = 255,
    LEACH_ROUND_LENGTH = 100000,            // 100 seconds for each round duration
	LEACH_ANNONCE_LENGTH = 4000,           	// 3 second for each CH that annonce it's new CH, Depended to Max(depth)
	LEACH_ORGANISATION_LENGTH = 4000,      	// 1 second for send join request to CH
	LEACH_SLOT_LENGTH=1000,                 	// 1 second for each member to send its data
	LEACH_SLOT_OFFSET=0
};

enum{
	ROUND_LENGTH = LEACH_ROUND_LENGTH,
	ANNONCE_LENGTH = LEACH_ANNONCE_LENGTH,
	ORGANISATION_LENGTH = LEACH_ORGANISATION_LENGTH,
	SLOT_LENGTH = LEACH_SLOT_LENGTH,
	SLOT_OFFSET = LEACH_SLOT_OFFSET
};

typedef nx_struct puits_msg {
	nx_uint16_t ID;                	//l'identificateur de chaque noeud qui correspond à TOS_LOCAL_ADRESS 
	nx_uint8_t 	round;              	//le round courant	
	nx_uint32_t probability;       	//la probabilité que chaque noeud devienne CH	(float)
	nx_uint8_t 	Depth;              	//la profondeur du neoud dans le réseaux
	//nx_bool		newRound;
} puits_msg_t;

typedef nx_struct member_msg{
	nx_uint16_t ID_MEMBRE;                //l'identificateur de chaque noeud qui correspond à TOS_LOCAL_ADRESS 
	nx_uint16_t ID_CH;  				   //l'identificateur du CH dont lequel appatiendra le noeud membre
    nx_uint8_t  temp;      			   //variable qui contient la température captée,
    nx_uint8_t  req;                	   //si req=1 alors le neoud membre préviend le CH qu'il fais partie de son groupe,si il est égal à 2 sa veut dire qu'il a envoyé la valeur captée
}member_msg_t;

typedef nx_struct cluster_head_msg{
	nx_uint16_t ID_MEMBRE;                //l'identificateur de chaque noeud qui correspond à TOS_LOCAL_ADRESS 
	nx_uint16_t ID_CH;  				   //l'identificateur du CH dont lequel appatiendra le noeud membre
    nx_uint8_t  donne_aggreger;      	   //la donnée aggreger à envoyer au noeud PUITS
	nx_uint16_t FREQ;                     //La fréquence avec laquelle les membre d'un memebre Cluster envoi
    nx_uint16_t  SLOT_ATTRIBUER;           //le slot attribuer à chaque membre
	nx_uint8_t  NBR_MBR;                  //Calcul le nombre de membre utiliser pour la connectivité 
}cluster_head_msg_t;

#endif