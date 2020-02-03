'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' New version map editor
''
'' Not really meant to be super neat code but I didn't want it to be as 
'' messy and unmaintainable as the old code.
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'' Screen resoloution
#define __XRES__ 1280
#define __YRES__ 620

'' Window dimensions
#define __WIN_WIDTH__ 256
#define __WIN_PROPERTIES_HEIGHT__ 128
#define __WIN_EDIT_HEIGHT__ 128
#define __WIN_TOOLS_HEIGHT__ ( __YRES__ - __WIN_PROPERTIES_HEIGHT__ - __WIN_EDIT_HEIGHT__ )

'' Icon characters (see font reference)
#define __CHR_LAYER_VIS__ Chr(219)
#define __CHR_LAYER_NON_VIS__ Chr(254)

#define __CHR_EDITING__ Chr(16)
#define __CHR_EDIT__ "E"

'' When to snap to the maximum scroll
#define __SCROLL_SNAP__ 45

'' Hotkeys
#define _HK_SELECT_UP fb.SC_UP
#define _HK_SELECT_DN fb.SC_DOWN
#define _HK_SELECT_LF fb.SC_LEFT
#define _HK_SELECT_RG fb.SC_RIGHT

#define _HK_LAYER_UP fb.SC_PAGEUP
#define _HK_LAYER_DN fb.SC_PAGEDOWN

#define _HK_SAVE fb.SC_S, fb.SC_CONTROL

#define _HK_PICK_FG fb.SC_C, fb.SC_CONTROL
#define _HK_PICK_BG fb.SC_C, fb.SC_LSHIFT

#define _HK_SET_FG fb.SC_E
#define _HK_SET_BG fb.SC_R

#define _HK_SIZE_UP &h1B
#define _HK_SIZE_DN &h1A

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'' UI toolkit
#include "headers/uitk/ui.bi"
#include "headers/uitk/textinput.bi"
#include "headers/uitk/label.bi"
#include "headers/uitk/window.bi"
#include "headers/uitk/dialouge.bi"

'' Tilemap and graphics
#include "headers/images.bi"
#include "headers/tilemap.bi"
#include "fbgfx.bi"

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Initialisation
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'' Loading Screen
ScreenRes __XRES__, __YRES__, 32
WindowTitle "Editor"

Declare Sub LoadingIndicator( ByVal As String = "Loading...", ByVal As String = "" )

LoadingIndicator("Tilemap Editor v2.0","By Mishka")
Sleep 1000,1

'' Files
Dim As String		tilemap
Dim As String		tileset

Dim As Boolean		changesSaved = true
Dim As Boolean		wasSaved = true

'' The tilemap
Dim As Screen		map

'' Triggers for code template
Dim As String		trigger(__MAP_SIZE,__MAP_SIZE)

'' Editor
Dim As Integer		EditLayer
Dim As Boolean		HideLayer(__LAYER_COUNT__)

'' The selected place position
Dim As Integer		EditX
Dim As Integer		EditY

Dim As Integer		SelectionSize = (32/__TILE_SIZE)

'' The tiles selected to be placed
Dim As Integer		EditTile1ID = 1
Dim As Integer		EditTile2ID

'' Palette scroll
Dim As Integer		paletteScroll

'' Wether to show flags on the tilemap
Dim As Boolean		showDebug

'' Mouse stuff
Dim As Integer		mouseX
Dim As Integer		mouseY
Dim As Integer		mouseButtons

'' Declare routines from the bottom of the file
Declare Sub framerate( ByVal As Integer, ByVal As Integer )
Declare Sub drawTile( ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Screen Ptr, ByVal As Any Ptr )

Declare Sub checkerBoard( ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Any Ptr = 0 )
Declare Sub SelectBox( ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Integer = rgb(200,0,180), ByVal As Any Ptr = 0 )

Declare Function userHotkey( ByVal As Integer, ByVal As Integer = -1, ByVal As Boolean = true ) As Boolean

'' Tile window ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Dim As uiWindow		win_tileProperties

Dim As uiLabel		Lbl_Selected_tileIDs
Dim As uiLabel		Lbl_Selected_Flags
Dim As uiLabel		Lbl_Editing_Layer

Dim As uiButton		Btn_ClearTile
Dim As uiButton		Btn_SetFG_Tile
Dim As uiButton		Btn_SetBG_Tile

Dim As uiButton		Btn_TglSolid
Dim As uiButton		Btn_TglFlag(3)

win_tileProperties.set( __XRES__ - __WIN_WIDTH__, 0, __WIN_WIDTH__, __WIN_PROPERTIES_HEIGHT__, _
			 "Tile Properties", true, false )
			 
Lbl_Selected_tileIDs.set( 42, 24, __WIN_WIDTH__ - 50, 15, "(0|0|0|0)" )
Lbl_Selected_Flags.set( 42, 44, __WIN_WIDTH__ - 50, 15, "Flags: " )
Lbl_Editing_Layer.set( 4, 64, __WIN_WIDTH__ - 8, 15, "Editing Layer: " & EditLayer )

Btn_SetFG_Tile.set( 4, 82, (__WIN_WIDTH__-16)/2, 15, "Set FG" )
Btn_SetBG_Tile.set( (__WIN_WIDTH__)/2, 82, (__WIN_WIDTH__-16)/2, 15, "Set BG" )

Btn_ClearTile.set( 4, 102, (__WIN_WIDTH__-16)/2, 15, "Clear Data" )

Btn_TglSolid.set( (__WIN_WIDTH__)/2, 102, 15, 15, "S" )

For i As Integer = 0 to 3
	Btn_TglFlag(i).set( ((__WIN_WIDTH__)/2)+(18*i)+18, 102, 15, 15, str(i) )
	Btn_TglFlag(i).box.color.value = rgb(50*i,255-(50*i),255)
	
	Win_TileProperties.add(@Btn_TglFlag(i))
Next

Win_TileProperties.add(@Btn_TglSolid)
			 
Win_TileProperties.add(@Lbl_Selected_tileIDs)
Win_TileProperties.add(@Lbl_Selected_Flags)
Win_TileProperties.add(@Lbl_Editing_Layer)

Win_TileProperties.add(@Btn_SetFG_Tile)
Win_TileProperties.add(@Btn_SetBG_Tile)
Win_TileProperties.add(@Btn_ClearTile)

'' Currently selected pallete tiles ''''''''''''''''''''''''''''''''''''''''''
Dim As uiWindow		win_Edit

win_Edit.Set( __XRES__ - __WIN_WIDTH__, __WIN_PROPERTIES_HEIGHT__, _
			__WIN_WIDTH__, __WIN_EDIT_HEIGHT__, _
			"Editing", true, false )

'' Tools Window '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Dim As uiWindow		win_Tools

Dim As uiButton		Btn_Save
Dim As uiButton		Btn_ToolsFill
Dim As uiButton		Btn_Clear
Dim As uiButton		Btn_Refresh
Dim As uiButton		Btn_TglInfo

Dim As uiButton		Btn_LoadTileSet
Dim As uiButton		Btn_LoadTileMap

Dim As uiButton		Btn_ExportTriggers
Dim As uiButton		Btn_AddTrigger
Dim As uiLabel		Lbl_Trigger

Dim As uiButton		Btn_LayerVis(__LAYER_COUNT__)
Dim As uiButton		Btn_LayerEdit(__LAYER_COUNT__)
Dim As uiLabel		Lbl_LayerVis(__LAYER_COUNT__)

win_Tools.set( __XRES__ - __WIN_WIDTH__, __YRES__ - __WIN_TOOLS_HEIGHT__, _
			__WIN_WIDTH__, __WIN_TOOLS_HEIGHT__, _
			"Tools", true, false )

Btn_Save.set		( 4, 24, (__WIN_WIDTH__-16)/2, 15, 				"Save" )
Btn_Refresh.set		( (__WIN_WIDTH__-16)/2 + 8, 24, (__WIN_WIDTH__-16)/2, 15,	"Refresh" )
Btn_ToolsFill.set	( 4, 44, (__WIN_WIDTH__-16)/2, 15, 				"Fill" )
Btn_Clear.set		( (__WIN_WIDTH__-16)/2 + 8, 44, 120, 15, 			"Clear" )
Btn_TglInfo.set		( 4, 64, (__WIN_WIDTH__-16)/2, 15,			        "Info" )

Btn_LoadTileSet.set ( 4, __WIN_TOOLS_HEIGHT__ - 24, __WIN_WIDTH__ - 8, 15,	"Load Tile Set" )
Btn_LoadTileMap.set ( 4, __WIN_TOOLS_HEIGHT__ - 44, __WIN_WIDTH__ - 8, 15,	"Load Tile Map" )

Btn_ExportTriggers.set ( 4, __WIN_TOOLS_HEIGHT__ - 84, __WIN_WIDTH__ - 8, 15, 	"Export Script Template")
Btn_AddTrigger.set ( 4, __WIN_TOOLS_HEIGHT__ - 64, (__WIN_WIDTH__ - 8)/2, 15,	"Add trigger")
Lbl_Trigger.set ( 8 + (__WIN_WIDTH__ - 8)/2, __WIN_TOOLS_HEIGHT__ - 64, (__WIN_WIDTH__ - 8)/2, 15, "")

Win_Tools.add(@Btn_Save)
Win_Tools.add(@Btn_ToolsFill)
Win_Tools.add(@Btn_Clear)
Win_Tools.add(@Btn_Refresh)
Win_Tools.add(@Btn_TglInfo)

Win_Tools.add(@Btn_LoadTileSet)
Win_Tools.add(@Btn_LoadTileMap)

Win_Tools.add(@Btn_ExportTriggers)
Win_Tools.add(@Btn_AddTrigger)
Win_Tools.add(@Lbl_Trigger)

For i As Integer = 0 to __LAYER_COUNT__
	Btn_LayerVis(i).set ( 4, 84 + (20*i), 15, 15, __CHR_LAYER_VIS__ )
	Btn_LayerEdit(i).set( 24, 84 + (20*i), 15, 15, __CHR_EDIT__ )
	
	If i = EditLayer Then
		Btn_LayerEdit(i).box.text = __CHR_EDITING__
	Endif
	
	Lbl_LayerVis(i).set ( 44, 84 + (20*i), 120, 15, "Layer " & (i+1) )
	
	Win_Tools.add(@Lbl_LayerVis(i))
	
	Win_Tools.add(@Btn_LayerEdit(i))
	Win_Tools.add(@Btn_LayerVis(i))
Next

'' Palette selection window '''''''''''''''''''''''''''''''''''''''''''''''''''
Dim As uiWindow		Win_Palette

Dim As uiButton		Btn_PaletteUp
Dim As uiButton		Btn_PaletteDn

Win_Palette.set( 0, __YRES__ - __WIN_WIDTH__, __XRES__ - __WIN_WIDTH__, __WIN_WIDTH__, "Palette", true, false )

Btn_PaletteUp.set( 520, 24, 100, 100, Chr(24) )
Btn_PaletteDn.set( 520, 148, 100, 100, Chr(25) )

Win_Palette.add(@Btn_PaletteUp)
Win_Palette.add(@Btn_PaletteDn)

'' Arguments ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
If Command(1) <> "" Then
	tileset = Command(1)
Endif
If Command(2) <> "" Then
	tilemap = Command(2)
Endif

'' Initialise tilemap '''''''''''''''''''''''''''''''''''''''''''''''''''''''''
map.init(tileset, tilemap)
map.refresh(showDebug)

map.vp_x = 0
map.vp_y = 10
map.vp_w = __XRES__ - __WIN_WIDTH__
map.vp_h = __YRES__ - __WIN_WIDTH__

'' Main Loop ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Do
	'' Update window title
	If wasSaved <> ChangesSaved Then
		WindowTitle("Editor" & IIF( changesSaved, "", " (Unsaved Changes)" ) )
	Endif
	wasSaved = ChangesSaved
	
	'' If we need to use print for debugging, reset the cursor location
	Locate 6,1
	
	ScreenLock
		'' Draw the background checker pattern
		checkerboard(0,0,__XRES__,__YRES__)
		
		'' Info title bar
		Line (0,0)-STEP(__XRES__ - __WIN_WIDTH__, 10), rgb(0,0,0), BF
		Draw String (100,1), "Tilemap: " & tilemap & IIF(changesSaved, " (SAVED)", " (NOT SAVED)") & " Tileset: " & tileset
		
		'' Draw the tilemap
		For i As Integer = 0 to __LAYER_COUNT__
			If not HideLayer(i) Then:map.draw(i):Endif
		Next
		
		'' Draw the palette
		put Win_Palette.Context.Buffer, ( 4, 24 ), map.scr_tileset, _
			(0, paletteScroll*__TILE_SIZE)-STEP(512,__WIN_WIDTH__ - __TILE_SIZE), PSET
		
		' Draw the selected tile
		drawTile(map.tiles(editX, editY).tID(EditLayer), 4, 24, @map, Win_TileProperties.Context.Buffer)
		
		' The editor selected tiles
		drawTile(EditTile1ID, 4, 24, @map, Win_Edit.Context.Buffer)
		drawTile(EditTile2ID, 4, 64, @map, Win_Edit.Context.Buffer)
		
		'' Draw the selection boxes
		selectBox( (EditX*__TILE_SIZE) + map.vp_x - map.vp_sx, (EditY*__TILE_SIZE) + map.vp_y - map.vp_sy, _
			__TILE_SIZE*SelectionSize, __TILE_SIZE*SelectionSize, rgb(255,200,0) )
		
		'' palette tiles
		Scope
			Dim As Integer tx,ty
			
			_tm_1to2d( EditTile1ID, __TILESET_WIDTH, tx, ty )
			selectBox( 5 + (__TILE_SIZE*tx), 25 + (__TILE_SIZE*ty) - (__TILE_SIZE*paletteScroll), _
				__TILE_SIZE*SelectionSize, __TILE_SIZE*SelectionSize, rgb(100,255,80), Win_Palette.context.buffer )
			
			_tm_1to2d( EditTile2ID, __TILESET_WIDTH, tx, ty )
			selectBox( 3 + (__TILE_SIZE*tx), 23 + (__TILE_SIZE*ty) - (__TILE_SIZE*paletteScroll), _
				__TILE_SIZE*SelectionSize, __TILE_SIZE*SelectionSize, rgb(80,100,255), Win_Palette.context.buffer )
		End Scope
		
		' Update GUI
		Win_Tools.Put()
		Win_Edit.Put()
		Win_TileProperties.Put()
		Win_Palette.Put()
		
		' Display framerate
		framerate(1,0)
	ScreenUnLock
	
	' Poll UI
	Win_Tools.Update()
	Win_Edit.Update()
	Win_TileProperties.Update()
	Win_Palette.Update()
	
	'' Update the mouse
	getMouse(mouseX, mouseY,, mouseButtons)
	
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	
	'' Scroll the palette
	If Btn_PaletteUp.onClick() Then
		paletteScroll -= 1
		Win_Palette.context.redraw = true
		Sleep 200,1
	Elseif Btn_PaletteDn.onClick() Then
		paletteScroll += 1
		Win_Palette.context.redraw = true
		Sleep 200,1
	Endif
	
	'If paletteScroll > (10*__TILESET_PAGES__) Then
	'	paletteScroll = (10*__TILESET_PAGES__)
	'Else
	If paletteScroll < 0 Then
		paletteScroll = 0
	Endif
	
	'' Update the trigger label
	Lbl_Trigger.box.text = trigger(EditX, EditY)
	Lbl_Trigger.refresh = true
	
	'' Always refresh the window because it's content changes often
	Win_TileProperties.context.redraw = true
	
	Lbl_Selected_TileIDs.box.text = "(" & EditX & "," & EditY & ") "
	Lbl_Selected_Flags.box.text = "Flags: "
	
	'' Update layer controls
	For i As Integer = 0 to __LAYER_COUNT__
		' hide/show layer
		If Btn_LayerVis(i).onClick() Then
			HideLayer(i) = not HideLayer(i)
			
			Sleep 100,1
			
			If Btn_LayerVis(i).box.text = __CHR_LAYER_VIS__ Then
				Btn_LayerVis(i).box.text = __CHR_LAYER_NON_VIS__
			Else
				Btn_LayerVis(i).box.text = __CHR_LAYER_VIS__
			Endif
		Endif
		
		' Select editing layer
		If Btn_LayerEdit(i).onClick() Then
			EditLayer = i
		Endif
		
		' Update edit buttons
		If i = EditLayer Then
			Btn_LayerEdit(i).box.text = __CHR_EDITING__
			Btn_LayerEdit(i).refresh = true
		Else
			Btn_LayerEdit(i).box.text = __CHR_EDIT__
			Btn_LayerEdit(i).refresh = true
		Endif
		
		' Layer ID indicators
		Lbl_Selected_TileIDs.box.text += IIF(i > 0, "|", "") & map.tiles(EditX, EditY).tID(i)
	Next
	Lbl_Selected_TileIDs.refresh = true
	
	'' Update selected flag indicators
	Lbl_Selected_Flags.box.text += IIF( map.tiles(EditX, EditY).solid, "S ", "" )
	For i As Integer = 0 to 3
		Lbl_Selected_Flags.box.text += IIF( map.tiles(EditX, EditY).flag(i), "F" & i & " ", "" )
	Next
	Lbl_Selected_Flags.refresh = true
	
	'' Update properties panel
	Lbl_Editing_Layer.box.text = "Editing Layer: " & (EditLayer+1)
	Lbl_Editing_Layer.refresh = true
	
	'' Tools ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	
	'' hotkey only actions
	If userHotkey(_HK_SELECT_UP,,false) Then
		EditY -= 1
	ElseIf userHotkey(_HK_SELECT_DN,,false) Then
		EditY += 1
	ElseIf userHotkey(_HK_SELECT_LF,,false) Then
		EditX -= 1
	ElseIf userHotKey(_HK_SELECT_RG,, false) Then
		EditX += 1
		
	ElseIf userHotkey(_HK_LAYER_UP) Then
		EditLayer += 1
	ElseIf userHotkey(_HK_LAYER_DN) Then
		EditLayer -= 1	
		
	ElseIf userHotKey(_HK_SET_FG) Then
		For sx As Integer = 0 to SelectionSize-1
			For sy As Integer = 0 to SelectionSize-1
				map.tiles(EditX+sx, EditY+sy).tID(EditLayer) = EditTile1ID + sx + (sy*__TILESET_WIDTH)
			Next
		Next
				
		map.refresh()
	ElseIf userHotKey(_HK_SET_BG) Then
		For sx As Integer = 0 to SelectionSize-1
			For sy As Integer = 0 to SelectionSize-1
				map.tiles(EditX+sx, EditY+sy).tID(EditLayer) = EditTile2ID + sx + (sy*__TILESET_WIDTH)
			Next
		Next
		
		map.refresh()
		
	'' Resize the selection
	ElseIf userHotKey(_HK_SIZE_UP) Then
		SelectionSize += 1
	ElseIf userHotKey(_HK_SIZE_DN) Then
		SelectionSize -= 1
		
	EndIf
	
	'' Sanitize some values
	If SelectionSize < 1 Then
		SelectionSize = 1
	ElseIf SelectionSize > __TILESET_WIDTH/2 Then
		SelectionSize = __TILESET_WIDTH/2
	Endif
	
	If EditLayer < 0 Then
		EditLayer = 0
	ElseIf EditLayer > __LAYER_COUNT__ Then
		EditLayer = __LAYER_COUNT__
	Endif
	
	'' Tools window 
	If Btn_Refresh.onClick() Then
		map.refresh(showDebug)
		
	ElseIf Btn_Save.onClick() or userHotkey(_HK_SAVE) Then
		if (tilemap <> "") then
			'' Update header
			map.fileHeader.magic = __FH_MAGIC__
			map.fileHeader.tmWidth = __MAP_SIZE
			map.fileHeader.tmHeight = __MAP_SIZE
			
			map.fileHeader.reservedString = "Created with EDIT2"
			
			map.fileHeader.tileSize = __TILE_SIZE
			
			'' Write to file
			Dim hndl As Integer = Freefile
			Open tilemap For Binary As #hndl
			
			Put #hndl,, map.fileHeader
			Put #hndl,, map.tiles()

			Close #hndl

			changesSaved = true

			uiDlgAlert("Saved. Probably. (" & Err & ")")
		else
			uiDlgAlert("No file was specified!")
		endif
	ElseIf Btn_ToolsFill.onClick() Then
		If uiDlgConfirm("Are you sure you want to fill layer " & (EditLayer + 1) & " with tile " & EditTile1ID & "?") Then
			For y As Integer = 0 to __MAP_SIZE-SelectionSize STEP SelectionSize
				For x As Integer = 0 to __MAP_SIZE-SelectionSize STEP SelectionSize
					LoadingIndicator("Filling layer...", "(" & ((y*__MAP_SIZE)+x) & "/" & (__MAP_SIZE^2) & ")")
					
					For sx As Integer = 0 to SelectionSize-1
						For sy As Integer = 0 to SelectionSize-1
							map.tiles(x+sx, y+sy).tID(EditLayer) = EditTile1ID + sx + (sy*__TILESET_WIDTH)
						Next
					Next
				Next
			Next
			
			map.refresh(showDebug)
			changesSaved = false
		Endif
		
	Elseif Btn_Clear.onClick() Then
		If uiDlgConfirm("Are you sure you want to clear layer " & (EditLayer + 1) & "?") Then
			For y As Integer = 0 to __MAP_SIZE
				For x As Integer = 0 to __MAP_SIZE
					LoadingIndicator("Filling layer...", "(" & ((y*__MAP_SIZE)+x) & "/" & (__MAP_SIZE^2) & ")")
					map.tiles(x,y).tID(EditLayer) = 0
				Next
			Next
			
			map.refresh(showDebug)
			changesSaved = false
		Endif
		
	Elseif Btn_TglInfo.onClick() Then
		showDebug = not showDebug
		map.refresh(showDebug)
		
		Sleep 200,1
		
	ElseIf Btn_AddTrigger.onClick() Then
		Dim As String label = uiDlgInput("Code label name:","Clear",, trigger(EditX, EditY))
		
		For sx As Integer = 0 to SelectionSize-1
			For sy As Integer = 0 to SelectionSize-1
				trigger(EditX+sx, EditY+sy) = label
			Next
		Next
		
	ElseIf Btn_LoadTileSet.onClick() Then
		Dim As String ret = uiDlgInput("Tile set file path:",,,tileset)
		
		If ret <> "" Then
			tileset = ret
			
			map.loadTiles(tileset)
			
			LoadingIndicator("Loading tile set...")
			Sleep 500,1
		Endif
		
	Elseif Btn_ExportTriggers.onClick() Then
		'' Export a code template file
		Dim As String	fileName = uiDlgInput("File name:")
		
		If fileName <> "" Then
			Dim As Integer hndl = freefile
			
			open fileName for output as #hndl
			
			Print #hndl, "// Auto-generated script template"
			Print #hndl, "// Generated by EDIT2"
			Print #hndl, ""
			
			Print #hndl, "Goto EndOfTemplate"
			Print #hndl, ":LoadTemplate"
			Print #hndl, ""
			
			Print #hndl, "LoadTileSet " & chr(34) & tileset & chr(34)
			Print #hndl, "LoadTileMap " & chr(34) & tilemap & chr(34)
			Print #hndl, ""
			
			Print #hndl, "Player Position 0 0"
			Print #hndl, ""
			
			Print #hndl, "Object Clear"
			Print #hndl, ""
			
			'' Add the trigger statements
			For y As Integer = 0 to __MAP_SIZE
				For x As Integer = 0 to __MAP_SIZE
					If trigger(x,y) <> "" Then
						Print #hndl, "Trigger " & x & " " & y & " " & trigger(x,y)
					Endif
				Next
			Next
			
			'' Goto main
			Print #hndl, "Goto Main"
			Print #hndl, ""
			Print #hndl, "// Trigger code segments"
			
			'' Add empty code snippets
			For y As Integer = 0 to __MAP_SIZE
				For x As Integer = 0 to __MAP_SIZE
					If trigger(x,y) <> "" Then
						Print #hndl, ":" & trigger(x,y)
						
						If map.tiles(x,y).flag(3) Then
							Print #hndl, "// Action button flag"
						Endif
						
						Print #hndl, "// Auto-generated trigger segment"
						Print #hndl, "Goto Main"
						Print #hndl, ""
					Endif
				Next
			Next
			
			Print #hndl, "// End of Auto-generated template"
			Print #hndl, ":EndOfTemplate"
			Print #hndl, ""
			
			close #hndl
			
			LoadingIndicator("Exported code template.")
			Sleep 1000,1
		Endif
	
	ElseIf Btn_LoadTileMap.onClick() Then
		Dim As String ret = uiDlgInput("Tile map file path:",,,tilemap)
		
		If ret <> "" Then
			tilemap = ret
			
			map.loadMap(tilemap)
			
			LoadingIndicator("Loading tile map...")
			Sleep 500,1
		Endif
		
	Endif
	
	'' Tile window
	If Btn_ClearTile.onClick() Then
		'' Clear flags
		map.tiles(EditX, EditY).solid = 0
		
		For i As Integer = 0 to 3
			For sx As Integer = 0 to SelectionSize-1
				For sy As Integer = 0 to SelectionSize-1
					map.tiles(EditX+sx, EditY+sy).flag(i) = 0
				Next
			Next
		Next
		
		map.refresh(showDebug)
		changesSaved = false
		
		LoadingIndicator("Cleared all flags", "(" & EditX & ", " & EditY & ")")
		Sleep 1000,1
		
	Elseif Btn_TglSolid.onClick() Then
		map.tiles(EditX, EditY).solid = not map.tiles(EditX, EditY).solid
		changesSaved = false
		Sleep 200,1
		
	Endif
	
	For i As Integer = 0 to 3
		If Btn_TglFlag(i).onClick() Then
			If Multikey(fb.SC_CONTROL) Then
				map.tiles(EditX, EditY).flag(i) = not map.tiles(EditX, EditY).flag(i)
			Else
				Dim As Boolean	setFlag = not map.tiles(EditX, EditY).flag(i)
				
				For sx As Integer = 0 to SelectionSize-1
					For sy As Integer = 0 to SelectionSize-1
						map.tiles(EditX+sx, EditY+sy).flag(i) = setFlag
					Next
				Next
			Endif
			
			If ShowDebug Then
				map.refresh(ShowDebug)
			Endif
			
			changesSaved = false
			Sleep 200,1
		Endif
	Next
	
	'' Map interactions '''''''''''''''''''''''''''''''''''''''''''''''''''
	If inBounds( mouseX, mouseY, map.vp_x, map.vp_y, map.vp_x + map.vp_w, map.vp_y + map.vp_h) Then
		If ( mouseButtons and 1 ) and Multikey(fb.SC_ALT) Then
			'' Viewport scrolling
			map.vp_sx = ( (mouseX-map.vp_x) / map.vp_w ) * (__TILE_SIZE*__MAP_SIZE)
			map.vp_sy = ( (mouseY-map.vp_y) / map.vp_h ) * (__TILE_SIZE*__MAP_SIZE)
			
			' If the viewport is wide enough don't scroll
			If map.vp_w > 1000 Then
				map.vp_sx = 0
			Endif

			' snap to edges
			If map.vp_sx < __SCROLL_SNAP__ Then
				map.vp_sx = 0
			ElseIf map.vp_sx > (((__TILE_SIZE*__MAP_SIZE)-map.vp_w)-__SCROLL_SNAP__) Then
				map.vp_sx = ((__TILE_SIZE*__MAP_SIZE)-map.vp_w)
			Endif
			
			If map.vp_sy < __SCROLL_SNAP__ Then
				map.vp_sy = 0
			ElseIf map.vp_sy > (((__TILE_SIZE*__MAP_SIZE)-map.vp_h)-__SCROLL_SNAP__) Then
				map.vp_sy = ((__TILE_SIZE*__MAP_SIZE)-map.vp_h)
			Endif
			
		''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
		ElseIf ( mouseButtons and 1 ) or ( mouseButtons and 2) Then
			'' Set tile to be edited
			EditX = ( mouseX - map.vp_x + map.vp_sx - (__TILE_SIZE/2) ) / __TILE_SIZE
			EditY = ( mouseY - map.vp_y + map.vp_sy - (__TILE_SIZE/2) ) / __TILE_SIZE
			
			'' Hold control to set tile, otherwise just pick the tile
			If Multikey(fb.SC_CONTROL) Then
				Dim As Integer	setTile = IIF( mouseButtons and 1, EditTile1ID, EditTile2ID )
				
				For sx As Integer = 0 to SelectionSize-1
					For sy As Integer = 0 to SelectionSize-1
						map.tiles(EditX+sx, EditY+sy).tID(EditLayer) = setTile + sx + (sy*__TILESET_WIDTH)
					Next
				Next
				
				map.refresh(showDebug)
				changesSaved = false
				
			'' Hold shift to set/unset collision
			Elseif Multikey(fb.SC_LSHIFT) Then
				'' Enable debug and reset the selection size so we can see what we are doing
				showDebug = true
				
				'' Set the solid flag appropriately
				If Multikey(fb.SC_X) Then
					map.tiles(EditX, EditY).solid = IIF( mouseButtons and 1, true, false )
					SelectionSize = 1
				Else
					For sx As Integer = 0 to SelectionSize-1
						For sy As Integer = 0 to SelectionSize-1
							map.tiles(EditX+sx, EditY+sy).solid = IIF( mouseButtons and 1, true, false )
						Next
					Next
				Endif
				
				
				map.refresh(showDebug)
				changesSaved = false
			Endif
		Endif
	Endif
	
	'' Choose tiles from the map ''''''''''''''''''''''''''''''''''''''''''
	If Btn_SetFG_Tile.onClick() or userHotkey(_HK_PICK_FG) Then
		EditTile1ID = map.tiles(EditX, EditY).tID(EditLayer)
	Endif
	
	If Btn_SetBG_Tile.onClick() or userHotkey(_HK_PICK_BG) Then
		EditTile2ID = map.tiles(EditX, EditY).tID(EditLayer)
	Endif
	
	' Don't mess up the stack with temp vars
	Scope
	Dim As Integer plx, ply
	Dim As Integer plw, plh
	
	plx = Win_Palette.context.posX + 4
	ply = Win_Palette.context.posY + 24
	
	plw = 512
	plh = __WIN_WIDTH__ - 32
	
	If inBounds( mouseX, mouseY, plx, ply, plx+plw, ply+plh ) Then
		
		' Pick tiles from the palette
		If ( mouseButtons and 1 ) Then
			Dim As Integer stx, sty
			
			stx = ( mouseX - plx - 8 ) / __TILE_SIZE
			sty = ( mouseY - ply - 8 ) / __TILE_SIZE
			
			sty += paletteScroll
			
			EditTile1ID = ( sty * __TILESET_WIDTH ) + stx
		Endif
		
		If ( mouseButtons and 2 ) Then
			Dim As Integer stx, sty
			
			stx = ( mouseX - plx - 8 ) / __TILE_SIZE
			sty = ( mouseY - ply - 8 ) / __TILE_SIZE
			
			sty += paletteScroll
			
			EditTile2ID = ( sty * __TILESET_WIDTH ) + stx
		Endif
	Endif
	End Scope
	
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	Sleep regulateFPS(60),1
	
	'' Quit '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	If Multikey(1) or InKey() = Chr(255) & "k" Then
		If changesSaved Then
			End
		Else
			If uiDlgConfirm("You have unsaved changes, quit anyway?") Then
				End
			Endif 
		Endif
	Endif
Loop

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Utility Functions
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Sub framerate( ByVal x As Integer, ByVal y As Integer )
	Dim As String		outputString
	
	Static As Double	prevTime
	Static As Double	frameTime
	
	frameTime = Timer - prevTime
	prevTime = Timer
	
	outputString = Cast(Integer, 1/frameTime) & " FPS  "
	
	Line ( x-1, y-1 )-STEP(Len(outputString)*8,10), rgb(0,0,0), BF
	Draw String ( x, y ), outputString, rgb(255,220,0)
End Sub

' Draw a specific tile
Sub drawTile( ByVal tID As Integer, ByVal x As Integer, ByVal y As Integer, ByVal tilemap As Screen Ptr, ByVal target As Any Ptr )
	' border
	Line target, (x-1,y-1)-STEP(34,34), rgb(40,40,40), BF
	Line target, (x,y)-STEP(32,32), rgb(0,0,0), BF
	
	' Calculate tile position in the tilemap
	Dim As Integer tx, ty
	_tm_1to2d( tID, __TILESET_WIDTH, tx, ty)
	
	' Draw the specific tile
	Put target, (x,y), tilemap->scr_tileset, _
		(tx*__TILE_SIZE, ty*__TILE_SIZE)-STEP(31,31), PSET
End sub

' Draw a checkerboard pattern for transparent images
Sub checkerBoard( ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer, ByVal target As Any Ptr = 0)
	'Line (x,y)-STEP(w,h), rgb(0,0,0), BF
	'return 
	
	''''''''''''''''''''''''''''''''''''
	Dim As Integer squareSize = 8
	Dim As Integer fgc = rgb(100,100,100)
	Dim As Integer bgc = rgb(80,80,80)
	
	Dim As Any Ptr t = ImageCreate(squareSize*2,squareSize*2, bgc)
	Dim As Any Ptr outp = ImageCreate(w,h)
	
	Line t, (0,0)-STEP(squareSize,squareSize), fgc, BF
	Line t, (squareSize,squareSize)-STEP(squareSize,squareSize), fgc, BF
	
	For yi As Integer = 0 to h+(squareSize*2) STEP squareSize*2
		For xi As Integer = 0 to w+(squareSize*2) STEP squareSize*2
			Put outp, (xi,yi), t, PSET
		Next
	Next
	
	Put target, (x,y), outp, PSET
	
	ImageDestroy(outp)
	ImageDestroy(t)
End Sub

' Draw a box around something that is selected
Sub SelectBox( ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer, _
	ByVal colour As Integer = rgb(200,0,180), Byval target As Any Ptr = 0 )
	
	Line target, (x,y)-STEP(w-1,h-1), colour or rgb(20,20,20), B
	Line target, (x-1,y-1)-STEP(w+1,h+1), colour, B
End Sub

' Let the user know something is happening
Sub LoadingIndicator( ByVal line1 As String = "Loading...", ByVal line2 As String = "" )
	Line ( (__XRES__/2)-(Len(line1)*4)-4, (__YRES__/2)-(12) )-STEP( (Len(line1)*8)+8, 24 ), rgb( 120, 120, 120 ), BF
	
	Draw String ( (__XRES__/2)-(len(line1)*4), (__YRES__/2)-10 ), line1, rgb(80,80,80)
	Draw String ( (__XRES__/2)-(len(line2)*4), (__YRES__/2) ), line2, rgb(80,80,80)
End Sub

'' Hotkeys
Function userHotkey( ByVal key As Integer, ByVal modifier As Integer = -1, ByVal block As Boolean = true ) As Boolean
	Dim As Boolean	ret
	
	'' Check if the key is pressed
	If Multikey(key) and IIF( modifier = -1, -1, Multikey(modifier)) Then
		ret = true
		
		'' Prevent keys being repeated too quickly
		Sleep 200,1
	Endif
	
	'' Wait for keyUp to prevent key repeats 
	If block and ret Then
		Do:Sleep 10,1:Loop Until (not Multikey(key)) and IIF(modifier = -1, -1, not Multikey(modifier))
		Sleep 200,1
	Endif
	
	'' Return true/false
	Return ret
End Function
