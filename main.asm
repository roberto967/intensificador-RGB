;João Roberto de Oliveira Ferreira - Mat.: 20200083646 
.686
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\msvcrt.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

.data
    ;variaveis de entrada e saída
    inputHandle dd 0 ; Variavel para armazenar o handle de entrada
    outputHandle dd 0 ; Variavel para armazenar o handle de saida
    console_count dd 0 ; Variavel para armazenar caracteres lidos/escritos na console
    tamanho_string dd 0 ; Variavel para armazenar tamanho de string terminada em 0

    ; Variaveis destinadas a abertura e tratamento dos arquivos
    readHandle dd 0
    fileHandle dd 0
    fileBuffer3bytes dd 3 dup(0)
    fileBuffer54bytes dd 54 dup(0)
    readCount dd 0
    writeHandle dd 0
    writeCount dd 0

    ; nome do arquivo a ser aberto
    fileName db 50 dup(0)

    ; nome do novo arquivo
    newFile db 50 dup(0)

    ;string de leitura dos numero
    numStr db 10 dup(0)

    ; variaveis de cor e intensidade a serem definidas pelo usuário
    cor dd 0
    intensidade dd 0

    ;variavel para armazenar a entrada
    stringEntrada1 db 5 dup(0)
    stringEntrada2 db 5 dup(0)

    ;texto para guiar o usuario
    textoNome1 db "Insira o nome do arquivo de origem: ", 0
    textoNome2 db "Insira o nome do arquivo de destino: ", 0
    textoNome3 db "Insira a cor: ", 0
    textoNome4 db "Insira a intensidade: ", 0

.code
    funcao proc stdcall
        ;+8 = intensidade
        ;+12 = cor
        ;+16 = array?
        
        push ebp
        mov ebp, esp

        xor edx, edx ; clear edx
        mov edx, DWORD PTR [ebp+12] ; cor -> edx

        xor ebx, ebx ;clear ebx
        mov ebx, DWORD PTR [ebp+8] ; intensidade -> ebx

        xor eax, eax ; clear eax
        mov eax, DWORD PTR [ebp+16] ;endereço da primeira parte do array, alterando na cor azul -> a ser alterado

        add eax, edx ; -> desloca o array para a cor selecionada
        mov ecx, [eax]

        add cl, bl ; somando com a intensidade (byte menos significativos dos reg)
        jc definirDCC ; caso a soma passe de 255 (carryOut)

        mov [eax], ecx
        jmp fimRet

        definirDCC:
            mov ebx, 255
            mov [eax], ebx
        fimRet:
            pop ebp
            ret   0
    funcao endp

    start:
        ;definição de destino e origem dos arquivos:

        ;input
        invoke GetStdHandle, STD_INPUT_HANDLE
        mov inputHandle, eax

        ;output
        invoke GetStdHandle, STD_OUTPUT_HANDLE
        mov outputHandle, eax

        ;insira o nome do arquivo:
        invoke StrLen, addr textoNome1
        mov tamanho_string, eax
        invoke WriteConsole, outputHandle, addr textoNome1, tamanho_string, addr console_count, NULL

        invoke ReadConsole, inputHandle, addr fileName, sizeof fileName, addr console_count, NULL ; entrada nome arquivo de entrada

        ;insira o nome do arquivo de saída:
        invoke StrLen, addr textoNome2
        mov tamanho_string, eax
        invoke WriteConsole, outputHandle, addr textoNome2, tamanho_string, addr console_count, NULL

        invoke ReadConsole, inputHandle, addr newFile, sizeof newFile, addr console_count, NULL ; entrada nome arquivo de saída

        ;tratando o nome do arquivo de entrada
        xor esi, esi ;clear esi
        mov esi, offset fileName ; Armazenar apontador da string em esi
        proximo:
            mov al, [esi] ; Mover caractere atual para al
            inc esi ; Apontar para o proximo caractere
            cmp al, 13 ; Verificar se eh o caractere ASCII CR - FINALIZAR
            jne proximo
            dec esi ; Apontar para caractere anterior
            xor al, al ; ASCII 0
            mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CR
        
        ;tratando o nome do arquivo de saída
        xor esi, esi ;clear esi
        mov esi, offset newFile ; Armazenar apontador da string em esi
        proximo2:
            mov al, [esi] ; Mover caractere atual para al
            inc esi ; Apontar para o proximo caractere
            cmp al, 13 ; Verificar se eh o caractere ASCII CR - FINALIZAR
            jne proximo2
            dec esi ; Apontar para caractere anterior
            xor al, al ; ASCII 0
            mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CR


        ;leitura e tratamento da intensidade e cor

        ;insira a cor:
        invoke StrLen, addr textoNome3
        mov tamanho_string, eax
        invoke WriteConsole, outputHandle, addr textoNome3, tamanho_string, addr console_count, NULL

        invoke ReadConsole, inputHandle, addr stringEntrada1, sizeof stringEntrada1, addr console_count, NULL ; entrada de cor

        ;tratando para salvar o numero da cor:
        mov esi, offset stringEntrada1 ; Armazenar apontador da string em esi
        proxCor:
            mov al, [esi] ; Mover caracter atual para al
            inc esi ; Apontar para o proximo caracter
            cmp al, 48 ; Verificar se menor que ASCII 48 - FINALIZAR
            jl termCor
            cmp al, 58 ; Verificar se menor que ASCII 58 - CONTINUAR
            jl proxCor
        termCor:
            dec esi ; Apontar para caracter anterior
            xor al, al ; 0 ou NULL
            mov [esi], al ; Inserir NULL logo apos o termino do numero
        
        invoke atodw, addr stringEntrada1

        mov cor, eax
        ;fim inserção da cor

        ;insira a intesidade:
        invoke StrLen, addr textoNome4
        mov tamanho_string, eax
        invoke WriteConsole, outputHandle, addr textoNome4, tamanho_string, addr console_count, NULL

        invoke ReadConsole, inputHandle, addr stringEntrada2, sizeof stringEntrada2, addr console_count, NULL ; entrada de intensidade

        ;tratando para salvar a intensidade:
        mov esi, offset stringEntrada2 ; Armazenar apontador da string em esi
        proxIntens:
            mov al, [esi] ; Mover caracter atual para al
            inc esi ; Apontar para o proximo caracter
            cmp al, 48 ; Verificar se menor que ASCII 48 - FINALIZAR
            jl terminaIntens
            cmp al, 58 ; Verificar se menor que ASCII 58 - CONTINUAR
            jl proxIntens
        terminaIntens:
            dec esi ; Apontar para caracter anterior
            xor al, al ; 0 ou NULL
            mov [esi], al ; Inserir NULL logo apos o termino do numero
        
        invoke atodw, addr stringEntrada2

        mov intensidade, eax
        ;fim inserção intensidade

        ;primeira abertura e criação do arquivo, le e copia os 54 bytes
        invoke CreateFile, addr fileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL ; abre arquivo para leitura
        mov fileHandle, eax ; ponteiro para arquivo
        invoke ReadFile, fileHandle, addr fileBuffer54bytes, 54, addr readCount, NULL ; Le 10 bytes do arquivo

        invoke CreateFile, addr newFile, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL ; cria um novo arquivo para escrita
        mov writeHandle, eax ; ponteiro para novo arquivo
        invoke WriteFile, writeHandle, addr fileBuffer54bytes, 54, addr writeCount, NULL ; escreve no novo arquivo
        
        ;loop copiando de 3 em 3 bytes
        ler:
            invoke ReadFile, fileHandle, addr fileBuffer3bytes, 3, addr readCount, NULL
            
            ; movendo os parametos das funções para registradores
            mov ecx, intensidade
            mov edx, cor
            mov ebx, offset fileBuffer3bytes
            
            ; colocando os registradores com os parametros na pilha (na ordem inversa)
            push ebx
            push edx
            push ecx
            
            ; fazendo a chamada da função
            call funcao
            
            ; limpeza do da pilha
            add esp, 12
            
            cmp readCount, 0
        je fim


        repete:
            invoke WriteFile, writeHandle, addr fileBuffer3bytes, 3, addr writeCount, NULL ; escreve no novo arquivo
            jmp ler
            
        fim:
            invoke CloseHandle, fileHandle ;fechando arquivo de entrada
            invoke CloseHandle, writeHandle ;fechado arquivo de escrita
            invoke ExitProcess, 0
    end start
