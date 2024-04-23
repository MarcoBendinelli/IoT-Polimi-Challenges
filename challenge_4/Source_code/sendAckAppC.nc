#include "sendAck.h"

configuration sendAckAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, sendAckC as App;
  
  //add the other components here
  components ActiveMessageC;
  components new AMReceiverC(AM_MY_MSG);
  components new AMSenderC(AM_MY_MSG);
  components new TimerMilliC();
  components new TimerMilliC() as TurningOffTimerC;
  components new FakeSensorC();

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  
  //Radio Control
  App.SplitControl -> ActiveMessageC;
  
  //Interfaces to access package fields
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements -> AMSenderC;
  
  //Timer interface
  App.MilliTimer -> TimerMilliC;
  App.TurningOffTimer -> TurningOffTimerC;
  
  //Fake Sensor read
  App.Read -> FakeSensorC;

}

