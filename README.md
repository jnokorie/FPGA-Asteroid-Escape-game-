# FPGA-Asteroid-Escape-game-
A real-time arcade-style game implemented in Verilog for FPGA platforms featuring VGA output and 7-segment display integration.

## Features
Real-time gameplay with VGA video output (1440x900 resolution), 
Ship navigation system with collision detection and boundary constraints, 
Dynamic asteroid field with 8 moving obstacles, 
Variable speed control using 3-switch input for ship movement, 
Countdown timer displayed on 7-segment displays, 
Multiple game states: Idle, Opening Screen, Game Running, and Game Over, 
Exit zone mechanics - reach the top of the screen to win, 
Animated graphics with 2-second animation clock, 
Button-controlled movement (4-directional navigation + action button).

##Technical Implementation:
Written in Verilog HDL with modular design architecture, 
Clock domain management with pixel clock and game logic clocks, 
Custom VGA controller for display output, 
Collision detection algorithms, 
State machine-based game logic, 
Real-time position tracking and boundary checking.
