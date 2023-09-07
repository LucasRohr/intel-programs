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

    opcaoF dw "f-"
    opcaoO dw "o-"
    opcaoN dw "n-"
    opcaoA dw "a-"
    opcaoT dw "t-"
    opcaoG dw "g-"
    opcaoC dw "c-"
    opcaoMais dw "+-"

    nomeArquivoEntrada db 50 dup (?)
    nomeArquivoSaida db 50 dup (?)
    tamanhoGrupoString db 5 dup (?)
    tamanhoGrupo dw 0
    escolhaATGC dw 5 dup (?)
    tamanhoEscolhaATGC dw 5 dup (?)

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

    tamanhoMaxArquivo equ 10000

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

    msgArquivoMuitoPequeno db "Erro: o arquivo informado eh muito pequeno", CR, LF, 0
    msgTamanhoMinArquivo db "Tamanho minimo:", CR, LF, 0
    msgArquivoMuitoGrande db "Erro: o arquivo informado eh muito grande (mais de 10.000 caracteres)", CR, LF, 0

    msgCRLF	db	CR, LF, 0

    nomePadraoArquivoSaida	db	"a.out"
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

    indiceFimBaseArquivo dw 0

    totalBasesA dw 0
    totalBasesT dw 0
    totalBasesC dw 0
    totalBasesG dw 0
    totalBasesAT dw 0
    totalBasesCG dw 0

    stringLinhaDeSaida 	db	50 dup (?) ; linha a ser escrita no arquivo de saida a cada leitura de grupo na entrada
    tamanhoStringLinhaDeSaida dw 0

    stringHeaderSaida db 15 dup (?)
    tamanhoStringHeaderSaida dw 0

    ; Variaveis para o resumo em tela

    msgInfosDasOpcoes db CR, LF, "== Informacoes das opcoes fornecidas ==", CR, LF, 0
    msgNomeArquivoEntrada db "-> Nome do arquivo de entrada:", CR, LF, 0
    msgNomeArquivoSaida db "-> Nome do arquivo de saida:", CR, LF, 0
    msgTamanhoGrupos db "-> Tamanho dos grupos de bases:", CR, LF, 0
    msgOpcoesATGC db "-> Opcoes ATGC:", CR, LF, 0

    msgInfosDaEntrada db CR, LF, "== Informacoes do arquivo de entrada ==", CR, LF, 0
    msgNumeroDeBases db "-> Total de bases no arquivo de entrada:", CR, LF, 0
    msgNumeroDeGrupos db "-> Total de grupos no arquivo de entrada:", CR, LF, 0
    msgNumeroDeLinhas db "-> Total de linhas no arquivo de entrada:", CR, LF, 0

    ; ---------------------------------------------------------------

    .code ; segmento de codigo
	.startup

    ; obtem a string de opcoes digitadas pelo usuario

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
    mov	ax, ds ; Ajusta ES=DS
	mov	es, ax

    lea di, entradaLinhaComando ; Inicializa registradores

    loop_busca_opcao_f:
        mov dl, es:[di]

        cmp dl, CR
        je erro_sem_opcao_f

        cmp dl, 0
        je erro_sem_opcao_f

        cmp dl, '-'
        je continua_loop_busca_opcao_f

        inc di
        jmp loop_busca_opcao_f

        continua_loop_busca_opcao_f:
            inc di
            mov dl, es:[di]

            cmp dl, 'f'
            je continua_processa_opcao_f_informada

            jmp loop_busca_opcao_f

    continua_processa_opcao_f_informada:

        ; caso tiver opcao, guarda o nome do arquivo

        inc di

        mov si, di ; SI recebe o endereco atual na string de entrada
        inc si
        lea di, nomeArquivoEntrada ; DI recebe o endereco do nome do arquivo a ser salvo

        loop_guarda_opcao_f:
            mov dl, es:[si]

            cmp dl, CR
            je fim_loop_guarda_opcao_f

            cmp dl, 0
            je fim_loop_guarda_opcao_f

            cmp dl, ' '
            je fim_loop_guarda_opcao_f

            mov es:[di], dl

            inc si
            inc di
            jmp loop_guarda_opcao_f

            fim_loop_guarda_opcao_f:

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
    mov	ax, ds ; Ajusta ES=DS
	mov	es, ax

    lea di, entradaLinhaComando ; Inicializa registradores

    loop_busca_opcao_o:
        mov dl, es:[di]

        cmp dl, CR
        je fim_sem_opcao_o

        cmp dl, 0
        je fim_sem_opcao_o

        cmp dl, '-'
        je continua_loop_busca_opcao_o

        inc di
        jmp loop_busca_opcao_o

        continua_loop_busca_opcao_o:
            inc di
            mov dl, es:[di]

            cmp dl, 'o'
            je continua_processa_opcao_o_informada

            jmp loop_busca_opcao_o

    continua_processa_opcao_o_informada:
        ; caso tiver opcao, guarda o nome do arquivo de saída

        inc di

        mov si, di ; SI recebe o endereco atual na string de entrada
        inc si
        lea di, nomeArquivoSaida ; DI recebe o endereco do nome do arquivo a ser salvo

        loop_guarda_opcao_o:
            mov dl, es:[si]

            cmp dl, CR
            je fim_loop_guarda_opcao_o

            cmp dl, 0
            je fim_loop_guarda_opcao_o

            cmp dl, ' '
            je fim_loop_guarda_opcao_o

            mov es:[di], dl

            inc si
            inc di
            jmp loop_guarda_opcao_o

            fim_loop_guarda_opcao_o:
                mov	byte ptr es:[di], 0 ; Coloca marca de fim de string
                ret ; retorna

        fim_sem_opcao_o:
            lea si, nomePadraoArquivoSaida ; SI recebe o endereco do nome padrao
            lea di, nomeArquivoSaida ; DI recebe o endereco do nome do arquivo a ser salvo
            mov cx, 5 ; tamanho do nome padrao

            mov	ax, ds ; Ajusta ES=DS para poder usar o MOVSB
            mov	es, ax

            rep movsb

            mov	byte ptr es:[di], 0

            ret ; retorna

processa_opcao_o	endp


; Funcao para processar o tamanho dos grupos de bases na linha de comando lida

processa_opcao_n	proc	near

    mov	ax, ds ; Ajusta ES=DS
	mov	es, ax

    lea di, entradaLinhaComando ; Inicializa registradores

    loop_busca_opcao_n:
        mov dl, es:[di]

        cmp dl, CR
        je erro_sem_opcao_n

        cmp dl, 0
        je erro_sem_opcao_n

        cmp dl, '-'
        je continua_loop_busca_opcao_n

        inc di
        jmp loop_busca_opcao_n

        continua_loop_busca_opcao_n:
            inc di
            mov dl, es:[di]

            cmp dl, 'n'
            je continua_processa_opcao_n_informada

            jmp loop_busca_opcao_n

    continua_processa_opcao_n_informada:
        ; caso tiver opcao, guarda o tamanho dos grupos

        inc di

        mov si, di ; SI recebe o endereco atual na string de entrada
        inc si
        lea di, tamanhoGrupoString ; DI recebe o endereco do nome do arquivo a ser salvo

       loop_guarda_opcao_n:
            mov dl, es:[si]

            cmp dl, CR
            je fim_loop_guarda_opcao_n

            cmp dl, 0
            je fim_loop_guarda_opcao_n

            cmp dl, ' '
            je fim_loop_guarda_opcao_n

            mov es:[di], dl

            inc si
            inc di
            jmp loop_guarda_opcao_n

            fim_loop_guarda_opcao_n:
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

    mov	ax, ds ; Ajusta ES=DS
	mov	es, ax

    lea di, entradaLinhaComando

    loop_busca_opcao_a:
        mov dl, es:[di]

        cmp dl, CR
        je processa_busca_opcao_t

        cmp dl, 0
        je processa_busca_opcao_t

        cmp dl, '-'
        je continua_loop_busca_opcao_a

        inc di
        jmp loop_busca_opcao_a

        continua_loop_busca_opcao_a:
            inc di
            mov dl, es:[di]

            cmp dl, 'a'
            je processa_opcao_atgc_completa

            jmp loop_busca_opcao_a

    processa_busca_opcao_t:
        lea di, entradaLinhaComando

        loop_busca_opcao_t:
            mov dl, es:[di]

            cmp dl, CR
            je processa_busca_opcao_g

            cmp dl, 0
            je processa_busca_opcao_g

            cmp dl, '-'
            je continua_loop_busca_opcao_t

            inc di
            jmp loop_busca_opcao_t

            continua_loop_busca_opcao_t:
                inc di
                mov dl, es:[di]

                cmp dl, 't'
                je processa_opcao_atgc_completa

                jmp loop_busca_opcao_t

    processa_busca_opcao_g:
        lea di, entradaLinhaComando

        loop_busca_opcao_g:
            mov dl, es:[di]

            cmp dl, CR
            je processa_busca_opcao_c

            cmp dl, 0
            je processa_busca_opcao_c

            cmp dl, '-'
            je continua_loop_busca_opcao_g

            inc di
            jmp loop_busca_opcao_g

            continua_loop_busca_opcao_g:
                inc di
                mov dl, es:[di]

                cmp dl, 'g'
                je processa_opcao_atgc_completa

                jmp loop_busca_opcao_g

    processa_busca_opcao_c:
        lea di, entradaLinhaComando

        loop_busca_opcao_c:
            mov dl, es:[di]

            cmp dl, CR
            je processa_busca_opcao_mais

            cmp dl, 0
            je processa_busca_opcao_mais

            cmp dl, '-'
            je continua_loop_busca_opcao_c

            inc di
            jmp loop_busca_opcao_c

            continua_loop_busca_opcao_c:
                inc di
                mov dl, es:[di]

                cmp dl, 'c'
                je processa_opcao_atgc_completa

                jmp loop_busca_opcao_c

    processa_busca_opcao_mais:
        lea di, entradaLinhaComando

        loop_busca_opcao_mais:
            mov dl, es:[di]

            cmp dl, CR
            je erro_sem_opcao_atgc

            cmp dl, 0
            je erro_sem_opcao_atgc

            cmp dl, '-'
            je continua_loop_busca_opcao_mais

            inc di
            jmp loop_busca_opcao_mais

            continua_loop_busca_opcao_mais:
                inc di
                mov dl, es:[di]

                cmp dl, '+'
                je processa_opcao_atgc_completa

                jmp loop_busca_opcao_mais

    processa_opcao_atgc_completa:
        mov si, di ; SI recebe o endereco atual na string de entrada
        lea di, escolhaATGC ; DI recebe o endereco das opcoes ATGE a serem salvas

        loop_processa_atgc_completa:
            mov dl, es:[si]

            cmp dl, ' '
            je fim_opcao_atgc

            cmp dl, 0
            je fim_opcao_atgc

            cmp dl, CR
            je fim_opcao_atgc

            cmp dl, opcaoExtraA
            je salva_opcao_extra_atgc

            cmp dl, opcaoExtraT
            je salva_opcao_extra_atgc

            cmp dl, opcaoExtraG
            je salva_opcao_extra_atgc

            cmp dl, opcaoExtraC
            je salva_opcao_extra_atgc

            cmp dl, opcaoExtraMais
            je salva_opcao_extra_atgc

            jne fim_opcao_atgc_invalida

            salva_opcao_extra_atgc:
                mov es:[di], dl ; salva opcao que esta no dl
                inc si
                inc di
                inc tamanhoEscolhaATGC

                jmp loop_processa_atgc_completa

        fim_opcao_atgc:
            mov byte ptr es:[di], 0 ; Coloca marca de fim de string
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

    mov	ax, ds ; Ajusta ES=DS
	mov	es, ax

    ; abre arquivo de entrada
    mov	al, 0 ; modo read
	lea	dx, nomeArquivoEntrada
	mov	ah, 3dh
	int	21h

    ; se nao houve erro para abrir, continua
	jnc	continua_processa_arquivo_entrada

    ; se houve erro, printa que o arquivo nao existe e encerra
	lea	bx, msgErroAbrirArquivo
	call printf_s
    mov	al,1
	jmp	final_processa_arquivo_entrada

    continua_processa_arquivo_entrada:
        ; fileHandle = ax
	    mov	fileHandle, ax

        mov totalBasesArquivo, 0
        mov totalGruposArquivo, 0
        mov totalLinhasArquivo, 1 ; comeca em uma linha sempre, pois é total de CR/LF + 1

        loop_le_caractere_arquivo:

            ; contar tamanho do arquivo de entrada para validar o mesmo

            ;		if ( (ax=fread(ah=0x3f, bx=FileHandle, cx=1, dx=FileBuffer)) ) {
            ;			printf ("Erro na leitura do arquivo.\r\n");
            ;			fclose(bx=FileHandle)
            ;			exit(1);
            ;		}

            mov	bx, fileHandle
            mov	ah, 3fh
            mov	cx, 1 ; le caractere por caractere
            lea	dx, fileBuffer
            int	21h

            jnc	valida_caractere_arquivo_entrada

            lea	bx, msgErroLerArquivo
            call printf_s
            mov	al,1
            jmp	final_processa_arquivo_entrada

        valida_caractere_arquivo_entrada:
            mov dl, fileBuffer

            cmp dl, CR
            je loop_processa_file_buffer_tamanho_arquivo_CR

            cmp dl, LF
            je loop_processa_file_buffer_tamanho_arquivo_LF

            cmp dl, 0
            je fim_loop_processa_file_buffer_tamanho_arquivo

            ; se nao for quebra de linha e nem 0, contabiliza
            inc totalBasesArquivo
            jmp loop_le_caractere_arquivo

            loop_processa_file_buffer_tamanho_arquivo_CR:
                inc totalLinhasArquivo
                jmp loop_le_caractere_arquivo
        
            loop_processa_file_buffer_tamanho_arquivo_LF:
                jmp loop_le_caractere_arquivo

        fim_loop_processa_file_buffer_tamanho_arquivo:
            lea bx, msgErroOpcaoF
            call printf_s

            lea bx, msgCRLF
            call printf_s

            mov dx, totalBasesArquivo

            cmp dx, tamanhoGrupo
            jl tamanho_arquivo_invalido_pequeno

            cmp dx, tamanhoMaxArquivo
            jg tamanho_arquivo_invalido_grande

            jmp continua_valida_tamanho_arquivo_entrada_valido

            tamanho_arquivo_invalido_pequeno:
                lea	bx, msgArquivoMuitoPequeno
                call printf_s
                jmp	final_processa_arquivo_entrada

            tamanho_arquivo_invalido_grande:
                lea	bx, msgArquivoMuitoGrande
                call printf_s
                jmp	final_processa_arquivo_entrada

        continua_valida_tamanho_arquivo_entrada_valido:
            mov dx, totalBasesArquivo
            mov indiceFimBaseArquivo, dx ; total m de bases

            mov dx, tamanhoGrupo ; total n de grupos
            sub indiceFimBaseArquivo, dx ; m-n

            mov dx, indiceFimBaseArquivo
            mov totalGruposArquivo, dx ; totalGruposArquivo = m-n

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
            jnc		printa_header_arquivo_saida ; se criou com sucesso, vai para printar o header

            mov		bx, fileHandle
            call	fclose ; se houve erro criando o arquivo de saida, fecha o de entrada e encerra
            lea		bx, msgErroCriarArquivoSaida
            call	printf_s

            jmp final_processa_arquivo_entrada

        printa_header_arquivo_saida:
            ; abrir o arquivo de output

            ; tenta abrir arquivo de saida, fopen
            mov	al, 1 ; modo write
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
                lea si, stringHeaderSaida

                lea di, escolhaATGC ; Inicializa registradores
                mov cx, tamanhoEscolhaATGC
                cld

                mov al, opcaoExtraA
                repne scasb ; procura 'a'

                jne procura_t_printa_header_arquivo_saida

                ; caso tiver opcao, guarda ela

                mov es:[si], opcaoASaida ; bota A no header
                inc si ; proxima posicao da linha
                mov es:[si], pontoEVirgula ; bota ponto e virgula
                inc si ; proxima posicao da linha
                add tamanhoStringHeaderSaida, 2

                procura_t_printa_header_arquivo_saida:
                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov al, opcaoExtraT
                    repne scasb ; procura 't'

                    jne procura_c_printa_header_arquivo_saida

                    ; caso tiver opcao, guarda ela

                    mov es:[si], opcaoTSaida ; bota T no header
                    inc si ; proxima posicao da linha
                    mov es:[si], pontoEVirgula ; bota ponto e virgula
                    inc si ; proxima posicao da linha
                    add tamanhoStringHeaderSaida, 2

                procura_c_printa_header_arquivo_saida:
                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov al, opcaoExtraC
                    repne scasb ; procura 'c'

                    jne procura_g_printa_header_arquivo_saida

                    ; caso tiver opcao, guarda ela

                    mov es:[si], opcaoCSaida ; bota C no header
                    inc si ; proxima posicao da linha
                    mov es:[si], pontoEVirgula ; bota ponto e virgula
                    inc si ; proxima posicao da linha
                    add tamanhoStringHeaderSaida, 2

                procura_g_printa_header_arquivo_saida:
                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov al, opcaoExtraG
                    repne scasb ; procura 'g'

                    jne procura_mais_printa_header_arquivo_saida

                    ; caso tiver opcao, guarda ela

                    mov es:[si], opcaoGSaida ; bota G no header
                    inc si ; proxima posicao da linha
                    mov es:[si], pontoEVirgula ; bota ponto e virgula
                    inc si ; proxima posicao da linha
                    add tamanhoStringHeaderSaida, 2

                procura_mais_printa_header_arquivo_saida:
                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov al, opcaoExtraMais
                    repne scasb ; procura '+'

                    jne finaliza_printa_header_arquivo_saida

                    ; caso tiver opcao, guarda ela

                    mov es:[si], opcaoASaida ; bota A no header
                    inc si ; proxima posicao da linha
                    mov es:[si], opcaoMaisSaida ; bota + no header
                    inc si ; proxima posicao da linha
                    mov es:[si], opcaoTSaida ; bota T no header
                    inc si ; proxima posicao da linha
                    mov es:[si], pontoEVirgula ; bota ; no header

                    inc si ; 
                    mov es:[si], opcaoCSaida ; bota C no header
                    inc si ; proxima posicao da linha
                    mov es:[si], opcaoMaisSaida ; bota + no header
                    inc si ; proxima posicao da linha
                    mov es:[si], opcaoGSaida ; bota G no header
                    
                    add tamanhoStringHeaderSaida, 7 ; A+T;C+G

                finaliza_printa_header_arquivo_saida:
                    inc si ; proxima posicao da linha
                    mov es:[si], CR ; bota CR no header
                    inc si ; proxima posicao da linha
                    mov es:[si], LF ; bota LF no header
                    inc si ; proxima posicao da linha
                    mov byte ptr es:[di], 0 ; bota 0 como fim

                    add tamanhoStringHeaderSaida, 3

                    jmp printa_header

            printa_header:
                ; escreve o header no arquivo de saida
                mov bx, fileSaidaHandle
                mov	ah, 40h
                mov	cx, tamanhoStringHeaderSaida ; num de bytes e a serem escritos
                lea	dx, stringHeaderSaida ; buffer dos dados
                int	21h

                jnc	loop_processa_grupo

                mov	bx, fileHandle
                call fclose ; se houve erro escrevendo no arquivo de saida, fecha o de entrada e encerra
                lea	bx, msgErroEscreverArquivoSaida
                call printf_s

                jmp final_processa_arquivo_entrada

        loop_processa_grupo:
            mov totalBasesA, 0
            mov totalBasesT, 0
            mov totalBasesC, 0
            mov totalBasesG, 0
            mov totalBasesAT, 0
            mov totalBasesCG, 0
            mov tamanhoStringLinhaDeSaida, 0

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

            jnc	verifica_fim_loop_processa_grupo

            lea	bx, msgErroLerArquivo
            call printf_s
            mov	al,1
            jmp	final_processa_arquivo_entrada

            verifica_fim_loop_processa_grupo:
                dec indiceFimBaseArquivo

                cmp indiceFimBaseArquivo, 0 ; se chegou no fim de quantos grupos vai ter, acaba
                je final_resumo_processa_arquivo_entrada

                ; Verifica se terminou o arquivo
                ;	if (ax==0) {
                ;		fclose(bx=FileHandle);
                ;		exit(0);
                ;	}
                cmp		ax,0
                jne		continua_loop_processa_grupo
                mov		al,0
                jmp		final_resumo_processa_arquivo_entrada

            continua_loop_processa_grupo:
                ; abrir o arquivo de output

                ; tenta abrir arquivo de saida, fopen
                mov	al, 1 ; modo write
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
                ; preciso iterar pelo file buffer do grupo atual e processar o grupo
                ;   -> usar o arquivo de entrada e processar ele (fileBuffer)
                ;   -> salvar totais para mostrar no resumo e na saida
                ;   -> escrever dados do grupo no arquivo de saida

                lea di, fileBuffer ; di recebe o endereco do fileBuffer

                loop_processa_file_buffer:
                    mov dl, es:[di] ; dl recebe o char atual do buffer

                    cmp dl, CR
                    je ignora_loop_processa_file_buffer ; se leu CR no buffer de entrada, ignora

                    cmp dl, LF
                    je ignora_loop_processa_file_buffer ; se leu LF no buffer de entrada, ignora

                    cmp dl, 0
                    je escreve_grupo_no_arquivo_saida ; se chegou no 0 do buffer, acabou ele

                    cmp dl, opcaoASaida
                    je processa_file_buffer_A

                    cmp dl, opcaoTSaida
                    je processa_file_buffer_T

                    cmp dl, opcaoCSaida
                    je processa_file_buffer_C

                    cmp dl, opcaoGSaida
                    je processa_file_buffer_G

                    ; se chegou aqui, leu um char invalido diferente dos permitidos, gera erro e finaliza
                    lea bx, msgErroCaractereInvalidoArquivoEntrada
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


                escreve_grupo_no_arquivo_saida:
                    ; escrever dados do grupo no arquivo de saida

                    lea si, stringLinhaDeSaida

                    lea di, escolhaATGC ; Inicializa registradores
                    mov cx, tamanhoEscolhaATGC
                    cld

                    mov al, opcaoExtraA
                    repne scasb ; procura 'a'

                    jne procura_t_escreve_grupo_no_arquivo_saida

                    ; caso tiver opcao A, guarda total

                    mov dx, totalBasesA
                    add dx, 48 ; soma 48 no total para ser lido como char ASCII

                    mov es:[si], dx ; bota total de bases A na linha
                    inc si ; proxima posicao da linha
                    mov es:[si], pontoEVirgula ; bota ponto e virgula
                    inc si ; proxima posicao da linha
                    add tamanhoStringLinhaDeSaida, 2

                    procura_t_escreve_grupo_no_arquivo_saida:
                        lea di, escolhaATGC ; Inicializa registradores
                        mov cx, tamanhoEscolhaATGC
                        cld

                        mov al, opcaoExtraT
                        repne scasb ; procura 't'

                        jne procura_c_escreve_grupo_no_arquivo_saida

                        ; caso tiver opcao T, guarda total

                        mov dx, totalBasesT
                        add dx, 48 ; soma 48 no total para ser lido como char ASCII

                        mov es:[si], dx ; bota total de bases T na linha
                        inc si ; proxima posicao da linha
                        mov es:[si], pontoEVirgula ; bota ponto e virgula
                        inc si ; proxima posicao da linha
                        add tamanhoStringLinhaDeSaida, 2

                    procura_c_escreve_grupo_no_arquivo_saida:
                        lea di, escolhaATGC ; Inicializa registradores
                        mov cx, tamanhoEscolhaATGC
                        cld

                        mov al, opcaoExtraC
                        repne scasb ; procura 'c'

                        jne procura_g_escreve_grupo_no_arquivo_saida

                        ; caso tiver opcao C, guarda total

                        mov dx, totalBasesC
                        add dx, 48 ; soma 48 no total para ser lido como char ASCII

                        mov es:[si], dx ; bota total de bases C na linha
                        inc si ; proxima posicao da linha
                        mov es:[si], pontoEVirgula ; bota ponto e virgula
                        inc si ; proxima posicao da linha
                        add tamanhoStringLinhaDeSaida, 2

                    procura_g_escreve_grupo_no_arquivo_saida:
                        lea di, escolhaATGC ; Inicializa registradores
                        mov cx, tamanhoEscolhaATGC
                        cld

                        mov al, opcaoExtraG
                        repne scasb ; procura 'g'

                        jne procura_mais_escreve_grupo_no_arquivo_saida

                        ; caso tiver opcao G, guarda total

                        mov dx, totalBasesG
                        add dx, 48 ; soma 48 no total para ser lido como char ASCII

                        mov es:[si], dx ; bota total de bases G na linha
                        inc si ; proxima posicao da linha
                        mov es:[si], pontoEVirgula ; bota ponto e virgula
                        inc si ; proxima posicao da linha
                        add tamanhoStringLinhaDeSaida, 2

                    procura_mais_escreve_grupo_no_arquivo_saida:
                        lea di, escolhaATGC ; Inicializa registradores
                        mov cx, tamanhoEscolhaATGC
                        cld

                        mov al, opcaoExtraMais
                        repne scasb ; procura '+'

                        jne finaliza_escreve_grupo_no_arquivo_saida ; se chegou aqui, finaliza e escreve a linha na saida

                        ; caso tiver opcao +, guarda total

                        mov dx, totalBasesAT
                        add dx, 48 ; soma 48 no total para ser lido como char ASCII

                        mov es:[si], dx ; bota total de bases AT na linha
                        inc si ; proxima posicao da linha
                        mov es:[si], pontoEVirgula ; bota ponto e virgula
                        inc si ; proxima posicao da linha

                        mov dx, totalBasesCG
                        add dx, 48 ; soma 48 no total para ser lido como char ASCII

                        mov es:[si], dx ; bota total de bases CG na linha
                        
                        add tamanhoStringLinhaDeSaida, 3

                    finaliza_escreve_grupo_no_arquivo_saida:
                        inc si ; proxima posicao da linha
                        mov es:[si], CR ; bota CR na linha
                        inc si ; proxima posicao da linha
                        mov es:[si], LF ; bota LF na linha
                        inc si ; proxima posicao da linha
                        mov es:[si], 0 ; bota 0 como fim

                        add tamanhoStringLinhaDeSaida, 3

                        ; escreve a linha no arquivo de saida
                        mov bx, fileSaidaHandle
                        mov	ah, 40h
                        mov	cx, tamanhoStringLinhaDeSaida ; num de bytes e a serem escritos
                        lea	dx, stringLinhaDeSaida ; buffer dos dados
                        int	21h

                        jnc	loop_processa_grupo ; se escreveu com sucesso, vai para o proximo grupo

                        mov	bx, fileHandle
                        call fclose ; se houve erro escrevendo no arquivo de saida, fecha o de entrada e encerra
                        lea	bx, msgErroEscreverArquivoSaida
                        call printf_s

                        jmp final_processa_arquivo_entrada
                

    final_resumo_processa_arquivo_entrada:
        ; == secao de opcoes ==

        lea bx, msgInfosDasOpcoes
        call printf_s

        ; -> nome do arquivo de entrada
        lea bx, msgNomeArquivoEntrada
        call printf_s

        lea bx, nomeArquivoEntrada
        call printf_s

        ; -> nome do arquivo de saida
        lea bx, msgNomeArquivoSaida
        call printf_s

        lea bx, nomeArquivoSaida
        call printf_s

        ; -> tamanho dos grupos
        lea bx, msgTamanhoGrupos
        call printf_s

        lea bx, tamanhoGrupoString
        call printf_s

        ; -> opcoes ATGC
        lea bx, msgOpcoesATGC
        call printf_s

        lea bx, escolhaATGC
        call printf_s

        ; == secao de dados da entrada ==
        
        lea bx, msgInfosDaEntrada
        call printf_s

        lea bx, msgNumeroDeBases
        call printf_s

        mov dx, totalBasesArquivo
        push bx
        mov	ah,2
        int	21H
        pop	bx

        lea bx, msgCRLF
        call printf_s

        lea bx, msgNumeroDeGrupos
        call printf_s

        mov dx, totalGruposArquivo
        push bx
        mov	ah,2
        int	21H
        pop	bx

        lea bx, msgCRLF
        call printf_s

        lea bx, msgNumeroDeLinhas
        call printf_s

        mov dx, totalLinhasArquivo
        push bx
        mov	ah,2
        int	21H
        pop	bx

        lea bx, msgCRLF
        call printf_s

        .exit

    final_processa_arquivo_entrada:
        .exit

processa_arquivo_entrada	endp


; ========== Funcoes default de uso geral =============

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
		mov		dl,[bx]
		cmp		dl,0
		je		atoi_1

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