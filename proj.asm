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
; * contínua, enquanto se carrega na tecla), até atingir o limite do ecrã; 
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
; * número qualquer para dígitos em decimal. 
; **********************************************************************

; **********************************************************************
; * Constantes
; **********************************************************************
DISPLAYS   EQU 0A000H  ; endereço dos displays de 7 segmentos (periférico POUT-1)
TEC_LIN    EQU 0C000H  ; endereço das linhas do teclado (periférico POUT-2)
TEC_COL    EQU 0E000H  ; endereço das colunas do teclado (periférico PIN)
LINHA      EQU 8      ; linha a testar (4º linha, 1000b)
MASCARA    EQU 00FH     ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

; **********************************************************************
; * Código
; **********************************************************************
PLACE      0
inicio:		
; inicializações
    MOV  R2, TEC_LIN   ; endereço do periférico das linhas
    MOV  R3, TEC_COL   ; endereço do periférico das colunas
    MOV  R4, DISPLAYS  ; endereço do periférico dos displays
    MOV  R5, MASCARA   ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

; corpo principal do programa
ciclo:
    MOV  R1, LINHA     ; testa linha

espera_tecla:          ; neste ciclo espera-se até uma tecla ser premida
    MOVB [R2], R1      ; escrever no periférico de saáda (linhas)
    MOVB R0, [R3]      ; ler do periférico de entrada (colunas)
    AND  R0, R5        ; elimina bits para além dos bits 0-3
    CMP  R0, 0         ; há tecla premida ?
    JNZ  ha            ; Se há teclado premida, continua para "ha"
    SHR  R1,1          ; Testa a proxima colina (da 4º linha para a 1º linha)
    JZ   ciclo         ; Se todas as linhas foram testadas, repete o ciclo
    JMP  espera_tecla  ; se nenhuma tecla premida, repete
    
ha:    

calcula_output:
    MOV  R9, R1        ; Numero da linha
    MOV  R11, R0       ; Numero da coluna
    MOV R6,0           ; 
    MOV R7,0           ; 
    MOV R8,1           ; 

calcula_linha:         ;
    SHR R9,1           ;
    ADD R6,R8          ; 
    CMP R9,0           ;
    JNZ calcula_linha  ;
    SUB R6,R8          ;
     
calcula_coluna:        ;
    SHR R11,1          ;
    ADD R7,R8          ;
    CMP R11,0          ;
    JNZ calcula_coluna ;
    SUB R7,R8          ;
    MOV R8,4           ;
    MUL R6, R8         ;
    ADD R6,R7          ;

    MOVB [R4], R6      ; escreve linha + coluna nos displays
    


ha_tecla:              ; neste ciclo espera-se até NENHUMA tecla estar premida
    MOVB [R2], R1      ; escrever no periférico de saída (linhas)
    MOVB R0, [R3]      ; ler do periférico de entrada (colunas)
    AND  R0, R5        ; elimina bits para além dos bits 0-3
    CMP  R0, 0         ; há tecla premida?
    JNZ  ha_tecla      ; se ainda houver uma tecla premida, espera até não haver
    JMP  ciclo         ; repete ciclo

