.include "functions.s" // Incluir el archivo de funciones

.equ SCREEN_WIDTH, 		640
.equ SCREEN_HEIGHT, 	480
.equ BITS_PER_PIXEL,  	32

.equ GPIO_BASE,      0x3f200000
.equ GPIO_GPFSEL0,   0x00
.equ GPIO_GPLEV0,    0x34

// Tabla de offsets para flameo (signed int)


.globl main

main:
	// x0 contiene la direccion base del framebuffer
 	mov x20, x0	// Guarda la dirección base del framebuffer en x20
	//---------------- CODE HERE ------------------------------------
    bl background

	bl luna

    bl texto

    bl bandera

InfLoop:
	b InfLoop

