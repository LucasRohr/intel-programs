
;
;====================================================================
;	- Escrever um programa para ler um arquivo texto e 
;		apresent�-lo na tela
;	- O usu�rio devem informar o nome do arquivo, 
;		assim que for apresentada a mensagem: �Nome do arquivo: �
;====================================================================
;
	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah

	.data
FileName		db		256 dup (?)		; Nome do arquivo a ser lido
FileBuffer		db		10 dup (?)		; Buffer de leitura do arquivo
FileHandle		dw		0				; Handler do arquivo
FileNameBuffer	db		150 dup (?)

MsgPedeArquivo		db	"Nome do arquivo: ", 0
MsgErroOpenFile		db	"Erro na abertura do arquivo.", CR, LF, 0
MsgErroReadFile		db	"Erro na leitura do arquivo.", CR, LF, 0

	.code
	.startup

;====================================================================
;void main(void)
;{
;	GetFileName();
;
;	if ( (ax=fopen(ah=0x3d, dx->FileName) ) ) {
;		printf("Erro na abertura do arquivo.\r\n");
;		exit(1);
;	}
;	FileHandle = ax
;
;	while(1) {
;		if ( (ax=fread(ah=0x3f, bx=FileHandle, cx=1, dx=FileBuffer)) ) {
;			printf ("Erro na leitura do arquivo.\r\n");
;			fclose(bx=FileHandle)
;			exit(1);
;		}
;		if (ax==0) {
;			fclose(bx=FileHandle);
;			exit(0);
;		}
;
;		printf("%c", FileBuffer[0]);	// Coloca um caractere na tela
;	}
;}
;
;====================================================================
		
	;	GetFileName();
	call	GetFileName

	;	if ( (ax=fopen(ah=0x3d, dx->FileName) ) ) {
	;		printf("Erro na abertura do arquivo.\r\n");
	;		exit(1);
	;	}
	mov		al,0
	lea		dx,FileName
	mov		ah,3dh
	int		21h
	jnc		Continua1
	
	lea		bx,MsgErroOpenFile
	call	printf_s
	
	.exit	1
	
Continua1:

	;	FileHandle = ax
	mov		FileHandle,ax		; Salva handle do arquivo

	;	while(1) {
Again:
	;		if ( (ax=fread(ah=0x3f, bx=FileHandle, cx=1, dx=FileBuffer)) ) {
	;			printf ("Erro na leitura do arquivo.\r\n");
	;			fclose(bx=FileHandle)
	;			exit(1);
	;		}
	mov		bx,FileHandle
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	jnc		Continua2
	
	lea		bx,MsgErroReadFile
	call	printf_s
	
	mov		al,1
	jmp		CloseAndFinal

Continua2:
	;		if (ax==0) {
	;			fclose(bx=FileHandle);
	;			exit(0);
	;		}
	cmp		ax,0
	jne		Continua3

	mov		al,0
	jmp		CloseAndFinal

Continua3:
	;		printf("%c", FileBuffer[0]);	// Coloca um caractere na tela
	mov		ah,2
	mov		dl,FileBuffer
	int		21h
	
	;	}
	jmp		Again

CloseAndFinal:
	mov		bx,FileHandle		; Fecha o arquivo
	mov		ah,3eh
	int		21h

Final:
	.exit

;
;--------------------------------------------------------------------
;Funcao: Le o nome do arquivo do teclado
;void GetFileName(void)
;{
;	printf_s("Nome do arquivo: ");
;
;	// L� uma linha do teclado
;	FileNameBuffer[0]=100;
;	gets(ah=0x0A, dx=&FileNameBuffer)
;
;	// Copia do buffer de teclado para o FileName
;	for (char *s=FileNameBuffer+2, char *d=FileName, cx=FileNameBuffer[1]; cx!=0; s++,d++,cx--)
;		*d = *s;
;
;	// Coloca o '\0' no final do string
;	*d = '\0';
;}
;--------------------------------------------------------------------
GetFileName	proc	near

	;	printf_s("Nome do arquivo: ");
	lea		bx,MsgPedeArquivo
	call	printf_s

	;	// L� uma linha do teclado
	;	FileNameBuffer[0]=100;
	;	gets(ah=0x0A, dx=&FileNameBuffer)
	mov		ah,0ah
	lea		dx,FileNameBuffer
	mov		byte ptr FileNameBuffer,100
	int		21h

	;	// Copia do buffer de teclado para o FileName
	;	for (char *s=FileNameBuffer+2, char *d=FileName, cx=FileNameBuffer[1]; cx!=0; s++,d++,cx--)
	;		*d = *s;		
	lea		si,FileNameBuffer+2
	lea		di,FileName
	mov		cl,FileNameBuffer+1
	mov		ch,0
	mov		ax,ds						; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax
	rep 	movsb

	;	// Coloca o '\0' no final do string
	;	*d = '\0';
	mov		byte ptr es:[di],0
	ret
GetFileName	endp


;====================================================================
; A partir daqui, est�o as fun��es j� desenvolvidas
;	1) printf_s
;====================================================================
	
;--------------------------------------------------------------------
;Fun��o Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
		
ps_1:
	ret
printf_s	endp

;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------


	




