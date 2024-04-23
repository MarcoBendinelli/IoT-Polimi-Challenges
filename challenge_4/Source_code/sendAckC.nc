/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	interface SplitControl;
	
    //interfaces for communication
    interface Receive;
    interface AMSend;    
    
	//interface for timer
	interface Timer<TMilli> as MilliTimer;
	interface Timer<TMilli> as TurningOffTimer;
	
    //other interfaces, if needed
    interface Packet;
	interface PacketAcknowledgements;
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t last_digit = 9;
  uint8_t counter = 1;
  uint8_t packet_content_counter = 0;
  //uint8_t rec_id;
  message_t packet;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
  // This function is called when we want to send a request
	 
  // 1. Prepare the msg
  
  my_msg_t* request = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
  
  if (request == NULL)
    return;
  
  request->msg_type = REQ;
  request->msg_counter = counter;
  request->value = 0;
  
  // 2. Set the ACK flag for the message using the PacketAcknowledgements interface
  
  call PacketAcknowledgements.requestAck(&packet);

  // 3. Send an UNICAST message to the correct node

  call AMSend.send(SERVER, &packet, sizeof(my_msg_t));
  
  dbg("radio_send","The mote 1 tries to send a packet to the mote 2 with the following information:\n");  
  dbg_clear("radio_pack", "           packet type (1: Request, 2: Response): %hhu,", request->msg_type);
  dbg_clear("radio_pack", " counter : %hhu\n", request->msg_counter);	 
  }       

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raises the event read done.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    if (err == SUCCESS) {
    
      if (TOS_NODE_ID == CLIENT) {
        call MilliTimer.startPeriodic(TIMER_PERIOD);
        dbg("init", "The mote %d has turn on the Timer\n", TOS_NODE_ID);
      }
        
    } else {
      call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){
    dbg("radio", "Stop done by the SplitControl of the mote %d\n", TOS_NODE_ID);
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
    /* This event is triggered every time the timer fires.
    * When the timer fires, we send a request
	*/
	sendReq();
  }
  
  //***************** TurningOffTimer interface ********************//
  event void TurningOffTimer.fired() {
    /* This event is triggered just once when the mote1 ends.
    *  When the timer fires, we send stop the SplitControl
	*/
	call SplitControl.stop();
  }
  
  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf, error_t err) {
    // This event is triggered when a message is sent 
    
    my_msg_t* msg_sent = (my_msg_t*)call Packet.getPayload(buf, sizeof(my_msg_t));
    
    // 1. Check if the packet is sent
      
    if (err == SUCCESS)
      dbg("radio_send","The packet %hhu was sent successfully by the mote %d\n", msg_sent->msg_counter, TOS_NODE_ID);
    else {
      dbgerror("radio_send","The packet %hhu was NOT sent successfully by the mote %d\n", msg_sent->msg_counter, TOS_NODE_ID);
      return;
    }
    
    // 2. Check if the ACK is received (read the docs)
	
	if (call PacketAcknowledgements.wasAcked(&packet) == TRUE)
	  dbg("radio_ack", "The packet %hhu sent by the mote %d was acknowledged successfully\n", msg_sent->msg_counter, TOS_NODE_ID);
  	else {
	  dbgerror("radio_ack", "The packet %hhu sent by the mote %d was NOT acknowledged successfully\n", msg_sent->msg_counter, TOS_NODE_ID);
	  return;
	}
	
	// 2a. If yes, stop the timer according to my id (10673478 so X = 9). The program is done
	// 2b. Otherwise, send again the request
	
	if (TOS_NODE_ID == CLIENT) {
	
	  if (msg_sent->msg_counter == last_digit) {
	    call MilliTimer.stop();
	    call TurningOffTimer.startOneShot(1000);
	    dbg("radio", "All packets are sent, now the timer is off\n");
	  } else {
	    dbg("radio", "I need to send other %hhu packets\n", last_digit - counter);
	    counter++;
	  }	
	}
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len) {
    // This event is triggered when a message is received

    my_msg_t* msg_received = (my_msg_t*)payload;
    packet_content_counter = msg_received->msg_counter;
      
    // 1. Read the content of the message
    
    dbg("radio_rec","A message is received, check the content of the message\n");  
    dbg_clear("radio_pack", "           packet type (1: Request, 2: Response): %hhu,", msg_received->msg_type);
    dbg_clear("radio_pack", " counter : %hhu,", msg_received->msg_counter);
    dbg_clear("radio_pack", " reading : %hhu\n", msg_received->value);
    
    // 2. Check if the type is request (REQ)
    // 3. If a request is received, send the response
    
    if (msg_received->msg_type == REQ)
      sendResp();
             
    return buf;
  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
  // This event is triggered when the fake sensor finishes to read (after a Read.read()) 

  // 1. Prepare the response (RESP)
  
  my_msg_t* response = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
  
  if (response == NULL)
    return;
    
  response->msg_type = RESP;
  response->msg_counter = packet_content_counter;
  response->value = data;  
  
  // 2. Set the ACK flag for the message using the PacketAcknowledgements interface
  
  call PacketAcknowledgements.requestAck(&packet);
  
  // 3. Send back (with a unicast message) the response
  
  call AMSend.send(CLIENT, &packet, sizeof(my_msg_t));
  
  dbg("radio_send","The mote 2 tries to send a packet to the mote 1 with the following information:\n");  
  dbg_clear("radio_pack", "           packet type (1: Request, 2: Response): %hhu,", response->msg_type);
  dbg_clear("radio_pack", " counter : %hhu,", response->msg_counter);
  dbg_clear("radio_pack", " reading : %hhu\n", response->value);
  }
}

