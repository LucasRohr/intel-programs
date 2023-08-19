;
;====================================================================
; Trabalho Intel 2023/1
;====================================================================
;
	.model small
	.stack

    ; ---------------------------------------------------------------

	.data ; Segmento de dados para declaracao de variáveis, EQUs e mensagens

    entradaLinhaComando db 100 dup (?) ; reserva espaco para entrada da linha de comando
    nomeArquivoEntrada db 50 dup (?)
    nomeArquivoSaida db 50 dup (?)
    tamanhoGrupo db 0
    opcaoATGC db 5 dup (?)

    opcaoF db "-f", 0
    opcaoO db "-o", 0
    opcaoN db "-n", 0
    opcaoF db "-f", 0

    opcaoA db "-a", 0
    opcaoT db "-t", 0
    opcaoG db "-g", 0
    opcaoC db "-c", 0
    opcaoMais db "-+", 0

    opcaoExtraA db 'a'
    opcaoExtraT db 't'
    opcaoExtraG db 'g'
    opcaoExtraC db 'c'
    opcaoExtraMais db '+'

    NomePadraoArquivoSaida	db	"a.out", 0

    ; ---------------------------------------------------------------

    .code ; segmento de codigo
	.startup

    call get_linha_comando ; le a linha de comando

    call processa_opcao_f

    .exit ; sai da execucao do programa principal


; Funcao get_linha_comando para obter o que foi digitado pelo usuario
; na linha de comando e salvo em memoria essa string

get_linha_comando	proc	near

	push ds ; salva as informações de segmentos na stack
    push es

    mov ax, ds ; troca DS <-> ES, para poder usa o MOVSB
    mov bx, es
    mov ds, bx
    mov es, ax

    mov si, 80h ; obtém o tamanho do string e coloca em CX
    mov ch, 0
    mov cl, [si]

    mov si, 81h ; inicializa o ponteiro de origem

    lea di, VAR ; inicializa o ponteiro de destino

    rep movsb

    pop es ; retorna as informações dos registradores de segmentos
    pop ds

get_linha_comando	endp


; Funcao para processar a linha de comando lida

processa_opcao_f	proc	near

    lea di, entradaLinhaComando ; Inicializa registradores
    mov cx, 100
    cld

    mov AL, opcaoF
    repne scasb
    
    jne erro_sem_opcao_f

    ; caso tiver opcao, guarda o nome do arquivo

    lea di, nomeArquivoEntrada
    mov AL, ' '
    repne scasb

    erro_sem_opcao_f:

        .exit

processa_opcao_f	endp


;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------