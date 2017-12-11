configuration LeachAppC{
}
implementation
{ 
  	components MainC, LeachC as App, LedsC, RandomC, new DemoSensorC();
  	components ActiveMessageC;
	components TossimActiveMessageC;
  	
	components new AMReceiverC(AM_MHMESSAGE) as LEACH_AMR;
  	components new AMSenderC(AM_MHMESSAGE) as LEACH_AMS;
	components new AMReceiverC(AM_MEMBRE) as ANNONCE_AMR;
  	components new AMSenderC(AM_MEMBRE) as ANNONCE_AMS;
  	components new AMReceiverC(AM_ORGANISATION) as ORGANISATION_AMR;
  	components new AMSenderC(AM_ORGANISATION) as ORGANISATION_AMS;
  	components new AMReceiverC(AM_SLOT) as SLOT_AMR;
  	components new AMSenderC(AM_SLOT) as SLOT_AMS;
  	components new AMReceiverC(AM_AGGREGATION) as AGGREGATION_AMR;
  	components new AMSenderC(AM_AGGREGATION) as AGGREGATION_AMS;
  	
  	components new TimerMilliC() as ReqRelayTimer;
  	components new TimerMilliC() as RoundTimerStart;
  	components new TimerMilliC() as RoundTimerEnd;
  	components new TimerMilliC() as WakeupTimer;
  	components new TimerMilliC() as AnnonceTimer;
  	components new TimerMilliC() as OrganisationTimer;
  	components new TimerMilliC() as OrdonnecementTimer;
  	components new TimerMilliC() as AggregerTimer;
  	components new TimerMilliC() as NBRECPNNECTimer;
  	components new TimerMilliC() as Timer1;
	
	//MainC.StdControl -> MHLeachPSM.StdControl;
	//MainC.StdControl -> Comm.Control;
	//MainC.StdControl -> TimerC.StdControl;
	
	App.Boot -> MainC.Boot;
	App.Leds -> LedsC;
	App.Random -> RandomC;
	App.Read -> DemoSensorC;

	App.RadioControl -> ActiveMessageC;
	App.TossimPacket -> TossimActiveMessageC;
	App.PacketAcknowledgements -> ActiveMessageC;//Annonce_AMS;
	App.Packet -> ActiveMessageC;//Annonce_AMS;
	App.AMPacket -> ActiveMessageC;//Annonce_AMS;
	
	App.LEACH_ReceiveMsg -> LEACH_AMR;
	App.LEACH_SendMsg -> LEACH_AMS;
	App.ANNONCE_ReceiveMsg -> ANNONCE_AMR;
	App.ANNONCE_SendMsg -> ANNONCE_AMS;
	App.ORGANISATION_ReceiveMsg -> ORGANISATION_AMR;
	App.ORGANISATION_SendMsg -> ORGANISATION_AMS;
	App.SLOT_ReceiveMsg -> SLOT_AMR;
	App.SLOT_SendMsg -> SLOT_AMS;
	App.AGGREGATION_ReceiveMsg -> AGGREGATION_AMR;
	App.AGGREGATION_SendMsg -> AGGREGATION_AMS;

	App.ReqRelayTimer -> ReqRelayTimer;
	App.RoundTimerStart -> RoundTimerStart;	
	App.RoundTimerEnd -> RoundTimerEnd;	
	App.MoteWackup -> WakeupTimer;		
	App.AnnonceTimer -> AnnonceTimer;		
	App.OrganisationTimer -> OrganisationTimer;		
	App.OrdonnecementTimer -> OrdonnecementTimer;
	App.AggregerTimer -> NBRECPNNECTimer;
	App.NBRECPNNECTimer -> NBRECPNNECTimer;
	App.Timer1 -> Timer1;
}
