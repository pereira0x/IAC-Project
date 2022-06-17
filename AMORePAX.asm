; *********************************************************************
; * IST-UL
; * Disciplina: IAC
; * Versão:     Intermédia
; * Grupo:	    23
; * Autores:    Henrique Dutra - 99234
; *             José Pereira   - 103252
; *             Miguel Parece  - 103369 
; *
; *********************************************************************

; *********************************************************************
; Instruções:
; Teclas:
;	- 1 : Pausar/Continuar o jogo
;	- 2 : terminar o jogo
;	- 3 : Começar/Recomecar o jogo
;	- C : Dispara missil
;	- D : Movimentar o tubarão para a esquerda
;	- E : Movimentar o tubarão para a direita
; **********************************************************************

; *********************************************************************************
; * Constantes
; *********************************************************************************
DEFINE_LINHA    EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA   EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL   	EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO    	EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ		EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO  EQU 6042H  ; endereço do comando para selecionar uma imagem de fundo

DISPLAYS		EQU 0A000H	   ; endereço do periférico que liga aos displays
TEC_LIN			EQU 0C000H	   ; endereço das linhas do teclado (periférico POUT-2)
TEC_COL			EQU 0E000H	   ; endereço das colunas do teclado (periférico PIN)
LINHA_TECLADO	EQU 8		   ; primeira linha a testar (4ª linha, 1000b)
MASCARA			EQU	0FH		   ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
MASK 			EQU 0FFH	   ; para isolar os 8 bits de menor peso

TECLA_1			EQU 1		   ; tecla 1 do teclado
TECLA_2			EQU 2		   ; tecla 2 do teclado
TECLA_3			EQU 3		   ; tecla 3 do teclado
TECLA_C			EQU 0CH		   ; tecla C do teclado
TECLA_D			EQU 0DH	       ; tecla D do teclado
TECLA_E			EQU 0EH		   ; tecla E do teclado

TOCA_SOM		EQU 605AH      ; endereço do comando para tocar um som

LARGURA			EQU	5	       ; largura dos objetos
ALTURA			EQU 5	 	   ; Altura da dos objetos

ALTURA_EXPLOSAO EQU 6          ; altura da explosão
ALTURA_TUBARAO	EQU 4	       ; altura do tubarao
LINHA        	EQU 27         ; linha do tubarao (no fim do ecrâ))
COLUNA			EQU 30         ; coluna do tubarao (no fim do ecrã)

LINHA_MINA      EQU 0 	   	   ; linha da mina
COLUNA_MINA		EQU 10         ; coluna da mina

MIN_COLUNA		EQU 0		   ; número da coluna mais à esquerda que o objeto pode ocupar
MAX_COLUNA		EQU 63         ; número da coluna mais à direita que o objeto pode ocupar

MAX_LINHA 		EQU 31		   ; número da linha mais a baixo que a mina pode ocupar.

DECIMAL_10		EQU 000AH      ; numero 10 em hexadecimal
DECIMAL_1000	EQU 03E8H	   ; numero 1000 em hexadecimal

MAX_OBJETOS		EQU 4		   ; numero maximo de minas em tela
DECREMENTA_ENERGIA_VALOR EQU 5 ; valor a decrementar à energia
DECREMENTA_MISSIL_VALOR  EQU 5 ; valor a decrementar à energia quando um missil destroi uma mina
DECREMENTA_ENERGIA_VALOR_XL EQU 10 ; valor a decrementar à energia quando o tubarao come um peixeç


; *********************************************************************************
; * Dados 
; *********************************************************************************
	PLACE       1000H

; Reserva do espaço para as pilhas dos processos
	STACK 100H			; espaço reservado para a pilha do processo "programa principal"
SP_inicial_prog_princ:
							
	STACK 100H			; espaço reservado para a pilha do processo "teclado"
SP_inicial_teclado:	
						
	STACK 100H			; espaço reservado para a pilha do processo "boneco"
SP_inicial_boneco:	

	STACK 100H			; espaço reservado para a pilha do processo "missil"
SP_inicial_missil:		

	STACK 100H			; espaço reservado para a pilha do processo "energia"
SP_inicial_energia:		

	STACK 100H			; espaço reservado para a pilha do processo "pausa"
SP_inicial_pausa:		

	STACK 100H			; espaço reservado para a pilha do processo "fim"
SP_inicial_fim:		

; SP inicial de cada processo "mina"
	STACK 100H			; espaço reservado para a pilha do processo "mina", instância 0
SP_inicial_objeto0:		
	STACK 100H			; espaço reservado para a pilha do processo "mina", instância 1
SP_inicial_objeto1:		
	STACK 100H			; espaço reservado para a pilha do processo "mina", instância 2
SP_inicial_objeto2:		
	STACK 100H			; espaço reservado para a pilha do processo "mina", instância 3
SP_inicial_objeto3:		


linha_minas:			; linha em que cada mina está
	WORD 0
	WORD 0
	WORD 0
	WORD 0
                              
coluna_minas:			; colunas iniciais em que cada mina está
	WORD 5
	WORD 15
	WORD 24
	WORD 46

posicao_missil:			; posicao inicial do missil
	WORD 200
	WORD 200

posicao_tubarao:		; posicao incial do tubarão
	WORD LINHA
	WORD COLUNA

posicao_explosao:		; posicao incial da explosao
	WORD 200
	WORD 200			 

objetosSP_tab:				; varias instancias dos objetos
	WORD SP_inicial_objeto0
	WORD SP_inicial_objeto1
	WORD SP_inicial_objeto2
	WORD SP_inicial_objeto3



BTE_START:
	WORD movimenta_mina		; interrupção da mina
	WORD movimenta_missil	; interrupção do missil
	WORD interrupt_energia  ; interrupção da energia
	WORD 0

tecla_carregada:
	LOCK 0				; LOCK para o teclado comunicar aos restantes processos que tecla detetou,
						; uma vez por cada tecla carregada
							
tecla_continuo:
	LOCK 0				; LOCK para o teclado comunicar aos restantes processos que tecla detetou,
						; enquanto a tecla estiver carregada

mina_anda:				; LOCK para a rotina de interrupção comunicar ao processo desce minas que 
	LOCK 0				; é para andar

missil_anda:			; LOCK para a rotina de interrupção comunicar ao processo do missil que 
	LOCK 0				; é para disparar

evento_int_0:
	LOCK 0				; LOCK para a rotina de interrupção comunicar ao processo boneco que a interrupção ocorreu

evento_int_energia:
	LOCK 0				; LOCK para a rotina de interrupção comunicar que a interrupção ocorreu e
						; desce a energia





DEF_MINA1:						; tabela que define a mina1
	WORD LARGURA
	WORD ALTURA
	WORD 0A000H, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0

DEF_MINA2:						; tabela que define a mina2 
	WORD LARGURA
	WORD ALTURA
	WORD 0A000H, 0A000H, 0, 0, 0
	WORD 0A000H, 0A000H, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0

DEF_MINA3:						; tabela que define a mina3
	WORD LARGURA
	WORD ALTURA
	WORD 0A000H, 0, 0A000H, 0, 0
	WORD 0, 0FF00H, 0,0,0
	WORD 0A000H, 0, 0A000H, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
DEF_MINA4:						; tabela que define a mina4´
	WORD LARGURA
	WORD ALTURA
	WORD 0F000H, 0, 0, 0F000H, 0
	WORD 0, 0F000H, 0F000H, 0, 0
	WORD 0, 0F000H, 0F000H, 0, 0
	WORD 0F000H, 0, 0, 0F000H, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
DEF_MINA5:						; tabela que define a mina5
	WORD LARGURA
	WORD ALTURA
	WORD 0F000H, 0, 0A000H, 0, 0F000H
	WORD 0, 0F000H, 0F000H, 0F000H, 0
	WORD 0A000H, 0F000H, 0FF00H, 0F000H, 0A000H
	WORD 0, 0F000H, 0F000H, 0F000H, 0
	WORD 0F000H, 0, 0A000H, 0, 0F000H
	WORD 0, 0, 0, 0, 0




DEF_PEIXE1:						; tabela que define o peixe1
	WORD LARGURA
	WORD ALTURA
	WORD 0A000H, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0


DEF_PEIXE2:						; tabela que define o peixe2
	WORD LARGURA
	WORD ALTURA
	WORD 0A000H, 0A000H, 0, 0, 0
	WORD 0A000H, 0A000H, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0
	WORD 0, 0, 0, 0, 0


DEF_PEIXE3:     				; tabela que define o peixe3
	WORD LARGURA
	WORD ALTURA
	WORD 0FF62H, 0, 0FF62H, 0, 0
	WORD 0, 0FF62H, 0, 0, 0
	WORD 0F000H, 0FF62H, 0F000H, 0, 0
	WORD 0,0, 0, 0, 0
	WORD 0,0, 0, 0, 0	
	WORD 0,0, 0, 0, 0

DEF_PEIXE4:     				; tabela que define o peixe4 (
	WORD LARGURA
	WORD ALTURA
	WORD 0FF62H, 0, 0, 0FF62H, 0
	WORD 0, 0FF62H, 0FF62H, 0, 0
	WORD 0FF62H, 0FF62H, 0FF62H, 0FF62H, 0
	WORD 0F000H, 0FF62H, 0FF62H, 0F000H, 0
	WORD 0, 0, 0, 0, 0	
	WORD 0, 0, 0, 0, 0

DEF_PEIXE5:     			; tabela que define o peixe5
	WORD LARGURA
	WORD ALTURA
	WORD 0, 0FF62H, 0, 0, 0FF62H 
	WORD 0, 0, 0FF62H, 0FF62H, 0
	WORD 0, 0, 0FF62H, 0FF62H, 0
	WORD 0, 0FF62H,  0FF62H, 0FF62H, 0FF62H
	WORD 0, 0F000H,  0FF62H, 0FF62H, 0F000H

TABELA_MINA:				; varios tamanhos das minas
	WORD DEF_MINA1
	WORD DEF_MINA2
	WORD DEF_MINA3
	WORD DEF_MINA4
	WORD DEF_MINA5

TABELA_PEIXE:				; varios tamanhos dos peixes
	WORD DEF_PEIXE1
	WORD DEF_PEIXE2
	WORD DEF_PEIXE3
	WORD DEF_PEIXE4
	WORD DEF_PEIXE5
	

DEF_TUBARAO:				; tabela que define o tubarão
	WORD LARGURA
	WORD ALTURA_TUBARAO
	WORD 0, 0, 0F258H, 0, 0
	WORD 0F000H, 0F258H, 0FFFFH, 0F258H, 0F000H 
	WORD 0F258H, 0FFFFH, 0FF00H, 0FFFFH, 0F258H
	WORD 0FFFFH, 0FF00H, 0FB00H, 0FF00H, 0FFFFH
	

DEF_EXPLOSAO:				; tabela que define a explosao
	WORD LARGURA
	WORD ALTURA_EXPLOSAO
	WORD 0, 0FF62H, 0FFA1H, 0FF62H, 0
	WORD 0FF62H, 0FFA1H, 0FFA1H, 0FFA1H, 0FF62H
	WORD 0FFA1H, 0FFA1H, 0FFFFH, 0FFA1H, 0FFA1H
	WORD 0FF62H, 0FFA1H, 0FFA1H, 0FFA1H, 0FF62H
	WORD 0, 0FF62H, 0FFA1H, 0FF62H, 0, 0
	WORD 0, 0, 0, 0, 0

TABELA_EXPLOSAO:			; tamanho unico da explosao
	WORD DEF_EXPLOSAO

DEF_MISSIL:					; tabela que define o missil 
	WORD 1
	WORD 1
	WORD 0FB00H


ENERGIA: WORD 64H			; variavel global do valor da energia	
PAUSADO: WORD 0				; variavel global para verificar se o jogo esta em pausa
POSICAO_EXPLOSAO: WORD 0	; variavel global 
; *********************************************************************************
; * Código
; *********************************************************************************
PLACE   0                   ; o código tem de começar em 0000H

inicio:
	MOV SP, SP_inicial_prog_princ	; inicializa SP do programa principal
	MOV BTE, BTE_START
	EI0						; permite interrupções 0
	EI1						; permite interrupções 1
	EI2						; permite interrupções 2
                            
    MOV [APAGA_AVISO], R1	; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV [APAGA_ECRÃ], R1	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	R1, 0				; cenário de fundo número 0
    MOV [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
	MOV	R7, 1				; valor a somar à coluna do boneco, para o movimentar
     
	; cria processos. O CALL não invoca a rotina, apenas cria um processo executável
	CALL teclado			; cria o processo teclado
	CALL boneco				; cria o processo boneco
	CALL missil				; cria o processo missil
	CALL energia			; cria o processo energia
	CALL pausa				; cria o processo pausa
	CALL fim				; cria o processo fim
	MOV R11, MAX_OBJETOS	; numero maximo de objetos (peixes e minas)
	loop_bonecos:
	SUB	R11, 1				; próximo boneco
	CALL objeto				; cria uma nova instância do processo boneco (o valor de R11 distingue-as)
							; Cada processo fica com uma cópia independente dos registos
	CMP R11, 0				; já criou as instâncias todas?
    JNZ	loop_bonecos		; se não, continua
	

	; o resto do programa principal é também um processo (neste caso, trata dos displays)
display_setup:
	MOV R2, [ENERGIA]		; valor do contador, cujo valor vai ser mostrado nos displays
	MOV R0, DISPLAYS        ; endereço do periférico que liga aos displays
	 
	MOV R5, 0				; valor da energia em decimal
	MOV R4, DECIMAL_1000	; 1000 representado em hexadecimal

calcula_decimal:			; converte a energia de hexadecimal para decimal
	MOV R3, R2				; valor inicial da energia
	MOD R3, R4				; valor a converter
	MOV R10, DECIMAL_10		; 10 em decimal
	DIV R4, R10				; fator de divisão
	CMP R4, 0				; ve se ja é menor que 10
	JZ atualiza_display		; se for, acaba a conversao
	MOV R6, R3				; vamos calcular o digito
	DIV R6, R4				; digito
	SHL R5, 4				; mais um digito do valor decimal
	OR R5, R6				; vai compondo o resultado
	JMP calcula_decimal		; repete

atualiza_display:			; atualiza o display com a energia
	MOV R8, [PAUSADO]		; lê a variavel do estado de pausa do jogo
	MOV R10, 0				
	CMP R8, R10				; ve se a variavel é 0
	JNZ pausame				; se nao for zero, vai pausar
	EI						; ativa as interrupções (geral)
checkpoint1:	
	MOV  [R0], R5           ; mostra o valor do contador nos displays
	YIELD
	JMP display_setup

pausame:
	DI						; desativa as interrupções (geral)
	JMP checkpoint1



; **********************************************************************
; Processo
;
; FIM - Processo que deteta quando se carrega na tecla de terminar o jogo,
;		e termina-o
;
; **********************************************************************
PROCESS SP_inicial_fim
fim:
YIELD
	MOV	 R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R9,TECLA_2				; tecla para terminar o jogo
	CMP	 R3, R9					; é a tecla para terminar o jogo?
	JNZ fim						; se náo é, sai
	MOV R10, 1					; se 
	MOV  [APAGA_ECRÃ], R4	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	 R1, 4				; cenário de fundo número 0
	MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
fim_loop:
	JMP fim_loop





; **************************************************+
PROCESS SP_inicial_pausa
pausa:
	MOV R1, 04AFH
tempo:
	YIELD
	
	SUB R1, 1
	JNZ tempo
	MOV R10, 0
	MOV	 R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R11, [tecla_continuo]
	CMP R11, 0
	JZ pausa
	MOV R9,TECLA_1
	CMP	 R3, R9			; é a coluna da tecla 1?
	JNZ pausa
	MOV R8, [PAUSADO]
	CMP R8, R10
	JNZ reseta
	troca_para_pausa:
		MOV R10, 1
		MOV [PAUSADO], R10
		MOV  [APAGA_ECRÃ], R4	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
		MOV	 R1, 3				; cenário de fundo número 0
		MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
		JMP pausa
	reseta:
		MOV R10, 0
		MOV [PAUSADO], R10
		MOV  [APAGA_ECRÃ], R4	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
		MOV	 R1, 0				; cenário de fundo número 0
		MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
		MOV  R1, [posicao_tubarao]			; linha do boneco
		MOV	 R2, [posicao_tubarao+2]
		MOV	 R4, DEF_TUBARAO		; endereço da tabela que define o boneco
		CALL desenha_boneco
		JMP pausa


; **********************************************************************
; Processo
;
; TECLADO - Processo que deteta quando se carrega numa tecla na 4ª linha
;		  do teclado e escreve o valor da coluna num LOCK.
;
; **********************************************************************

PROCESS SP_inicial_teclado	; indicação de que a rotina que se segue é um processo,
							; com indicação do valor para inicializar o SP
teclado:
DI					; processo que implementa o comportamento do teclado
	MOV  R2, TEC_LIN		; endereço do periférico das linhas
	MOV  R3, TEC_COL		; endereço do periférico das colunas
	MOV  R5, MASCARA		; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOV  R1, LINHA_TECLADO	; testar a linha 4 

espera_tecla:			; neste ciclo espera-se até uma tecla ser premida

	YIELD				; este ciclo é potencialmente bloqueante, pelo que tem de
						; ter um ponto de fuga (aqui pode comutar para outro processo)
	MOV R1, 16
	proxima_linha:
	SHR R1, 1
	JZ espera_tecla
	MOVB  [R2], R1		; escrever no periférico de saída (linhas)
	MOVB  R0, [R3]		; ler do periférico de entrada (colunas)
	AND  R0, R5			; elimina bits para além dos bits 0-3
	CMP  R0, 0			; há tecla premida?

	JZ  proxima_linha	; se nenhuma tecla premida, repete
	MOV R6, R1
	CALL calcula_output
	MOV	 [tecla_carregada], R0	; informa quem estiver bloqueado neste LOCK que uma tecla foi carregada
						; (o valor escrito é o número da coluna da tecla no teclado)

ha_tecla:				; neste ciclo espera-se até NENHUMA tecla estar premida

	YIELD				; este ciclo é potencialmente bloqueante, pelo que tem de
						; ter um ponto de fuga (aqui pode comutar para outro processo)
	MOV R1, 16
	proxima_linhaa:
	SHR R1, 1
	JZ ha_tecla
	MOV R6, R1
	CALL calcula_output
	MOV	 [tecla_continuo], R0	; informa quem estiver bloqueado neste LOCK que uma tecla está a ser carregada
								; (o valor escrito é o número da coluna da tecla no teclado)
    MOVB  [R2], R1				; escrever no periférico de saída (linhas)
    MOVB  R0, [R3]				; ler do periférico de entrada (colunas)
	AND  R0, R5			; elimina bits para além dos bits 0-3
    CMP  R0, 0			; há tecla premida?
    JNZ  proxima_linhaa		; se ainda houver uma tecla premida, espera até não haver

	JMP	espera_tecla	; esta "rotina" nunca retorna porque nunca termina
						; Se se quisesse terminar o processo, era deixar o processo chegar a um RET


; **********************************************************************
; Processo
;
; ENERGIA -
;
; **********************************************************************
PROCESS SP_inicial_energia
	
	energia:
		DI
		YIELD
		MOV	R0,[evento_int_energia]
		MOV R0,[ENERGIA]
		CMP R0,0
		JZ	parar
		CALL desincrementa_energia
		JMP energia
		parar:
		CALL game_over


; **********************************************************************
; Processo
;
; BONECO - Processo que desenha um boneco e o move horizontalmente, com
;		 temporização marcada pela interrupção 0
;
; **********************************************************************

PROCESS SP_inicial_boneco	; indicação de que a rotina que se segue é um processo,
							; com indicação do valor para inicializar o SP
boneco:
	DI						; processo que implementa o comportamento do boneco
	; desenha o boneco na sua posição inicial
    MOV  R1, LINHA			; linha do boneco
	MOV	 R2, COLUNA
	MOV	 R4, DEF_TUBARAO		; endereço da tabela que define o boneco
	MOV  R5, 8				; atraso
ciclo_boneco:
	CALL  desenha_boneco	; desenha o boneco a partir da tabela
espera_movimento:

testa_mover_direita:
	MOV	 R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R9,TECLA_E
	CMP	 R3, R9			; é a coluna da tecla E?
	JZ  move_direita

testa_mover_esquerda:
	MOV	 R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R9,TECLA_D
	CMP	 R3, R9		; é a coluna da tecla E?
	JZ  move_esquerda
	JNZ	 espera_movimento	; se não é, ignora e continua à espera

move_direita:

	MOV	 R7, +1				; vai deslocar para a esquerda
	JMP  move
move_esquerda:
	MOV	 R7, -1
	JMP  move
move:
	SUB  R5, 1				; subtrai uma unidade ao atraso
	CMP  R5, 0				; ve se é igual a 0
	JNZ  ciclo_boneco		; se nao é, nao move ainda
	MOV  R5, 8				; se é, repoem o valor e vai mover
	CALL  apaga_boneco		; apaga o boneco na sua posição corrente
	
	MOV	 R6, [R4]			; obtém a largura do boneco
	CALL  testa_limites		; vê se chegou aos limites do ecrã e nesse caso inverte o sentido
	ADD	 R2, R7				; para desenhar objeto na coluna seguinte (direita ou esquerda)
	MOV[posicao_tubarao],R1
	MOV[posicao_tubarao+2],R2
	JMP	 ciclo_boneco		; esta "rotina" nunca retorna porque nunca termina
							; Se se quisesse terminar o processo, era deixar o processo chegar a um RET

; **********************************************************************
; DESENHA_BONECO - Desenha um boneco na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o boneco
;
; **********************************************************************
desenha_boneco:
	PUSH  R1
	PUSH  R2
	PUSH  R3
	PUSH  R4
	PUSH  R5
	PUSH  R6
	PUSH  R7
	PUSH  R8
	MOV  R8,R2
	MOV  R7, [R4]				; obtém a largura do boneco
	MOV  R5,R7
	ADD	 R4, 2			
	MOV	 R6, [R4]				; obtém a altura do boneco	
	ADD	 R4, 2					; endereço da cor do 1º pixel (2 porque a largura é uma word)
desenha_pixels:       			; desenha os pixels do boneco a partir da tabela
	MOV	 R3, [R4]				; obtém a cor do próximo pixel do boneco
	CALL  escreve_pixel		; escreve cada pixel do boneco
	ADD	 R4, 2					; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R2, 1                  ; próxima coluna
    SUB  R5, 1					; menos uma coluna para tratar
    JNZ  desenha_pixels         ; continua até percorrer toda a largura do objeto
	;troca de linha
	MOV  R2,R8
	MOV  R5,R7
	ADD  R1,1
	SUB  R6, 1
	JNZ  desenha_pixels
	
	POP  R8 
	POP  R7
	POP  R6
	POP	 R5
	POP	 R4
	POP	 R3
	POP	 R2
	POP  R1
	RET

; **********************************************************************
; APAGA_BONECO - Apaga um boneco na linha e coluna indicadas
;			  com a forma definida na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o boneco
;
; **********************************************************************
apaga_boneco:
	PUSH  R1
	PUSH  R2
	PUSH  R3
	PUSH  R4
	PUSH  R5
	PUSH  R6
	PUSH  R7
	PUSH  R8
	MOV  R8,R2
	MOV	 R7, [R4]				; obtém a largura do boneco
	MOV  R5,R7
	ADD	 R4, 2			
	MOV	 R6, [R4]				; obtém a altura do boneco	
	ADD	 R4, 2					; endereço da cor do 1º pixel (2 porque a largura é uma word)
apaga_pixels:       			; desenha os pixels do boneco a partir da tabela
	MOV	 R3, 0					; obtém a cor do próximo pixel do boneco
	CALL  escreve_pixel			; escreve cada pixel do boneco
	ADD	 R4, 2					; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R2, 1                  ; próxima coluna
    SUB  R5, 1					; menos uma coluna para tratar
    JNZ  apaga_pixels           ; continua até percorrer toda a largura do objeto
	;troca de linha
	MOV  R2,R8
	MOV  R5,R7
	ADD  R1,1
	SUB  R6, 1
	JNZ  apaga_pixels
	POP  R8 
	POP  R7
	POP  R6
	POP	 R5
	POP	 R4
	POP  R3
	POP	 R2
	POP  R1
	RET

;processo missil================================================================
PROCESS SP_inicial_missil

missil:
	; desenha o missil na sua posição inicial


espera_tecla_disparar:
	MOV	 R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R9,TECLA_C
	
	MOV R2,[posicao_tubarao+2]
	ADD R2,2
	MOV  R1,[posicao_tubarao]
	SUB  R1, 1			; linha do boneco
	MOV	 R4, DEF_MISSIL		; endereço da tabela que define o boneco
	
	CMP	 R3, R9			; é a coluna da tecla E?
	
	JZ  ciclo_missil_energia	
	JMP espera_tecla_disparar


ciclo_missil_energia:
	MOV R10, DECREMENTA_MISSIL_VALOR	; valor a decrementar
	MOV R11, [ENERGIA]		; leitura do valora atual da energia
	SUB R11, R10				; subtrai o valor a decrementar
	MOV [ENERGIA], R11		; escreve o novo valor da energia	
ciclo_missil:
	CALL  desenha_MISSIL	; desenha o boneco a partir da tabela

	MOV	 R3, [missil_anda]
Testa_top:
	MOV R6,15
	CMP R1,R6
	JNZ sobe_missil
	CALL apaga_MISSIL
	MOV R1,200
	MOV R2,200
	MOV[posicao_missil],R1
	MOV[posicao_missil+2],R2
	JMP missil
sobe_missil:
	CALL  apaga_MISSIL		; apaga o boneco na sua posição corrente
	
	MOV	 R6, [R4]			; obtém a largura do boneco
	SUB	 R1, 1				; para desenhar objeto na coluna seguinte (direita ou esquerda)
	MOV[posicao_missil],R1
	MOV[posicao_missil+2],R2
	JMP	 ciclo_missil		; esta "rotina" nunca retorna porque nunca termina
							; Se se quisesse terminar o processo, era deixar o processo chegar a um RET

desenha_MISSIL:
	PUSH R3
	MOV R3,0FB00H ; COR DO MISSIL
	CALL escreve_pixel
	POP R3
	RET

apaga_MISSIL:
	PUSH R3
	MOV R3,0 ; COR DO MISSIL
	CALL escreve_pixel
	POP R3
	RET




;processo mina==========================================================
PROCESS SP_inicial_objeto0
objeto:
mina:
	CALL rand
	CMP R4, 3
	JLT peixe
	MOV  R10, R11			; cópia do nº de instância do processo
	SHL  R10, 1			; multiplica por 2 porque as tabelas são de WORDS
	MOV  R9, objetosSP_tab	; tabela com os SPs iniciais das várias instâncias deste processo
	MOV	SP, [R9+R10]		; re-inicializa SP deste processo, de acordo com o nº de instância
	MOV R9,coluna_minas
	CALL rand
	MOV R7,8
	MUL R4,R7
	MOV  [R9+R10],R4
	MOV  R2, [R9+R10]			; linha do boneco
	MOV R9,linha_minas
	
	MOV	 R1, [R9+R10]
	MOV R4, [TABELA_MINA]
	MOV R7,1

	
	MOV R11,0

ciclo_mina:
	CALL desenha_mina
	MOV  R9, mina_anda
	MOV  R3, [R9]		; lê o LOCK desta instância (bloqueia até a rotina de interrupção
						; respetiva escrever neste LOCK)
						; Quando bloqueia, passa o controlo para outro processo
						; Como não há valor a transmitir, o registo pode ser um qualquer		

testa_descer:
	MOV R9,MAX_LINHA
	CMP R1,R9
	JZ mina

CMP R11,2
JGE	mina_evolui


mina_evolui:
	MOV R5,3
	CMP R1,R5
	JLT	mina1
	MOV R5,6
	CMP R1,R5
	JLT	mina2
	MOV R5,9
	CMP R1,R5
	JLT	mina3
	MOV R5,12
	CMP R1,R5
	JLT	mina4
	JMP	mina5

	mina1:
	MOV R4, [TABELA_MINA+2]		; endereço da tabela que define o bonec

	JMP desce_mina
	mina2:
	MOV R4, [TABELA_MINA+4]		; endereço da tabela que define o bonec
	JMP desce_mina
	mina3:
	MOV R4, [TABELA_MINA+6]		; endereço da tabela que define o bonec
	JMP desce_mina
	mina4:
	MOV R4, [TABELA_MINA+8]		; endereço da tabela que define o bonec
	JMP desce_mina
	mina5:
	
	JMP desce_mina



desce_mina:
	CALL apaga_mina
	ADD R1,1

MOV R5,[posicao_missil]
MOV R6,[posicao_missil+2]
testa_colisao_missil:
	MOV R9,0
	MOV R9,R1
	ADD R9,5
	CMP R9,R5
	JLT verifica_colisao_tubarao

	CMP R1,R5
	JGT verifica_colisao_tubarao

	CMP R6,R2
	
	JLT verifica_colisao_tubarao
	MOV R10,R2
	ADD R10,5
	CMP R6,R10
	JGT verifica_colisao_tubarao
	MOV R9,0
	MOV [TOCA_SOM],R9
	CALL incrementa_energia
		; explode me
	MOV R4, [TABELA_EXPLOSAO]
	MOV[posicao_explosao], R1
	MOV [posicao_explosao+2], R2
	CALL desenha_mina
	MOV R10, 0FFFH
BACK1:
	YIELD
	SUB R10, 1
	JNZ BACK
	CALL apaga_mina
	JMP mina
	
	

verifica_colisao_tubarao:
	MOV R5,[posicao_tubarao]
	MOV R6,[posicao_tubarao+2]
	MOV R9,R1
	ADD R9,5
	CMP R9,R5
	JLT ciclo_mina

	MOV R9,R5
	ADD R5,5
	CMP R1,R5
	JGT ciclo_mina

	MOV R8,R6
	ADD R6,5
	CMP R6,R2
	JLT ciclo_mina
	MOV R10,R2
	ADD R10,5
	CMP R8,R10
	JGT ciclo_mina
	JMP game_over


peixe:
	MOV  R10, R11			; cópia do nº de instância do processo
	SHL  R10, 1			; multiplica por 2 porque as tabelas são de WORDS
	MOV  R9, objetosSP_tab	; tabela com os SPs iniciais das várias instâncias deste processo
	MOV	SP, [R9+R10]		; re-inicializa SP deste processo, de acordo com o nº de instância
	MOV R9,coluna_minas
	CALL rand
	MOV R7,8
	MUL R4,R7
	MOV  [R9+R10],R4
	MOV  R2, [R9+R10]			; linha do boneco
	MOV R9,linha_minas
	
	MOV	 R1, [R9+R10]
	MOV R4, [TABELA_PEIXE]
	MOV R7,1

	
	MOV R11,0

ciclo_peixe:
	CALL desenha_mina
	MOV  R9, mina_anda
	MOV  R3, [R9]		; lê o LOCK desta instância (bloqueia até a rotina de interrupção
						; respetiva escrever neste LOCK)
						; Quando bloqueia, passa o controlo para outro processo
						; Como não há valor a transmitir, o registo pode ser um qualquer		

testa_descer_peixe:
	MOV R9,MAX_LINHA
	CMP R1,R9
	JZ peixe

CMP R11,2
JGE	peixe_evolui


peixe_evolui:
	MOV R5,3
	CMP R1,R5
	JLT	peixe1
	MOV R5,6
	CMP R1,R5
	JLT	peixe2
	MOV R5,9
	CMP R1,R5
	JLT	peixe3
	MOV R5,12
	CMP R1,R5
	JLT	peixe4
	JMP	peixe5

	peixe1:
	MOV R4, [TABELA_PEIXE+2]		; endereço da tabela que define o bonec

	JMP desce_peixe
	peixe2:
	MOV R4, [TABELA_PEIXE+4]		; endereço da tabela que define o bonec
	JMP desce_peixe
	peixe3:
	MOV R4, [TABELA_PEIXE+6]		; endereço da tabela que define o bonec
	JMP desce_peixe
	peixe4:
	MOV R4, [TABELA_PEIXE+8]		; endereço da tabela que define o bonec
	JMP desce_peixe
	peixe5:
	
	JMP desce_peixe



desce_peixe:
	CALL apaga_mina
	ADD R1,1

MOV R5,[posicao_missil]
MOV R6,[posicao_missil+2]
testa_colisao_missil_peixe:
	MOV R9,0
	MOV R9,R1
	ADD R9,5
	CMP R9,R5
	JLT verifica_colisao_tubarao_peixe

	CMP R1,R5
	JGT verifica_colisao_tubarao_peixe

	CMP R6,R2
	
	JLT verifica_colisao_tubarao_peixe
	MOV R10,R2
	ADD R10,5
	CMP R6,R10
	JGT verifica_colisao_tubarao_peixe
	MOV R9,0
	MOV [TOCA_SOM],R9
	; explode me
	MOV R4, [TABELA_EXPLOSAO]
	MOV[posicao_explosao], R1
	MOV [posicao_explosao+2], R2
	CALL desenha_mina
	MOV R10, 0FFFH
BACK:
	YIELD
	SUB R10, 1
	JNZ BACK
	CALL apaga_mina
	JMP mina
	
	

verifica_colisao_tubarao_peixe:
	MOV R5,[posicao_tubarao]
	MOV R6,[posicao_tubarao+2]
	MOV R9,R1
	ADD R9,5
	CMP R9,R5
	JLT ciclo_peixe

	MOV R9,R5
	ADD R5,5
	CMP R1,R5
	JGT ciclo_peixe

	MOV R8,R6
	ADD R6,5
	CMP R6,R2
	JLT ciclo_peixe
	MOV R10,R2
	ADD R10,5
	CMP R8,R10
	JGT ciclo_peixe
	CALL incrementa_energiaOP
	JMP mina


	


;====================================================================================================
; **********************************************************************
; DESENHA_mina - Desenha um mina na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o mina
;
; **********************************************************************
desenha_mina:
	PUSH  R1
	PUSH  R2
	PUSH  R3
	PUSH  R4
	PUSH  R5
	PUSH  R6
	PUSH  R7
	PUSH  R8
	MOV  R8,R2
	MOV  R7, [R4]				; obtém a largura do boneco
	MOV  R5,5
	ADD	 R4, 2			
	MOV	 R6, 6				; obtém a altura do boneco	
	ADD	 R4, 2					; endereço da cor do 1º pixel (2 porque a largura é uma word)
	JMP desenha_pixels
	RET

; **********************************************************************
; APAGA_mina - Apaga um mina na linha e coluna indicadas
;			  com a forma definida na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o mina
;
; **********************************************************************
apaga_mina:
	PUSH  R1
	PUSH  R2
	PUSH  R3
	PUSH  R4
	PUSH  R5
	PUSH  R6
	PUSH  R7
	PUSH  R8
	MOV  R8,R2
	MOV	 R7, [R4]				; obtém a largura do boneco
	MOV  R5,5
	ADD	 R4, 2			
	MOV	 R6, [R4]				; obtém a altura do boneco	
	ADD	 R4, 5					; endereço da cor do 1º pixel (2 porque a largura é uma word)
	JMP apaga_pixels
	RET




escreve_pixel:
	MOV  [DEFINE_LINHA], R1		; seleciona a linha
	MOV  [DEFINE_COLUNA], R2	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3		; altera a cor do pixel na linha e coluna já selecionadas
	RET


; **********************************************************************
; TESTA_LIMITES - Testa se o boneco chegou aos limites do ecrã e nesse caso
;			   inverte o sentido de movimento
; Argumentos:	R2 - coluna em que o objeto está
;			R6 - largura do boneco
;			R7 - sentido de movimento do boneco (valor a somar à coluna
;				em cada movimento: +1 para a direita, -1 para a esquerda)
;
; Retorna: 	R7 - novo sentido de movimento (pode ser o mesmo)	
; **********************************************************************
testa_limites:
	PUSH  R5
	PUSH  R6
testa_limite_esquerdo:			; vê se o boneco chegou ao limite esquerdo
	MOV	 R5, MIN_COLUNA
	CMP	 R2, R5
	JGT	 testa_limite_direito
	CMP	 R7, 0					; passa a deslocar-se para a direita
	JGE	 sai_testa_limites
	JMP	 impede_movimento		; entre limites. Mantém o valor do R7
testa_limite_direito:			; vê se o boneco chegou ao limite direito
	ADD	 R6, R2					; posição a seguir ao extremo direito do boneco
	MOV	 R5, MAX_COLUNA
	CMP	 R6, R5
	JLE	 sai_testa_limites		; entre limites. Mantém o valor do R7
	CMP	 R7, 0					; passa a deslocar-se para a direita
	JGT	 impede_movimento
	JMP	 sai_testa_limites
impede_movimento:
	MOV	 R7, 0					; impede o movimento, forçando R7 a 0
sai_testa_limites:	
	POP	 R6
	POP	 R5
	RET


;rotina game over

game_over:
    MOV  [APAGA_ECRÃ], R1	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	 R1, 1				; cenário de fundo número 0
    MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
	ciclo_game_over:
	JMP ciclo_game_over
	RET

; **********************************************************************
; Rand - aleatorio
; Argumentos:   R1 - linha
;               R2 - coluna
;               R3 - cor do pixel (em formato ARGB de 16 bits)
;
; **********************************************************************

rand:
    PUSH R0
    PUSH R1
    MOV  R0, TEC_COL	; lê de um periférico de entrada           
    MOV  R1, MASK    	; Obtem o valor da mascara a usar
    MOVB R4, [R0]       
    SHR R4, 5			; Deslocamento para a direita de 5 bits
    AND  R4, R1         ; Obtem o valor random 
    POP R1
    POP R0
    RET 

incrementa_energia:
	PUSH R0
	PUSH R1

	MOV R0, DECREMENTA_ENERGIA_VALOR	; valor a decrementar
	MOV R1, [ENERGIA]		; leitura do valora atual da energia
	ADD R1, R0				; subtrai o valor a decrementar
	MOV [ENERGIA], R1		; escreve o novo valor da energia

	POP R1
	POP R0
	RET


incrementa_energiaOP:
	PUSH R0
	PUSH R1

	MOV R0, DECREMENTA_ENERGIA_VALOR_XL	; valor a decrementar
	MOV R1, [ENERGIA]		; leitura do valora atual da energia
	ADD R1, R0				; subtrai o valor a decrementar
	MOV [ENERGIA], R1		; escreve o novo valor da energia

	POP R1
	POP R0
	RET

desincrementa_energia:
	PUSH R0
	PUSH R1

	MOV R0, DECREMENTA_ENERGIA_VALOR	; valor a decrementar
	MOV R1, [ENERGIA]		; leitura do valora atual da energia
	SUB R1, R0				; subtrai o valor a decrementar
	MOV [ENERGIA], R1		; escreve o novo valor da energia

	POP R1
	POP R0
	RET


;
; Interrupts
;


interrupt_energia:
	PUSH	R1
	MOV [evento_int_energia],R1		; avisa que é para mover a mina
	
	POP	R1
	RFE
	
movimenta_mina:
	PUSH	R1
	MOV [mina_anda],R1		; avisa que é para mover a mina
	
	POP	R1
	RFE

movimenta_missil:
	PUSH	R1
	MOV [missil_anda],R1		; avisa que é para mover a mina
	
	POP	R1
	RFE



calcula_output:		   ; Calcula o valor da tecla premida (0 a F)
	PUSH R5
	PUSH R7
	PUSH R8
	PUSH R9
	PUSH R11
    MOV  R9, R6        ; Numero da linha
    MOV  R11, R0       ; Numero da coluna
    MOV R5,0            	
    MOV R7,0            
    MOV R8,1            

calcula_linha:         ; Conta qual a linha, a partir da 0
    SHR R9,1           ;
    ADD R5,R8          ; 
    CMP R9,0           ;
    JNZ calcula_linha  ;
    SUB R5,R8          ;
     
calcula_coluna:        ; Conta qual a coluna, a partir da 0
    SHR R11,1          
    ADD R7,R8          
    CMP R11,0          
    JNZ calcula_coluna 
    SUB R7,R8          
    MOV R8,4           
    MUL R5, R8         ; Multiplica por 4
    ADD R5,R7          ; Obter o valor da tecla na tal coluna e linha

	MOV R0, R5		   ; R0 vai ser o numero da tecla premida
	POP R11
	POP R9
	POP R8
	POP R7
	POP R5
	RET