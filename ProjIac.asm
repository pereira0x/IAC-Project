; *********************************************************************
; * IST-UL
; * Disciplina: IAC
; * Versão:    Intermédia
; * Autores:  Henrique Dutra - 99234
; *           José Pereira   - 103252
; *           Miguel Parece  - 103369 
; *
; *********************************************************************

; *********************************************************************
; Instruções:
; Teclas:
;	- 3 : Movimentar a mina para baixo
;	- 4 : Movimentar o tubarão para a esquerda
;	- 5 : Movimentar o tubarão para a direita
;	- 6 : Incrementar o contador
;	- 7 : Desincrementar o contador
; **********************************************************************

; *********************************************************************************
; * Constantes
; *********************************************************************************
TEC_LIN				EQU 0C000H	; endereço das linhas do teclado (periférico POUT-2)
TEC_COL				EQU 0E000H	; endereço das colunas do teclado (periférico PIN)
DISPLAYS   			EQU 0A000H  ; endereço dos displays de 7 segmentos (periférico POUT-1)
LINHA_TECLADO		EQU 1		; linha a testar (1ª linha, 0001b)
MASCARA				EQU 0FH		; para isolar os 4 bits de menor peso

TOCA_SOM			EQU 605AH   ; endereço do comando para tocar um som

TECLA_METEORO		EQU 3		; tecla para movimentar a mina para baixo
TECLA_ESQUERDA		EQU 4		; tecla para movimentar o tubarão para a esquerda
TECLA_DIREITA		EQU 5		; tecla para movimentar o tubarão para a direita
TECLA_INCREMENTA    EQU 6       ; tecla para incrementar o contador
TECLA_DESINCREMENTA EQU 7       ; tecla para desincrementar o contador

LINHA_MOVE_MINA		EQU 1		; linha onde esta a tecla de mover a mina
LINHA_CONTADOR	 	EQU 2       ; linha onde estao as teclas de des/incrementar o contador.


DEFINE_LINHA    	EQU 600AH   ; endereço do comando para definir a linha
DEFINE_COLUNA   	EQU 600CH   ; endereço do comando para definir a coluna
DEFINE_PIXEL    	EQU 6012H   ; endereço do comando para escrever um pixel
APAGA_AVISO     	EQU 6040H   ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ	 		EQU 6002H   ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO  EQU 6042H   ; endereço do comando para selecionar uma imagem de fundo

LINHA        		EQU 27      ; linha do boneco (a meio do ecrã))
COLUNA				EQU 30      ; coluna do boneco (a meio do ecrã)

LINHA_MINA       	EQU 0 	    ; linha da mina
COLUNA_MINA			EQU 10  	; coluna da mina
ALTURA_MINA			EQU 5		; Altura da mina

MIN_COLUNA			EQU 0		; número da coluna mais à esquerda que o objeto pode ocupar
MAX_COLUNA			EQU 63      ; número da coluna mais à direita que o objeto pode ocupar
MAX_LINHA 			EQU 001FH	; número da linha mais a baixo que a mina pode ocupar.

ATRASO				EQU	0A00H	; atraso para limitar a velocidade de movimento do boneco

LARGURA				EQU	5		; largura do tubarão e da mina
ALTURA_TUBARAO		EQU 4		; altura do tubarão

; *********************************************************************************
; * Dados 
; *********************************************************************************
	PLACE       1000H
pilha:
	STACK 100H					; espaço reservado para a pilha 
								; (200H bytes, pois são 100H words)
SP_inicial:						; este é o endereço (1200H) com que o SP deve ser 
								; inicializado. O 1.º end. de retorno será 
								; armazenado em 11FEH (1200H-2)
							
DEF_TUBARAO:					; tabela que define o tubarão (cor, largura, pixels)
	WORD		LARGURA
	WORD		ALTURA_TUBARAO
	WORD    0, 0, 0F258H, 0, 0
	WORD    0F000H, 0F258H, 0FFFFH, 0F258H, 0F000H 
	WORD    0F258H, 0FFFFH, 0FF00H, 0FFFFH, 0F258H
	WORD    0FFFFH, 0FF00H, 0FB00H, 0FF00H, 0FFFFH

DEF_MINA:						; tabela que define a mina (cor, largura, pixels)
	WORD		LARGURA
	WORD		ALTURA_MINA
	WORD    0F000H, 0, 0A000H, 0, 0F000H
	WORD    0, 0F000H, 0F000H, 0F000H, 0
	WORD    0A000H, 0F000H, 0FF00H, 0F000H, 0A000H
	WORD    0, 0F000H, 0F000H, 0F000H, 0
	WORD    0F000H, 0, 0A000H, 0, 0F000H

; *********************************************************************************
; * Código
; *********************************************************************************
PLACE   0                     	; o código tem de começar em 0000H
inicio:
	MOV SP, SP_inicial			; inicializa SP para a palavra a seguir
								; à última da pilha
                            
	MOV [APAGA_AVISO], R1		; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV [APAGA_ECRÃ], R1		; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	R1, 0					; cenário de fundo número 0
    MOV [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
	MOV	R7, 1					; valor a somar à coluna do boneco, para o movimentar
	MOV R5, DISPLAYS  			; endereço do periférico dos displays
	MOV R8, 0					; contador global, iniciado a 0
	MOV [R5], R8				; começar o valor nos displays a 0
     
posição_mina:
	MOV  R9, LINHA_MINA         ; linha da mina
	MOV  R10, COLUNA_MINA       ; coluna da mina
	MOV  R3, DEF_MINA           ; endereço da tabela que define a mina

posição_tubarão:
	MOV R1, LINHA				; linha do tubarão
    MOV R2, COLUNA				; coluna do tubarão
	MOV	R4, DEF_TUBARAO			; endereço da tabela que define o tubarão

mostra_mina:
	CALL desenha_mina			; desenha a mina a partir da tabela
	MOV R11, ATRASO				; obtem o valor do atraso
	CALL atraso					; realiza o atraso

mostra_tubarao:
	CALL desenha_boneco		; desenha o tubarao a partir da tabela
	MOV R11, ATRASO				; obtem o valor do atraso
	CALL atraso					; realiza o atraso

reset_teclado:
	MOV R6, LINHA_TECLADO		; primeira linha a testar no teclado
	JMP espera_tecla			; vai esperar por uma tecla premida

espera_tecla:					; neste ciclo espera-se até uma tecla ser premida
	CALL teclado				; leitura às teclas
	SHL R6,1					; Testa a proxima colina (da 1º linha para a 4º linha)
	PUSH R8      				
	MOV R8, MASCARA				; mascara com "1" nos 4 bits de menor peso
	AND R6, R8					; isolar os 4 bits de menor peso
	POP R8	
    JZ reset_teclado      		; Se todas as linhas foram testadas, repete o ciclo
	CMP	R0, 0					; ve se ha alguma tecla premida
	JZ espera_tecla				; espera, enquanto não houver tecla premida
	CMP R0, TECLA_INCREMENTA	; tecla para incrementar o contador
	JZ incrementa		
	CMP R0, TECLA_DESINCREMENTA ; tecla para desincrementar o contador
	JZ desincrementa	
	CMP R0, TECLA_METEORO		; tecla para mover o meteoro
	JZ move_mina		
	CMP	R0, TECLA_ESQUERDA		; tecla para andar para a esquerda
	JNZ	testa_direita			; 
	MOV	R7, -1					; vai deslocar para a esquerda
	JMP	ve_limites

testa_direita:
	CMP	R0, TECLA_DIREITA
	JNZ	espera_tecla			; tecla que não interessa
	MOV	R7, +1					; vai deslocar para a direita
	
ve_limites:
	MOV	R6, [R4]				; obtém a largura do boneco
	CALL testa_limites			; vê se chegou aos limites do ecrã e se sim força R7 a 0
	CMP	R7, 0
	JZ espera_tecla				; se não é para movimentar o objeto, vai ler o teclado de novo

move_boneco:
	CALL apaga_boneco			; apaga o boneco na sua posição corrente
	
coluna_seguinte:
	ADD	R2, R7					; para desenhar objeto na coluna seguinte (direita ou esquerda)
	JMP	mostra_tubarao			; vai desenhar o boneco de novo

incrementa:
	CALL incrementaContador		; incrementa o contador e escreve nos displays
	JMP espera_tecla			; ja nao ha tecla premida

desincrementa:				
	CALL desincrementaContador  ; desincrementa o contador e escreve nos displays
	JMP espera_tecla			; ja nao ha tecla premida

move_mina:
	CALL desce_mina				; desce a mina para a linha em baixo
	JMP espera_tecla			; ja nao ha tecla premida

;**********************************************************************
; DESENHA_MINA - Desenha a mina na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define a mina
; **********************************************************************
desenha_mina:
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R9
	PUSH R10
	MOV R1,R9
	MOV R2,R10
	MOV R4,R3
	CALL desenha_boneco
	POP R10
	POP R9
	POP R4
	POP R3
	POP R2
	POP R1
	RET

;**********************************************************************
; APAGA_MINA - Apaga a mina na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o boneco
; **********************************************************************
apaga_mina:
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R9
	PUSH R10
	MOV R1,R9
	MOV R2,R10
	MOV R4,R3
	CALL apaga_boneco
	POP R10
	POP R9
	POP R4
	POP R3
	POP R2
	POP R1
	RET
;**********************************************************************
; desenha_boneco - Desenha um boneco na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o boneco
;
; **********************************************************************
desenha_boneco:
	PUSH 	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	PUSH 	R6
	PUSH 	R7
	PUSH	R8
	MOV R8,R2
	MOV	R7, [R4]				; obtém a largura do boneco
	MOV R5,R7
	ADD	R4, 2			
	MOV	R6, [R4]				; obtém a altura do boneco	
	ADD	R4, 2					; endereço da cor do 1º pixel (2 porque a largura é uma word)
desenha_pixels:       			; desenha os pixels do boneco a partir da tabela
	MOV	R3, [R4]				; obtém a cor do próximo pixel do boneco
	CALL	escreve_pixel		; escreve cada pixel do boneco
	ADD	R4, 2					; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R2, 1                  ; próxima coluna
    SUB  R5, 1					; menos uma coluna para tratar
    JNZ  desenha_pixels         ; continua até percorrer toda a largura do objeto
	;troca de linha
	MOV R2,R8
	MOV R5,R7
	ADD R1,1
	SUB  R6, 1
	JNZ  desenha_pixels
	POP R8 
	POP R7
	POP R6
	POP	R5
	POP	R4
	POP	R3
	POP	R2
	POP R1
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
	PUSH 	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	PUSH 	R6
	PUSH 	R7
	PUSH	R8
	MOV R8,R2
	MOV	R7, [R4]				; obtém a largura do boneco
	MOV R5,R7
	ADD	R4, 2			
	MOV	R6, [R4]				; obtém a altura do boneco	
	ADD	R4, 2					; endereço da cor do 1º pixel (2 porque a largura é uma word)
apaga_pixels:       			; desenha os pixels do boneco a partir da tabela
	MOV	R3, 0					; obtém a cor do próximo pixel do boneco
	CALL	escreve_pixel		; escreve cada pixel do boneco
	ADD	R4, 2					; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R2, 1                  ; próxima coluna
    SUB  R5, 1					; menos uma coluna para tratar
    JNZ  apaga_pixels           ; continua até percorrer toda a largura do objeto
	;troca de linha
	MOV R2,R8
	MOV R5,R7
	ADD R1,1
	SUB  R6, 1
	JNZ  apaga_pixels
	POP R8 
	POP R7
	POP R6
	POP	R5
	POP	R4
	POP	R3
	POP	R2
	POP R1
	RET

; **********************************************************************
; DESCE MINA - Move a mina para a linha de baixo
; Argumentos:  R9 - Linha da mina
;			   R11 - Endereço do som
;
; **********************************************************************
desce_mina:
	CALL apaga_mina				; apaga a mina
	PUSH R3
	MOV R3, MAX_LINHA			; linha maxima onde a mina pode estar
	CMP R3, R9					; ve se a mina esta na linha maxima
	POP R3
	JZ espera_mina				; se esta, nao desenha mais a mina
	ADD R9, +1					; incrementa a linha da mina
	PUSH R11
	MOV	R11, 0					; som com número 0
	MOV [TOCA_SOM], R11			; comando para tocar o som
	POP R11
	CALL desenha_mina			; desenha a mina

espera_mina:	
	MOV R6, LINHA_MOVE_MINA		; linha da tecla para desincrementar
	CALL teclado				; leitura às teclas
	CMP	R0, TECLA_METEORO 		; ve se a tecla ainda esta premida
	JZ	espera_mina			;	 espera, enquanto a tecla esta premida
	RET

; **********************************************************************
; INCREMENTACONTADOR - incrementa uma unidade ao contador
; Argumentos:   R8 - Contador
;				R5 - Endereço dos displays
;
; **********************************************************************

incrementaContador:				; incrementa o contador por uma unidade e mete nos displays
	ADD R8, 1					; incrementa uma unidade
	MOV [R5], R8				; mete nos displays

espera_incrementa:	
	MOV R6, LINHA_CONTADOR      ; linha da tecla para incrementar
	CALL teclado				; leitura às teclas
	CMP	R0, TECLA_INCREMENTA	; verifica se a tecla ainda esta premida
	JZ	espera_incrementa		; espera, enquanto houver tecla uma tecla premida
	RET

; **********************************************************************
; DESINCREMENTACONTADOR - incrementa uma unidade ao contador
; Argumentos:   R8 - Contador
;				R5 - Endereço dos displays
;
; **********************************************************************

desincrementaContador:			; desincrementa o contador por uma unidade e mete nos dispalys
	SUB R8, 0					; testa se o contador é 0
	JZ espera_desincrementa		; se for 0, vai esperar enquanto estiver a tecla premida
	SUB R8, 1					; desincrementa uma unidade
	MOV [R5], R8				; escreve no display

espera_desincrementa:	
	MOV R6, LINHA_CONTADOR		; linha da tecla para desincrementar
	CALL teclado				; leitura às teclas
	CMP	R0, TECLA_DESINCREMENTA ; ve se a tecla ainda esta premida
	JZ	espera_desincrementa	; espera, enquanto a tecla esta premida
	RET
		
; **********************************************************************
; ESCREVE_PIXEL - Escreve um pixel na linha e coluna indicadas.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R3 - cor do pixel (em formato ARGB de 16 bits)
;
; **********************************************************************
escreve_pixel:
	MOV  [DEFINE_LINHA], R1		; seleciona a linha
	MOV  [DEFINE_COLUNA], R2	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3		; altera a cor do pixel na linha e coluna já selecionadas
	RET


; **********************************************************************
; ATRASO - Executa um ciclo para implementar um atraso.
; Argumentos:   R11 - valor que define o atraso
;
; **********************************************************************
atraso:
	PUSH	R11
ciclo_atraso:
	SUB	R11, 1					; subtrai uma unidade ao atraso
	JNZ	ciclo_atraso			; se o valor de atraso ainda nao for 0, repete
	POP	R11
	RET

; **********************************************************************
; TESTA_LIMITES - Testa se o boneco chegou aos limites do ecrã e nesse caso
;			   impede o movimento (força R7 a 0)
; Argumentos:	R2 - coluna em que o objeto está
;			R6 - largura do boneco
;			R7 - sentido de movimento do boneco (valor a somar à coluna
;				em cada movimento: +1 para a direita, -1 para a esquerda)
;
; Retorna: 	R7 - 0 se já tiver chegado ao limite, inalterado caso contrário	
; **********************************************************************
testa_limites:
	PUSH	R5
	PUSH	R6
testa_limite_esquerdo:			; vê se o boneco chegou ao limite esquerdo
	MOV	R5, MIN_COLUNA
	CMP	R2, R5
	JGT	testa_limite_direito
	CMP	R7, 0					; passa a deslocar-se para a direita
	JGE	sai_testa_limites
	JMP	impede_movimento		; entre limites. Mantém o valor do R7
testa_limite_direito:			; vê se o boneco chegou ao limite direito
	ADD	R6, R2					; posição a seguir ao extremo direito do boneco
	MOV	R5, MAX_COLUNA
	CMP	R6, R5
	JLE	sai_testa_limites		; entre limites. Mantém o valor do R7
	CMP	R7, 0					; passa a deslocar-se para a direita
	JGT	impede_movimento
	JMP	sai_testa_limites
impede_movimento:
	MOV	R7, 0					; impede o movimento, forçando R7 a 0
sai_testa_limites:	
	POP	R6
	POP	R5
	RET

; **********************************************************************
; TECLADO - Faz uma leitura às teclas de uma linha do teclado e retorna o valor lido
; Argumentos:	R6 - linha a testar (em formato 1, 2, 4 ou 8)
;
; Retorna: 	R0 - valor lido das colunas do teclado (0, 1, 2, 4, ou 8)	
; **********************************************************************
teclado:
	PUSH	R2
	PUSH	R3
	PUSH	R5
	MOV  R2, TEC_LIN   			; endereço do periférico das linhas
	MOV  R3, TEC_COL   			; endereço do periférico das colunas
	MOV  R5, MASCARA   			; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOVB [R2], R6      			; escrever no periférico de saída (linhas)
	MOVB R0, [R3]      			; ler do periférico de entrada (colunas)
	AND  R0, R5        			; elimina bits para além dos bits 0-3
	JZ no_tecla					; caso nao haja nenhuma tecla premida, nao calcula nada
	CALL calcula_output			; vai calcular o numero da tecla
no_tecla:
	POP	R5
	POP	R3
	POP	R2
	RET

calcula_output:		   ; Calcula o valor da tecla premida (0 a F)
	PUSH R5
	PUSH R7
	PUSH R8
	PUSH R9
	PUSH R11
    MOV  R9, R6        ; Numero da linha
    MOV  R11, R0       ; Numero da coluna
    MOV R5,0           ; 
    MOV R7,0           ; 
    MOV R8,1           ; 

calcula_linha:         ;
    SHR R9,1           ;
    ADD R5,R8          ; 
    CMP R9,0           ;
    JNZ calcula_linha  ;
    SUB R5,R8          ;
     
calcula_coluna:        ;
    SHR R11,1          ;
    ADD R7,R8          ;
    CMP R11,0          ;
    JNZ calcula_coluna ;
    SUB R7,R8          ;
    MOV R8,4           ;
    MUL R5, R8         ;
    ADD R5,R7          ;

	MOV R0, R5		   ; R0 vai ser o numero da tecla premida
	POP R11
	POP R9
	POP R8
	POP R7
	POP R5
	RET