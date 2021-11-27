	;;==========================================================================;;
	;;									                                        ;;
	;;                   UNIVERSIDAD DEL ESTADO DE MORELOS           	        ;;
	;;              FACULTAD DE CIENCIAS QUIMICAS e INGENIERIA       	        ;;
	;;                   2006 - MICROPROCESADORES - PIC16F84                    ;;
	;;				   		                                                    ;;
	;;==========================================================================;;

;;
;--------------------------------------------------------------------------------------
; LCDMOD.ASM
; 
; El conjunto de rutinas que se presentan a continuaci¢n permiten realizar
; las tareas básicas de control del módulo de visualización LCD. Se emplean
; con los PIC 16cxx. En el programa principal se deber  reservar memoria
; para el bloque de variables que utiliza el LCD de la siguiente manera:
;
; 	lcd_var EQU dir_inicio_del_bloque
;
;
;		 -------------------------------------------------------------------- 
;		¦  ----------------------------------------------------------------  ¦
;		¦ ¦		  L C D      2  L I N E A S			   ¦ ¦
;		¦ ¦		  1 6   C A R A C T E R E S			   ¦ ¦
;		¦  ----------------------------------------------------------------  ¦
;		¦	Vss  Vdd  V0  RS  R/W  E   D0  D1  D2  D3  D4  D5  D6  D7    ¦
;		 --------¦----¦----¦---¦---¦---¦----¦---¦---¦---¦---¦---¦---¦---¦----
;			 ¦    ¦    ¦   ¦   ¦   ¦    ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦
;			 ¦    ¦    ¦   ¦   ¦   ¦    ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦
;			GND  +5V  CNT  A0  A1  A2   B0  B1  B2  B3  B4  B5  B6  B7	
;
;		V0:    Regula el contraste al recibir una tensión entre 0 y +5 Volts 
;		       mediante un potenciometro
;		R/W:   Si R/W=0 se escribe en el modulo y si R/W=1 el modulo LCD es leido
;		RS:    Si RS=0 se selecciona el registro de control
;		       Si RS=1 se selecciona el registro de datos
;		E:     Señal de activación. Si E=0 el modulo LCD esta desactivado
;		       y no funcionan las restantes señales. Se activa con E=1
;	
;		D0-D7: Son las entradas de un byte de datos al LCD, esta infromación de
;		       puede ser de control (comandos) o datos de caracteres ASCII
;			
;
;
;
;
; Nota 1: THIS file was updated by ARBR from it's original source
;         from the book Microcontroladores PIC Angulo U. 99
;								
; Nota 2: Todas las constantes estan definidas en el archivo: p16f84.inc
;--------------------------------------------------------------------------------------
;;


;BLOQUE DE ETIQUETAS 

 
	#define ENABLE 		bsf PORTA,2 ;Activa E
	#define DISABLE 	bcf PORTA,2 ;Desactiva
	#define LEER 		bsf PORTA,1 ;Pone LCD en Modo RD
	#define ESCRIBIR 	bcf PORTA,1 ;Pone LCD en Modo WR
	#define MODO_COMANDO 	bcf PORTA,0 ;Desactiva RS (modo comando)
	#define MODO_DATOS 	bsf PORTA,0 ;Activa RS (modo datos)


	CBLOCK 	
		LCD_VAR
		LCD_TEMP_2	;Inicio de las variables. Será la primera dirección libre disponible 
		LCD_TEMP_1	
	ENDC		
 
 
; RUTINA UP_LCD
; Con esta rutina se configura el PIC para que trabaje con el LCD.

 
UP_LCD		SELECT_BANK1	 	;Banco 1
	 	clrf 	PORTB 		;RB <0-7> salidas digitales
		clrf 	PORTA 		;RA <0-4> salidas digitales
	 	bcf 	STATUS,RP0 	;Banco 0
		MODO_COMANDO 		;RS=0
		DISABLE 		;E=0, desabilita el LCD		
		return			; retorna
 
 
; RUTINA LCD_BUSY
; Con esta rutina se chequea el estado del 
; flag BUSY del modulo LCD, que indica, cuando está activado, que el
; módulo aún no ha terminado el comando anterior. La rutina espera a
; que se complete cualquier comando anterior antes de retornar al
; programa principal, para poder enviar un nuevo comando.
 
 
LCD_BUSY	
		LEER 			;Pone el LCD en Modo RD (Read)
		;;---------------------------------------------------
		SELECT_BANK1	 	;Banco 1
		movlw 	H'FF'		;0x'FF'=b'11111111'
		movwf 	PORTB 		;Puerta B como entrada
		bcf 	STATUS,RP0 	;Selecciona el banco 0
		;;---------------------------------------------------
		ENABLE 			;Activa el LCD
		nop
L_BUSY 		btfsc 	PORTB,7		;Chequea bit de Busy
		goto 	L_BUSY
		DISABLE 	 	;Desactiva LCD
		SELECT_BANK1 		;Banco1
		clrf 	PORTB 		;Puerta B salida
		SELECT_BANK0	 	;Banco0
		ESCRIBIR		;Pone LCD en modo WR
		return
 
 
; RUTINA LCD_E
; Se trata de una pequeña rutina que se encarga de generar
; un impulso de 1 us (para una frecuencia de funcionamiento de 4 Mhz)
; por la patita de salida de la Puerta A RA2, que se halla conectada
; a la señal E (Enable) del módulo LCD. Con esta rutina se pretende activar
; al módulo LCD.
 
LCD_E 		
		ENABLE			;Activa E
		nop
		DISABLE			;Desactiva E
		return
 
 
; RUTINA LCD_DATO
; Es una rutina que pasa el contenido cargado en el
; registro w, el cual contiene un carácter ASCII, a la PUERTA B, para 
; visualizarlo por el LCD o escribirlo en la CGRAM.

LCD_DATO 	MODO_COMANDO 		;Desactiva RS (modo comando)
		movwf	PORTB 		;Valor ASCII a sacar por PORTB
		call 	LCD_BUSY 	;Espera a que se libere el LCD
		MODO_DATOS 		;Activa RS (modo dato)
		call 	LCD_E 		;Genera pulso de E
 		return
 
 
;RUTINA LCD_COMANDO
; Rutina parecida a la anterior, pero el contenido de W
; ahora es el código de un comando para el LCD, que es necesario pasar
; tambien a la PUERTA B para su ejecución.

LCD_COMANDO 	
		MODO_COMANDO 		;Desactiva RS (modo comando)
		movwf 	PORTB 		;Código de comando
		call 	LCD_BUSY 	;LCD libre?.
		call 	LCD_E 		;SÍ. Genera pulso de E.
 		return
 
 
; RUTINA LCD_INI
; Esta rutina se encarga de realizar la secuencia de 
; inicializaci¢n del módulo LCD de acuerdo con los tiempos dados por 
; el fabricante (15 ms). Se especifican los valores de DL, N y F,
; así como la configuración de un interfaz de 8 líneas con el bus
; de datos del PIC, y 2 líneas de 16 caracteres de 5 x 7 pixels. 
 
LCD_INI		
		movlw	b'00111000'	
		call	LCD_COMANDO 	;Envia el código de instrucción por la puertaB, la instrucción
					;es FUNCTION SET, con la siguiente configuración: 0 0 1 DL N F 0 0
					; - DL=1 bus de datos de 8 bits 
					; - N =1 Se usan las 2 lineas del LCD (Si N=1 se usa una)
					; - F =1 El caracter ASCII es de 5x10 Pixeles
	
		call	LCD_DELAY	;Temporiza
		movlw	b'00111000'
		call	LCD_COMANDO	;Código de instrucción
		call	LCD_DELAY	;Temporiza
		movlw 	b'00111000'
		call	LCD_COMANDO	;Código de instrucción
		call 	LCD_DELAY	;Temporiza
		return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;comandos para el LCD

LCD_HOME	
		movlw 	b'00000010'	;Pone el cursor en la posición 0
		call LCD_COMANDO
		return

LCD_CONECTAR
		movlw   b'00001100'
		call    LCD_COMANDO    	;Conecta el LCD     		
		return

LCD_CURSOR_OFF
		movlw   b'00001100'	;Configura cursor LCD corsor Off
		call LCD_COMANDO
		return


; Borra el display y retorna el cursor a la posición 0. 

CLEAR_LCD 
		movlw 	b'00000001' 	;Borra LCD y Home.
		call 	LCD_COMANDO
		return
 
 
;RUTINA DISPLAY_ON_CUR_OFF
; Control del display y cursor.
; Activa el display y desactiva es cursor
 
LCD_ON_CUR_OFF	movlw 	b'00001100' 	;LCD on, cursor off.
		call 	LCD_COMANDO
		return

LCD_GOTO_L1
		movlw	  b'10000000'	;0x80 <-- Esta derección corresponde a la linea 1 del LCD
		call	  LCD_COMANDO	;
		return

LCD_GOTO_L2
 		movlw	  b'11000000'	;0xc0 <-- Esta derección corresponde a la linea 2 del LCD
		call	  LCD_COMANDO	;
		return
 


; RUTINA LCD_DELAY
; Se trata de un rutina que implementa un retardo 
; o temporización de 5 ms. Utiliza dos variables llamadas LCD_TEMP_1 
; y LCD_TEMP_2, que se van decrementando hasta alcanzar dicho tiempo.
 
LCD_DELAY
		clrwdt
		movlw 	10		
		movwf 	LCD_TEMP_1	;LCD_TEMP_1=10
		clrf 	LCD_TEMP_2	;LCD_TEMP_2=0
LCD_DELAY_1 	decfsz	LCD_TEMP_2,F	;
		goto	LCD_DELAY_1	;Esta linea nunca se ejecuta, puesto que LCD_TEMP_2 siempre vale cero
					;sin embargo decfsz provoca dos periodos de instrucción = 2 uS
		decfsz	LCD_TEMP_1,F	;Se decrementa LCD_TEMP_1 en uno
		goto	LCD_DELAY_1	;cuando LCD_TEMP_1=0 se salta esta linea y ejecuta la instrucción siguiente
		return			;la cual regresa el flujo del programa a la linea que llama

	
