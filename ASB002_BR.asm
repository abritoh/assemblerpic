	;;==========================================================================;;
	;;							                                                ;;
	;;                   UNIVERSIDAD DEL ESTADO DE MORELOS           	        ;;
	;;              FACULTAD DE CIENCIAS QUIMICAS e INGENIERIA       	        ;;
	;;                   2006 - MICROPROCESADORES | PIC16F84                    ;;
	;;				                ArBR                                        ;;
	;;==========================================================================;;
;
;
;_______________________________________________________________________________________________________
;
; Programa: ASB02.asm							Fecha: 2006-02-15
;_______________________________________________________________________________________________________
;
;
; El programa simula el funcionamiento de un ascensor de cuatro pisos.
; En el LCD se ve la posición del ascensor y el estado de sus puertas
;	así como la indicación de su movimiento.
; Un led Verde conctado a PA3 indica que la puerta del ascensor esta abierta
; 	conectado a la misma linea un LED Rojo indica que la puerta esta cerrada.
; Mediante un menu de Resets, conectados a Puerta B se introduce el piso deseado.
;	Con resets conectados a PB0,PB1,PB2 y PB3 se llama al ascensor para que 
;	acuda a los pisos PB,1,2 y 3 respectivamente (considere PB como Planta Baja).
;	Con resets conectados a PB5,PB6,PB7 y PB8 se indica al ascensor que 
;	nos lleve a los pisos PB,1,2 y 3 respectivamente.
;
;-------------------------------------------------------------------------------------------------------
;
;			Revisión.................................
; 			Microcontrolador............... PIC16F84A
; 			Power Up timer [PWRT] ............ON  OFF
; 			Protección del código [CP]....... ON  OFF		
; 			Tipo de Reloj......................... XT
; 			Frecuencia del oscilador........... 4 MHz
; 			Tinstrucción = 4/f.................. 1 uS				  
;
;									ArBR
;_______________________________________________________________________________________________________

;______________________________________________________________________________________________________;

	LIST    p=16f84A              		;Se define el tipo de microcontrolador

	;;;-------------------------------------------------------------------------;;;
	;;;	origen del programa						                                ;;;
	;;;-------------------------------------------------------------------------;;;

Origen:	
	;;;	Entradas analogicas
	banksel	TRISA
	movlw	b'111111'
	movwf	TRISA
	banksel	PORTA
	
	movlw	Mensaje0		; Carga la posición del mensaje
	call	SendTextToPC	; Visualiza el mensaje
	movlw	Mensaje2		; 
	call	SendTextToPC	; 

	movlw	Mensaje3		; 
	call	SendTextToPC	; 

	call	ConfigurarInputBotons
	;;;	Espera a que se presione el boton para continuar
	;;;-----------------------------------------------------
soltoBoton_01
	btfsc	InputBoton1
	goto	soltoBoton_01	
soltoBoton_02
	btfss	InputBoton1	
	goto	soltoBoton_02	

	;;;-------------------------------------------------------------------------;;;
	;;;		rutina principal del programa			                            ;;;
	;;;-------------------------------------------------------------------------;;;
	
	clrf	VarMax					;Inicializa el valor analogico Maximo
	movlw	MensajeInicioClock	    ; 
	call	SendTextToPC			; 
	call	Retardo4MHz_500mS

	call	LCD_Inicializa
	call	Retardo4MHz_500mS
	call	Iniciar_Reloj	

Main:		
	call	Retardo4MHz_200mS
	goto	Select_Case01				    ;Observa el estado de los botones para cambier la hora
	goto 	Main					        ;Ciclo principal infinito



	#include "C:\MPLAB\LIB\p16f84.inc"  	;Incluye archivo con definición de registros

	;;; DEFINICION DE MACROS
	#define SELECT_BANK0	bcf	STATUS,RP0
	#define	SELECT_BANK1	bsf	STATUS,RP0
	
;______________________________________________________________________________________________________;


;Se reserva espacio en la memoria para las variables utilizadas en el programa

	VTMP		equ	0x11
	ASC_PUERTA	equ	0x12
	ACCION		equ 0x13
	PISOD		equ 0x14
	PISO   		equ 0x15
	VAR		equ 	0x16
	VAR1		equ 0x17
	BITB		equ 0x18		;Variable que controla el estado de PB
	BITA		equ	0x19		;Variable que controla el estado de PA

	;lcd_var	equ 	0x0c	;Reserva un espacio de memoria para las variables del LCD

  	org             0  			;Para que al resetear se vaya a INICIO                        
 	goto   		INICIO
	org             5  			;Indica donde comienza el programa
				 
	#include "C:\MPLAB\LIB\LCD_A.ASM" 	;Incluye las rutinas del LCD			     

;______________________________________________________________________________________________________;
;Comienzo del programa.
;
INICIO
	        
		SELECT_BANK1		        ;Selecciona pagina 1 de datos (banco1)
                movlw   b'00001111'	
	            movwf   OPTION_REG	;
 	            bcf     INTCON,GIE  ;Desconecta interrupciones
                SELECT_BANK0		;Selecciona pagina 0 de datos		
		
		;######## configuración e inicialización del LCD
		call    UP_LCD  	       ;Configura RB y RA para control del LCD
		call    LCD_INI            ;Rutina de inicialización del LCD
		call	LCD_CONECTAR	   ;Conecta el LCD
		call	CLEAR_LCD	       ;Borra el LCD y lo sitúa en la posición		
					               ;de inicio ( HOME )
		
		;######## Mensaje de inicio
		call	MSG_INICIO
		
		movlw   d'2'		       ;inicio de la variable piso
                movwf   PISO       ;

		movlw   d'1'		       ;inicio de la variable accion, 1=Llamada
                movwf   ACCION     ; 

		movlw   d'1'		       ;inicio de la variable ASC_PUERTA=1=open
                movwf   ASC_PUERTA ;                
		
		call	CLEAR_LCD	;limpia el LCD
		call	msg_ASCENSOR	   ;
		call	msg_PISO
		call	LLAMADA_DE_P1	   ;PISOD=1
		goto 	MAIN
;______________________________________________________________________________________________________;
;Rutinas útiles

;;;;;;;;;;;;;;;; ### Referentes a la puerta B
PB_AS_OUTPUT
		;;;###	Establece PB como salida
		SELECT_BANK1
		movlw	b'00000000'
		movwf	TRISB
		SELECT_BANK0
		return

PB_AS_INPUT
		;;;###	Establece PB como entrada
		SELECT_BANK1
		movlw	b'11111111'
		movwf	TRISB
		SELECT_BANK0
		return

UNOS_EN_PB
		;;;###	Pone en unos a PB
		SELECT_BANK0
		movlw	b'11111111'
		movwf	PORTB
		return

CEROS_EN_PB
		;;;###	Pone en ceros a PB
		SELECT_BANK0
		movlw	b'00000000'
		movwf	PORTB
		return

;______________________________________________________________________________________________________;
;Bucle principal del programa.
;

MAIN		
		call	PB_AS_OUTPUT		;PB como salida
		call	UNOS_EN_PB		    ;PB en unos
		call	PB_AS_INPUT		    ;PB como entrada

		nop				            ;pausa de 1uS

		;;;###	Lee la puerta B y almacena su contenido en BITB, para comparar sus bits
		
		movf	PORTB,W			    ;se lee la puerta, w=PORTB
		movwf	BITB			    ;guarda w en BITB: BITB=w

		;;;###	Verifica si el estado de la puerta B ha cambiado, es decir si se presiono un reset
		;;;;;;	Si es así llama a SELECT

		movlw	b'11111111'		;w = unos
            	subwf   BITB,W	;Si f-w=0 -->Z=1, indica que PB no ha cambiado.
		btfss	STATUS,Z		;Si PortB no ha cambiado de su valor predeterminado
		goto	SELECT_PB		;salta esta linea (si Z=1)
		
		nop				;pausa de 1uS
		goto	MAIN			;Bucle infinito

END_MAIN

;______________________________________________________________________________________________________;

SELECT_PB

		;;;###	Revisar la puerta del ascensor, si esta abierta --> cerrarla
           	movlw	d'1'			        ;1=open
            	subwf   ASC_PUERTA,W		;
		btfsc	STATUS,Z		            ;
	        call    CLOSE_DOOR              ;si Z=0 salta esta linea, si no (si Z=1) --> la ejecuta

		;;;###	Seleccion de opciones

		;;	llamada del ascensor desde un piso
           	movlw	b'11111110'		    ;
            	subwf   BITB,W			;
		btfsc	STATUS,Z		        ;
	        goto    LLAMADA_DE_P1		;

            	movlw	b'11111101'		;
            	subwf   BITB,W			;
		btfsc	STATUS,Z		        ;
	        goto    LLAMADA_DE_P2	    ;
		
            	movlw	b'11111011'		;
            	subwf   BITB,W			;
		btfsc	STATUS,Z		        ;
	        goto     LLAMADA_DE_P3	    ;

            	movlw	b'11110111'		;
            	subwf   BITB,W			;
		btfsc	STATUS,Z		        ;
	        goto    LLAMADA_DE_P4	    ;

		
		;;	Ir al piso especicado
            	movlw	b'11101111'		;
            	subwf   BITB,W			;
		btfsc	STATUS,Z		        ;
	        goto    IR_A_P1		        ;

            	movlw	b'11011111'		;
            	subwf   BITB,W			;
		btfsc	STATUS,Z		        ;
	        goto    IR_A_P2		        ;
		
            	movlw	b'10111111'		;
            	subwf   BITB,W			;
		btfsc	STATUS,Z		        ;
	        goto    IR_A_P3		        ;

            	movlw	b'01111111'		;
            	subwf   BITB,W			;
		btfsc	STATUS,Z		        ;
	        goto    IR_A_P4		        ;

		goto 	MAIN			;;; si no se cumple ninguna condición regresa a MAIN

END_SELECT_PB

;______________________________________________________________________________________________________;


OPEN_DOOR	
	bsf	PORTA,3				    ;Activa el indicador de Puerta abierta,	PA3=1

	movlw	d'1'				;open=1
	movwf	ASC_PUERTA			;
	call	msg_OPEN_DOOR
	return	


CLOSE_DOOR	
	bcf	PORTA,3				    ;Desactiva el indicador de Puerta abierta, PA3=0

	movlw	d'2'				;close=2
	movwf	ASC_PUERTA			;	
	call	msg_CLOSE_DOOR
	return


;______________________________________________________________________________________________________;

;;;; # # # # # Llamadas al ascensor

LLAMADA_DE_P1
	movlw	d'1'
	movwf	PISOD			;piso destino
	movlw	d'1'
	movwf	ACCION			;acción=1=llamada
	goto 	BUCLE			


LLAMADA_DE_P2
	movlw	d'2'
	movwf	PISOD			;piso destino
	movlw	d'1'
	movwf	ACCION			;acción=1=llamada
	goto 	BUCLE			


LLAMADA_DE_P3
	movlw	d'3'
	movwf	PISOD			;piso destino
	movlw	d'1'
	movwf	ACCION			;acción=1=llamada
	goto 	BUCLE			


LLAMADA_DE_P4	
	movlw	d'4'
	movwf	PISOD			;piso destino
	movlw	d'1'
	movwf	ACCION			;acción=1=llamada
	goto 	BUCLE			

IR_A_P1
	movlw	d'1'
	movwf	PISOD			;piso destino
	movlw	d'0'
	movwf	ACCION			;acción=0=iR_A
	goto 	BUCLE			

IR_A_P2
	movlw	d'2'
	movwf	PISOD			;piso destino
	movlw	d'0'
	movwf	ACCION			;acción=0=iR_A
	goto 	BUCLE			

IR_A_P3
	movlw	d'3'
	movwf	PISOD			;piso destino
	movlw	d'0'
	movwf	ACCION			;acción=0=iR_A
	goto 	BUCLE			

IR_A_P4
	movlw	d'4'
	movwf	PISOD			;piso destino
	movlw	d'0'
	movwf	ACCION			;acción=0=iR_A
	goto 	BUCLE			
	
;______________________________________________________________________________________________________;

BUCLE
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	movf	PISO,W			;
	subwf	PISOD,W			;;;;  f-w ;;; PISOD-PISO

					        ;;;;  El resultado es comparado
	btfsc 	STATUS,Z	    	;Son iguales (Z=1)?
	goto 	F_IGUAL_W 	        ;Si
        btfsc 	STATUS,C    	;No. F mayor que W (C=0)?
        goto  	F_MAYOR_W 	    ;Si
	goto	F_MENOR_W	
	;;;;;;;;;;;;;;;;;;;;;;;;;

F_IGUAL_W
		goto	END_BUCLE  	;PISOD=PISO


F_MAYOR_W				;PISOD>PISO
		call	msg_UP
BF_MAYOR_W		
		incf	PISO,F		;PISO=PISO+1
		call	VER_N_PISO	;muestra el piso actual
		call	PAUSA1S

		movf	PISO,W		;W=PISO		
		subwf	PISOD,W		;PISOD-W
		btfsc	STATUS,Z
		goto	END_BUCLE	;Es Z=1
		goto	BF_MAYOR_W
	

F_MENOR_W				;PISOD<PISO
		call	msg_DWN		
BF_MENOR_W				;
		decf	PISO,F		;PISO=PISO-1
		call	VER_N_PISO	;muestra el piso actual
		call	PAUSA1S

		movf	PISO,W		;W=PISO		
		subwf	PISOD,W		;PISOD-W
		btfsc	STATUS,Z
		goto	END_BUCLE	;Es Z=1
		goto	BF_MENOR_W
	

END_BUCLE		
		call	msg_STOP	;mensaje de Parada
		call	delay
		call	delay

		call	OPEN_DOOR	;abre la puerta al llegar al destino
		call	PAUSA1S		;espera con la puerta abierta
		call	PAUSA1S
		call	CLOSE_DOOR	;cierra la puerta 

		goto	MAIN		;vuelve al ciclo principal

;______________________________________________________________________________________________________;


;Delay de 1seg
PAUSA1S
	call	delay
	call 	delay
	call	delay
	call	delay
	return
	


;Rutina de temporización de unos 0.25 segundos.     
delay   
	    movlw   .250
        movwf   VAR1
delay1  
	    movlw   .250
        movwf   VAR			;La temporización se realiza mediante
delay2  
	nop				        ;las restas sucesivas de dos variables
        decfsz  VAR,F
        goto    delay2
        decfsz  VAR1,F
        goto    delay1
        return


;______________________________________________________________________________________________________;

;; ## Mensaje del piso actual
VER_N_PISO
		;;;###	Seleccion de opciones

		;;	
           	movlw	d'1'			    ;
            	subwf   PISO,W			;
		btfsc	STATUS,Z		        ;
	        goto	VP1

           	movlw	d'2'			    ;
            	subwf   PISO,W			;
		btfsc	STATUS,Z		        ;
	        goto	VP2

           	movlw	d'3'			    ;
            	subwf   PISO,W			;
		btfsc	STATUS,Z		        ;
	        goto	VP3

           	movlw	d'4'			    ;
            	subwf   PISO,W			;
		btfsc	STATUS,Z		        ;
	        goto	VP4

VP1		;;;Planta baja
		movlw	b'11000101'
		call	LCD_COMANDO
		movlw	'P'
		call	LCD_DATO
		call	delay
		movlw	'B'
		call	LCD_DATO
		call	delay
		goto	RetVP

VP2		;;Piso 1
		movlw	b'11000101'
		call	LCD_COMANDO
		movlw	'1'
		call	LCD_DATO
		call	delay
		movlw	' '
		call	LCD_DATO
		call	delay
		goto	RetVP


VP3		;;Piso 2
		movlw	b'11000101'
		call	LCD_COMANDO
		movlw	'2'
		call	LCD_DATO
		call	delay
		movlw	' '
		call	LCD_DATO
		call	delay
		goto	RetVP

VP4		;;; Piso3
		movlw	b'11000101'
		call	LCD_COMANDO
		movlw	'3'
		call	LCD_DATO
		call	delay
		movlw	' '
		call	LCD_DATO
		call	delay
		
RetVP
	
		return


;; ## Mensaje PISO
msg_PISO
		movlw	b'11000000'
		call	LCD_COMANDO
		call 	delay

   		movlw   'P' 
	      	call    LCD_DATO	    ;visualiza el codigo ASCCI en el LCD
            	call    delay	 	;Retardo en la visualización del carácter
            	movlw   'I'   
		call	LCD_DATO	
		call    delay
		movlw   'S'   
		call	LCD_DATO			
		call    delay
		movlw   '0'   
		call	LCD_DATO	
		call    delay
		movlw   ' '   
		call	LCD_DATO	
 		call    delay
		
	return


;;;

msg_OPEN_DOOR
		movlw	b'10001100'	;linea1
		call	LCD_COMANDO
				
            	call    delay	 	;Retardo en la visualización del carácter
            	movlw   'P'   
		call	LCD_DATO	
		call    delay
		movlw   '='   
		call	LCD_DATO			
		call    delay
		movlw   'A'   
		call	LCD_DATO	
		call    delay
		movlw   'b'   

		return


msg_CLOSE_DOOR
		movlw	b'10001100'	;linea1
		call	LCD_COMANDO
				
            	call    delay	 	;Retardo en la visualización del carácter
            	movlw   'P'   
		call	LCD_DATO	
		call    delay
		movlw   '='   
		call	LCD_DATO			
		call    delay
		movlw   'C'   
		call	LCD_DATO	
		call    delay
		movlw   'e'   

		return


msg_UP
		movlw	b'11001100'
		call	LCD_COMANDO

		movlw   'U'   
		call	LCD_DATO			
		call    delay
		movlw   'P'   
		call	LCD_DATO			
		call    delay
		movlw   '*'   
		call	LCD_DATO
		call	delay
		movlw   '*'   
		call	LCD_DATO


		return


msg_DWN
		movlw	b'11001100'
		call	LCD_COMANDO

		movlw   'D'   
		call	LCD_DATO			
		call    delay
		movlw   'W'   
		call	LCD_DATO			
		call    delay
		movlw   'N'   
		call	LCD_DATO			
		call    delay
		movlw   '*'   
		call	LCD_DATO			
		call    delay

		return

msg_STOP
		movlw	b'11001100'
		call	LCD_COMANDO

		movlw   'S'   
		call	LCD_DATO			
		call    delay
		movlw   't'   
		call	LCD_DATO			
		call    delay
		movlw   'o'   
		call	LCD_DATO			
		call    delay
		movlw   'p'   
		call	LCD_DATO			
		call    delay

		return


msg_ASCENSOR
		movlw	b'10000000'	;linea1
		call	LCD_COMANDO
				
            	call    delay	 	;Retardo en la visualización del carácter
            	movlw   'A'   
		call	LCD_DATO	
		call    delay
		movlw   's'   
		call	LCD_DATO			
		call    delay
		movlw   'c'   
		call	LCD_DATO	
		call    delay
		movlw   'e'   
		call	LCD_DATO	
 		call    delay
     	      	movlw   'n'   
		call	LCD_DATO	
		call    delay
		movlw   's'   
		call	LCD_DATO			
		call    delay
		movlw   'o'   
		call	LCD_DATO	
            	call    delay
		movlw   'r'  
		call	LCD_DATO	 
		call	delay
		return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;##	Mensaje al inicio
MSG_INICIO
		call	CLEAR_LCD 

   		movlw   'P' 
	      	call    LCD_DATO	    ;visualiza el codigo ASCCI en el LCD
            	call    delay	 	;Retardo en la visualización del carácter
            	movlw   'I'   
		call	LCD_DATO	
		call    delay
		movlw   'C'   
		call	LCD_DATO			
		call    delay
		movlw   ' '   
		call	LCD_DATO	
		call    delay
		movlw   '1'   
		call	LCD_DATO	
 		call    delay
     	      	movlw   '6'   
		call	LCD_DATO	
		call    delay
		movlw   'F'   
		call	LCD_DATO			
		call    delay
		movlw   '8'   
		call	LCD_DATO	
            	call    delay
		movlw   '7'   
		call	LCD_DATO	
		call    delay
		movlw   '7'   
		call	LCD_DATO			
		call    delay

		movlw	0xc6
		call	LCD_COMANDO

		movlw   'C'   
		call	LCD_DATO	
		call    delay
		movlw   'O'   
		call	LCD_DATO	
		call    delay
 	      	movlw   'N'   
		call	LCD_DATO	
		call    delay
		movlw   'T'   
		call	LCD_DATO			
		call    delay
		movlw   'R'   
		call	LCD_DATO	
		call    delay
		movlw   'O'   
		call	LCD_DATO	
		call    delay
		movlw   'L'   
		call	LCD_DATO	
		call    delay
		movlw   ' '   
		call	LCD_DATO	
		call    delay
		movlw   '1'   
		call	LCD_DATO	
		call    delay

		call	PAUSA1S
		call	PAUSA1S
		call	PAUSA1S

		;;;******************;;;;;;

		call	CLEAR_LCD 

   		movlw   'A' 
	        call    LCD_DATO	    ;visualiza el codigo ASCCI en el LCD
                call    delay	 	;Retardo en la visualización del carácter
                movlw   'r'   
		call	LCD_DATO	
		call    delay
		movlw   'c'   
		call	LCD_DATO			
		call    delay
		movlw   '.'   
		call	LCD_DATO	
		call    delay
		movlw   '.'   
		call	LCD_DATO	
 		call    delay
		movlw   '.'   
		call	LCD_DATO	
		call    delay
		movlw   '.'   
		call	LCD_DATO			
		call    delay
		movlw   ' '   
		call	LCD_DATO	
            	call    delay
		movlw   'B'   
		call	LCD_DATO	
		call    delay
		movlw   '.'   
		call	LCD_DATO			
		call    delay		

		call	PAUSA1S
		call	PAUSA1S
		call	PAUSA1S
		call	PAUSA1S

		;;;******************;;;;;;

		return			     ;

;______________________________________________________________________________________________________;
;;;###	Utilerias

;;; Muestra una barra de progreso en la linea 2 del LCD
PROGRESSBAR
		movlw	0xC0			;w=0xc0
		movwf	VTMP			;VTMP=w
BPROGRESSBAR
		movf	VTMP,W			;w=VTMP	
		call	LCD_COMANDO		;Ejecuta el comando cargado en w
		call	delay
		movlw	'*'			
		call	LCD_DATO		;Muestra un ASCII en el LCD
		call	delay			;Realiza una Pausa
		
		incf	VTMP,F			;VTMP=VTMP+1
						;
		movlw	0xcf			;w=0xcf
		subwf	VTMP,W			;Efectua la operación: VTMP-0xcf
		btfsc	STATUS,Z		;Z=?
		return				    ;si Z=1 Sale del bucle
		goto	BPROGRESSBAR	;Si Z=0 Regresa al bucle	

;______________________________________________________________________________________________________;

		end 				;Fin del código	

