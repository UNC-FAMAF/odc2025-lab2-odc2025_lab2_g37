.equ SCREEN_WIDTH,          640
.equ SCREEN_HEIGHT,         480

.align 2
FlagWaveOffsets:
	.word 0, 5, 8, 10, 7, 3, 0, 4

//------------------ Funciones Básicas ------------------ 
    calculate_pixel_address:
        // Parametros:
        // x3 -> Coordenada en X
        // x4 -> Coordenada en Y
        // x0 -> Coordenadas

        mov x0, SCREEN_WIDTH                    // x0 = 640
        mul x0, x0, x4                          // x0 = 640 * y  
        add x0, x0, x3                          // x0 = (640 * y) + x
        lsl x0, x0, 2                           // x0 = ((640 * y) + x) * 4
        add x0, x0, x20                         // x0 = ((640 * y) + x) * 4 + A[0]
    ret                                         

    draw_pixel:
        // Parametros
        // x1 -> Coordenada en X
        // x2 -> Coordenada en Y
        // x10 -> Color

        // Guardamos los registros actuales en el stack para no perderlos
        SUB SP, SP, 24                                  
        STUR x30, [SP, 16]
        STUR x3, [SP, 8]
        STUR x4, [SP, 0]

        // Checkeamos si las coordenadas estan dentro los limites de la pantalla
        cmp x1, SCREEN_WIDTH
        b.ge no_draw_pixel          // x1 >= 640   

        cmp x2, SCREEN_HEIGHT
        b.ge no_draw_pixel          // x2 >= 480 

        mov x3, x1                  // x3 -> Pixel X
        mov x4, x2                  // x4 -> Pixel Y

        BL calculate_pixel_address  // Calculamos la dirección dónde dibujar el pixel

        stur w10, [x0]              // Dibujamos el pixel

        no_draw_pixel:              // Reestablecemos los valores del stack
        LDR x4, [SP, 0]                                 
        LDR x3, [SP, 8]
        LDR x30, [SP, 16]
        ADD SP, SP, 24  
    ret

    check_and_draw_circle_pixel:
        // La idea es usar la ecuación de un círculo, (x-a)^2 + (y-b)^2 = r^2
        // donde centro = (x_centro,y_centro) = (a, b)
        // Si el pixel en (x1, x2) pertenece al círculo entonces dibujamos el pixel.
        // Parametros:
        // (x1, x2) -> Pixel 
        // (x4, x5) -> Centro del círculo
        // x3 -> Radio del círculo
        // x10 -> Color

        // Si (x1 - x4)^2 + (x2 - x5)^2 <= x3^2 entonces (x1, x2) esta dentro del círculo

        // Guardamos los registros actuales en el stack para no perderlos
        SUB SP, SP, 32                                  
        STUR x30, [SP, 24]
        STUR x15, [SP, 16]
        STUR x14, [SP, 8]
        STUR x13, [SP, 0]

        mul x15, x3, x3             // x15 -> r * r (radio al cuadrado)
        sub x13, x1, x4             // x13 -> (x_pixel - x_centro) 
        mul x13, x13, x13           // x13 -> (x_pixel - x_centro)^2
        sub x14, x2, x5             // x14 -> (y_pixel - y_centro)
        mul x14, x14, x14           // x14 -> (y_pixel - y_centro)^2
        add x13, x13, x14           // x13 -> (x_pixel - x_centro)^2 + (y_pixel - y_centro)^2

        cmp x13, x15
        b.gt outside_circle         // Si no esta adentro del círculo.
        bl draw_pixel               // Si esta adentro, dibujamos el pixel (x1, x2)

    outside_circle: 
        // Reestablecemos los valores del stack
        LDR x13, [SP, 0]                                
        LDR x14, [SP, 8]
        LDR x15, [SP, 16]
        LDR x30, [SP, 24]
        ADD SP, SP, 32
    ret

    draw_circle:
        // La idea es ver los pixeles SOLO del cuadrado circunscrito al círculo que queremos hacer, y ver si sus pixeles deben o no pertenecer al círculo utiilizando check_and_draw_circle_pixel.
        // Puede no ser un cuadrado en el caso de que el círculo se salga parcialmente de la pantalla.
        // Parametros:
        // x3 -> r (radio)
        // (x4, x5) -> (x_centro, y_centro)
        // x10 -> Color

        // Guardamos los registros actuales en el stack para no perderlos
        SUB SP, SP, 56                                  
        STUR x30, [SP, 48]
        STUR x9, [SP, 40]
        STUR x8, [SP, 32]
        STUR x7, [SP, 24]
        STUR x6, [SP, 16]
        STUR x2, [SP, 8]
        STUR x1, [SP, 0]

        // Calculamos el lado del cuadrado circuncrito al círculo
        add x6, x3, x3                          // x6 -> r + r (diametro)
        subs x1, x4, x3                         // x1 -> x_centro - r (X inicial para el cuadrado/rectángulo)
        b.lt set_x1_to_0                        // Si es negativo, ponemos x1 en 0
        b skip_x1
    set_x1_to_0:    
        add x1, xzr, xzr                        // x1 -> 0
    skip_x1:
        subs x2, x5, x3                         // x2 -> y_centro - r (Y inicial para el cuadrado/rectángulo)
        b.lt set_x2_to_0                        // Si es negativo, ponemos x2 en 0
        b skip_x2
    set_x2_to_0:    
        add x2, xzr, xzr                        // x2 -> 0
    skip_x2:
        mov x7, x1                              // x7 -> x_actual (x inicial para el loop interior)
        mov x9, x6                              // x9 -> altura_actual (altura inicial para el loop exterior, igual al diametro)

        // Iteramos a traves los pixeles del cuadrado que contiene al circulo.
    outer_loop:                             
        cbz x9, end_outer_loop                  // Si la altura_actual es 0, terminamos el loop
        cmp x2, SCREEN_HEIGHT
        b.ge end_outer_loop                     // si y_actual esta por fuera de la altura de la pantalla, terminamos el loop

        mov x1, x7                              // Reseteamos x1 para el comienzo de fila siguiente
        mov x8, x6                              // x8 -> ancho_actual (ancho inicial para el loop interior, igual al diametro)
        
    inner_loop:
        cbz x8, end_inner_loop                  // Si el ancho_actual es 0, terminalos el loop interior
        cmp x1, SCREEN_WIDTH
        b.ge end_inner_loop                     // Si x_actual esta por fuera de la pantalla, terminamos el loop interior.

        bl check_and_draw_circle_pixel          // Checkeamos y dibujamos el pixel (x1, x2)
        add x1, x1, 1                           // Incrementamos x
        sub x8, x8, 1                           // Disminuimos ancho_actual
        b inner_loop

    end_inner_loop:
        add x2, x2, 1                           // Incrementamos y (Nos movemos a la siguiente fila)
        sub x9, x9, 1                           // Disminuimos la altura_actual
        b outer_loop
        
    end_outer_loop:
        // Reestablecemos los valores del stack
        LDR x1, [SP, 0]                                 
        LDR x2, [SP, 8]                                 
        LDR x6, [SP, 16]                                
        LDR x7, [SP, 24]                                
        LDR x8, [SP, 32]                                
        LDR x9, [SP, 40]
        LDR x30, [SP, 48]
        ADD SP, SP, 56
    ret


    draw_rectangle:
        // Parametros
        // w10 -> Color
        // x1 -> Ancho
        // x2 -> Altura
        // x3 -> Pixel X (inicial)
        // x4 -> Pixel Y (inicial)

        // Guardamos los registros actuales en el stack
        SUB SP, SP, 40                                  
        STUR x30, [SP, 32]
        STUR x13, [SP, 24]
        STUR x12, [SP, 16]
        STUR x11, [SP, 8]
        STUR x9,  [SP, 0]

        // Calculamos la dirección de la esquina inicial
        mov x0, x3  // 
        //mov x29, x4 // Pass y to calculate_pixel_address (using x29 temporarily to avoid overwriting x4 which is needed later)
        BL calculate_pixel_address
        //mov x4, x29 // Restore original x4 (Pixel Y)

        mov x9, x2                              // x9 = x2 -> Guardamos la altura del rectángulo en x9 
        mov x13, x0                             // x13 = x0 -> Guardamos la dirección inicial de la fila actual en x13
        
    paint_rectangle_row_loop:
        cbz x9, end_paint_rectangle             // Si el contador de altura es 0, terminamos el rectángulo.
        mov x11, x1                             // x11 = x1 -> Guardamos el ancho del rectángulo en x11 (contador de columna)
        mov x12, x13                            // x12 = x13 -> Guardamos la dirección inicial de la fila actual (para cuando terminemos de pintar la fila)
        
    paint_rectangle_pixel_loop:
        cbz x11, end_paint_rectangle_pixel_loop // Si el contador de ancho es 0, temrinamos de pintar
        stur w10, [x13]                         // Memory[x13] = w10 -> Pintamos el pixel
        add x13, x13, 4                         // x13 = x13 + 4 -> Vamos al siguiente pixel
        sub x11, x11, 1                         // x11 = x11 - 1 -> Disminuimos el contador de ancho en 1
        b paint_rectangle_pixel_loop            // Seguimos pintando la fila

    end_paint_rectangle_pixel_loop:
        mov x13, x12                            // Reseteamos x13 al comienzo dela fila actual
        add x13, x13, 2560                      // x13 = x13 + (SCREEN_WIDTH * 4) -> Nos movemos al comienzo de la siguiente fila
        sub x9, x9, 1                           // x9 = x9 - 1 -> Disminuimos el contador de altura en 1
        b paint_rectangle_row_loop              // Seguiimos pintando la siguiente fila

    end_paint_rectangle:
        // Reestablecemos los valores del stack
        LDR x9, [SP, 0]                                 
        LDR x11, [SP, 8]                                
        LDR x12, [SP, 16]                               
        LDR x13, [SP, 24]                               
        LDR x30, [SP, 32]                               
        ADD SP, SP, 40
    ret

    draw_triangle:
        // Parametros:
        // w10 -> Color
        // x1 -> Ancho base
        // x2 -> Filas por paso (cuantos segmentos de altura pintamos antes de disminuir el ancho)
        // x3 -> Pixel X (Esquina superior izquierda de la parte más grande)
        // x4 -> Pixel Y (Esquina superior izquierda de la parte más grande)

        // Guardamos los registros actuales en el stack
        SUB SP, SP, 48                                  
        STUR x30, [SP, 40]
        STUR x15, [SP, 32]
        STUR x14, [SP, 24]
        STUR x13, [SP, 16]
        STUR x12, [SP, 8]
        STUR x11,  [SP, 0]

        // Calculamos la dirección de la esquina más ancha
        mov x0, x3 // Pasamos x para calcular la dirección del pixel
        //mov x29, x4 // Pass y to calculate_pixel_address (using x29 temporarily to avoid overwriting x4 which is needed later)
        BL calculate_pixel_address
        //mov x4, x29 // Restore original x4 (Pixel Y)
        
        mov x13, x0                             // x13 = x0 -> Guardamos la dirección inicial de la fila actual en x13
        mov x14, x1                             // x14 = x1 -> Guardamos el ancho actual de la fila en x14

    paint_triangle_main_loop:
        cbz x14, end_draw_triangle              // Si el ancho actual es 0, terminamos de dibujar el triangulo.
        mov x15, x2                             // x15 = x2 -> Guardamos las filas por paso en x15
        
    paint_triangle_row_segment_loop:
        cbz x15, end_row_segment_loop           // Si el contador de pasos por fila es 0, nos movemos al siguiente segmento de ancho
        
        mov x11, x14                            // x11 = x14 -> Guardamos el ancho de la fila actual en x11 (contador de columnas)
        mov x12, x13                            // x12 = x13 -> Guardamos la dirección inicial de la fila actual en x12
        
    paint_triangle_pixel_loop:
        cbz x11, end_paint_triangle_pixel_loop  // Si el contador de ancho es 0, terminamos de pintar.
        stur w10, [x13]                         // Memory[x13] = w10 -> Pintamos el pixel
        add x13, x13, 4                         // x13 = x13 + 4 -> Nos movemos al siguiente pixel
        sub x11, x11, 1                         // x11 = x11 - 1 ->  Disminuimos el contador de ancho
        b paint_triangle_pixel_loop             // Continuamos pintando la fila
        
    end_paint_triangle_pixel_loop:
        mov x13, x12                            // Reseteamos x13 al comienzo de la fila actual
        add x13, x13, 2560                      // x13 = x13 + (SCREEN_WIDTH * 4) -> Nos movemos al comienzo de la siguiente fila
        sub x15, x15, 1                         // x15 = x15 - 1 -> Disminuimos las filas por paso para el ancho actual
        b paint_triangle_row_segment_loop       // Continuamos pintando las filas para el ancho actual
            
    end_row_segment_loop:
        mov x13, x12                            // Reseteamos x13 al comienzo de la última fila del segmento
        add x13, x13, 2564                      // Nos movemos a la siguiente fila, pero corridos 1 pixel a la derecha. ((640+1)*4)
        sub x14, x14, 2                         // x14 = x14 - 2 -> Disminuimos  el ancho de la fila actual en dos pixeles (1 por cada lado)
        b paint_triangle_main_loop              // Continuamos con el siguiente segmento de ancho

    end_draw_triangle:
        // Reestablecemos los valores del stack
        LDR x11, [SP, 0]                                
        LDR x12, [SP, 8]                                
        LDR x13, [SP, 16]                               
        LDR x14, [SP, 24]                               
        LDR x15, [SP, 32]                               
        LDR x30, [SP, 40]                               
        ADD SP, SP, 48
    ret

    delay_function:
        // Parametros:
        // x8 -> Duración del Delay.

        // Guardamos los registros actuales en el stack
        SUB SP, SP, 8                                   
        STUR x9,  [SP, 0]

        mov x9, x8                                  // Inicializamos x9 con x8 (contador)
        delay_loop:
        sub x9, x9, 1                               // Disminuimos el contador
        cbnz x9, delay_loop                         //Mientras x9 no es 0, continuamos el loop.

        // Reestablecemos los valores del stack
        LDR x9, [SP, 0]                                 
        ADD SP, SP, 8
    ret
//------------------ Fin Funciones Básicas ------------------ 

//---------------------- Dibujos --------------------------
background:
    SUB SP, SP, 8 						
	STUR X30, [SP, 0]
    
    movz w10, 0x14, lsl 16
    movk w10, 0x1414, lsl 0
    mov x1, SCREEN_WIDTH    // Ancho total de la pantalla
    mov x2, SCREEN_HEIGHT   // Alto total de la pantalla
    mov x3, 0               // Posición X inicial (0)
    mov x4, 0               // Posición Y inicial (0)
    bl draw_rectangle       // Llamar a la función para dibujar el rectángulo de fondo
	
    // Pasto
	movz w10, 0x00, lsl 16
	movk w10, 0x4A00, lsl 0
	mov x1, SCREEN_WIDTH    // Ancho del suelo
	mov x2, 100             // Alto del suelo (ajustar según preferencia)
	mov x3, 0               // Posición X inicial
	mov x4, SCREEN_HEIGHT-100 // Posición Y inicial (parte inferior)
	bl draw_rectangle

    LDR X30, [SP, 0]
	ADD SP, SP, 8	
ret

luna:
    SUB SP, SP, 8 						
	STUR X30, [SP, 0]
    
    // Dibujar la luna (círculo)
	// Color de la luna (gris claro: ARGB=FFE0E0E0)
	movz w10, 0xE0, lsl 16
	movk w10, 0xE0E0, lsl 0
	mov x3, 65              // Radio de la luna (más grande)
	mov x4, 570             // Centro X (más a la derecha)
	mov x5, 70              // Centro Y (más arriba)
	bl draw_circle

	// Círculo interior 1 (gris medio: ARGB=FFCCCCCC)
	movz w10, 0xCC, lsl 16
	movk w10, 0xCCCC, lsl 0
	mov x3, 28
	mov x4, 600             // Más a la derecha
	mov x5, 90              // Más arriba
	bl draw_circle

	// Círculo interior 2 (gris medio: ARGB=FFCCCCCC)
	movz w10, 0xCC, lsl 16
	movk w10, 0xCCCC, lsl 0
	mov x3, 16
	mov x4, 545             // Más a la izquierda
	mov x5, 60              // Más arriba
	bl draw_circle

	// Círculo interior 3 (gris medio: ARGB=FFCCCCCC)
	movz w10, 0xCC, lsl 16
	movk w10, 0xCCCC, lsl 0
	mov x3, 12
	mov x4, 585             // Más a la derecha
	mov x5, 45
	bl draw_circle

	// Detalle: cráter pequeño (gris claro: ARGB=FFCCCCCC)
	movz w10, 0xCC, lsl 16
	movk w10, 0xCCCC, lsl 0
	mov x3, 7
	mov x4, 555             // Más a la izquierda
	mov x5, 95
	bl draw_circle

	// Detalle: cráter pequeño 2 (gris claro: ARGB=FFCCCCCC)
	movz w10, 0xCC, lsl 16
	movk w10, 0xCCCC, lsl 0
	mov x3, 5
	mov x4, 590             // Cerca del borde derecho
	mov x5, 60
	bl draw_circle

	// Detalle: cráter pequeño 3 (gris claro: ARGB=FFCCCCCC)
	movz w10, 0xCC, lsl 16
	movk w10, 0xCCCC, lsl 0
	mov x3, 4
	mov x4, 575             // Más centrado
	mov x5, 80
	bl draw_circle

    LDR X30, [SP, 0]
	ADD SP, SP, 8	
ret

texto:
    SUB SP, SP, 8 						
	STUR X30, [SP, 0]

    // Dibujar 'O' (aproximación con cuadrados)
    // Exterior
    movz w10, 0xFF, lsl 16
    movk w10, 0xFFFF, lsl 0
    mov x1, 30              // Ancho del segmento
    mov x2, 30              // Alto del segmento
    mov x3, 20              // Posición X
    mov x4, 40              // Posición Y
    bl draw_rectangle
    // Interior
    movz w10, 0x14, lsl 16
    movk w10, 0x1414, lsl 0
    mov x1, 10              // Ancho del segmento
    mov x2, 10              // Alto del segmento
    mov x3, 30              // Posición X
    mov x4, 50              // Posición Y
    bl draw_rectangle

    

    // Dibujar 'd' (aproximación con cuadrados)
    movz w10, 0xFF, lsl 16
    movk w10, 0xFFFF, lsl 0
    mov x1, 10
    mov x2, 50
    mov x3, 80
    mov x4, 20
    bl draw_rectangle
    mov x1, 30
    mov x2, 10
    mov x3, 60
    mov x4, 60
    bl draw_rectangle
    mov x1, 10
    mov x2, 30
    mov x3, 60
    mov x4, 40
    bl draw_rectangle
    mov x1, 30
    mov x2, 10
    mov x3, 60
    mov x4, 40
    bl draw_rectangle

    // Dibujar 'd' (aproximación con cuadrados)
    movz w10, 0xFF, lsl 16
    movk w10, 0xFFFF, lsl 0
    mov x1, 30              // Ancho del segmento
    mov x2, 50              // Alto del segmento
    mov x3, 60              // Posición X
    mov x4, 20              // Posición Y
    bl draw_rectangle
    mov x1, 20              // Ancho del segmento
    mov x2, 20              // Alto del segmento
    movz w10, 0x14, lsl 16
    movk w10, 0x1414, lsl 0
    bl draw_rectangle
    mov x1, 10              // Ancho del segmento
    mov x2, 10              // Alto del segmento
    mov x3, 70              // Posición X
    mov x4, 50              // Posición Y
    bl draw_rectangle

    // Dibujar 'C' (aproximación con cuadrados)
    // Exterior
    movz w10, 0xFF, lsl 16
    movk w10, 0xFFFF, lsl 0
    mov x1, 30              // Ancho del segmento
    mov x2, 30              // Alto del segmento
    mov x3, 100             // Posición X
    mov x4, 40              // Posición Y
    bl draw_rectangle
    // Interior
    movz w10, 0x14, lsl 16
    movk w10, 0x1414, lsl 0
    mov x1, 20              // Ancho del segmento
    mov x2, 10              // Alto del segmento
    mov x3, 110             // Posición X
    mov x4, 50              // Posición Y
    bl draw_rectangle

    // Dibujar ' ' (espacio - no se dibuja)

    // Dibujar '2' (aproximación con cuadrados)
    movz w10, 0xFF, lsl 16
    movk w10, 0xFFFF, lsl 0
    mov x1, 30
    mov x2, 50
    mov x3, 140
    mov x4, 20
    bl draw_rectangle
    movz w10, 0x14, lsl 16
    movk w10, 0x1414, lsl 0
    mov x1, 20              // Ancho del segmento
    mov x2, 10              // Alto del segmento
    mov x4, 30              // Posición Y
    bl draw_rectangle
    mov x3, 150             // Posición X
    mov x4, 50              // Posición Y
    bl draw_rectangle

    // Dibujar '0' (aproximación con cuadrados)
    // Exterior
    movz w10, 0xFF, lsl 16
    movk w10, 0xFFFF, lsl 0
    mov x1, 30              // Ancho del segmento
    mov x2, 50              // Alto del segmento
    mov x3, 180             // Posición X
    mov x4, 20              // Posición Y
    bl draw_rectangle
    // Interior
    movz w10, 0x14, lsl 16
    movk w10, 0x1414, lsl 0
    mov x1, 10              // Ancho del segmento
    mov x2, 30              // Alto del segmento
    mov x3, 190              // Posición X
    mov x4, 30              // Posición Y
    bl draw_rectangle


    // Dibujar '2' (segundo 2, aproximación con cuadrados)
    movz w10, 0xFF, lsl 16
    movk w10, 0xFFFF, lsl 0
    mov x1, 30
    mov x2, 50
    mov x3, 220
    mov x4, 20
    bl draw_rectangle
    movz w10, 0x14, lsl 16
    movk w10, 0x1414, lsl 0
    mov x1, 20              // Ancho del segmento
    mov x2, 10              // Alto del segmento
    mov x4, 30              // Posición Y
    bl draw_rectangle
    mov x3, 230             // Posición X
    mov x4, 50              // Posición Y
    bl draw_rectangle

    // Dibujar '5' (aproximación con cuadrados)
    movz w10, 0xFF, lsl 16
    movk w10, 0xFFFF, lsl 0
    mov x1, 30
    mov x2, 50
    mov x3, 260         // Posición X
    mov x4, 20          // Posición Y
    bl draw_rectangle

    movz w10, 0x14, lsl 16
    movk w10, 0x1414, lsl 0
    mov x1, 20
    mov x2, 10  
    mov x3, 270         // Posición X
    mov x4, 30          // Posición Y
    bl draw_rectangle
    mov x3, 260         // Posición X
    mov x4, 50          // Posición Y
    bl draw_rectangle

    LDR X30, [SP, 0]
	ADD SP, SP, 8	
ret
 
bandera:
    SUB SP, SP, 8 						
	STUR X30, [SP, 0]

	// Mástil (gris: ARGB=FFAAAAAA -> 0xFFAAAAAA)
	movz w10, 0xAA, lsl 16
	movk w10, 0xAAAA, lsl 0
	mov x1, 12              // Ancho del mástil
	mov x2, 300             // Alto del mástil (más alto)
	mov x3, 160             // Posición X del mástil (más a la izquierda)
	mov x4, SCREEN_HEIGHT-360 // Posición Y del mástil (ajustado para mástil más alto)
	bl draw_rectangle

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

    LDR X30, [SP, 0]
	ADD SP, SP, 8	
ret

estrellas1:
    SUB SP, SP, 8 						
    STUR X30, [SP, 0]

    // Estrella 1 (x3=50)
    mov x1, 3      // ancho
    mov x2, 3      // alto
    mov x3, 50     // x
    mov x4, 200    // y
    bl draw_rectangle

    // Estrella 4 (x3=80)
    mov x3, 80
    mov x4, 140
    bl draw_rectangle

    // Estrella 7 (x3=180)
    mov x3, 180
    mov x4, 250
    bl draw_rectangle

    // Estrella 10 (x3=300)
    mov x3, 300
    mov x4, 110
    bl draw_rectangle

    // Estrella 13 (x3=350)
    mov x3, 350
    mov x4, 350
    bl draw_rectangle

    // Estrella 16 (x3=420)
    mov x3, 420
    mov x4, 320
    bl draw_rectangle

    // Estrella 19 (x3=540)
    mov x3, 540
    mov x4, 250
    bl draw_rectangle

    LDR X30, [SP, 0]
    ADD SP, SP, 8	
    ret

estrellas2:
    SUB SP, SP, 8 						
    STUR X30, [SP, 0]

    // Estrella 2 (x3=40)
    mov x1, 3      // ancho
    mov x2, 3      // alto
    mov x3, 40
    mov x4, 100
    bl draw_rectangle

    // Estrella 5 (x3=120)
    mov x3, 120
    mov x4, 200
    bl draw_rectangle

    // Estrella 8 (x3=250)
    mov x3, 250
    mov x4, 320
    bl draw_rectangle

    // Estrella 11 (x3=320)
    mov x3, 320
    mov x4, 50
    bl draw_rectangle

    // Estrella 14 (x3=370)
    mov x3, 370
    mov x4, 90
    bl draw_rectangle

    // Estrella 17 (x3=410)
    mov x3, 410
    mov x4, 30
    bl draw_rectangle

    // Estrella 20 (x3=550)
    mov x3, 550
    mov x4, 350
    bl draw_rectangle

    LDR X30, [SP, 0]
    ADD SP, SP, 8	
    ret

estrellas3:
    SUB SP, SP, 8 						
    STUR X30, [SP, 0]

    // Estrella 3 (x3=80)
    mov x1, 3      // ancho
    mov x2, 3      // alto
    mov x3, 80
    mov x4, 300
    bl draw_rectangle

    // Estrella 6 (x3=150)
    mov x3, 150
    mov x4, 320
    bl draw_rectangle

    // Estrella 9 (x3=260)
    mov x3, 260
    mov x4, 120
    bl draw_rectangle

    // Estrella 12 (x3=350)
    mov x3, 350
    mov x4, 20
    bl draw_rectangle

    // Estrella 15 (x3=370)
    mov x3, 370
    mov x4, 250
    bl draw_rectangle

    // Estrella 18 (x3=470)
    mov x3, 470
    mov x4, 80
    bl draw_rectangle

    // Estrella 21 (x3=600)
    mov x3, 600
    mov x4, 200
    bl draw_rectangle

    LDR X30, [SP, 0]
    ADD SP, SP, 8	
    ret


//------------------- Fin Dibujos -------------------------
animacion:
    SUB SP, SP, 8 						
    STUR X30, [SP, 0]

    //estado 1
    movz w10, 0x14, lsl 16
	movk w10, 0x1414, lsl 0
    BL estrellas1
    BL estrellas2
    BL estrellas3

    MOVZ X8, 0x2800, LSL 16
    BL delay_function

    //estado 2
    movz w10, 0x40, lsl 16
	movk w10, 0x4040, lsl 0
    BL estrellas1
    BL estrellas2
    BL estrellas3

    MOVZ X8, 0x0800, LSL 16
    BL delay_function

    //estado 3
    movz w10, 0x66, lsl 16
	movk w10, 0x6666, lsl 0
    BL estrellas1
    BL estrellas2
    BL estrellas3

    MOVZ X8, 0x0800, LSL 16
    BL delay_function

    //estado 4
    movz w10, 0xC2, lsl 16
	movk w10, 0xC2C2, lsl 0
    BL estrellas1
    BL estrellas2
    BL estrellas3

    MOVZ X8, 0x0800, LSL 16
    BL delay_function

    //estado 5
    movz w10, 0xFF, lsl 16
	movk w10, 0xFFFF, lsl 0
    BL estrellas1
    BL estrellas2
    BL estrellas3

    MOVZ X8, 0x2800, LSL 16
    BL delay_function
    
    //estado 6
    movz w10, 0xC2, lsl 16
	movk w10, 0xC2C2, lsl 0
    BL estrellas1
    BL estrellas2
    BL estrellas3

    MOVZ X8, 0x0800, LSL 16
    BL delay_function

    //estado 7
    movz w10, 0x66, lsl 16
	movk w10, 0x6666, lsl 0
    BL estrellas1
    BL estrellas2
    BL estrellas3

    MOVZ X8, 0x0800, LSL 16
    BL delay_function

    //estado 8
    movz w10, 0x40, lsl 16
	movk w10, 0x4040, lsl 0
    BL estrellas1
    BL estrellas2
    BL estrellas3

    MOVZ X8, 0x0800, LSL 16
    BL delay_function

    BL animacion

    LDR X30, [SP, 0]
    ADD SP, SP, 8	
ret

//------------------ Fin Animación -----------------------
