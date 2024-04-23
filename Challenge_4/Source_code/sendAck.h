#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct my_msg {
  //field 1: REQ/RESP
  nx_uint8_t msg_type;
	
  //field 2: incremental integer
  nx_uint32_t msg_counter;
	
  //field 3: value from the fake sensor (uint16_t is also ok)
  nx_uint32_t value;

} my_msg_t;

#define REQ 1
#define RESP 2 

#define CLIENT 1
#define SERVER 2
#define TIMER_PERIOD 1000

enum{
  AM_MY_MSG = 6,
};

#endif
