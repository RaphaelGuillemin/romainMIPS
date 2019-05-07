#Laura Begin et Raphael Guillemin
#segment de la memoire contenant les donnees globales
.data
#tampon reserve pour une chaine encodee
buffer: .space 28
IVX: .ascii "IVX_" #symboles pour unites
XLC: .ascii "XLC_" #symboles pour dizaines
CDM: .ascii "CDM_" #symboles pour centaines
M: .ascii "M___" #symbole pour milliers
msg: .asciiz "Entrez un nombre de 1 a 3999 :"
err: .asciiz "Erreur, veuillez entrer un nombre valide.\n"
#segment de la memoire contenant le code
.text

#prend un nombre en entree
main:	la $a0, msg
	li $v0, 4 # Print string (Code 4 de syscall)
	syscall # faire appel du service
	li $v0, 5 # charger le numero de service
	syscall # faire appel de ce service
	add $t0, $v0, $0 # recuperer le resultat de $v0 dans $t0
	
	slti $t1, $t0, 4000 # verifie si nombre est inferieur a 4000
	beq $t1, $0, erreur # si non, erreur
	blez $t0, erreur # si nombre => 0, erreur
	
	add $a0, $t0, $0 # place argument de romain
	addi $a1, $0, 1000 # deuxieme argument de romain (rang)
	la $a2, M # troisieme argument de romain (adr. symboles rang)
	la $a3, buffer # quatrieme argument de romain (adr. buffer)
	addi $sp, $sp, -4 # faire un espace sur la pile
	sw $ra, 0($sp) # stocker $ra sur la pile
	jal romain # appelle romain
	
	la $t0, buffer #charger l'adresse du buffer
	li $v0, 4 # service 4 imprime un string
	add $a0, $t0, $zero # charger String à imprimer dans $a0
	syscall # faire appel du service
	li $v0,10 #terminer le programme
	syscall	

erreur: la $a0, err
	li $v0, 4 # Print string (Code 4 de syscall)
	syscall # faire appel du service 
	j main # retourne a main
	
#fonction romain. quatre parametres: nombre a convertir, rang, addresse rang, adresse buffer
	#passe toujours ici, definies le hi et le lo ainsi que l'adresse de retour sur la pile
romain: addi $sp, $sp, -4 # faire un espace sur la pile
	sw $ra, 0($sp) # met l'adresse de retour sur la pile
	div $t0, $a0, $a1# divise le nombre par le rang
	mfhi $s1  # stocker mfhi (reste)
	mflo $s2  # stocker mflo (quotient (entier))
	
	beqz $s2, else # entier = 0 (nombre ne possede pas ce range) ? aller a else : appeler chiffre
	add $a0, $s2, $0 # 1er argument : nombre a encoder
	add $a1, $a1, $0 # 2eme argument : le rang actuel
	add $s3, $a1, $0 #sauvegarder rang actuel
	add $s4, $a2, $0 #sauvegarder adresse rang
	add $a3, $a3, $0 #4e argument : adresse de retour du buffer
	jal chiffre #appelle chiffre
	
	add $a0, $s1, $0 # 1er argument : reste à encoder
	add $a1, $s3, $0 # 2eme argument : le rang actuel
	add $a2, $s4, $0 #3e argument : adresse rang
	add $a3, $v0, $0 #4e argument : adresse de retour du buffer
	div $a1, $a1, 10 # diviser le rang par 10 et le mettre dans le 2eme parametre 
	addi $a2, $a2, -4 # changer l'adresse des symboles 
	blt $a1, 1, done_1 #si rang plus petit que 1, aller à done_1
	jal romain # appelle romain	
	j done_1
	
else:	blt $a1, 10, done_1 # Rang >= 10 ? appeler romain : done
	add $a0, $s1, $0 # met le reste dans le premier parametre
	div $a1, $a1, 10 # diviser le rang par 10 et le mettre dans le 2eme parametre 
	addi $a2, $a2, -4 # changer l'adresse des symboles 
	add $a3, $a3, $0 # 4e argument : adresse de retour du buffer
	jal romain # appelle romain
	j done_1
	
done_1:	lw $ra 0($sp) # retablir $ra
	addi $sp, $sp, 4 # retablir $sp
	jr $ra # return	

#quatre parametre : nombre a encoder, rang du chiffre a encoder, adresse contenant les symboles, adresse resultat
chiffre:addi $sp, $sp, -4 # faire un espace sur la pile
	sw $ra, 0($sp) # met l'adresse de retour sur la pile
	addi $t0, $0, 1 #stocke le chiffre 1
	slti $t1, $a0, 4 #nombre < 4?
	beq  $t1, $t0 cas1a3 # si oui : cas 1a3, sinon continuer
	beq  $a0, 4, cas4 # Si nombre = 4, aller au cas4, sinon continuer
	slti $t1, $a0, 9 # nombre > 9?
	beq $t1, $t0, cas5a8 #si oui : cas 5a8
	b   cas9 #si non : cas 9
	
cas1a3: add $a0, $a0, $0 #1er argument : nombre de repetition
	lb $a1, 0($a2) #2e argument : caractere a repeter (premier byte I, X, C ou M)
	add $a2, $a3, $0 #3e argument : adresse du buffer
	jal repeter # appelle repeter
	j done_2 #terminer
	
cas4:   addi $a0, $0, 1 #1er argument : nombre de repetitions = 1
	lb $a1, 0($a2) #2e argument : caractere a repeter (valeur 1 du rang : I, X ou C)
	addi $sp, $sp, -4 #allouer espace sur la pile
	sw $a2, 0($sp) #sauvegarder l'adresse des caractères du rang
	add $a2, $a3, $0 #3e argument : adresse du buffer
	jal repeter #appelle repeter
	addi $a0, $0, 1 #1er argument : nombre de repetitions = 1
	lw $t0, 0($sp) #charger l'adresse des caractères du rang
	addi $sp, $sp, 4 #desallouer l'espace sur la pile
	lb $a1, 1($t0) #2e argument : caractere a repeter (valeur 5 du rang : V, L ou D)
	add $a2, $v0, $0 #3e argument : adresse du buffer (retournée par repeter)
	jal repeter #appelle repeter
	j done_2 #terminer
	
cas5a8: add $s5, $a0, $0 #sauvegarder nombre a encoder
	addi $a0, $0, 1 #1er argument : nombre de repetitions = 1
	lb $a1, 1($a2) #2e argument : caractere a repeter (valeur 5 du rang : V, L ou D)
	addi $sp, $sp, -4 #allouer espace sur la pile
	sw $a2, 0($sp) #sauvegarder l'adresse des caractères du rang
	add $a2, $a3, $0 #3e argument : adresse du buffer
	jal repeter #appelle repeter
	lw $t0, 0($sp) #charger l'adresse des caractères du rang
	addi $sp, $sp, 4 #desallouer l'espace sur la pile
	sub $t1, $s5, 5 #nombre de reptitions - 5
	blez $t1, done_2 #si nombre = 5, terminer, sinon continuer
	add $a0, $t1, $0 #1er argument : nombre de repetitions
	lb $a1, 0($t0) #2e argument : caractere a repeter (valeur 1 du rang : I, X ou C)
	add $a2, $v0, $0 #3e argument : adresse du buffer
	jal repeter #appelle repeter
	j done_2 #terminer

cas9:	addi $a0, $0, 1 #1er argument : nombre de repetitions = 1
	lb $a1, 0($a2) #2e argument : caractere a repeter (valeur 1 du rang : I, X ou C)
	addi $sp, $sp, -4 #allouer espace sur la pile
	sw $a2, 0($sp) #sauvegarder l'adresse des caracteres du rang
	add $a2, $a3, $0 #3e argument : adresse du buffer
	jal repeter #appelle repeter
	addi $a0, $0, 1 #1er argument : nombre de repetitions = 1
	lw $t0, 0($sp) #charger l'adresse des caracteres du rang
	addi $sp, $sp, 4 #desallouer l'espace sur la pile
	lb $a1, 2($t0) #2e argument : caractere a repeter (valeur 5 du rang : V, L ou D)
	add $a2, $v0, $0 #3e argument : adresse du buffer (retournee par repeter)
	jal repeter #appelle repeter
	j done_2 #terminer

done_2: add $v0, $a2, $0
	lw $ra, 0($sp) # retabli $ra
	addi $sp, $sp, 4 #desallouer l'espace dans la pile
	jr $ra # return
	
#trois parametres : un nombre, l'adresse du caractere a repeter et l'adresse de sauvegarde du resultat
repeter: add $s0, $a0, $0 # stocke le nombre de repetitions
	 beqz $s0, done_0 #si plus de chiffre a repeter, aller a done
	 sb $a1, 0($a2) #mettre symbole a l'adresse du buffer
	 addi, $a2, $a2, 1 #incremente adresse du buffer
	 sub $a0, $a0, 1 #decremente le nombre de repetitions
	 j repeter #boucle continue
	 
done_0:	 add $v0, $a2, $0
	 jr $ra #return
	



	












