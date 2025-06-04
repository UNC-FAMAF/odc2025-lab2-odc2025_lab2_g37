	.equ SCREEN_WIDTH, 		640
	.equ SCREEN_HEIGHT, 		480
	.equ BITS_PER_PIXEL,  	32

	.equ GPIO_BASE,      0x3f200000
	.equ GPIO_GPFSEL0,   0x00
	.equ GPIO_GPLEV0,    0x34

	.globl main

main:
	// x0 contiene la direccion base del framebuffer
 	mov x20, x0	// Guarda la dirección base del framebuffer en x20
	//---------------- CODE HERE ------------------------------------

	// fondo
	movz x10, 0x21, lsl 16 		// color de fondo #212121
	movk x10, 0x2121, lsl 00 	// color de fondo

	// mastil
	movz x11, 0x7D, lsl 16 		//7D4016
	movk x11, 0x4016, lsl 00

	// bandera y algunas estrellas
	movz x12, 0xFF, lsl 16 		// #FFFFF 
	movk x12, 0xFFF, lsl 00

	// azul bandera 
	movz x13, 0x6C, lsl 16 	// #6CACE4
	movk x13, 0xACE4, lsl 00 

	// estrellas lilas
	movz x14, 0xD8, lsl 16 //#D8C9F4
	movk x14, 0xC9F4, lsl 00 

	// pasto(?) 
	movz x15, 0x2B, lsl 16 //#2B5B44
	movk x15, 0x5B44, lsl 00
	
	mov x2, SCREEN_HEIGHT         // Y Size
loop1:
	mov x1, SCREEN_WIDTH         // X Size
loop0:
	stur w10,[x0]  // Colorear el pixel N
	add x0,x0,4	   // Siguiente pixel
	sub x1,x1,1	   // Decrementar contador X
	cbnz x1,loop0  // Si no terminó la fila, salto
	sub x2,x2,1	   // Decrementar contador Y
	cbnz x2,loop1  // Si no es la última fila, salto

	// Ejemplo de uso de gpios
	mov x9, GPIO_BASE

	// Atención: se utilizan registros w porque la documentación de broadcom
	// indica que los registros que estamos leyendo y escribiendo son de 32 bits

	// Setea gpios 0 - 9 como lectura
	str wzr, [x9, GPIO_GPFSEL0]

	// Lee el estado de los GPIO 0 - 31
	ldr w10, [x9, GPIO_GPLEV0]

	// And bit a bit mantiene el resultado del bit 2 en w10
	and w11, w10, 0b10

	// w11 será 1 si había un 1 en la posición 2 de w10, si no será 0
	// efectivamente, su valor representará si GPIO 2 está activo
	lsr w11, w11, 1

	//---------------------------------------------------------------
	// Infinite Loop

InfLoop:
	b InfLoop
