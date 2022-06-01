; *********************************************************************
; * IST-UL
; * Disciplina: IAC
; * Versão:    Intermédia
; * Autores: - Henrique Dutra - 99234
; *            José Pereira - 103252
; *            Miguel Parece - 103369 
; *
; *********************************************************************

; *********************************************************************
; * To Do
; * - O teclado deve estar completamente funcional, detetando todas as teclas; Feito
; *
; * - Deve desenhar o rover e movimentá-lo para a esquerda e para a direita (de forma 
; * contínua, enquanto se carrega na tecla), até atingir o limite do ecrã; Feito
; *
; * - Deve desenhar um meteoro (bom ou mau), no tamanho máximo, numa coluna 
; * qualquer, no topo do ecrã. Esse meteoro deve descer uma linha no ecrã sempre que se 
; * carrega numa tecla (escolha qual), mas apenas uma linha por cada clique na tecla 
; *
; * - Deve ter um cenário de fundo e um efeito sonoro, de cada vez que se carrega na tecla 
; * para o meteoro descer 
; *
; * - Use outras duas teclas para aumentar e diminuir o valor nos displays. Para já pode ser 
; * em hexadecimal, mas na versão final terá de fazer uma rotina para converter um 
; * número qualquer para dígitos em decimal. Feito
; **********************************************************************

; *********************************************************************************
; * Constantes
; *********************************************************************************
TEC_LIN				EQU 0C000H	; endereço das linhas do teclado (periférico POUT-2)
TEC_COL				EQU 0E000H	; endereço das colunas do teclado (periférico PIN)
LINHA_TECLADO		EQU 1		; linha a testar (4ª linha, 1000b)
MASCARA				EQU 0FH		; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

TECLA_ESQUERDA		EQU 4		; tecla para movimentar para a esquerda (tecla 4)
TECLA_DIREITA		EQU 5		; tecla para movimentar para a direita (tecla 5)
TECLA_INCREMENTA    EQU 6       ; tecla para incrementar o contador (tecla 6)
TECLA_DESINCREMENTA EQU 7       ; tecla para desincrementar o contador (tecla 7)
TECLA_METEORO		EQU 3		; tecla para movimentar a mina para baixo (tecla 3)

LINHA_CONTADOR	 	EQU 2       ; linha onde estao as teclas de des/incrementar o contador.


DEFINE_LINHA    	EQU 600AH   ; endereço do comando para definir a linha
DEFINE_COLUNA   	EQU 600CH   ; endereço do comando para definir a coluna
DEFINE_PIXEL    	EQU 6012H   ; endereço do comando para escrever um pixel
APAGA_AVISO     	EQU 6040H   ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ	 		EQU 6002H   ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO  EQU 6042H   ; endereço do comando para selecionar uma imagem de fundo

LINHA        		EQU  27     ; linha do boneco (a meio do ecrã))
COLUNA				EQU  30     ; coluna do boneco (a meio do ecrã)

LINHAMETEO       		EQU  0     ; linha do boneco (a meio do ecrã))
COLUNAMETEO				EQU  10     ; coluna do boneco (a meio do ecrã)
ALTURAMETEO				EQU 5		; Altura do MINA

MIN_COLUNA			EQU  0		; número da coluna mais à esquerda que o objeto pode ocupar
MAX_COLUNA			EQU  63     ; número da coluna mais à direita que o objeto pode ocupar
ATRASO				EQU	0A00H	; atraso para limitar a velocidade de movimento do boneco

LARGURA				EQU	5		; largura do Tubarao
ALTURA				EQU 4		; Altura do Tubarao
COR_PIXEL			EQU	 0FF00H	; cor do pixel: vermelho em ARGB (opaco e vermelho no máximo, verde e azul a 0)
DISPLAYS   EQU 0A000H  ; endereço dos displays de 7 segmentos (periférico POUT-1)

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
							
DEF_BONECO:						; tabela que define o boneco (cor, largura, pixels)
	WORD		LARGURA
	WORD		ALTURA
	WORD    0, 0, 0F258H, 0, 0
	WORD    0F000H, 0F258H, 0FFFFH, 0F258H, 0F000H 
	WORD    0F258H, 0FFFFH, 0FF00H, 0FFFFH, 0F258H
	WORD    0FFFFH, 0FF00H, 0FB00H, 0FF00H, 0FFFFH

DEF_METEORO:						; tabela que define o boneco (cor, largura, pixels)
	WORD		LARGURA
	WORD		ALTURAMETEO
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
     
posição_meteo:
	MOV  R9, LINHAMETEO                ; linha do boneco
	MOV  R10, COLUNAMETEO            ; coluna do boneco
	MOV  R3, DEF_METEORO        ;     endereço da tabela que define o boneco

posição_boneco:
	MOV R1, LINHA				; linha do boneco
    MOV R2, COLUNA				; coluna do boneco
	MOV	R4, DEF_BONECO			; endereço da tabela que define o boneco

mostra_boneco:
	CALL desenha_boneco			; desenha o boneco a partir da tabela
	MOV R11, ATRASO				; obtem o valor do atraso (delay)
	CALL atraso					; realiza o atraso (delay)


mostra_meteoro:
	CALL desenha_meteoro			; desenha o boneco a partir da tabela
	MOV R11, ATRASO				; obtem o valor do atraso (delay)
	CALL atraso					; realiza o atraso (delay)

ciclo:
	MOV R6, LINHA_TECLADO		; primeira linha a testar no teclado
	JMP espera_tecla			; vai esperar por uma tecla premida

incrementa:						; incrementa o contador por uma unidade e mete nos displays
	ADD R8, 1					; incrementa uma unidade
	MOV [R5], R8				; mete nos displays

espera_incrementa:	
	MOV R6, LINHA_CONTADOR      ; linha da tecla para incrementar
	CALL teclado				; leitura às teclas
	CMP	R0, TECLA_INCREMENTA	; verifica se a tecla ainda esta premida
	JZ	espera_incrementa		; espera, enquanto houver tecla uma tecla premida
	JMP espera_tecla			; ja nao ha tecla premida


desincrementa:					; desincrementa o contador por uma unidade e mete nos dispalys
	SUB R8, 0					; testa se o contador é 0
	JZ espera_desincrementa		; se for 0, vai esperar enquanto estiver a tecla premida
	SUB R8, 1					; desincrementa uma unidade
	MOV [R5], R8				; escreve no display
	JMP espera_desincrementa	; vai esperar enquanto a tecla estiver premida

espera_desincrementa:	
	MOV R6, LINHA_CONTADOR		; linha da tecla para desincrementar
	CALL teclado				; leitura às teclas
	CMP	R0, TECLA_DESINCREMENTA ; ve se a tecla ainda esta premida
	JZ	espera_desincrementa	; espera, enquanto a tecla esta premida
	JMP espera_tecla			; ja nao ha tecla premida

move_meteoro:
	CALL apaga_meteoro
	ADD R9, +1
	CALL desenha_meteoro
	JMP espera_meteoro	; vai esperar enquanto a tecla estiver premida

espera_meteoro:	
	MOV R6, 1		; linha da tecla para desincrementar
	CALL teclado				; leitura às teclas
	CMP	R0, TECLA_METEORO ; ve se a tecla ainda esta premida
	JZ	espera_meteoro	; espera, enquanto a tecla esta premida
	JMP espera_tecla			; ja nao ha tecla premida

espera_tecla:					; neste ciclo espera-se até uma tecla ser premida
	CALL teclado				; leitura às teclas
	SHL R6,1         			; Testa a proxima colina (da 4º linha para a 1º linha)
	MOV R8, MASCARA
	AND R6, R8
    JZ ciclo      				; Se todas as linhas foram testadas, repete o ciclo
	CMP	R0, 0					; ve se ha alguma tecla premida
	JZ espera_tecla				; espera, enquanto não houver tecla premida
	CMP R0, TECLA_INCREMENTA	; tecla para incrementar o contador
	JZ incrementa				; vai incrementar
	CMP R0, TECLA_DESINCREMENTA ; tecla para desincrementar o contador
	JZ desincrementa			; vai desincrementar
	CMP R0, TECLA_METEORO
	JZ move_meteoro
	CMP	R0, TECLA_ESQUERDA		
	JNZ	testa_direita
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
	JMP	mostra_boneco			; vai desenhar o boneco de novo


desenha_meteoro:
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
; DESENHA_BONECO - Desenha um boneco na linha e coluna indicadas
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
apaga_meteoro:
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
	SUB	R11, 1
	JNZ	ciclo_atraso
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

 calcula_output:
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