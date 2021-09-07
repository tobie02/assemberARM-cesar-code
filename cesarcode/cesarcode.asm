.data
entrada: .asciz "                                                                                                    "
salida: .asciz ""
mensaje: .asciz "                                                                                                   "
clave_texto: .asciz "                 "
clave_numero: .int
r0: .word 0
f1: .word 0
f2: .word 0
f3: .word 0
f4: .word 0
opcion: .asciz " "
c1: .asciz "\nSe procesaron "
c2: .asciz "     caracteres\n"
encriptado: .asciz "\neste mensaje esta encriptado"
cartel_mensaje: .asciz "\nMensaje: "
desplazamiento_usado: .asciz "\ndesplazamiento usado: "
salto_de_linea: .asciz "\n"

.text

.global main

extraer_mensaje:
	.fnstart
	//GUARDO EL MENSAJE EN MENSAJE
	PUSH {lr}
	LDR r0, = mensaje
	loop_mensaje:
		LDRB r2, [r1], #1
		CMP r2, #0x3B
		BEQ fin_mensaje //SI ES UN ; TERMINO
		STRB r2, [r0], #1
		BAL loop_mensaje
	fin_mensaje:
		MOV r2, #0xa
		STRB r2, [r0], #1
		POP {lr}
		BX lr
	.fnend



extraer_clave:
	//RECORRO LA ENTRADA PARA ENCONTRAR ; Y CONSEGUIR CODIFICACION
	.fnstart
	PUSH {lr}
	LDR r0, = clave_texto
	MOV r12, #0 //BANDERA: 0 = POSITIVO, 1 = NEGATIVO
	loop_clave:
		LDRB r2, [r1], #1
		CMP r2, #0x2D //SI ES UN - PONGO BANDERA EN UNO
		BEQ negativo
		CMP r2, #0x3B
		BEQ fin_clave
		STRB r2, [r0], #1
		BAL loop_clave
	negativo:
		MOV r12, #1
		BAL loop_clave
	fin_clave:
		BL ascii_a_entero
		POP {lr}
		BX lr
	.fnend



extraer_opcion:
	//RECORRO EL RESTO DE r0 PARA ENCONTRAR ; Y VER EL SIGUIENTE DIGITO
	.fnstart
	PUSH {lr}
	LDR r0, = opcion
	loop_opcion:
		LDRB r2, [r1], #1
		CMP r2, #0xa
		BEQ fin_opcion
		CMP r2, #0x3B
		BEQ fin_opcion //SI ES UN ; ME VOY
		STRB r2, [r0], #1
		BAL loop_opcion
	fin_opcion:
		POP {lr}
		BX lr
	.fnend



ascii_a_entero:
	//CONVIERTE LOS CARACTERES EN INT
	.fnstart
	PUSH {r1,r2,r3,r4,lr}
	LDR r0, = clave_texto //CARGO EL TEXTO DE LA CLAVE
	MOV r1, #0
	MOV r10, #10
	loop_entero:
		LDRB r2, [r0]
		CMP r2, #0x20
		BEQ fin_entero
		MUL r4, r1, r10
		MOV r1, r4
		SUB r2, #0x30
		ADD r1, r2
		ADD r0, #1
		BAL loop_entero
	fin_entero:
		LDR r0, = clave_numero //DEVUELVO EL INT CORRESPONDIENTE
		STR r1, [r0]
		POP {r1,r2,r3,r4,lr}
		BX lr
	.fnend



entero_a_ascii:
	.fnstart
	PUSH {lr}
	MOV r2, #0
	CMP r11, #10
	BLT fin_ascii
	loop_ascii:
		SUB r11, #10
		ADD r2, #1
		CMP r11, #10
		BGE loop_ascii
	fin_ascii:
		ADD r2, #0x30
		ADD r11, #0x30
		POP {lr}
		BX lr
	.fnend



conseguir_bit_paridad:
	.fnstart
	PUSH {lr}
	loop_paridad:
		SUB r6, #2
		CMP r6, #1
		BGT loop_paridad
		BEQ sumar_bit_paridad
		BAL fin_paridad
		sumar_bit_paridad:
			CMP r9, #0
			BEQ esta_en_cero //SI ESTA EN CERO LO PONGO EN 1 Y ME VOY
			MOV r9, #0 //SINO, LO PONGO EN 0 Y ME VOY
			BAL fin_paridad
			esta_en_cero:
				MOV r9, #1
				BAL fin_paridad
		fin_paridad:
			POP {lr}
			BX lr
	.fnend



conseguir_desplazamiento:
	.fnstart
	PUSH {lr}
	MOV r2, #0 //DESPLAZAMIENTO EN r2
	loop_desplazamiento_1:
		LDR r0, = clave_texto
		LDR r1, = mensaje
		ADD r2, #1 //AUMENTO EL DESPLAZAMIENTO PARA SIGUIENTE RECORRIDO
 		loop_desplazamiento_2:
			LDRB r3, [r0], #1 //CARACTER DE PALABRA EN R3
			LDRB r4, [r1], #1 //CARACTER DE MENSAJE EN R4
			CMP r3, #0x20
			BEQ fin_desplazamiento //SI LLEGO AL FIN DE PALABRA TERMINO
			CMP r4, #0xa
			BEQ loop_desplazamiento_1 //SI LLEGO AL FIN DE MENSAJE AUMENTO EL DESPLAZAMIENTO
			SUB r4, r2
			CMP r4, #0x61
			ADDLT r4, #26 //SI ES MENOR QUE a VOLTEO ABECEDARIO
			CMP r3, r4
			BEQ loop_desplazamiento_2
			BAL reinicio_palabra
			reinicio_palabra: //SI NO COINIDE REINICIO LA PALABRA Y SIGO
				LDR r0, = clave_texto
				BAL loop_desplazamiento_2
	fin_desplazamiento:
		LDR r0, = clave_numero //GUARDO DEL DESPLAZAMIENTO Y ME VOY
		STRB r2, [r0]
		POP {lr}
		BX lr
	.fnend



codificar:
	//CODIFICO EL MENSAJE CON LA CORRESPONDIENTE CLAVE
	.fnstart
	PUSH {lr}
	LDR r0, = clave_numero
	LDRB r1, [r0] //CARGO EN r1 LA CLAVE
	LDR r2, = mensaje
	LDR r3, = salida
	MOV r11, #0 //CONTADOR DE CARACTERES PROCESADOR EN R11
	MOV r9, #0 //CONTADOR DE PARIDAD
	loop_codificar:
		LDRB r4, [r2], #1 //CARGO EN r4 EL DIGITO ACTUAL
		CMP r4, #0xa
		BEQ fin_codificar //SI ES UN CERO/SALTO DE LINEA, ME VOY
		ADD r11, #1 //SUMO AL CONTADOR DE CARACTERES
		MOV r6, r4 //UTILIZO r6 COMO CARACTER AUXILIAR
		BL conseguir_bit_paridad
		CMP r4, #0x20
		BNE cambiar //SI NO ES UN ESPACIO CAMBIO EL DIGITO
		STRB r4, [r3], #1

		BAL loop_codificar //SI ES UN ESPACIO LO CARGO Y VUELVO
	cambiar:
		CMP r12, #1
		BEQ es_negativo //SI ES UNO ES RESTA
		BAL es_positivo //SINO ES SUMA

	es_negativo:
		SUB r4, r1 //LE RESTO AL DIGITO LA CLAVE
		CMP r4, #0x61 //SI ES MENOR QUE a
		BLT menor_que_a
		STRB r4, [r3], #1
		BAL loop_codificar //CARGO EL DIGITO Y VUELVO
		menor_que_a:
			ADD r4, #26
			STRB r4, [r3], #1
			BAL loop_codificar

	es_positivo:
		ADD r4, r1 // LE SUMO AL DIGITO LA CLAVE
		CMP r4, #0x7A //SI ES MAYOR QUE z
		BGT mayor_que_z
		STRB r4, [r3], #1
		BAL loop_codificar //CARGO EL DIGITO Y VUELVO
		mayor_que_z:
			SUB r4, #26
			STRB r4, [r3], #1
			BAL loop_codificar
	fin_codificar:
		MOV r5, #0x20
		STRB r5, [r3], #1 //AGREGO UN ESPACIO
		ADD r9, #0x30 //AGREGO 30 A LA PARIDAD PARA CONVERTIR EN ASCII
		STRB r9, [r3], #1 //LO AGREGO AL FINAL DE LA CADENA
		POP {lr}
		BX lr
	.fnend




main:
	//PIDO ENTRADA Y LA GUARDO EN CADENA
	MOV r7, #3
	MOV r0, #0 //ENTRADA
	MOV r2, #100 //LARGO
	LDR r1, = entrada
	SWI 0

	// EXTRAIGO EL MENSAJE
	BL extraer_mensaje

	// EXTRAIGO LA CLAVE Y LA PASO A INT
	BL extraer_clave

	// EXTRAIGO LA OPCION
	BL extraer_opcion
	LDR r0, = opcion
	LDRB r8, [r0], #1
	CMP r8, #0x63
	BEQ opcion_codificar
	CMP r8, #0x64
	BEQ opcion_decodificar
	CMP r8, #0x20
	BEQ opcion_decodificar_desplazamiento
	BAL salir


	opcion_codificar:
	// CODIFICO EL MENSAJE CON LA CLAVE ASIGNADA
		BL codificar
		BL entero_a_ascii
		LDR r0, = c1
		STR r2, [r0, #15]
		STR r11, [r0, #16]

		MOV r7, #4
		MOV r0, #1
		MOV r2, #1
		LDR r1, = salto_de_linea
		SWI 0

		MOV r7, #4
		MOV r0, #1
		MOV r2, #93
		LDR r1, = salida  //IMPRIMO LA SALIDA
		SWI 0

		MOV r7, #4
		MOV r0, #1
		MOV r2, #16
		LDR r1, = c1  //IMPRIMO LA CADENA DE LOS CARACTERES PROCESADOS
		SWI 0

		MOV r7, #4
		MOV r0, #1
		MOV r2, #17
		LDR r1, = c2  //IMPRIMO LA SEGUNDA PARTE DE LA CADENA
		SWI 0

		BAL salir


	opcion_decodificar:
		CMP r12, #0
		BEQ cambiar_signo //INVIERTO EL SIGNO
		MOV r12, #0
		BAL seguir
		cambiar_signo:
			MOV r12, #1
		seguir:
			BL codificar
			BL entero_a_ascii

			LDR r0, = c1
			STR r2, [r0, #15]
			STR r11, [r0, #16]

			MOV r7, #4
			MOV r0, #1
			MOV r2, #30
			LDR r1, = encriptado
			SWI 0

			MOV r7, #4
			MOV r0, #1
			MOV r2, #10
			LDR r1, = cartel_mensaje
			SWI 0

			MOV r7, #4
			MOV r0, #1
			MOV r2, #93
			LDR r1, = salida
			SWI 0

			MOV r7, #4
			MOV r0, #1
			MOV r2, #16
			LDR r1, = c1
			SWI 0

			MOV r7, #4
			MOV r0, #1
			MOV r2, #17
			LDR r1, = c2
			SWI 0

			BAL salir

		opcion_decodificar_desplazamiento:

			BL conseguir_desplazamiento
			MOV r11, r2
			BL entero_a_ascii
			LDR r0, = desplazamiento_usado
			STR r2, [r0, #24]
			STR r11, [r0, #25]

			MOV r12, #1
			BL codificar
			BL entero_a_ascii

			LDR r0, = c1
			STR r2, [r0, #15]
			STR r11, [r0, #16]

			MOV r7, #4
			MOV r0, #1
			MOV r2, #30
			LDR r1, = encriptado
			SWI 0

			MOV r7, #4
			MOV r0, #1
			MOV r2, #40
			LDR r1, = desplazamiento_usado
			SWI 0

			MOV r7, #4
			MOV r0, #1
			MOV r2, #10
			LDR r1, = cartel_mensaje
			SWI 0

			MOV r7, #4
			MOV r0, #1
			MOV r2, #93
			LDR r1, = salida
			SWI 0

			MOV r7, #4
			MOV r0, #1
			MOV r2, #16
			LDR r1, = c1
			SWI 0

			MOV r7, #4
			MOV r0, #1
			MOV r2, #17
			LDR r1, = c2
			SWI 0

salir:

	MOV r7, #1
	SWI 0

