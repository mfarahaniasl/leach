#include "MH.h"

module LeachC @safe(){
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface SplitControl as RadioControl;
	    interface Boot;
	    interface Random;
		interface Leds;	
		interface Read<uint16_t>;
		
		interface TossimPacket;
		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;
	    interface Receive as LEACH_ReceiveMsg;
		interface AMSend as LEACH_SendMsg;
		interface Receive as ANNONCE_ReceiveMsg;        //utiliser par les CH pour annaonce  aux noeud qu'ils son les chefs
		interface AMSend as ANNONCE_SendMsg;              //reception des noeuds membre des nouveau CH
		interface Receive as ORGANISATION_ReceiveMsg;   //reception des CH les msg de ses membres
		interface AMSend as ORGANISATION_SendMsg;         //envoie des noeuds aux CH auxquels ils compte appatenir
		interface Receive as SLOT_ReceiveMsg;           //RECEPTION DES MEMBRES  DES SLOTS
		interface AMSend as SLOT_SendMsg;                 //ENVOIE CH DES SLOTS
		interface Receive as AGGREGATION_ReceiveMsg;    //RECEPTION DU NOEUD PUITS LES DONNEES AGGREGER PAR LE CH
		interface AMSend as AGGREGATION_SendMsg;          //ENVOIE CH DU CH LES DONNEE AGGREGER AU NOEUD PUITS
		
		interface Timer<TMilli> as RoundTimerStart;           //Timer apres lequel le noeud PUITS annonce le nouveau round
		interface Timer<TMilli> as RoundTimerEnd;
		interface Timer<TMilli> as MoteWackup;           //
		interface Timer<TMilli> as ReqRelayTimer;        //Timer apres lequel les noeuds apres réception du nouveau round du PUITS le renvoie à leur voisins proche, ce dernier fera de meme
	    interface Timer<TMilli> as AnnonceTimer;         //Timer apres lequel les noeuds annoncent qu'ils sont CH
		interface Timer<TMilli> as OrganisationTimer;    //Timer apres lequel pour que un noeud membre prévienne son Chef qu'il va faire partie de son Cluster 
		interface Timer<TMilli> as OrdonnecementTimer;   //Timer pour  apres lequel les noeuds membr eenvoie leurs donnée pendant leurs SLOT attribuer par le CH
		interface Timer<TMilli> as AggregerTimer;        //Timer pour  apres lequel les CH envoie la donnée au noeud PUITS apres aggrégation
		interface Timer<TMilli> as NBRECPNNECTimer;      //Timer pour  apres lequel le noeud PUITS calcule la somme de tous les noeuds connecté
		interface Timer<TMilli> as Timer1;				 //Timer utiliser pour les LED lorsque les noeuds sont élu CH	
	}
}
implementation
{
	/**************************************************/
	/*                                                                                               */
	/*     Définition des variables locales à chaque noeuds        */
	/*                                                                                                */
	/**************************************************/

	message_t packet;
	bool locked = FALSE;
	bool recu = FALSE;                 //une fois que un noeud reçois le nouveau round il le transmet à son voisin puis il met sa variable à vrai pour qu'il sache qu'il a déjà reçu le début du round
	//TOS_Msg buffer;                  //chaque noeud a un buffer dans lequelle il met le paquet avant de l'envoyer ou apres réception 
	bool isClusterHead;              //varaible pour indiquer si un noeud est un CH ou pas
	uint8_t r;                       //cette variable est utiliser que par le noeud PUITS pour incrémenter le round courant 
	int8_t rCH = -1;                   //cette variable est utiliser que pour les autres noeuds pour savoir dans quelle round ils sont apres reception du paquet
	float proba;                     //la probabilité qu'un noeud devienne CH utiliser par le noeud PUITS
	float probability;               //la probabilité qu'un noeud devienne CH utiliser par les autres noeuds
	uint16_t depth = 0;                //variable indiquant la profondeur du noeud dans le réseaux sa remplacra la puissance du signal
	bool depth_recu = FALSE;           //cette variable sera à vrai une fois que le noeud connait sa profondeur comme sa il n'aura plus a la recalculer
	uint16_t Depth_CH_Init = 0xff;     //elle sera utiliser pour prendre le CH le plus proche elle est initialiser à 255 puis à chaque fois qu'un CH arrive elle prend la valeur de la profondeur du CH                               
	uint16_t ID_CH_CHOISI;           //cette varaible contient l'ID du CH dans lequel un noeud membre décide d'appartenir
	bool round_CH;                   //cette variable nous permettra de savoir dans qu'elle round un noeud a été CH on aura besoin dans la phase 
	                                 //d'annonce pour que un CH dans son round ne reçoive pas les mesg des autres noeud CH
							         //mais par contre il pourra les recevoir dans un autre round par d'autre CH car une fois qu'il n'est plus CH il doit appartenir a un CH
	uint16_t Table_Entree_Membre = 0;  //c'est un entier qui calcul le nombre de Membre pour chaque CH
	uint16_t Table_Membre_Reelle = 0;  //C'est le nombre de membre réelle qui font partie d'un CH sont compter sous qui n'arrive pas à joindre le CH
	uint16_t temp_moyenne = 0;        //This use for avrage temp recived from CH that arregated by its members
	uint8_t nbre_conectiv = 0;        //This use count members
	uint8_t frequence;
	uint16_t mySlot;
	bool	bs_botted=FALSE;
	//puits_msg_t* puits_rms1; 
	//member_msg_t* member_rms; 
	//cluster_head_msg_t* cluster_rms; 
	/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
	/*          Procedure d'initialisation du round et du nombre  K           */
	/*                            désiré pour chauqe round                                    */
	/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

	static void Envoie();
	
	command error_t StdControl.start(){
		// TODO Auto-generated method stub
		return SUCCESS;
	}
	
	command error_t StdControl.stop(){
		// TODO Auto-generated method stub
		return SUCCESS;
	}
	//added
	event void Boot.booted() {	
		if (TOS_NODE_ID == BASE_STATION_ADDRESS){	
			r=-1; 
			total_ch=(uint16_t)total_node*10/100;                      //CH social for each round is 0.1
			if (total_ch==0 ){total_ch++;}
			
			depth_recu = TRUE;			
			depth = 0;
	         	 
			dbg("DebugApp", "LEACH - I am baseStation.\n");	    
			dbg("DebugApp", "LEACH - I'm planning a zero round\n");	    			
			dbg("DebugApp", "LEACH - Total ClusterHead for each round id: %i\n",total_ch);		
			//dbg("DebugGraph",";%i;%i;BS;1 \n",TOS_NODE_ID,TOS_NODE_ID);	
		}
	
    	call RadioControl.start();
  	}
	//added
	event void RadioControl.startDone(error_t err) {
    	if (err == SUCCESS) {
			dbg("DebugApp","\t Radio Start done. @%s\t\n", sim_time_string());
			
			if (TOS_NODE_ID == BASE_STATION_ADDRESS){	
				if(!bs_botted){
					call RoundTimerStart.startPeriodic(ROUND_LENGTH);
					bs_botted=TRUE;		
					
					dbg("DebugApp","\t Basestation booted for first time. @%s\t\n", sim_time_string());
				}
				
				Envoie();
			}
			else{
				
			}
    	}
	}
  	//added
  	event void RadioControl.stopDone(error_t err) {
  		//call RoundTimerStart.stop();
		call ReqRelayTimer.stop();
		call AnnonceTimer.stop(); 		
		dbg("DebugApp","\t Radio Stop done. \t@%s\n", sim_time_string());
  	}

	static void Envoie(){
		if (TOS_NODE_ID == BASE_STATION_ADDRESS){
			puits_msg_t* puits_rms;
			puits_rms = (puits_msg_t*)call Packet.getPayload(&packet, sizeof(puits_msg_t));

			if (puits_rms == NULL) { return; }
			else { 
				recu = TRUE;	  	       
				r++;      
				proba = (float)(total_ch/(total_node-total_ch*((float)(r%(total_node/total_ch)))));//
				puits_rms->round = r; 
				puits_rms->probability = (uint32_t)((float)proba*(float)1000);
				//memcpy(&puits_rms->probability, &proba, sizeof(uint32_t));
				puits_rms->ID = BASE_STATION_ADDRESS;	  
				
				// ptr->Status=1;
				puits_rms->Depth = 0;
				depth_recu = TRUE;	  
				
				dbg("DebugApp", "==================================================================================\n");
		        dbg("DebugApp", "=====The round started @%s                                          ====\n", sim_time_string());
				dbg("DebugApp", "==================================================================================\n");
				dbg("DebugApp", "I am BaseStation.\n");			 	 
				dbg("DebugApp", "The probability for this round is %f.\n",proba);				 	 	  	  
				dbg("DebugApp", "The r value is %i.\n",r);				 	 
				dbg("DebugApp", "Round number is %i.\n",(r)%(total_node/total_ch));	
				dbg("DebugGraph","#New round start here.\n");	
				dbg("DebugGraph",";%i;%i;BS;1 \n",TOS_NODE_ID,TOS_NODE_ID);	
				if (call LEACH_SendMsg.send(TOS_BCAST_ADDR, &packet, sizeof(puits_msg_t)) == SUCCESS) {locked = TRUE;}
			}			 	 	  
		}
	}

	static void Envoie_MEMBRE_CH(){
		member_msg_t* member_rms;
		member_rms = (member_msg_t*)call Packet.getPayload(&packet, sizeof(member_msg_t));

		if (member_rms == NULL) { return; }
		else {
			member_rms->ID_MEMBRE = TOS_NODE_ID;
			member_rms->ID_CH = ID_CH_CHOISI;
			member_rms->req = 1; 
			
			dbg("DebugApp", "I want to send request to CH %i for join to it.\t@%s\n", ID_CH_CHOISI, sim_time_string());
			
			if (call ORGANISATION_SendMsg.send(TOS_BCAST_ADDR, &packet, sizeof(member_msg_t)) == SUCCESS) {locked = TRUE;}
		}
    }

	event message_t* LEACH_ReceiveMsg.receive(message_t* msg, 
				   void* payload, uint8_t len) {
	  	float probability_buf;
	  	if (len != sizeof(puits_msg_t)) {
	  		dbg("DebugApp", "error here (puits_msg_t)!\n"); 
			return msg;
		}
    	else {
      		puits_msg_t* puits_rsm = (puits_msg_t*)payload;

 			probability_buf = (float)(puits_rsm->probability/(float)1000);

			if (!depth_recu) {
				dbg("DebugApp", "==================================================================================\n");	                                                	 	 	 
				dbg("DebugApp", "===== In node %i, Recived from %i that new round is %i \t@%s                 ====\n", TOS_NODE_ID, puits_rsm->ID, puits_rsm->round, sim_time_string());	                                                	 	 	 
				dbg("DebugApp", "==================================================================================\n");	                                                	 	 	 
				
				depth = puits_rsm->Depth + 1;
				depth_recu = TRUE;
				dbg("DebugApp", "My depth is %i\n", depth);	                                               //à effacer
				dbg("DebugApp", "Recived from node %i that its depth is %i.\n", puits_rsm->ID, puits_rsm->Depth);
			}	
			
			if(rCH < puits_rsm->round){
				Depth_CH_Init = 0xff;                           //a chaque nouveau round on initialise la profondeur initiale pour la comparer à celle des cluster head et prend la plus petite
				round_CH = FALSE;
				rCH = puits_rsm->round;
				
				probability = probability_buf;
				recu=FALSE;	 	     
				//dbg(DebugApp, "le rCH  est:  %i\n",rCH);	                                               //à effacer
		
				if (rCH%(total_node/total_ch)==0){                            //le round doit etre réinitialiser à zéro car il a atteint total_node/total_ch round donc tous les CH doivent revenir à faux 
					isClusterHead = FALSE;
					Table_Entree_Membre = 0;
					Table_Membre_Reelle = 0;
					temp_moyenne = 0;
				}
			}
		
			if ( (!recu) && (!isClusterHead) &&(TOS_NODE_ID != BASE_STATION_ADDRESS)) {
				float randNo = (float)call Random.rand16()/(float)100000;			 
				recu = TRUE;
				call ReqRelayTimer.startOneShot((call Random.rand16())%800+200); 
	
				dbg("DebugApp", "I recived a message from node %i.\n", puits_rsm->ID);
				dbg("DebugApp", "I am node %i. I want to be CH.\n", TOS_NODE_ID);
				dbg("DebugApp", "I recived new round = %i.\n", puits_rsm->round);   
				dbg("DebugApp", "The probability for selection as CH is = %f.\n", probability_buf);//à effacer  puits_rsm->probability
				dbg("DebugApp", "The random nomber that i generated, is = %f.\n", randNo);			 

				if (puits_rsm->round % total_node/total_ch == 0){ 
					isClusterHead = FALSE; 
				}
				
				call MoteWackup.startOneShot(LEACH_ROUND_LENGTH-1000);

			    if ((randNo < probability_buf) && (!isClusterHead)){		 		
					dbg("DebugApp", "My probability show that %i can be CH for this round @%s.\n", TOS_NODE_ID, sim_time_string());
				 	isClusterHead = TRUE;
				 	round_CH = TRUE; 
				 	dbg("DebugGraph",";%i;%i;CH;1 \n",TOS_NODE_ID,BASE_STATION_ADDRESS);
			    }
				
				if (isClusterHead){
					call Timer1.startPeriodic(1000); 
				   	dbg("DebugApp", "Set timer for annonce \t@%s\n", sim_time_string());
				   	call AnnonceTimer.startOneShot(ANNONCE_LENGTH+((call Random.rand16())%800+200)); 
				   	frequence = (uint16_t) call Random.rand16()/100;
				   	dbg("DebugApp", "frequence is %i\n", frequence);
				}
			}
		
	    	return msg;
		}
	}
	
	event message_t* ANNONCE_ReceiveMsg.receive(message_t* msg, 
				   void* payload, uint8_t len) {
	  	uint16_t rand=0;
	  	if (len != sizeof(puits_msg_t)) {
				dbg("DebugApp", "error here (puits_msg_t)!\n"); 
				return msg;
			}
    	else {
      		puits_msg_t* puits_rsm = (puits_msg_t*)payload;				
		  	
		    if ((!round_CH)&&(TOS_NODE_ID != BASE_STATION_ADDRESS)) {
			 	dbg("DebugApp", "==================================================================================\n");	                                                	 	 	 
			 	dbg("DebugApp", "===== In node %i, Recive a message from CH %i \t@%s                                  ====\n", TOS_NODE_ID, puits_rsm->ID, sim_time_string());	                                                	 	 	 
			 	dbg("DebugApp", "==================================================================================\n");
		 
			 	if(rCH < puits_rsm->round){
		       		Depth_CH_Init = 0xff;  
			   		rCH = puits_rsm->round;
		      	}

			 	dbg("DebugApp", "The node  %i is CH.\n", puits_rsm->ID);
			 	dbg("DebugApp", "Its depth is = %i.\n", puits_rsm->Depth);
			 	dbg("DebugApp", "The depth that initialized is = %i.\n", Depth_CH_Init);
			 
			 	if (puits_rsm->Depth <= Depth_CH_Init) {
					if(puits_rsm->Depth == Depth_CH_Init){   //on va choisir aléatoirement le CH car leur profondeur est égale
					  	uint16_t randNo = call Random.rand16();			 
					  	if(randNo > 45000){
					  		ID_CH_CHOISI = puits_rsm->ID;       
				      	}
			    	}
			    	else{                              //dans le deuxieme cas ça veut dire que la profondeur est plus petite alors on choisie celui dont la profondeur est petite
			      		ID_CH_CHOISI = puits_rsm->ID;
			    	}		 
			    
					Depth_CH_Init = puits_rsm->Depth;
			    	dbg("DebugApp", "I belong to CH : %i \t@%s\n", ID_CH_CHOISI, sim_time_string());
					//attentdre un certain temps avant d'annoncer au CH c'est le temps de traiter tous le CH auxquels un noeud peut appatenir
					rand = (call Random.rand16())%2000+200;
					dbg("DebugApp", "I belong to CH : %i \t@%s\n", ID_CH_CHOISI, sim_time_string());
					call OrganisationTimer.startOneShot(ORGANISATION_LENGTH+rand); 
				}
			}
		
	      	return msg;
		}
	}		

	event message_t* ORGANISATION_ReceiveMsg.receive(message_t* msg, 
				   void* payload, uint8_t len) {
		
		if (len != sizeof(member_msg_t)) {
			dbg("DebugApp", "error here (member_msg_t)!\n"); 
			return msg;
		}
    	else {
      		member_msg_t* member_rsm = (member_msg_t*)payload;		
		 
	     	if(member_rsm->ID_CH == TOS_NODE_ID){
	      		cluster_head_msg_t* ch_rsm;
	      		ch_rsm = (cluster_head_msg_t*)call Packet.getPayload(&packet, sizeof(cluster_head_msg_t));
	      		
	      		if (member_rsm->req == 1){
		    		dbg("DebugApp", "====================================================================\n");	                                                	 	 	 
		    		dbg("DebugApp", "===== I am CH %i. I recived a request for admission from node %i \t@%s  ====\n", member_rsm->ID_CH, member_rsm->ID_MEMBRE, sim_time_string());	                                                	 	 	 
		    		dbg("DebugApp", "====================================================================\n");
		    		
					Table_Entree_Membre = Table_Entree_Membre + 1;
		 			dbg("DebugApp","I am CH %i, Node %i is a my member. I have %i membre.\n", member_rsm->ID_CH, member_rsm->ID_MEMBRE, Table_Entree_Membre);

		    		ch_rsm->ID_MEMBRE = member_rsm->ID_MEMBRE;
					ch_rsm->ID_CH = TOS_NODE_ID;
					//ptrCH->donne_aggreger=;
					ch_rsm->SLOT_ATTRIBUER = Table_Entree_Membre;
					ch_rsm->FREQ = frequence;
					dbg("DebugApp", "It will send request with a CDMA code %i to %i.\n", ch_rsm->FREQ , ch_rsm->ID_MEMBRE);		
				
					if (call SLOT_SendMsg.send(ch_rsm->ID_MEMBRE, &packet, sizeof(cluster_head_msg_t)) == SUCCESS) {locked = TRUE;}
					
		   		}
		   		else if (member_rsm->req == 2){
		    
					dbg("DebugApp", "====================================================================\n");	                                                	 	 	 
	    			dbg("DebugApp", "=====I am CH %i. I recived temp value  %i, from my member %i \t@%s     ==\n", member_rsm->ID_CH, member_rsm->temp, member_rsm->ID_MEMBRE, sim_time_string());	                                                	 	 	 
	    			dbg("DebugApp", "====================================================================\n");	 	
		 
		 			dbg("DebugApp", "I am CH %i.\n", member_rsm->ID_CH);
		 			dbg("DebugApp", "The member %i sent this information: temp= %i\n", member_rsm->ID_MEMBRE, member_rsm->temp);
		 			temp_moyenne = temp_moyenne + member_rsm->temp;   
		 			Table_Membre_Reelle = Table_Membre_Reelle + 1;
		 			dbg("DebugApp", "I will collect information.\n");
		 			ch_rsm->NBR_MBR = nbre_conectiv = nbre_conectiv + ch_rsm->NBR_MBR+1;

         			call AggregerTimer.startOneShot(((Table_Entree_Membre)*(SLOT_LENGTH))); 
		   		}
		 	}
		 	return msg;
		}
	}		

	event message_t* SLOT_ReceiveMsg.receive(message_t* msg, 
				   void* payload, uint8_t len) {
				   	
		if (len != sizeof(cluster_head_msg_t)) {
			dbg("DebugApp", "error here (cluster_head_msg_t)!\n"); 
			return msg;
		}
    	else {
      		cluster_head_msg_t* ch_rms = (cluster_head_msg_t*)payload;
			
		  	dbg("DebugApp", "Passed!\n");
		  	if(ch_rms->ID_MEMBRE == TOS_NODE_ID){
		  		dbg("DebugApp", "====================================================================\n");	                                                	 	 	 
		  		dbg("DebugApp", "=====   I am node %i, i recived slot number from CH %i \t@%s  ====\n", TOS_NODE_ID, ch_rms->ID_CH, sim_time_string());	                                                	 	 	 
		  		dbg("DebugApp", "====================================================================\n");
		  		
		  		mySlot = ch_rms->SLOT_ATTRIBUER;
		  		dbg("DebugApp", "My slot number is = %i.\n", mySlot);
		  		dbg("DebugGraph",";%i;%i;Mote;1 \n",TOS_NODE_ID,ch_rms->ID_CH);	
		  		call OrdonnecementTimer.startOneShot(((mySlot)*(SLOT_LENGTH)) + ch_rms->FREQ); 
		  		
		  		//Start radio
				//call RadioControl.stop();	      
		 	}
		 	return msg;	
		}	
	}		

	event message_t* AGGREGATION_ReceiveMsg.receive(message_t* msg, 
				   void* payload, uint8_t len) {
	 
	    if(TOS_NODE_ID==BASE_STATION_ADDRESS){	    
			cluster_head_msg_t* ch_rms = (cluster_head_msg_t*)payload;

			dbg("DebugApp", "==========================================================================\n");	                                                	 	 	 
	    dbg("DebugApp", "=====  I am BaseStation, I recived collected information %i from CH %i \t@%s ==\n", ch_rms->donne_aggreger, ch_rms->ID_CH, sim_time_string());	                                                	 	 	 
	    dbg("DebugApp", "==========================================================================\n");
			dbg("DebugApp", "I recived Collected température %i From CH %i.\n", ch_rms->donne_aggreger, ch_rms->ID_CH);
			nbre_conectiv = nbre_conectiv + ch_rms->NBR_MBR + 1;		
			call NBRECPNNECTimer.startOneShot(30000);	       
		}

	 	return msg;
	}		
		
	event void ReqRelayTimer.fired(){
		puits_msg_t* puits_rms;
		puits_rms = (puits_msg_t*)call Packet.getPayload(&packet, sizeof(puits_msg_t));

		if (puits_rms == NULL) { return; }
		else{
			puits_rms->round = rCH;
			puits_rms->probability = (uint32_t)((float)probability*(float)1000);
			dbg("DebugApp", "Relay annonce timer fired @%s\n",sim_time_string());	 	
		    puits_rms->ID = TOS_NODE_ID;	  	
			puits_rms->Depth = depth;
			if (call LEACH_SendMsg.send(TOS_BCAST_ADDR, &packet, sizeof(puits_msg_t)) == SUCCESS) {locked = TRUE;}
		}
    }

	event void Timer1.fired(){	
    	atomic{ 
			call Leds.led1Toggle();
 	  	}
  	}
	
	event void AnnonceTimer.fired(){  
		//float* f_buf;
		puits_msg_t* puits_rms;
		puits_rms = (puits_msg_t*)call Packet.getPayload(&packet, sizeof(puits_msg_t)); 
		if (puits_rms == NULL) { return; }
		else{		
			call Leds.led1Toggle();
			call Leds.led2Toggle();
			//call Leds.led3Toggle();
			call Timer1.stop();	    
			
			dbg("DebugApp", "==========================================================================\n");	             
			dbg("DebugApp", "===== I annonce as CH and attract other mote to yourself.\t@%s   ====\n", sim_time_string());
			dbg("DebugApp", "==========================================================================\n");

			puits_rms->round = rCH;
			//f_buf = &probability;
			//dbg("DebugApp", "MFA:Probability for sent to members is %f  \n",probability);
			puits_rms->probability =  (uint32_t)((float)probability*(float)1000);		
		    puits_rms->ID = TOS_NODE_ID;	  
		    //ptr->Status=2;		
		    if (call ANNONCE_SendMsg.send(TOS_BCAST_ADDR, &packet, sizeof(puits_msg_t)) == SUCCESS) {locked = TRUE;}
	    }
    }

	event void OrganisationTimer.fired(){		
		Envoie_MEMBRE_CH();		
	}

	event void OrdonnecementTimer.fired(){
	   	member_msg_t* member_rms;
	   	member_rms = (member_msg_t*)call Packet.getPayload(&packet, sizeof(member_msg_t)); 
	   	
	   	if (member_rms == NULL) { return; }
		else{	
		   	uint16_t randNo =(uint16_t) call Random.rand16()/1000;			 
		   	
		   	dbg("DebugApp", "==========================================================================\n");	             
			dbg("DebugApp", "===== My slot %i start here. \t@%s   ====\n", mySlot, sim_time_string());
			dbg("DebugApp", "==========================================================================\n");
	   		dbg("DebugApp", "The temp that i measure is %i.\n",randNo);	
		   	
		   	//Start radio
			//call RadioControl.start();
		   	
		   	dbg("DebugApp", "I send measured temp %i to my CH  %i.\n",randNo,ID_CH_CHOISI);	
		   	member_rms->ID_MEMBRE = TOS_NODE_ID;
		   	member_rms->ID_CH = ID_CH_CHOISI;
		   	member_rms->req = 2; 
		   	member_rms->temp = randNo; 
		   	   
		   	if (call ORGANISATION_SendMsg.send(member_rms->ID_CH, &packet, sizeof(member_msg_t)) == SUCCESS) {locked = TRUE;}
		}
	}

	event void AggregerTimer.fired(){
		uint8_t mTemp=0;
		cluster_head_msg_t* cluster_rms;
		cluster_rms = (cluster_head_msg_t*)call Packet.getPayload(&packet, sizeof(cluster_head_msg_t)); 

		if (cluster_rms == NULL) { return; }
		else{	
			if(Table_Membre_Reelle >0)
				mTemp = temp_moyenne/Table_Membre_Reelle;
			else
				mTemp=0;
						
			dbg("DebugApp", "I am CH  %i.\n",TOS_NODE_ID);		
			dbg("DebugApp", "The Temp moyenne is %i and member count is %i\n",temp_moyenne , Table_Membre_Reelle); 			
			dbg("DebugApp", "The collected temp is %i.\n",mTemp);		//
			//dbg("DebugApp", "je vais envoyer cette information au noeud PUITS\n");					
			//dbg("DebugApp", "le nombre de MEMBRE qui font partie de mon groupe est de %i\n",Table_Entree_Membre);					
			//dbg("DebugApp", "le nombre de MEMBRE qui ont réellement envoyer les données est de %i\n",Table_Membre_Reelle);					
			cluster_rms->NBR_MBR = Table_Membre_Reelle;
			//cluster_rms->ID_MEMBRE = ptrM->ID_MEMBRE;
			cluster_rms->ID_CH = TOS_NODE_ID;
			cluster_rms->donne_aggreger = mTemp;
			//cluster_rms->SLOT_ATTRIBUER = Table_Entree_Membre;
			if (call AGGREGATION_SendMsg.send(BASE_STATION_ADDRESS, &packet, sizeof(cluster_head_msg_t)) == SUCCESS) {locked = TRUE;}
		}
	}
	
	event void NBRECPNNECTimer.fired(){
		//dbg("DebugApp","le nombre de noeuds connecté %i \n",nbre_conectiv+1);				   
   	}
   
	event void RoundTimerStart.fired(){
		uint32_t r_duration=ANNONCE_LENGTH + ORGANISATION_LENGTH + ((total_node)*SLOT_LENGTH*0.25);
		
		dbg("DebugApp", "==================================================================================\n");
		dbg("DebugApp", "=====Preview rount finished @%s                                              ====\n", sim_time_string());
		dbg("DebugApp", "==================================================================================\n");		
		dbg("DebugApp", "Start radio and Triggering a new round.\n");
		
		//Start radio
		call RadioControl.start();
		
		dbg("DebugApp","Round duration is %i. @%s\t\n", r_duration, sim_time_string());	
		call RoundTimerEnd.startOneShot(r_duration);

		//Envoie();
	}
	
	event void RoundTimerEnd.fired(){
		dbg("DebugApp", "==================================================================================\n");
		dbg("DebugApp", "=====The rount timed out @%s                                              ====\n", sim_time_string());
		dbg("DebugApp", "==================================================================================\n");		
		
		//Start radio
		call RadioControl.stop();
	}
	
	event void MoteWackup.fired(){
		dbg("DebugApp", "==================================================================================\n");
		dbg("DebugApp", "=====Mote wakeup @%s                                              ====\n", sim_time_string());
		dbg("DebugApp", "==================================================================================\n");		
		
		//Start radio
		call RadioControl.start();
	}

	event void LEACH_SendMsg.sendDone(message_t *msg, error_t error){
        if (&packet == msg) { 
        	locked = FALSE; 
        }
    }

	event void ANNONCE_SendMsg.sendDone(message_t *msg, error_t error){
        if (&packet == msg) { locked = FALSE; }
    }

	event void ORGANISATION_SendMsg.sendDone(message_t *msg, error_t error){
        if (&packet == msg) { 
        	locked = FALSE; 
        	dbg("DebugApp", "MFA: ORGANISATION_SendMsg.\n");
        	
        	//Stop radio
			//call RadioControl.stop();
        }
    }

	event void SLOT_SendMsg.sendDone(message_t *msg, error_t error){
        if (&packet == msg) { 
        	//dbg("DebugApp", "CDMA Message sent.\n");
        	locked = FALSE; 
        }
    }

	event void AGGREGATION_SendMsg.sendDone(message_t *msg, error_t error){
        if (&packet == msg) { locked = FALSE; }
        
        //Start radio
		call RadioControl.stop();
    }
    
    event void Read.readDone(error_t result, uint16_t val){
		// TODO Auto-generated method stub
	}
}	
