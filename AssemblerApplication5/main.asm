/*
AssemblerApplication5.asm
This code is written in assembly language for an AVR Atmega32 microcontroller. It controls the behavior of a traffic light system that has two modes: car mode and person mode.

In car mode, the traffic light system displays a green light for cars and a red light for pedestrians. In person mode, 
the traffic light system displays a green light for pedestrians and a red light for cars.;The code uses an external interrupt to detect when a pedestrian has pushed a button to cross the street. 
If the button is pressed and the yellow light for cars is currently on, 
the code will turn on the red light for cars in car mode and the green light for pedestrians in person mode,
instead of turning on the green light for cars in car mode and returning to car mode.

The code sets up the necessary I/O registers and enables global interrupts,
It then enters an infinite loop where it alternates between car mode and person mode, with delays in between. 

In each mode, it turns on and off the appropriate lights using the SBI (set bit in I/O register) and CBI (clear bit in I/O register) instructions. 
When the button is pressed and the code enters person mode, it clears the external interrupt flag and re-enables global interrupts before returning to the main loop.
*/

;
.INCLUDE "M32DEF.INC"
.ORG 0
   JMP MAIN
.ORG 0X02
   JMP EX0_ISR  ; vector location for external interrupt
MAIN:  ; set configrations---------- 
 ;-------------------------------CAR MODE---------------------
 SBI DDRA,0 ;init led red as output (SBI : this instruction using to set bit in I/O register and take name of register and number of bit)
 SBI DDRA,1 ;init led yellow as output
 SBI DDRA,2 ;init led green as output
 ;------------------------------PERSON MODE---------------------
 SBI DDRC,0 ;init led red as output
 SBI DDRC,1 ;init led yellow as output
 SBI DDRC,2 ;init led green as output
 ;------------------------- 
 LDI R16,0x02  ;(LDI : store value in (GPR))
 OUT MCUCR,R16; MAKE INT0 IS FALLING EDGE this mean when button is low and become high (OUT : store (GPR) to I/O register location)
 CBI DDRD,2; init button as input 
 LDI R16,1<<INT0;enable INT0
 OUT GICR,R16
 SEI; enable global interrupts
CAR_MODE:
   SBI PORTA,0; RED_CAR_ON (SBI : set bit 0 in port A)
   SBI PORTC,2; GREEN_PERSON_ON
   CALL DELAY_30s ;  delay using timer register
   CBI PORTA,0;RED_CAR_OFF (CBI : clear 0 in port A )
   CBI PORTC,2;GREEN_PERSON_OFF
   SBI PORTA,1;YELLOW_CAR_ON
   SBI PORTC,1;YELLOW_PERSON_ON
   CALL DELAY_30s
   SBIC PORTA,6 ; (SBIC: skip next instruction if bit 6 in port A is low(bit 6= 0))
   JMP PERSON_MODE ;( this mean the interrupt is happened )
   ;NOP
   CBI PORTA,1;YELLOW_CAR_OFF
   CBI PORTC,1;YELLOW_PERSON_OFF
   SBI PORTA,2; GREEN_CAR_ON
   SBI PORTC,0; GREEN_PERSON_ON
   CALL DELAY_30s
   CBI PORTA,2; GREEN_CAR_OFF
   CBI PORTC,0; GREEN_PERSON_OFF
   JMP CAR_MODE
PERSON_MODE:
   CBI PORTA,1;YELLOW_CAR_OFF 
   CBI PORTC,1;YELLOW_PERSON_OFF
   SBI PORTC,2;GREEN_PERSON_ON
   SBI PORTA,0;RED_CAR_ON
   CALL DELAY_30s
   CBI PORTA,0;RED_CAR_OFF
   CBI PORTC,2;GREEN_PERSON_OFF
   CBI PORTA,6; i cleared this bit becuase if the button is pushed agine
   SBI PORTA,2; GREEN_CAR_ON
   SBI PORTC,0; RED_PERSON_ON
   CALL DELAY_30s
   CBI PORTA,2; GREEN_CAR_OFF
   CBI PORTC,0; RED_PERSON_OFF
   SEI; enable interrupts 
   JMP CAR_MODE
;---------------ISR for external INT0(interrupt 0) if button is pushed and yellow led in car mode is on i will turn on pin 6 in port A to check it before
; turn on led Light in car mode if is high i will switch to person mode and person can cross street 
EX0_ISR:
   SBIC PORTA,1 ; skip next instruction if this bit is low
   SBI PORTA,6  ; set this bit (this bit is high)
   RETI ;return from interrupt
;-------------------------Timer delay : - make timer in normal mode and make 1000 overflow to make this delay 
DELAY_30s:
    LDI R28,10
L6:
	 CALL DELAY
	 DEC R28
	 BRNE L6 ;
	 RET
DELAY: LDI R18,0x00
       OUT TCNT0,R18 ; init value for timer0 equal to zero
	   LDI R18,0x01
	   OUT TCCR0,R18 ; timer0 is normal mode , no prescaler
	   LDI R25,10
B1:
    LDI R22,100
AGIN:  IN R18,TIFR ; read TIFR(Timer interrupt flag register)
       SBRS R18,TOV0 ;IF TOV0 IS SET SKIP NEXT INSTRUCTION ( is mean the overflow is happened in timer)
	   RJMP AGIN
	   DEC R22
	   LDI R18,(1<<TOV0)
	   OUT TIFR,R18 ;CLEAR TOV0 FLAG BY WEITING A 1TO TIFR
	   BRNE AGIN
	   DEC R25
	   BRNE B1
	   LDI R18,0x00
	   OUT TCCR0,R18;STOP TIMER   
	   RET