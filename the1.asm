LIST P=18F4620
    
#include <P18F4620.INC>

			    
; You may go over the list below to understand the code better.
;
;		    GIST
; (1)	Global Variables				line :   67 - 125
; (2)	Initialization and Start-Up Phase		line :	130 - 210	
; (3)	main_fake (main is used as 200ms loop label)	line :	909 - 991
;
;
;	    INDIVIDUAL PROCEDURES
; (4)	turn_on_row / turn_off_row			line :	220 - 272
; (5)	update_leds					line :	276 - 287
; (6)	row_select_button				line :	291 - 509
; (7)	drawing_buttons					line :  513 - 891
;
;
; Author : Ahmet Can Ogreten
;
			
			
config OSC = HSPLL      ; Oscillator Selection bits (HS oscillator, PLL enabled (Clock Frequency = 4 x FOSC1))
config FCMEN = OFF      ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
config IESO = OFF       ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)

; CONFIG2L
config PWRT = ON        ; Power-up Timer Enable bit (PWRT enabled)
config BOREN = OFF      ; Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software)
config BORV = 3         ; Brown Out Reset Voltage bits (Minimum setting)

; CONFIG2H
config WDT = OFF        ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
config WDTPS = 32768    ; Watchdog Timer Postscale Select bits (1:32768)

; CONFIG3H
config CCP2MX = PORTC   ; CCP2 MUX bit (CCP2 input/output is multiplexed with RC1)
config PBADEN = OFF     ; PORTB A/D Enable bit (PORTB<4:0> pins are configured as digital I/O on Reset)
config LPT1OSC = OFF    ; Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation)
config MCLRE = ON       ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)

; CONFIG4L
config STVREN = OFF     ; Stack Full/Underflow Reset Enable bit (Stack full/underflow will not cause Reset)
config LVP = OFF        ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
config XINST = OFF      ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))

; CONFIG5L
config CP0 = OFF        ; Code Protection bit (Block 0 (000800-003FFFh) not code-protected)
config CP1 = OFF        ; Code Protection bit (Block 1 (004000-007FFFh) not code-protected)
config CP2 = OFF        ; Code Protection bit (Block 2 (008000-00BFFFh) not code-protected)
config CP3 = OFF        ; Code Protection bit (Block 3 (00C000-00FFFFh) not code-protected)

; CONFIG5H
config CPB = OFF        ; Boot Block Code Protection bit (Boot block (000000-0007FFh) not code-protected)
config CPD = OFF        ; Data EEPROM Code Protection bit (Data EEPROM not code-protected)

; CONFIG6L
config WRT0 = OFF       ; Write Protection bit (Block 0 (000800-003FFFh) not write-protected)
config WRT1 = OFF       ; Write Protection bit (Block 1 (004000-007FFFh) not write-protected)
config WRT2 = OFF       ; Write Protection bit (Block 2 (008000-00BFFFh) not write-protected)
config WRT3 = OFF       ; Write Protection bit (Block 3 (00C000-00FFFFh) not write-protected)

; CONFIG6H
config WRTC = OFF       ; Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) not write-protected)
config WRTB = OFF       ; Boot Block Write Protection bit (Boot Block (000000-0007FFh) not write-protected)
config WRTD = OFF       ; Data EEPROM Write Protection bit (Data EEPROM not write-protected)

; CONFIG7L
config EBTR0 = OFF      ; Table Read Protection bit (Block 0 (000800-003FFFh) not protected from table reads executed in other blocks)
config EBTR1 = OFF      ; Table Read Protection bit (Block 1 (004000-007FFFh) not protected from table reads executed in other blocks)
config EBTR2 = OFF      ; Table Read Protection bit (Block 2 (008000-00BFFFh) not protected from table reads executed in other blocks)
config EBTR3 = OFF      ; Table Read Protection bit (Block 3 (00C000-00FFFFh) not protected from table reads executed in other blocks)

; CONFIG7H
config EBTRB = OFF      ; Boot Block Table Read Protection bit (Boot Block (000000-0007FFh) not protected from table reads executed in other blocks)

			    
			    
			    
;   ####### START (1) #########   			   		    
timer_vars udata_acs
count_n	    res 1   ;	    These three counters are used inside "wait_for_n_times_10ms" procedure.
count_256_1 res 1   ;	"count_256_1" and "count_256_2" are set in this procedure in a way that with 40MHz
count_256_2 res 1   ;	clock speed, waiting time is approximately "count_n" * 10ms.

button_counter_1	res 1	;	These three counters are used similarly. They will be further explained
button_counter_2	res 1	;   in the main section. For now, knowing that these will help to divide the
button_counter_3	res 1	;   run-time into 200ms periods is enough.	
	
button_states	res 1	;	This register contains states of each button in its first 4 bits. Since only
			;   one of them can be pressed at a time, at most one of the first 4 bits can be 1. 
			;   bit0 -> rb0 -> toggle
			;   bit1 -> rb1 -> down/left
			;   bit2 -> rb2 -> up/right
			;   bit3 -> rb3 -> confirm
			;   0 -> released, 1 -> pressed			
			
TOGGLE	    equ 0   ;	    These will be used to denote different buttons
DOWN_LEFT   equ 1   ;	in conditional skippings
UP_RIGHT    equ 2   ;	for readability.
CONFIRM	    equ 3   ;
	
state	    res 1	    ;	    Since start-up phase will only be accessible
			    ;	at reset, there won't be a separate state for it
			    ;	bit0 -> is in row selection
			    ;	bit1 -> is in line selection
			    
ROW_STATE	equ 0	;	These will be used to denote different buttons
LINE_STATE	equ 1	;   in conditional skippings
			;   for readability.

selected_row	res 1	;   Storing selected state
			;   bit0 = 1-> row0, A
			;   bit1 = 1-> row1, C
			;   bit2 = 1-> row2, D

ROW1	equ 0	;	Denoting different rows
ROW2	equ 1	;   to be used in conditionals
ROW3	equ 2	;   for readabilty.	
	
row1_leds   res 1   ;	    To store which LEDs
row2_leds   res 1   ;	are turned-on at each
row3_leds   res 1   ;	row.
   
candidate   res 1   ;	    Store candidate LEDs in a row in LINE state. It will
		    ;	be initialized as the leftmost LED. When the state changes
		    ;	from LINE to ROW back again, it will be add to row#_leds. 

direction   res 1   ;	    This will be used as the direction of candidate line.
		    ;	bit0 = 0 -> right
		    ;	bit0 = 1 -> left   

led_state   res 1   ;	    This will function as flag so that every 200ms, LEDs
		    ;	will be turned-on and off again.
		    ;	bit0 = 1 -> ON
		    ;	bit0 = 0 -> OFF
;   ####### END (1) ######### 
	   


 
;   ####### START (2) #########   			   		    
org 0x0    
    goto start    
org 0x8
    goto $    
org 0x18
    goto $
    
wait_for_n_times_10ms:  ;n * 10ms (9.98 ms in fact)
    while_count_n:
	movlw 0x82
	movwf count_256_1
	while_count_256_1:
	    setf count_256_2
	    while_count_256_2:
		decf count_256_2
		bnz while_count_256_2
	    decf count_256_1
	    bnz while_count_256_1
	decf count_n
	bnz while_count_n
    return

    
    
start:    
    
    setf ADCON1	;   Configure PORTA as digital
    clrf TRISA	;   PORTA as OUTPUT
    
    clrf TRISC	;   PORTC as OUTPUT
    clrf TRISD	;   PORTD as OUTPUT
    
    setf TRISB	;   PORTB as INPUT  
    
    
    ;******** Go into row selection, selected_row = 1 ********
    clrf state
    bsf state, ROW_STATE	; state = 0x1 -> row selection
    
    clrf selected_row
    bsf selected_row, ROW1	; selected_row = 0x1 -> selected row is A
    
    clrf button_states	; Buttons are unpressed
    
    clrf row1_leds  ; No LED is on at startup
    clrf row2_leds
    clrf row3_leds
    
    clrf led_state
    bsf	led_state, 0	;	LEDs start as ROW1 ON (This is not row#_leds. 
			;   This is for flashing LEDs in ROW state.)
    
    clrf direction  ;	    Direction of candidate is right. (Always will be right
		    ;	when going into LINE state. This will be accomplished by
		    ;	clearing the register when transitioning from LINE state)
    
    clrf candidate	;	    This will be always set to the leftmost LED
    bsf candidate, 0	;	when transitioning into LINE state.
    
    init_complete:  ; for tester
    
    ;************ START-UP PHASE ***************
    setf LATA	; Turn-on all the LEDs
    setf LATC
    setf LATD
    
    movlw 0x64	; 100 in decimal. 100 * 10ms = 1000ms waiting
    movwf count_n
    call wait_for_n_times_10ms
    
    clrf LATA	;   Turn-off all the LEDs again.
    clrf LATC
    clrf LATD
    
    sec_passed:
    
    
    goto main_fake  ;	    This is called main_fake to encapsulate only the loop
		    ;	into the main.
    ;   ####### END (2) #########   			   		    

    
;   ####### START (4) #########	
turn_on_row:			;   Turn-on the selected row
    btfsc selected_row, ROW1
	bra turn_on_row1

    btfsc selected_row, ROW2
	bra turn_on_row2

    btfsc selected_row, ROW3
	bra turn_on_row3

    turn_on_row1:
	setf LATA		;   Turn-on all the LEDs in ROW1    (Due to flashing)
	movff row2_leds, LATC	;   Turn-on drawn shape on ROW2	    (Shape drawn in LINE state)
	movff row3_leds, LATD	;   Turn-on drawn shape on ROW3	    (Shape drawn in LINE state)
	return
    turn_on_row2:
	setf LATC
	movff row1_leds, LATA
	movff row3_leds, LATD
	return
    turn_on_row3:
	setf LATD
	movff row2_leds, LATC
	movff row1_leds, LATA
	return
	
turn_off_row:			;   Turn-off the selected row
    btfsc selected_row, ROW1
	bra turn_off_row1

    btfsc selected_row, ROW2
	bra turn_off_row2

    btfsc selected_row, ROW3
	bra turn_off_row3

    turn_off_row1:
	clrf LATA		;   Turn-off all the LEDs in ROW1   (Due to flashing)
	movff row2_leds, LATC	;   Turn-on drawn shape on ROW2	    (They stay fixed, don't flash remember)
	movff row3_leds, LATD	;   Turn-on drawn shape on ROW2	    (They stay fixed, don't flash remember)
	return
    turn_off_row2:
	clrf LATC
	movff row1_leds, LATA
	movff row3_leds, LATD
	return
    turn_off_row3:
	clrf LATD
	movff row1_leds, LATA
	movff row2_leds, LATC
	return
;   ####### END (4) ######### 

;   ####### START (5) #########
update_led:			; Switch LEDs (flashing)
    btfsc led_state, 0
	goto turn_off	    ;   IF LED is ON
    turn_on:
	call turn_on_row
	bsf led_state, 0    ;	led_state is the state of LEDs flashing
	return
    turn_off:
	call turn_off_row
	bcf led_state, 0
	return
;   ####### END (5) ######### 	
	
    		   		    
;   ####### START (6) ######### 
row_select_button:	    ;	ROW state actions
    nop
    nop		;	These nops are due to the execution time difference between
    nop		;   ROW state and LINE state. LINE state was a little
    nop		;   faster than ROW state. In this way, we make their execution 
    nop		;   time approximately the same. (This is important because we need
    nop		;   to keep 200ms period even the state changes inside loops.)
    nop
    
    ;	Important Points in the rest of the procedure :
    ;		+ Even though we know only one button can be pressed at a time, we 
    ;	    don't quit polling. For example, we may return if we sense that TOGGLE
    ;	    button released after necessary operations. This is not present in code
    ;	    (especially in releasing part) to keep the deterministic nature of the procedure.
    ;	    That is, timings will be as close as possible at each time.
    ;
    ;		+ Releasing or Pressing will add 10ms waiting to make sure.

    toggle_button_check:
	btfsc button_states, TOGGLE	; skip if not pressed
	    bra toggle_pressed

	toggle_released:
	    btfsc PORTB, TOGGLE ; skip if pressed
		bra confirm_button_check

	    toggle_released_pressed:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfsc PORTB, TOGGLE	; skip if pressed
		    bra confirm_button_check

		bsf button_states, TOGGLE
		return

	toggle_pressed:
	    btfss PORTB, TOGGLE ; skip if released
		bra confirm_button_check

	    toggle_pressed_released:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfss PORTB, TOGGLE	; skip if released
		    bra confirm_button_check

		call rb0_released_fake
		bcf button_states, TOGGLE

		btfsc selected_row, ROW1
		    bra toggle_row1

		btfsc selected_row, ROW2
		    bra toggle_row2

		btfsc selected_row, ROW3
		    bra toggle_row3

		toggle_row1:
		    COMF row1_leds, 1
		    bra confirm_button_check
		toggle_row2:
		    COMF row2_leds, 1
		    bra confirm_button_check
		toggle_row3:
		    COMF row3_leds, 1
		    bra confirm_button_check
    confirm_button_check:
	btfsc button_states, CONFIRM    ; skip if not pressed
	    bra confirm_pressed

	confirm_released:
	    btfsc PORTB, CONFIRM	; skip if pressed
		bra up_button_check

	    confirm_released_pressed:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfsc PORTB, CONFIRM    ; skip if still pressed
		    bra up_button_check

		bsf button_states, CONFIRM
		return

	confirm_pressed:
	    btfss PORTB, CONFIRM	; skip if released
		bra up_button_check

	    confirm_pressed_released:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfss PORTB, CONFIRM    ; skip if still released
		    bra up_button_check

		call rb3_released_fake
		bcf button_states, CONFIRM

		bcf state, ROW_STATE
		bsf state, LINE_STATE
		bra up_button_check


    up_button_check:
	btfsc button_states, UP_RIGHT   ; skip if not pressed
	    bra up_pressed

	up_released:
	    btfsc PORTB, UP_RIGHT	; skip if pressed
		bra down_button_check

	    up_released_pressed:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfsc PORTB, UP_RIGHT   ; skip if still pressed
		    bra down_button_check

		bsf button_states, UP_RIGHT
		bra down_button_check

	up_pressed:
	    btfss PORTB, UP_RIGHT	; skip if released
		bra down_button_check

	    up_pressed_released:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfss PORTB, UP_RIGHT   ; skip if still released
		    bra down_button_check

		call rb2_released_fake
		call update_led

		bcf button_states, UP_RIGHT

		btfsc selected_row, ROW1
		    bra up_row1
		btfsc selected_row, ROW2
		    bra up_row2
		btfsc selected_row, ROW3
		    bra up_row3	    

		up_row1:
		    bra down_button_check
		up_row2:
		    clrf selected_row
		    bsf selected_row, ROW1
		    bra down_button_check
		up_row3:
		    clrf selected_row
		    bsf selected_row, ROW2
		    bra down_button_check

    down_button_check:
	btfsc button_states, DOWN_LEFT  ; skip if not pressed
	    bra down_pressed

	down_released:
	    btfsc PORTB, DOWN_LEFT	; skip if pressed
		return

	    down_released_pressed:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfsc PORTB, DOWN_LEFT  ; skip if still pressed
		    return

		bsf button_states, DOWN_LEFT
		return

	down_pressed:
	    btfss PORTB, DOWN_LEFT	; skip if released
		return

	    down_pressed_released:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfss PORTB, DOWN_LEFT  ; skip if still released
		    return

		call rb1_released_fake
		call update_led


		bcf button_states, DOWN_LEFT

		btfsc selected_row, ROW1
		    bra down_row1
		btfsc selected_row, ROW2
		    bra down_row2
		btfsc selected_row, ROW3
		    bra down_row3	    

		down_row1:    
		    clrf selected_row
		    bsf selected_row, ROW2
		    return
		down_row2:
		    clrf selected_row
		    bsf selected_row, ROW3
		    return
		down_row3:
		    return
;   ####### END (6) ######### 
	
    
;   ####### START (7) #########
drawing_buttons:
    
    ;	    Polling is done very similarly. However, at the end there is a little code snippet.
    ;	This part is necessary so that candidate line is drawn in real-time. What it does
    ;	is simple ORing row#_leds with candidate. Then, writing it in a LAT#.
    
    right_button_check:
	btfsc button_states, UP_RIGHT   ; skip if not pressed
	    bra right_pressed

	right_released:
	    btfsc PORTB, UP_RIGHT	; skip if pressed
		bra left_button_check

	    right_released_pressed:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfsc PORTB, UP_RIGHT   ; skip if still pressed
		    bra left_button_check

		bsf button_states, UP_RIGHT
		bra left_button_check

	right_pressed:
	    btfss PORTB, UP_RIGHT	; skip if not pressed
		bra left_button_check

	    right_pressed_released:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfss PORTB, UP_RIGHT   ; skip if still not pressed
		    bra left_button_check

		call rb2_released_fake

		bcf button_states, UP_RIGHT

		btfsc direction, 0	; skil if direction is from right
		    bra to_right_from_left

		to_right_from_right:
		    btfsc candidate, 7
			bra drawing_buttons
		    btfsc candidate, 6
			bra to_right_from_right_7
		    btfsc candidate, 5
			bra to_right_from_right_6
		    btfsc candidate, 4
			bra	to_right_from_right_5
		    btfsc candidate, 3
			bra to_right_from_right_4
		    btfsc candidate, 2
			bra to_right_from_right_3
		    btfsc candidate, 1
			bra to_right_from_right_2
		    btfsc candidate, 0
			bra to_right_from_right_1			

		    to_right_from_right_1:
			bsf candidate, 1
			goto line_rest
		    to_right_from_right_2:
			bsf candidate, 2
			goto line_rest
		    to_right_from_right_3:
			bsf candidate, 3
			goto line_rest
		    to_right_from_right_4:
			bsf candidate, 4
			goto line_rest
		    to_right_from_right_5:
			bsf candidate, 5
			goto line_rest
		    to_right_from_right_6:
			bsf candidate, 6
			goto line_rest
		    to_right_from_right_7:
			bsf candidate, 7
			goto line_rest

		to_right_from_left:
		    btfsc candidate, 0
			bra to_right_from_left_1
		    btfsc candidate, 1
			bra to_right_from_left_2
		    btfsc candidate, 2
			bra to_right_from_left_3
		    btfsc candidate, 3
			bra to_right_from_left_4
		    btfsc candidate, 4
			bra to_right_from_left_5
		    btfsc candidate, 5
			bra to_right_from_left_6
		    btfsc candidate, 6
			bra to_right_from_left_7
		    btfsc candidate, 7
			goto line_rest

		    to_right_from_left_1:
			btfsc candidate, 1
			    bcf candidate, 0
			goto line_rest
		    to_right_from_left_2:
			btfsc candidate, 2
			    bcf candidate, 1
			goto line_rest
		    to_right_from_left_3:
			btfsc candidate, 3
			    bcf candidate, 2
			goto line_rest
		    to_right_from_left_4:
			btfsc candidate, 4
			    bcf candidate, 3
			goto line_rest
		    to_right_from_left_5:
			btfsc candidate, 5
			    bcf candidate, 4
			goto line_rest
		    to_right_from_left_6:
			btfsc candidate, 6
			    bcf candidate, 5
			goto line_rest
		    to_right_from_left_7:
			btfsc candidate, 7
			    bcf candidate, 6
			goto line_rest
    left_button_check:
	btfsc button_states, DOWN_LEFT  ; skip if not pressed
	    bra left_pressed

	left_released:
	    btfsc PORTB, DOWN_LEFT	; skip if pressed
		bra confirm_button_check_in_line

	    left_released_pressed:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfsc PORTB, DOWN_LEFT  ; skip if still pressed
		    bra confirm_button_check_in_line

		bsf button_states, DOWN_LEFT
		bra confirm_button_check_in_line

	left_pressed:
	    btfss PORTB, DOWN_LEFT	; skip if released
		bra confirm_button_check_in_line

	    left_pressed_released:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfss PORTB, DOWN_LEFT  ; skip if still released
		    bra confirm_button_check_in_line

		call rb1_released_fake
		bcf button_states, DOWN_LEFT

		btfsc direction, 0	; skip if direction is from right
		    bra to_left_from_left

		to_left_from_right:						
		    btfsc candidate, 7
			bra to_left_from_right_6
		    btfsc candidate, 6
			bra to_left_from_right_5
		    btfsc candidate, 5
			bra to_left_from_right_4
		    btfsc candidate, 4
			bra to_left_from_right_3
		    btfsc candidate, 3
			bra to_left_from_right_2
		    btfsc candidate, 2
			bra to_left_from_right_1
		    btfsc candidate, 1
			bra to_left_from_right_0
		    btfsc candidate, 0
			goto line_rest

		    to_left_from_right_6:
			btfsc candidate, 6
			    bcf candidate, 7
			goto line_rest
		    to_left_from_right_5:
			btfsc candidate, 5
			    bcf candidate, 6
			goto line_rest
		    to_left_from_right_4:
			btfsc candidate, 4
			    bcf candidate, 5
			goto line_rest
		    to_left_from_right_3:
			btfsc candidate, 3
			    bcf candidate, 4
			goto line_rest
		    to_left_from_right_2:
			btfsc candidate, 2
			    bcf candidate, 3
			goto line_rest
		    to_left_from_right_1:
			btfsc candidate, 1
			    bcf candidate, 2
			goto line_rest
		    to_left_from_right_0:
			btfsc candidate, 0
			    bcf candidate, 1
			goto line_rest


		to_left_from_left:
		    btfsc candidate, 0
			goto line_rest
		    btfsc candidate, 1
			bra to_left_from_left_0
		    btfsc candidate, 2
			bra to_left_from_left_1
		    btfsc candidate, 3
			bra to_left_from_left_2
		    btfsc candidate, 4
			bra to_left_from_left_3
		    btfsc candidate, 5
			bra to_left_from_left_4
		    btfsc candidate, 6
			bra to_left_from_left_5
		    btfsc candidate, 7
			bra to_left_from_left_6

		    to_left_from_left_0:
			bsf candidate, 0
			goto line_rest
		    to_left_from_left_1:
			bsf candidate, 11
			goto line_rest
		    to_left_from_left_2:
			bsf candidate, 2
			goto line_rest
		    to_left_from_left_3:
			bsf candidate, 3
			goto line_rest
		    to_left_from_left_4:
			bsf candidate, 4
			goto line_rest
		    to_left_from_left_5:
			bsf candidate, 5
			goto line_rest
		    to_left_from_left_6:
			bsf candidate, 6
			goto line_rest

    confirm_button_check_in_line:
	btfsc button_states, CONFIRM    ; skip if not pressed
	    bra confirm_pressed_in_line

	confirm_released_in_line:
	    btfsc PORTB, CONFIRM	; skip if pressed
		bra toggle_button_check_in_line

	    confirm_released_pressed_in_line:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfsc PORTB, CONFIRM    ; skip if still pressed
		    bra toggle_button_check_in_line

		bsf button_states, CONFIRM
		bra toggle_button_check_in_line

	confirm_pressed_in_line:
	    btfss PORTB, CONFIRM	; skip if released
		bra toggle_button_check_in_line

	    confirm_pressed_released_in_line:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfss PORTB, CONFIRM    ; skip if still released
		    bra toggle_button_check_in_line

		call rb3_released_fake
		bcf button_states, CONFIRM

		movf candidate, w

		btfsc selected_row, ROW1
		    iorwf row1_leds, f
		btfsc selected_row, ROW2
		    iorwf row2_leds, f
		btfsc selected_row, ROW3
		    iorwf row3_leds, f

		bcf state, LINE_STATE
		bsf state, ROW_STATE

		clrf direction
		clrf candidate
		bsf candidate, 0

		call update_led

		return

    toggle_button_check_in_line:
	btfsc button_states, TOGGLE	; skip if not pressed
	    bra toggle_pressed_in_line

	toggle_released_in_line:
	    btfsc PORTB, TOGGLE ; skip if pressed
		goto line_rest

	    toggle_released_pressed_in_line:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfsc PORTB, TOGGLE	; skip if still pressed
		    goto line_rest

		bsf button_states, TOGGLE
		    goto line_rest

	toggle_pressed_in_line:
	    btfss PORTB, TOGGLE ; skip if released
		goto line_rest

	    toggle_pressed_released_in_line:
		movlw 0x1
		movwf count_n
		call wait_for_n_times_10ms

		btfss PORTB, TOGGLE	; skip if still released
		    goto line_rest

		call rb0_released_fake
		bcf button_states, TOGGLE

		btfsc direction, 0
		    bra toggle_to_right

		toggle_to_left:
		    bsf direction, 0
		    goto line_rest
		toggle_to_right:
		    bcf direction, 0
		    goto line_rest

    line_rest:
	btfsc selected_row, ROW1
	    bra line_row1
	btfsc selected_row, ROW2
	    bra line_row2
	btfsc selected_row, ROW3
	    bra line_row3

	line_row1:
	    movf row1_leds, w
	    iorwf candidate, w
	    movwf LATA
	    return
	line_row2:
	    movf row2_leds, w
	    iorwf candidate, w
	    movwf LATC
	    return
	line_row3:
	    movf row3_leds, w
	    iorwf candidate, w
	    movwf LATD
	    return

;   ####### END (7) #########


rb0_released_fake:
    rb0_released:
	return
rb1_released_fake:
    rb1_released:
	return
rb2_released_fake:
    rb2_released:
	return
rb3_released_fake:
    rb3_released:
	return


	
;   ####### START (1) #########		   		    
main_fake:    
    
    btfsc state, ROW_STATE  
	bra row_setup       ;	IF in ROW_STATE
    btfsc state, LINE_STATE  
	bra line_setup	    ;	IF in LINE_STATE
	
    
    ;	    OK, now this part is a little complicated.
    ;	"button_counter_#"s are used to time 200ms. However,
    ;	in order for buttons to be responsible in this waiting
    ;	area, polling is timed. 
    ;	First of all, we have 2 more procedures
    ;		1 -> row_select_button	: to handle button actions in ROW state
    ;		2 -> drawing_buttons	: to handle button actions in LINE state
    ;	   
    ;	    These two procedure will simply poll buttons in their respective states,
    ;	and act accordingly. What happened here is, first they are implemented. Then,
    ;	using "nop" execution time is equalized. Therefore, they will both have 
    ;	approximately the same running time. (To overcome button bouncing, if a button
    ;	is sensed as pressed, there is extra 10ms but that is not that important in general)
    ;	
    ;	    Finally, "button_counter_#"s are set so that loops execute for an approximately
    ;	200ms. (Remember that if any button is pressed, this time will increase to make sure 
    ;	that it is indeed pressed and not an artifact.)
	
    row_setup:
	movlw 0x9D
	movwf button_counter_1
	
	call update_led	    ;	    Now we are in ROW state. This procedure will handle 
			    ;	flashing of LEDs using the flag register led_state.
	bra main
	    
    line_setup:
	movlw 0x9D
	movwf button_counter_1
	
    
    main:
    nop	;   Debug handler
    while_button_counter_1_on:
	movlw 0x16
	movwf button_counter_2
	while_button_counter_2_on:
	    movlw 0x10
	    movwf button_counter_3
	    while_button_counter_3_on:
		
		;	This is the innerloop. We poll here so that we don't miss any
		;   button action. If we instead wait for 200ms for example, we might
		;   miss a button action whose length is less than 200ms.		
		
		btfsc state, LINE_STATE	
		    bra line_loop   ; IF in LINE state
		    row_loop:
			call row_select_button
			bra come_here
		    line_loop:
			call drawing_buttons
		    come_here:
		    
		    ;	These two procedure will change the state. 
		    ;	    Since in ROW state
		    ;		LEDs flashes with a period of 200ms ON/OFF, if their state change
		    ;		here; it will wait until 200ms elapsed. Since updating LEDs is done
		    ;		inside row_setup procedure.
		    ;	    However in LINE state
		    ;		there is no flashing. They are always on or off. Therefore, drawin_buttons
		    ;		procedure also handles turning-on or off. This way, it will be more responsive.
			
		decf button_counter_3
		bnz while_button_counter_3_on
	    decf button_counter_2
	    bnz while_button_counter_2_on
	decf button_counter_1
	bnz while_button_counter_1_on
    
    msec200_passed:
	nop ; Debug handler
   goto main_fake
   ;   ####### END (3) #########		   		    

end


