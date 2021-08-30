;startup address
; 02A7 - player direction
; 02A8 - length
; 02A9 - x position
; 02AA - y position
; 02AB - location pointer
; 02AC - food count
; 0C00 - 0CFF snake row locations
; 0D00 - 0DFF snake col locations

* = $0801
;create BASIC startup (SYS line)
!basic



startScreen:
  JSR clearScreen
  LDY #$00 ; char pointer
  LDX #$08 ; row
titleMessage:
  TYA ; copy y to a so we can modify it
  PHA ; save the index because we'll need it for the next time round
  ADC #$10 ; shift positin along so we write in the middle
  TAY ; put back in y so we can use for col
  JSR $FFF0 ; call PLOT
  PLA ; grab the index back off the stack
  TAY ; stick the index back in y so we can read the right char
  LDA titleText,y      ; read characters from line1 table of text...
  JSR $FFD2
  INY 
  CPY #$09         ; finished when all 40 cols of a line are processed
  BNE titleMessage    ; loop if we are not done yet

waitToStart:
  LDX $D020
  INX
  STX $D020
  

  LDA $DC00
  AND #$10
  BNE waitToStart
  JSR clearScreen  
  JSR initGame

mainLoop:
  JSR joystick
  JSR undrawTail
  JSR moveSnake
  JSR drawHead
  
  JSR makeFood
  JMP mainLoop

dead:
  JSR clearScreen
  LDY #$00 ; char pointer
  LDX #$08 ; row
deadMessage:
  TYA ; copy y to a so we can modify it
  PHA ; save the index because we'll need it for the next time round
  ADC #$10 ; shift positin along so we write in the middle
  TAY ; put back in y so we can use for col
  JSR $FFF0 ; call PLOT
  PLA ; grab the index back off the stack
  TAY ; stick the index back in y so we can read the right char
  LDA deathText,y      ; read characters from line1 table of text...
  JSR $FFD2
  INY 
  CPY #$08         ; finished
  BNE deadMessage    ; loop if we are not done yet  
waitToRestart:
  LDX $D020
  INX
  STX $D020
  

  LDA $DC00
  AND #$10
  BNE waitToRestart
  JMP startScreen 
  
initGame:
  LDX #$01
  STX $02A7
  LDX #$01
  STX $02A8
  LDX #$14
  LDY #$10
  JSR saveSnake

  LDX #$00
  STX $02AB
  STX $02AC

  LDA #$00
  STA $D020
  STA $D021

  
clearScreen:
  LDX #$FF
clearScreenLoop:
  LDA #$20
  STA $0400, X
  STA $0500, X
  STA $0600, X
  STA $0700, X
  LDA #$05
  STA $D800, X 
  STA $D900, X 
  STA $DA00, X
  STA $DB00, X
  DEX
  BNE clearScreenLoop
  ; because the loop above stops when it gets to zero but doesn't actually run for zero
  LDA #$20
  STA $0400
  STA $0500
  STA $0600
  STA $0700
  LDA #$05
  STA $D800 
  STA $D900 
  STA $DA00
  STA $DB00
  RTS
  
joystick:
  LDX $02A7
  LDY $DC00
  TYA
  AND #$01
  BEQ joyUp
  TYA
  AND #$02
  BEQ joyDown
  TYA
  AND #$04
  BEQ joyLeft
  TYA
  AND #$08
  BEQ joyRight

joyDone:
  STX $02A7 ; put our direction flag in 02A7
  RTS
joyUp:
  LDX #$01
  JMP joyDone
joyDown:
  LDX #$02
  JMP joyDone  
joyLeft:
  LDX #$04
  JMP joyDone
joyRight:
  LDX #$08
  JMP joyDone

moveSnake:
  LDX $02FF
  DEX
  STX $02FF
  BEQ doMoveSnake
  RTS
    
doMoveSnake:
  JSR rollSnake
  JSR getHead
  LDA $02A7
  AND #$01
  BNE moveSnakeUp
  LDA $02A7
  AND #$02
  BNE moveSnakeDown
  LDA $02A7
  AND #$04
  BNE moveSnakeLeft
  LDA $02A7
  AND #$08
  BNE moveSnakeRight
moveSnakeDone:  
  JSR saveSnake 
  JSR checkDeath
  JSR checkFoodCollision
  RTS
moveSnakeUp:
  DEX
  CPX #$FF
  BNE moveSnakeDone
  LDX #$19 ; to the bottom
  JMP moveSnakeDone
moveSnakeDown:
  INX
  CPX #$1A
  BNE moveSnakeDone
  LDX #$00 ; to the top
  JMP moveSnakeDone  
moveSnakeLeft:
  DEY
  CPY #$FF
  BNE moveSnakeDone
  LDY #$28 ; to the right
  JMP moveSnakeDone
moveSnakeRight:
  INY
  CPY #$28
  BNE moveSnakeDone
  LDY #$00 ; to the left
  JMP moveSnakeDone  
  
drawHead:
  JSR getHead
  LDA #$A0
  JSR plotChar
  RTS  

undrawTail:
  JSR getTail
  LDA #$20
  JSR plotChar
  RTS  

  
saveSnake:
  TXA
  LDX $02A8 ; snake length
  STA $0C00, x  ; store row
  TYA
  STA $0D00, x  ; store col
  RTS

getHead: ; load head x and y into y and x (so they are ready to do row & col)
  PHA ; save A
  LDX $02A8 ; snake length
  LDA $0D00, x
  TAY
  LDA $0C00, x
  TAX
  PLA ; recover A
  RTS

getTail: ; load tail x and y into y and x (so they are ready to do row & col)
  LDY $0D00
  LDX $0C00
  RTS

rollSnake:
  ; roll rows
  LDX $02A8
  LDY $0C00, x    
  rollSnakeLoopRow:
    TYA
    DEX
    LDY $0C00, x
    STA $0C00, x 
    CPX #00
    BNE rollSnakeLoopRow
    
  ; row cols  
  LDX $02A8
  LDY $0D00, x    
  rollSnakeLoopCol:
    TYA
    DEX
    LDY $0D00, x
    STA $0D00, x 
    CPX #00
    BNE rollSnakeLoopCol  
  RTS

makeFood:
  LDA $02AC
  BNE foodDone
  JSR rnd
  TAX
  JSR rnd
  TAY
  
  ; make sure we're not inside the snake
  LDA ScreenRowTableDataL, x
  STA $80
  LDA ScreenRowTableDataH, x
  STA $81
  LDA ($80), y
  CMP #$A0
  BEQ makeFood ; insdie the snake - try again
  
  LDA #$51
  JSR plotChar
  LDA #01
  STA $02AC ; there is now food
foodDone:
  RTS  

; with row in x and col in y, get char at pos and put it in A  
getCharUnderHead:
  JSR getHead
  LDA ScreenRowTableDataL, x
  STA $80
  LDA ScreenRowTableDataH, x
  STA $81
  LDA ($80), y
  RTS
checkFoodCollision:
  JSR getCharUnderHead
  CMP #$51
  BNE foodCollisionChecked
  TXA
  LDX $02A8  ; make
  INX        ; snake
  STX $02A8  ; longer
  TAX
  JSR saveSnake
  JSR undrawTail
  JSR drawHead
  LDX $02AC
  DEX 
  STX $02AC ; there is now less food
foodCollisionChecked:
  RTS  

checkDeath:
  JSR getCharUnderHead
  CMP #$A0
  BNE deathChecked
  JMP dead
deathChecked:  
  RTS
  
plotChar:
  PHA ; A onto stack
  LDA ScreenRowTableDataL, x
  STA $80
  LDA ScreenRowTableDataH, x
  STA $81
  PLA ; Retrieve A from stack
  STA ($80), y
  RTS
  

startRandomizer:
  LDA #$FF  ; maximum frequency value
  STA $D40E ; voice 3 frequency low byte
  STA $D40F ; voice 3 frequency high byte
  LDA #$80  ; noise waveform, gate bit off
  STA $D412 ; voice 3 control register  
  RTS

rnd:
  JSR startRandomizer
  LDA $D41B ; random number
  AND #$0F
  BEQ rnd
  RTS
  
  
;* = $c000
;========================================================
titleText:
!text "S N A K E"
deathText:
!text "d e a d"
ScreenRowTableDataL:
!byte $00
!byte $28
!byte $50
!byte $78
!byte $a0
!byte $c8
!byte $f0
;-------------------------------------------------------
!byte $18
!byte $40
!byte $68
!byte $90
!byte $b8
!byte $e0
;-------------------------------------------------------
!byte $08
!byte $30
!byte $58
!byte $80
!byte $a8
!byte $d0
!byte $f8
;--------------------------------------------------------
!byte $20
!byte $48
!byte $70
!byte $98
!byte $c0
;========================================================
ScreenRowTableDataH:
!byte $04
!byte $04
!byte $04
!byte $04
!byte $04
!byte $04
!byte $04
;---------------------------------------------------------
!byte $05
!byte $05
!byte $05
!byte $05
!byte $05
!byte $05
;----------------------------------------------------------
!byte $06
!byte $06
!byte $06
!byte $06
!byte $06
!byte $06
!byte $06
;----------------------------------------------------------
!byte $07
!byte $07
!byte $07
!byte $07
!byte $07  
  