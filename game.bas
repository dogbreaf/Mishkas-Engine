'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Yet another 2D RPG game engine, hopefully the last
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Compile-time configuration
#define __SCALE 2
#define __XRES 800
#define __YRES 600

' Turn script debugging on 
#define __DEBUGGING__

' Turn sound support on (This uses SDL)
#define _SND_SUPPORT_

' Turn on non-bitmap suport
#define _IMG_SUPPORT_

' Send messages to stderr for debugging
#include "headers/debug.bi"

' Play sounds
#include "headers/audio.bi"

' Image Loading Abstractions and other drawing related functions
#include "headers/images.bi"

' Custom text drawing
#include "headers/drawtext.bi"

' Core graphics routines
#include "headers/sprite.bi"
#include "headers/tilemap.bi"

' Get keyboard input
#include "headers/controls.bi"

' Unite the sprite object with player controls
#include "headers/player.bi"

' Use sprites for NPCs and interactable objects
#include "headers/object.bi"

' Scale the screen
#include "headers/screenScale.bi"

' Draws menus and text and stuff
#include "headers/text.bi"

' Combines tilemap and sprite stuff
#include "headers/room.bi"

' Manages inventory
#include "headers/inventory.bi"

' Scriptable
#include "headers/script.bi"

' Glue everything together
#include "headers/glue.bi"

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
ScreenRes __XRES,__YRES,32

Dim As script		gameScript
Dim As String	main = Command(1)

'' 
If main = "" Then
	main = "data/main.gs"
Endif

'' Add routines from various modules
gameScript.addOperator(@textAndMenuCallback)
gameScript.addOperator(@gameCallback)
gameScript.addOperator(@inventoryManagerCallback)
gameScript.addOperator(@musicAndSoundCallback)

'' Load and execute the main script
gameScript.load(main)
gameScript.execute()

