;######## COS10004 ASSIGNMENT 2: ARMLITE STOPWATCH PROGRAM ########;
;############### SUBMISSION BY STUDENT N.T.M. TRIET ###############;

// Press `R` to Reset
// Press `S` to Split time
// Press `T` to Toggle aka Start/Stop
// Press `E` to Exit the program altogether

;############ Stopwatch Graphical User Interface (GUI) ############;

drawGUI:
      PUSH {R0-R3}
      MOV R0, #bitmapData ; Point to GUI's bitmap data
      MOV R1, #.Pixel96 ; Start from the 4th row (Low-res)
      MOV R2, #0        ; This number is used to choose a pixel
draw: LDR R3, [R0 + R2] ; Get pixel color
      STR R3, [R1 + R2] ; Draw in pixel
      ADD R2, R2, #4    ; Increment index
      CMP R2, #2304     ; Continue drawing for 576 pixels
      BLT draw
      POP {R0-R3}

labelGUI:
      PUSH {R0-R3}
      MOV R1, #.CharScreen
txt1: MOV R2, #0
      MOV R0, #labelE
      ADD R1, R1, #204
      B labl
txt2: MOV R2, #0
      MOV R0, #labelS
      ADD R1, R1, #97
labl: LDRB R3, [R0 + R2]
      STRB R3, [R1 + R2]
      ADD R2, R2, #1
      CMP R2, #12
      BLT labl
      CMP R0, #labelE   ; If current label is "Elapsed time"
      BEQ txt2          ; Then "Split time" must be next
      POP {R0-R3}

;############# Stopwatch Initialisation && Activation #############;

initialise:
      MOV R4, #48       ; Minutes Tens digit (MT)
      MOV R5, #48       ; Minutes Ones digit (MO)
      MOV R6, #48       ; Seconds Tens digit (ST)
      MOV R7, #48       ; Seconds Ones digit (SO)
      MOV R8, #1        ; Stopwatch state (on by default)
stopwatchGUI:
      BL displayElapsed
      BL displaySplit
setupInterrupts:
      PUSH {R0}
      // Register time elapsing routine
      MOV R0, #elapse
      STR R0, .ClockISR

      // Register keypress handler
      MOV R0, #keypress
      STR R0, .KeyboardISR

      // Enable keyboard interrupt
      MOV R0, #1
      STR R0, .KeyboardMask

      // Enable time elapsing routine at 1 second interval
      MOV R0, #1000
      STR R0, .ClockInterruptFrequency
      POP {R0}

      // *robotic voice* "Stopwatch, Online."
      STR R8, .InterruptRegister

;#################### Main Programs Event Loop ####################;

eventLoop:
      B eventLoop

;########### Stopwatch Core Functionality - Elapse Time ###########;

elapse:
      ADD R7, R7, #1    ; Count up Seconds Ones
      CMP R7, #58       ; Limit Seconds Ones to 9
      BLT eout
      MOV R7, #48       ; Wrap SO back to zero
      ADD R6, R6, #1    ; Count up Seconds Tens
      CMP R6, #54       ; Limit Seconds Tens to 5
      BLT eout
      MOV R6, #48       ; Wrap ST back to zero
      ADD R5, R5, #1    ; Count up Minutes Ones
      CMP R5, #58       ; Limit Minutes Ones to 9
      BLT eout
      MOV R5, #48       ; Wrap MO back to zero
      ADD R4, R4, #1    ; Count up Minutes Tens
      CMP R4, #58       ; Limit Minutes Tens to 9
      BLT eout
      MOV R4, #48       ; Wrap MT back to zero
eout: BL displayElapsed
      RFE

;################# Display Elapsed and Split time #################;

display:
      PUSH {R0, R1, R2}
      MOV R2, #.CharScreen
      ADD R2, R2, R0    ; Get the coordinate as an argument
      STRB R4, [R2 + 0] ; Minutes Tens digit
      STRB R5, [R2 + 1] ; Minutes Ones digit
      MOV R1, #109      ; Letter `m`
      STRB R1, [R2 + 2]
      STRB R6, [R2 + 3] ; Seconds Tens digit
      STRB R7, [R2 + 4] ; Seconds Ones digit
      MOV R1, #115      ; Letter `s`
      STRB R1, [R2 + 5]
      POP {R0, R1, R2}
      RET

displayElapsed:
      PUSH {R0, LR}
      MOV R0, #143  ; Column 4, Row 15
      BL display
      POP {R0, LR}
      RET

displaySplit:
      PUSH {R0, LR}
      MOV R0, #367 ; Column 11, Row 15
      BL display
      POP {R0, LR}
      RET

;######### Keypress Handler: Called when a key is pressed #########;

keypress:
      PUSH {R0, LR}
      LDR R0, .LastKeyAndReset
      CMP R0, #82       ; `R` for `Reset`
      BNE .+2
      BL reset          ; Enter reset stopwatch procedure

      CMP R0, #83       ; `S` for `Split`
      BNE .+2
      BL split          ; Enter split time procedure

      CMP R0, #84       ; `T` for `Toggle stopwatch state`
      BNE .+2
      BL toggle         ; Enter state toggle procedure

      CMP R0, #69       ; `E` for `Exit Stopwatch program`
      BNE .+2
      BL exit           ; Enter stopwatch exit sequence
      POP {R0, LR}
      RFE

;###################### Split time procedure #####################;

split:
      PUSH {LR}
      BL displaySplit
      POP {LR}
      RET

;###################### Toggle procedure #####################;

toggle:
      PUSH {R0}
      CMP R8, #0
      BEQ strt          ; Set to started if stopped
stop: MOV R8, #0        ; Set to stopped otherwise
      MOV R0, #msgToggle2
      B tout
strt: MOV R8, #1000
      MOV R0, #msgToggle1
tout: STR R8, .ClockInterruptFrequency
      STR R0, .WriteString
      POP {R0}
      RET

;###################### Reset procedure #####################;

reset:
      MOV R8, #0        ; Set Stopwatch state to stopped
      STR R8, .ClockInterruptFrequency
resetElapsedTime:
      MOV R4, #48       ; Set MT digit to 0
      MOV R5, #48       ; Set MO digit to 0
      MOV R6, #48       ; Set ST digit to 0
      MOV R7, #48       ; Set SO digit to 0
      PUSH {LR}
      BL displayElapsed
      BL displaySplit
      POP {LR}
resetMessage:
      PUSH {R0}
      MOV R0, #msgReset
      STR R0, .WriteString
      POP {R0}
      RET

;##################### Stopwatch exit sequence ####################;

exit: HALT

;############ The program ends here - Following is the ############;
;########################## DATA SECTION ##########################;

.ALIGN 128
labelE: .ASCIZ "Elapsed Time"
.ALIGN 16
labelS: .ASCIZ "Split Time"
.ALIGN 16
msgToggle1: .ASCIZ " Started!"
.ALIGN 16
msgToggle2: .ASCIZ " Stopped!"
.ALIGN 16
msgReset: .ASCIZ " Stopwatch Reset!"

;### Bitmap data for stopwatch GUI
;### This might look overwhelmingly large, but it
;### actually represents a tiny, 32x18 bitmap image

.ALIGN 64
bitmapData:
      0xffffff          ; Begin row 00/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 01/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 02/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 03/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xfe640b
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 04/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xfe640b
      0x11111b
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 05/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xfe640b
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 06/17
      0xffffff
      0xffffff
      0xffffff
      0xdf8e1d
      0xdf8e1d
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 07/17
      0xffffff
      0xffffff
      0xdf8e1d
      0xdf8e1d
      0xdf8e1d
      0xdf8e1d
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 08/17
      0xffffff
      0xffffff
      0xdf8e1d
      0xdf8e1d
      0xdf8e1d
      0xdf8e1d
      0x11111b
      0x11111b
      0x8839ef
      0x8839ef
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 09/17
      0xffffff
      0xffffff
      0xdf8e1d
      0xdf8e1d
      0xdf8e1d
      0xdf8e1d
      0x11111b
      0x11111b
      0x8839ef
      0x8839ef
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x4c4f69
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 10/17
      0xffffff
      0xffffff
      0xdf8e1d
      0xdf8e1d
      0xdf8e1d
      0xdf8e1d
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 11/17
      0xffffff
      0xffffff
      0xffffff
      0xdf8e1d
      0xdf8e1d
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 12/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 13/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 14/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 15/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 16/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff          ; Begin row 17/17
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0x8839ef
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
      0xffffff
