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
    tamanhoEscolhaATGC dw 5 dup (?)

    opcaoF dw "-f"

    opcaoO dw "-o"

    opcaoN dw "-n"

    opcaoA dw "-a"
    opcaoT dw "-t"
    opcaoG dw "-g"
    opcaoC dw "-c"
    opcaoMais dw "-+"

    opcaoExtraA equ 'a'
    opcaoExtraT equ 't'
    opcaoExtraG equ 'g'
    opcaoExtraC equ 'c'
    opcaoExtraMais equ '+'

    opcaoASaida equ 'A'
    opcaoTSaida equ 'T'
    opcaoGSaida equ 'G'
    opcaoCSaida equ 'C'
    opcaoMaisSaida equ '+'
    pontoEVirgula equ 59

    msgErroOpcaoF db CR, "Erro: Nome do arquivo de entrada nao informado", CR, LF, 0
    msgErroOpcaoN db CR, "Erro: Tamanho dos grupos de bases nitrogenadas nao informado", CR, LF, 0
    msgErroOpcaoATGC db CR, "Erro: Opcao de saida ATGC+ nao informada", CR, LF, 0
    msgErroOpcaoATGCInvalida db CR, "Erro: Opcao de saida ATGC+ invalida", CR, LF, 0
    msgErroAbrirArquivo db CR, "Erro de abertura: o arquivo de entrada informado nao existe", CR, LF, 0
    msgErroLerArquivo db CR, "Erro de leitura: houve um problema ao ler o arquivo de entrada", CR, LF, 0

    msgErroAbrirArquivoSaida db CR, "Erro de abertura: o arquivo de saida informado nao existe", CR, LF, 0
    msgErroCriarArquivoSaida db CR, "Erro de criacao: erro ao criar arquivo de saida", CR, LF, 0
    msgErroEscreverArquivoSaida db "Erro de escrita: erro ao escrever no arquivo de saida", CR, LF, 0

    msgErroCaractereInvalidoArquivoEntrada db "Erro de leitura: o arquivo de entrada possui um caractere invalido (diferente de ATGC)", CR, LF, 0

    msgCRLF	db	CR, LF, 0

    nomePadraoArquivoSaida	db	"a.out", 0
    temErroLinhaDeComando db 0

    ; Variaveis para guardar dados do arquivo de entrada

    fileBuffer	db	10000 dup (?)	; Buffer de leitura do arquivo
    fileHandle	dw	0
    fileSaidaBuffer	db	10000 dup (?)	; Buffer de leitura do arquivo
    fileSaidaHandle	dw	0

    ; == infos para o resumo em tela ==
    totalBasesArquivo dw 0 ; total de bases nitrogenadas do arquivo, contador
    totalGruposArquivo dw 0 ; total de grupos no arquivo
    totalLinhasArquivo dw 0 ; total de linhas do arquivo (total de CRs + 1)

    totalBasesA db 0
    totalBasesT db 0
    totalBasesC db 0
    totalBasesG db 0
    totalBasesAT db 0
    totalBasesCG db 0

    stringLinhaDeSaida 	db	50 dup (?) ; linha a ser escrita no arquivo de saida a cada leitura de grupo na entrada
    tamanhoStringLinhaDeSaida dw 0

    stringHeaderSaida db 15 dup (?)
    tamanhoStringHeaderSaida dw 0

    ; ---------------------------------------------------------------

    .code ; segmento de codigo

    call get_linha_comando ; le a linha de comando

	.startup

    lea bx, entradaLinhaComando
    call printf_s

    lea bx, msgCRLF
    call printf_s

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

    mov ax, opcaoF
    repne scasb ; procura '-f'

    jne erro_sem_opcao_f

    ; caso tiver opcao, guarda o nome do arquivo

    inc di

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

    mov ax, opcaoO
    repne scasb ; procura '-o'

    jne fim_sem_opcao_o

    ; caso tiver opcao, guarda o nome do arquivo de saída

    inc di

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

    mov ax, opcaoN
    repne scasb ; procura '-n'

    jne erro_sem_opcao_n

    ; caso tiver opcao, guarda o tamanho dos grupos

    inc di

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

    mov ax, opcaoA
    repne scasb ; procura '-a'
    jne processa_opcao_t
    je processa_opcao_atgc_completa

    processa_opcao_t:

        lea di, entradaLinhaComando ; Inicializa registradores
        mov cx, 100
        cld

        mov ax, opcaoT
        repne scasb ; procura '-t'
        jne processa_opcao_g
        je processa_opcao_atgc_completa

    processa_opcao_g:

        lea di, entradaLinhaComando ; Inicializa registradores
        mov cx, 100
        cld

        mov ax, opcaoG
        repne scasb ; procura '-g'
        jne processa_opcao_c
        je processa_opcao_atgc_completa

    processa_opcao_c:

        lea di, entradaLinhaComando ; Inicializa registradores
        mov cx, 100
        cld

        mov ax, opcaoC
        repne scasb ; procura '-c'
        jne processa_opcao_mais
        je processa_opcao_atgc_completa

    processa_opcao_mais:

        lea di, entradaLinhaComando ; Inicializa registradores
        mov cx, 100
        cld

        mov ax, opcaoMais
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
                inc tamanhoEscolhaATGC

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
        ; fileHandle = ax
	    mov	fileHandle, ax

        ; criar arquivo de saida

        ;if (fcreate(FileNameDst)) {
        ;	fclose(FileHandleSrc);
        ;	printf("Erro na criacao do arquivo.\r\n")
        ;	exit(1)
        ;}
        ;FileHandleDst = BX
        lea		dx, nomeArquivoSaida
        call	fcreate
        mov		fileSaidaHandle, bx
        jnc		loop_processa_grupo ; se criou com sucesso, volta no loop para abrir ele

        mov		bx, fileHandle
        call	fclose ; se houve erro criando o arquivo de saida, fecha o de entrada e encerra
        lea		bx, msgErroCriarArquivoSaida
        call	printf_s

        ret

        printa_header_arquivo_saida:
            ; abrir o arquivo de output

            ; tenta abrir arquivo de saida
            mov	al, 0
            lea	dx, nomeArquivoSaida
            mov	ah, 3dh
            int	21h

            ; se nao houve erro para abrir, continua
            jnc	continua_printa_header_arquivo_saida

            ; se houve erro, printa que o arquivo nao existe e encerra
            lea	bx, msgErroAbrirArquivoSaida
            call printf_s
            mov	al, 1
            jmp	final_processa_arquivo_entrada

            continua_printa_header_arquivo_saida:

                lea bx, stringHeaderSaida

                lea di, escolhaATGC ; Inicializa registradores
                mov cx, tamanhoEscolhaATGC
                cld

                mov ax, opcaoExtraA
                repne scasb ; procura 'a'

                jne procura_t_printa_header_arquivo_saida

                ; caso tiver opcao, guarda ela

                mov di, bx
                mov es:[di], opcaoASaida ; bota A no header
                inc di ; proxima posicao da linha
                inc bx
                mov es:[di], pontoEVirgula ; bota ponto e virgula
                add tamanhoStringHeaderSaida, 2

                procura_t_printa_header_arquivo_saida:

                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov ax, opcaoExtraT
                    repne scasb ; procura 't'

                    jne procura_c_printa_header_arquivo_saida

                    ; caso tiver opcao, guarda ela

                    mov di, bx
                    mov es:[di], opcaoTSaida ; bota T no header
                    inc di ; proxima posicao da linha
                    inc bx
                    mov es:[di], pontoEVirgula ; bota ponto e virgula
                    add tamanhoStringHeaderSaida, 2

                procura_c_printa_header_arquivo_saida:

                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov ax, opcaoExtraC
                    repne scasb ; procura 'c'

                    jne procura_g_printa_header_arquivo_saida

                    ; caso tiver opcao, guarda ela

                    mov di, bx
                    mov es:[di], opcaoCSaida ; bota C no header
                    inc di ; proxima posicao da linha
                    inc bx
                    mov es:[di], pontoEVirgula ; bota ponto e virgula
                    add tamanhoStringHeaderSaida, 2

                procura_g_printa_header_arquivo_saida:

                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov ax, opcaoExtraG
                    repne scasb ; procura 'g'

                    jne procura_mais_printa_header_arquivo_saida

                    ; caso tiver opcao, guarda ela

                    mov di, bx
                    mov es:[di], opcaoGSaida ; bota G no header
                    inc di ; proxima posicao da linha
                    inc bx
                    mov es:[di], pontoEVirgula ; bota ponto e virgula
                    add tamanhoStringHeaderSaida, 2

                procura_mais_printa_header_arquivo_saida:

                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov ax, opcaoExtraMais
                    repne scasb ; procura '+'

                    jne printa_header

                    ; caso tiver opcao, guarda ela

                    mov di, bx
                    mov es:[di], opcaoASaida ; bota A no header
                    inc di ; proxima posicao da linha
                    mov es:[di], opcaoMaisSaida ; bota + no header
                    inc di ; proxima posicao da linha
                    mov es:[di], opcaoTSaida ; bota T no header
                    inc di ; proxima posicao da linha
                    mov es:[di], pontoEVirgula ; bota ; no header

                    inc di ; 
                    mov es:[di], opcaoCSaida ; bota C no header
                    inc di ; proxima posicao da linha
                    mov es:[di], opcaoMaisSaida ; bota + no header
                    inc di ; proxima posicao da linha
                    mov es:[di], opcaoGSaida ; bota G no header
                    inc di ; proxima posicao da linha
                    mov es:[di], CR ; bota CR no header
                    inc di ; proxima posicao da linha
                    mov es:[di], LF ; bota LF no header
                    inc di ; proxima posicao da linha
                    mov es:[di], 0 ; bota 0 como fim
                    add tamanhoStringHeaderSaida, 9 ; 7 + CR LF

            printa_header:
                ; escreve o header no arquivo de saida
                mov	ah, 40h
                mov	cx, tamanhoStringHeaderSaida
                mov		stringHeaderSaida, dl
                lea		dx, stringHeaderSaida
                int		21h

                jnc	loop_processa_grupo

                mov	bx, fileHandle
                call fclose ; se houve erro escrevendo no arquivo de saida, fecha o de entrada e encerra
                lea	bx, msgErroEscreverArquivoSaida
                call printf_s

                ret

        loop_processa_grupo:

            mov totalBasesA, 0
            mov totalBasesT, 0
            mov totalBasesC, 0
            mov totalBasesG, 0
            mov totalBasesAT, 0
            mov totalBasesCG, 0

            ;		if ( (ax=fread(ah=0x3f, bx=FileHandle, cx=1, dx=FileBuffer)) ) {
            ;			printf ("Erro na leitura do arquivo.\r\n");
            ;			fclose(bx=FileHandle)
            ;			exit(1);
            ;		}

            mov	bx, fileHandle
            mov	ah, 3fh
            mov	cx, tamanhoGrupo ; n caracteres a serem lidos
            lea	dx, fileBuffer
            int	21h

            jnc	contiua_loop_processa_grupo

            lea	bx, msgErroLerArquivo
            call printf_s
            mov	al,1
            jmp	final_processa_arquivo_entrada

            verifica_fim_loop_processa_grupo:

                ; Verifica se terminou o arquivo
                ;	if (ax==0) {
                ;		fclose(bx=FileHandle);
                ;		exit(0);
                ;	}
                cmp		ax,0
                jne		contiua_loop_processa_grupo
                mov		al,0
                jmp		final_processa_arquivo_entrada

            contiua_loop_processa_grupo:
                ; abrir o arquivo de output

                ; tenta abrir arquivo de saida
                mov	al, 0
                lea	dx, nomeArquivoSaida
                mov	ah, 3dh
                int	21h

                ; se nao houve erro para abrir, continua
                jnc	abriu_saida_loop_processa_grupo

                ; se houve erro, printa que o arquivo nao existe e encerra
                lea	bx, msgErroAbrirArquivoSaida
                call printf_s
                mov	al, 1
                jmp	final_processa_arquivo_entrada

            abriu_saida_loop_processa_grupo:

                ; depois disso preciso iterar pelo file buffer do grupo atual e processar o grupo
                ;   -> preciso primeiro abrir o arquivo de entrada e processar ele - Check
                ;   -> salvar totais para mostrar no resumo - Check
                ;   -> escrever dados do grupo no arquivo de saida

                inc totalGruposArquivo ; contabiliza grupo

                lea bx, fileBuffer
                mov di, bx
                
                loop_processa_file_buffer:

                    mov dx, es:[di]

                    cmp dx, CR
                    je ignora_loop_processa_file_buffer

                    cmp dx, LF
                    je ignora_linha_loop_processa_file_buffer

                    cmp dx, 0
                    je escreve_grupo_no_arquivo_saida

                    cmp dx, opcaoASaida
                    je processa_file_buffer_A

                    cmp dx, opcaoTSaida
                    je processa_file_buffer_T

                    cmp dx, opcaoCSaida
                    je processa_file_buffer_C

                    cmp dx, opcaoGSaida
                    je processa_file_buffer_G

                    mov bx, msgErroCaractereInvalidoArquivoEntrada
                    call printf_s

                    jmp final_processa_arquivo_entrada

                    processa_file_buffer_A:
                        inc totalBasesA
                        inc totalBasesAT

                        inc totalBasesArquivo

                        inc di
                        jmp loop_processa_file_buffer

                    processa_file_buffer_T:
                        inc totalBasesT
                        inc totalBasesAT

                        inc totalBasesArquivo

                        inc di
                        jmp loop_processa_file_buffer

                    processa_file_buffer_C:
                        inc totalBasesC
                        inc totalBasesCG

                        inc totalBasesArquivo

                        inc di
                        jmp loop_processa_file_buffer

                    processa_file_buffer_G:
                        inc totalBasesG
                        inc totalBasesCG

                        inc totalBasesArquivo

                        inc di
                        jmp loop_processa_file_buffer

                    ignora_loop_processa_file_buffer:
                        inc di
                        jmp loop_processa_file_buffer

                    ignora_linha_loop_processa_file_buffer:
                        inc totalLinhasArquivo
                        inc di
                        jmp loop_processa_file_buffer


                escreve_grupo_no_arquivo_saida:
                    ; escrever dados do grupo no arquivo de saida

                    lea bx, stringLinhaDeSaida

                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov ax, opcaoExtraA
                    repne scasb ; procura 'a'

                    jne procura_t_escreve_grupo_no_arquivo_saida

                    ; caso tiver opcao A, guarda total

                    mov di, bx
                    mov es:[di], totalBasesA ; bota total de bases A na linha
                    inc di ; proxima posicao da linha
                    inc bx
                    mov es:[di], pontoEVirgula ; bota ponto e virgula
                    add tamanhoStringLinhaDeSaida, 2

                    procura_t_escreve_grupo_no_arquivo_saida:

                        lea di, escolhaATGC ; Inicializa registradores
                        mov cx, tamanhoEscolhaATGC
                        cld

                        mov ax, opcaoExtraT
                        repne scasb ; procura 't'

                        jne procura_c_escreve_grupo_no_arquivo_saida

                        ; caso tiver opcao T, guarda total

                        mov di, bx
                        mov es:[di], totalBasesT ; bota total de bases T na linha
                        inc di ; proxima posicao da linha
                        inc bx
                        mov es:[di], pontoEVirgula ; bota ponto e virgula
                        add tamanhoStringLinhaDeSaida, 2

                    procura_c_escreve_grupo_no_arquivo_saida:

                        lea di, escolhaATGC ; Inicializa registradores
                        mov cx, tamanhoEscolhaATGC
                        cld

                        mov ax, opcaoExtraC
                        repne scasb ; procura 'c'

                        jne procura_g_escreve_grupo_no_arquivo_saida

                        ; caso tiver opcao C, guarda total

                        mov di, bx
                        mov es:[di], totalBasesC ; bota total de bases C na linha
                        inc di ; proxima posicao da linha
                        inc bx
                        mov es:[di], pontoEVirgula ; bota ponto e virgula
                        add tamanhoStringLinhaDeSaida, 2

                    procura_g_escreve_grupo_no_arquivo_saida:

                        lea di, escolhaATGC ; Inicializa registradores
                        mov cx, tamanhoEscolhaATGC
                        cld

                        mov ax, opcaoExtraG
                        repne scasb ; procura 'g'

                        jne procura_mais_escreve_grupo_no_arquivo_saida

                        ; caso tiver opcao G, guarda total

                        mov di, bx
                        mov es:[di], totalBasesG ; bota total de bases G na linha
                        inc di ; proxima posicao da linha
                        inc bx
                        mov es:[di], pontoEVirgula ; bota ponto e virgula
                        add tamanhoStringLinhaDeSaida, 2

                    procura_mais_escreve_grupo_no_arquivo_saida:

                        lea di, escolhaATGC ; Inicializa registradores
                        mov cx, tamanhoEscolhaATGC
                        cld

                        mov ax, opcaoExtraMais
                        repne scasb ; procura '+'

                        jne finaliza_escreve_grupo_no_arquivo_saida ; se chegou aqui, finalizou e volta pro fluxo

                        ; caso tiver opcao +, guarda total

                        mov di, bx
                        mov es:[di], totalBasesAT ; bota total de bases AT na linha
                        inc di ; proxima posicao da linha
                        mov es:[di], pontoEVirgula ; bota ponto e virgula
                        inc di ; proxima posicao da linha
                        mov es:[di], totalBasesCG ; bota total de bases CG na linha
                        
                        add tamanhoStringLinhaDeSaida, 4

                    finaliza_escreve_grupo_no_arquivo_saida:
                        inc di ; proxima posicao da linha
                        mov es:[di], CR ; bota CR na linha
                        inc di ; proxima posicao da linha
                        mov es:[di], LF ; bota LF na linha
                        inc di ; proxima posicao da linha
                        mov es:[di], 0 ; bota 0 como fim

                        jmp loop_processa_grupo
                

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

    mov	byte ptr es:[di], 0

    pop es ; retorna as informações dos registradores de segmentos
    pop ds

    ret

get_linha_comando	endp

;--------------------------------------------------------------------
;Fun��o Cria o arquivo cujo nome est� no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fcreate	proc	near
	mov		cx,0
	mov		ah,3ch
	int		21h
	mov		bx,ax
	ret
fcreate	endp

;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp


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