.data
    filename: .asciiz "numeros.txt"     # Nombre del archivo de entrada con los números
    buffer: .space 100                  # Espacio para almacenar temporalmente el contenido del archivo
    vector: .space 100                  # Espacio para almacenar los números convertidos
    space: .asciiz ", "                 # Cadena que representa la coma y espacio
    NewFile: .asciiz "equipo04.txt"     # Nombre del archivo de salida
    new_space: .space 2048              # Espacio para conversión de números a texto

.text
main: 
        # Abrir archivo de entrada
        addi $v0, $zero, 13             # Syscall para abrir archivo
        la $a0, filename                # Dirección del nombre del archivo
        addi $a1, $zero, 0              # Modo de lectura (read-only)
        addi $a2, $zero, 0              # Permisos por defecto
        syscall
        add $t0, $zero, $v0             # Guardar el descriptor del archivo en $t0

        # Leer el contenido del archivo
        addi $v0, $zero, 14             # Syscall para leer archivo
        add $a0, $zero, $t0             # Descriptor de archivo en $a0
        la $a1, buffer                  # Dirección de almacenamiento del buffer
        addi $a2, $zero, 100            # Tamaño máximo de lectura en bytes
        syscall
        add $t1, $zero, $v0             # Almacenar número de bytes leídos en $t1

        # Cerrar el archivo
        addi $v0, $zero, 16             # Syscall para cerrar archivo
        add $a0, $zero, $t0             # Descriptor de archivo
        syscall

        # Configurar punteros para el parsing de números
        la $t2, buffer                  # Puntero al inicio del buffer
        add $t3, $t2, $t1               # Puntero al final del buffer
        addi $sp, $sp, -4               # Reservar espacio en la pila

parse_loop:
        # Comprobar fin del buffer
        beq $t2, $t3, end_parse         # Si llegamos al final, salir del bucle
        lb $t4, 0($t2)                  # Cargar el siguiente byte en $t4
        beq $t4, 44, store_number       # Si es una coma (','), almacenar número
        beq $t4, 10, end_parse          # Si es salto de línea, terminar
        beq $t4, 13, end_parse          # Si es retorno de carro, terminar
        sub $t4, $t4, 48                # Convertir de ASCII a número (0-9)
        mul $t5, $t5, 10                # Multiplicar el número actual por 10
        add $t5, $t5, $t4               # Añadir el dígito actual
        addi $t2, $t2, 1                # Avanzar al siguiente byte
        j parse_loop

    store_number:
        # Almacenar el número en la pila y preparar para el siguiente
        sw $t5, 0($sp)                  # Guardar número en la pila
        addi $sp, $sp, -4               # Reservar espacio para el siguiente número
        addi $t5, $zero, 0              # Reiniciar $t5 para el próximo número
        addi $t2, $t2, 1                # Avanzar al siguiente byte
        j parse_loop

    end_parse:
        addi $sp, $sp, 4                # Ajustar la pila para iniciar la impresión

llenarVector:
        # Llenar el array desde la pila
        lw $t6, 0($sp)                  # Cargar número desde la pila
        beq $t6, 0, ordenar_e_imprimir               # Salir si encontramos un cero (fin de pila)
        bne $t7, $zero, indiceInicializado
        add $t7, $zero, 0               # Definir índice $t7 = 0
indiceInicializado:
 		sw $t6, vector($t7)             # Guardar el número en vector[i]
        
        # Imprimir el número actual
        addi $v0, $zero, 1              # Syscall para imprimir entero
        add $a0, $zero, $t6             # Número a imprimir
        syscall
        
        # Avanzar en la pila y aumentar el índice del vector
        addi $sp, $sp, 4                # Moverse al siguiente número en la pila
        addi $t7, $t7, 4                # Incrementar índice
        j llenarVector

ordenar_e_imprimir:  
    la $a0, vector 
    jal longitudArreglo         # a0 = dirección de vector[]
    addi $a1, $v0, 0            # a1 = n (longitud del array)
    addi $s0, $v0, 0            # a1 = n (longitud del array)
    jal heapsort                # Llamar a heapsort
    
    jal guardar_archivo

guardar_archivo:
    # Abrir o crear el archivo para escritura
    li $v0, 13               # syscall para abrir/crear archivo
    la $a0, NewFile          # nombre del archivo
    li $a1, 1                # modo de escritura
    li $a2, 0                # permisos por defecto
    syscall
    move $s6, $v0            # guardar el descriptor del archivo
    
    # Verificar si hubo error al abrir el archivo
    bltz $s6, salir          # si es negativo, hubo error
    
    # Inicializar variables
    la $t1, vector           # puntero al vector
    li $t2, 0                # índice
    la $s1, new_space        # buffer para conversión
    
escribir_bucle:
    lw $t3, ($t1)            # cargar número actual
    beqz $t3, cerrar_archivo  # si es 0, terminamos
    
    # Convertir número a string
    move $t4, $t3            # copiar número para conversión
    li $t5, 0                # contador de dígitos
    li $t6, 10               # divisor
    la $s1, new_space        # reiniciar puntero del buffer
    
    # Si el número es negativo, manejarlo
    bgez $t4, bucle_conversion
    li $t7, 45               # ASCII del signo menos
    sb $t7, ($s1)            # guardar el signo
    addiu $s1, $s1, 1        # avanzar puntero
    neg $t4, $t4             # hacer positivo el número
    
bucle_conversion:
    divu $t4, $t6            # dividir por 10
    mfhi $t7                 # obtener resto (último dígito)
    mflo $t4                 # obtener cociente
    addiu $t7, $t7, 48       # convertir a ASCII
    sb $t7, ($s1)            # guardar dígito
    addiu $s1, $s1, 1        # avanzar puntero
    addiu $t5, $t5, 1        # incrementar contador
    bnez $t4, bucle_conversion  # si quedan dígitos, continuar
    
    # Invertir la cadena de caracteres
    la $s1, new_space        # reiniciar puntero
    move $t7, $s1            # guardar inicio
    add $t8, $s1, $t5        # apuntar al final
    addi $t8, $t8, -1        # ajustar al último carácter
    
invertir_bucle:
    bge $t7, $t8, escribir_numero
    lb $t4, ($t7)            # cargar carácter del inicio
    lb $t6, ($t8)            # cargar carácter del final
    sb $t6, ($t7)            # intercambiar caracteres
    sb $t4, ($t8)
    addiu $t7, $t7, 1        # avanzar puntero inicio
    addiu $t8, $t8, -1       # retroceder puntero final
    j invertir_bucle
    
escribir_numero:
    # Escribir el número en el archivo
    li $v0, 15               # syscall para escribir
    move $a0, $s6            # descriptor del archivo
    la $a1, new_space        # buffer con el número
    move $a2, $t5            # longitud del número
    syscall
    
    # Avanzar al siguiente número
    addiu $t1, $t1, 4        # siguiente elemento del vector
    addiu $t2, $t2, 1        # incrementar índice
    
    # Verificar si hay más números para escribir la coma
    lw $t3, ($t1)            # cargar el siguiente número
    bnez $t3, escribir_coma     # si no es cero, escribir la coma
    j escribir_bucle           # si es cero, terminar el bucle

escribir_coma:
    # Escribir el separador (coma y espacio)
    li $v0, 15               # syscall para escribir
    move $a0, $s6            # descriptor del archivo
    la $a1, space            # ", "
    li $a2, 2                # longitud del separador
    syscall
    
    j escribir_bucle           # volver al bucle de escritura
    
cerrar_archivo:
    li $v0, 16               # syscall para cerrar archivo
    move $a0, $s6            # descriptor del archivo
    syscall
    j salir
    
salir:


exitfinal:
    li $v0, 10               # syscall para terminar el programa
    syscall

#Calcular la longitud del arreglo
longitudArreglo:
		addi $sp, $sp, -8 		                 # Reservamos espacio en la pila
		sw $ra, 0($sp)			                 # Guardamos en la pila la posiciÃ³n de retorno
		sw $a0, 4($sp)			                 # Guardamos en la pila nuestro arreglo
		addi $t1, $zero, 0 		                 # Definimos el contador
whileElementoMayorCero:
		lw  $t2,0($a0)			                 # Guardamos en $t2 cada valor del arreglo al recorrerlo
        beq $t2,$zero,endElementoMayorCero		 # Si $t2 = 0, entonces termina while
        addi $t1,$t1,1 			                 # Sumamos 1 al contador
        addi $a0,$a0,4 		                     # aumentamos en 4 el valor del indice de nuestro arreglo
        j   whileElementoMayorCero
endElementoMayorCero:    
        add $v0, $zero,$t1						 # Guardamos en $v0 la longitud
        lw  $ra,0($sp)							 # cargamos la posiciÃ³n de retorno
        lw  $a0,4($sp)							 # Cargamos en $a0 el arreglo  guardado en la pila
        addi $sp,$sp,8							 # liberamos la pila
        jr  $ra

# Función heapsort para ordenar el array usando min-heap
heapsort:
	addi $sp, $sp, -4           # Guardar $ra en la pila
	sw $ra, 0($sp)
	addi $s2, $s2, 0            # Índice para heapify
	addi $s3, $s3, 0            # Temporal para swap
	addi $t3, $zero, 2          # Temporal para dividir entre 2
	addi $t2, $a1, 0            # Guardar tamaño del array

	# Calcular índice inicial de heapificación
	div $t2, $t3                # División n/2
	mflo $t2
	addi $t2, $t2, -1           # t2 = n/2 - 1
	addi $s2, $t2, 0            # i = n/2 - 1
	j while1                    # Crear el min-heap

# Bucle para construir el min-heap
while1:
	addi $a2, $s2, 0            # Pasar índice i a heapify
	beq $s2, -1, exit1          # Salir si i < 0
	beq $s7, -1, exit1          # Salida si el proceso termina
	jal heapify                 # Llamar a heapify en el subárbol de i
	addi $s2, $s2, -1           # i = i - 1
	j while1

exit1:
	addi $s7, $zero, -1
	j while2

# Bucle principal de heapsort para ordenar elementos del heap
while2:
	addi $t0, $a1, -1           # i = n - 1
	addi $s2, $t0, 0            # Copiar valor a s2 (i)
	ble $s2, 0, salirf          # Si el índice es 0, termina el bucle

	# Intercambiar el primer y último elemento del heap
	la $t5, 0($a0)              # Dirección base del array
	lw $t3, 0($t5)              # Guardar arr[0] en t3

	# Dirección de arr[i] usando s2 como índice
	la $t8, 0($a0)
	move $t9, $s2
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	lw $t4, 0($t8)              # t4 = arr[i]
	addi $s3, $t3, 0            # Guardar arr[0] en temp
	sw $t4, 0($t5)              # arr[0] = arr[i]
	sw $s3, 0($t8)              # arr[i] = temp

	# Reducir el tamaño del heap y llamar a heapify
	add $a1, $s2, $zero         # a1 = i
	addi $a2, $zero, 0          # a2=0
	jal heapify                 # Llamada a heapify

	# Decrementar el índice y repetir el proceso
	addi $s2, $s2, -1           # i = i - 1
	j while2

salirf:
	# Restaurar y salir de heapsort
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	add $v1, $a0, $zero
	jr $ra

# Función heapify para ajustar el subárbol en min-heap
heapify:
	addi $t6, $zero, 0          # temp = 0
	addi $t1, $a2, 0            # min = i
	addi $sp, $sp, -4           # Guardar $ra en la pila
	sw $ra, 0($sp)
	addi $sp, $sp, -4           # Guardar ind_izq
	sw $s0, 0($sp)
	addi $sp, $sp, -4           # Guardar ind_der
	sw $s1, 0($sp)

	# Calcular índices de hijos izquierdo y derecho
	add $s0, $zero, $a2         # s0 = i
	sll $s0, $s0, 1             # s0 = i * 2
	addi $s0, $s0, 1            # s0 = i * 2 + 1
	add $s1, $zero, $a2         # s1 = i
	sll $s1, $s1, 1             # s1 = i * 2
	addi $s1, $s1, 2            # s1 = i * 2 + 2

	ble $a1, $s0, comparar_der  # if(n <= ind_izq)salta

	# Cargar arr[ind_izq] para comparar
	la $t8, 0($a0)
	move $t9, $s0
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	lw $t3, 0($t8)              # Cargar el valor de vector[ind_izq]

	# Cargar arr[min] para comparar
	la $t8, 0($a0)
	move $t9, $t1
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	lw $t4, 0($t8)              # t4 = arr[min]

	ble $t4, $t3, comparar_der  # if(arr[min] <= arr[ind_izq])salta
	move $t1, $s0               # else min = ind_izq
	j comparar_der

comparar_der:
	ble $a1, $s1, sort          # if(n <= ind_der)salta

	# Cargar arr[ind_der] para comparar
	la $t8, 0($a0)
	move $t9, $s1
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	lw $t5, 0($t8)              # t5 = vector[ind_der]

	# Cargar arr[min] para comparar
	la $t8, 0($a0)
	move $t9, $t1
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	lw $t4, 0($t8)              # t4 = arr[min]

	ble $t4, $t5, sort          # if(arr[min] <= arr[ind_der])salta
	move $t1, $s1               # min = ind_der
	j sort

sort:
	beq $t1, $a2, rest          # Si min == i, no hay cambio necesario, salir

	# Intercambiar arr[i] con arr[min]
	la $t8, 0($a0)              # Cargar dirección base del array en $t8
	move $t9, $a2               # Copiar índice actual i en $t9
	sll $t9, $t9, 2             # Multiplicar $t9 por 4 (tamaño palabra)
	add $t8, $t8, $t9           # $t8 apunta a arr[i]
	lw $t3, 0($t8)              # Cargar arr[i] en $t3

	# Intercambiar arr[i] con arr[min]
	la $t8, 0($a0)
	move $t9, $t1               # min en $t9
	sll $t9, $t9, 2             # Multiplicar min por 4
	add $t8, $t8, $t9           # $t8 apunta a arr[min]
	lw $t4, 0($t8)              # Cargar arr[min] en $t4

	# Realizar el intercambio
	la $t8, 0($a0)
	move $t9, $a2               # Direccionamiento para arr[i]
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	sw $t4, 0($t8)              # arr[i] = arr[min]

	la $t8, 0($a0)
	move $t9, $t1               # Direccionamiento para arr[min]
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	sw $t3, 0($t8)              # arr[min] = arr[i]

	# Llamada recursiva a heapify para asegurar la propiedad del heap
	addi $a2, $t1, 0            # i = min
	jal heapify                 # Llamada recursiva

# Fin de la función heapify
rest:
	lw $s1, 0($sp)              # Restaurar ind_der
	addi $sp, $sp, 4
	lw $s0, 0($sp)              # Restaurar ind_izq
	addi $sp, $sp, 4
	lw $ra, 0($sp)              # Restaurar $ra
	addi $sp, $sp, 4
	jr $ra                       # Regresar a heapsort
