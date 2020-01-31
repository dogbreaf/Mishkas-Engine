' Refactored to be more sensible 13/1/2019
#include once "fbgfx.bi"

' Changing the number of layers will break binary compatability with old files, so probs dont
#define __LAYER_COUNT__ 3
#define __TILESET_PAGES__ 4

#define __FH_MAGIC__ "TILEMAP.V2"

Declare Function _tm_1to2d(ByVal i As Integer, ByVal xSize As Integer, ByRef x As Integer, ByRef y As Integer) As Integer

Enum FlagType
	F_RESERVED0
	F_RESERVED1
	F_RESERVED2
	F_ETRIGGER
End Enum

Type tile
	tID(__LAYER_COUNT__) As Integer

	'' Flags
	solid	As Byte
	flag(3) As Byte
End Type

' For future use
Type tilemapHeader
	magic		As String*10 = __FH_MAGIC__
	
	tmWidth		As Integer = 32
	tmHeight	As Integer = 32
	
	reservedInt(8)	As Integer
	
	ReservedString	As String*32
End Type

Type screen
	' For future use
	fileHeader As tilemapHeader
	
	' Image buffers
	scr_tileset As fb.Image Ptr       ' The source tileset


	scr_buffer( __LAYER_COUNT__ ) As fb.Image Ptr

	' viewport settings
	vp_w As Integer                   ' The viewport size
	vp_h As Integer

	vp_x As Integer                   ' The drawing position of the viewport
	vp_y As Integer

	vp_sx As Integer                  ' The viewport position in the buffer
	vp_sy As Integer

	' Tilemap data
	tiles(32,32) As Tile           ' The tilemap data

	'
	Declare Sub init( ByVal As String = "", ByVal As String = "" )

	Declare Sub refresh( ByVal debug As Integer = 0 )
	Declare Sub draw( ByVal layer As Integer = 0 )

	Declare Sub loadMap( ByVal As String )
	Declare Sub loadTiles( ByVal As String )
End Type

Sub screen.loadTiles( ByVal tileset As String )
	LoadImageFile(tileset, this.scr_tileset)
End Sub

Sub screen.loadMap( ByVal tilemap As String )
	Dim As Integer hndl

	hndl = FreeFile

	Open tilemap For Binary As #hndl

	if Err > 0 then
	return
	else
	
	Get #hndl,, this.fileHeader
	Get #hndl,, this.tiles()

	Close #hndl
	endif
End Sub

Sub screen.refresh( ByVal debug As Integer = 0 )
	For i As Integer = 0 to __LAYER_COUNT__
		Line scr_buffer(i), (0,0)-(1024,1024), rgb(255,0,255), BF
		
		' Three dimensional For is kind of ugly and gross
		For y As Integer = 0 to 32
			For x As Integer = 0 to 32
				Dim As Integer tx,ty

				_tm_1to2d(tiles(x,y).tID(i), 16, tx, ty)

				tx = tx*32
				ty = ty*32

				if tx > 512 then:tx = 0:endif
				if ty > 512*__TILESET_PAGES__ then:ty = 0:endif

				Put scr_buffer(i), (x*32, y*32), scr_tileset, (tx,ty)-STEP(31,31), TRANS
			Next
		Next
	Next
	
	if debug then
		For y As Integer = 0 to 32
		For x As Integer = 0 to 32
			if tiles(x,y).solid then
				line scr_buffer(__LAYER_COUNT__), (x*32,y*32)-STEP(31,31), rgb(255,0,0), B
			endif

			For j As Integer = 0 to 3
				if tiles(x,y).flag(j) then
					line scr_buffer(__LAYER_COUNT__), _
						((x*32)+(4*j),y*32)-STEP(4,4), _
						rgb(50*j,255-(50*j),255), BF
				endif
			Next
		Next
		Next
	endif
End Sub

Sub screen.draw(ByVal LayerNumber As Integer = 0 )
	if vp_sx < 0 then:vp_sx = 1024 - vp_sx:endif
	if vp_sy < 0 then:vp_sy = 1024 - vp_sy:endif

	if vp_sx > 1024 then:vp_sx = vp_sx - 1024:endif
	if vp_sy > 1024 then:vp_sy = vp_sy - 1024:endif

	Put (vp_x, vp_y), scr_buffer(LayerNumber), (vp_sx, vp_sy)-STEP(vp_w, vp_h), TRANS
End Sub

Sub screen.init( ByVal tileset As String = "", ByVal tilemap As String = "" )
	' Tilesets must be 512x512 pixels containing 256 32x32 pixel tiles for simplicity
	' if the tilset image does not fit it will be placed at the top left or cropped
	' The internal tilemap is always 32x32 tiles
	this.scr_tileset = imagecreate(512,512*__TILESET_PAGES__)
	
	For i As Integer = 0 to __LAYER_COUNT__
		this.scr_buffer(i)  = imagecreate(1024,1024)
		
		Line this.scr_buffer(i),  (0,0)-(1024,1024), rgb(255,0,255), BF
	Next

	' Set viewport defaults
	vp_w = 512
	vp_h = 256
	vp_x = 0
	vp_y = 0
	vp_sx = 0
	vp_sy = 0

	' Load the files if they were specified
	if ( tileset <> "" ) then
		LoadImageFile(tileset, this.scr_tileset)
	endif

	if ( tilemap <> "" ) then
		this.loadMap(tilemap)
	endif
End Sub

Function _tm_1to2d(ByVal i As Integer, ByVal xSize As Integer, ByRef x As Integer, ByRef y As Integer) As Integer
	'' There must be a faster way but I don't know what it is
	Dim As Integer ti = 0
	
	For ty As Integer = 0 to (xSize*__TILESET_PAGES__)-1
		For tx As Integer = 0 to xSize-1
			If ti = i Then
				x = tx
				y = ty
				
				Return -1
			Endif
			
			ti += 1
		Next
	Next
	
	Return 0
End Function

