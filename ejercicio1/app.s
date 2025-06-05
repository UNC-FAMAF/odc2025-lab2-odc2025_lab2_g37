.include "functions.s" // Incluir el archivo de funciones

.equ SCREEN_WIDTH, 		640
.equ SCREEN_HEIGHT, 	480
.equ BITS_PER_PIXEL,  	32

.equ GPIO_BASE,      0x3f200000
.equ GPIO_GPFSEL0,   0x00
.equ GPIO_GPLEV0,    0x34

// Tabla de offsets para flameo (signed int)
.align 2
FlagWaveOffsets:
	.word 0, 5, 8, 10, 7, 3, 0, 4

.globl main

main:
	// x0 contiene la direccion base del framebuffer
 	mov x20, x0	// Guarda la dirección base del framebuffer en x20
	//---------------- CODE HERE ------------------------------------
    bl background

	bl luna

    bl texto

	// d) Dibujar bandera Argentina en un mástil (más alta)
	// Color del mástil (gris: ARGB=FFAAAAAA -> 0xFFAAAAAA)
	movz w10, 0xAA, lsl 16
	movk w10, 0xAAAA, lsl 0
	mov x1, 12              // Ancho del mástil
	mov x2, 300             // Alto del mástil (más alto)
	mov x3, 160             // Posición X del mástil (más a la izquierda)
	mov x4, SCREEN_HEIGHT-360 // Posición Y del mástil (ajustado para mástil más alto)
	bl draw_rectangle

	// Secciona cada franja de la bandera en cuadrados de 40x40 píxeles
	// Cada columna tiene una variación en Y para simular flameo

	// Franja celeste superior (ARGB=FF87CEEB)
	movz w10, 0x87, lsl 16
	movk w10, 0xCEEB, lsl 0
	mov x1, 40              // Ancho del cuadrado
	mov x2, 40              // Alto del cuadrado
	mov x3, 172             // X inicial (inicio de la bandera)
	FlagCelesteSupLoop:
		cmp x3, 172+320         // ¿Llegó al final de la franja?
		b.ge FlagCelesteSupDone
		// Calcular variación Y: offset = 8 * sin((x3-172)/40 * 25°)
		// Aproximamos con una tabla de offsets para 8 columnas
		// offsets: 0, 4, 7, 8, 7, 4, 0, -4
		sub x12, x3, 172        // x12 = columna*40
		mov x17, 40
		udiv x13, x12, x17      // x13 = columna (0..7)
		adr x14, FlagWaveOffsets
		ldrsw x15, [x14, x13, lsl 2] // offset en x15 (signed)
		mov x16, SCREEN_HEIGHT
		sub x16, x16, 360       // Y base
		add x4, x16, x15        // Y inicial con offset
		bl draw_rectangle
		add x3, x3, 40
		b FlagCelesteSupLoop
	FlagCelesteSupDone:

	// Franja blanca central (ARGB=FFFFFFFF)
	movz w10, 0xFF, lsl 16
	movk w10, 0xFFFF, lsl 0
	mov x1, 40
	mov x2, 40
	mov x3, 172
	FlagBlancaLoop:
		cmp x3, 172+320
		b.ge FlagBlancaDone
		sub x12, x3, 172
		mov x17, 40
		udiv x13, x12, x17
		adr x14, FlagWaveOffsets
		ldrsw x15, [x14, x13, lsl 2]
		mov x16, SCREEN_HEIGHT
		sub x16, x16, 320
		add x4, x16, x15
		bl draw_rectangle
		add x3, x3, 40
		b FlagBlancaLoop
	FlagBlancaDone:

    // Franja celeste inferior (ARGB=FF87CEEB)
    movz w10, 0x87, lsl 16
    movk w10, 0xCEEB, lsl 0
    mov x1, 40
    mov x2, 40
    mov x3, 172          // <-- REINICIAR x3 ANTES DEL BUCLE
	FlagCelesteInfLoop:
		cmp x3, 172+320
		b.ge FlagCelesteInfDone
		sub x12, x3, 172
		mov x17, 40
		udiv x13, x12, x17
		adr x14, FlagWaveOffsets
		ldrsw x15, [x14, x13, lsl 2]
		mov x16, SCREEN_HEIGHT
		sub x16, x16, 280
		add x4, x16, x15
		bl draw_rectangle
		add x3, x3, 40
		b FlagCelesteInfLoop
	FlagCelesteInfDone:

	// Sol central pequeño (amarillo oscuro: ARGB=FFCCCC00)
	movz w10, 0xCC, lsl 16
	movk w10, 0xCC00, lsl 0
	mov x3, 18              // Radio más pequeño (no más grande que la franja)
	mov x4, 332             // Centro X (centro de la bandera: 172 + 320/2)
	mov x5, SCREEN_HEIGHT-290 // Centro Y (en la franja blanca)
	bl draw_circle

InfLoop:
	b InfLoop

