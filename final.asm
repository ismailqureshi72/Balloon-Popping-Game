[org 0x100]
jmp main_menu_start

VIDEO_SEG equ 0B800h
COLS      equ 80
ROWS      equ 25

TITLE_BLOCK_ATTR equ 0x75
MENU_TEXT_ATTR   equ 0x17
BG_COLOR         equ 0x10

opt1       db '               [1] Survival Mode',0
opt2       db '               [2] Endless Mode',0
opt3       db '               [3] Instructions',0
opt4       db '               [4] Exit',0
prompt     db '               Select an option (1-4):',0
msg_start  db '         Loading game... Get ready!',0
msg_instr1 db '      SURVIVAL: Type letters before bubbles escape! 3 lives, 2 mins',0
msg_instr2 db '      ENDLESS: No lives, no timer. How high can you score?',0
msg_instr3 db '              Correct key = +10 points. Press ESC to pause',0
msg_exit   db '       Thank you for playing GUBARAY!',0


GAMEOVER_BLOCK_ATTR equ 0xCC
TEXT_ATTR           equ 0x40

loopCounter: db 0
minutes: db 2
seconds: db 0
score: dw 0
lives: db 3

gameMode: db 0        ; 0 = Survival, 1 = Endless

balloon1_pos: dw 0
balloon1_prev: dw 0
balloon1_color: db 0x70
balloon1_letter: db 'A'

balloon2_pos: dw 0
balloon2_prev: dw 0
balloon2_color: db 0x60
balloon2_letter: db 'B'

balloon3_pos: dw 0
balloon3_prev: dw 0
balloon3_color: db 0x50
balloon3_letter: db 'C'

balloon4_pos: dw 0
balloon4_prev: dw 0
balloon4_color: db 0x40
balloon4_letter: db 'D'

balloon1_spawn: dw 3540
balloon2_spawn: dw 3580
balloon3_spawn: dw 3620
balloon4_spawn: dw 3660

spawnColumns: dw 3540, 3580, 3620, 3660

spawnCounter: db 0
balloon1_spawnDelay: db 0
balloon2_spawnDelay: db 0
balloon3_spawnDelay: db 0
balloon4_spawnDelay: db 0
randomSeed: dw 1234

balloon1_column: db 0
balloon2_column: db 0
balloon3_column: db 0
balloon4_column: db 0

timeMsg: db 'TIME: ', 0
scoreMsg: db 'SCORE: ', 0
livesMsg: db 'LIVES: ', 0

msg_score: db '                               Your Final Score:',0
msg_finalscore: db '                               '
score_text: db '0000 POINTS',0
msg_prompt: db '                    Press ESC key to return to main menu',0
msg_restart_hint db '            Press [R] to Restart Game  |  Press [Q] to Quit to Menu',0

PAUSE_BLOCK_ATTR  equ 0x74   ; Red text
PAUSE_OPTION_ATTR equ 0x7F   ; White text
PAUSE_HINT_ATTR   equ 0x73   ; Cyan text
PAUSE_BG_COLOR    equ 0x70


pause_opt1         db '             [R] Resume Game',0
pause_opt2         db '             [Q] Quit to Menu',0
pause_prompt       db '     Press R to continue or Q to quit',0
msg_resuming       db 'Resuming game...',0
msg_quitting       db 'Returning to menu...',0

oldISR: dd 0              ; Store old interrupt vector (segment:offset)
tickCounter: dw 0

timerISR:
    push ax

    inc word [tickCounter]

    cmp word [tickCounter], 18
    jl skipTimeUpdate

    mov word [tickCounter], 0

    cmp byte [seconds], 0
    jne decSecondsISR

    cmp byte [minutes], 0
    je skipTimeUpdate

    dec byte [minutes]
    mov byte [seconds], 59
    jmp skipTimeUpdate

decSecondsISR:
    dec byte [seconds]

skipTimeUpdate:
    pop ax

    jmp far [cs:oldISR]

main_menu_start:
    mov ax, VIDEO_SEG
    mov es, ax

menu_loop:
    call fill_cyan_background_menu
    call draw_gubara_blocks
    call draw_balloon
    call draw_menu_text
    call get_choice

    cmp al, '1'
    je start_survival_mode
    cmp al, '2'
    je start_endless_mode
    cmp al, '3'
    je show_instructions
    cmp al, '4'
    je exit_game
    jmp menu_loop

start_survival_mode:
    mov byte [gameMode], 0
    jmp start_game_jump

start_endless_mode:
    mov byte [gameMode], 1
    jmp start_game_jump

start_game_jump:
    ; Reset game variables before starting
    mov byte [minutes], 2
    mov byte [seconds], 00
    mov word [score], 0
    mov byte [lives], 3
    mov byte [loopCounter], 0

    ; Reset balloons
    mov word [balloon1_pos], 0
    mov word [balloon2_pos], 0
    mov word [balloon3_pos], 0
    mov word [balloon4_pos], 0
    mov word [balloon1_prev], 0
    mov word [balloon2_prev], 0
    mov word [balloon3_prev], 0
    mov word [balloon4_prev], 0

    jmp gameplay_start

show_instructions:
    call fill_purple_background
    mov ax, VIDEO_SEG
    mov es, ax

    mov ax, 80
    mov bl, 9
    mul bl
    add ax, 7
    shl ax, 1
    mov di, ax
    mov si, msg_instr1
    call draw_text_line_purple

    mov ax, 80
    mov bl, 10
    mul bl
    add ax, 7
    shl ax, 1
    mov di, ax
    mov si, msg_instr2
    call draw_text_line_purple

    mov ax, 80
    mov bl, 11
    mul bl
    add ax, 7
    shl ax, 1
    mov di, ax
    mov si, msg_instr3
    call draw_text_line_purple

wait_esc_loop:
    call wait_key_menu
    cmp al, 27
    jne wait_esc_loop
    jmp menu_loop


exit_game:
    push ds
    mov ah, 0x25
    mov al, 0x08
    lds dx, [oldISR]
    int 0x21
    pop ds

    call fill_exit_background
    mov ax, VIDEO_SEG
    mov es, ax

    mov ax, 80
    mov bl, 12
    mul bl
    add ax, 14
    shl ax, 1
    mov di, ax
    mov si, msg_exit
    call draw_text_line_exit

    call wait_key_menu
    mov ax, 0x4C00
    int 0x21

fill_exit_background:
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov ah, 0x4F
    mov al, 0x20
    mov cx, 2000
fill_exit_loop:
    mov [es:di], ax
    inc di
    inc di
    dec cx
    jnz fill_exit_loop
    ret

draw_text_line_exit:
    mov ah, 0x4F          ; Bright white text on bright red background
text_loop_exit:
    lodsb
    cmp al, 0
    je text_done_exit
    mov [es:di], ax
	add di,2
    jmp text_loop_exit
text_done_exit:
    ret
fill_red_background_gameover:
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov ah, GAMEOVER_BLOCK_ATTR
    mov al, 0x20
    mov cx, 2000
fill_loop_gameover:
    mov [es:di], ax
    inc di
    inc di
    dec cx
    jnz fill_loop_menu
    ret
fill_cyan_background_menu:
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov ah, BG_COLOR
    mov al, 0x20
    mov cx, 2000
fill_loop_menu:
    mov [es:di], ax
    inc di
    inc di
    dec cx
    jnz fill_loop_menu
    ret
fill_purple_background:
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov ah, 0x55
    mov al, 0x20
    mov cx, 2000
fill_purple_loop:
    mov [es:di], ax
    inc di
    inc di
    dec cx
    jnz fill_purple_loop
    ret

draw_text_line_purple:
    mov ah, 0x5F
text_loop_purple:
    lodsb
    cmp al, 0
    je text_done_purple
    mov [es:di], ax
	add di,2
    jmp text_loop_purple
text_done_purple:
    ret

draw_menu_text:
    mov ax, VIDEO_SEG
    mov es, ax

    mov di, 2400          ; Row 15
    mov si, opt1
    call draw_text_line_menu

    mov di, 2560          ; Row 16
    mov si, opt2
    call draw_text_line_menu

    mov di, 2720          ; Row 17
    mov si, opt3
    call draw_text_line_menu

    mov di, 2880          ; Row 18
    mov si, opt4
    call draw_text_line_menu

    mov di, 3200          ; Row 20
    mov si, prompt
    call draw_text_line_menu
    ret
draw_text_line_menu:
    mov ah, MENU_TEXT_ATTR
text_loop_menu:
    lodsb
    cmp al, 0
    je text_done_menu
    mov [es:di], ax
	add di,2
    jmp text_loop_menu
text_done_menu:
    ret

clear_screen_black:
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov cx, 2000
    mov ax, 0x0020
clear_loop:
    mov [es:di], ax
    inc di
    inc di
    dec cx
    jnz clear_loop
    ret

draw_balloon:
    pusha

    mov ax ,0xb800
    mov es , ax

    mov di , 1094
    mov word [es:di] , 0x0BDB
    mov word [es:di+2] , 0x0BDB
    mov word [es:di+4] , 0x0BDB
    mov word [es:di+6] , 0x0BDB

    add di , 160
    sub di , 4
    mov word [es:di] , 0x0BDB
    mov word [es:di+2] , 0x0BDB
    mov word [es:di+4] , 0x0BDB
    mov word [es:di+6] , 0x0BDB
    mov word [es:di+8] , 0x0BDB
    mov word [es:di+10] , 0x0BDB
    mov word [es:di+12] , 0x0BDB
    mov word [es:di+14] , 0x0BDB

    add di , 160
    sub di , 4
    mov word [es:di] , 0x0BDB
    mov word [es:di+2] , 0x0BDB
    mov word [es:di+4] , 0x0BDB
    mov word [es:di+6] , 0x0BDB
    mov word [es:di+8] , 0x0BDB
    mov word [es:di+10] , 0x0BDB
    mov word [es:di+12] , 0x0BDB
    mov word [es:di+14] , 0x0BDB
    mov word [es:di+16] , 0x0BDB
    mov word [es:di+18] , 0x0BDB
    mov word [es:di+20] , 0x0BDB
    mov word [es:di+22] , 0x0BDB

    ; 50 48 4F 52 44 4F

    add di , 160
    mov word [es:di] , 0x0BDB
    mov word [es:di+2] , 0x0BDB
    mov word [es:di+4] , 0x0B54
    mov word [es:di+6] , 0x0B59
    mov word [es:di+8] , 0x0B50
    mov word [es:di+10] , 0x0B45
    mov word [es:di+12] , 0x0BDB
    mov word [es:di+14] , 0x0BDB
    mov word [es:di+16] , 0x0B54
    mov word [es:di+18] , 0x0B4F
    mov word [es:di+20] , 0x0BDB
    mov word [es:di+22] , 0x0BDB

    add di , 160
    mov word [es:di] , 0x0BDB
    mov word [es:di+2] , 0x0BDB
    mov word [es:di+4] , 0x0BDB
    mov word [es:di+6] , 0x0BDB
    mov word [es:di+8] , 0x0BDB
    mov word [es:di+10] , 0x0450
    mov word [es:di+12] , 0x044F
    mov word [es:di+14] , 0x0450
    mov word [es:di+16] , 0x0BDB
    mov word [es:di+18] , 0x0BDB
    mov word [es:di+20] , 0x0BDB
    mov word [es:di+22] , 0x0BDB

    add di , 160
    mov word [es:di] , 0x0BDB
    mov word [es:di+2] , 0x0BDB
    mov word [es:di+4] , 0x0BDB
    mov word [es:di+6] , 0x0BDB
    mov word [es:di+8] , 0x0BDB
    mov word [es:di+10] , 0x0BDB
    mov word [es:di+12] , 0x0BDB
    mov word [es:di+14] , 0x0BDB
    mov word [es:di+16] , 0x0BDB
    mov word [es:di+18] , 0x0BDB
    mov word [es:di+20] , 0x0BDB
    mov word [es:di+22] , 0x0BDB

    add di , 160
    add di , 4
    mov word [es:di] , 0x0BDB
    mov word [es:di+2] , 0x0BDB
    mov word [es:di+4] , 0x0BDB
    mov word [es:di+6] , 0x0BDB
    mov word [es:di+8] , 0x0BDB
    mov word [es:di+10] , 0x0BDB
    mov word [es:di+12] , 0x0BDB
    mov word [es:di+14] , 0x0BDB

    add di , 160
    add di , 4
    mov word [es:di] , 0x0BDB
    mov word [es:di+2] , 0x0BDB
    mov word [es:di+4] , 0x0BDB
    mov word [es:di+6] , 0x0BDB

    add di , 162
    mov word [es:di] , 0x0BDB
    mov word [es:di+2] , 0x0BDB

    add di , 160
    mov word [es:di-2+160] , 0x1B07
    mov word [es:di+2] , 0x1B07
    mov word [es:di+2+320] , 0x1B07
    mov word [es:di+480] , 0x1B07

    mov word [es:di-2+640] , 0x1B07
    mov word [es:di+800] , 0x1B07

    popa
    ret

draw_gubara_blocks:
    mov ax, VIDEO_SEG
    mov es, ax
    mov ax, 0x0BDB

    ; letter G (col 15-19)
    mov di, 990
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax

    mov di, 1150
    mov [es:di], ax

    mov di, 1310
    mov [es:di], ax
    mov di, 1316
    mov [es:di], ax
    mov di, 1318
    mov [es:di], ax

    mov di, 1470
    mov [es:di], ax
    mov di, 1478
    mov [es:di], ax

    mov di, 1630
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    ; letter U (col 21-25)
    mov di, 1002
    mov [es:di], ax
    mov di, 1010
    mov [es:di], ax

    mov di, 1162
    mov [es:di], ax
    mov di, 1170
    mov [es:di], ax

    mov di, 1322
    mov [es:di], ax
    mov di, 1330
    mov [es:di], ax

    mov di, 1482
    mov [es:di], ax
    mov di, 1490
    mov [es:di], ax

    mov di, 1642
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax

    ; letter B (col 27-31)
    mov di, 1014
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax

    mov di, 1174
    mov [es:di], ax
    mov di, 1182
    mov [es:di], ax

    mov di, 1334
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax

    mov di, 1494
    mov [es:di], ax
    mov di, 1502
    mov [es:di], ax

    mov di, 1654
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax

    ; letter A (col 33-37)
    mov di, 1026
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax

    mov di, 1186
    mov [es:di], ax
    mov di, 1194
    mov [es:di], ax

    mov di, 1346
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax
    add di,2
    mov [es:di], ax

    mov di, 1506
    mov [es:di], ax
    mov di, 1514
    mov [es:di], ax

    mov di, 1666
    mov [es:di], ax
    mov di, 1674
    mov [es:di], ax

    ;letter R (col 39-43)
    mov di, 1038
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1198
    mov [es:di], ax
    mov di, 1206
    mov [es:di], ax

    mov di, 1358
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1518
    mov [es:di], ax
    mov di, 1526
    mov [es:di], ax

    mov di, 1678
    mov [es:di], ax
    mov di, 1686
    mov [es:di], ax

    ; Letter A (col 45-49)
    mov di, 1050
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1210
    mov [es:di], ax
    mov di, 1218
    mov [es:di], ax

    mov di, 1370
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1530
    mov [es:di], ax
    mov di, 1538
    mov [es:di], ax

    mov di, 1690
    mov [es:di], ax
    mov di, 1698
    mov [es:di], ax

    ; Letter Y (col 51-55)
    mov di, 1062
    mov [es:di], ax
    mov di, 1070
    mov [es:di], ax

    mov di, 1222
    mov [es:di], ax
    mov di, 1230
    mov [es:di], ax

    mov di, 1384
    mov [es:di], ax
    mov di, 1388
    mov [es:di], ax

    mov di, 1546
    mov [es:di], ax

    mov di, 1706
    mov [es:di], ax

    ret

wait_key_menu:
    mov ah, 0
    int 0x16
    ret

get_choice:
    mov ah, 0
    int 0x16
    ret
; GAMEPLAY SECTION

; Play a short "pop" sound using PC speaker
playPopSound:
    push ax
    push bx
    push cx
    push dx

    ; Program PIT channel 2 for ~2000 Hz
    mov al, 0B6h        ; Control word: channel 2, mode 3 (square wave)
    out 43h, al

    mov ax, 1193180/2000 ; Divisor for ~2000 Hz
    out 42h, al          ; Low byte
    mov al, ah
    out 42h, al          ; High byte

    ; Enable speaker
    in al, 61h
    or al, 3
    out 61h, al

    ; Short delay (keeps tone on briefly)
    mov cx, 3000
popDelayLoop:
    loop popDelayLoop

    ; Disable speaker
    in al, 61h
    and al, 0FCh
    out 61h, al

    pop dx
    pop cx
    pop bx
    pop ax
    ret

playMelody:
    push ax
    push bx
    push cx
    push dx

    mov cx, 2
melodyLoop:
    ; Note 1: D3 (low)
    mov al, 0B6h
    out 43h, al
    mov ax, 1FB4h; D3 frequency
    out 42h, al
    mov al, ah
    out 42h, al

    in al, 61h
    mov ah, al
    or al, 3
    out 61h, al
    call melodyDelay
    mov al, ah
    out 61h, al
    call melodyDelay

    ; === Note 2: A3 (mid) ===
    mov ax, 152Fh          ; A3 frequency
    out 42h, al
    mov al, ah
    out 42h, al

    in al, 61h
    mov ah, al
    or al, 3
    out 61h, al
    call melodyDelay
    mov al, ah
    out 61h, al
    call melodyDelay

    ; === Note 3: A4 (high) ===
    mov ax, 0A97h          ; A4 frequency
    out 42h, al
    mov al, ah
    out 42h, al

    in al, 61h
    mov ah, al
    or al, 3
    out 61h, al
    call melodyDelay
    mov al, ah
    out 61h, al
    call melodyDelay

    loop melodyLoop

    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Delay for melody notes
melodyDelay:
    push cx
    mov cx, 0xFFFF
melodyDelayLoop:
    loop melodyDelayLoop
    pop cx
    ret

gameplay_start:
    ; Initialize spawn delays
    mov byte [balloon1_spawnDelay], 2
    mov byte [balloon2_spawnDelay], 6
    mov byte [balloon3_spawnDelay], 8
    mov byte [balloon4_spawnDelay], 10

    mov byte [balloon1_column], 0xFF
    mov byte [balloon2_column], 0xFF
    mov byte [balloon3_column], 0xFF
    mov byte [balloon4_column], 0xFF

    ; HOOK TIMER INTERRUPT
    ; Save old INT 08h vector
    push es
    mov ah, 0x35        ; Get interrupt vector
    mov al, 0x08        ; INT 08h
    int 0x21            ; Returns ES:BX = old vector
    mov [oldISR], bx    ; Save offset
    mov [oldISR+2], es  ; Save segment
    pop es

    push ds
    mov ah, 0x25        ; Set interrupt vector
    mov al, 0x08        ; INT 08h
    mov dx, timerISR    ; Our handler
    int 0x21
    pop ds

    mov word [tickCounter], 0

    call clscrn
    call displayUI
    jmp gameLoop

displayUI:
    push ax

    cmp byte [gameMode], 1
    je displayEndlessUI

    push 0
    push 2
    push timeMsg
    call printString

    push 0
    push 30
    push livesMsg
    call printString

    push 0
    push 62
    push scoreMsg
    call printString

    push 0
    push 69
    push word [score]
    call displayScore

    push 0
    push 37
    xor ax, ax
    mov al, [lives]
    push ax
    call displayScore

    push 0
    push 8
    call displayTime

    pop ax
    ret

displayEndlessUI:
    push 0
    push 35
    push scoreMsg
    call printString

    ; Display score
    push 0
    push 42
    push word [score]
    call displayScore

displayUIDone:
    pop ax
    ret

gameLoop:
    cmp byte [gameMode], 1
    je skipGameOverChecks

    ; Check if lives are 0
    cmp byte [lives], 0
    je gameOver

    ; Check if time is 0
    cmp byte [minutes], 0
    jne continueGame
    cmp byte [seconds], 0
    je gameOver
skipGameOverChecks:
continueGame:
    ; Move balloons and spawn new ones
    call moveBalloons

    ; Check for key press
    call checkKeyPress

    ; Draw all active balloons
    call drawBalloon1
    call drawBalloon2
    call drawBalloon3
    call drawBalloon4

    call displayUI

    call halfSecondDelay

    jmp gameLoop


decSeconds:
    dec byte [seconds]
    jmp gameLoop

gameOver:
    push ds
    mov ah, 0x25        ; Set interrupt vector
    mov al, 0x08        ; INT 08h
    lds dx, [oldISR]    ; Load old vector
    int 0x21
    pop ds

	call playMelody

    call fill_red_background_gameover
    call draw_gameover_blocks
    call updateScoreMessage
    call draw_score_text
    call draw_restart_options
    jmp gameOverWaitKey

gameOverWaitKey:
    call wait_key

    cmp al, 'r'
    je restartGameFromGameOver
    cmp al, 'R'
    je restartGameFromGameOver
    cmp al, 'q'
    je quitToMenuFromGameOver
    cmp al, 'Q'
    je quitToMenuFromGameOver

    jmp gameOverWaitKey

restartGameFromGameOver:

    mov byte [minutes], 2
    mov byte [seconds], 0
    mov word [score], 0
    mov byte [lives], 3
    mov byte [loopCounter], 0

    ; Reset balloons
    mov word [balloon1_pos], 0
    mov word [balloon2_pos], 0
    mov word [balloon3_pos], 0
    mov word [balloon4_pos], 0
    mov word [balloon1_prev], 0
    mov word [balloon2_prev], 0
    mov word [balloon3_prev], 0
    mov word [balloon4_prev], 0

    ; Reset spawn delays
    mov byte [balloon1_spawnDelay], 2
    mov byte [balloon2_spawnDelay], 6
    mov byte [balloon3_spawnDelay], 8
    mov byte [balloon4_spawnDelay], 10

    ; Mark columns as free
    mov byte [balloon1_column], 0xFF
    mov byte [balloon2_column], 0xFF
    mov byte [balloon3_column], 0xFF
    mov byte [balloon4_column], 0xFF

    ; RE-HOOK TIMER INTERRUPT
    push es
    mov ah, 0x35
    mov al, 0x08
    int 0x21
    mov [oldISR], bx
    mov [oldISR+2], es
    pop es

    push ds
    mov ah, 0x25
    mov al, 0x08
    mov dx, timerISR
    int 0x21
    pop ds

    ; Reset tick counter
    mov word [tickCounter], 0

    ; Start game
    call clscrn
    call displayUI
    jmp gameLoop

quitToMenuFromGameOver:
    push ds
    mov ah, 0x25
    mov al, 0x08
    lds dx, [oldISR]
    int 0x21
    pop ds

    jmp main_menu_start


draw_restart_options:
    push ax
    push es

    mov ax, VIDEO_SEG
    mov es, ax

    mov di, 3200
    mov si, msg_restart_hint
    call draw_text_line_gameover

    pop es
    pop ax
    ret

draw_text_line_gameover:
    push ax
    mov ah, 0x4F          ; Bright white on red
text_loop_gameover:
    lodsb
    cmp al, 0
    je text_done_gameover
    mov [es:di], ax
    add di, 2
    jmp text_loop_gameover
text_done_gameover:
    pop ax
    ret

updateScoreMessage:
    push ax
    push bx
    push cx
    push dx

    mov ax, [score]
    mov bx, 10

    xor dx, dx
    div bx
    push dx          ; ones digit

    xor dx, dx
    div bx
    push dx          ; tens digit

    xor dx, dx
    div bx
    push dx          ; hundreds digit

    xor dx, dx
    div bx
    push dx          ; thousands digit

    ; Write thousands
    pop ax
    add al, '0'
    mov [score_text], al

    ; Write hundreds
    pop ax
    add al, '0'
    mov [score_text+1], al

    ; Write tens
    pop ax
    add al, '0'
    mov [score_text+2], al

    ; Write ones
    pop ax
    add al, '0'
    mov [score_text+3], al

    pop dx
    pop cx
    pop bx
    pop ax
    ret

fill_cyan_background:
    push ax
    push cx
    push di
    push es

    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov ah, BG_COLOR
    mov al, 0x20
    mov cx, 2000
fill_loop_gameplay:
    mov [es:di], ax
    add di, 2
    dec cx
    jnz fill_loop_gameplay

    pop es
    pop di
    pop cx
    pop ax
    ret

draw_score_text:
    push ax
    push es

    mov ax, VIDEO_SEG
    mov es, ax

    ; Line for "Your Final Score"
    mov di, 2880
    mov si, msg_score
    call draw_text_line

    ; Line for numeric score
    mov di, 3040
    mov si, msg_finalscore
    call draw_text_line

    pop es
    pop ax
    ret

draw_text_line:
    push ax
    mov ah, TEXT_ATTR
text_loop_gameplay:
    lodsb
    cmp al, 0
    je text_done_gameplay
    mov [es:di], ax
    add di, 2
    jmp text_loop_gameplay
text_done_gameplay:
    pop ax
    ret

wait_key:
    mov ah, 0
    int 0x16
    ret

draw_gameover_blocks:
    push ax
    push di
    push es

    mov ax, VIDEO_SEG
    mov es, ax
    mov ax, 0xCC00
    or al, 0xDB

    ; G
    mov di, 1300
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1460
    mov [es:di], ax

    mov di, 1620
    mov [es:di], ax
    mov di, 1626
    mov [es:di], ax
    mov di, 1628
    mov [es:di], ax

    mov di, 1780
    mov [es:di], ax
    mov di, 1788
    mov [es:di], ax

    mov di, 1940
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    ; A
    mov di, 1312
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1472
    mov [es:di], ax
    mov di, 1480
    mov [es:di], ax

    mov di, 1632
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1792
    mov [es:di], ax
    mov di, 1800
    mov [es:di], ax

    mov di, 1952
    mov [es:di], ax
    mov di, 1960
    mov [es:di], ax

    ; M
    mov di, 1324
    mov [es:di], ax
    mov di, 1336
    mov [es:di], ax

    mov di, 1484
    mov [es:di], ax
    mov di, 1486
    mov [es:di], ax
    mov di, 1494
    mov [es:di], ax
    mov di, 1496
    mov [es:di], ax

    mov di, 1644
    mov [es:di], ax
    mov di, 1648
    mov [es:di], ax
    mov di, 1650
    mov [es:di], ax
    mov di, 1652
    mov [es:di], ax
    mov di, 1656
    mov [es:di], ax

    mov di, 1804
    mov [es:di], ax
    mov di, 1816
    mov [es:di], ax

    mov di, 1964
    mov [es:di], ax
    mov di, 1976
    mov [es:di], ax

    ; E
    mov di, 1340
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1500
    mov [es:di], ax

    mov di, 1660
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1820
    mov [es:di], ax

    mov di, 1980
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    ; O
    mov di, 1360
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1520
    mov [es:di], ax
    mov di, 1528
    mov [es:di], ax

    mov di, 1680
    mov [es:di], ax
    mov di, 1688
    mov [es:di], ax

    mov di, 1840
    mov [es:di], ax
    mov di, 1848
    mov [es:di], ax

    mov di, 2000
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    ; V
    mov di, 1372
    mov [es:di], ax
    mov di, 1380
    mov [es:di], ax

    mov di, 1532
    mov [es:di], ax
    mov di, 1540
    mov [es:di], ax

    mov di, 1692
    mov [es:di], ax
    mov di, 1700
    mov [es:di], ax

    mov di, 1854
    mov [es:di], ax
    mov di, 1858
    mov [es:di], ax

    mov di, 2016
    mov [es:di], ax

    ; E (second E)
    mov di, 1384
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1544
    mov [es:di], ax

    mov di, 1704
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1864
    mov [es:di], ax

    mov di, 2024
    mov [es:di], ax
    mov di, 2026
    mov [es:di], ax
    mov di, 2028
    mov [es:di], ax
    mov di, 2030
    mov [es:di], ax

    ; R
    mov di, 1396
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1556
    mov [es:di], ax
    mov di, 1564
    mov [es:di], ax

    mov di, 1716
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax
    add di, 2
    mov [es:di], ax

    mov di, 1876
    mov [es:di], ax
    mov di, 1884
    mov [es:di], ax

    mov di, 2036
    mov [es:di], ax
    mov di, 2044
    mov [es:di], ax

    pop es
    pop di
    pop ax
    ret

; Add 10 to score
addScore:
    push ax
    mov ax, [score]
    add ax, 10
    mov [score], ax
    pop ax
    ret

; Decrement lives
decLives:
    push ax
    cmp byte [lives], 0
    je skipDecLives
    dec byte [lives]
skipDecLives:
    pop ax
    ret

; Simple random number generator
getRandomLetter:
    push bx
    push cx
    push dx

    ; Mix in system timer for better randomness
    mov ah, 0
    int 0x1A              ; Get timer ticks in CX:DX
    xor [randomSeed], dx  ; Mix with current seed

    mov ax, [randomSeed]
    rol ax, 1
    xor ax, 0x8405
    add ax, dx            ; Add timer for more entropy
    mov [randomSeed], ax

    mov bx, 26
    xor dx, dx
    div bx
    mov ax, dx

    add al, 'A'

    pop dx
    pop cx
    pop bx
    ret


getRandomColumn:
    push bx
    push cx
    push dx

    mov cx, 10          ; Try up to 10 times to find a free column

findColumn:
    ; Generate random column (0-3)
    mov ax, [randomSeed]
    rol ax, 1
    xor ax, 0x8405
    mov [randomSeed], ax

    mov bx, 4
    xor dx, dx
    div bx              ; DX = 0–3 (column index)
    mov dl, dl          ; DL = column index (0–3)

    ; Check if this column is CURRENTLY IN USE
    cmp dl, [balloon1_column]
    je columnUsed
    cmp dl, [balloon2_column]
    je columnUsed
    cmp dl, [balloon3_column]
    je columnUsed
    cmp dl, [balloon4_column]
    je columnUsed

    ; Column is FREE - use it
    mov bx, dx          ; BX = column index
    shl bx, 1           ; word offset
    mov ax, [spawnColumns + bx]   ; AX = spawn position
    jmp columnFound

columnUsed:
    loop findColumn

    ; If all 10 attempts fail, just use column 0
    mov ax, [spawnColumns]
    mov dl, 0

columnFound:
    pop dx
    pop cx
    pop bx
    ret

getRandomDelay:
    push bx
    push dx

    mov ax, [randomSeed]
    rol ax, 1
    xor ax, 0x8405
    mov [randomSeed], ax

    mov bx, 5          ; Range of 5 values
    xor dx, dx
    div bx
    mov ax, dx         ; AX = 0-4
    add al, 2          ; AL = 2-6

    pop dx
    pop bx
    ret

isPositionOccupied:
    push ax
    push bx
    push cx

    mov bx, ax
    xor dx, dx

    ; 14 rows minimum spacing:
    ; 5 rows for balloon + 4 row gap + 5 rows for next balloon = 14 rows
    ; 14 * 160 = 2240 bytes

    ; Check balloon 1
    mov ax, [balloon1_pos]
    cmp ax, 0
    je checkPos2

    mov cx, ax
    sub cx, bx
    jns abs1_positive
    neg cx
abs1_positive:
    cmp cx, 2240          ; 14 rows apart
    jl occupied

checkPos2:
    mov ax, [balloon2_pos]
    cmp ax, 0
    je checkPos3

    mov cx, ax
    sub cx, bx
    jns abs2_positive
    neg cx
abs2_positive:
    cmp cx, 2240
    jl occupied

checkPos3:
    mov ax, [balloon3_pos]
    cmp ax, 0
    je checkPos4

    mov cx, ax
    sub cx, bx
    jns abs3_positive
    neg cx
abs3_positive:
    cmp cx, 2240
    jl occupied

checkPos4:
    mov ax, [balloon4_pos]
    cmp ax, 0
    je notOccupied

    mov cx, ax
    sub cx, bx
    jns abs4_positive
    neg cx
abs4_positive:
    cmp cx, 2240
    jl occupied

notOccupied:
    xor dx, dx            ; means not occupied
    jmp done_check

occupied:
    mov dx, 1             ;  means occupied

done_check:
    pop cx
    pop bx
    pop ax
    ret

getRandomBalloon:
    push bx
    push dx

    mov ax, [randomSeed]
    rol ax, 1
    xor ax, 0x8405
    mov [randomSeed], ax

    mov bx, 4
    xor dx, dx
    div bx
    mov ax, dx      ; AX now has 0-3
    inc ax          ; AX now has 1-4

    pop dx
    pop bx
    ret


; Move all balloons upward
moveBalloons:
    push ax

    ; Try to spawn balloon 1
    cmp byte [balloon1_spawnDelay], 0
    jne skipSpawn1
    cmp word [balloon1_pos], 0
    jne resetDelay1
    call spawnBalloon1
    call getRandomDelay
    mov [balloon1_spawnDelay], al
    jmp skipSpawn1
resetDelay1:
    mov byte [balloon1_spawnDelay], 3  ; Try again in 1.5 seconds
skipSpawn1:

    ; Try to spawn balloon 2
    cmp byte [balloon2_spawnDelay], 0
    jne skipSpawn2
    cmp word [balloon2_pos], 0
    jne resetDelay2
    call spawnBalloon2
    call getRandomDelay
    mov [balloon2_spawnDelay], al
    jmp skipSpawn2
resetDelay2:
    mov byte [balloon2_spawnDelay], 3
skipSpawn2:

    ; Try to spawn balloon 3
    cmp byte [balloon3_spawnDelay], 0
    jne skipSpawn3
    cmp word [balloon3_pos], 0
    jne resetDelay3
    call spawnBalloon3
    call getRandomDelay
    mov [balloon3_spawnDelay], al
    jmp skipSpawn3
resetDelay3:
    mov byte [balloon3_spawnDelay], 3
skipSpawn3:

    ; Try to spawn balloon 4
    cmp byte [balloon4_spawnDelay], 0
    jne skipSpawn4
    cmp word [balloon4_pos], 0
    jne resetDelay4
    call spawnBalloon4
    call getRandomDelay
    mov [balloon4_spawnDelay], al
    jmp skipSpawn4
resetDelay4:
    mov byte [balloon4_spawnDelay], 3
skipSpawn4:

    ; Decrement all delays (do this AFTER checking)
    cmp byte [balloon1_spawnDelay], 0
    je skipDec1
    dec byte [balloon1_spawnDelay]
skipDec1:

    cmp byte [balloon2_spawnDelay], 0
    je skipDec2
    dec byte [balloon2_spawnDelay]
skipDec2:

    cmp byte [balloon3_spawnDelay], 0
    je skipDec3
    dec byte [balloon3_spawnDelay]
skipDec3:

    cmp byte [balloon4_spawnDelay], 0
    je skipDec4
    dec byte [balloon4_spawnDelay]
skipDec4:

    ; Move balloon 1
    mov ax, [balloon1_pos]
    cmp ax, 0
    je skip1
    mov [balloon1_prev], ax
    sub word [balloon1_pos], 160
    cmp word [balloon1_pos], 320
    jge skip1
    call decLives
	call clearBalloon1
    mov word [balloon1_pos], 0
	mov word [balloon1_prev] , 0
	mov byte [balloon1_column], 0xFF

skip1:
    ; Move balloon 2
    mov ax, [balloon2_pos]
    cmp ax, 0
    je skip2
    mov [balloon2_prev], ax
    sub word [balloon2_pos], 160
    cmp word [balloon2_pos], 320
    jge skip2
    call decLives
	call clearBalloon2
    mov word [balloon2_pos], 0
	mov word [balloon2_prev] , 0
	mov byte [balloon2_column], 0xFF

skip2:
    ; Move balloon 3
    mov ax, [balloon3_pos]
    cmp ax, 0
    je skip3
    mov [balloon3_prev], ax
    sub word [balloon3_pos], 160
    cmp word [balloon3_pos], 320
    jge skip3
    call decLives
	call clearBalloon3
    mov word [balloon3_pos], 0
	mov word [balloon3_prev], 0
	mov byte [balloon3_column], 0xFF

skip3:
    ; Move balloon 4
    mov ax, [balloon4_pos]
    cmp ax, 0
    je skip4
    mov [balloon4_prev], ax
    sub word [balloon4_pos], 160
    cmp word [balloon4_pos], 320
    jge skip4
    call decLives
	call clearBalloon4
    mov word [balloon4_pos], 0
	mov word [balloon4_prev], 0
	mov byte [balloon4_column], 0xFF

skip4:
    pop ax
    ret

spawnBalloon1:
    push ax

    cmp word [balloon1_pos], 0
    jne spawnDone1

    call getRandomLetter
    mov [balloon1_letter], al
    mov ax, [spawnColumns]          ; Column 0 (position 0 in array)
    mov [balloon1_pos], ax
    mov [balloon1_prev], ax
    mov byte [balloon1_column], 0   ; Column index 0

spawnDone1:
    pop ax
    ret

spawnBalloon2:
    push ax

    cmp word [balloon2_pos], 0
    jne spawnDone2

    call getRandomLetter
    mov [balloon2_letter], al
    mov ax, [spawnColumns + 2]      ; Column 1 (position 1 in array)
    mov [balloon2_pos], ax
    mov [balloon2_prev], ax
    mov byte [balloon2_column], 1   ; Column index 1

spawnDone2:
    pop ax
    ret

spawnBalloon3:
    push ax

    cmp word [balloon3_pos], 0
    jne spawnDone3

    call getRandomLetter
    mov [balloon3_letter], al
    mov ax, [spawnColumns + 4]      ; Column 2 (position 2 in array)
    mov [balloon3_pos], ax
    mov [balloon3_prev], ax
    mov byte [balloon3_column], 2   ; Column index 2

spawnDone3:
    pop ax
    ret

spawnBalloon4:
    push ax

    cmp word [balloon4_pos], 0
    jne spawnDone4

    call getRandomLetter
    mov [balloon4_letter], al
    mov ax, [spawnColumns + 6]      ; Column 3 (position 3 in array)
    mov [balloon4_pos], ax
    mov [balloon4_prev], ax
    mov byte [balloon4_column], 3   ; Column index 3

spawnDone4:
    pop ax
    ret

checkKeyPress:
    push ax
    push bx
    push cx
    push di
    push es

    mov ah, 1
    int 16h
    jz noKey

    mov ah, 0
    int 16h

    cmp al, 27          ; ESC key
    je pauseGame

    cmp al, 'a'
    jl checkUpper
    cmp al, 'z'
    jg checkUpper
    sub al, 32

checkUpper:
    mov bl, al

    ; Check balloon 1
    cmp bl, [balloon1_letter]
    jne checkB2
    cmp word [balloon1_pos], 0
    je checkB2

    ; CLEAR balloon 1 before removing it
    call clearBalloon1
	call playPopSound
    mov word [balloon1_pos], 0
    mov word [balloon1_prev], 0
	mov byte [balloon1_column], 0xFF
    call addScore
    jmp noKey

checkB2:
    cmp bl, [balloon2_letter]
    jne checkB3
    cmp word [balloon2_pos], 0
    je checkB3

    ; CLEAR balloon 2 before removing it
    call clearBalloon2
	call playPopSound
    mov word [balloon2_pos], 0
    mov word [balloon2_prev], 0
	mov byte [balloon2_column], 0xFF
    call addScore
    jmp noKey

checkB3:
    cmp bl, [balloon3_letter]
    jne checkB4
    cmp word [balloon3_pos], 0
    je checkB4

    ; CLEAR balloon 3 before removing it
    call clearBalloon3
	call playPopSound
    mov word [balloon3_pos], 0
    mov word [balloon3_prev], 0
	mov byte [balloon3_column], 0xFF
    call addScore
    jmp noKey

checkB4:
    cmp bl, [balloon4_letter]
    jne noKey
    cmp word [balloon4_pos], 0
    je noKey

    ; CLEAR balloon 4 before removing it
    call clearBalloon4
	call playPopSound
    mov word [balloon4_pos], 0
    mov word [balloon4_prev], 0
	mov byte [balloon4_column], 0xFF
    call addScore

noKey:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; PAUSE GAME HANDLER
pauseGame:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ; Game is now paused, jump to pause screen
    jmp pause_screen_start

clearBalloon1:
    push ax
    push bx
    push cx
    push di
    push es

    mov ax, 0b800h
    mov es, ax
    mov bx, [balloon1_prev]  ; Save starting position in BX
    cmp bx, 0
    je clearB1Done

    mov al, ' '
    mov ah, 0x31
    mov cx, 5              ; 5 rows to clear

clearB1Loop:
    mov di, bx             ; Reset to start of current row
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    mov word [es:di+6], ax
    mov word [es:di+8], ax
    add bx, 160            ; Move BX to next row
    loop clearB1Loop

clearB1Done:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Clear balloon 2 from screen
clearBalloon2:
    push ax
    push bx
    push cx
    push di
    push es

    mov ax, 0b800h
    mov es, ax
    mov bx, [balloon2_prev]
    cmp bx, 0
    je clearB2Done

    mov al, ' '
    mov ah, 0x31
    mov cx, 5

clearB2Loop:
    mov di, bx
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    mov word [es:di+6], ax
    mov word [es:di+8], ax
    add bx, 160
    loop clearB2Loop

clearB2Done:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Clear balloon 3 from screen
clearBalloon3:
    push ax
    push bx
    push cx
    push di
    push es

    mov ax, 0b800h
    mov es, ax
    mov bx, [balloon3_prev]
    cmp bx, 0
    je clearB3Done

    mov al, ' '
    mov ah, 0x31
    mov cx, 5

clearB3Loop:
    mov di, bx
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    mov word [es:di+6], ax
    mov word [es:di+8], ax
    add bx, 160
    loop clearB3Loop

clearB3Done:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Clear balloon 4 from screen
clearBalloon4:
    push ax
    push bx
    push cx
    push di
    push es

    mov ax, 0b800h
    mov es, ax
    mov bx, [balloon4_prev]
    cmp bx, 0
    je clearB4Done

    mov al, ' '
    mov ah, 0x31
    mov cx, 5

clearB4Loop:
    mov di, bx
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    mov word [es:di+6], ax
    mov word [es:di+8], ax
    add bx, 160
    loop clearB4Loop

clearB4Done:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

drawBalloon1:
    push ax
    push bx
    push cx
    push di
    push es

    mov ax, 0b800h
    mov es, ax

    ; Clear previous position
    mov di, [balloon1_prev]
    cmp di, 0
    je skipClear1
    cmp di, [balloon1_pos]
    je skipClear1

    mov al, ' '
    mov ah, 0x31
    mov cx, 5

clearRow1:
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    mov word [es:di+6], ax
    mov word [es:di+8], ax
    add di, 160
    loop clearRow1

skipClear1:
    mov di, [balloon1_pos]
    cmp di, 0
    je drawDone1

    mov ah, 0x4F  ; Light gray
    mov al, 0xDB

    ; Row 1: Top border (3 wide)
    add di, 2
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    sub di, 2
    add di, 160

    ; Row 2: Left and right borders only
    mov word [es:di], ax                    ; Left border
    mov word [es:di+2], 0x3120              ; Hollow (cyan background)
    mov word [es:di+4], 0x3120              ; Hollow
    mov word [es:di+6], 0x3120              ; Hollow
    mov word [es:di+8], ax                  ; Right border
    add di, 160

    ; Row 3: Middle with letter (left border, letter, right border)
    mov word [es:di], ax                    ; Left border
    mov word [es:di+2], 0x3120              ; Hollow
    mov bl, [balloon1_letter]
    mov bh, 0x6E                            ; BLACK letter on YELLOW
    mov word [es:di+4], bx                  ; Letter in center
    mov word [es:di+6], 0x3120              ; Hollow
    mov word [es:di+8], ax                  ; Right border
    add di, 160

    ; Row 4: Left and right borders only
    mov word [es:di], 0x3120                    ; Left border
    mov word [es:di+2], ax              ; Hollow
    mov word [es:di+4], 0x3120              ; Hollow
    mov word [es:di+6], ax              ; Hollow
    mov word [es:di+8], 0x3120                  ; Right border
    add di, 160

    ; Row 5: Bottom border (3 wide)
    add di, 2
    mov word [es:di], 0x3120
    mov word [es:di+2], ax
    mov word [es:di+4], 0x3120

drawDone1:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Draw balloon 2 - ROUND BALLOON (Red)
drawBalloon2:
    push ax
    push bx
    push cx
    push di
    push es

    mov ax, 0b800h
    mov es, ax

    ; Clear previous position
    mov di, [balloon2_prev]
    cmp di, 0
    je skipClear2
    cmp di, [balloon2_pos]
    je skipClear2

    mov al, ' '
    mov ah, 0x31
    mov cx, 5

clearRow2:
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    mov word [es:di+6], ax
    mov word [es:di+8], ax
    add di, 160
    loop clearRow2

skipClear2:
    mov di, [balloon2_pos]
    cmp di, 0
    je drawDone2

    mov ah, 0x4A  ; Red
    mov al, 0xDB

    ; Row 1: Top border (3 wide)
    add di, 2
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    sub di, 2
    add di, 160

    ; Row 2: Left and right borders only
    mov word [es:di], ax
    mov word [es:di+2], 0x3120
    mov word [es:di+4], 0x3120
    mov word [es:di+6], 0x3120
    mov word [es:di+8], ax
    add di, 160

    ; Row 3: Middle with letter
    mov word [es:di], ax
    mov word [es:di+2], 0x3120
    mov bl, [balloon2_letter]
    mov bh, 0x6E
    mov word [es:di+4], bx
    mov word [es:di+6], 0x3120
    mov word [es:di+8], ax
    add di, 160

    ; Row 4: Left and right borders only
    mov word [es:di], 0x3120
    mov word [es:di+2], ax
    mov word [es:di+4], 0x3120
    mov word [es:di+6], ax
    mov word [es:di+8], 0x3120
    add di, 160

    ; Row 5: Bottom border (3 wide)
    add di, 2
    mov word [es:di], 0x3120
    mov word [es:di+2], ax
    mov word [es:di+4], 0x3120

drawDone2:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Draw balloon 3 - ROUND BALLOON (Yellow)
drawBalloon3:
    push ax
    push bx
    push cx
    push di
    push es

    mov ax, 0b800h
    mov es, ax

    ; Clear previous position
    mov di, [balloon3_prev]
    cmp di, 0
    je skipClear3
    cmp di, [balloon3_pos]
    je skipClear3

    mov al, ' '
    mov ah, 0x31
    mov cx, 5

clearRow3:
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    mov word [es:di+6], ax
    mov word [es:di+8], ax
    add di, 160
    loop clearRow3

skipClear3:
    mov di, [balloon3_pos]
    cmp di, 0
    je drawDone3

    mov ah, 0x4C  ; Bright Yellow
    mov al, 0xDB

    ; Row 1: Top border (3 wide)
    add di, 2
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    sub di, 2
    add di, 160

    ; Row 2: Left and right borders only
    mov word [es:di], ax
    mov word [es:di+2], 0x3120
    mov word [es:di+4], 0x3120
    mov word [es:di+6], 0x3120
    mov word [es:di+8], ax
    add di, 160

    ; Row 3: Middle with letter
    mov word [es:di], ax
    mov word [es:di+2], 0x3120
    mov bl, [balloon3_letter]
    mov bh, 0x6E
    mov word [es:di+4], bx
    mov word [es:di+6], 0x3120
    mov word [es:di+8], ax
    add di, 160

    ; Row 4: Left and right borders only
    mov word [es:di], 0x3120
    mov word [es:di+2], ax
    mov word [es:di+4], 0x3120
    mov word [es:di+6], ax
    mov word [es:di+8], 0x3120
    add di, 160

    ; Row 5: Bottom border (3 wide)
    add di, 2
    mov word [es:di], 0x3120
    mov word [es:di+2], ax
    mov word [es:di+4], 0x3120

drawDone3:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Draw balloon 4 - ROUND BALLOON (Cyan)
drawBalloon4:
    push ax
    push bx
    push cx
    push di
    push es

    mov ax, 0b800h
    mov es, ax

    ; Clear previous position
    mov di, [balloon4_prev]
    cmp di, 0
    je skipClear4
    cmp di, [balloon4_pos]
    je skipClear4

    mov al, ' '
    mov ah, 0x31
    mov cx, 5

clearRow4:
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    mov word [es:di+6], ax
    mov word [es:di+8], ax
    add di, 160
    loop clearRow4

skipClear4:
    mov di, [balloon4_pos]
    cmp di, 0
    je drawDone4

    mov ah, 0x4D  ; Bright Cyan
    mov al, 0xDB

    ; Row 1: Top border (3 wide)
    add di, 2
    mov word [es:di], ax
    mov word [es:di+2], ax
    mov word [es:di+4], ax
    sub di, 2
    add di, 160

    ; Row 2: Left and right borders only
    mov word [es:di], ax
    mov word [es:di+2], 0x3120
    mov word [es:di+4], 0x3120
    mov word [es:di+6], 0x3120
    mov word [es:di+8], ax
    add di, 160

    ; Row 3: Middle with letter
    mov word [es:di], ax
    mov word [es:di+2], 0x3120
    mov bl, [balloon4_letter]
    mov bh, 0x6E
    mov word [es:di+4], bx
    mov word [es:di+6], 0x3120
    mov word [es:di+8], ax
    add di, 160

    ; Row 4: Left and right borders only
    mov word [es:di], 0x3120
    mov word [es:di+2], ax
    mov word [es:di+4], 0x3120
    mov word [es:di+6], ax
    mov word [es:di+8], 0x3120
    add di, 160

    ; Row 5: Bottom border (3 wide)
    add di, 2
    mov word [es:di], 0x3120
    mov word [es:di+2], ax
    mov word [es:di+4], 0x3120

drawDone4:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Delay (Half second using BIOS timer)
halfSecondDelay:
    push ax
    push cx
    push dx
    push bx

    mov ah, 0
    int 0x1A

    mov bx, dx
    add bx, 6       ; 9 ticks = half second

halfWaitLoop:
    mov ah, 0
    int 0x1A

    cmp dx, bx
    jl halfWaitLoop

    pop bx
    pop dx
    pop cx
    pop ax
    ret

; Delay (Exactly 1 second using BIOS timer)
oneSecondDelay:
    push ax
    push cx
    push dx

    ; Get current timer tick count
    mov ah, 0
    int 0x1A

    ; Save starting tick
    push dx
    push cx

waitLoop:
    ; Get current tick again
    mov ah, 0
    int 0x1A

    ; Compare with start time
    pop cx          ; Get start CX
    pop bx          ; Get start DX into BX
    push bx         ; Push back
    push cx

    ; Calculate difference (DX - start_DX)
    sub dx, bx
    ; If difference >= 18 ticks (approximately 1 second), exit
    cmp dx, 18
    jl waitLoop

    ; Clean up stack
    pop cx
    pop dx

    pop dx
    pop cx
    pop ax
    ret

clscrn:
    push ax
    push di
    push es
    mov ax, 0b800h
    mov es, ax
    mov di, 0
nextclear:
    mov word [es:di], 0x3120
    add di, 2
    cmp di, 4000
    jne nextclear
    pop es
    pop di
    pop ax
    ret

printString:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, 0b800h
    mov es, ax

    mov al, 80
    mul byte [bp+8]
    add ax, [bp+6]
    shl ax, 1
    mov di, ax

    mov si, [bp+4]
    mov ah, 0x3F

printLoop:
    mov al, [si]
    cmp al, 0
    je printDone
    mov [es:di], ax
    add di, 2
    inc si
    jmp printLoop

printDone:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

displayTime:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov ax, 0b800h
    mov es, ax

    mov al, 80
    mul byte [bp+6]
    add ax, [bp+4]
    shl ax, 1
    mov di, ax

    xor ah, ah
    mov al, [minutes]
    mov bl, 10
    div bl
    push ax
    add al, '0'
    mov ah, 0x3E
    mov [es:di], ax
    add di, 2

    pop ax
    mov al, ah
    add al, '0'
    mov ah, 0x3E
    mov [es:di], ax
    add di, 2

    mov al, ':'
    mov ah, 0x3E
    mov [es:di], ax
    add di, 2

    xor ah, ah
    mov al, [seconds]
    mov bl, 10
    div bl
    push ax
    add al, '0'
    mov ah, 0x3E
    mov [es:di], ax
    add di, 2

    pop ax
    mov al, ah
    add al, '0'
    mov ah, 0x3E
    mov [es:di], ax

    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 4

displayScore:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov ax, 0b800h
    mov es, ax

    mov al, 80
    mul byte [bp+8]
    add ax, [bp+6]
    shl ax, 1
    mov di, ax

    mov ax, [bp+4]
    mov bx, 10
    xor cx, cx

convertDigits:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz convertDigits

displayDigits:
    pop ax
    add al, '0'
    mov ah, 0x3A
    mov [es:di], ax
    add di, 2
    loop displayDigits

    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

pause_screen_start:
    mov ax, VIDEO_SEG
    mov es, ax

pause_loop:
    call fill_light_blue_background
    call draw_pause_overlay
    call get_pause_choice

    cmp al, 'r'
    je resume_game_from_pause
    cmp al, 'R'
    je resume_game_from_pause
    cmp al, 'q'
    je quit_to_menu_from_pause
    cmp al, 'Q'
    je quit_to_menu_from_pause
    cmp al, 27
    je resume_game_from_pause
    jmp pause_loop


quit_to_menu_from_pause:
    ; Restore original timer interrupt
    push ds
    mov ah, 0x25
    mov al, 0x08
    lds dx, [oldISR]
    int 0x21
    pop ds

    ; Reset game and go to main menu
    jmp main_menu_start


resume_game_from_pause:
    ; Redraw the game screen and continue
    call clscrn
    call displayUI
    jmp gameLoop        ; RETURN TO GAME LOOP!

; draws the pause overlay text and options
draw_pause_overlay:
    call draw_paused_blocks
    mov word [cur_row], 18
    mov si, pause_opt1
    mov bl, PAUSE_OPTION_ATTR
    call print_center_color
    mov si, pause_opt2
    mov bl, PAUSE_OPTION_ATTR
    call print_center_color
    add word [cur_row], 1
    mov si, pause_prompt
    mov bl, PAUSE_HINT_ATTR
    call print_center_color
    ret

fill_light_blue_background:
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov ah, PAUSE_BG_COLOR
    mov al, 0x20
    mov cx, COLS * ROWS
    rep stosw
    ret
draw_paused_blocks:
    mov ax, VIDEO_SEG
    mov es, ax
    mov ah, PAUSE_BLOCK_ATTR
    mov al, 0xDB

    ; letter P
    mov di, (8*COLS + 23)*2
    stosw
    stosw
    stosw
    stosw
    mov di, (9*COLS + 23)*2
    stosw
    mov di, (9*COLS + 26)*2
    stosw
    mov di, (10*COLS + 23)*2
    stosw
    stosw
    stosw
    stosw
    mov di, (11*COLS + 23)*2
    stosw
    mov di, (12*COLS + 23)*2
    stosw

    ; letter A
    mov di, (8*COLS + 29)*2
    stosw
    stosw
    stosw
    stosw
    mov di, (9*COLS + 29)*2
    stosw
    mov di, (9*COLS + 32)*2
    stosw
    mov di, (10*COLS + 29)*2
    stosw
    stosw
    stosw
    stosw
    mov di, (11*COLS + 29)*2
    stosw
    mov di, (11*COLS + 32)*2
    stosw
    mov di, (12*COLS + 29)*2
    stosw
    mov di, (12*COLS + 32)*2
    stosw

    ; letter U
    mov di, (8*COLS + 35)*2
    stosw
    mov di, (8*COLS + 38)*2
    stosw
    mov di, (9*COLS + 35)*2
    stosw
    mov di, (9*COLS + 38)*2
    stosw
    mov di, (10*COLS + 35)*2
    stosw
    mov di, (10*COLS + 38)*2
    stosw
    mov di, (11*COLS + 35)*2
    stosw
    mov di, (11*COLS + 38)*2
    stosw
    mov di, (12*COLS + 35)*2
    stosw
    stosw
    stosw
    stosw

    ; letter S
    mov di, (8*COLS + 41)*2
    stosw
    stosw
    stosw
    stosw
    mov di, (9*COLS + 41)*2
    stosw
    mov di, (10*COLS + 41)*2
    stosw
    stosw
    stosw
    stosw
    mov di, (11*COLS + 44)*2
    stosw
    mov di, (12*COLS + 41)*2
    stosw
    stosw
    stosw
    stosw

    ; letter E
    mov di, (8*COLS + 47)*2
    stosw
    stosw
    stosw
    stosw
    mov di, (9*COLS + 47)*2
    stosw
    mov di, (10*COLS + 47)*2
    stosw
    stosw
    stosw
    stosw
    mov di, (11*COLS + 47)*2
    stosw
    mov di, (12*COLS + 47)*2
    stosw
    stosw
    stosw
    stosw

    ; letter D
    mov di, (8*COLS + 53)*2
    stosw
    stosw
    stosw
    mov di, (9*COLS + 53)*2
    stosw
    mov di, (9*COLS + 56)*2
    stosw
    mov di, (10*COLS + 53)*2
    stosw
    mov di, (10*COLS + 56)*2
    stosw
    mov di, (11*COLS + 53)*2
    stosw
    mov di, (11*COLS + 56)*2
    stosw
    mov di, (12*COLS + 53)*2
    stosw
    stosw
    stosw
    ret

clear_pause_message:
    mov ax, VIDEO_SEG
    mov es, ax
    mov di, 8 * COLS * 2
    mov ah, 0x00
    mov al, ' '
    mov cx, COLS * 13
    rep stosw
    ret

clear_screen:
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov ah, 0x00
    mov al, ' '
    mov cx, COLS * ROWS
    rep stosw
    mov word [cur_row], 5
    ret

print_center_color:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    mov ax, VIDEO_SEG
    mov es, ax
    mov bx, [cur_row]
    mov ax, bx
    mov bx, COLS
    mul bx
    add ax, (COLS/2 - 20)
    shl ax, 1
    mov di, ax
	mov bl, PAUSE_OPTION_ATTR
print_loop:
    lodsb
    cmp al, 0
    je done
    mov ah, bl
    stosw
    jmp print_loop
done:
    add word [cur_row], 1
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

cur_row dw 18

wait_key_pause:
    mov ah, 0
    int 0x16
    ret

get_pause_choice:
    mov ah, 0
    int 0x16
	ret