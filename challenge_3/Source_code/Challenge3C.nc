#include "printf.h"
#define PERSONAL_CODE 10673478
#define TIMER_PERIOD 60000

module Challenge3C {
  uses {
    interface Boot;
    interface Timer<TMilli>;
    interface Leds;
  }
}

implementation {

  uint8_t ledId;
  uint32_t toConvert = PERSONAL_CODE;
  uint8_t base = 3;
  uint8_t statusLed0 = 0;
  uint8_t statusLed1 = 0;
  uint8_t statusLed2 = 0;
  	
  event void Boot.booted() {
    call Timer.startPeriodic(TIMER_PERIOD);	
  }

  event void Timer.fired() {
     
    ledId = toConvert % base;
  	
    if (toConvert != 0) {
    
      if (ledId == 0) {
        call Leds.led0Toggle();
        statusLed0 = !statusLed0;
      }
      
      else if (ledId == 1) {
        call Leds.led1Toggle();
        statusLed1 = !statusLed1;
      }
        
      else if (ledId == 2) {
        call Leds.led2Toggle();
        statusLed2 = !statusLed2;
      }
            
  	  printf("%u%u%u\n", statusLed0, statusLed1, statusLed2);
  	  printfflush();
  	}
    else
      call Timer.stop();
  
    toConvert = toConvert / base;
  }
}
