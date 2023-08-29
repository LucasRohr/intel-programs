;
;====================================================================
; Trabalho Intel 2023/1
;====================================================================
;
	.model small
	.stack

    ; ---------------------------------------------------------------

    CR	equ	13
    LF	equ	10

	.data ; Segmento de dados para declaracao de variáveis, EQUs e mensagens

    entradaLinhaComando db 100 dup (?) ; reserva espaco para entrada da linha de comando

    nomeArquivoEntrada db 50 dup (?)
    nomeArquivoSaida db 50 dup (?)
    tamanhoGrupoString db 5 dup (?)
    tamanhoGrupo dw 0
    escolhaATGC dw 5 dup (?)

    opcaoF db "-f ", 0

    opcaoO db "-o ", 0

    opcaoN db "-n ", 0

    opcaoA db "-a", 0
    opcaoT db "-t", 0
    opcaoG db "-g", 0
    opcaoC db "-c", 0
    opcaoMais db "-+", 0

    opcaoExtraA equ 'a'
    opcaoExtraT equ 't'
    opcaoExtraG equ 'g'
    opcaoExtraC equ 'c'
    opcaoExtraMais equ '+'

    msgErroOpcaoF db CR, "Erro: Nome do arquivo de entrada nao informado", CR, 0
    msgErroOpcaoN db CR, "Erro: Tamanho dos grupos de bases nitrogenadas nao informado", CR, 0
    msgErroOpcaoATGC db CR, "Erro: Opcao de saída ATGC+ nao informada", CR, 0
    msgErroOpcaoATGCInvalida db CR, "Erro: Opcao de saída ATGC+ invalida", CR, 0
    msgErroAbrirArquivo db CR, "Erro de leitura: o arquivo de entrada informado nao existe", CR, 0

    nomePadraoArquivoSaida	db	"a.out", 0
    temErroLinhaDeComando db 0

    fileBuffer	db	10000 dup (?)	; Buffer de leitura do arquivo
    fileHandle	dw	0
    tamanhoFile dw 0

    ; ---------------------------------------------------------------

    .code ; segmento de codigo
	.startup

    call get_linha_comando ; le a linha de comando

    call processa_opcao_f ; procura e armazena nome do arquivo de entrada ou gera erro
    call processa_opcao_o ; procura e armazena nome do arquivo de  saida ou usa o nome padrao
    call processa_opcao_n ; procura e armazena o tamanho dos grupos de bases ou gera erro
    call processa_opcao_ATGC ; procura e armazena a opcao ATGC+ ou gera erro

    cmp temErroLinhaDeComando, 1
    je fim_programa_principal ; se houve erro na entrada da linha de comando, finaliza o programa

    call processa_arquivo_entrada

    fim_programa_principal:

        .exit ; sai da execucao do programa principal



; ===== Funcoes principais ======

; Funcao para processar o nome do arquivo de entrada na linha de comando lida

processa_opcao_f	proc	near

    lea di, entradaLinhaComando ; Inicializa registradores
    mov cx, 100
    cld

    mov AL, opcaoF
    repne scasb ; procura '-f '

    jne erro_sem_opcao_f

    ; caso tiver opcao, guarda o nome do arquivo

    mov si, di ; SI recebe o endereco atual na string de entrada
    lea di, nomeArquivoEntrada ; DI recebe o endereco do nome do arquivo a ser salvo

    mov	ax, ds ; Ajusta ES=DS para poder usar o MOVSB
	mov	es, ax

    repe movsb ; copia sting

    mov	byte ptr es:[di], 0 ; Coloca marca de fim de string

    ret ; retorna

    erro_sem_opcao_f:
        lea	bx, msgErroOpcaoF
		call printf_s

        mov temErroLinhaDeComando, 1

        ret

processa_opcao_f	endp


; Funcao para processar o nome do arquivo de saída na linha de comando lida

processa_opcao_o	proc	near

    lea di, entradaLinhaComando ; Inicializa registradores
    mov cx, 100
    cld

    mov AL, opcaoO
    repne scasb ; procura '-o '

    jne fim_sem_opcao_o

    ; caso tiver opcao, guarda o nome do arquivo de saída

    mov si, di ; SI recebe o endereco atual na string de entrada
    lea di, nomeArquivoSaida ; DI recebe o endereco do nome do arquivo a ser salvo

    mov	ax,ds ; Ajusta ES=DS para poder usar o MOVSB
	mov	es,ax

    repe movsb ; move a string de entrada até encontrar 0

    mov	byte ptr es:[di], 0 ; Coloca marca de fim de string

    ret ; retorna

    fim_sem_opcao_o:
        lea si, nomePadraoArquivoSaida ; SI recebe o endereco do nome padrao
        lea di, nomeArquivoSaida ; DI recebe o endereco do nome do arquivo a ser salvo
        mov cx, 6 ; tamanho do nome padrao

        rep movsb

        ret ; retorna

processa_opcao_o	endp


; Funcao para processar o tamanho dos grupos de bases na linha de comando lida

processa_opcao_n	proc	near

    lea di, entradaLinhaComando ; Inicializa registradores
    mov cx, 100
    cld

    mov AL, opcaoN
    repne scasb ; procura '-n '

    jne erro_sem_opcao_n

    ; caso tiver opcao, guarda o tamanho dos grupos

    mov si, di ; SI recebe o endereco atual na string de entrada
    lea di, tamanhoGrupoString ; DI recebe o endereco do nome do arquivo a ser salvo

    mov	ax,ds ; Ajusta ES=DS para poder usar o MOVSB
	mov	es,ax

    repe movsb ; move a string de entrada até encontrar 0

    mov	byte ptr es:[di], 0 ; Coloca marca de fim de string

    lea bx, tamanhoGrupoString
	call atoi ; ax = atoi(tamanhoGrupoString)

    mov tamanhoGrupo, ax ; salva tamanho do grupo como valor hexa

    ret ; retorna

    erro_sem_opcao_n:
        lea	bx, msgErroOpcaoN
		call printf_s

        mov temErroLinhaDeComando, 1

        ret

processa_opcao_n	endp


; Funcao para processar a opcao ATGC+ na linha de comando lida

processa_opcao_ATGC	proc	near

    lea di, entradaLinhaComando ; Inicializa registradores
    mov cx, 100
    cld

    mov AL, opcaoA
    repne scasb ; procura '-a'
    jne processa_opcao_t
    je processa_opcao_atgc_completa

    processa_opcao_t:

        lea di, entradaLinhaComando ; Inicializa registradores
        mov cx, 100
        cld

        mov AL, opcaoT
        repne scasb ; procura '-t'
        jne processa_opcao_g
        je processa_opcao_atgc_completa

    processa_opcao_g:

        lea di, entradaLinhaComando ; Inicializa registradores
        mov cx, 100
        cld

        mov AL, opcaoG
        repne scasb ; procura '-g'
        jne processa_opcao_c
        je processa_opcao_atgc_completa

    processa_opcao_c:

        lea di, entradaLinhaComando ; Inicializa registradores
        mov cx, 100
        cld

        mov AL, opcaoC
        repne scasb ; procura '-c'
        jne processa_opcao_mais
        je processa_opcao_atgc_completa

    processa_opcao_mais:

        lea di, entradaLinhaComando ; Inicializa registradores
        mov cx, 100
        cld

        mov AL, opcaoMais
        repne scasb ; procura '-+'
        jne erro_sem_opcao_atgc
        je processa_opcao_atgc_completa

    processa_opcao_atgc_completa:
        inc di ; comeca o loop do proximo char, pois tem o -
        mov bx, di

        mov	ax, escolhaATGC ; passar endereco
	    mov	es, ax

        mov ax, [bx]
        mov	escolhaATGC, ax

        loop_processa_atgc_completa:
            cmp byte ptr[bx], ' '
            je fim_opcao_atgc

            cmp byte ptr[bx], opcaoExtraA
            je salva_opcao_extra_atgc

            cmp byte ptr[bx], opcaoExtraT
            je salva_opcao_extra_atgc

            cmp byte ptr[bx], opcaoExtraG
            je salva_opcao_extra_atgc

            cmp byte ptr[bx], opcaoExtraC
            je salva_opcao_extra_atgc

            cmp byte ptr[bx], opcaoExtraMais
            je salva_opcao_extra_atgc

            jne fim_opcao_atgc_invalida

            salva_opcao_extra_atgc:
                mov ax, [bx]
                mov es:[di], ax
                inc bx
                inc di

                jmp loop_processa_atgc_completa

        fim_opcao_atgc:
            mov	byte ptr es:[di], 0 ; Coloca marca de fim de string

            ret

    fim_opcao_atgc_invalida:

        lea	bx, msgErroOpcaoATGCInvalida
		call printf_s

        mov temErroLinhaDeComando, 1

        ret

    erro_sem_opcao_atgc:
        lea	bx, msgErroOpcaoATGC
		call printf_s

        mov temErroLinhaDeComando, 1

        ret

processa_opcao_ATGC	endp


; Funcao para processar o arquivo de entrada com base no que foi fornecido na linha de comando

processa_arquivo_entrada	proc	near

    ; abre arquivo de entrada
    mov	al, 0
	lea	dx, nomeArquivoEntrada
	mov	ah, 3dh
	int	21h

    ; se nao houve erro para abrir, continua
	jnc	continua_processa_arquivo_entrada

    ; se houve erro, printa que o arquivo nao existe e encerra
	lea	bx, msgErroAbrirArquivo
	call printf_s
	mov	al, 1
	jmp	final_processa_arquivo_entrada

    continua_processa_arquivo_entrada:


    final_processa_arquivo_entrada:
        .exit

processa_arquivo_entrada	endp


; ========== Funcoes default de uso geral =============

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

    lea di, entradaLinhaComando ; inicializa o ponteiro de destino

    rep movsb

    pop es ; retorna as informações dos registradores de segmentos
    pop ds

get_linha_comando	endp


; Funcao para printar mensagem em tela

printf_s	proc	near

;	While (*s!='\0') {
	mov	dl,[bx]
	cmp	dl,0
	je	ps_1

;		putchar(*s)
	push bx
	mov	ah,2
	int	21H
	pop	bx

;		++s;
	inc	bx
		
;	}
	jmp	printf_s
		
ps_1:
	ret
	
printf_s	endp



; Funcao para converter string em numero inteiro de 16bits

atoi	proc near

		; A = 0;
		mov	ax,0
		
atoi_2:
		; while (*S!='\0') {
		cmp	byte ptr[bx], 0
		jz	atoi_1

		; 	A = 10 * A
		mov	cx,10
		mul	cx

		; 	A = A + *S
		mov	ch,0
		mov	cl,[bx]
		add	ax,cx

		; 	A = A - '0'
		sub	ax,'0'

		; 	++S
		inc	bx
		
		;}
		jmp	atoi_2

atoi_1:
		; return
		ret

atoi	endp


; =====================================================


;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------