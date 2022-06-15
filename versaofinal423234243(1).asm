
; *********************************************************************************
; * IST-UL
; * Modulo:    lab7-processos-boneco-teclado-continuo.asm
; * Descrição: Este programa ilustra a utilização do teclado em modo "tecla a tecla" e
; *			em modo "continuo".
; *			As teclas C e D fazem subir ou descer o valor nos displays, 
; *			uma vez por cada toque numa tecla.
; *			A tecla E causa o movimento do boneco no ecrã em modo "contínuo", 
; *			enquanto a tecla estiver carregada
; *
; *********************************************************************************

; *********************************************************************************
; * Constantes
; *********************************************************************************
DEFINE_LINHA    EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA   EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL   	EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO    	EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ		EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO  EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo

DISPLAYS		EQU 0A000H	   ; endereço do periférico que liga aos displays
TEC_LIN			EQU 0C000H	   ; endereço das linhas do teclado (periférico POUT-2)
TEC_COL			EQU 0E000H	   ; endereço das colunas do teclado (periférico PIN)
LINHA_TECLADO	EQU 8		   ; linha a testar (4ª linha, 1000b)
MASCARA			EQU	0FH		   ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
MASK 			EQU 0FFH
TECLA_C			EQU 3		   ; tecla na primeira coluna do teclado (tecla C)
TECLA_D			EQU 2	       ; tecla na segunda coluna do teclado (tecla D)
TECLA_E			EQU 4		   ; tecla na terceira coluna do teclado (tecla E)
TECLA_F			EQU 2
TOCA_SOM		EQU 605AH      ; endereço do comando para tocar um som

LARGURA			EQU	5	       ; largura do tubarão e da mina
ALTURA_TUBARAO	EQU 4	       ; altura do tubarã
LINHA        	EQU 27         ; linha do boneco (no fim do ecrâ))
COLUNA			EQU 30         ; coluna do boneco (no fim do ecrã)

LINHA_MINA      EQU 0 	   	   ; linha da mina
COLUNA_MINA		EQU 10         ; coluna da mina
ALTURA_MINA		EQU 5	 	   ; Altura da mina

MIN_COLUNA		EQU 0		   ; número da coluna mais à esquerda que o objeto pode ocupar
MAX_COLUNA		EQU 63         ; número da coluna mais à direita que o objeto pode ocupar

MAX_LINHA 		EQU 36			; número da linha mais a baixo que a mina pode ocupar.


; *********************************************************************************
; * Dados 
; *********************************************************************************
	PLACE       1000H

; Reserva do espaço para as pilhas dos processos
	STACK 100H			; espaço reservado para a pilha do processo "programa principal"
SP_inicial_prog_princ:	; este é o endereço com que o SP deste processo deve ser inicializado
							
	STACK 100H			; espaço reservado para a pilha do processo "teclado"
SP_inicial_teclado:		; este é o endereço com que o SP deste processo deve ser inicializado
						
	STACK 100H			; espaço reservado para a pilha do processo "boneco"
SP_inicial_boneco:		; este é o endereço com que o SP deste processo deve ser inicializado

	STACK 100H			; espaço reservado para a pilha do processo "boneco"
SP_inicial_missil:		; este é o endereço com que o SP deste processo deve ser inicializado

; SP inicial de cada processo "meteoro"
	STACK 100H			; espaço reservado para a pilha do processo "meteoro", instância 0
SP_inicial_meteoro0:		; este é o endereço com que o SP deste processo deve ser inicializado
	STACK 100H			; espaço reservado para a pilha do processo "meteoro", instância 0
SP_inicial_meteoro1:		; este é o endereço com que o SP deste processo deve ser inicializado
	STACK 100H			; espaço reservado para a pilha do processo "meteoro", instância 0
SP_inicial_meteoro2:		; este é o endereço com que o SP deste processo deve ser inicializado
	STACK 100H			; espaço reservado para a pilha do processo "meteoro", instância 0
SP_inicial_meteoro3:		; este é o endereço com que o SP deste processo deve ser inicializado


linha_meteoros:				; linha em que cada boneco está (inicializada com a linha inicial)
	WORD 0
	WORD 0
	WORD 0
	WORD 0
                              
coluna_meteoros:				; coluna em que cada boneco está (inicializada com a coluna inicial)
	WORD 5
	WORD 15
	WORD 24
	WORD 46

posicao_tubarao:
	WORD LINHA
	WORD COLUNA				 

;


meteoroSP_tab:
	WORD	SP_inicial_meteoro0
	WORD	SP_inicial_meteoro1
	WORD	SP_inicial_meteoro2
	WORD	SP_inicial_meteoro3


BTE_START:
	WORD movimenta_meteoro
	WORD 0
	WORD decrementa_energia
	WORD 0

tecla_carregada:
	LOCK  0				; LOCK para o teclado comunicar aos restantes processos que tecla detetou,
						; uma vez por cada tecla carregada
							
tecla_continuo:
	LOCK  0				; LOCK para o teclado comunicar aos restantes processos que tecla detetou,
						; enquanto a tecla estiver carregada


meteoro_anda:			;LOCK PARA A ROTINA DE INTERRUPCAO COMUNICAR AO PROCESSO DESCE METEOROS QUE 
						;é para andar
	LOCK 0

evento_int_0:
	LOCK  0				; LOCK para a rotina de interrupção comunicar ao processo boneco que a interrupção ocorreu

evento_int_meteoro:
	LOCK 0



DEF_MINA:						; tabela que define a mina (cor, largura, pixels)
	WORD		LARGURA
	WORD		ALTURA_MINA
	WORD    0F000H, 0, 0A000H, 0, 0F000H
	WORD    0, 0F000H, 0F000H, 0F000H, 0
	WORD    0A000H, 0F000H, 0FF00H, 0F000H, 0A000H
	WORD    0, 0F000H, 0F000H, 0F000H, 0
	WORD    0F000H, 0, 0A000H, 0, 0F000H
	WORD	0,0,0,0,0
							
DEF_BONECO:				; tabela que define o tubarão (cor, largura, pixels)
	WORD  LARGURA
	WORD  ALTURA_TUBARAO
	WORD  0, 0, 0F258H, 0, 0
	WORD  0F000H, 0F258H, 0FFFFH, 0F258H, 0F000H 
	WORD  0F258H, 0FFFFH, 0FF00H, 0FFFFH, 0F258H
	WORD  0FFFFH, 0FF00H, 0FB00H, 0FF00H, 0FFFFH
    



ENERGIA: WORD 64H
MOV_DOWN: WORD 0
; *********************************************************************************
; * Código
; *********************************************************************************
PLACE   0                     ; o código tem de começar em 0000H

inicio:
	MOV  SP, SP_inicial_prog_princ		; inicializa SP do programa principal
	MOV BTE, BTE_START
	EI0
	EI2					; permite interrupções 0
	EI					; permite interrupções (geral)
                            
    MOV  [APAGA_AVISO], R1	; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV  [APAGA_ECRÃ], R1	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	 R1, 0				; cenário de fundo número 0
    MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
	MOV	 R7, 1				; valor a somar à coluna do boneco, para o movimentar
     
	; cria processos. O CALL não invoca a rotina, apenas cria um processo executável
	CALL  teclado			; cria o processo teclado
	CALL  boneco			; cria o processo boneco
	
	MOV R11,4
	loop_bonecos:
	SUB	R11, 1			; próximo boneco
	CALL	meteoro			; cria uma nova instância do processo boneco (o valor de R11 distingue-as)
						; Cada processo fica com uma cópia independente dos registos
	CMP  R11, 0			; já criou as instâncias todas?
     JNZ	loop_bonecos		; se não, continua
	
	; o resto do programa principal é também um processo (neste caso, trata dos displays)
display_setup:
	MOV  R2, [ENERGIA]				; valor do contador, cujo valor vai ser mostrado nos displays
	MOV  R0, DISPLAYS       ; endereço do periférico que liga aos displays

	MOV R5, 0				; valor da energia em decimal
	MOV R4, 03E8H			; 1000 em decimal

calcula_decimal:
	MOV R3, R2				; valor inicial da energia
	MOD R3, R4				; valor a converter
	MOV R10, 000AH			; 10 em decimal
	DIV R4, R10				; fator de divisão
	CMP R4, 0
	JZ atualiza_display
	MOV R6, R3				; vamos calcular o digito
	DIV R6, R4				; digito
	SHL R5, 4				; mais um digito do valor decimal
	OR R5, R6				; vai compondo o resultado
	JMP calcula_decimal

atualiza_display:
	MOV  [R0], R5          ; mostra o valor do contador nos displays
	YIELD	
	JMP display_setup


; **********************************************************************
; Processo
;
; TECLADO - Processo que deteta quando se carrega numa tecla na 4ª linha
;		  do teclado e escreve o valor da coluna num LOCK.
;
; **********************************************************************

PROCESS SP_inicial_teclado	; indicação de que a rotina que se segue é um processo,
							; com indicação do valor para inicializar o SP
teclado:					; processo que implementa o comportamento do teclado
	MOV  R2, TEC_LIN		; endereço do periférico das linhas
	MOV  R3, TEC_COL		; endereço do periférico das colunas
	MOV  R5, MASCARA		; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOV  R1, LINHA_TECLADO	; testar a linha 4 

espera_tecla:			; neste ciclo espera-se até uma tecla ser premida

	YIELD				; este ciclo é potencialmente bloqueante, pelo que tem de
						; ter um ponto de fuga (aqui pode comutar para outro processo)

	MOVB  [R2], R1		; escrever no periférico de saída (linhas)
	MOVB  R0, [R3]		; ler do periférico de entrada (colunas)
	AND  R0, R5			; elimina bits para além dos bits 0-3
	CMP  R0, 0			; há tecla premida?
	JZ  espera_tecla	; se nenhuma tecla premida, repete
						
	MOV	 [tecla_carregada], R0	; informa quem estiver bloqueado neste LOCK que uma tecla foi carregada
						; (o valor escrito é o número da coluna da tecla no teclado)

ha_tecla:				; neste ciclo espera-se até NENHUMA tecla estar premida

	YIELD				; este ciclo é potencialmente bloqueante, pelo que tem de
						; ter um ponto de fuga (aqui pode comutar para outro processo)

	MOV	 [tecla_continuo], R0	; informa quem estiver bloqueado neste LOCK que uma tecla está a ser carregada
						; (o valor escrito é o número da coluna da tecla no teclado)
    MOVB  [R2], R1		; escrever no periférico de saída (linhas)
    MOVB  R0, [R3]		; ler do periférico de entrada (colunas)
	AND  R0, R5			; elimina bits para além dos bits 0-3
    CMP  R0, 0			; há tecla premida?
    JNZ  ha_tecla		; se ainda houver uma tecla premida, espera até não haver

	JMP	espera_tecla	; esta "rotina" nunca retorna porque nunca termina
						; Se se quisesse terminar o processo, era deixar o processo chegar a um RET


; **********************************************************************
; Processo
;
; BONECO - Processo que desenha um boneco e o move horizontalmente, com
;		 temporização marcada pela interrupção 0
;
; **********************************************************************

PROCESS SP_inicial_boneco	; indicação de que a rotina que se segue é um processo,
							; com indicação do valor para inicializar o SP
boneco:						; processo que implementa o comportamento do boneco
	; desenha o boneco na sua posição inicial
    MOV  R1, LINHA			; linha do boneco
	MOV	 R2, COLUNA
	MOV	 R4, DEF_BONECO		; endereço da tabela que define o boneco
	MOV  R5, 8				; atraso
ciclo_boneco:
	CALL  desenha_boneco	; desenha o boneco a partir da tabela
espera_movimento:

testa_mover_direita:
	MOV	 R3, [tecla_continuo]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	CMP	 R3, TECLA_E			; é a coluna da tecla E?
	JZ  move_direita

testa_mover_esquerda:
	MOV	 R3, [tecla_continuo]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	CMP	 R3, TECLA_F		; é a coluna da tecla E?
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


;processo meteoro
PROCESS SP_inicial_meteoro0

meteoro:
	MOV  R10, R11			; cópia do nº de instância do processo
	SHL  R10, 1			; multiplica por 2 porque as tabelas são de WORDS
	MOV  R9, meteoroSP_tab	; tabela com os SPs iniciais das várias instâncias deste processo
	MOV	SP, [R9+R10]		; re-inicializa SP deste processo, de acordo com o nº de instância
	MOV R9,coluna_meteoros
	CALL rand
	MOV R7,8
	MUL R4,R7
	MOV  [R9+R10],R4
	MOV  R2, [R9+R10]			; linha do boneco
	MOV R9,linha_meteoros
	
	MOV	 R1, [R9+R10]
	MOV	 R4, DEF_MINA		; endereço da tabela que define o boneco
	MOV R7,1
ciclo_meteoro:
	CALL desenha_meteoro
	MOV  R9, meteoro_anda
	MOV  R3, [R9]		; lê o LOCK desta instância (bloqueia até a rotina de interrupção
						; respetiva escrever neste LOCK)
						; Quando bloqueia, passa o controlo para outro processo
						; Como não há valor a transmitir, o registo pode ser um qualquer		

testa_descer:
	MOV R9,MAX_LINHA
	CMP R1,R9
	JZ meteoro


desce_mina:
	CALL apaga_meteoro
	ADD R1,1
MOV R5,[posicao_tubarao]
MOV R6,[posicao_tubarao+2]
testa_colisao_tubarao:
	MOV R9,R1
	ADD R9,5
	CMP R9,R5
	JLT ciclo_meteoro
	MOV R8,R6
	ADD R6,5
	CMP R6,R2
	JLT ciclo_meteoro
	MOV R10,R2
	ADD R10,5
	CMP R8,R10
	JGT ciclo_meteoro
	JMP game_over


	


;====================================================================================================
; **********************************************************************
; DESENHA_meteoro - Desenha um meteoro na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o meteoro
;
; **********************************************************************
desenha_meteoro:
	PUSH  R1
	PUSH  R2
	PUSH  R3
	PUSH  R4
	PUSH  R5
	PUSH  R6
	PUSH  R7
	PUSH  R8
	MOV	R4, DEF_MINA
	MOV  R8,R2
	MOV  R7, [R4]				; obtém a largura do boneco
	MOV  R5,5
	ADD	 R4, 2			
	MOV	 R6, 6				; obtém a altura do boneco	
	ADD	 R4, 2					; endereço da cor do 1º pixel (2 porque a largura é uma word)
	desenha_pixels1:       			; desenha os pixels do boneco a partir da tabela
	MOV	 R3, [R4]				; obtém a cor do próximo pixel do boneco
	CALL  escreve_pixel		; escreve cada pixel do boneco
	ADD	 R4, 2					; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R2, 1                  ; próxima coluna
    SUB  R5, 1					; menos uma coluna para tratar
    JNZ  desenha_pixels1        ; continua até percorrer toda a largura do objeto
	;troca de linha
	MOV  R2,R8
	MOV  R5,R7
	ADD  R1,1
	SUB  R6, 1
	JNZ  desenha_pixels1
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
; APAGA_meteoro - Apaga um meteoro na linha e coluna indicadas
;			  com a forma definida na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o meteoro
;
; **********************************************************************
apaga_meteoro:
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
apaga_pixels1:       			; desenha os pixels do boneco a partir da tabela
	MOV	 R3, 0					; obtém a cor do próximo pixel do boneco
	CALL  escreve_pixel			; escreve cada pixel do boneco
	ADD	 R4, 2					; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R2, 1                  ; próxima coluna
    SUB  R5, 1					; menos uma coluna para tratar
    JNZ  apaga_pixels1           ; continua até percorrer toda a largura do objeto
	;troca de linha
	MOV  R2,R8
	MOV  R5,R7
	ADD  R1,1
	SUB  R6, 1
	JNZ  apaga_pixels1
	POP  R8 
	POP  R7
	POP  R6
	POP	 R5
	POP	 R4
	POP  R3
	POP	 R2
	POP  R1
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
    MOV  R0, TEC_COL           
    MOV  R1, MASK    
    MOVB R4, [R0]             
    SHR R4, 5
    AND  R4, R1               
    POP R1
    POP R0
    RET 

;
; Interrupts
;

decrementa_energia:
	PUSH R0
	PUSH R1

	MOV R0, 5
	MOV R1, [ENERGIA]
	SUB R1, R0
	MOV [ENERGIA], R1

	POP R1
	POP R0
	RFE

movimenta_meteoro:
	PUSH	R1
	MOV [meteoro_anda],R1
	
	POP	R1
	RFE
