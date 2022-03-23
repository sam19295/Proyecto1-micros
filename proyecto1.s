;Archvo: main.s
;Dispositivo: PIC16F887
;Autor: Melanie Samayoa
    
;Compilador: Pic.as(v2.31) MPLAB v5.50
;Programa: reloj y fecha
;Harware: displays,leds,botones,cables
    
;Creado: 8/03/2022
;Ultima modificacion: 16/03/2021
    
PROCESSOR 16F887
#include <xc.inc>

;-------------------------- bits de configuracion -------------------------------;
   
; Configuration word 1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscilador interno sin salidas
  CONFIG  WDTE = OFF            ; WDT disabled (reinicio repetitivo del PIC)
  CONFIG  PWRTE = OFF           ; PWRT enabled (espera de 72ms al iniciar)
  CONFIG  MCLRE = OFF           ; El pin de MCLR se utiliza como I/O
  CONFIG  CP = OFF              ; Sin protecci?n de c?digo 
  CONFIG  CPD = OFF             ; Sin protecci?n de datos
  
  CONFIG  BOREN = OFF           ; Sin reinicio cuando el voltaje de alimentaci?n baja de 4V
  CONFIG  IESO = OFF            ; Reinicio sin cambio de reloj de interno a externo
  CONFIG  FCMEN = OFF           ; Cambio de reloj externo a interno en caso de fallo
  CONFIG  LVP = OFF             ; Programaci?n en bajo voltaje permitida
  
; Configuration word 2
  CONFIG  BOR4V = BOR40V        ; Reinicio abajo de 4V 
  CONFIG  WRT = OFF             ; Protecci?n de autoescritura por el programa desactivada 
    
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr			; Memoria compartida
    tempw:		DS  1
    temp_status:	DS  1
    
PSECT udata_bank0		; Variables almacenadas en el banco 0
    segundos:			DS  1
    segundost:			DS  1
    minutos:			DS  1
    minutost:			DS  1
    minutosa:			DS  1
    horas:			DS  1
    horasa:			DS  1
    dias:			DS  1
    meses:			DS  1
    unidades_seg:		DS  1
    decenas_seg:		DS  1
    unidades_min:		DS  1
    decenas_min:		DS  1
    unidades_hrs:		DS  1
    decenas_hrs:		DS  1
    unidades_dia:		DS  1
    decenas_dia:		DS  1
    unidades_mes:		DS  1
    decenas_mes:		DS  1
    unidadesst:			DS  1
    decenasst:			DS  1
    unidadesmt:			DS  1
    decenasmt:			DS  1
    unidadesma:		    	DS  1
    decenasma:			DS  1
    unidadesha:			DS  1
    decenasha:			DS  1
    banderas:			DS  1
    valor_seg:			DS  1
    valor_segt:			DS  1
    valor_min:			DS  1
    valor_mint:			DS  1
    valor_hrs:			DS  1
    valor_dia:			DS  1
    valor_mes:			DS  1
    valor_hrsa:			DS  1
    valor_mina:			DS  1
    veces_uniseg:		DS  1
    veces_decseg:		DS  1
    veces_unimin:		DS  1
    veces_decmin:		DS  1
    veces_unihrs:		DS  1
    veces_dechrs:		DS  1
    veces_unidia:		DS  1
    veces_decdia:		DS  1
    veces_unimes:		DS  1
    veces_decmes:		DS  1
    veces_unist:		DS  1
    veces_decst:		DS  1
    veces_unimt:		DS  1
    veces_decmt:		DS  1
    veces_unima:		DS  1
    veces_decma:		DS  1
    veces_uniha:		DS  1
    veces_decha:		DS  1
    diez:			DS  1
    uno:			DS  1
    cont1:			DS  1
    cont2:			DS  1
    cont3:			DS  1
    medio:			DS  1
    estados:			DS  1
    bandera_config:		DS  1
    num_config:			DS  1
    config_state:		DS  1
    bandera_alarma:		DS  1
    alarma_bandera:		DS  1
    display:			DS  4

PSECT resVect, class = CODE, abs, delta = 2
 ;-------------- vector reset ---------------
 ORG 00h			; Posici?n 00h para el reset
 resVect:
    goto main

PSECT intVect, class = CODE, abs, delta = 2
ORG 004h				; posici?n 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
 
push:
    movwf   tempw		; Se guarda W en el registro temporal
    swapf   STATUS, W		
    movwf   temp_status		; Se guarda STATUS en el registro temporal
    
isr:
    banksel INTCON
    btfsc   T0IF		; Ver si bandera de TMR0 se encendi?
    call    tm0
    btfsc   TMR1IF		; Ver si bandera de TMR1 se encendi?
    call    tm1
    btfsc   TMR2IF		; Ver si bandera de TMR2 se encendi?
    call    tm2
    btfsc   RBIF
    call    intb
    
pop:
    swapf   temp_status, W	
    movwf   STATUS		; Se recupera el valor de STATUS
    swapf   tempw, F
    swapf   tempw, W		; Se recupera el valor de W
    retfie      
    
PSECT code,  delta = 2, abs
ORG 200h
 
main:
    call    configio	; Configuraci?n de I/O
    call    configclk		; Configuraci?n de reloj
    call    config_tmr0		; Configuraci?n de TMR0
    call    config_tmr1		; Configuraci?n de TMR1
    call    config_tmr2		; Configuraci?n de TMR2
    call    configint		; Configuraci?n de interrupciones
    
loop:
    btfsc   cont1,	1	; Verifica si contador 1 es 2
    call    completar
    
    movf    segundos,	0
    sublw   0x3C
    btfsc   STATUS,	2	; Verificar si segundos = 60
    call    completar_min
    
    btfsc   segundost,	7
    decf    minutost,	1
    movlw   0x3B
    btfsc   segundost,	7
    movwf   segundost		; Verificar si segundos de timer = 0
    
    btfsc   bandera_config,0
    goto    $+7
    movf    segundost,	1
    btfss   STATUS,	2
    goto    $+4
    movf    minutost,	1
    btfsc   STATUS,	2
    call    completar_tmr	; Verificar si el timer se complet? 
    
    btfss   PORTA,	6
    goto    $+7
    btfsc   bandera_alarma,   0
    call    apagar_alarma	; Apagar alarma de timer
    
    btfss   PORTA,	6
    goto    $+3
    btfss   alarma_bandera, 0
    call    alarma_off		; Apagar alarma 
    
    movf    minutos,	0
    sublw   0x3C
    btfsc   STATUS,	2	; Verificar si minutos = 60
    call    completar_hrs
    
    movf    minutosa,	0
    sublw   0x3C
    btfsc   STATUS,	2
    clrf    minutosa		; Verificar si minutos alarma = 60
    
    movf    horasa,	0
    sublw   0x17
    btfss   STATUS,	0
    clrf    horasa		; Verificar si horas alarma = 24
    
    movf    horas,	0
    sublw   0x18
    btfsc   STATUS,	2
    call    completar_dia	; Verificar si horas = 24
    
    movf    minutost,	0
    sublw   0x64
    btfsc   STATUS,	2
    call    timer_minmax	; Verificar si minutos timer = 99
    
    btfsc   minutost,  7
    clrf    minutost		; Verificar si minutos timer es "negativo"
    
    movf    segundost,	0
    sublw   0x3C
    btfsc   STATUS,	2
    call    timer_segmax	; Verificar si segundos timer = 60
    
    btfsc   segundost,	7
    clrf    segundost		; Verificar si segundos timer es "negativo"
    
    movlw   0x3B
    btfsc   minutos,	7
    movwf   minutos		; Verificar si minutos es "negativo"
    
    movlw   0x3B
    btfsc   minutosa,	7
    movwf   minutosa		; Verificar si minutos alarma es "negativo"
    
    movlw   0x17
    btfsc   horas,	7
    movwf   horas		; Verificar si horas es "negativo"
    
    movlw   0x17
    btfsc   horasa,	7
    movwf   horasa		; Verificar si horas alarma es "negativo"
    
    movf    meses,	0
    sublw   0x0D
    btfsc   STATUS,	2
    call    completar_year	; Verificar si meses = 12
    
    movlw   0x1F
    btfsc   dias,	7
    movwf   dias		; Verificar si dias es "negativo"
    
    movlw   0x0C
    btfsc   meses,	7
    movwf   meses		; Verificar si meses es "negativo"
    
    btfss   bandera_config, 0
    goto    $+8
    movf    minutost,	    1
    btfss   STATUS,	    2
    goto    $+5
    movf    segundost,	    1
    movlw   0x01
    btfsc   STATUS,	    2
    movwf   segundost		; Timer m?nimo 1 seg
    
    movf    minutost,	    0
    sublw   0x64
    btfsc   STATUS,	    0
    goto    $+3
    movlw   0x63
    movwf   minutost		; Minutos timer max
    
    btfsc   bandera_config, 0
    goto    $+11
    btfss   alarma_bandera,0
    goto    $+9
    movf    horasa,	0
    xorwf   horas,	0
    btfss   STATUS,	2
    goto    $+5
    movf    minutosa,	0
    xorwf   minutos,	0
    btfsc   STATUS,	2
    call    alarma_complete	; Verificar si alarma es igual a hora 
    
    btfsc   alarma_bandera, 0
    goto    $+3   
    bcf	    PORTA,	4
    goto    $+2
    bsf	    PORTA,	4	; Encender LED de alarma encendida
    
    btfsc   bandera_config, 0
    goto    $+3
    bcf	    PORTA,	5
    goto    $+2
    bsf	    PORTA,	5	; Encender LED de modo configuracion
    
    movf    meses,	0
    xorlw   0x01
    btfsc   STATUS,	2
    call    mes31		; Verificar mes (enero)
    
    movf    meses,	0
    xorlw   0x02
    btfsc   STATUS,	2
    call    mes28		; Verificar mes (febrero)
    
    movf    meses,	0
    xorlw   0x03
    btfsc   STATUS,	2
    call    mes31		; Verificar mes (marzo)
    
    movf    meses,	0
    xorlw   0x04
    btfsc   STATUS,	2
    call    mes30		; Verificar mes (abril)
    
    movf    meses,	0
    xorlw   0x05
    btfsc   STATUS,	2
    call    mes31		; Verificar mes (mayo)
    
    movf    meses,	0
    xorlw   0x06
    btfsc   STATUS,	2
    call    mes30		; Verificar mes (junio) 
    
    movf    meses,	0
    xorlw   0x07
    btfsc   STATUS,	2
    call    mes31		; Verificar mes (julio)
    
    movf    meses,	0
    xorlw   0x08
    btfsc   STATUS,	2
    call    mes31		; Verificar mes (agosto)
    movf    meses,	0
    xorlw   0x09
    btfsc   STATUS,	2
    call    mes30		; Verificar mes (septiembre)
    
    movf    meses,	0
    xorlw   0x0A
    btfsc   STATUS,	2
    call    mes31		; Verificar mes (octubre)
    
    movf    meses,	0
    xorlw   0x0B
    btfsc   STATUS,	2
    call    mes30		; Verificar mes (noviembre)
    
    movf    meses,	0
    xorlw   0x0C
    btfsc   STATUS,	2
    call    mes31		; Verificar mes (diciembre)
    
    movf    medio,	0
    movwf   PORTE
    
    btfsc   estados,	0	; Estados = 001 -> Fecha
    goto    fechaloop
    btfsc   estados,	1	; Estados = 010 -> Alarma
    goto    alarmaloop
    btfsc   estados,	2	; Estados = 100 -> Timer
    goto    timerloop
    goto    watchloop		; Estados = 000 -> Hora/reloj
    
watchloop:
    bsf	    PORTA,	0	; LED indicador de modo hora/reloj
    bcf	    PORTA,	1
    bcf	    PORTA,	2
    bcf	    PORTA,	3
    
    movf    segundos,	0
    movwf   valor_seg		; Almacenar el valor de segundos en valor
    movf    minutos,	0
    movwf   valor_min		; Almacenar el valor de minutos en valor
    movf    horas,	0
    movwf   valor_hrs		; Almacenar el valor de horas en valor
    
    ; Convertir a decimal 
    clrf    veces_uniseg
    clrf    veces_decseg
    clrf    veces_unimin
    clrf    veces_decmin
    clrf    veces_unihrs
    clrf    veces_dechrs
    
    movf    diez,   0
    subwf   valor_min,  1
    incf    veces_decmin,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_decmin	; Obtener decenas de minutos

    movf    uno,    0
    subwf   valor_min,  1
    incf    veces_unimin,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_unimin	; Obtener unidades de minutos
    
    movf    diez,   0
    subwf   valor_hrs,  1
    incf    veces_dechrs,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_dechrs	; Obtener decenas de horas

    movf    uno,    0
    subwf   valor_hrs,  1
    incf    veces_unihrs,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_unihrs	; Obtener unidades de horas
   
    call    set_displayS0	; Setear display para mostrar horas y minutos
    goto    loop		; Volver a loop principal 
    
fechaloop:
    bsf	    PORTE,	2	; LEDs que cuentan segundos siempre encendidos para ser diagonal
    bcf	    PORTA,	0
    bsf	    PORTA,	1	; LED indicador de modo fecha
    bcf	    PORTA,	2
    bcf	    PORTA,	3
    
    movf    dias,	0	; Almacenar el valor de dias en valor
    movwf   valor_dia
    movf    meses,	0	; Almacenar el valor de meses en valor
    movwf   valor_mes
    
    ; Convertir a decimal 
    clrf    veces_unidia
    clrf    veces_decdia
    clrf    veces_unimes
    clrf    veces_decmes
    
    movf    diez,   0
    subwf   valor_dia,  1
    incf    veces_decdia,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_decdia ; Obtener decenas de dias

    movf    uno,    0
    subwf   valor_dia,  1
    incf    veces_unidia,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_unidia	; Obtener unidades de dias
    
    movf    diez,   0
    subwf   valor_mes,  1
    incf    veces_decmes,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_decmes	; Obtener decenas de mes

    movf    uno,    0
    subwf   valor_mes,  1
    incf    veces_unimes,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_unimes	; Obtener unidades de mes
    
    call    set_displayS1	; Configurar display para mostrar mes y dia
    goto    loop		; Volver a loop principal
    
alarmaloop:
    bcf	    PORTA,	0
    bcf	    PORTA,	1
    bsf	    PORTA,	2	; LED indicador de modo alarma
    bcf	    PORTA,	3
    
    clrf    veces_unima
    clrf    veces_decma
    clrf    veces_uniha
    clrf    veces_decha
    
    movf    minutosa,	0	; Almacenar valor de minutos en valor
    movwf   valor_mina
    movf    horasa,	0	; Almacenar el valor de horas en valor
    movwf   valor_hrsa
    
    movf    diez,   0
    subwf   valor_mina,  1
    incf    veces_decma,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_decma	; Obtener decenas de minutos

    movf    uno,    0
    subwf   valor_mina,  1
    incf    veces_unima,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_unima	; OBtener unidades de minutos
    
    movf    diez,   0
    subwf   valor_hrsa,  1
    incf    veces_decha,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_decha	; Obtener deceas de horas

    movf    uno,    0
    subwf   valor_hrsa,  1
    incf    veces_uniha,	1
    btfsc   STATUS, 0
    goto    $-3    
    call    check_uniha	; Obtener unidades de horas
	
    call    set_displayS3	; Configurar display para mostrar horas y minutos de alarma
    goto    loop		; Volver a loop principal 
 
timerloop:
    bcf	    PORTA,	0
    bcf	    PORTA,	1
    bcf	    PORTA,	2
    bsf	    PORTA,	3	; LED indicador de modo timer
    
    clrf    veces_unist
    clrf    veces_decst
    clrf    veces_unimt
    clrf    veces_decmt
    
    movf    segundost,	0	; Almacenar el valor de segundos en valor
    movwf   valor_segt
    movf    minutost,	0	; Almacenar el valor de minutos en valor
    movwf   valor_mint
    
    movf    diez,   0
    subwf   valor_segt,  1
    incf    veces_decst,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_decst	; Obtener decenas de segundos

    movf    uno,    0
    subwf   valor_segt,  1
    incf    veces_unist,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_unist	; Obtener unidades de segundos
    
    movf    diez,   0
    subwf   valor_mint,  1
    incf    veces_decmt,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_decmt	 ; Obtener decenas de minutos 

    movf    uno,    0
    subwf   valor_mint,  1
    incf    veces_unimt,	1
    btfsc   STATUS, 0
    goto    $-3
    call    check_unimt	; Obtener unidades de minutos 
    
    call    set_displayS4	; Configurar display para mostrar minutos y segundos de timer
    goto    loop		; Volver a loop principal 
    
;--------------- Subrutinas ------------------
configio:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH	    ; I/O digitales
    banksel TRISA
    movlw   0xFF
    movwf   TRISB	    ; Puerto B como entrada
    clrf    TRISA	    ; Puerto A como salida
    clrf    TRISC	    ; Puerto C como salida
    clrf    TRISD	    ; Puerto D como salida
    clrf    TRISE	    ; Puerto E como salida
    banksel PORTA
    clrf    PORTA
    clrf    PORTC
    clrf    PORTD
    clrf    PORTB
    clrf    PORTE
    movlw   0x00
    movwf   segundos	
    movlw   0x10
    movwf   minutos
    movlw   0x05
    movwf   horas
    movlw   0x00    
    movwf   unidades_seg
    movlw   0x00
    movwf   decenas_seg
    movlw   0x00
    movwf   unidades_min
    movlw   0x00
    movwf   decenas_min
    movlw   0x00
    movwf   unidades_hrs
    movlw   0x00
    movwf   decenas_hrs
    movlw   0x00
    movwf   veces_uniseg
    movlw   0x00
    movwf   veces_decseg
    movlw   0x00
    movwf   veces_unimin
    movlw   0x00
    movwf   veces_decmin
    movlw   0x00
    movwf   veces_unihrs
    movlw   0x00
    movwf   veces_dechrs
    movlw   0x0A
    movwf   diez
    movlw   0x01
    movwf   uno
    movlw   0x00
    movwf   banderas
    movlw   0x00
    movwf   cont1
    movlw   0x00
    movwf   cont2
    movlw   0x00
    movwf   cont3
    movlw   0xFF
    movwf   medio
    movlw   0x00
    movwf   estados
    movlw   0x0F
    movwf   dias
    movlw   0x06
    movwf   meses
    movlw   0xFE
    movwf   bandera_config
    movlw   0x00
    movwf   num_config
    movlw   0x00
    movwf   config_state
    movlw   0x00
    movwf   segundost
    movlw   0x01
    movwf   minutost
    movlw   0x11
    movwf   minutosa
    movlw   0x05
    movwf   horasa
    movlw   0x00
    movwf   bandera_alarma
    movlw   0x00
    movwf   alarma_bandera
    return
    
configclk:
    banksel OSCCON	    ; cambiamos a banco de OSCCON
    bsf	    OSCCON,	 0  ; SCS -> 1, Usamos reloj interno
    bsf	    OSCCON,	 6
    bsf	    OSCCON,	 5
    bcf	    OSCCON,	 4  ; IRCF<2:0> -> 110 4MHz
    return
    
config_tmr0:
    banksel OPTION_REG	    ; Cambiamos a banco de OPTION_REG
    bcf	    OPTION_REG, 5   ; T0CS = 0 --> TIMER0 como temporizador 
    bcf	    OPTION_REG, 3   ; Prescaler a TIMER0
    bcf	    OPTION_REG, 2   ; PS2
    bcf	    OPTION_REG, 1   ; PS1
    bcf	    OPTION_REG, 0   ; PS0 Prescaler de 1 : 2
    banksel TMR0	    ; Cambiamos a banco 0 de TIMER0
    movlw   6		    ; Cargamos el valor 6 a W
    movwf   TMR0	    ; Cargamos el valor de W a TIMER0 para 2mS de delay
    bcf	    T0IF	    ; Borramos la bandera de interrupcion
    return  
    
config_tmr1:
    banksel T1CON	    ; Cambiamos a banco de tmr1
    bcf	    TMR1CS	    ; Reloj interno 
    bcf	    T1OSCEN	    ; Apagamos LP
    bsf	    T1CKPS1	    ; Prescaler 1:8
    bsf	    T1CKPS0
    bcf	    TMR1GE	    ; tmr1 siempre contando 
    bsf	    TMR1ON	    ; Encender tmr1
    call    reset_tmr1
    return
    
config_tmr2:
    banksel PR2
    movlw   243		    ; Para delay de 62.5 mS
    movwf   PR2
    banksel T2CON
    bsf	    T2CKPS1	    ; Prescaler de 1:16
    bsf	    T2CKPS0
    bsf	    TOUTPS3	    ; Postscaler de 1:16
    bsf	    TOUTPS2
    bsf	    TOUTPS1
    bsf	    TOUTPS0
    bsf	    TMR2ON	    ; tmr2 encendido 
    return
    
configint:
    banksel IOCB
    bsf	    IOCB,   0	    ; Interrupcion en RB0
    bsf	    IOCB,   1	    ; Interrupcion en RB1
    bsf	    IOCB,   2	    ; Interrupcion en RB2
    bsf	    IOCB,   3	    ; Interrupcion en RB3
    bsf	    IOCB,   4	    ; Interrupcion en RB4
    banksel PIE1
    bsf	    TMR1IE	    ; Habilitamos interrupcion TMR1
    bsf	    TMR2IE	    ; Habilitamos interrupcion TMR2
    banksel INTCON
    bsf	    PEIE
    bsf	    GIE		    ; Habilitamos interrupciones
    bsf	    T0IE	    ; Habilitamos interrupcion TMR0
    bcf	    T0IF	    ; Limpiamos bandera de TMR0
    bcf	    TMR1IF	    ; Limpiamos bandera de TMR1
    bcf	    TMR2IF	    ; Limpiamos bandera de TMR2
    bsf	    RBIE	    ; Habilitamos interrupcion PORTB
    bcf	    RBIF	    ; Limpiamos bandera de PORTB
    return
    
reset_tmr0:
    banksel TMR0	    ; cambiamos de banco
    movlw   6
    movwf   TMR0	    ; delay 4.44mS
    bcf	    T0IF
    return

reset_tmr1:
    banksel TMR1H
    movlw   0x0B	    ; Configuraci?n tmr1 H
    movwf   TMR1H
    movlw   0xDC	    ; Configuraci?n tmr1 L
    movwf   TMR1L	    ; tmr1 a 500 mS
    bcf	    TMR1IF	    ; Limpiar bandera de tmr1
    
tm0:
    call    reset_tmr0
    call    valores
    return
    
tm1:
    call    reset_tmr1
    incf    cont1
    comf    medio
    return
    
tm2:
    bcf	    TMR2IF	    ; Limpiar la bandera de tmr2
    return
    
intb:			    ; Interrupciones de puerto B
    btfss   PORTB,	0
    call    cambiarestado  ; Ver si fue B1
    btfss   PORTB,	1
    call    configuracion   ; Ver si fue B2
    btfss   PORTB,	2
    call    inc		    ; Ver si fue B3
    btfss   PORTB,	3
    call    decr	    ; Ver si fue B4
    btfss   PORTB,	4
    call    cambiar	    ; Ver si fue B5
    bcf	    RBIF	    ; Limpiar bandera de puerto B
    return
    
cambiarestado:
    btfsc   estados,	0   ; Verificar en qu? estado se encuentra la FSM
    goto    S2_cambio	    ; para verificar cu?l deber?a de ser el siguiente
    btfsc   estados,	1
    goto    S3_cambio
    btfsc   estados,	2
    goto    S0_cambio
    goto    S1_cambio
    
    S0_cambio:
	bcf	    estados,	0
	bcf	    estados,	1
	bcf	    estados,	2
	return
    
    S1_cambio:
	bsf	    estados,	0
	bcf	    estados,	1
	bcf	    estados,	2
	return

    S2_cambio:
	bcf	    estados,	0
	bsf	    estados,	1
	bcf	    estados,	2
	return

    S3_cambio:
	bcf	    estados,	0
	bcf	    estados,	1
	bsf	    estados,	2
	return
    
configuracion:
    comf    bandera_config	    ; Habilitar o deshabilitar bandera de configuraciones 
    return
    
set_displayS0:			    ; Mostrar en el display horas y minutos de reloj
    movf    unidades_min,	w 
    call    tabla
    movwf   display+1
    
    movf    decenas_min,	w
    call    tabla
    movwf   display+2
    
    movf    unidades_hrs,	w
    call    tabla
    movwf   display+3
    
    movf    decenas_hrs,	w
    call    tabla
    movwf   display
    return    
    
set_displayS1:			    ; Mostrar en el display dia y mes de fecha 
    movf    unidades_mes,	w 
    call    tabla
    movwf   display+1
    
    movf    decenas_mes,	w
    call    tabla
    movwf   display+2
    
    movf    unidades_dia,   w
    call    tabla
    movwf   display+3
    
    movf    decenas_dia,    w
    call    tabla
    movwf   display
    return      
    
set_displayS3:			    ; Mostrar en el display hora y minutos de alarma 
    movf    unidadesma,	w 
    call    tabla
    movwf   display+1
    
    movf    decenasma,	w
    call    tabla
    movwf   display+2
    
    movf    unidadesha,   w
    call    tabla
    movwf   display+3
    
    movf    decenasha,    w
    call    tabla
    movwf   display
    return    
    
set_displayS4:			    ; Mostrar en display minutos y segundos de timer
    movf    unidadesst,	w 
    call    tabla
    movwf   display+1
    
    movf    decenasst,	w
    call    tabla
    movwf   display+2
    
    movf    unidadesmt,   w
    call    tabla
    movwf   display+3
    
    movf    decenasmt,    w
    call    tabla
    movwf   display
    return      
    
valores:		    ; Multiplexado para displays de 7 segmentos 
    clrf    PORTD
    btfsc   banderas,	0
    goto    display1
    btfsc   banderas,	1
    goto    display2
    btfsc   banderas,	2
    goto    display3
    goto    display0
    
    display0:			    
	movf    display+3,    W
	movwf   PORTC
	bsf	PORTD,	    0
	bsf	banderas,   0
	bcf	banderas,   1
	bcf	banderas,   2
return

    display1:			    
	movf    display+2,  W
	movwf   PORTC
	bsf	PORTD,	    1
	bcf	banderas,   0
	bsf	banderas,   1
	bcf	banderas,   2
return
	
    display2:			    
	movf	display+1,   W
	movwf	PORTC
	bsf	PORTD,	    2
	bcf	banderas,   0
	bcf	banderas,   1
	bsf	banderas,   2
return
	
    display3:
	movf	display,    w
	movwf	PORTC
	bsf	PORTD,	    3
	bcf	banderas,   0
	bcf	banderas,   1
	bcf	banderas,   2
return	
	
check_decseg:
    decf    veces_decseg,	1
    movf    diez,   0
    addwf   valor_seg,  1
    movf    veces_decseg,	0
    movwf   decenas_seg
    return
    
check_uniseg:
    decf    veces_uniseg,	1
    movf    uno,    0
    addwf   valor_seg,  1
    movf    veces_uniseg,	0
    movwf   unidades_seg
    return
    
check_decmin:
    decf    veces_decmin,	1
    movf    diez,   0
    addwf   valor_min,  1
    movf    veces_decmin,	0
    movwf   decenas_min
    return
    
check_unimin:
    decf    veces_unimin,	1
    movf    uno,    0
    addwf   valor_min,  1
    movf    veces_unimin,	0
    movwf   unidades_min
    return
    
check_dechrs:
    decf    veces_dechrs,	1
    movf    diez,   0
    addwf   valor_hrs,  1
    movf    veces_dechrs,	0
    movwf   decenas_hrs
    return
    
check_unihrs:
    decf    veces_unihrs,	1
    movf    uno,    0
    addwf   valor_hrs,  1
    movf    veces_unihrs,	0
    movwf   unidades_hrs
    return
    
check_decdia:
    decf    veces_decdia,	1
    movf    diez,   0
    addwf   valor_dia,  1
    movf    veces_decdia,	0
    movwf   decenas_dia
    return
    
check_unidia:
    decf    veces_unidia,	1
    movf    uno,    0
    addwf   valor_dia,  1
    movf    veces_unidia,	0
    movwf   unidades_dia
    return    
    
check_decmes:
    decf    veces_decmes,	1
    movf    diez,   0
    addwf   valor_mes,  1
    movf    veces_decmes,	0
    movwf   decenas_mes
    return
    
check_unimes:
    decf    veces_unimes,	1
    movf    uno,    0
    addwf   valor_mes,  1
    movf    veces_unimes,	0
    movwf   unidades_mes
    return  
    
check_decst:
    decf    veces_decst,	1
    movf    diez,   0
    addwf   valor_segt,  1
    movf    veces_decst,	0
    movwf   decenasst
    return
    
check_unist:
    decf    veces_unist,	1
    movf    uno,    0
    addwf   valor_segt,  1
    movf    veces_unist,	0
    movwf   unidadesst
    return 
    
check_decmt:
    decf    veces_decmt,	1
    movf    diez,   0
    addwf   valor_mint,  1
    movf    veces_decmt,	0
    movwf   decenasmt
    return
    
check_unimt:
    decf    veces_unimt,	1
    movf    uno,    0
    addwf   valor_mint,  1
    movf    veces_unimt,	0
    movwf   unidadesmt
    return 
    
check_decma:
    decf    veces_decma,	1
    movf    diez,   0
    addwf   valor_mina,  1
    movf    veces_decma,	0
    movwf   decenasma
    return
    
check_unima:
    decf    veces_unima,	1
    movf    uno,    0
    addwf   valor_mina,  1
    movf    veces_unima,	0
    movwf   unidadesma
    return 
    
check_decha:
    decf    veces_decha,	1
    movf    diez,   0
    addwf   valor_hrsa,  1
    movf    veces_decha,	0
    movwf   decenasha
    return
    
check_uniha:
    decf    veces_uniha,	1
    movf    uno,    0
    addwf   valor_hrsa,  1
    movf    veces_uniha,	0
    movwf   unidadesha
    return
    
completar:			; Contador de TMR1
    clrf    cont1
    incf    segundos,	1
    btfss   bandera_alarma,   0
    return
    decf    segundost,	1
    return
    
completar_min:		; Se complet? un minuto
    clrf    segundos
    incf    minutos,	1
    btfsc   PORTA, 6
    call    alarma_off		; Ver si la alarma estuvo encendida un minuto y apagarla
    return	
    
completar_hrs:			; Se completo una hora
    clrf    minutos
    incf    horas,	1
    return
    
completar_dia:			; Se completo un dia 
    clrf    horas
    incf    dias,	1
    return
    
completar_year:			; Se completo un año
    movlw   0x01
    movwf   meses
    return
    
min_amax:			
    movlw   0x03B
    movwf   minutosa
    return
    
hrs_amax: 
    movlw   0x17
    movwf   horasa
    return
    
completar_tmr:			; Se completo el timer
    movlw   0x01		; Volver a cargar un minuto al timer
    movwf   minutost
    movlw   0x00
    movwf   segundost
    bsf	    PORTA,	6	; Encender alarma
    bcf	    bandera_alarma,   0
    return
    
alarma_complete:		; Se completo la alarma
    bsf	    PORTA,	6	; Emcemder alarma
    return
    
apagar_alarma:
    bcf	    PORTA,	6	; Apagar la alarma de timer con B5
    movlw   0x01		; Volver a cargar un minuto al timer
    movwf   minutost
    movlw   0x00
    movwf   segundost
    bcf	    bandera_alarma,	0
    return
    
alarma_off:			; Apagar alarma con B5
    bcf	    PORTA,	6
    bcf	    alarma_bandera, 0
    return
    
timer_minmax:
    movlw   0x63
    movwf   minutost
    return
    
timer_segmax:
    movlw   0x00
    movwf   segundost
    return
    
mes31:				; Subrutina para limitar meses de 31 d?as
    movf    dias,   0
    sublw   0x1F
    btfsc   STATUS, 0
    goto    $+4
    movlw   0x01
    movwf   dias
    incf    meses,  1
    return
    
mes28:				; Subrutina para limitar febrero de 28 d?as
    movf    dias,   0
    sublw   0x1C
    btfsc   STATUS, 0
    goto    $+4
    movlw   0x01
    movwf   dias
    incf    meses,  1
    return
    
mes30:				; Subrutina para limitar meses de 30 d?as
    movf    dias,   0
    sublw   0x1E
    btfsc   STATUS, 0
    goto    $+4
    movlw   0x01
    movwf   dias
    incf    meses,  1
    return
    
cambiar:				; Cambiar de modo configuraci?n
    btfsc   bandera_config,	0
    goto    estado2
    goto    estado1
    
    estado1:
	btfsc   estados,	0
	goto	alarma_a    
	btfsc   estados,	1
	goto	alarma_a
	btfsc   estados,	2
	goto	timer_alarma
	goto    alarma_a
	
	timer_alarma:
	    comf    bandera_alarma, 1
	    return
	    
	alarma_a:
	    comf    alarma_bandera, 1
	    return
    
    estado2:
    comf    config_state,   1
    return
    
inc:				    ; Subrutina para inrementar en modo configuraci?n
    btfss   bandera_config,	0
    return
    
    btfsc   config_state,	0
    goto    config_2inc
    goto    config_1inc
    
    config_1inc:
	btfsc   estados,	0
	goto	inc_dias    
	btfsc   estados,	1
	goto	inc_ma
	btfsc   estados,	2
	goto	inc_st
	goto    inc_min
	
	inc_min:
	    incf    minutos
	    return
	    
	inc_dias:
	    incf    dias
	    return
	    
	inc_ma:
	    incf    minutosa
	    return
	    
	inc_st:
	    incf    segundost
	    return
	    
    config_2inc:
	btfsc   estados,	0
	goto	inc_mes    
	btfsc   estados,	1
	goto	inc_ha
	btfsc   estados,	2
	goto	inc_mt
	goto    inc_hrs
	
	inc_hrs:
	    incf    horas
	    return
	    
	inc_mes:
	    incf    meses
	    return
	    
	inc_ha:
	    incf    horasa
	    return
	    
	inc_mt:
	    incf    minutost
	    return
    
decr:					; Subrutina para decrementar en modo configuraci?n 
    btfss   bandera_config, 0
    return
    
    btfsc   config_state,	0
    goto    config_2dec
    goto    config_1dec
    
    config_1dec:
	btfsc   estados,	0
	goto	dec_dia    
	btfsc   estados,	1
	goto	dec_ma
	btfsc   estados,	2
	goto	dec_st
	goto    dec_min
	
	dec_min:
	    decf    minutos
	    return
	    
	dec_dia:
	    decf    dias
	    return
	    
	dec_ma:
	    decf    minutosa
	    return
	    
	dec_st:
	    decf    segundost
	    return
	    
    config_2dec:
	btfsc   estados,	0
	goto	dec_mes    
	btfsc   estados,	1
	goto	dec_ha
	btfsc   estados,	2
	goto	dec_mt
	goto    dec_hr
	
	dec_hr:
	    decf    horas
	    return 
	    
	dec_mes:
	    decf    meses
	    return
	    
	dec_ha:
	    decf    horasa
	    return
	    
	dec_mt:
	    decf    minutost
	    return
	
org 100h

;-------------------------- tabla -------------------------------;

tabla: 
    clrf    PCLATH
    bsf	    PCLATH,0 ; PCLATH = 01
    andlw   0x0f
    addwf   PCL 
    retlw   00111111B ;0
    retlw   00000110B ;1
    retlw   01011011B ;2
    retlw   01001111B ;3
    retlw   01100110B ;4
    retlw   01101101B ;5
    retlw   01111101B ;6
    retlw   00000111B ;7
    retlw   01111111B ;8
    retlw   01101111B ;9
    retlw   01110111B ;A
    retlw   01111100B ;B
    retlw   00111001B ;C
    retlw   01011110B ;D
    retlw   01111001B ;E
    retlw   01110001B ;F
    
END

 

