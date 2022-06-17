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
DECIMAL_100		EQU 64H        ; numero 100 em hexadecimal
DECIMAL_1000	EQU 03E8H	   ; numero 1000 em hexadecimal

MAX_OBJETOS		EQU 4		   ; numero maximo de minas em tela
ENERGIA_VALOR 	EQU 5 		   ; valor a decrementar à energia
ENERGIA_MISSIL_VALOR  EQU 5	   ; valor a decrementar à energia quando um missil destroi uma mina
ENERGIA_VALOR_XL EQU 10 	   ; valor a decrementar à energia quando o tubarao come um peixe

PAUSA_TEMPO		EQU 04AFH	   ; valor de tempo entre pausas
EXPLOSAO_TEMPO  EQU 0FFFH	   ; valor de tempo que a explosão fica ativa
LIMITE_MISSIL   EQU 15		   ; valor do limite do missil
FORA_DO_ECRA    EQU 200        ; posicao fora do ecra do missil

LINHA_OBJETO1		EQU 3		   ; linha até qual se desenha a mina1
LINHA_OBJETO2		EQU 6		   ; linha até qual se desenha a mina2
LINHA_OBJETO3		EQU	9		   ; linha até qual se desenha a mina3
LINHA_OBJETO4		EQU 12		   ; linha até qual se desenha a mina4

; *********************************************************************************
; * Dados 
; *********************************************************************************
	PLACE       1000H

; Reserva do espaço para as pilhas dos processos
	STACK 100H			; espaço reservado para a pilha do processo "programa principal"
SP_inicial_prog_princ:
							
	STACK 100H			; espaço reservado para a pilha do processo "teclado"
SP_inicial_teclado:	
						
	STACK 100H			; espaço reservado para a pilha do processo "tubarao"
SP_inicial_tubarao:	

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


linhas_objetos:			; linha em que cada mina está
	WORD 0
	WORD 0
	WORD 0
	WORD 0
                              
coluna_objetos:			; colunas iniciais em que cada mina está
	WORD 5
	WORD 15
	WORD 24
	WORD 46

posicao_missil:			; posicao inicial do missil
	WORD FORA_DO_ECRA
	WORD FORA_DO_ECRA

posicao_tubarao:		; posicao incial do tubarão
	WORD LINHA
	WORD COLUNA

posicao_explosao:		; posicao incial da explosao
	WORD FORA_DO_ECRA
	WORD FORA_DO_ECRA			 

objetosSP_tab:				; varias instancias dos objetos
	WORD SP_inicial_objeto0
	WORD SP_inicial_objeto1
	WORD SP_inicial_objeto2
	WORD SP_inicial_objeto3



BTE_START:
	WORD movimenta_objeto		; interrupção da mina
	WORD movimenta_missil	; interrupção do missil
	WORD interrupt_energia  ; interrupção da energia
	WORD 0

tecla_carregada:
	LOCK 0				; LOCK para o teclado comunicar aos restantes processos que tecla detetou,
						; uma vez por cada tecla carregada
							
tecla_continuo:
	LOCK 0				; LOCK para o teclado comunicar aos restantes processos que tecla detetou,
						; enquanto a tecla estiver carregada

objeto_anda:				; LOCK para a rotina de interrupção comunicar ao processo desce minas que 
	LOCK 0				; é para andar

missil_anda:			; LOCK para a rotina de interrupção comunicar ao processo do missil que 
	LOCK 0				; é para disparar

evento_int_0:
	LOCK 0				; LOCK para a rotina de interrupção comunicar ao processo tubarao que a interrupção ocorreu

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


ENERGIA: WORD DECIMAL_100			; variavel global do valor da energia	
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
	MOV	R7, 1				; valor a somar à coluna do tubarao, para o movimentar
     
	; cria processos. O CALL não invoca a rotina, apenas cria um processo executável
	CALL teclado			; cria o processo teclado
	CALL tubarao				; cria o processo tubarao
	CALL missil				; cria o processo missil
	CALL energia			; cria o processo energia
	CALL pausa				; cria o processo pausa
	CALL fim				; cria o processo fim
	MOV R11, MAX_OBJETOS	; numero maximo de objetos (peixes e minas)
	loop_tubaraos:
	SUB	R11, 1				; próximo tubarao
	CALL objeto				; cria uma nova instância do processo tubarao (o valor de R11 distingue-as)
							; Cada processo fica com uma cópia independente dos registos
	CMP R11, 0				; já criou as instâncias todas?
    JNZ	loop_tubaraos		; se não, continua
	

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
	MOV [R0], R5           ; mostra o valor do contador nos displays
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
; **********************************************************************
PROCESS SP_inicial_fim
fim:
YIELD
	MOV	R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R9,TECLA_2				; tecla para terminar o jogo
	CMP	R3, R9					; é a tecla para terminar o jogo?
	JNZ fim						; se náo é, sai
	MOV [APAGA_ECRÃ], R4		; se, é: apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	R1, 4					; cenário de fundo número 4
	MOV [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
fim_loop:						; fica aqui para sempre
	JMP fim_loop





; **********************************************************************
; Processo
;
; Pausa - Processo que deteta quando se carrega na tecla de pausar o jogo,
;		  e pausa o jogo, ou continua caso este ja esteja pausado.
; **********************************************************************
PROCESS SP_inicial_pausa
pausa:
	MOV R1, PAUSA_TEMPO  ; valor a esperar entre pausas, de forma nao bloqueante
tempo:
	YIELD
	
	SUB R1, 1					; subtrai uma unidade
	JNZ tempo					; se nao for zero, repete			
	MOV	R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R11, [tecla_continuo]	; lê o LOCK da tecla continua
	CMP R11, 0					; ve se é zero
	JZ pausa					; se for, repete
	MOV R9,TECLA_1				; tecla para pausar o jogo
	CMP	R3, R9					; é a tecla para pausar o jogo?
	JNZ pausa					; se nao for, sai
	MOV R8, [PAUSADO]			; ve o estado de pausa do jogo
	MOV R10, 0
	CMP R8, R10					; vê se é zero
	JNZ reseta					; se nao for, entao sai da pausa, continuando o jogo (reseta)
								
troca_para_pausa:			; entra em modo pausa
	MOV R10, 1					; valor que representa o jogo estar em pausa
	MOV [PAUSADO], R10			; escreve esse valor
	MOV  [APAGA_ECRÃ], R4		; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	 R1, 3					; cenário de fundo número 3
	MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
	JMP pausa					; sai

reseta:
	MOV R10, 0					; valor que representa o jogo nao estar em pausa
	MOV [PAUSADO], R10			; escreve esse valor
	MOV [APAGA_ECRÃ], R4		; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	R1, 0					; cenário de fundo número 0
	MOV [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
	MOV R1, [posicao_tubarao]			; guarda a linha do tubarão
	MOV	R2, [posicao_tubarao+2]	; guarda a coluna do tubarão
	MOV	R4, DEF_TUBARAO			; endereço da tabela que define o tubarao
	CALL desenha_tubarao			; desenha o tubarão outra vez
	JMP pausa					; sai


; **********************************************************************
; Processo
;
; TECLADO - Processo que deteta quando se carrega numa tecla
;		  do teclado e escreve o valor da coluna num LOCK.
; **********************************************************************

PROCESS SP_inicial_teclado	
teclado:					; processo que implementa o comportamento do teclado
	DI						; desativa as interrupções (geral)
	MOV R2, TEC_LIN			; endereço do periférico das linhas
	MOV R3, TEC_COL			; endereço do periférico das colunas
	MOV R5, MASCARA			; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOV R1, LINHA_TECLADO	; testar a linha 4 primeiro 

espera_tecla:				; neste ciclo espera-se até uma tecla ser premida

	YIELD					; este ciclo é potencialmente bloqueante, pelo que tem de
							; ter um ponto de fuga (aqui pode comutar para outro processo)
	MOV R1, 16
	proxima_linha:
	SHR R1, 1
	JZ espera_tecla
	MOVB [R2], R1			; escrever no periférico de saída (linhas)
	MOVB R0, [R3]			; ler do periférico de entrada (colunas)
	AND R0, R5				; elimina bits para além dos bits 0-3
	CMP R0, 0				; há tecla premida?

	JZ proxima_linha		; se nenhuma tecla premida, repete
	MOV R6, R1
	CALL calcula_output		; calcula o numero da tecla
	MOV [tecla_carregada], R0	; informa quem estiver bloqueado neste LOCK que uma tecla foi carregada
							; (o valor escrito é o número da coluna da tecla no teclado)

ha_tecla:					; neste ciclo espera-se até NENHUMA tecla estar premida

	YIELD					; este ciclo é potencialmente bloqueante, pelo que tem de
							; ter um ponto de fuga (aqui pode comutar para outro processo)
	MOV R1, 16
	proxima_linhaa:
	SHR R1, 1
	JZ ha_tecla
	MOV R6, R1
	CALL calcula_output		; calcula o numero da tecla
	MOV	[tecla_continuo], R0	; informa quem estiver bloqueado neste LOCK que uma tecla está a ser carregada
							; (o valor escrito é o número da coluna da tecla no teclado)
    MOVB [R2], R1			; escrever no periférico de saída (linhas)
    MOVB R0, [R3]			; ler do periférico de entrada (colunas)
	AND R0, R5				; elimina bits para além dos bits 0-3
    CMP R0, 0				; há tecla premida?
    JNZ proxima_linhaa		; se ainda houver uma tecla premida, espera até não haver

	JMP	espera_tecla		; esta "rotina" nunca retorna porque nunca termina


; **********************************************************************
; Processo
;
; ENERGIA - Processo que deteta quando é para decrementar a energia
;
; **********************************************************************
PROCESS SP_inicial_energia
	
energia:						; processo que decrementa a energia
	DI							; desativa as interrupções (geral)
	YIELD				
	MOV	R0, [evento_int_energia]; le o valor da interrupção
	MOV R0, [ENERGIA]			; le o valor da energia
	CMP R0, 0					; se for zero, fim de jogo
	JZ parar					
	CALL desincrementa_energia	; decrementa a energia
	JMP energia					; sai
parar:
	CALL fim_de_jogo			; fim de jogo


; **********************************************************************
; Processo
;
; TUBARAO - Processo que desenha um tubarão e o move horizontalmente, com
;		 temporização marcada pela interrupção 0
; **********************************************************************

PROCESS SP_inicial_tubarao	
tubarao:					; processo que implementa o comportamento do tubarao
	DI						; desativa as interrupções (geral)
	; desenha o tubarao na sua posição inicial
    MOV R1, LINHA			; linha do tubarão
	MOV	R2, COLUNA			; coluna do tubarão
	MOV	R4, DEF_TUBARAO		; endereço da tabela que define o tubarao
	MOV R5, 8				; atraso do tubarão

ciclo_tubarao:
	CALL desenha_tubarao	; desenha o tubarao a partir da tabela
espera_movimento:

testa_mover_direita:
	MOV	R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R9, TECLA_E			; tecla para andar para a direita
	CMP	R3, R9				; é a tecla para andar para a direita?
	JZ move_direita			; se sim, move

testa_mover_esquerda:
	MOV	R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R9, TECLA_D			; tecla para andar para a esquerda
	CMP	R3, R9				; é a tecla para andar para a esquerda?
	JZ move_esquerda		; se sim, move
	JNZ espera_movimento	; se não é, ignora e continua à espera

move_direita:
	MOV	R7, +1				; vai deslocar para a direita
	JMP move	
move_esquerda:
	MOV	R7, -1				; vai deslocar para a esquerda
	JMP move
move:
	SUB R5, 1				; subtrai uma unidade ao atraso
	CMP R5, 0				; ve se é igual a 0
	JNZ ciclo_tubarao		; se nao é, nao move ainda
	MOV R5, 8				; se é, repoem o valor e vai mover
	CALL apaga_tubarao		; apaga o tubarao na sua posição corrente
	
	MOV	R6, [R4]			; obtém a largura do tubarao
	CALL testa_limites		; vê se chegou aos limites do ecrã e nesse caso inverte o sentido
	ADD	R2, R7				; para desenhar objeto na coluna seguinte (direita ou esquerda)
	MOV[posicao_tubarao], R1 ; guarda a posicao da linha do tubarão
	MOV[posicao_tubarao+2], R2 ; guarda a posicao da coluna do tubarão
	JMP	ciclo_tubarao



; **********************************************************************
; Processo
;
; MISSIL - Processo que desenha um um missil, e o movimento horizontalmente
; 			temporizado com a interrupção 1
; **********************************************************************
PROCESS SP_inicial_missil

missil:
	; desenha o missil na sua posição inicial
espera_tecla_disparar:
	MOV	R3, [tecla_carregada]	; lê o LOCK e bloqueia até o teclado escrever nele novamente
	MOV R9,TECLA_C				; tecla para disparar o missil
	
	MOV R2,[posicao_tubarao+2]	; posição do tubarão(coluna)
	ADD R2,2					
	MOV R1,[posicao_tubarao]	; posição do tubarão (linha)
	SUB R1, 1					; linha do tubarao
	MOV	R4, DEF_MISSIL			; endereço da tabela que define o missil
	
	CMP	R3, R9					; é a coluna para disparar o missil?
		
	JZ ciclo_missil_energia		; se for, vai remover o custo de energia do missil	
	JMP espera_tecla_disparar	; se nao for, sai


ciclo_missil_energia:
	MOV R10, ENERGIA_MISSIL_VALOR	; valor a decrementar
	MOV R11, [ENERGIA]			; leitura do valora atual da energia
	SUB R11, R10				; subtrai o valor a decrementar
	MOV [ENERGIA], R11			; escreve o novo valor da energia
	
ciclo_missil:
	CALL desenha_MISSIL			; desenha o missil a partir da tabela

	MOV	R3, [missil_anda]		; LOCK para mover o missil

Testa_top:						; testa o limite maximo superior do missil
	MOV R6,LIMITE_MISSIL		; linha maxima do missil
	CMP R1,R6					; ve se esta no limite
	JNZ sobe_missil				; se nao estiver no limite, sobre
	CALL apaga_MISSIL			; se estiver, apaga o missil
	MOV R1, FORA_DO_ECRA		; tira o missil (linhas)
	MOV R2, FORA_DO_ECRA		; tira o missil (colunas)
	MOV[posicao_missil], R1		; guarda o valor da linha do missil
	MOV[posicao_missil+2], R2	; guarda o valor da coluna do missil
	JMP missil					; repete

sobe_missil:	
	CALL apaga_MISSIL			; apaga o missil na sua posição corrente
	MOV	R6, [R4]				; obtém a largura do missil
	SUB	R1, 1					; para desenhar objeto na linha seguinte
	MOV[posicao_missil], R1		; guarda a posicão (linha) do missil
	MOV[posicao_missil+2], R2	; guarda a posição (coluna) do missil
	JMP	 ciclo_missil		

desenha_MISSIL:
	PUSH R3
	MOV R3, 0FB00H 				; cor do missil
	CALL escreve_pixel
	POP R3
	RET

apaga_MISSIL:
	PUSH R3
	MOV R3, 0 					; cor do missil
	CALL escreve_pixel
	POP R3
	RET

; **********************************************************************
; Processo
;
; OBJETO - Processo que desenha um um objeto (peixe ou mina), e o movimento verticalmente
; 			temporizado com a interrupção 0
; **********************************************************************
PROCESS SP_inicial_objeto0
objeto:
mina:
	CALL rand					; obtem um numero random (0-9)
	CMP R4, 3					; ve se o random é 0, 1 ou 2
	JLT peixe					; se for, vai criar um peixe, se nao uma mina
	MOV R10, R11				; cópia do nº de instância do processo
	SHL R10, 1					; multiplica por 2 porque as tabelas são de WORDS
	MOV R9, objetosSP_tab		; tabela com os SPs iniciais das várias instâncias deste processo
	MOV	SP, [R9+R10]			; re-inicializa SP deste processo, de acordo com o nº de instância
	MOV R9, coluna_objetos		; colunas iniciais dos objetos
	CALL rand					; obtem um numero random
	MOV R7, 8					
	MUL R4, R7					; multiplica o numero por 8
	MOV [R9+R10], R4			; NAOSEI
	MOV R2, [R9+R10]			; linha do tubarao
	MOV R9,linhas_objetos			; linhas em que cada mina está
	
	MOV	R1, [R9+R10]			; NAOSEI
	MOV R4, [TABELA_MINA]		; tamanho da mina default
	MOV R7, 1					; NAOSEI
	
	MOV R11,0					; NAOSEI

ciclo_mina:
	CALL desenha_objeto			; desenha a mina
	MOV  R9, objeto_anda			; LOCK para ver se é para deslocar a mina
	MOV  R3, [R9]				; lê o LOCK desta instância (bloqueia até a rotina de interrupção
								; respetiva escrever neste LOCK)
								; Quando bloqueia, passa o controlo para outro processo
								; Como não há valor a transmitir, o registo pode ser um qualquer		

testa_descer:					; verifica se pode descer a mina
	MOV R9, MAX_LINHA			; linha maxima
	CMP R1, R9					; ve se esta na linha maxima
	JZ mina						; se estiver, nao desce, volta ao inicio
	CMP R11, 2					; NAOSEI
	JGE	mina_evolui				; verifica qual desenho da minha é para desenhar


mina_evolui:
	MOV R5,LINHA_OBJETO1		; até desta linha, desenha a mina1
	CMP R1, R5
	JLT	mina1					; desenha a mina1´
	MOV R5, LINHA_OBJETO2		; até desta linha, desenha a mina2
	CMP R1, R5
	JLT	mina2					; desenha a mina2
	MOV R5, LINHA_OBJETO3		; até desta linha, desenha a mina3
	CMP R1, R5
	JLT	mina3					; desenha a mina3
	MOV R5, LINHA_OBJETO4		; até desta linha, desenha a mina4
	CMP R1, R5
	JLT	mina4					; desenha a mina4
	JMP	mina5					; desenha a mina5

mina1:
	MOV R4, [TABELA_MINA+2]		; endereço da tabela que define a mina1
	JMP desce_mina				; vai descer

mina2:
	MOV R4, [TABELA_MINA+4]		; endereço da tabela que define a mina2
	JMP desce_mina				; vai descer

mina3:
	MOV R4, [TABELA_MINA+6]		; endereço da tabela que define a mina3
	JMP desce_mina				; vai descer

mina4:
	MOV R4, [TABELA_MINA+8]		; endereço da tabela que define a mina4
	JMP desce_mina				; vai descer

mina5:
	JMP desce_mina				; vai descer



desce_mina:						; desce a mina
	CALL apaga_objeto				; apaga a mina
	ADD R1, 1					; NAOSEI

testa_colisao_missil:			; testa a colisao de uma mina com um missil
	MOV R5,[posicao_missil]		; obtem posição (linha do missil)
	MOV R6,[posicao_missil+2]	; obtem posição (coluna do missil)
	MOV R9, 0					; NAOSEI
	MOV R9, R1					; NAOSEI		
	ADD R9, 5					; NAOSEI
	CMP R9, R5					; NAOSEI
	JLT verifica_colisao_tubarao; NAOSEI

	CMP R1, R5					; NAOSEI
	JGT verifica_colisao_tubarao; NAOSEI

	CMP R6, R2					; NAOSEI
	JLT verifica_colisao_tubarao; NAOSEI

	MOV R10, R2					; NAOSEI
	ADD R10, 5					; NAOSEI
	CMP R6, R10					; NAOSEI
	JGT verifica_colisao_tubarao; NAOSEI
	; houve colisão
	MOV R9, 0					; seleciona o som 0
	MOV [TOCA_SOM], R9			; toca o som 
	CALL incrementa_energia		; incrementa a energia 
	; animação da explosão
	MOV R4, [TABELA_EXPLOSAO]	; tabela que define a explosão
	MOV[posicao_explosao], R1	; define a linha da posição da explosão
	MOV [posicao_explosao+2], R2; define a coluna da posição da explosão
	CALL desenha_objeto			; desenha a explosão
	MOV R10, EXPLOSAO_TEMPO		; tempo de explosão

tempo_mina_explosao:			; tempo de duração da explosão
	YIELD
	SUB R10, 1					; subtrai uma unidade
	JNZ tempo_mina_explosao					; repete ate ser zero
	CALL apaga_objeto				; vai apagar a mina
	JMP mina
	
	

verifica_colisao_tubarao:		; verifica se a mina colidiu com um tubarão
	MOV R5, [posicao_tubarao]	; lê a posição (linha) do tubarão
	MOV R6, [posicao_tubarao+2] ; lê a posiçaõ (coluna) do tubarão
	MOV R9, R1					; NAOSEI esta toda, comenta pls
	ADD R9, 5
	CMP R9, R5
	JLT ciclo_mina

	MOV R9, R5					; NAOSEI esta toda, comenta pls
	ADD R5, 5
	CMP R1, R5
	JGT ciclo_mina

	MOV R8, R6					; NAOSEI esta toda, comenta pls
	ADD R6, 5
	CMP R6, R2
	JLT ciclo_mina				; NAOSEI esta toda, comenta pls

	MOV R10, R2
	ADD R10, 5
	CMP R8, R10
	JGT ciclo_mina

	JMP fim_de_jogo				; se houve colisão, perde o jogo


peixe:						; instância de um peixe
	MOV R10, R11			; cópia do nº de instância do processo
	SHL R10, 1				; multiplica por 2 porque as tabelas são de WORDS
	MOV R9, objetosSP_tab	; tabela com os SPs iniciais das várias instâncias deste processo
	MOV	SP, [R9+R10]		; re-inicializa SP deste processo, de acordo com o nº de instância
	MOV R9, coluna_objetos	; colunas iniciais dos objetos
	CALL rand				; obtem um número random
	MOV R7,8				; NAOSEI
	MUL R4,R7				; NAOSEI
	MOV [R9+R10], R4		; NAOSEI
	MOV R2, [R9+R10]		; linha do tubarao
	MOV R9, linhas_objetos	; linhas em que cada objeto está
	
	MOV	R1, [R9+R10]		; NAOSEI
	MOV R4, [TABELA_PEIXE]	; tamanho do peixe default
	MOV R7, 1				; NAOSEI
	MOV R11,0				; NAOSEI

ciclo_peixe:
	CALL desenha_objeto		; desenha o peixe 
	MOV R9, objeto_anda	; avisa que é para tentar mover o peixe
	MOV R3, [R9]			; lê o LOCK desta instância (bloqueia até a rotina de interrupção
							; respetiva escrever neste LOCK)
							; Quando bloqueia, passa o controlo para outro processo
							; Como não há valor a transmitir, o registo pode ser um qualquer		

testa_descer_peixe:			; testa tentar descer o peixe
	MOV R9,MAX_LINHA		; linha maxima onde o peixe pode estar
	CMP R1,R9				; ve se está na linha maxima
	JZ peixe				; se tiver, sai

	CMP R11,2				; NAOSEI
	JGE	peixe_evolui		; vai ver qual tamanho de peixe é para desenhar


peixe_evolui:
	MOV R5, LINHA_OBJETO1	; linha até a qual se desenha o peixe1
	CMP R1, R5
	JLT	peixe1				; desenha o peixe1
	MOV R5, LINHA_OBJETO2	; linha até a qual se desenha o peixe2
	CMP R1, R5
	JLT	peixe2				; desenha o peixe2
	MOV R5, LINHA_OBJETO3	; linha até a qual se desenha o peixe3
	CMP R1, R5
	JLT	peixe3				; desenha o peixe3
	MOV R5, LINHA_OBJETO4	; linha até a qual se desenha o peixe4
	CMP R1, R5
	JLT	peixe4				; desenha o peixe4
	JMP	peixe5				; desenha o peixe5

peixe1:
	MOV R4, [TABELA_PEIXE+2]; endereço da tabela que define o peixe1
	JMP desce_peixe			; vai descer o peixe

peixe2:
	MOV R4, [TABELA_PEIXE+4]; endereço da tabela que define o peixe2
	JMP desce_peixe			; vai descer o peixe

peixe3:
	MOV R4, [TABELA_PEIXE+6]; endereço da tabela que define o peixe3
	JMP desce_peixe			; vai descer o peixe

peixe4:
	MOV R4, [TABELA_PEIXE+8]; endereço da tabela que define o peixe4
	JMP desce_peixe			; vai descer o peixe

peixe5:						; tamanho default, peixe5
	JMP desce_peixe			; vai descer o peixe

desce_peixe:				; desce o peixe por uma linha
	CALL apaga_objeto		; apaga o peixe
	ADD R1, 1				; NAOSEI

testa_colisao_missil_peixe:
	MOV R5,[posicao_missil]		; obtem a posição (linha) do missil
	MOV R6,[posicao_missil+2]	; obtem a posição (coluna) do missil
	MOV R9,0				; NAOSEI, completa até ao fim deste pedaço pls
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
	MOV R9,0			; seleciona o som 0
	MOV [TOCA_SOM],R9	; toca o som
	; animação da explosão
	MOV R4, [TABELA_EXPLOSAO]	; tabela que define a explosão
	MOV[posicao_explosao], R1	; define a posição (linha) da explosão
	MOV [posicao_explosao+2], R2; define a posição (coluna) da explosão
	CALL desenha_objeto			; desenha a explosão
	MOV R10, EXPLOSAO_TEMPO		; duração da explosão
tempo_peixe_explosao:	
	YIELD
	SUB R10, 1					; subtrai uma unidade
	JNZ tempo_peixe_explosao	; se nao for zero, repete
	CALL apaga_objeto			; apaga a explosão
	JMP objeto
	
verifica_colisao_tubarao_peixe: ; verifica a colisão do peixe com o tubarão
	MOV R5, [posicao_tubarao]	; obtem a posição do tubarão (linha)
	MOV R6, [posicao_tubarao+2]	; obtem a posição do tubarão (coluna)
	MOV R9, R1					; NAOSEI, completa ate ao fim pls
	ADD R9, 5
	CMP R9, R5
	JLT ciclo_peixe

	MOV R9, R5
	ADD R5, 5
	CMP R1, R5
	JGT ciclo_peixe

	MOV R8, R6
	ADD R6, 5
	CMP R6, R2
	JLT ciclo_peixe

	MOV R10, R2
	ADD R10, 5
	CMP R8, R10
	JGT ciclo_peixe

	CALL incrementa_energia_peixe	; incrementa a energia
	JMP mina

; **********************************************************************
; * ROTINAS                                                            
; **********************************************************************

; **********************************************************************
; DESENHA_tubarao - Desenha um tubarao na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o tubarao
;
; **********************************************************************
desenha_tubarao:
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R5
	PUSH R6
	PUSH R7
	PUSH R8
	MOV R8, R2
	MOV R7, [R4]				; obtém a largura do tubarao
	MOV R5, R7
	ADD	R4, 2			
	MOV	R6, [R4]				; obtém a altura do tubarao	
	ADD	R4, 2					; endereço da cor do 1º pixel (2 porque a largura é uma word)
desenha_pixels:       			; desenha os pixels do tubarao a partir da tabela
	MOV	R3, [R4]				; obtém a cor do próximo pixel do tubarao
	CALL escreve_pixel			; escreve cada pixel do tubarao
	ADD	R4, 2					; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD R2, 1                   ; próxima coluna
    SUB R5, 1					; menos uma coluna para tratar
    JNZ desenha_pixels          ; continua até percorrer toda a largura do objeto
	;troca de linha
	MOV R2, R8 
	MOV R5, R7
	ADD R1, 1
	SUB R6, 1
	JNZ desenha_pixels
	
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
; APAGA_tubarao - Apaga um tubarao na linha e coluna indicadas
;			 	 com a forma definida na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o tubarao
;
; **********************************************************************
apaga_tubarao:
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R5
	PUSH R6
	PUSH R7
	PUSH R8
	MOV R8, R2
	MOV	R7, [R4]				; obtém a largura do tubarao
	MOV R5, R7
	ADD	R4, 2			
	MOV	R6, [R4]				; obtém a altura do tubarao	
	ADD	R4, 2					; endereço da cor do 1º pixel (2 porque a largura é uma word)
apaga_pixels:       			; desenha os pixels do tubarao a partir da tabela
	MOV	R3, 0					; obtém a cor do próximo pixel do tubarao
	CALL escreve_pixel			; escreve cada pixel do tubarao
	ADD	R4, 2					; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD R2, 1                   ; próxima coluna
    SUB R5, 1					; menos uma coluna para tratar
    JNZ apaga_pixels            ; continua até percorrer toda a largura do objeto
	;troca de linha
	MOV R2,R8
	MOV R5,R7
	ADD R1,1
	SUB R6, 1
	JNZ apaga_pixels
	POP R8 
	POP R7
	POP R6
	POP	R5
	POP	R4
	POP R3
	POP	R2
	POP R1
	RET

;====================================================================================================
; **********************************************************************
; desenha_objeto - Desenha um mina na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o mina
;
; **********************************************************************
desenha_objeto:
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R5
	PUSH R6
	PUSH R7
	PUSH R8
	MOV R8, R2
	MOV R7, [R4]				; obtém a largura do tubarao
	MOV R5, 5
	ADD	R4, 2			
	MOV	R6, 6					; obtém a altura do tubarao	
	ADD	R4, 2					; endereço da cor do 1º pixel (2 porque a largura é uma word)
	JMP desenha_pixels
	RET

; **********************************************************************
; apaga_objeto - Apaga um mina na linha e coluna indicadas
;			  com a forma definida na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o mina
;
; **********************************************************************
apaga_objeto:
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R5
	PUSH R6
	PUSH R7
	PUSH R8
	MOV R8, R2
	MOV	R7, [R4]				; obtém a largura do tubarao
	MOV R5, 5
	ADD	R4, 2			
	MOV	R6, [R4]				; obtém a altura do tubarao	
	ADD	R4, 5					; endereço da cor do 1º pixel (2 porque a largura é uma word)
	JMP apaga_pixels
	RET




escreve_pixel:
	MOV  [DEFINE_LINHA], R1		; seleciona a linha
	MOV  [DEFINE_COLUNA], R2	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3		; altera a cor do pixel na linha e coluna já selecionadas
	RET


; **********************************************************************
; TESTA_LIMITES - Testa se o tubarao chegou aos limites do ecrã e nesse caso
;			   inverte o sentido de movimento
; Argumentos:	R2 - coluna em que o objeto está
;			R6 - largura do tubarao
;			R7 - sentido de movimento do tubarao (valor a somar à coluna
;				em cada movimento: +1 para a direita, -1 para a esquerda)
;
; Retorna: 	R7 - novo sentido de movimento (pode ser o mesmo)	
; **********************************************************************
testa_limites:
	PUSH R5
	PUSH R6
testa_limite_esquerdo:			; vê se o tubarao chegou ao limite esquerdo
	MOV	R5, MIN_COLUNA
	CMP	R2, R5
	JGT	testa_limite_direito
	CMP	R7, 0					; passa a deslocar-se para a direita
	JGE	sai_testa_limites
	JMP	impede_movimento		; entre limites. Mantém o valor do R7
testa_limite_direito:			; vê se o tubarao chegou ao limite direito
	ADD	R6, R2					; posição a seguir ao extremo direito do tubarao
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
; fim_de_jogo - termina o jogo e muda o ecra
; **********************************************************************
fim_de_jogo:
    MOV  [APAGA_ECRÃ], R1	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	 R1, 1				; cenário de fundo número 1
    MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
	ciclo_fim_de_jogo:		; fim de jogo
	JMP ciclo_fim_de_jogo
	RET

; **********************************************************************
; Rand - aleatorio
; Retorna:	R4 - um número aleatório entre 0  e 9
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
; **********************************************************************
; incrementa_energia - aumenta a energia com o valor normal
; **********************************************************************
incrementa_energia:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV R0, ENERGIA_VALOR	; valor a incrementar
	MOV R1, [ENERGIA]		; leitura do valora atual da energia
	ADD R1, R0				; adiciona o valor a incrementar
	MOV R2, DECIMAL_100		; 100 em hexadecimal
	CMP R1, R2				; ve se a energia ficava mais que 100
	JGT max_100				; se sim, limite a 100
	MOV [ENERGIA], R1		; escreve o novo valor da energia

	PUSH R2
	POP R1
	POP R0
	RET

max_100:
	MOV [ENERGIA], R2		; mete energia a 100
	POP R2
	POP R1
	POP R0
	RET


; **********************************************************************
; incrementa_energia_peixe - aumenta a energia quando um peixe é comido
; **********************************************************************
incrementa_energia_peixe:
	PUSH R0
	PUSH R1
	PUSH R2

	MOV R0, ENERGIA_VALOR_XL; valor a incrementar
	MOV R1, [ENERGIA]		; leitura do valora atual da energia
	ADD R1, R0				; adiciona o valor a incrementar
	MOV R2, DECIMAL_100		; 100 em hexadecimal
	CMP R1, R2				; ve se a energia ficava mais que 100
	JGT max100				; se sim, limite a 100
	MOV [ENERGIA], R1		; escreve o novo valor da energia

	POP R2
	POP R1
	POP R0
	RET

max100:
	MOV [ENERGIA], R2		; mete energia a 100
	POP R2
	POP R1
	POP R0
	RET

; **********************************************************************
; desincrementa_energia - diminiu a energia com o valor normal
; **********************************************************************
desincrementa_energia:
	PUSH R0
	PUSH R1

	MOV R0, ENERGIA_VALOR	; valor a decrementar
	MOV R1, [ENERGIA]		; leitura do valora atual da energia
	SUB R1, R0				; subtrai o valor a decrementar
	MOV [ENERGIA], R1		; escreve o novo valor da energia

	POP R1
	POP R0
	RET

; **********************************************************************
; calcula_output - calcula qual o numero da tecla do tecla que foi premida
; Argumentos: R[NAOSEI] - linha da tecla premida
;			  R[NAOSEI] - linha da coluna premida
; Retorna: R0 - numero da tecla
; **********************************************************************
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
    SHR R9,1           ;NAOSEI
    ADD R5,R8          ;NAOSEI
    CMP R9,0           ;NAOSEI
    JNZ calcula_linha  ;NAOSEI
    SUB R5,R8          ;NAOSEI
     
calcula_coluna:        ; Conta qual a coluna, a partir da 0
    SHR R11,1          ;NAOSEI esta rotina a serio nunca a percebi lol
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

; ***********************************************************************
; * Interrupts
; ***********************************************************************
interrupt_energia:
	PUSH R1
	MOV [evento_int_energia], R1		; avisa que é para diminuir a energia
	POP	R1
	RFE
	
movimenta_objeto:
	PUSH R1
	MOV [objeto_anda], R1		; avisa que é para mover o objeto
	POP	R1
	RFE

movimenta_missil:
	PUSH R1
	MOV [missil_anda], R1		; avisa que é para mover a missil
	POP	R1
	RFE
