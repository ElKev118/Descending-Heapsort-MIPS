.data
	# Array y otros datos iniciales
	 vector: .word 2,3,5,15,18,20	# Array a ordenar
	lenght: .word 6              
	space: .asciiz ", "            # Espacio para separar valores al imprimir
	new_line: .asciiz "\n"         # Nueva l�nea
	
.text
# Punto de entrada del programa
main: 
	# Cargar la longitud del array en $s0
	la $s0, lenght             # Cargar la direcci�n de lenght en $s0
	lw $s0, 0($s0)             # Cargar el valor de longitud desde la direcci�n en $s0
	la $t1, vector             # t1 apunta al inicio de vector[]
	addi $a1, $s0, 0           # Copiar longitud de array en $a1 para mantener $s0
	addi $t0, $zero, 0         # Inicializar �ndice i=0

	# Llamada a la rutina para imprimir el array desordenado
	jal whileImprimir

	# Imprimir una nueva l�nea despu�s del array desordenado
	li $v0, 4                  # C�digo de syscall para imprimir string
	la $a0, new_line           # Direcci�n del salto de l�nea
	syscall

	# Reestablecer los valores iniciales para la segunda impresi�n
	la $s0, lenght
	lw $s0, 0($s0)
	la $t1, vector
	addi $a1, $s0, 0
	addi $t0, $zero, 0
	jal whileImprimir          # Imprimir el array ordenado despu�s de heapsort

	beq $s7, -1, exitfinal      # Saltar a exitfinal si el proceso ha terminado
	
# Bucle para imprimir el array
whileImprimir:
	beq $t0, $s0, exit			# Si i=n, salir del bucle
	li $v0, 1                   # C�digo de syscall para imprimir integer
	lw $a0, 0($t1)              # Imprimir arr[i]
	syscall

	# Moverse al siguiente elemento e incrementar el �ndice
	addi $t1, $t1, 4            # Avanzar al siguiente elemento en el array
	addi $t0, $t0, 1            # Incrementar el �ndice i
	beq $t0, $s0, exit          # Si i=n, salir del bucle

	# Imprimir una coma y espacio entre los n�meros
	li $v0, 4
	la $a0, space               # Direcci�n de espacio y coma
	syscall

	j whileImprimir             # Repetir el ciclo

exit: 
	# Preparar la pila para llamar a heapsort
	addi $sp, $sp, -4           # Reservar espacio en pila
	sw $ra, 0($sp)              # Guardar el valor de $ra en la pila
	la $a0, vector              # a0 = direcci�n de vector[]
	addi $a1, $s0, 0            # a1 = n (longitud del array)
	jal heapsort                # Llamar a heapsort
	lw $ra, 0($sp)              # Restaurar $ra de la pila
	addi $sp, $sp, 4            # Limpiar la pila
	jr $ra                      # Regresar a main
	
exitfinal: 
	addi $v0, $zero,10 # C�digo de syscall para terminar el programa
	syscall 	
	
# Funci�n heapsort para ordenar el array usando min-heap
heapsort:
	addi $sp, $sp, -4           # Guardar $ra en la pila
	sw $ra, 0($sp)
	addi $s2, $s2, 0            # �ndice para heapify
	addi $s3, $s3, 0            # Temporal para swap
	addi $t3, $zero, 2          # Temporal para dividir entre 2
	addi $t2, $a1, 0            # Guardar tama�o del array

	# Calcular �ndice inicial de heapificaci�n
	div $t2, $t3                # Divisi�n n/2
	mflo $t2
	addi $t2, $t2, -1
	addi $s2, $t2, 0            # i = n/2 - 1
	j while1                    # Crear el min-heap
	
# Bucle para construir el min-heap
while1:
	addi $a2, $s2, 0            # Pasar �ndice i a heapify
	beq $s2, -1, exit1          # Salir si i < 0
	beq $s7, -1, exit1          # Salida si el proceso termina
	jal heapify                 # Llamar a heapify en el sub�rbol de i
	addi $s2, $s2, -1           # i = i - 1
	j while1
exit1:
	addi $s7, $zero, -1
	j while2
	
# Bucle principal de heapsort para ordenar elementos del heap
while2:
	addi $t0, $a1, -1           # i = n - 1
	addi $s2, $t0, 0            # Copiar valor a s2 (i)
	
	
	ble $s2, 0, salirf			# Si el �ndice es 0, termina el bucle
	
	# Intercambiar el primer y �ltimo elemento del heap
	la $t5, 0($a0)
	lw $t3, 0($t5)              # Guardar arr[0] en t3

	la $t8, 0($a0)
	move $t9, $s2				# Direccionamiento para arr[i]
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	lw $t4, 0($t8)              # t4 = arr[i]
	addi $s3, $t3, 0            # Guardar arr[0] en temp
	sw $t4, 0($t5)              # arr[0] = arr[i]
	sw $s3, 0($t8)              # arr[i] = temp
	
	# Reducir el tama�o del heap y llamar a heapify
	add $a1, $s2, $zero			# a1 = i
	addi $a2, $zero, 0			# a2=0

	jal heapify
	
	# Decrementar el �ndice y repetir el proceso
	addi $s2, $s2, -1			# i=i-1
	j while2
	
salirf:
	# Restaurar y salir de heapsort
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	add $v1, $a0, $zero
	jr $ra
	
# Funci�n heapify para ajustar el sub�rbol en min-heap
heapify:
	addi $t6,$zero, 0			#temp=0
	addi $t1, $a2, 0            # min = i
	addi $sp, $sp, -4           # Guardar $ra en la pila
	sw $ra, 0($sp)
	addi $sp, $sp, -4           # Guardar ind_izq
	sw $s0, 0($sp)
	addi $sp, $sp, -4           # Guardar ind_der
	sw $s1, 0($sp)
	
	# Calcular �ndices de hijos izquierdo y derecho
	add $s0, $zero, $a2         # s0 = i
	sll $s0, $s0, 1             # s0 = i * 2
	addi $s0, $s0, 1            # s0 = i * 2 + 1
	add $s1, $zero, $a2			# s1 = i
	sll $s1, $s1, 1				# s1 = i * 2
	addi $s1, $s1, 2            # s1 = i * 2 + 2
	
	ble $a1,$s0,comparar_der	# if(n<=ind_izq)salta
	la $t8, 0($a0)				# cargar direcci�n de arr[] en $t8
    move $t9, $s0 				# ind_izq a t9
    sll $t9, $t9, 2 			# ind_izq * 4 para calcular direcci�n
    add $t8, $t8, $t9 			# t8 apunta a arr[ind_izq]
    lw $t3, 0($t8) 				# Cargar el valor de vector[ind_izq]
    
	la $t8, 0($a0)
	move $t9, $t1
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	la $t4, 0($a0) 
	lw $t4, 0($t8) 				# t4 = arr[min]
	
	ble $t4,$t3,comparar_der 	# if(arr[min]<=arr[ind_izq])salta
	move $t1,$s0 				# else min=ind_izq
	j comparar_der
	
comparar_der:
	
	ble $a1,$s1, sort 			# if(n <= ind_der)salta
	la $t8, 0($a0)
	move $t9, $s1
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	la $t5, 0($a0) 
	lw $t5, 0($t8) 				# t5 = vector[ind_der]
	
	la $t8, 0($a0)
	move $t9, $t1
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	la $t4, 0($a0) 
	lw $t4, 0($t8) 				# t4 = arr[min]
	
	ble $t4, $t5, sort 			# if(arr[min] <= arr[ind_der])salta
	move $t1, $s1 				# min = ind_der
	j sort
	
sort:	
	beq $t1, $a2, rest          # Si min == i, no hay cambio necesario, salir
	la $t8, 0($a0)              # Cargar direcci�n base del array en $t8
	move $t9, $a2               # Copiar �ndice actual i en $t9
	sll $t9, $t9, 2             # Multiplicar $t9 por 4 (tama�o palabra)
	add $t8, $t8, $t9           # $t8 apunta a arr[i]
	lw $t3, 0($t8)              # Cargar arr[i] en $t3

	# Intercambiar arr[i] con arr[min]
	la $t8, 0($a0)              # Cargar direcci�n base del array en $t8
	move $t9, $t1               # Copiar min en $t9
	sll $t9, $t9, 2             # Multiplicar min por 4 para obtener direcci�n
	add $t8, $t8, $t9           # $t8 apunta a arr[min]
	lw $t4, 0($t8)              # Cargar arr[min] en $t4

	# Realizar el intercambio
	la $t8, 0($a0)
	move $t9, $a2               # Direcci�n de arr[i]
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	sw $t4, 0($t8)              # arr[i] = arr[min]

	la $t8, 0($a0)
	move $t9, $t1               # Direcci�n de arr[min]
	sll $t9, $t9, 2
	add $t8, $t8, $t9
	sw $t3, 0($t8)              # arr[min] = arr[i]

	# Llamar recursivamente a heapify para asegurar la propiedad del heap
	addi $a2, $t1, 0            # i = min
	jal heapify                 # Llamada recursiva

# Fin de la funci�n heapify
rest:
	lw $s1, 0($sp)              # Restaurar ind_der desde la pila
	addi $sp, $sp, 4            # Ajustar el stack pointer
	lw $s0, 0($sp)              # Restaurar ind_izq desde la pila
	addi $sp, $sp, 4
	lw $ra, 0($sp)              # Restaurar $ra
	addi $sp, $sp, 4
	jr $ra                      # Retorno de la funci�n heapify
