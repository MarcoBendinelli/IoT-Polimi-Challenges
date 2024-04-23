#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration Challenge3AppC{
}
implementation {
  components MainC, Challenge3C, LedsC;
  components new TimerMilliC();
  components SerialPrintfC;
  components SerialStartC;

  Challenge3C.Boot -> MainC;
  Challenge3C.Timer -> TimerMilliC;
  Challenge3C.Leds -> LedsC;
}
