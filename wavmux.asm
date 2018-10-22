include Irvine32.inc

 GetFileSize proto, hFile: handle, lpFileSizeHigh: ptr dword;Win32 API function

.const
	riffConst EQU "FFIR" ;Marking the riff type of file
	waveConst EQU "EVAW" ;File type header mark
	formatChunkConst EQU " tmf"; Format chunk marker
	dataConst EQU "atad" ;Marking the begining of data section
	inBuffSize EQU 262144 ; 256KB
	outBuffSize EQU 524288; Min size 44 bytes, 512KB 
	maxPathLen EQU 260 ;Max path length for MS-DOS, 260 ASCII characters

.data
	sampleSize dword 16 ;Sample bit size, default value 16 bit
	channels word 2; Number of channels, default value 2
	sampleRate dword 44100; Sample rate, default value 44100 (CD) 48000 (DVD)
	byteRate dword 176400; (sampleRate *sampleSize*channels)/8

	consoleTitle byte "WAVMUX",0h

	introText label byte
	byte "============================================================================",0ah
	byte "|                                W A V M U X                               |",0ah
	byte "|Program that muxes two .wav                       Authors: Petar Marin    |",0ah
	byte "|mono files into single .wav stereo file                    Igor Beracka   |",0ah
	byte "============================================================================",0ah,0ah
	introTextSize dword ($ - introText)

	message1 label byte
	byte "Enter left channel filepath: "
	message1Size dword ($ - message1)

	message2 label byte
	byte "Enter right channel filepath: "
	message2Size dword ($ - message2)
	
	message3 label byte
	byte "ERROR: Filepath doesn't exist!",0ah
	message3Size dword ($ - message3)

	message4 label byte
	byte "Enter output filepath: "
	message4Size dword ($ - message4)

	message5 label byte
	byte "ERROR: File can't be created",0ah
	message5Size dword ($ - message5)

	message6 label byte
	byte "Finished!",0ah,0ah
	message6Size dword ($ - message6)

.data?
	fileSize dword ?
	dataSize dword ?
	consoleInputHandle handle ?
	consoleOutputHandle handle ?
	lchFileHnd handle ?
	rchFileHnd handle ?
	outFileHnd handle ?
	lchFilepathSize dword ?
	rchFilepathSize dword ?
	outFilepathSize dword ?

	outBuff byte outBuffSize DUP(?) 
	in1Buff byte inBuffSize DUP(?)
	in2Buff byte inBuffSize DUP(?)
	
	lchFilepath byte maxPathLen DUP(?);Left channel filepath
	rchFilepath byte maxPathLen DUP(?);Right channel filepath
	outFilepath byte maxPathLen DUP(?);Output filepath
	
.code
populateOutBuff proc 
	;ecx = local counter
	;edx = how many bytes to move in output buffer
	push ecx
	push eax
	mov ecx, 0; initialising local counter
	lp: mov ax, [esi]
	mov [edi], ax
	add esi, 2
	add edi, 2
	mov ax, [ebx]
	mov [edi], ax
	add ebx, 2
	add edi, 2
	add ecx, 4
	cmp ecx, edx
	jne lp
	
	pop eax
	pop ecx
	ret
populateOutBuff endp

main proc
	invoke SetConsoleTitle, ADDR consoleTitle
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov consoleOutputHandle, eax
	invoke GetStdHandle, STD_INPUT_HANDLE
	mov consoleInputHandle, eax
	invoke WriteConsole, consoleOutputHandle, ADDR introtext, introtextSize, 0, 0

	;Opening left channel file
j1: invoke WriteConsole, consoleOutputHandle, ADDR message1, message1Size, 0, 0
	invoke ReadConsole, consoleInputHandle, ADDR lchFilepath, maxPathLen, ADDR lchFilepathSize, 0
	mov edx, offset lchFilepath
	mov ecx, lchFilepathSize
	mov esi, edx
	mov al, 0h
	;Inserting 0h string termination char
	mov [ecx+esi-2], al
	;Getting input file 1 handle
	call OpenInputFile
	mov lchFileHnd, eax
	cmp eax, INVALID_HANDLE_VALUE
	jne j2
	;Error msg
	invoke WriteConsole, consoleOutputHandle, ADDR message3, message3Size, 0, 0
	jmp j1

	;Opening right channel file
j2: invoke WriteConsole, consoleOutputHandle, ADDR message2, message2Size, 0, 0
	invoke ReadConsole, consoleInputHandle, ADDR rchFilepath, maxPathLen, ADDR rchFilepathSize, 0
	mov edx, offset rchFilepath
	mov ecx, rchFilepathSize
	mov esi, edx
	mov al, 0h
	;Inserting 0h string termination char
	mov [ecx+esi-2], al
	;Getting input file 1 handle
	call OpenInputFile
	mov rchFileHnd, eax
	cmp eax, INVALID_HANDLE_VALUE
	jne j3
	;Error msg
	invoke WriteConsole, consoleOutputHandle, ADDR message3, message3Size, 0, 0
	jmp j2

	;Creating output file
j3: invoke WriteConsole, consoleOutputHandle, ADDR message4, message4Size, 0, 0
	invoke ReadConsole, consoleInputHandle, ADDR outFilepath, maxPathLen, ADDR outFilepathSize, 0
	mov edx, offset outFilepath
	mov ecx, outFilepathSize
	mov esi, edx
	mov al, 0h
	;Inserting 0h string termination char
	mov [ecx+esi-2], al
	mov [ecx+esi-1], al
	call CreateOutputFile
	mov outFileHnd, eax
	cmp eax, INVALID_HANDLE_VALUE
	jne j4
	;Error msg
	invoke WriteConsole, consoleOutputHandle, ADDR message5, message5Size, 0, 0
	jmp j3

	;Writing file header to output file buffer
j4: mov edi, offset outBuff
	mov eax, riffConst
	mov [edi], eax
	add edi, 4;shifting buffer pointer
	mov eax, offset dataSize
	;Calculating file size
	invoke GetFileSize, lchFileHnd, 0
	mov dataSize, eax
	invoke GetFileSize, rchFileHnd, 0
	add eax, dataSize
	mov dataSize, eax
	add eax, 36; filesize = headersize + datasize - 8, headersize = 44-8 bytes, 8 bytes read already
	mov fileSize, eax
	mov [edi], eax ;writing fileSize to buffer
	add edi, 4
	mov eax, waveConst
	mov [edi], eax
	add edi, 4
	mov eax, formatChunkConst
	mov [edi], eax
	add edi, 4
	mov eax, 16;Length of format data
	mov [edi], eax; to output buffer byte 17-20
	add edi, 4
	mov ax, 1;value=1 for PCM format
	mov [edi], ax; to output buffer byte 21-22
	add edi, 2
	mov ax, channels; default value=2 channels
	mov [edi], ax 
	add edi, 2
	mov eax, sampleRate; default value 44100
	mov [edi], eax
	add edi, 4
	mov eax, byteRate
	mov [edi], eax
	add edi, 4
	mov ax, 4; bitrate*channels/8
	mov [edi], ax
	add edi, 2
	mov eax, sampleSize
	mov [edi], eax
	add edi, 2
	mov eax, dataConst
	mov [edi], eax
	add edi, 4
	mov eax, dataSize
	mov [edi], eax
	add edi, 4
	;Header is loaded in buffer
	;Writing header to file
	mov eax, outFileHnd
	mov edx, offset outBuff
	mov ecx, 44
	call WriteToFile
	;skipping header from input files
	invoke SetFilePointer, lchFileHnd, 44, 0, 0;moving file pointer to position 44
	invoke SetFilePointer, rchFileHnd, 44, 0, 0
	;Reading from input buffers
ld:	mov eax, lchFileHnd
	mov edx, offset in1Buff
	mov ecx, inBuffSize
	call ReadFromFile
	mov eax, rchFileHnd
	mov edx, offset in2Buff
	mov ecx, inBuffSize
	call ReadFromFile
	mov esi, offset in1Buff;reseting input buffer pointer
	mov ebx, offset in2Buff;
	mov edi, offset outBuff;reseting output buffer pointer
	cmp eax, inBuffSize
	jne eof
	mov edx, outBuffSize; input value for procedure populateOutBuff
	call populateOutBuff
	;writing output buffer to file
	mov eax, outFileHnd
	mov edx, offset outBuff
	mov ecx, outBuffSize
	call WriteToFile
	jmp ld
eof:mov edx,eax; eof-End of file label,  procedure populateOutBuff counter end value
	shl edx, 1 ;Output buffer is 2 times larger than input buffer
	call populateOutBuff

	;Writing output buffer to file
	mov eax, outFileHnd
	mov ecx, edx
	mov edx, offset outBuff
	call WriteToFile
	
	;Closing files
	mov eax, lchFileHnd
	call CloseFile
	mov eax, rchFileHnd
	call CloseFile
	mov eax, outFileHnd
	call CloseFile
	invoke WriteConsole, consoleOutputHandle, ADDR message6, message6Size, 0, 0
	
	invoke ExitProcess,0
main endp
end main