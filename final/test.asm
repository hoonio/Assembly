; ECE 291 Fall 2003 Final Project
; --------------------------------------
; --  C & C: 10 seconds               --
; --  (Castles & Cannons: 10 seconds  --
; --------------------------------------
;
; Group members:
;  Ki Chung
;  Seunghoon Kim
;  Gi Hyun Ko
;  Hyun J Jeong
;
; Instructor:
;  Doug Jones
;
; Mentor:
;  Mark Lippmann
;
;
; Version 1.0

%include "lib291.inc"

	BITS	32

	GLOBAL	_main

; Constant definitions

	TIMER_INT		EQU	1Ch	; timer int #

	SCREEN_WIDTH		EQU	640	; width of resolution
	SCREEN_HEIGHT		EQU	480	; height of resolution
	GAME_MAP_WIDTH		EQU	65	; width of game map in grids
	GAME_MAP_HEIGHT		EQU	60	; height of game map in grids
	MAP_PIXEL_WIDTH		EQU	520	; width of game map in pixels
	MAP_PIXEL_HEIGHT	EQU	480	; height of game map in pixels

	A			EQU	0000000100000000b ; map value for empty P1 region
	B			EQU	0000000100000100b ; map value for empty P2 region
	I			EQU	0000001000000000b ; map value for P1 obstacle
	J			EQU	0000001000000100b ; map value for P2 obstacle
	P			EQU	0000001100000000b ; map value for P1 castle
	Q			EQU	0000001100000100b ; map value for P2 castle
	U			EQU	0000000000000000b ; map value for unavailable terrain

	STATUSBAR_WIDTH		EQU	120	; width of status bar
	STATUSBAR_HEIGHT	EQU	480	; height of status bar
	STATUSBAR_X		EQU	520	; x coordinate for status bar
	STATUSBAR_Y		EQU	0	; y coordinate for status bar

	WIN_BANNER_WIDTH	EQU	50	; width of win banner
	WIN_BANNER_HEIGHT	EQU	50	; height of win banner
	WIN_BANNER_X		EQU	50	; x coordinate for win banner
	WIN_BANNER_Y		EQU	50	; y coordinate for win banner

	DEPLOY_BANNER_WIDTH	EQU	50	; width of deploy banner
	DEPLOY_BANNER_HEIGHT	EQU	50	; height of deploy banner
	BATTLE_BANNER_WIDTH	EQU	50	; width of battle banner
	BATTLE_BANNER_HEIGHT	EQU	50	; height of battle banner
	REBUILD_BANNER_WIDTH	EQU	50	; width of rebuild banner
	REBUILD_BANNER_HEIGHT	EQU	50	; height of rebuild banner

	BANNER_INIT_X		EQU	640	; x coordinate for initial banner location
	BANNER_INIT_Y		EQU	100	; y coordinate for initial banner location

	BIG_NUM_WIDTH		EQU	40	; width of big number font
	BIG_NUM_HEIGHT		EQU	55	; height of big number font

	CASTLE_WIDTH		EQU	24	; width of castle image buffer
	CASTLE_HEIGHT		EQU	24	; height of castle image buffer

	WALL_WIDTH		EQU	8	; width of wall
	WALL_HEIGHT		EQU	8	; height of wall
	
	CANNON_WIDTH	EQU 16  ; width of cannon
	CANNON_HEIGHT	EQU 16  ; height of cannon

	INIT_CURSOR_WIDTH	EQU	56	; width of init cursor
	INIT_CURSOR_HEIGHT	EQU	72	; height of init cursor

	BATTLE_CURSOR_WIDTH	EQU	24	; width of battle cursor
	BATTLE_CURSOR_HEIGHT	EQU	24	; height of battle cursor

	NUM_FRAMES_INIT_CURSOR	EQU	16	; number of frames for initialize cursor
	NUM_FRAMES_BATTLE_CURSOR	EQU	8 ; number of frames for battle cursor

	DIM_VAL			EQU	50	; value for dimming buffer

	MAX_CANNON		EQU	30	; max number of cannons allowed
	NUM_HANDICAP_CANNON	EQU	4	; number of deploy cannons given to player who lost
	NUM_INIT_TERRITORY	EQU	63	; amount of initial territory in grids
	NUM_TOTAL_ROUNDS	EQU	10	; total number of game rounds

	INIT_PHASE		EQU	00000000b ; phase value for initialize
	DEPLOY_PHASE		EQU	00100000b ; phase value for deploy
	BATTLE_PHASE		EQU	01000000b ; phase value for battle
	REBUILD_PHASE		EQU	01100000b ; phase value for rebuild
	BREAK_PHASE		EQU	10000000b ; phase value for break
	BREAK_DEPLOY_PHASE	EQU	10000000b ; break before deploy phase
	BREAK_BATTLE_PHASE	EQU	10000001b ; break before battle phase
	BREAK_REBUILD_PHASE	EQU	10000010b ; break before rebuild phase
	BREAK_TIME		EQU	10	; duration of break phase

	OCCUPIED		EQU	00000001b ; map bit for occupied
	REGION			EQU	00001100b ; region bits in map buffer
	CANNON			EQU	00000010b ; map bit for cannon
	UNAVAILABLE		EQU	00000000b	; map value for unavailable grid

	CANNON_REMAINS	EQU	0000010000000000b ; map value for remains of destroyed cannon
	WALL_HIT		EQU	0000011000000000b ; map value for wall piece hit by cannon ball

	P1_OCCUPIED		EQU	0000000100000001b
	P1_REGION		EQU	0000000000000000b ; map value for P1 region
	P1_EMPTY		EQU	0000000100000000b ; map value for empty P1 region
	P1_CASTLE		EQU	0000001100000000b ; map value for P1 castle
	P1_WALL			EQU	0000010100000000b ; map value for P1 wall
	P1_CANNON		EQU	00000011b ; map value for P1 cannon
	P1_INIT_PHASE	EQU	00000001b ; bit for P1 initialize phase
	P1_DEPLOY_PHASE	EQU	00100001b ; bit for P1 deploy phase

	P2_OCCUPIED		EQU	0000000100000101b
	P2_REGION		EQU	0000000000000100b ; map value for P2 region
	P2_EMPTY		EQU	0000000100000100b ; map value for empty P2 region
	P2_CASTLE		EQU	0000001100000100b ; map value for P2 castle
	P2_WALL			EQU	0000010100000100b ; map value for P2 wall
	P2_CANNON		EQU	00000111b ; map value for P2 cannon
	P2_INIT_PHASE	EQU	00000010b ; bit for P2 initialize phase
	P2_DEPLOY_PHASE	EQU	00100010b ; bit for P2 deploy phase

	EXIT_FLAG		EQU	00000001b ; exit flag
	PRIMARY_FLAG	EQU	00100000b ; 'primary' input flag
	SECONDARY_FLAG	EQU	00010000b ; 'secondary' input flag
	UP_FLAG			EQU	00001000b ; 'up' input flag
	DOWN_FLAG		EQU	00000100b ; 'down' input flag
	LEFT_FLAG		EQU	00000010b ; 'left' input flag
	RIGHT_FLAG		EQU	00000001b ; 'right' input flag

	CANNONLIFE		EQU	10


	SIZE		EQU 4096 ; size of the DMA buffer in bytes
	ESC			EQU	1	; scancode for ESC


SECTION .bss

	_GraphicsMode	resw	1	; graphics mode #

	_kbINT		resb	1	; keyboard interrupt #
	_kbIRQ		resb	1	; keyboard IRQ
	_kbPort		resw	1	; keyboard port

	_MouseSeg	resw	1	; real mode segment for MouseCallback
	_MouseOff	resw	1	; real mode offset for MouseCallback
	_MouseX		resw	1	; X coordinate position of mouse on screen
	_MouseY		resw	1	; Y coordinate position of mouse on screen

	_TimeTick	resb	1	; tick counter for timer (for controlling time limit in _Game)
	_CBallTick	resb	1	; tick counter for timer (for updating cannon ball array)
	_AnimateTick	resb	1	; tick counter for timer (for animation)

	_Time		resb	1	; counter for game time

	_BannerX	resw	1	; x coordinate of banner
	_BannerY	resw	1	; y coordinate of banner

 
; image offset variables

	_StatusBarOff		resd	1	; offset of status bar image (120 x 480 x 4)
	_LeadOff		resd	1	; offset of Lead image buffer (20 x 20 x 4)

	_P1InitCursorOff	resd	1	; offset of P1 initialize cursor (56 x 72 x 4)
	_P1DeployCursorOff	resd	1	; offset of P1 initialize cursor (16 x 16 x 4)
	_P1BattleCursorOff	resd	1	; offset of P1 battle cursor (24 x 24 x 4)
	_P1TerrainOff		resd	1	; offset of P1 terrain image (8 x 8 x 4)
	_P1BlockOff		resd	1	; offset of P1 block image (8 x 8 x 4)
	_P1FlatWallOff		resd	1	; offset of P1 flat wall image (8 x 8 x 4)
	_P1BattleWallOff	resd	1	; offset of P1 battle wall image (?)
	_P1FlatCannonOff	resd	1	; offset of P1 flat cannon image (16 x 16 x 4)
	_P1BattleCannonOff	resd	1	; offset of P1 battle cannon image (16 x 16 x 4)
	_P1FlatCastleOff	resd	1	; offset of P1 flat castle image (24 x 24 x 4)
	_P1BattleCastleOff	resd	1	; offset of P1 battle castle image (24 x 24 x 4)
	_P1WinBannerOff		resd	1	; offset of win banner for P1 (?)

	_P2InitCursorOff	resd	1	; offset of P2 initialize cursor (56 x 72 x 4)
	_P2DeployCursorOff	resd	1	; offset of P2 initialize cursor (16 x 16 x 4)
	_P2BattleCursorOff	resd	1	; offset of P2 battle cursor (24 x 24 x 4)
	_P2TerrainOff		resd	1	; offset of P2 terrain image (8 x 8 x 4)
	_P2BlockOff		resd	1	; offset of P2 block image (8 x 8 x 4)
	_P2FlatWallOff		resd	1	; offset of P2 flat wall image (8 x 8 x 4)
	_P2BattleWallOff	resd	1	; offset of P2 battle wall image (?)
	_P2FlatCannonOff	resd	1	; offset of P2 flat cannon image (16 x 16 x 4)
	_P2BattleCannonOff	resd	1	; offset of P2 battle cannon image (16 x 16 x 4)
	_P2FlatCastleOff	resd	1	; offset of P2 flat castle image (24 x 24 x 4)
	_P2BattleCastleOff	resd	1	; offset of P2 battle castle image (24 x 24 x 4)
	_P2WinBannerOff		resd	1	; offset of win banner for P2 (?)

	_InvalidBlockOff	resd	1	; offset of invalid block image (8 x 8 x 4)
	_InvalidCannonOff	resd	1	; offset of invalid cannon image (8 x 8 x 4)
	_CannonBallOff		resd	1	; offset of cannon ball image offset (8 x ? x 4)
	_ExplosionOff		resd	1	; offset of explosion image offset (16 x ? x 4)
	_RubblesOff		resd	1	; offset of rubbles image offset (8 x 8 x 4)
	_DestroyedCannonOff	resd	1	; offset of destroyed cannon image (16 x 16 x 4)

	_Terrain1Off		resd	1	; offset of terrain image #1 (520 x 480 x 4)
	_Terrain2Off		resd	1	; offset of terrain image #2 (520 x 480 x 4)
	_TerrainOff		resd	1	; offset of terrain image selected (520 x 480 x 4)

	_BigNumFontOff		resd	1	; offset of big number font image buffer (?)
	_SmallNumFontOff	resd	1	; offset of small number font image buffer (?)
	_BlueNumFontOff		resd	1	; offest of blue number font image buffer (?)

	_BattleBannerOff	resd	1	; offset of battle phase banner image buffer (?)
	_RebuildBannerOff	resd	1	; offset of rebuild phase banner image buffer (?)
	_DeployBannerOff	resd	1	; offset of deploy phase banner image buffer (?)


; sound offset variables

	_FireSndOff		resd	1	; offset of cannon firing sound (?)
	_ExplosionSndOff	resd	1	; offset of explosion sound (?)
	_BuildWallSndOff	resd	1	; offset of placing wall piece sound (?)
	_BuildCannonSndOff	resd	1	; offset of placing cannon sound (?)
	_InvalidSndOff		resd	1	; offset of invalid move for placing object sound (?)

	_IntroBGMOff		resd	1	; offset of intro background music (?)
	_BattleBGMOff		resd	1	; offset of battle phase background music (?)
	_RebuildBGMOff		resd	1	; offset of rebuild phase background music (?)
	_DeployBGMOff		resd	1	; offset of deploy phase background music (?)
	
	_FireSndSize		resd	1	; size of cannon firing sound (?)
	_ExplosionSndSize	resd	1	; size of explosion sound (?)
	_BuildWallSndSize	resd	1	; size of placing wall piece sound (?)
	_BuildCannonSndSize	resd	1	; size of placing cannon sound (?)
	_InvalidSndSize		resd	1	; size of invalid move for placing object sound (?)

	_IntroBGMSize		resd	1	; size of intro background music (?)
	_BattleBGMSize		resd	1	; size of battle phase background music (?)
	_RebuildBGMSize		resd	1	; size of rebuild phase background music (?)
	_DeployBGMSize		resd	1	; size of deploy phase background music (?)
	
	
; DMA and Sound Variables
	DMASel		resw	1    ;DMA selector
	DMAAddr		resd	1    ;DMA address
	DMAChan		resb	1    ;DMA channel
	BGMPos		resd	1    ;Next address of the BGM to refill
	BGMSize		resd	1    ;size of the BGM currently playing
	BGMOff		resd	1    ;Starting offset of the current BGM
	NextPos		resd	1    ;position marker for BGM, starting from 0
	SFXOff      resd    1    ;Starting offset of the sound effect
	SFXPos      resd	1    ;next address of the SFX to mix
	SFXSize		resd	1    ;size of the current sound effect
	MixCycle	resd	1    ;number of cycles required to mix SFX
	;RemCycle	resd	1
	ISR_Called	resd	1    ;number of times soundISR is called

; map and buffer offset variables

	_GameMapOff	resd	1	; offset of game map buffer (65 x 60 x 2)
	_ScreenOff	resd	1	; offset of screen buffer (640 x 480 x 4)
	_AuxScreenOff	resd	1	; offset of secondary screen buffer (520 x 480 x 4) (for backup purposes)
	_MapScreenOff	resd	1	; offset of map screen buffer (520 x 480 x 4)
	_OverlayOff	resd	1	; offset of overlay buffer (520 x 480 x 4)


; game data variales

	_P1X			resw	1	; x coordinate of P1 cursor
	_P1Y			resw	1	; y coordinate of P1 cursor
	_P1Score		resw	1	; score for P1
	_P1Life			resb	1	; indicates how many life P1 has
	_P1CurrentBlock		resw	1	; current wall piece for P1 player
	_NumP1Castle		resb	1	; number of conquered P1 castle
	_NumP1Territory		resw	1	; number of conquered grid by P1
	_NumP1Cannon		resb	1	; number of P1 cannons on the map
	_NumP1DeployCannon	resb	1	; number of P1 cannons available for deployment
	_P1CastleArray		resd	1	; array of castles for P1 (10 x 4)
	_P1CannonArray		resd	1	; array of cannons for P1 (30 x 4)

	_P2X			resw	1	; x coordinate of P2 cursor
	_P2Y			resw	1	; y coordinate of P2 cursor
	_P2Score		resw	1	; score for P2
	_P2Life			resb	1	; indicates how many life P2 has
	_P2CurrentBlock		resw	1	; current wall piece for P2 player
	_NumP2Castle		resb	1	; number of conquered P2 castle
	_NumP2Territory		resw	1	; number of conquered grid by P2
	_NumP2Cannon		resb	1	; number of P2 cannons on the map
	_NumP2DeployCannon	resb	1	; number of P2 cannons available for deployment
	_P2CastleArray		resd	1	; array of castles for P2 (10 x 4)
	_P2CannonArray		resd	1	; array of cannons for P2 (30 x 4)

	_CBallArray		resd	1	; array of cannon balls currently on map (60 x 8)
	;_BlockArray		resd	1	; array of 19 available wall pieces (19 x 2)
	_ExplosionArray		resd	1	; array of explosion grids (30 x 4)
	_NumTotalCastle		resb	1	; number of castles available for each player
	_NumRounds		resb	1	; number of game rounds played
	_BattleTime		resw	1	; duration of battle phase
	_RebuildTime		resw	1	; duration of rebuild phase
	_DeployTime		resw	1	; duration of deploy phase

	_PointQueue		resd	1	; queue offset for update enclose region
	_QueueHead		resd	1	; queue head
	_QueueTail		resd	1	; queue tail

; line algorithm variables
	_x1			resw	1
	_x2			resw	1
	_y1			resw	1
	_y2			resw	1
	_newx			resw	1
	_newy			resw	1
	_dx			resw	1
	_dy			resw	1
	_lineerror		resw	1
	_xhorizinc		resw	1
	_xdiaginc		resw	1
	_yvertinc		resw	1
	_ydiaginc		resw	1
	_errordiaginc		resw	1
	_errornodiaginc		resw	1

; flags and status indicators

	_DMA_Refill_Flag	resb	1   ; Decides which half of the DMA buffer to refill
	_DMA_Repeat_Flag   	resb	1   ; decides whether do repeat
	_DMA_Mix		resb	1   ; to mix sounds or not
	_BGM_On			resb	1   ; BGM On or not?
	_Flags			resb	1	; program flags
	_P1_InputFlags		resb	1	; player 1 input flags
	_P2_InputFlags		resb	1	; player 2 input flags
	_Phase				resb	1	; phase indicator




SECTION .data

; map data for terrain 1
;                       0         .         1         .         2         .         3         .         4         .         5         .         6
	_Map1	dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A ;0
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,I,I,I,A,A,A,A ;
		dw	A,A,A,A,A,A,A,A,A,A,I,I,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,I,P,I,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,I,P,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,I,I,I,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,I,I,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,I,I,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,I,P,I,A,A,A,A,A,A,A,U,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,I,I,I,A,A,A,A,A,U,U,U,U,U,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A ;1
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,A,A,A,A,A,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,A,A,A,A,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,A,A,A,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,A,A,A,A,A,A,A
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,I,I,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,A,A,A,A ;
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,I,P,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,A,A
		dw	A,A,A,A,A,I,I,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,I,I,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U
		dw	A,A,A,A,A,I,P,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U
		dw	A,A,A,A,A,I,I,I,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U ;2
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,U,U,U,U,U,U,U,U,U,U,U,U,U
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,U,U,U,U,U,U,U,U,U,U
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,U,U,U,U,U
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B ;
		dw	A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	A,A,A,U,U,U,U,A,A,A,A,A,A,A,A,A,A,U,U,U,U,A,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,U,U,U,U,A,A,A,A,A,U,U,U,U,U,U,A,A,A,A,A,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,U,U,U,U,U,U,U,A,U,U,U,U,U,U,U,U,U,U,U,A,A,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,J,Q,J,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B ;3
		dw	U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B ;
		dw	U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,U,U,U,U,U,B,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B ;4
		dw	U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,U,U,U,U,U,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,U,U,U,U,U,U,U,U,U,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,J,Q,J,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B ;
		dw	B,B,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B,B,B,B,B,B,J,Q,J,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,J,Q,J,B,B,B,B,B,B,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B ;5
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,J,Q,J,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,J,J,J,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B ;
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
		dw	B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B
;                       0         .         1         .         2         .         3         .         4         .         5         .         6

	_BlockArray		dw	0100h
				dw	0120h
				dw	0122h
				dw	010Ah
				dw	0138h
				dw	01A2h
				dw	0132h
				dw	0126h
				dw	01A1h	
				dw	01C2h
				dw	01AAh
				dw	019Ch
				dw	018Dh
				dw	0199h
				dw	01CCh
				dw	01D3h
				dw	018Eh
				dw	01A9h
				dw	01CAh

; keyboard input scancodes

	_P1_Up_Key		db	72	; scancode of P1 'up' key (NumPad '8')
	_P1_Down_Key		db	80	; scancode of P1 'down' key (NumPad '5')
	_P1_Left_Key		db	75	; scancode of P1 'left' key (NumPad '4')
	_P1_Right_Key		db	77	; scancode of P1 'right' key (NumPad '6')
	_P1_Primary_Key		db	25	; scancode of P1 'primary' key ('P')
	_P1_Secondary_Key	db	26	; scancode of P1 'secondary' key ('[')

	_P2_Up_Key			db	19	; scancode of P2 'up' key ('R')
	_P2_Down_Key		db	33	; scancode of P2 'down' key ('F')
	_P2_Left_Key		db	32	; scancode of P2 'left' key ('D')
	_P2_Right_Key		db	34	; scancode of P2 'right' key ('G')
	_P2_Primary_Key		db	16	; scancode of P2 'primary' key ('Q')
	_P2_Secondary_Key	db	30	; scancode of P2 'secondary' key ('A')


; required images

	_StatusBarFN		db	'StatusBar.png', 0
	_LeadFN			db	'Lead.png', 0

	_P1InitCursorFN		db	'P1InitCur.png', 0
	_P1DeployCursorFN	db	'P1DeployCur.png', 0
	_P1BattleCursorFN	db	'P1BattleCur.png', 0
	_P1TerrainFN		db	'P1Terrain.png', 0
	_P1BlockFN		db	'P1Block.png', 0
	_P1FlatWallFN		db	'P1FlatWall.png', 0
	_P1BattleWallFN		db	'P1BattleWall.png', 0
	_P1FlatCannonFN		db	'P1FlatCannon.png', 0
	_P1BattleCannonFN	db	'P1BattleCannon.png', 0
	_P1FlatCastleFN		db	'P1FlatCastle.png', 0
	_P1BattleCastleFN	db	'P1BattleCastle.png', 0
	_P1WinBannerFN		db	'P1WinBan.png', 0

	_P2InitCursorFN		db	'P2InitCur.png', 0
	_P2DeployCursorFN	db	'P2DeployCur.png', 0
	_P2BattleCursorFN	db	'P2BattleCur.png', 0
	_P2TerrainFN		db	'P2Terrain.png', 0
	_P2BlockFN		db	'P2Block.png', 0
	_P2FlatWallFN		db	'P2FlatWall.png', 0
	_P2BattleWallFN		db	'P2BattleWall.png', 0
	_P2FlatCannonFN		db	'P2FlatCannon.png', 0
	_P2BattleCannonFN	db	'P2BattleCannon.png', 0
	_P2FlatCastleFN		db	'P2FlatCastle.png', 0
	_P2BattleCastleFN	db	'P2BattleCastle.png', 0
	_P2WinBannerFN		db	'P2WinBanner.png', 0

	_InvalidBlockFN		db	'InvalidBlock.png', 0
	_InvalidCannonFN	db	'InvalidCannon.png', 0
	_CannonBallFN		db	'CannonBall.png', 0
	_ExplosionFN		db	'Explosion.png', 0
	_RubblesFN		db	'Rubbles.png', 0
	_DestroyedCannonFN	db	'DestroyedCannon.png', 0

	_Terrain1FN		db	'Terrain1.png', 0
	_Terrain2FN		db	'Terrain2.png', 0

	_BigNumFontFN		db	'BigNumFont.png', 0
	_SmallNumFontFN		db	'SmallNumFont.png', 0
	_BlueNumFontFN		db	'BlueNumFont.png', 0

	_BattleBannerFN		db	'BattleBanner.png', 0
	_RebuildBannerFN	db	'RebuildBanner.png', 0
	_DeployBannerFN		db	'DeployBanner.png', 0


; required sounds

	_FireSndFN		db	'Fire.wav', 0
	_ExplosionSndFN		db	'Explosion.wav', 0
	_BuildWallSndFN		db	'BuildWall.wav', 0
	_BuildCannonSndFN	db	'BuildCannon.wav', 0
	_InvalidSndFN		db	'Invalid.wav', 0

	_IntroBGMFN		db	'IntroBGM.wav', 0
	_BattleBGMFN		db	'BattleBGM.wav', 0
	_RebuildBGMFN		db	'RebuildBGM.wav', 0
	_DeployBGMFN		db	'DeployBGM.wav', 0


; others

	_RoundingFactor		dd	000800080h, 00000080h	;rounding factor for alpha-blending

 
SECTION .text

_main
	call	_LibInit

	; allocates screen buffer
	invoke	_AllocMem, dword SCREEN_WIDTH * SCREEN_HEIGHT * 4
	cmp	eax, -1
	je	near .memError
	mov	[_ScreenOff], eax

	; allocates backup screen buffer
	invoke	_AllocMem, dword SCREEN_WIDTH * SCREEN_HEIGHT * 4
	cmp	eax, -1
	je	near .memError
	mov	[_AuxScreenOff], eax

	; allocates map screen buffer
	invoke	_AllocMem, dword MAP_PIXEL_WIDTH * MAP_PIXEL_HEIGHT * 4
	cmp	eax, -1
	je	near .memError
	mov	[_MapScreenOff], eax

	; allocates overlay buffer
	invoke	_AllocMem, dword MAP_PIXEL_WIDTH * MAP_PIXEL_HEIGHT * 4
	cmp	eax, -1
	je	near .memError
	mov	[_OverlayOff], eax

	; allocates game map buffer
	invoke	_AllocMem, dword GAME_MAP_WIDTH * GAME_MAP_HEIGHT * 2
	cmp	eax, -1
	je	near .memError
	mov	[_GameMapOff], eax

	; allocates P1CastleArray buffer
	invoke	_AllocMem, dword 10 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P1CastleArray], eax

	; allocates P2CastleArray buffer
	invoke	_AllocMem, dword 10 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P2CastleArray], eax

	; allocates block array buffer
	invoke	_AllocMem, dword 19 * 2
	cmp	eax, -1
	je	near .memError
	mov	[_BlockArray], eax

	; allocates status bar image buffer
	invoke	_AllocMem, dword 120 * 480 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_StatusBarOff], eax

	; allocates lead image buffer
	invoke	_AllocMem, dword 20 * 20 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_LeadOff], eax

	; allocates big num image buffer
	invoke	_AllocMem, dword 400 * 55 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_BigNumFontOff], eax
	
	; allocates small num image buffer
	invoke	_AllocMem, dword 200 * 21 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_SmallNumFontOff], eax
	
	; allocates blue num image buffer
	invoke	_AllocMem, dword 100* 12 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_BlueNumFontOff], eax
	
	; allocates InvalidCannon image buffer
	invoke	_AllocMem, dword 16 * 16 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_InvalidCannonOff], eax
	
;	; allocates Explosion image buffer
;	invoke	_AllocMem, dword ??? * 4
;	cmp	eax, -1
;	je	near .memError
;	mov	[_ExplosionOff], eax
	
	; allocates CannonBall image buffer
	invoke	_AllocMem, dword 240 * 20 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_CannonBallOff], eax
	

	; allocates P1 init cursor image buffer
	invoke	_AllocMem, dword 896 * 72 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P1InitCursorOff], eax
	
	;allocates P1 deploy cursor 
	invoke	_AllocMem, dword 16 * 16 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P1DeployCursorOff], eax
	
	;allocates P1 battle cursor 
	invoke	_AllocMem, dword 16 * 16 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P1BattleCursorOff], eax
	
	; allocates P1 terrain image buffer
	invoke	_AllocMem, dword 8 * 8 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P1TerrainOff], eax

	; allocates P1 block image buffer
	invoke	_AllocMem, dword 8 * 8 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P1BlockOff], eax

	; allocates P1 flat cannon image buffer
	invoke	_AllocMem, dword 16 * 16 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P1FlatCannonOff], eax

	; allocates P1 flat castle image buffer
	invoke	_AllocMem, dword 24 * 24 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P1FlatCastleOff], eax

	; allocates P1 flat wall image buffer
	invoke	_AllocMem, dword 8 * 8 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P1FlatWallOff], eax

	; allocates P2 init cursor image buffer
	invoke	_AllocMem, dword 896 * 72 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P2InitCursorOff], eax
	
	;allocates P2 deploy cursor 
	invoke	_AllocMem, dword 16 * 16 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P2DeployCursorOff], eax
	
	;allocates P2 battle cursor 
	invoke	_AllocMem, dword 16 * 16 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P2BattleCursorOff], eax

	; allocates P2 terrain image buffer
	invoke	_AllocMem, dword 8 * 8 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P2TerrainOff], eax

	; allocates P2 block image buffer
	invoke	_AllocMem, dword 8 * 8 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P2BlockOff], eax

	; allocates P2 flat cannon image buffer
	invoke	_AllocMem, dword 16 * 16 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P2FlatCannonOff], eax

	; allocates P2 flat castle image buffer
	invoke	_AllocMem, dword 24 * 24 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P2FlatCastleOff], eax

	; allocates P2 flat wall image buffer
	invoke	_AllocMem, dword 8 * 8 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_P2FlatWallOff], eax

	; allocates Terrain1 image buffer
	invoke	_AllocMem, dword 520 * 480 * 4
	cmp	eax, -1
	je	near .memError
	mov	[_Terrain1Off], eax

	; Allocate Point Queue
	invoke	_AllocMem, dword 65 * 60 * 64
	cmp	eax, -1
	je	near .memError
	mov	[_PointQueue], eax

	; load image files
	invoke	_LoadPNG, dword _StatusBarFN, dword [_StatusBarOff], dword 0, dword 0
	invoke	_LoadPNG, dword _LeadFN, dword [_LeadOff], dword 0, dword 0
	invoke	_LoadPNG, dword _BigNumFontFN, dword [_BigNumFontOff], dword 0, dword 0
	invoke	_LoadPNG, dword _SmallNumFontFN, dword [_SmallNumFontOff], dword 0, dword 0
	invoke	_LoadPNG, dword _BlueNumFontFN, dword [_BlueNumFontOff], dword 0, dword 0
	invoke	_LoadPNG, dword _CannonBallFN, dword [_CannonBallOff], dword 0, dword 0
	invoke	_LoadPNG, dword _ExplosionFN, dword [_ExplosionOff], dword 0, dword 0
	invoke	_LoadPNG, dword _InvalidCannonFN, dword [_InvalidCannonOff], dword 0, dword 0
	
	
	invoke	_LoadPNG, dword _P1InitCursorFN, dword [_P1InitCursorOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P1DeployCursorFN, dword [_P1DeployCursorOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P1BattleCursorFN, dword [_P1BattleCursorOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P1TerrainFN, dword [_P1TerrainOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P1BlockFN, dword [_P1BlockOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P1FlatCannonFN, dword [_P1FlatCannonOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P1FlatCastleFN, dword [_P1FlatCastleOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P1FlatWallFN, dword [_P1FlatWallOff], dword 0, dword 0

	invoke	_LoadPNG, dword _P2InitCursorFN, dword [_P2InitCursorOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P2DeployCursorFN, dword [_P2DeployCursorOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P2BattleCursorFN, dword [_P2BattleCursorOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P2TerrainFN, dword [_P2TerrainOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P2BlockFN, dword [_P2BlockOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P2FlatCannonFN, dword [_P2FlatCannonOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P2FlatCastleFN, dword [_P2FlatCastleOff], dword 0, dword 0
	invoke	_LoadPNG, dword _P2FlatWallFN, dword [_P2FlatWallOff], dword 0, dword 0

	invoke	_LoadPNG, dword _Terrain1FN, dword [_Terrain1Off], dword 0, dword 0
	
	invoke	_LoadPNG, dword _InvalidBlockFN, dword [_InvalidBlockOff], dword 0, dword 0
	
	
	
	
	; install sound and load sound files
	invoke	_InstallSound                 ;install sound
	mov	byte [_BGM_On], 00h
	
	;Allocate Memory for sound files
	
	invoke	_AllocMem, dword 41126 
	mov		[_FireSndOff], eax
	
	invoke	_AllocMem, dword 42732
	mov		[_ExplosionSndOff], eax
	
	;invoke	_AllocMem, dword ????
	;mov		[_BuildWallSndOff], eax
	
	invoke	_AllocMem, dword 15564
	mov		[_BuildCannonSndOff], eax
	
	invoke	_AllocMem, dword 13260 
	mov		[_InvalidSndOff], eax
	
	invoke	_AllocMem, dword 2158002 
	mov			[_IntroBGMOff], eax
	
	invoke	_AllocMem, dword 1785514
	mov		[_BattleBGMOff], eax
	
	;invoke	_AllocMem, dword ????
	;mov		[_RebuildBGMOff], eax
	
	;invoke	_AllocMem, dword ????
	;mov		[_DeployBGMOff], eax
	
	;open sound files
	
	invoke	_OpenFile, dword _FireSndFN, word 0	
	mov		ebx, eax
	push	ebx
	invoke  _ReadFile, ebx, dword [_FireSndOff], dword 41126 
	mov		[_FireSndSize], eax
	pop		ebx
	invoke	_CloseFile, ebx
	
	invoke	_OpenFile, dword _ExplosionSndFN, word 0	
	mov		ebx, eax
	push	ebx
	invoke  _ReadFile, ebx, dword [_ExplosionSndOff], dword 42732
	mov		[_ExplosionSndSize], eax
	pop		ebx
	invoke	_CloseFile, ebx	
	
	;invoke	_OpenFile, dword _BuildWallSndFN, word 0	
	;mov		ebx, eax
	;push	ebx
	;invoke  _ReadFile, ebx, dword [_BuildWallSndOff], dword ????
	;mov		[_BuildWallSndSize], eax
	;pop		ebx
	;invoke	_CloseFile, ebx
	
	invoke	_OpenFile, dword _BuildCannonSndFN, word 0	
	mov		ebx, eax
	push	ebx
	invoke  _ReadFile, ebx, dword [_BuildCannonSndOff], dword 15564
	mov		[_BuildCannonSndSize], eax
	pop		ebx
	invoke	_CloseFile, ebx
	
	invoke	_OpenFile, dword _InvalidSndFN, word 0	
	mov		ebx, eax
	push	ebx
	invoke  _ReadFile, ebx, dword [_InvalidSndOff], dword 13260
	mov		[_InvalidSndSize], eax
	pop		ebx
	invoke	_CloseFile, ebx
	
	invoke	_OpenFile, dword _IntroBGMFN, word 0	
	mov	ebx, eax
	push	ebx
	invoke  _ReadFile, ebx, dword [_IntroBGMOff], dword 2158002
	mov	[_IntroBGMSize], eax
	pop	ebx
	invoke	_CloseFile, ebx
	
	invoke	_OpenFile, dword _BattleBGMFN, word 0	
	mov		ebx, eax
	push	ebx
	invoke  _ReadFile, ebx, dword [_BattleBGMOff], dword 1785514
	mov		[_BattleBGMSize], eax
	pop		ebx
	invoke	_CloseFile, ebx
	
;	invoke	_OpenFile, dword _RebuildBGMFN, word 0	
;	mov		ebx, eax
;	push	ebx
;	invoke  _ReadFile, ebx, dword [_RebuildBGMOff], dword ????
;	mov		[_RebuildBGMSize], eax
;	pop		ebx
;	invoke	_CloseFile, ebx
;	
;	invoke	_OpenFile, dword _DeployBGMFN, word 0	
;	mov		ebx, eax
;	push	ebx
;	invoke  _ReadFile, ebx, dword [_DeployBGMOff], dword ????
;	mov		[_DeployBGMSize], eax
;	pop		ebx
;	invoke	_CloseFile, ebx
;	
	; graphics initialize
	invoke	_InitGraphics, dword _kbINT, dword _kbIRQ, dword _kbPort
	test	eax, eax
	jnz	near .initGraphicsError

	; find graphics mode: SCREEN_WIDTH x SCREEN_HEIGHT x 32
	invoke	_FindGraphicsMode, word SCREEN_WIDTH, word SCREEN_HEIGHT, word 32, dword 1
	mov	[_GraphicsMode], ax

	; set graphics mode
	invoke	_SetGraphicsMode, word [_GraphicsMode]
	test	eax, eax
	jnz	near .setGraphicsError

	; keyboard initialize
	call	_InstallKbd
	test	eax, eax
	jnz	near .keyboardError

	; install timer ISR
	call	_InstallTmr
	test	eax, eax
	jnz	.timerError

	call	_Menu

	; exit program and clean up

.timerError
	call	_RemoveTmr

.keyboardError
	call	_RemoveKbd

.setGraphicsError
	call	_UnsetGraphicsMode

.initGraphicsError
	call	_ExitGraphics

.memError
	call	_LibExit
	ret


;-----------------
;-- void Menu() --
;-----------------
; Inputs : -
; Outpus : -
; Returns : -
; Calls : _Game, _Instruction, _Credits
; - The Menu from which the player can choose 'Play Game', 'Instruction', 'Credits', or 'Exit'
_Menu
	invoke _PlayBGM, dword [_IntroBGMOff], dword [_IntroBGMSize]
	mov	eax, [_Terrain1Off]
	mov	[_TerrainOff], eax

	mov	dword [_GameMapOff], _Map1
	mov	ebx, [_GameMapOff]
	xor	cx, cx

.fillCastleArrays
	cmp	cl, GAME_MAP_WIDTH
	jb	.notEndOfRow
	xor	cl, cl
	inc	ch

.notEndOfRow
	cmp	ch, GAME_MAP_HEIGHT
	je	.doneFillCastleArrays
	cmp	word [ebx], P
	je	.P1Castle
	cmp	word [ebx], Q
	je	.P2Castle
	jmp	.doneEntry

.P1Castle
	inc	byte [_NumTotalCastle]
	mov	edx, [_P1CastleArray]

.findP1EmptyElement
	cmp	dword [edx], 0
	je	.P1EmptyElement
	add	edx, 4
	jmp	.findP1EmptyElement

.P1EmptyElement
	movzx	ax, cl
	mov	[edx], ax
	movzx	ax, ch
	mov	[edx + 2], ax
	jmp	.doneEntry

.P2Castle
	mov	edx, [_P2CastleArray]

.findP2EmptyElement
	cmp	dword [edx], 0
	je	.P1EmptyElement
	add	edx, 4
	jmp	.findP2EmptyElement

.P2EmptyElement
	movzx	ax, cl
	mov	[edx], ax
	movzx	ax, ch
	mov	[edx + 2], ax

.doneEntry
	inc	cl
	add	ebx, 2
	jmp	.fillCastleArrays

.doneFillCastleArrays
	mov	ebx, [_P1CastleArray]
	mov	ax, [ebx]
	mov	[_P1X], ax
	mov	ax, [ebx + 2]
	mov	[_P1Y], ax

	mov	ebx, [_P2CastleArray]
	mov	ax, [ebx]
	mov	[_P2X], ax
	mov	ax, [ebx + 2]
	mov	[_P2Y], ax

	call	_Game
	ret


;------------------------
;-- void Instruction() --
;------------------------
_Instruction

ret


;--------------------
;-- void Credits() --
;--------------------
_Credits

ret

;-----------------
;-- void Game() --
;-----------------
; Inputs : -
; Outputs : -
; Returns : -
; Calls : _UpdateInitCursor, _UpdateCursor, _RotateBlock, _UpdateEnclosedRegion, _BuildCastle, _BuildCannon, _BuildWall, _GenerateRandomBlock, _UpdateCannonBall, _FireCannon, _ScrollBanner, _DrawStatusBar, _DrawMap, _DrawImage, _DrawDeployCursor, _DrawBlock, _DrawCannonBall, _ClearBuffer, _CopyBuffer, _ComposeBuffer
; - Handles game
_Game
	
	mov	byte [_P1Life], 2
	mov	byte [_P2Life], 2

	mov	word [_BattleTime], 10
	mov	word [_RebuildTime], 25
	mov	word [_DeployTime], 15

	mov	word [_BannerX], BANNER_INIT_X
	mov	word [_BannerY], BANNER_INIT_Y

	mov	byte [_Phase], P1_INIT_PHASE
	or	byte [_Phase], P2_INIT_PHASE

	mov	byte [_Time], 0
.loopGame
	test	byte [_Flags], EXIT_FLAG
	jnz	near .doneGame

	cmp	byte [_Phase], BREAK_DEPLOY_PHASE
	je	near .breakDeployPhase
	cmp	byte [_Phase], BREAK_BATTLE_PHASE
	je	near .breakBattlePhase
	cmp	byte [_Phase], BREAK_REBUILD_PHASE
	je	near .breakRebuildPhase

	invoke	_DrawStatusBar, dword [_ScreenOff], word STATUSBAR_X, word STATUSBAR_Y
	invoke	_DrawMap, dword [_MapScreenOff], dword [_GameMapOff]
	mov	al, 11100000b
	and	al, [_Phase]
	cmp	al, INIT_PHASE
	je	near .initPhase
	cmp	al, DEPLOY_PHASE
	je	near .deployPhase
	cmp	al, BATTLE_PHASE
	je	near .battlePhase
	cmp	al, REBUILD_PHASE
	je	near .rebuildPhase


.breakDeployPhase
	invoke	_ScrollBanner, dword _BannerX, dword _BannerY
	invoke	_CopyBuffer, dword [_AuxScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word 0, word 0
	invoke	_DrawImage, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_DeployBannerOff], word DEPLOY_BANNER_WIDTH, word DEPLOY_BANNER_HEIGHT, word [_BannerX], word [_BannerY], word 1, dword 1
;	invoke	_UpdateEnclosedRegion, dword [_GameMapOff]
	cmp	byte [_Time], BREAK_TIME
	jne	near .doneBreakPhase
	mov	byte [_Time], 0
	mov	byte [_Phase],  P1_DEPLOY_PHASE
	or	byte [_Phase],  P2_DEPLOY_PHASE
	mov	word [_BannerX], BANNER_INIT_X
	mov	word [_BannerY], BANNER_INIT_Y
	jmp	near .donePhase


.breakBattlePhase
	invoke	_ScrollBanner, dword _BannerX, dword _BannerY
	invoke	_CopyBuffer, dword [_AuxScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word 0, word 0
	invoke	_DrawImage, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_BattleBannerOff], word BATTLE_BANNER_WIDTH, word BATTLE_BANNER_HEIGHT, word [_BannerX], word [_BannerY], word 1, dword 1
	cmp	byte [_Time], BREAK_TIME
	jne	near .doneBreakPhase
	mov	byte [_Time], 0
	mov	byte [_Phase], BATTLE_PHASE
	mov	word [_BannerX], BANNER_INIT_X
	mov	word [_BannerY], BANNER_INIT_Y
	jmp	near .donePhase


.breakRebuildPhase
	invoke	_ScrollBanner, dword _BannerX, dword _BannerY
	invoke	_CopyBuffer, dword [_AuxScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word 0, word 0
	invoke	_DrawImage, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_RebuildBannerOff], word REBUILD_BANNER_WIDTH, word REBUILD_BANNER_HEIGHT, word [_BannerX], word [_BannerY], word 1, dword 1
	cmp	byte [_Time], BREAK_TIME
	jne	near .doneBreakPhase
	mov	byte [_Time], 0
	mov	byte [_Phase], REBUILD_PHASE
	mov	word [_BannerX], BANNER_INIT_X
	mov	word [_BannerY], BANNER_INIT_Y
	jmp	near .donePhase


.initPhase
	mov	al, [_Phase]
	and	al, ~INIT_PHASE
	test	al, P1_INIT_PHASE
	jnz	near .P1Init
	test	al, P2_INIT_PHASE
	jnz	near .P2Init
	mov	byte [_Phase], BREAK_DEPLOY_PHASE
	invoke	_DimBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word DIM_VAL
	invoke	_CopyBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_AuxScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word 0, word 0
	jmp	near .donePhase

.P1Init
	invoke	_UpdateInitCursor, dword [_P1CastleArray], dword _P1X, dword _P1Y, word [_P1_InputFlags]
	mov	ax, [_P1X]
	shl	ax, 3
	add	ax, 4
	mov	bx, [_P1Y]
	shl	bx, 3
	add	bx, 4
	invoke	_DrawImage, dword [_MapScreenOff], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, dword [_P1InitCursorOff], word INIT_CURSOR_WIDTH, word INIT_CURSOR_HEIGHT, ax, bx, word NUM_FRAMES_INIT_CURSOR, dword 1
	invoke	_BuildCastle, dword [_GameMapOff], word [_P1X], word [_P1Y], word P1_WALL, dword _NumP1Castle, dword _NumP1Territory, word [_P1_InputFlags], word P1_INIT_PHASE
	mov	al, [_Phase]
	and	al, ~INIT_PHASE
	test	al, P2_INIT_PHASE
	jnz	.P2Init
	jmp	.donePhase

.P2Init
	invoke	_UpdateInitCursor, dword [_P2CastleArray], dword _P2X, dword _P2Y, word [_P2_InputFlags]
	mov	ax, [_P2X]
	shl	ax, 3
	add	ax, 4
	mov	bx, [_P2Y]
	shl	bx, 3
	add	bx, 4
	invoke	_DrawImage, dword [_MapScreenOff], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, dword [_P2InitCursorOff], word INIT_CURSOR_WIDTH, word INIT_CURSOR_HEIGHT, ax, bx, word NUM_FRAMES_INIT_CURSOR, dword 1
	invoke	_BuildCastle, dword [_GameMapOff], word [_P2X], word [_P2Y], word P2_WALL, dword _NumP2Castle, dword _NumP2Territory, word [_P2_InputFlags], word P2_INIT_PHASE
	jmp	.donePhase

.deployPhase
	mov	al, [_Time]
	cmp	al, [_DeployTime]
	je	.deployTimeUp
	mov	bx, word [_Phase]
	and	bx, P1_DEPLOY_PHASE
	cmp	bx, P1_DEPLOY_PHASE
	je	near .P1Deploy
	mov	bx, word [_Phase]
	and	bx, P2_DEPLOY_PHASE
	cmp	bx, P2_DEPLOY_PHASE
	je	near .P2Deploy

.deployTimeUp
	mov	byte [_Time], 0
	mov	byte [_Phase], BREAK_BATTLE_PHASE
	invoke	_DimBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word DIM_VAL
	invoke	_CopyBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_AuxScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word 0, word 0
	jmp	near .donePhase

.P1Deploy
	invoke	_UpdateCursor, dword _P1X, dword _P1Y, word 0, word 0, word GAME_MAP_WIDTH - 1, word GAME_MAP_HEIGHT - 1, word [_P1_InputFlags]
	mov	ax, [_P1X]
;	shl	ax, 3
	mov	bx, [_P1Y]
;	shl	bx, 3
	invoke	_DrawDeployCursor, dword [_MapScreenOff], ax, bx, dword [_P1DeployCursorOff]
	invoke	_BuildCannon, dword [_GameMapOff], dword [_P1CannonArray], dword _NumP1DeployCannon, dword _NumP1Cannon, word [_P1X], word [_P1Y], word [_P1_InputFlags], word P1_OCCUPIED, word P1_DEPLOY_PHASE
	mov	bx, word [_Phase]
	and	bx, P2_DEPLOY_PHASE
	cmp	bx, P2_DEPLOY_PHASE
	jne	near .donePhase

.P2Deploy
	invoke	_UpdateCursor, dword _P2X, dword _P2Y, word 0, word 0, word GAME_MAP_WIDTH - 1, word GAME_MAP_HEIGHT - 1, word [_P2_InputFlags]
	mov	ax, [_P2X]
;	shl	ax, 3
	mov	bx, [_P2Y]
;	shl	bx, 3
	invoke	_DrawDeployCursor, dword [_MapScreenOff], ax, bx, dword [_P2DeployCursorOff]
	invoke	_BuildCannon, dword [_GameMapOff], dword [_P2CannonArray], dword _NumP2DeployCannon, dword _NumP2Cannon, word [_P2X], word [_P2Y], word [_P2_InputFlags], word P2_OCCUPIED, word P2_DEPLOY_PHASE
	jmp	near .donePhase


.battlePhase
	cmp	byte [_BGM_On], 01h
	je .BattleBGMOn
	invoke _StopBGM
	invoke _PlayBGM, dword[_BattleBGMOff], dword[_BattleBGMSize]
	mov	byte [_BGM_On], 01h
.BattleBGMOn	
	invoke	_DrawExplosion, dword [_MapScreenOff], dword [_GameMapOff], dword [_ExplosionArray], dword [_ExplosionOff]
	invoke	_UpdateCannonBall, dword [_GameMapOff], dword [_CBallArray]
	invoke	_DrawCannonBall, dword [_MapScreenOff], dword [_CBallArray], dword [_CannonBallOff]

	invoke	_UpdateCursor, dword _P1X, dword _P1Y, word 0, word 0, word MAP_PIXEL_WIDTH - 1, word MAP_PIXEL_HEIGHT - 1, word [_P1_InputFlags]
	invoke	_DrawImage, dword [_MapScreenOff], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, dword [_P1BattleCursorOff], word BATTLE_CURSOR_WIDTH, word BATTLE_CURSOR_HEIGHT, word [_P1X], word [_P1Y], word NUM_FRAMES_BATTLE_CURSOR, dword 1
	invoke	_FireCannon, dword [_GameMapOff], dword [_P1CannonArray], dword [_CBallArray], word [_P1X], word [_P1Y], word [_P1_InputFlags]

	invoke	_UpdateCursor, dword _P2X, dword _P2Y, word 0, word 0, word MAP_PIXEL_WIDTH - 1, word MAP_PIXEL_HEIGHT - 1, word [_P2_InputFlags]
	invoke	_DrawImage, dword [_MapScreenOff], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, dword [_P2BattleCursorOff], word BATTLE_CURSOR_WIDTH, word BATTLE_CURSOR_HEIGHT, word [_P2X], word [_P2Y], word NUM_FRAMES_BATTLE_CURSOR, dword 1
	invoke	_FireCannon, dword [_GameMapOff], dword [_P2CannonArray], dword [_CBallArray], word [_P2X], word [_P2Y], word [_P2_InputFlags]
	mov	al, [_Time]
	cmp	al, [_BattleTime]
	jne	near .donePhase
	mov	byte [_Time], 0
	mov	byte [_Phase], BREAK_REBUILD_PHASE
	invoke	_DimBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word DIM_VAL
	invoke	_CopyBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_AuxScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word 0, word 0
	invoke	_UpdateEnclosedRegion, dword [_GameMapOff]
	invoke	_GenerateRandomBlock, dword _P1CurrentBlock
	mov	ax, [_P1CurrentBlock]
	mov	[_P2CurrentBlock], ax
	jmp	near .donePhase


.rebuildPhase
	invoke	_UpdateCursor, dword _P1X, dword _P1Y, word 0, word 0, word GAME_MAP_WIDTH - 1, word GAME_MAP_HEIGHT - 1, word [_P1_InputFlags]
	mov	ax, [_P1X]
;	shl	ax, 3
	mov	bx, [_P1Y]
;	shl	bx, 3
	invoke	_DrawBlock, dword [_MapScreenOff], ax, bx, word [_P1CurrentBlock], dword [_P1BlockOff]
	invoke	_RotateBlock, dword _P1CurrentBlock, word [_P1_InputFlags]
	invoke	_BuildWall, dword [_GameMapOff], word [_P1X], word [_P1Y], dword _P1CurrentBlock, word [_P1_InputFlags]

	invoke	_UpdateCursor, dword _P2X, dword _P2Y, word 0, word 0, word GAME_MAP_WIDTH - 1, word GAME_MAP_HEIGHT - 1, word [_P2_InputFlags]
	mov	ax, [_P2X]
;	shl	ax, 3
	mov	bx, [_P2Y]
;	shl	bx, 3
	invoke	_DrawBlock, dword [_MapScreenOff], ax, bx, word [_P2CurrentBlock], dword [_P2BlockOff]
	invoke	_RotateBlock, dword _P2CurrentBlock, word [_P2_InputFlags]
	invoke	_BuildWall, dword [_GameMapOff], word [_P2X], word[_P2Y], dword _P2CurrentBlock, word [_P2_InputFlags]

	mov	al, [_Time]
	cmp	al, [_RebuildTime]
	jne	near .donePhase
	mov	byte [_Time], 0
	mov	byte [_Phase], 0

	cmp	byte [_NumP1Castle], 0
	je	near .P1Dead
	cmp	byte [_NumP2Castle], 0
	je	near .P2Dead
	mov	byte [_Phase], BREAK_DEPLOY_PHASE
	mov	al, [_NumP1Castle]
	inc	al
	mov	[_NumP1DeployCannon], al
	mov	al, [_NumP2Castle]
	inc	al
	mov	[_NumP2DeployCannon], al
	invoke	_DimBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word DIM_VAL
	invoke	_CopyBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_AuxScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word 0, word 0
	invoke	_UpdateEnclosedRegion, dword [_GameMapOff]

	jmp	near .donePhase

.P1Dead
	dec	byte [_P1Life]
	inc	byte [_P2Life]
	cmp	byte [_NumP2Castle], 0
	je	.P2Dead
	cmp	byte [_P1Life], 0
	je	near .P2Wins
	cmp	byte [_P2Life], 2	;
	jbe	.P2LifeNotAboveMax	;
	mov	byte [_P2Life], 2	; reset [_P2Life] to initial value if goes over max

.P2LifeNotAboveMax
	or	byte [_Phase], P1_INIT_PHASE
	mov	byte [_NumP1DeployCannon], NUM_HANDICAP_CANNON
	jmp	.donePhase

.P2Dead
	dec	byte [_P2Life]
	inc	byte [_P1Life]
	cmp	byte [_P2Life], 0
	je	.P1Wins
	cmp	byte [_P1Life], 2	;
	jbe	.P1LifeNotAboveMax	;
	mov	byte [_P1Life], 2	; reset [_P1Life] to initial value if goes over max

.P1LifeNotAboveMax
	or	byte [_Phase], P2_INIT_PHASE
	mov	byte [_NumP2DeployCannon], NUM_HANDICAP_CANNON
	jmp	.donePhase

.P1Wins
	invoke	_DimBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word DIM_VAL
	invoke	_DrawImage, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_P1WinBannerOff], word WIN_BANNER_WIDTH, word WIN_BANNER_HEIGHT, word WIN_BANNER_X, word WIN_BANNER_Y, 1, 0
	jmp	.loopUntilExit

.P2Wins
	invoke	_DimBuffer, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word DIM_VAL
	invoke	_DrawImage, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_P2WinBannerOff], word WIN_BANNER_WIDTH, word WIN_BANNER_HEIGHT, word WIN_BANNER_X, word WIN_BANNER_Y, 1, 0
	jmp	.loopUntilExit

.loopUntilExit
	invoke	_CopyToScreen, dword [_ScreenOff], dword SCREEN_WIDTH * 4, dword 0, dword 0, dword SCREEN_WIDTH, dword SCREEN_HEIGHT, dword 0, dword 0
	cmp	byte [_Flags], EXIT_FLAG
	jne	.loopUntilExit
	jmp	.doneGame

.donePhase
	invoke	_CopyBuffer, dword [_MapScreenOff], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, dword [_ScreenOff], word SCREEN_WIDTH, word SCREEN_HEIGHT, word 0, word 0

.doneBreakPhase
	invoke	_CopyToScreen, dword [_ScreenOff], dword SCREEN_WIDTH * 4, dword 0, dword 0, dword SCREEN_WIDTH, dword SCREEN_HEIGHT, dword 0, dword 0
	cmp	byte [_TimeTick], 20
	jb	.notTime
	inc	byte [_Time]
	mov	byte [_TimeTick], 0

.notTime
	inc	byte [_TimeTick]
	jmp	.loopGame

.doneGame
	ret


;-------------------------------------------------------------------------------------
;-- void _UpdateInitCursor(dword *CastleArray, dword *X, dword *Y, word InputFlags) --
;-------------------------------------------------------------------------------------
; Inputs : CastleArray - array of castles
;          X - offset of x coordinate
;          Y - offset of y coordinate
;          InputFlags - input flags
; Outputs : [X] - X updated with new x coordinate
;           [Y] - Y updated with new y coordinate
; Returns : -
; Calls : -
; - Updates initialize phase cursor; moves cursor to previous castle if 'left' key pressed, moves cursor to next castle if 'right key' pressed
proc _UpdateInitCursor
.CastleArray	arg	4
.X		arg	4
.Y		arg	4
.InputFlags	arg	2

	push	esi

	mov	esi, [.CastleArray + ebp]
	mov	ecx, -1
	mov	eax, [.X + ebp]
	mov	ax, [eax]
	mov	ebx, [.Y + ebp]
	mov	bx, [ebx]

.loopSearchCurrentIndex				; from here to the end,
	inc	ecx				; ecx holds index of .CastleArray
	cmp	ax, [esi + ecx * 4]		;
	jne	.loopSearchCurrentIndex		;
	cmp	bx, [esi + ecx * 4 + 2]		;
	jne	.loopSearchCurrentIndex		;

.checkUpInput
	test	byte [.InputFlags + ebp], UP_FLAG
	jnz	.upPressed
	jmp	.checkDownInput

.upPressed
	test	ecx, ecx
	jz	.beginningOfArray
	dec	ecx
	jmp	.checkDownInput

.beginningOfArray
	movzx	ecx, byte [_NumTotalCastle]
	dec	ecx

.checkDownInput
	test	byte [.InputFlags + ebp], DOWN_FLAG
	jnz	.downPressed
	jmp	.checkLeftInput

.downPressed
	mov	al, [_NumTotalCastle]
	dec	al
	cmp	cl, al
	je	.endOfArray
	inc	ecx
	jmp	.checkLeftInput

.endOfArray
	xor	ecx, ecx

.checkLeftInput
	test	byte [.InputFlags + ebp], LEFT_FLAG
	jnz	.leftPressed
	jmp	.checkRightInput

.leftPressed
	xor	ebx, ebx
	mov	edx, ecx
	mov	ah, 0ffh

.findShortestLeftDist				; finds the castle closest to cursor
	cmp	bl, [_NumTotalCastle]		; in X to the left
	jae	.updateIndexForLeft		;
	mov	al, [esi + ecx * 4]		;
	sub	al, [esi + ebx * 4]		;
	test	al, al				;
	jz	.notShortestLeftDist		;
	cmp	ah, al				;
	jb	.notShortestLeftDist		;
	mov	ah, al				;
	mov	edx, ebx			;

.notShortestLeftDist
	inc	ebx
	jmp	.findShortestLeftDist

.updateIndexForLeft
	mov	ecx, edx

.checkRightInput
	test	byte [.InputFlags + ebp], RIGHT_FLAG
	jnz	.rightPressed
	jmp	.updateCoord

.rightPressed
	xor	ebx, ebx
	mov	edx, ecx
	mov	ah, 0ffh

.findShortestRightDist				; finds the castle closest to cursor
	cmp	bl, [_NumTotalCastle]		; in X to the right
	jae	.updateIndexForRight		;
	mov	al, [esi + ebx * 4]		;
	sub	al, [esi + ecx * 4]		;
	test	al, al				;
	jz	.notShortestRightDist		;
	cmp	ah, al				;
	jb	.notShortestRightDist		;
	mov	ah, al				;
	mov	edx, ebx			;

.notShortestRightDist
	inc	ebx
	jmp	.findShortestRightDist

.updateIndexForRight
	mov	ecx, edx

.updateCoord
	mov	ax, [esi + ecx * 4]	;
	mov	ebx, [.X + ebp]		;
	mov	[ebx], ax		; update X coordinate
	mov	ax, [esi + 2 + ecx * 4]	;
	mov	ebx, [.Y + ebp]		;
	mov	[ebx], ax		; update Y coordinate

.done
	pop	esi
	ret

endproc
_UpdateInitCursor_arglen	EQU	14


;---------------------------------------------------------------------------------------------------------
;-- void _UpdateCursor(dword *X, dword *Y, word MinX, word MinY, word MaxX, word MaxY, word InputFlags) --
;---------------------------------------------------------------------------------------------------------
; Inputs : X - offset of x coordinate
;          Y - offset of y coordinate
;          MinX - minimum x of the boundary
;          MinY - minimum y of the boundary
;          MaxX - maximum x of the boundary
;          MaxY - maximum y of the boundary
;          InputFlags - input flags
; Outputs : [X] - X updated with new x coordinate
;           [Y] - Y updated with new y coordinate
; Returns : -
; Calls : -
; - Updates cursor depending on which key is pressed
proc _UpdateCursor
.X		arg	4
.Y		arg	4
.MinX		arg	2
.MinY		arg	2
.MaxX		arg	2
.MaxY		arg	2
.InputFlags	arg	2

	push	esi
	push	edi

	mov	esi, [.X + ebp]				; eax = x
	mov	edi, [.Y + ebp]				; ebx = y

.CheckRightandLeft
	test	byte [.InputFlags + ebp], RIGHT_FLAG	; check if right key pressed
	jnz	.RightKey
	test	byte [.InputFlags + ebp], LEFT_FLAG	; check if left key pressed
	jnz	.LeftKey
	jmp	.CheckUpAndDown
.RightKey
	mov	eax, [esi]				; eax = x
	inc	eax
	cmp	ax, word [.MaxX + ebp]			; check if X+1 > MaxX
	ja	.CheckUpAndDown
	mov	[esi], ax
	jmp	.CheckUpAndDown
.LeftKey
	mov	eax, [esi]				; eax = x
	dec	eax
	cmp	ax, word [.MinX + ebp]			; check if X-1 < MinX
	jb	.End
	mov	[esi], ax

.CheckUpAndDown
	test	byte [.InputFlags + ebp], UP_FLAG	; check if up key pressed
	jnz	.UpKey
	test	byte [.InputFlags + ebp], DOWN_FLAG	; check if down key pressed
	jnz	.DownKey
	jmp	.End
.UpKey
	mov	ebx, [edi]				; ebx = y
	dec	ebx
	cmp	bx, word [.MaxY + ebp]			; check if Y+1 > MaxY
	ja	.End
	mov	[edi], bx
	jmp	.End

.DownKey
	mov	ebx, [edi]				; ebx = y
	inc	ebx
	cmp	bx, word [.MinY + ebp]			; check if Y-1 < MinY
	jb	.End
	mov	[edi], bx
	
.End
	pop	edi
	pop	esi
	ret

endproc
_UpdateCursor_arglen	EQU	18

;------------------------------------------------------
;-- void _RotateBlock(dword *Block, word InputFlags) --
;------------------------------------------------------
; Inputs : Block - offset of block to rotate
;          InputFlags - input flags
; Outputs : Block rotated 90 degrees counter-clockwise
; Returns : -
; Calls : -
; - Rotates 3 x 3 Block 90 degrees counter-clockwise if secondary key is pressed
proc _RotateBlock
.Block		arg	4
.InputFlags	arg	2

	mov	ebx, [.Block + ebp]
	mov	ax, [ebx]
	rol	al, 2
	mov	[ebx], ax
	ret

endproc
_RotateBlock_arglen	EQU	6


;------------------------------------------------------------------------------------------------------------------------
;-- dword _BoundaryInRegion(dword *MapOff, word X, word Y, word Width, word Height, word RegionVal) --
;------------------------------------------------------------------------------------------------------------------------
; Inputs : MapOff - offset of map buffer
;          X - current x coordinate
;          Y - current y coordinate
;          Width - width of the region
;          Height - height of the region
;          RegionVal - map value of particular region
; Outputs : -
; Returns : 1 if boundary is filled with RegionVal; 0 otherwise
; Calls: -
; - Checks if boundary defined by MinX, MinY, MaxX and MaxY at (X, Y) is filled with RegionVal
proc _BoundaryInRegion
.MapOff		arg	4
.X		arg	2
.Y		arg	2
.Width		arg	2
.Height		arg	2
.RegionVal	arg	2

	push	esi
	push	edi
	
	movzx	eax, word [.Y + ebp]	; finding address for MinX, MinY
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	mov	edi, eax
	movzx	edx, word [.Height + ebp]

.heightLoop	
	movzx	ecx, word [.Width + ebp]

.widthLoop	
	mov	eax, edi
	shl	eax, 1
	add	eax, [.MapOff + ebp]

	movzx	esi, word [.RegionVal + ebp]
	cmp	word [eax], si
	jne	.ReturnZero
	
	inc	edi
	dec	ecx
	cmp	ecx, 0
	ja	.widthLoop

	add	edi, GAME_MAP_WIDTH
	sub	di, word [.Width + ebp]
	dec	edx
	cmp	edx, 0
	ja	.heightLoop

.ReturnOne
	mov	eax, 1
	pop	edi
	pop	esi
	ret
	
.ReturnZero
	mov	eax, 0			; if not = then 0
	pop	edi
	pop	esi
	ret

endproc
_BoundaryInRegion_arglen	EQU	14


;-------------------------------------------------------------------------------------
;-- dword _BlockInRegion(dword *MapOff, word Block, word X, word Y, word RegionVal) --
;-------------------------------------------------------------------------------------
; Inputs : MapOff - offset of map buffer
;          Block - block to check if it is in region
;          X - current x coordinate
;          Y - current y coordinate
;          RegionVal - map value of particular region
; Outputs : -
; Returns : 1 if Block is filled with RegionVal; 0 otherwise
; Calls : -
; - Checks if Block at (X, Y) is in the region defined by RegionVal
proc _BlockInRegion
.MapOff		arg	4
.Block		arg	2
.X		arg	2
.Y		arg	2
.RegionVal	arg	2

	push	esi

	movzx	eax, word [.Y + ebp]
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	shl	eax, 1
	add	eax, [.MapOff + ebp]

	movzx	edx, word [.Block+ ebp]
	movzx	ecx, word [.RegionVal+ebp]

.CheckEight				; check for region 8
	test	dh, 00000001b
	jz	.CheckZero
	cmp	word [eax], cx
	jne	near .ReturnZero

.CheckZero				; check for region 0
	test	dl, 00000001b
	jz	.CheckOne
	movzx	eax, word [.Y + ebp]
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	sub	eax, GAME_MAP_WIDTH
	dec	eax
	shl	eax, 1
	add	eax, [.MapOff + ebp]
	cmp	word [eax], cx
	jne	near .ReturnZero

.CheckOne				; check for region 1
	test	dl, 00000010b
	jz	.CheckTwo
	movzx	eax, word [.Y + ebp]
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	dec	eax
	shl	eax, 1
	add	eax, [.MapOff + ebp]
	cmp	word [eax], cx
	jne	near .ReturnZero

.CheckTwo				; check for region 2
	test	dl, 00000100b
	jz	.CheckThree
	movzx	eax, word [.Y + ebp]
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	add	eax, GAME_MAP_WIDTH
	dec	eax
	shl	eax, 1
	add	eax, [.MapOff + ebp]
	cmp	word [eax], cx
	jne	near .ReturnZero

.CheckThree				; check for region 3
	test	dl, 00001000b
	jz	.CheckFour
	movzx	eax, word [.Y + ebp]
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	add	eax, GAME_MAP_WIDTH
	shl	eax, 1
	add	eax, [.MapOff + ebp]
	cmp	word [eax], cx
	jne	near .ReturnZero

.CheckFour				; check for region 4
	test	dl, 00010000b
	jz	.CheckFive
	movzx	eax, word [.Y + ebp]
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	add	eax, GAME_MAP_WIDTH
	inc	eax
	shl	eax, 1
	add	eax, [.MapOff + ebp]
	cmp	word [eax], cx
	jne	near .ReturnZero

.CheckFive				; check for region 5
	test	dl, 00100000b
	jz	.CheckSix
	movzx	eax, word [.Y + ebp]
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	inc	eax
	shl	eax, 1
	add	eax, [.MapOff + ebp]
	cmp	word [eax], cx
	jne	near .ReturnZero

.CheckSix				; check for region 6
	test	dl, 01000000b
	jz	.CheckSeven
	movzx	eax, word [.Y + ebp]
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	sub	eax, GAME_MAP_WIDTH
	inc	eax
	shl	eax, 1
	add	eax, [.MapOff + ebp]
	cmp	word [eax], cx
	jne	near .ReturnZero

.CheckSeven				; check for region 7
	test	dl, 10000000b
	jz	.ReturnZero
	movzx	eax, word [.Y + ebp]
	mov	ebx, GAME_MAP_WIDTH
	mul	ebx
	movzx	ebx, word [.X + ebp]
	add	eax, ebx
	sub	eax, GAME_MAP_WIDTH
	shl	eax, 1
	add	eax, [.MapOff + ebp]
	cmp	word [eax], cx
	jne	near .ReturnZero
	
.ReturnOne				; return 1
	mov	eax, 1
	jmp	.End
	
.ReturnZero				; return 0
	mov	eax, 0
	
.End
	pop	esi
	ret

endproc
_BlockInRegion_arglen	EQU	12


;-----------------------------------------------
;-- void _UpdateEnclosedRegion(dword *MapOff) --
;-----------------------------------------------
; Inputs : MapOff - offset of map buffer
; Outputs : [_NumP1Territory] - updates number of conquered grid by P1
;           [_NumP2Territory] - updates number of conquered grid by P2
; Returns : -
; Calls : -
; - Marks grid as occupied if enclosed by wall; marks it as unoccupied if not, also updates variables storing number of occupied grids
proc _UpdateEnclosedRegion
.MapOff		arg	4

	push	esi
	push	edi
	
	mov		edi, [_PointQueue]	;
	mov		[_QueueHead], edi	;
	mov		[_QueueTail], edi	; initialize _QueueHead and _QueueTail
	mov		ax, GAME_MAP_WIDTH
	shr		ax, 1
	mov		bx, GAME_MAP_HEIGHT
	shr		bx, 1
	mov		[edi], ax
	mov		[edi+2], bx
	add		dword [_QueueTail], 4

.loop1
	xor		edi, edi
	mov		edi, dword [_QueueHead]
	cmp		edi, dword [_QueueTail]
	jae		near .done
	add		dword [_QueueHead], 4	; dequeue

	push	edi
	xor		ecx, ecx
	xor		edx, edx
;	mov		cx, GAME_MAP_WIDTH
;	mov		dx, GAME_MAP_HEIGHT
;	dec		ecx
;	dec		edx
	invoke	_PointInBox, word [edi], word [edi + 2], word 0, word 0, GAME_MAP_WIDTH, GAME_MAP_HEIGHT
	pop		edi
	cmp		eax, 0
	je		NEAR .loop1

	xor		edx, edx
	movzx	eax, word[edi + 2]
	mov		dx, GAME_MAP_WIDTH
	mul		edx
	movzx	edx, word[edi]
	add		edx, eax
	shl		edx, 1
	add		edx, dword[.MapOff + ebp]
	
	movzx	eax, word[edx]

	mov		ecx, eax
	or		cl, 00000101b				; ignore dont care bits(player/occupied)
	cmp		cx, P2_WALL + OCCUPIED			; check for the wall
	je		NEAR .loop1

	test		ax, 0080h
	jnz		NEAR .loop1

	or		ax, 0080h				; modify grid bit attributes
	mov		word[edx], ax

	movzx		eax, word[edi]
	movzx		ebx, word[edi + 2]
	mov		edi, dword [_QueueTail]

	inc		eax						;
	mov		word [edi], ax			;
	mov		word [edi + 2], bx		; enqueue (X + 1, Y)

	sub		eax, 2					;
	mov		word [edi + 4], ax		;
	mov		word [edi + 6], bx		; enqueue (X - 1, Y)

	inc		eax						;
	mov		word [edi + 8], ax		;
	inc		ebx						;
	mov		word [edi + 10], bx		; enqueue (X, Y + 1)

	mov		word [edi + 12], ax		;
	sub		ebx, 2					;
	mov		word [edi + 14], bx		; enqueue (X, Y - 1)

	inc		eax						;
	mov		word [edi + 16], ax		;
	mov		word [edi + 18], bx		; enqueue (X + 1, Y - 1)

	sub		eax, 2					;
	mov		word [edi + 20], ax		;
	mov		word [edi + 22], bx		; enqueue (X - 1, Y - 1)

	mov		word [edi + 24], ax		;
	add		ebx, 2					;
	mov		word [edi + 26], bx		; enqueue (X - 1, Y + 1)

	add		eax, 2					;
	mov		word [edi + 28], ax		;
	mov		word [edi + 30], bx		; enqueue (X + 1, Y + 1)

	add		dword [_QueueTail], 32
	jmp		NEAR .loop1

.done
	mov		edi, dword [.MapOff + ebp]
	mov		ecx, 65*60

.loop2
	mov		ax, word [edi]
	test		ax, 0080h
	jnz		NEAR .notOccupied
	
	or		al, OCCUPIED
;	and		al, 00001111b			; clear out the upper bits
	mov		word [edi], ax

	test		ax, 0004h
	jnz		.incplayer2

	inc		word [_NumP1Territory]
	
.incplayer2
	inc		word [_NumP2Territory]
	jmp		.jump
	
.notOccupied
	and		al, 00001111b			; clear out the upper bits
;	or		al, OCCUPIED
	mov		word [edi], ax

.jump
	add		edi, 2
	loop		.loop2

	pop		edi
	pop		esi
	ret

endproc
_UpdateEnclosedRegion_arglen	EQU	4



;-----------------------------------------------------------------------------------------------------------------------------------------------
;-- void _BuildCastle(dword *MapOff, word X, word Y, word WallVal, dword *NumCastle, dword *NumTerritory, word InputFlags, word CurrentPhase) --
;-----------------------------------------------------------------------------------------------------------------------------------------------
; Inputs : MapOff - offset of map buffer
;          X - x coordinate of location around which to build castle walls
;          Y - y coordinate of location around which to build castle walls
;          WallVal - map value for wall
;          NumCastle - offset of variable holding number of castles
;          NumTerritory - offset of variable holding number of territory
;          InputFlags - input flags
;          CurrentPhase - current phase
; Outputs : [_Phase] - removes CurrentPhase from [_Phase] if walls are built
;           NumTerritory - updates amount of territory with NUM_INIT_TERRITORY
;           walls built around (X, Y) in the map buffer pointed to by MapOff
; Returns : -
; Calls : -
; - Updates map buffer pointed to by MapOff with walls around location (X, Y) if primary key is pressed, and also updates [_Phase] if walls are built
proc _BuildCastle
.MapOff		arg	4
.X		arg	2
.Y		arg	2
.WallVal	arg	2
.NumCastle	arg	4
.NumTerritory	arg	4
.InputFlags	arg	2
.CurrentPhase	arg	2

	test	byte [.InputFlags + ebp], PRIMARY_FLAG
	jz	near .done
	mov	al, [.CurrentPhase + ebp]					; updates phase and number of occupied
	not	al								; territory
	and	[_Phase], al							;
	mov	ebx, [.NumTerritory + ebp]					;
	mov	word [ebx], INIT_CURSOR_WIDTH / 8 + INIT_CURSOR_HEIGHT / 8	;
	mov	ebx, [.NumCastle + ebp]
	mov	byte [ebx], 1

	movzx	eax, word [.Y + ebp]			; locate current position in map buffer
	mov	edx, GAME_MAP_WIDTH			;
	mul	edx					;
	movzx	edx, word [.X + ebp]			;
	add	eax, edx				;
	sub	eax, GAME_MAP_WIDTH * 4 + 3		;
	shl	eax, 1
	add	eax, [.MapOff + ebp]			;
	mov	edx, eax				;
	xor	ebx, ebx
	xor	ecx, ecx
	mov	ax, [.WallVal + ebp]

.loopBuild
	cmp	ebx, INIT_CURSOR_WIDTH / 8
	jb	.notEndOfRow
	xor	ebx, ebx
	inc	ecx
	add	edx, GAME_MAP_WIDTH * 2
	cmp	ecx, INIT_CURSOR_HEIGHT / 8
	jae	.done

.notEndOfRow
	cmp	ebx, 0
	jne	.notLeftWall
	mov	[edx + ebx * 2], ax

.notLeftWall
	cmp	ebx, INIT_CURSOR_WIDTH / 8 - 1
	jne	.notRightWall
	mov	[edx + ebx * 2], ax

.notRightWall
	cmp	ecx, 0
	jne	.notTopWall
	mov	[edx + ebx * 2], ax

.notTopWall
	cmp	ecx, INIT_CURSOR_HEIGHT / 8 - 1
	jne	.notBottomWall
	mov	[edx + ebx * 2], ax

.notBottomWall
	or	byte [edx + ebx * 2], OCCUPIED
	inc	ebx
	jmp	.loopBuild

.done
	ret

endproc
_BuildCastle_arglen	EQU	22



;-----------------------------------------------------------------------------------------------------------------------------------------------------------
;void _BuildCannon(dword *MapOff, dword *CannonArray, dword *NumCannon, dword *TotalCannon, word X, word Y, word InputFlags, word Region, word CurrentPhase) 
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
; Inputs : MapOff - offset of map buffer
;          CannonArray - offset of cannon array
;          NumCannon - number of cannons available for deployment
;          X - x coordinate of location at which to place cannon
;          Y - y coordinate of location at which to place cannon
;          InputFlags - input flags
;          Region - map value of allowed region for cannon placement
;          CurrentPhase - CurrentPhase
; Outputs : NumCannon - number of cannons available updated if cannon is built
;           [_Phase] - removes CurrentPhase from [_Phase] if number of cannons reaches 0
;           CannonArray - cannon array updated with new cannon
;           TotalCannon - total number of cannons available
;           MapOff - walls built around (X, Y) in the map buffer pointed to by MapOff
; Returns : -
; Calls : _BoundaryInRegion
; - Updates map buffer and cannon array with new cannon if primary key is pressed
proc _BuildCannon
.MapOff		arg	4
.CannonArray	arg	4
.NumCannon	arg	4
.TotalCannon	arg	4
.X		arg	2
.Y		arg	2
.InputFlags	arg	2
.Region		arg	2
.CurrentPhase	arg	2

	test	byte [.InputFlags+ebp], PRIMARY_FLAG	; check if primary key is pressed
	jz		NEAR .End
	
	movzx	eax, word [.Y + ebp]		; set address for x,y
	mov		ebx, GAME_MAP_WIDTH
	mul		ebx
	add		ax, [.X + ebp]
	shl		eax, 1
	add		eax, [.MapOff + ebp]
	mov		edx, eax			; edx now contains x,y buffer address
	
	; check if cannon can be placed
	invoke	_BoundaryInRegion, dword [.MapOff+ebp], word [.X+ebp], word [.Y+ebp], word 2, word 2, word [.Region+ebp]
	
	cmp	eax, 1				; check if cannon can be placed
	jne	.End
	
	mov	eax, [.CannonArray + ebp]
	xor ecx, ecx
.SearchEmpty
	test	word [eax], 8000h			; search for empty cell
	jz	.EmptyCell
	add	eax, 4
	inc	cl
	cmp	cl, 30				; check if cannon array is full *SERIOUS ERROR
	je	.End
	jmp	.SearchEmpty

.EmptyCell
	mov	[eax], dx			; update empty cell with cannon info
	or	word [eax], 8000h

	mov	eax, [.TotalCannon + ebp]
	inc	byte [eax]			; increment Total Cannon #

	mov	byte [edx], cl		; upperleft
	or	byte [edx+1], 00000011b
	add	edx, 2				; upperright
	mov	byte [edx], cl
	or	byte [edx+1], 00000011b
	add	edx, GAME_MAP_WIDTH*2		; lowerright
	mov	byte [edx], cl
	or	byte [edx+1], 00000011b
	sub	edx, 2				; lowerleft
	mov	byte [edx], cl
	or	byte [edx+1], 00000011b
	
	mov	eax, [.NumCannon + ebp]
	dec	byte [eax]
	cmp	byte [eax], 0
	jne	.End

	movzx	ebx, word [.CurrentPhase + ebp]	; remove CurrentPhase from [_phase]
	NOT	bl
	and	[_Phase], bl

.End
	ret
	
endproc
_BuildCannon_arglen	EQU	26


;-------------------------------------------------------------------------------------------------
;-- void _BuildWall(dword *MapOff, word X, word Y, word *Block, word RegionVal word InputFlags) --
;-------------------------------------------------------------------------------------------------
; Inputs : MapOff - offset of map buffer
;          X - x coordinate of location at which to place block
;          Y - y coordinate of location at which to place block
;          Block - offset of block to place in the map buffer
;          RegionVal - value of the region used
;          InputFlags - input flags
; Outputs : MapOff - map buffer updated with new wall piece
;           Block - new wall piece generated and stored in block if old block is used
; Returns : -
; Calls : _BlockInRegion, _GenerateRandomBlock, _UpdateEnclosedRegion
; - Updates map buffer with new wall piece if primary key is pressed then checks for enclosed region, also if old block is used new random block is generated
proc _BuildWall
.MapOff		arg	4
.X		arg	2
.Y		arg	2
.Block		arg	2
;.RegionVal	arg	2
.InputFlags	arg	2

	test	byte [.InputFlags+ebp], PRIMARY_FLAG	; check if primary key is pressed
	jz	near .End

	mov	eax, [.Block+ebp]
	movzx	ebx, word [eax]
	or		bx, 0005h
	xor		edx, edx
	mov		dx, 0105h
	mov		ecx, edx
	push	ecx	
		
	invoke _BlockInRegion, dword [.MapOff+ebp], bx, word [.X+ebp], word [.Y+ebp], dx
	
	pop		ecx
	cmp	eax, 1					; check if the land is not occupied
	jne	near .End
	
	movzx	eax, word [.Y+ebp]			; find the location
	mov	ebx, GAME_MAP_WIDTH
	mul	eax
	add	ax, word [.X+ebp]
	shl	eax, 2

	movzx	edx, word [.Block+ ebp]
	
	add	eax, [.MapOff+ebp]			; region 8
	test	dh, 00000001b
	jz	.RegionZero
	mov	word [eax], cx

.RegionZero
	test	dl, 00000001b
	jz	.RegionOne
	movzx	eax, word [.Y+ebp]			; find the location
	mov	ebx, GAME_MAP_WIDTH
	mul	eax
	add	ax, word [.X+ebp]
	shl	eax, 2
	sub	eax, (GAME_MAP_WIDTH+1)*2		; region 0
	add	eax, [.MapOff+ebp]
	mov	word [eax], cx

.RegionOne
	test	dl, 00000010b
	jz	.RegionTwo
	movzx	eax, word [.Y+ebp]			; find the location
	mov	ebx, GAME_MAP_WIDTH
	mul	eax
	add	ax, word [.X+ebp]
	shl	eax, 2
	add	eax, GAME_MAP_WIDTH*2			; region 1
	add	eax, [.MapOff+ebp]
	mov	word [eax], cx

.RegionTwo
	test	dl, 00000100b
	jz	.RegionThree
	movzx	eax, word [.Y+ebp]			; find the location
	mov	ebx, GAME_MAP_WIDTH
	mul	eax
	add	ax, word [.X+ebp]
	shl	eax, 2
	add	eax, GAME_MAP_WIDTH*2			; region 2
	add	eax, [.MapOff+ebp]
	mov	word [eax], cx

.RegionThree
	test	dl, 00001000b
	jz	.RegionFour
	movzx	eax, word [.Y+ebp]			; find the location
	mov	ebx, GAME_MAP_WIDTH
	mul	eax
	add	ax, word [.X+ebp]
	shl	eax, 2
	add	eax, 2					; region 3
	add	eax, [.MapOff+ebp]
	mov	word [eax], cx

.RegionFour
	test	dl, 00010000b
	jz	.RegionFive
	movzx	eax, word [.Y+ebp]			; find the location
	mov	ebx, GAME_MAP_WIDTH
	mul	eax
	add	ax, word [.X+ebp]
	shl	eax, 2
	add	eax, 2					; region 4
	add	eax, [.MapOff+ebp]
	mov	word [eax], cx

.RegionFive
	test	dl, 00100000b
	jz	.RegionSix
	movzx	eax, word [.Y+ebp]			; find the location
	mov	ebx, GAME_MAP_WIDTH
	mul	eax
	add	ax, word [.X+ebp]
	shl	eax, 2
	sub	eax, GAME_MAP_WIDTH*2			; region 5
	add	eax, [.MapOff+ebp]
	mov	word [eax], cx

.RegionSix
	test	dl, 01000000b
	jz	.RegionSeven
	movzx	eax, word [.Y+ebp]			; find the location
	mov	ebx, GAME_MAP_WIDTH
	mul	eax
	add	ax, word [.X+ebp]
	shl	eax, 2
	sub	eax, GAME_MAP_WIDTH*2			; region 6
	add	eax, [.MapOff+ebp]
	mov	word [eax], cx

.RegionSeven
	test	dl, 10000000b
	jz	.Successful
	movzx	eax, word [.Y+ebp]			; find the location
	mov	ebx, GAME_MAP_WIDTH
	mul	eax
	add	ax, word [.X+ebp]
	shl	eax, 2
	sub	eax, 2					; region 7
	add	eax, [.MapOff+ebp]
	mov	word [eax], cx
	
.Successful						; block has been placed
	invoke _GenerateRandomBlock, dword [.Block+ebp]
	invoke _UpdateEnclosedRegion, dword [.MapOff+ebp]
	
.End
	ret

endproc
_BuildWall_arglen	EQU	12


;--------------------------------------------
;-- void _GenerateRandomBlock(dword *Block) --
;--------------------------------------------
; Inputs : _BlockArray - array holding different types of blocks
; Outputs : Block - updated with new wall piece
; Return : -
; Calls : _Random
; - Generates a random block and stores it in Block
proc _GenerateRandomBlock
.Block	arg	4

	invoke _Random, word 19
;	div	edx    ;divide by 19 and get remainder in edx
;	mov	edx, 0
	shl	eax, 1
	movzx 	edx, word [_BlockArray + eax]
	mov	esi, dword[.Block + ebp]
	mov	word[esi], dx

	ret


endproc
_GenerateRandomBlock_arglen	EQU	4


;-------------------------------------------------------------------
;-- void _UpdateCannonBall(dword *MapOff, dword *CannonBallArray) --
;-------------------------------------------------------------------
; Inputs : MapOff - offset of map buffer
;          CannonBallArray - offset of array of cannon balls in flight
;          [_CBallTick] - tick counter for cannon ball update
; Outputs : MapOff - map buffer updated if cannon ball destroys cannon or wall
;           CannonBallArray - updated with new position info
;           _P1CannonArray - P1 cannon array updated if P1 cannon ball landed
;           _P2CannonArray - P2 cannon array updated if P2 cannon ball landed
; Returns : -
; Calls : -
; - Updates cannon ball array with new position info using timer
proc _UpdateCannonBall
.MapOff			arg	4
.CannonBallArray	arg	4

;ret
	push	esi
	push	edi

	cmp	word [_CBallTick], 0
	jne	near .End
		
	mov	esi, dword [.CannonBallArray+ebp]
.CBallLoop
	cmp	dword [esi], 0
	je	near .End
	
	movzx	edi, word [esi+2]			; store x1
	mov	word [_x1], di
	movzx	eax, byte [esi+5]			; store x2
	mov	edi, 8
	mul	edi
	mov	word [_x2], ax
	movzx	edi, word [esi]				; store y1
	mov	word [_y1], di
	movzx	eax, byte [esi+4]			; store y2
	mov	edi, 8
	mul	edi
	mov	word [_y2], ax


; from drawline ----------------------------------------------------------------
	
	mov	ax, [_x1]		; abs(X2 - X1)
	mov	bx, [_x2]		;	
	cmp	ax, bx			;
	jl	.X2Greater		;
	sub	ax, bx			;
	mov	[_dx], ax		;
	jmp	.calc_dy		;
					;
.X2Greater				;
	sub	bx, ax			;
	mov	[_dx], bx		;

.calc_dy
	mov	ax, [_y1]		; abs(Y2 - Y1)
	mov	bx, [_y2]		;
	cmp	ax, bx			;
	jl	.Y2Greater		;
	sub	ax, bx			;
	mov	[_dy], ax		;
	jmp	.doneCalc_dx_dy		;
					;
.Y2Greater				;
	sub	bx, ax			;
	mov	[_dy], bx		;

.doneCalc_dx_dy
	mov	ax, [_dx]
	mov	bx, [_dy]
	cmp	ax, bx
	jb	._dxLessThan_dy
	movzx	ecx, ax			;
	inc	ecx			; numpixels = ecx = dx + 1
	shl	bx, 1			;
	mov	[_errornodiaginc], bx	; _errornodiaginc = 2 * dy
	sub	bx, ax			;
	mov	[_lineerror], bx	; _lineerror = (2 * dy) - dx
	mov	bx, [_dy]
	sub	bx, ax			;
	shl	bx, 1			;
	mov	[_errordiaginc], bx	; _errordiaginc = 2 * (dy - dx)
	mov	word [_xhorizinc], 1
	mov	word [_xdiaginc], 1
	mov	word [_yvertinc], 0
	mov	word [_ydiaginc], 1
	jmp	.correctVars

._dxLessThan_dy
;	movzx	ecx, bx			;
;	inc	ecx			; numpixels = ecx = dy + 1
	shl	ax, 1			;
	mov	[_errornodiaginc], ax	; _errornodiaginc = 2 * dx
	sub	ax, bx			;
	mov	[_lineerror], ax	; _lineerror = (2 * dx) - dy
	mov	ax, [_dx]
	sub	ax, bx			;
	shl	ax, 1			;
	mov	[_errordiaginc], ax	; _errordiaginc = 2 * (dx - dy)
	mov	word [_xhorizinc], 0
	mov	word [_xdiaginc], 1
	mov	word [_yvertinc], 1
	mov	word [_ydiaginc], 1

.correctVars
	mov	ax, [_x1]
	cmp	ax, [_x2]
	jle	.checkY
	neg	word [_xhorizinc]
	neg	word [_xdiaginc]

.checkY
	mov	ax, [_y1]
	cmp	ax, [_y2]
	jle	.draw
	neg	word [_yvertinc]
	neg	word [_ydiaginc]

.draw
	mov	ax, [_x1]
	mov	bx, [_y1]
	mov	dx, [_lineerror]

.loopDraw
;	push	ax
;	push	bx
;	push	dx
;	invoke	_DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]
;	pop	dx
;	pop	bx
;	pop	ax
	cmp	dx, 0
	jge	.lineerrorNotNegative
	add	dx, [_errornodiaginc]	; update _lineerror
	add	ax, [_xhorizinc]	; update x
	add	bx, [_yvertinc]		; update y
	jmp	.done

.lineerrorNotNegative
	add	dx, [_errordiaginc]	; update _lineerror
	add	ax, [_xdiaginc]		; update x
	add	bx, [_ydiaginc]		; update y

.done
	mov	[_newx], ax
	mov	[_newy], bx
; --------------------------------------------------------------------------------------

	cmp	ax, word [_x2]		; check to see if it has reached destination
	jne	NEAR .UpdateCBallArray
	cmp	bx, word [_y2]
	jne	NEAR .UpdateCBallArray
	
	; if reached	
	; put it in explosion queue
	movzx	eax, byte [esi+5]
	movzx	ebx, byte [esi+4]
	mov	edx, dword [_ExplosionArray]
	mov	ecx, 0
.ExplosionLoop				; find empty cell in explosion array
	cmp	word [edx+ecx], 0
	je	.EmptyCell
	add	ecx, 2
	jmp	.ExplosionLoop

.EmptyCell
	mov	ecx, 00000080h		; byte 3 flag
	shl	ecx, 8
	; *DONT KNOW HOW TO DO CURRENT FRAME TO DISPLAY
	mov	ch, al			; byte 1 x
	mov	cl, bl			; byte 0 y
	mov	dword [edx], ecx

.IfOccupied
	mov	edx, [.MapOff+ebp]	; check if occupied
;	movzx	ebx, byte [edx+1]
;	test	bl, 11000000b
	test	byte [edx], 00000011b
	jz	NEAR .RemoveCBallCell	; not wall not cannon
	
	xor	ebx, ebx
	movzx	ebx, word [edx]
	cmp	bh, 5			; check if it's a wall
	je	.DestroyWall
	
	test	bl, 00000010b		; check if it has a cannon
	jz	.RemoveCBallCell	; *SERIOUS ERROR
	
	; has cannon
	test	bl, 00000100b		; check which player
	jnz	.Player2	

	mov	edi, dword [_P1CannonArray]	; player 1
	mov	ebx, edi
	add	ebx, 30*4
	mov	ecx, [edi]
	jmp	.CannonLoop

.Player2					; player 2
	mov	edi, dword [_P2CannonArray]
	mov	ebx, edi
	add	ebx, 30*4
	mov	ecx, [edi]
.CannonLoop				; main cannon loop for both players
	cmp	ecx, 0			; check if cell is not empty
	jne	.CannonCell
	add	edi, 4
	jmp	.CannonLoop

.CannonCell
	cmp	ch, [_x2]		; check if current cell
	jne	.CheckAnother
	cmp	cl, [_y2]
	jne	.CheckAnother
	
	inc	byte [edi+2]		; increment the damage
	cmp	byte [edi+2], CANNONLIFE
	jne	.RemoveCBallCell
	
	mov	dword [edi], 0		; cell is cleared
	jmp	.RemoveCBallCell
.CheckAnother	
	add	edi, 4
	cmp	edi, ebx
	jg	.End			; no cell found *SERIOUS ERROR
	jmp	.CannonCell

	
.DestroyWall	
	mov	byte [edx+1], 6
	or	byte [edx], 00000001b	; *JUST TO BE SAFE
		
.RemoveCBallCell			; remove the Cball cell
	mov	dword [esi], 0
	mov	dword [esi+4], 0
	jmp	.NextCBallCell

.UpdateCBallArray			; Cannon ball in air update Cball cell with new location
	movzx	eax, word [_newx]
	shl	eax, 16
	mov	ax, word [_newy]
	mov	dword [esi], eax
	
.NextCBallCell
	add	esi, 8
	jmp	.CBallLoop

.End
	pop	edi
	pop	esi
	ret
	
endproc
_UpdateCannonBall_arglen	EQU	8


;------------------------------------------------------------------------------------------------------------------
;-- void _FireCannon(dword *MapOff, dword *CannonArray, dword *CannonBallArray, word X, word Y, word InputFlags) --
;------------------------------------------------------------------------------------------------------------------
; Inputs : MapOff - offset of map buffer
;          CannonArray - offset of array of cannons
;          CannonBallArray - offset of array of cannon balls in flight
;          X - x coordinate of destination for cannon ball
;          Y - y coordinate of destination for cannon ball
;          InputFlags - input flags
; Outputs : CannonArray - cannon array updated if cannon fires
;           CannonBallArray - cannon ball array updated with new cannon ball
; Returns : -
; Calls : -
; - Updates cannon ball array and cannon array if cannon fires (if primary key is pressed)
proc _FireCannon
.MapOff			arg	4
.CannonArray		arg	4
.CannonBallArray	arg	4
.X			arg	2
.Y			arg	2
.InputFlags		arg	2

	test	word [.InputFlags+ebp], PRIMARY_FLAG	; check if primary key is pressed
	jz	.End

	mov	eax, [.CannonArray+ebp]
	
.CheckEmptyCannon					; check for empty CannonArray cell
	movzx	ecx, byte [eax+3]
	test	cl, 00000001b
	jz	.UseThisCannon
	add	eax, 4
	jmp	.CheckEmptyCannon

.UseThisCannon
	or	byte [eax+3], 00000001b			; update CannonArray cell	
	mov	ebx, [.CannonBallArray+ebp]

.CheckEmptyCBall
	cmp	dword [ebx], 0				; check for empty CannonBallArray cell
	je	.UseThisCBall
	add	ebx, 8
	jmp	.CheckEmptyCBall
	
.UseThisCBall						; update CannonBallArray
	movzx	edx, word [eax]
	mov	word [ebx+6], dx			; put byte 7-6 x, y coordinates
	movzx	ecx, byte [.X+ebp]			; put byte 5 x destination
	mov	byte [ebx+5], cl
	movzx	ecx, byte [.Y+ebp]			; put byte 4 y destination
	mov	byte [ebx+4], cl

	movzx	ecx, dh					; put byte 3-2 x pixel
	shr	ecx, 3
	mov	word [ebx+2], cx

	movzx	ecx, dl					; put byte 1-0 y pixel
	shr	ecx, 3
	mov	word [ebx], cx
	
.End
	ret


endproc
_FireCannon_arglen	EQU	18



;--------------------------------------------------------
;-- void _ScrollBanner(dword *BannerX, dword *BannerY) --
;--------------------------------------------------------
; Inputs : BannerX - offset of x coordinate of banner
;          BannerY - offset of y coordinate of banner
;          [_AnimateTick] - tick counter for animation
; Outputs : banner positions updated
; Returns : -
; Calls : -
; - Updates banner position
proc _ScrollBanner
.BannerX	arg	4
.BannerY	arg	4

ret

endproc
_ScrollBanner_arglen	EQU	8


;--------------------------------
;-- dword _Random(word MaxNum) --
;--------------------------------
; Inputs : MaxNum - max value to be generated
; Outputs : -
; Returns : random value from 0 to (MaxNum - 1)
; Calls : -
; - Generates and returns a random value
proc _Random
.MaxNum		arg	2

	movzx	eax, word [_TimeTick]	; used _TimeTick instead of seed
	mov	ebx, 37549                                                    
	mul	ebx
	add	eax, 37747
	adc	edx, 0
	mov	ebx, 65535
	div	ebx
	mov	eax, edx    
;	mov	word [seed], dx
	xor	edx, edx
	mov	ecx, [.MaxNum + ebp]
	div	ecx
	mov	eax, edx

	ret

endproc
_Random_arglen	EQU	2


;------------------------------------------------------------------------------------------------------------------
;-- dword PointInBox(word X, word Y, word BoxULCornerX, word BoxULCornerY, word BoxLRCornerX, word BoxLRCornerY) --
;------------------------------------------------------------------------------------------------------------------
; Inputs : X - x coordinate of point in question
;          Y - y coordinate of point in question
;          BoxULCornerX - x coordinate of upper-left hand corner of box
;          BoxULCornerY - y coordinate of upper-left hand corner of box
;          BoxLRCornerX - x coordinate of lower-right hand corner of box
;          BoxLRCornerY - y coordinate of lower-right hand corner of box
; Outputs : -
; Returns : 1 if BoxULCornerX <= X <= BoxLRCornerX and BoxULCornerY <= Y <= BoxLRCornerY; 0 otherwise
; Calls : -
; - determines if the point (X, Y) is located in the box formed by the points (BoxULCornerX, BoxULCornerY) and
;   (BoxLRCornerX, BoxLRCornerY)
proc _PointInBox
.X		arg	2
.Y		arg	2
.BoxULCornerX	arg	2
.BoxULCornerY	arg	2
.BoxLRCornerX	arg	2
.BoxLRCornerY	arg	2

	mov	ax, [.X + ebp]			; check X if inside box
	cmp	ax, [.BoxULCornerX + ebp]	;
	jb	.outsideOfBox			;
	cmp	ax, [.BoxLRCornerX + ebp]	;
	ja	.outsideOfBox			;

	mov	ax, [.Y + ebp]			; check Y if inside box
	cmp	ax, [.BoxULCornerY + ebp]	;
	jb	.outsideOfBox			;
	cmp	ax, [.BoxLRCornerY + ebp]	;
	ja	.outsideOfBox			;

	mov	eax, 1
	jmp	.done

.outsideOfBox
	mov	eax, 0

.done
	ret

endproc
_PointInBox_arglen	EQU	12	   

;---------------------------------------------------------
;-- void _DrawStatusBar(dword *DestOff, word X, word Y) --
;---------------------------------------------------------
; Inputs : DestOff - offset of destination buffer
;          X - x coordinate of the status bar (use this as reference)
;          Y - y coordinate of the status bar (use this as reference)
;          _StatusBarOff - offset of status bar image
;          _BigNumFontOff - offset of big number font image
;          _SmallNumFontOff - offset of small number font image
;          _BlueNumFontOff - offset of blue number font image
;          [_NumP1Castle] - number of conquered P1 castle
;          [_NumP2Castle] - number of conquered P2 castle
;          [_NumP1Territory] - number of conquered P1 territory
;          [_NumP2Territory] - number of conquered P2 territory
;          [_NumP1Cannon] - number of P1 cannons
;          [_NumP2Cannon] - number of P2 cannons
;          [_Time] - time counter for displaying time left
;          [_AnimateTick] - tick counter for animation
; Outputs : DestOff - status bar drawn to the destination buffer pointed to by DestOff
; Returns : -
; Calls : _ClearBuffer, _CopyBuffer
; - Draws status bar which shows game info to the destination buffer pointed to by DestOff
proc _DrawStatusBar
.DestOff	arg	4
.X		arg	2
.Y		arg	2

	; not complete, being tested

	push	esi

	invoke	_CopyBuffer, dword [_StatusBarOff], word STATUSBAR_WIDTH, word STATUSBAR_HEIGHT, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, word [.X + ebp], word [.Y + ebp]
	movzx	eax, byte [_Time]
	mov	ebx, 10
	div	ebx
	mov	esi, edx
	mov	ebx, BIG_NUM_WIDTH
	mul	ebx
	mov	edx, [_BigNumFontOff]
	mov	bx, [.X + ebp]
	add	bx, BIG_NUM_WIDTH / 2 + 20
	mov	cx, [.Y + ebp]
	add	cx, BIG_NUM_HEIGHT / 2 + 20
	invoke	_DrawImage, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_BigNumFontOff], word BIG_NUM_WIDTH, word BIG_NUM_HEIGHT, word bx, word cx, word 10, dword 1

	xor	edx, edx
	mov	dl, byte[_AnimateTick]
	push	edx
	mov	byte [_AnimateTick], 0

	mov	eax, esi
	mov	ebx, BIG_NUM_WIDTH
	mul	ebx
	mov	edx, [_BigNumFontOff]
	mov	bx, [.X + ebp]
	add	bx, BIG_NUM_WIDTH / 2 + 65
	mov	cx, [.Y + ebp]
	add	cx, BIG_NUM_HEIGHT / 2 + 20
	invoke	_DrawImage, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_BigNumFontOff], word BIG_NUM_WIDTH, word BIG_NUM_HEIGHT, word bx, word cx, word 10, dword 1

;	xor		eax, eax
;	xor		ebx, ebx
;	mov		al, byte [_NumRounds]
;	mov		bx, 20
;	mul		bx
;	mov		bx, ax
	mov		bx, 20 / 2 + 95
	add		bx, [.X + ebp]
	mov		cx, [.Y + ebp]
	add		cx, 21 / 2 + 88
	

	invoke	_DrawImage, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_SmallNumFontOff], word 200, word 21, word bx, word cx, word 10, dword 1
	;invoke	_CopyBuffer, dword [_SmallNumFontOff], word 200, word 21, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, word bx, word cx

;	mov		bx, 10 / 2 + 45
;	add		bx, [.X + ebp]
;	mov		cx, [.Y + ebp]
;	add		cx, 21 / 2 + 150
	
;	invoke	_DrawImage, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_BlueNumFontOff], word 100, word 12, word bx, word cx, word 10, dword 0
;	add		cx, 20
;	invoke	_DrawImage, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_BlueNumFontOff], word 100, word 12, word bx, word cx, word 10, dword 0
;	add		cx, 20
;	invoke	_DrawImage, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_BlueNumFontOff], word 100, word 12, word bx, word cx, word 10, dword 1
;	add		cx, 20
;	invoke	_DrawImage, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_BlueNumFontOff], word 100, word 12, word bx, word cx, word 10, dword 1
;	add		cx, 55
;	invoke	_DrawImage, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_BlueNumFontOff], word 100, word 12, word bx, word cx, word 10, dword 1
;	add		cx, 20
;	invoke	_DrawImage, dword [.DestOff + ebp], word SCREEN_WIDTH, word SCREEN_HEIGHT, dword [_BlueNumFontOff], word 100, word 12, word bx, word cx, word 10, dword 1
;	add		cx, 20

	pop	edx
	mov	byte [_AnimateTick], dl	

	pop	esi
	ret

endproc
_DrawStatusBar_arglen	EQU	8


;--------------------------------------------------
;-- void _DrawMap(dword *DestOff, dword *MapOff) --
;--------------------------------------------------
; Inputs : DestOff - offset of destination buffer
;          MapOff - offset of map buffer
;          [_TerrainOff] - offset of terrain image
;          [_FlatCastleOff] - offset of flat castle image
;          [_BattleCastleOff] - offset of battle phase castle image
;          [_FlatCannonOff] - offset of flat cannon image
;          [_BattleCannonOff] - offset of battle phase cannon image
;          [_FlatWallOff] - offset of flat wall image
;          [_BattleWallOff] - offset of battle phase wall image
;          [_DestroyedCannonOff] - offset of destroyed cannon image
;          [_RubblesOff] - offset of rubbles image
;          [_OverlayOff] - offset of overlay buffer
;          [_Phase] - current phase
;          [_AnimateTick] - tick counter for animation
; Outputs : DestOff - map data drawn to the destination buffer pointed to by DestOff
; Returns : -
; Calls : _ClearBuffer, _CopyBuffer, _ComposeBuffer
; - Draws map data to the destination buffer pointed to by DestOff
proc _DrawMap
.DestOff	arg	4
.MapOff		arg	4

	push	esi
	push	edi

	invoke	_CopyBuffer, dword [_TerrainOff], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, word 0, word 0

	mov	esi, [.MapOff + ebp]
	xor	edi, edi
	xor	bx, bx			; bx holds current x coordinate in map buffer
	xor	cx, cx			; cx holds current y coordinate in map buffer

.loopDrawRegion
	cmp	bx, GAME_MAP_WIDTH
	jb	.notEndOfRow1
	xor	bx, bx
	inc	cx
	cmp	cx, GAME_MAP_HEIGHT
	jae	near .drawObjects

.notEndOfRow1
	mov	ax, [esi + edi * 2]
	and	ax, OCCUPIED + REGION
	cmp	ax, OCCUPIED + P1_REGION
	je	.drawP1Terrain
	cmp	ax, OCCUPIED + P2_REGION
	je	.drawP2Terrain
	jmp	.doneDrawRegion

.drawP1Terrain
	mov	ax, bx
	shl	ax, 3
	mov	dx, cx
	shl	dx, 3
	push	bx
	push	cx
	invoke	_ComposeBuffers, dword [_P1TerrainOff], word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, ax, dx
	pop	cx
	pop	bx
	jmp	.doneDrawRegion

.drawP2Terrain
	mov	ax, bx
	shl	ax, 3
	mov	dx, cx
	shl	dx, 3
	push	bx
	push	cx
	invoke	_ComposeBuffers, dword [_P2TerrainOff], word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, ax, dx
	pop	cx
	pop	bx

.doneDrawRegion
	inc	edi
	inc	bx
	jmp	near .loopDrawRegion

.drawObjects
	xor	edi, edi
	xor	bx, bx			; bx holds current x coordinate in map buffer
	xor	cx, cx			; bx holds current x coordinate in map buffer

.loopDrawObjects
	cmp	bx, GAME_MAP_WIDTH
	jb	.notEndOfRow2
	xor	bx, bx
	inc	cx
	cmp	cx, GAME_MAP_HEIGHT
	jae	near .done

.notEndOfRow2
	mov	ax, [esi + edi * 2]
	cmp	al, P1_CANNON
	je	NEAR .drawP1Cannon
	cmp	al, P2_CANNON
	je	NEAR .drawP2Cannon
	and	ax, ~OCCUPIED
	cmp	ax, P1_CASTLE
	je	near .drawP1Castle
	cmp	ax, P2_CASTLE
	je	near .drawP2Castle
	cmp	ax, P1_WALL
	je	near .drawP1Wall
	cmp	ax, P2_WALL
	je	near .drawP2Wall
	jmp	.doneDrawObjects

.drawP1Castle
	mov	ax, bx
	dec	ax
	shl	ax, 3
	mov	dx, cx
	dec	dx
	shl	dx, 3
	push	bx
	push	cx
	invoke	_ComposeBuffers, dword [_P1FlatCastleOff], word CASTLE_WIDTH, word CASTLE_HEIGHT, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, ax, dx
	pop	cx
	pop	bx
	jmp	.doneDrawObjects

.drawP2Castle
	mov	ax, bx
	dec	ax
	shl	ax, 3
	mov	dx, cx
	dec	dx
	shl	dx, 3
	push	bx
	push	cx
	invoke	_ComposeBuffers, dword [_P2FlatCastleOff], word CASTLE_WIDTH, word CASTLE_HEIGHT, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, ax, dx
	pop	cx
	pop	bx
	jmp	.doneDrawObjects

.drawP1Wall
	mov	ax, bx
	shl	ax, 3
	mov	dx, cx
	shl	dx, 3
	push	bx
	push	cx
	invoke	_CopyBuffer, dword [_P1FlatWallOff], word WALL_WIDTH, word WALL_HEIGHT, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, ax, dx
	pop	cx
	pop	bx
	jmp	.doneDrawObjects

.drawP2Wall
	mov	ax, bx
	shl	ax, 3
	mov	dx, cx
	shl	dx, 3
	push	bx
	push	cx
	invoke	_CopyBuffer, dword [_P2FlatWallOff], word WALL_WIDTH, word WALL_HEIGHT, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, ax, dx
	pop	cx
	pop	bx
	jmp	.doneDrawObjects

.drawP1Cannon
	mov	ax, bx
	shl	ax, 3
	mov	dx, cx
	shl	dx, 3
	push	bx
	push	cx
	invoke	_CopyBuffer, dword [_P1FlatCannonOff], word CANNON_WIDTH, word CANNON_HEIGHT, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, ax, dx
	pop	cx
	pop	bx
	jmp	.doneDrawObjects

.drawP2Cannon
	mov	ax, bx
	shl	ax, 3
	mov	dx, cx
	shl	dx, 3
	push	bx
	push	cx
	invoke	_CopyBuffer, dword [_P1FlatCannonOff], word CANNON_WIDTH, word CANNON_HEIGHT, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, ax, dx
	pop	cx
	pop	bx
	jmp	.doneDrawObjects

.doneDrawObjects
	inc	edi
	inc	bx
	jmp	near .loopDrawObjects

.done
	pop	edi
	pop	esi
	ret

endproc
_DrawMap_arglen	EQU	8


;------------------------------------------------------------------------------------------------------------------------------------------------------------
;-- void _DrawImage(dword *DestOff, word DestWidth, word DestHeight, dword *ImageOff, word ImageWidth, word ImageHeight, word X, word Y, word NumFrames, dword AlphaBlend) --
;------------------------------------------------------------------------------------------------------------------------------------------------------------
; Inputs : DestOff - offset of destination buffer
;          DestWidth - width of destination buffer
;          DestHeight - height of destination buffer
;          ImageOff - offset of image to draw
;          ImageWidth - width of image buffer
;          ImageHeight - height of image buffer
;          X - x coordinate of cursor in pixels
;          Y - y coordinate of cursor in pixels
;          NumFrames - number of frames for image
;          AlphaBlend - if 1, alpha-blend image to destination buffer
;          [_OverlayOff] - offset of overlay buffer
;          [_AnimateTick] - tick counter for animation
; Outputs : image drawn on the destination buffer at (X, Y)
; Returns : -
; Calls : _ClearBuffer, _CopyBuffer, _ComposeBuffer, _PointInBox
; - Draws image at (X, Y) on the destination buffer pointed to by DestOff and alpha-blends if indicated to do so
proc _DrawImage
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.ImageOff	arg	4
.ImageWidth	arg	2
.ImageHeight	arg	2
.X		arg	2
.Y		arg	2
.NumFrames	arg	2
.AlphaBlend	arg	4

	push	esi
	push	edi

	invoke	_ClearBuffer, dword [_OverlayOff], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, dword 0

	xor	cx, cx
	xor	bx, bx
	xor	esi, esi

	movzx	eax, word [.Y + ebp]		;
	movzx	edi, word [.ImageHeight + ebp]	;
	shr	edi, 1				;
	sub	eax, edi			;
	movzx	edi, word [.DestWidth + ebp]	;
	imul	edi				;
	movzx	edi, word [.X + ebp]		;
	add	eax, edi			;
	movzx	edi, word [.ImageWidth + ebp]	;
	shr	edi, 1				;
	sub	eax, edi			;
	mov	edi, eax			; for calculating destination offset

.loopDraw
	cmp	bx, [.ImageWidth + ebp]
	jb	.notEndOfRow
	inc	cx
	xor	bx, bx
	movzx	eax, word [.DestWidth + ebp]
	add	edi, eax
	movzx	eax, word [.ImageWidth + ebp]
	sub	edi, eax
	movzx	eax, word [.ImageWidth + ebp]
	sub	esi, eax
	movzx	edx, word [.NumFrames + ebp]
	mul	edx
	add	esi, eax
	cmp	cx, [.ImageHeight + ebp]
	jae	near .drawDone

.notEndOfRow
	mov	ax, [.X + ebp]			;
	mov	dx, [.ImageWidth + ebp]		;
	shr	dx, 1				;
	sub	ax, dx				;
	add	ax, bx				; ax now holds current x coordinate of destination
	shl	eax, 16
	mov	dx, [.Y + ebp]			;
	mov	ax, [.ImageHeight + ebp]	;
	shr	ax, 1				;
	sub	dx, ax				;
	add	dx, cx				; bx now holds current y coordinate of destination
	shr	eax, 16

	inc	ax
	inc	dx
	push	cx
	push	bx
	invoke	_PointInBox, ax, dx, word 1, word 1, word [.DestWidth + ebp], word [.DestHeight + ebp]
	pop	bx
	pop	cx
	test	eax, eax
	jz	.outsideBoundary

	xor	eax, eax
	xor	edx, edx
	cmp	byte [_AnimateTick], 0
	je	.frame0
	movzx	ax, byte [_AnimateTick]
	div	word [.NumFrames + ebp]
	mov	eax, edx
	movzx	edx, word [.ImageWidth + ebp]
	mul	edx
	shl	eax, 2

.frame0
	add	eax, [.ImageOff + ebp]		;
	mov	eax, [eax + esi * 4]		; source offset

	cmp	dword [.AlphaBlend + ebp], 1
	je	.copyToOverlay
	mov	edx, [.DestOff + ebp]		;
	mov	[edx + edi * 4], eax		; store into location pointed to by destination offset
	jmp	.outsideBoundary

.copyToOverlay
	mov	edx, [_OverlayOff]		;
	mov	[edx + edi * 4], eax		; store into location pointed to by overlay buffer offset

.outsideBoundary
	inc	edi
	inc	esi
	inc	bx
	jmp	.loopDraw

.drawDone
	cmp	dword [.AlphaBlend + ebp], 1
	jne	.done
	invoke	_ComposeBuffers, dword [_OverlayOff], word [.DestWidth + ebp], word [.DestHeight + ebp], dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], word 0, word 0

.done
	pop	edi
	pop	esi
	ret

endproc
_DrawImage_arglen	EQU	26


;-----------------------------------------------------------------------------------
;-- void _DrawDeployCursor(dword *DestOff, word X, word Y, dword *CursorImageOff) --
;-----------------------------------------------------------------------------------
; Inputs : DestOff - offset of destination buffer
;          X - x coordinate of cursor in grids
;          Y - y coordinate of cursor in grids
;          CursorImageOff - offset of deploy cursor image
;          [_InvalidCannonOff] - offset of invalid cannon image
;          [_OverlayOff] - offset of overlay buffer
;          [_AnimateTick] - tick count that determines which sprite to draw
; Outputs : deploy cursor drawn on the destination buffer at (X, Y)
; Returns : -
; Calls : _BoundaryInRegion, _ClearBuffer, _CopyBuffer, _ComposeBuffer
; - Draws deploy cursor at (X, Y) on the destination buffer pointed to by DestOff, if the cannon lies over where it cannot be placed, it's drawn with invalid cannon image
proc _DrawDeployCursor
.DestOff	arg	4
.X		arg	2
.Y		arg	2
.CursorImageOff	arg	4


	movzx	eax, word[.Y + ebp]
	mov		edx, 65
	mul		edx
	add		ax, word[.X + ebp]
	add		eax, dword[_GameMapOff]
	movzx	eax, word[eax]
	
	test	al, 00000100b
	jnz		.player2

.player1
	mov	dx, P1_OCCUPIED
	invoke	_BoundaryInRegion, dword[_GameMapOff], word[.X+ebp], word[.Y+ebp], word 2, word 2, dx
	cmp	eax, 1
	je	.Avail	
	jmp	.notAvail

.player2
	mov	dx, P2_OCCUPIED
	invoke	_BoundaryInRegion, dword[_GameMapOff], word[.X+ebp], word[.Y+ebp], word 2, word 2, dx
	cmp	eax, 1
	je	.Avail	

.notAvail
	mov	eax, dword[_InvalidCannonOff]
	jmp	.draw

.Avail
	mov	eax, dword[.CursorImageOff + ebp]
	
.draw
	mov		bx, word[.X + ebp]
	mov		cx, word[.Y + ebp]
	shl		bx, 3
	shl		cx, 3
	invoke	_CopyBuffer, eax, word 16, word 16, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx

	ret

endproc
_DrawDeployCursor_arglen	EQU	12


;---------------------------------------------------------------------------------------
;-- void _DrawBlock(dword *DestOff, word X, word Y, word Block, dword *BlockImageOff) --
;---------------------------------------------------------------------------------------
; Inputs : DestOff - offset of destination buffer
;          X - x coordinate of block in grids
;          Y - y coordinate of block in grids
;          Block - block to draw
;          BlockImageOff - offset of block image
;          [_InvalidBlockOff] - offset of invalid block image
;          [_OverlayOff] - offset of overlay buffer
;          [_AnimateTick] - tick count that determines which sprite to draw
; Outputs : block drawn on the destination buffer at (X, Y)
; Returns : -
; Calls : _BlockInRegion, _ClearBuffer, _CopyBuffer, _ComposeBuffer
; - Draws block at (X, Y) on the destination buffer pointed to by DestOff, if the block lies over where it cannot be placed, it's drawn with invalid block image
proc _DrawBlock
.DestOff	arg	4
.X		arg	2
.Y		arg	2
.Block		arg	2
.BlockImageOff	arg	4

;	movzx	eax, word[.Y + ebp]
;	mov		edx, 65
;	mul		edx
;	add		ax, word[.X + ebp]
;	shl		eax, 1
;	add		eax, dword[_GameMapOff]
;	movzx	eax, word[eax]
	
;	test	al, 00000100b
;	jnz		.player2

;.player1
;	or		ax, 0005h
;	mov		dx, 0105h
;	mov		ecx, edx
;	push	ecx	
		
;	invoke _BlockInRegion, dword [.MapOff+ebp], ax, word [.X+ebp], word [.Y+ebp], dx
	
	mov	dx, 0100h
	invoke	_BlockInRegion, dword[_GameMapOff], word[.Block+ebp], word[.X+ebp], word[.Y+ebp], word 3, word 3, dx
	cmp	eax, 1
	je	near .Avail	

	mov	dx, 0101h
	invoke	_BlockInRegion, dword[_GameMapOff], word[.Block+ebp], word[.X+ebp], word[.Y+ebp], word 3, word 3, dx
	cmp	eax, 1
	je	near .Avail	

	mov	dx, 0104h
	invoke	_BlockInRegion, dword[_GameMapOff], word[.Block+ebp], word[.X+ebp], word[.Y+ebp], word 3, word 3, dx
	cmp	eax, 1
	je	near .Avail	

	mov	dx, 0105h
	invoke	_BlockInRegion, dword[_GameMapOff], word[.Block+ebp], word[.X+ebp], word[.Y+ebp], word 3, word 3, dx
	cmp	eax, 1
	je	near .Avail	

.notAvail
	mov	eax, dword[_InvalidBlockOff]
	jmp	.draw

.Avail
	mov	eax, dword[.BlockImageOff + ebp]
	
.draw
	movzx	edx, word [.Block+ ebp]

.CheckEight				; check for region 8
	test	dh, 00000001b
	jz		.CheckSeven

	movzx	ebx, word [.X + ebp]
	movzx	ecx, word [.Y + ebp]
	shl		ebx, 3
	shl		ecx, 3
	push	edx
	push	eax
	invoke	_CopyBuffer, eax, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx
	pop		eax
	pop		edx

.CheckSeven				; check for region 7
	test	dl, 10000000b
	jz		.CheckSix

	movzx	ebx, word [.X + ebp]
	movzx	ecx, word [.Y + ebp]
	dec		ecx
	shl		ebx, 3
	shl		ecx, 3
	push	edx
	push	eax
	invoke	_CopyBuffer, eax, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx
	pop		eax
	pop		edx

.CheckSix				; check for region 6
	test	dl, 01000000b
	jz	.CheckFive

	movzx	ebx, word [.X + ebp]
	movzx	ecx, word [.Y + ebp]
	inc		ebx
	dec		ecx
	shl		ebx, 3
	shl		ecx, 3
	push	edx
	push	eax
	invoke	_CopyBuffer, eax, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx
	pop		eax
	pop		edx

.CheckFive				; check for region 5
	test	dl, 00100000b
	jz	.CheckFour

	movzx	ebx, word [.X + ebp]
	movzx	ecx, word [.Y + ebp]
	inc		ebx
	shl		ebx, 3
	shl		ecx, 3
	push	edx
	push	eax
	invoke	_CopyBuffer, eax, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx
	pop		eax
	pop		edx

.CheckFour				; check for region 4
	test	dl, 00010000b
	jz	.CheckThree

	movzx	ebx, word [.X + ebp]
	movzx	ecx, word [.Y + ebp]
	inc		ebx
	inc		ecx
	shl		ebx, 3
	shl		ecx, 3
	push	edx
	push	eax
	invoke	_CopyBuffer, eax, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx
	pop		eax
	pop		edx

.CheckThree				; check for region 3
	test	dl, 00001000b
	jz	.CheckTwo

	movzx	ebx, word [.X + ebp]
	movzx	ecx, word [.Y + ebp]
	inc		ecx
	shl		ebx, 3
	shl		ecx, 3
	push	edx
	push	eax
	invoke	_CopyBuffer, eax, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx
	pop		eax
	pop		edx

.CheckTwo				; check for region 2
	test	dl, 00000100b
	jz	.CheckOne

	movzx	ebx, word [.X + ebp]
	movzx	ecx, word [.Y + ebp]
	dec		ebx
	inc		ecx
	shl		ebx, 3
	shl		ecx, 3
	push	edx
	push	eax
	invoke	_CopyBuffer, eax, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx
	pop		eax
	pop		edx

.CheckOne				; check for region 1
	test	dl, 00000010b
	jz	.CheckZero

	movzx	ebx, word [.X + ebp]
	movzx	ecx, word [.Y + ebp]
	dec		ebx
	shl		ebx, 3
	shl		ecx, 3
	push	edx
	push	eax
	invoke	_CopyBuffer, eax, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx
	pop		eax
	pop		edx

.CheckZero				; check for region 0
	test	dl, 00000001b
	jz		.Done

	movzx	ebx, word [.X + ebp]
	movzx	ecx, word [.Y + ebp]
	dec		ebx
	dec		ecx
	shl		ebx, 3
	shl		ecx, 3
	push	edx
	push	eax
	invoke	_CopyBuffer, eax, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, bx, cx
	pop		eax
	pop		edx

.Done
	ret

endproc
_DrawBlock_arglen	EQU	14


;------------------------------------------------------------------------------------------------------
;-- void _DrawExplosion(dword *DestOff, dword *MapOff, dword *ExplosionArray, dword *ExplosionImage) --
;------------------------------------------------------------------------------------------------------
; Inputs : DestOff - offset of destination buffer
;          MapOff - offset of map buffer
;          ExplosionArray - array of explosions to draw
;          ExplosionImage - offset of explosion image
;          [_AnimateTick] - tick count for animation (updates ExplosionArray)
; Outputs : explosions drawn to the buffer pointed to by DestOff
; Returns : -
; Calls : _CopyBuffer
; - Draws explosions on the destination buffer pointed to by DestOff
proc _DrawExplosion
.DestOff	arg	4
.MapOff		arg	4
.ExplosionArray	arg	4
.ExplosionImage	arg	4


	mov	eax, dword [.ExplosionArray + ebp]

.draw:
	mov	edx, dword [eax]
	
	test	edx, 10000000h
	jz	.endLoop
	
	mov	ecx, edx
	mov	ebx, edx
	and	bx, 0011b				; y-coordinate
	shr	edx, 8
	and	dx, 0011b				; x-coordinate
	shr	ecx, 16
	and	cx, 0011b				; current frame(animate tick?)
	
	add	ecx, dword [.ExplosionImage + ebp]
	push	eax
	
	invoke	_CopyBuffer, ecx, word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, dx, bx	

	pop	eax
	inc	eax
	
	jmp	.draw
	
.endLoop
ret

endproc
_DrawExplosion_arglen	EQU	16


;------------------------------------------------------------------------------------------
;-- void _DrawCannonBall(dword *DestOff, dword *CannonBallArray, dword *CannonBallImage) --
;------------------------------------------------------------------------------------------
; Inputs : DestOff - offset of destination buffer
;          CannonBallArray - array of cannon balls to draw
;          CannonBallImage - offset of cannon ball image
; Outputs : cannon balls drawn to the buffer pointed to by DestOff
; Returns : -
; Calls : _CopyBuffer
; - Draws cannon balls on the destination buffer pointed to by DestOff
proc _DrawCannonBall
.DestOff		arg	4
.CannonBallArray	arg	4
.CannonBallImage	arg	4


	mov	ebx, dword[.CannonBallArray + ebp]

.moveCannon

	mov	edx, dword[ebx]
	
	test	edx, 00000000						; test for the end of the array
	jz	.endMove
	
	mov	ecx, edx
	shr	ecx, 8
	and	cx, 00FFh
	and	dx, 00FFh

	push	ebx

	invoke	_CopyBuffer, dword [.CannonBallImage + ebp], word 8, word 8, dword [.DestOff + ebp], word MAP_PIXEL_WIDTH, word MAP_PIXEL_HEIGHT, cx, dx
	
	pop	ebx
	add	ebx, 2		
	jmp	.moveCannon

.endMove
	ret
endproc
_DrawCannonBall_arglen	EQU	12


;-----------------------------------------------------------------------------------
;-- void _DimBuffer(dword *DestOff, word DestWidth, word DestHeight, word DimVal) --
;-----------------------------------------------------------------------------------
; Inputs : DestOff - offset of image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          DimVal - value with which to dim screen
; Outputs : buffer is dimmed with DimVal
; Returns : -
; Calls : -
; - Dims the buffer pointed to by DestOff with DimVal
proc _DimBuffer
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.DimVal		arg	2

ret

endproc
_DimBuffer_arglen	EQU	10


;------------------------------------------------------------------------------------
;-- void ClearBuffer(dword *DestOff, word DestWidth, word DestHeight, dword Color) --
;------------------------------------------------------------------------------------
; Inputs : DestOff - offset of an image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          Color - color to make buffer
; Outputs : color copied to buffer
; Returns : -
; Calls : -
; - clears a buffer pointed to by DestOff by filling it with color Color
proc _ClearBuffer
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.Color		arg	4

	push	edi

	mov	ax, ds
	mov	es, ax
	movzx	eax, word [.DestWidth + ebp]	;
	movzx	ecx, word [.DestHeight + ebp]	;
	mul	ecx				;
	mov	ecx, eax			; run (DestWidth * DestHeight) times
	mov	eax, [.Color + ebp]
	cld
	mov	edi, [.DestOff + ebp]
	rep	stosd

	pop	edi
	ret

endproc
_ClearBuffer_arglen	EQU	12


;------------------------------------------------------------------------------------------------------------------------------------
;-- void CopyBuffer(dword *ScrOff, word SrcWidth, word SrcHeight, dword *DestOff, word DestWidth, word DestHeight, word X, word Y) --
;------------------------------------------------------------------------------------------------------------------------------------
; Inputs : ScrOff - offset of source buffer
;          ScrWidth - width of source buffer
;          SrcHeight - height of source buffer
;          DestOff - offset of destination buffer
;          DestWidth - width of destination buffer
;          DestHeight - height of destination buffer
;          X - x coordinate of start point in destination buffer
;          Y - y coordinate of start point in destination buffer
; Outputs : source buffer copied onto destination buffer
; Returns : -
; Calls : -
; - copies a source buffer pointed to by ScrOff to a location (X, Y) in a destination buffer pointed to by DestOff
proc _CopyBuffer
.SrcOff		arg	4
.SrcWidth	arg	2
.SrcHeight	arg	2
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2

	push	esi
	push	edi

	mov	ax, ds
	mov	es, ax

	mov	esi, [.SrcOff + ebp]
	movzx	eax, word [.DestWidth + ebp]	;
	movsx	edi, word [.Y + ebp]		;
	imul	edi				;
	movsx	edi, word [.X + ebp]		;
	add	eax, edi			;
	shl	eax, 2				;
	add	eax, [.DestOff + ebp]		;
	mov	edi, eax			; calculate destination offset
	cld
	mov	bx, word [.SrcHeight + ebp]

.loopCopy
	movzx	ecx, word [.SrcWidth + ebp]	; run SrcWidth times
	rep	movsd
	movzx	eax, word [.DestWidth + ebp]
	sub	ax, word [.SrcWidth + ebp]
	shl	eax, 2
	add	edi, eax
	dec	bx
	test	bx, bx
	jnz	.loopCopy

	pop	edi
	pop	esi
	ret

endproc
_CopyBuffer_arglen	EQU	20


;----------------------------------------------------------------------------------------------------------------------------------------
;-- void ComposeBuffers(dword *SrcOff, word SrcWidth, word SrcHeight, dword *DestOff, word DestWidth, word DestHeight, word X, word Y) --
;----------------------------------------------------------------------------------------------------------------------------------------
; Inputs : ScrOff - offset of source buffer
;          ScrWidth - width of source buffer
;          SrcHeight - height of source buffer
;          DestOff - offset of destination buffer
;          DestWidth - width of destination buffer
;          DestHeight - height of destination buffer
;          X - x coordinate of start point in destination buffer
;          Y - y coordinate of start point in destination buffer
; Outputs : source buffer alpha composed onto destination buffer
; Returns : -
; Calls : -
; - alpha composes a source buffer pointed to by ScrOff onto a destination buffer pointed to by DestOff at location (X, Y)
proc _ComposeBuffers
.SrcOff		arg	4
.SrcWidth	arg	2
.SrcHeight	arg	2
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X	        arg	2
.Y		arg	2

	push	esi
	push	edi

	mov	esi, [.SrcOff + ebp]
	movzx	eax, word [.DestWidth + ebp]
	movsx	edi, word [.Y + ebp]
	imul	edi
	movsx	edi, word [.X + ebp]
	add	eax, edi
	shl	eax, 2
	add	eax, [.DestOff + ebp]
	mov	edi, eax

	mov	cx, [.SrcHeight + ebp]
	mov	dx, [.SrcWidth + ebp]
	shr	dx, 1

.loopCompose
	test	dx, dx
	jnz	.startMMX
	mov	dx, [.SrcWidth + ebp]
	shr	dx, 1
	movzx	eax, word [.DestWidth + ebp]
	sub	ax, word [.SrcWidth + ebp]
	shl	eax, 2
	add	edi, eax
	dec	cx
	test	cx, cx
	jz	near .done

.startMMX
	movq	mm0, [esi]		;
	movq	mm1, mm0		;
	pxor	mm7, mm7		;
	punpckhbw	mm1, mm7	; unpack high dword from mm0 into mm1 (source)

	mov	al, [esi + 7]		;
	mov	ah, al			;
	mov	bx, ax			;
	shl	ebx, 16			;
	mov	bx, ax			;
	movd	mm2, ebx		;
	punpcklbw	mm2, mm7	; copy out source alpha byte into ebx then to mm2

	pmullw	mm1, mm2		; alpha * source
	paddusw	mm1, [_RoundingFactor]
	psrlw	mm1, 8

	movq	mm4, [edi]		;
	movq	mm5, mm4		;
	punpckhbw	mm5, mm7	; unpack high dword from mm4 into mm5 (destination)

	paddusw	mm1, mm5		; alpha * source + destination

	pmullw	mm5, mm2		; alpha * destination
	paddusw	mm5, [_RoundingFactor]
	psrlw	mm5, 8

	psubusw	mm1, mm5		; (alpha * source) + destination - (alpha * destination)

	punpcklbw	mm0, mm7	; unpack low dword from mm0 into mm0 (source)

	mov	al, [esi + 3]		;
	mov	ah, al			;
	mov	bx, ax			;
	shl	ebx, 16			;
	mov	bx, ax			;
	movd	mm2, ebx		;
	punpcklbw	mm2, mm7	; copy out source alpha byte into ebx then to mm2

	pmullw	mm0, mm2		; alpha * source
	paddusw	mm0, [_RoundingFactor]
	psrlw	mm0, 8

	movq	mm5, mm4		;
	punpcklbw	mm5, mm7	; unpack low dword from mm4 into mm5 (destination)

	paddusw	mm0, mm5		; alpha * source + destination

	pmullw	mm5, mm2		; alpha * destination
	paddusw	mm5, [_RoundingFactor]
	psrlw	mm5, 8

	psubusw mm0, mm5		; (alpha * source) + destination - (alpha * destination)

	packuswb	mm0, mm1	; pack high and low words back into mm0

	movq	[edi], mm0
	dec	dx
	add	esi, 8
	add	edi, 8
	jmp	.loopCompose

.done
	pop	edi
	pop	esi
	ret

endproc
_ComposeBuffers_arglen	EQU	20


;---------------------------
;-- dword _InstallSound() --
;---------------------------
; Inputs : - None
; Outputs : installs sound
; Returns : 1 if error; 0 otherwise
; Calls : _SB16_Init
; - Installs sound ISR
_InstallSound
	mov	byte [_DMA_Mix], 00h
	mov	dword [ISR_Called], 0
	invoke	_DMA_Allocate_Mem, dword SIZE, dword DMASel, dword DMAAddr ;allocate buffer for BGM
	cmp	[DMASel], word 0
	je	near .error
	invoke	_DMA_Lock_Mem	
	mov	eax, 0
	ret
.error
	mov	eax, 1
	ret
ret


;-------------------------
;-- void _RemoveSound() --
;-------------------------
; Inputs : -
; Outputs : -
; Returns : -
; Calls : _SB16_exit
; - Removes sound ISR
_RemoveSound

ret


;----------------------
;-- void _SoundISR() --
;----------------------
; Inputs : - None
; Outputs : sound played
; Returns : - none
; Calls : - _DMA_Refill
; - Handles Sound
_SoundISR
	inc dword [ISR_Called]
	invoke	_DMA_Refill
ret

;----------------------------
;-- void _DMA_Refill() ------
;----------------------------
; Inputs : - NOne
; Outputs : - DMA Buffer Refilled
; Calls : -_SB16_Start
; Returns : none
; -Refills appropriate half buffer
_DMA_Refill
	cld
	cmp	byte [_DMA_Refill_Flag], 00h      ;refill first half for 00h, second for 01h
	jne	near .Refill_Second_Half
.Refill_First_Half
	mov	byte [_DMA_Refill_Flag], 01h      ; set next refill flag
	mov	es, [DMASel]                      ;copy data to buffer
	mov	ecx, SIZE/8                       ;     "
	mov	edi, 0                            ;      "
	mov	esi, [BGMPos]                     ;       "
	rep	movsd                             ;      "
	cmp	byte [_DMA_Mix], 01h              ;check mix flag and decide whether to mix sounds
	jne	near .CheckPos
	mov	ecx, 0
.MixFirHalf	                              ;mix with first half buffer
	cmp	dword [MixCycle], 0               ;check number of mixing cycles
	je .lastMix1
	movd mm3, [es:ecx]                    ; copy data to mmx registers and add bytewise
	mov	esi, [SFXPos]                     ;
	movd mm6, [esi]                       ;
	paddusb mm3, mm6                      ;
	movd [es:ecx], mm3                    ;move back to buffer
	add ecx, 4                            ;increment ecx   
	add	dword [SFXPos], 4                 ;    and position
	cmp	ecx, SIZE/2
	jb .MixFirHalf
	dec dword [MixCycle] 
	jmp .CheckPos
.lastMix1                                
	;movd mm3, [es:ecx]
	;mov	esi, [SFXPos]
	;movd mm6, [esi]
	;paddusb mm3, mm6
	;movd [es:ecx], mm3
	;add ecx, 4
	;add	dword [SFXPos], 4
	;cmp	ecx, [RemCycle]
	;jb .lastMix1
	mov byte [_DMA_Mix], 00h
	jmp .CheckPos
.Refill_Second_Half                      ;refill second half of buffer
	mov	byte [_DMA_Refill_Flag], 00h     ; same as refilling first half
	mov	es, [DMASel]
	mov	ecx, SIZE/8
	mov	edi, SIZE/2
	mov	esi, [BGMPos]
	rep	movsd
	cmp	byte [_DMA_Mix], 01h
	jne near .CheckPos
	mov	ecx, SIZE/2
.MixSecHalf                              ;mix sounds in the second half
	cmp	dword [MixCycle], 0              ; same as mixing in the first half
	je .lastMix2
	movd mm3, [es:ecx]
	mov	esi, [SFXPos]
	movd mm6, [esi]
	paddusb mm3, mm6
	movd [es:ecx], mm3
	add ecx, 4
	add	dword [SFXPos], 4
	cmp	ecx, SIZE
	jb .MixSecHalf
	dec dword [MixCycle] 
	jmp .CheckPos
.lastMix2
;	movd mm3, [es:ecx]
;	mov	esi, [SFXPos]
;	movd mm6, [esi]
;	paddusb mm3, mm6
;	movd [es:ecx], mm3
;	add ecx, 4
;	add	dword [SFXPos], 4
;	mov	eax, [RemCycle]
;	add	eax, SIZE/2
;	cmp	ecx, eax
;	jb .lastMix2
	mov byte [_DMA_Mix], 00h
.CheckPos
	add	dword [BGMPos], SIZE/2               ;check where we're at in the BGM file
	add	dword [NextPos], SIZE/2              ; and increment positions
	mov	eax, [BGMSize]
	cmp	eax, [NextPos]
	ja near	.Done
.StartOver                                   ;when BGM ends, restart
	mov	eax, [BGMOff]
	mov	[BGMPos], eax
	add	dword [BGMPos], SIZE
	mov	dword [NextPos], SIZE
	mov byte [_DMA_Refill_Flag], 00h
	mov	es, [DMASel]
	mov	ecx, SIZE/4
	mov	edi, 0
	mov	esi, [BGMOff]
	rep	movsd
	mov byte[_DMA_Repeat_Flag], 00h
	invoke	_SB16_Start, dword SIZE/2 , dword 1, dword 1
.Done
ret

;--------------------------------------------------
;-- boolean _PlayBGM(int FileOff, int filesize) ---
;--------------------------------------------------
; inputs: FileOff- offset of the background music to play
; outputs: sound played
; returns; 1 if error, 0 otherwise
; calls: _DMA_Start, _DMA_Stop, _DMA_Lock_Mem, _SB16Init, _SB16_GetChannel, 
;        _SB16_SetFormat, _SB16_SetMixers, _SB16_Start,
; -plays background music
proc _PlayBGM
.FileOff	arg	4
.filesize arg 4
	push	edi                           ;set position markers amd offsets
	mov	dword [NextPos], SIZE             ;
	mov	eax, [.FileOff + ebp]             ;
	mov	[BGMOff], eax                     ;
	mov	[BGMPos], eax                     ;
	add	dword [BGMPos], SIZE              ;
	mov	eax, [.filesize + ebp]
	mov	[BGMSize], eax
	mov	byte [_DMA_Refill_Flag], 00h       
	mov	es, [DMASel]                      ;fill entire buffer to start
	mov	ecx, SIZE/4                       ;
	mov	edi, 0                            ;
	mov	esi, [.FileOff+ ebp]              ;
	rep	movsd
	
	invoke	_SB16_Init, dword _SoundISR     
	test	eax, eax
	jnz	near .error
	
	invoke	_SB16_GetChannel
	mov	[DMAChan], al
	
	invoke	_SB16_SetFormat, dword 8, dword 22050, dword 0 
	test	eax, eax
	jnz	near .error

	invoke	_SB16_SetMixers, word 07fh, word 07fh, word 07fh, word 07fh
	test	eax, eax 
	jnz	near .error

	movzx	eax, byte [DMAChan]
	invoke	_DMA_Start, eax, dword [DMAAddr], dword SIZE, dword 1, dword 1
	invoke	_SB16_Start, dword SIZE/2, dword 1, dword 1  
	test	eax, eax
	jnz	near .error
	
	mov		eax, 0
	pop		esi
	pop		edi	
	ret
.error
	mov	eax, 1
	pop		esi
	pop		edi	
	ret
endproc

;-----------------------------------------
;-- boolean _StopBGM() -------------------
; Inputs: none
; Outputs: Stops BGM
; Returns: 1 if error, 0 otherwise
; -Stops the background music
_StopBGM
	invoke	_SB16_Start, dword SIZE/4, dword 0, dword 1
	test	eax, eax
	jnz	near .error

	movzx	eax, byte [DMAChan]
	invoke	_DMA_Stop, eax

	invoke	_SB16_Stop

	invoke	_SB16_SetMixers, word 0, word 0, word 0, word 0
	test	eax, eax
	jnz	near .error

	invoke	_SB16_Exit
	test	eax, eax
	jnz	near .error
	ret
	
.error
	mov	eax, 1
	ret
_PlayBGM_arglen	equ	8


;--------------------------------------------------
;--boolean _PlaySFX(int fileOff2, int filesize2) --
;--------------------------------------------------
; inputs: fileOff2 - offset of the sound effect to play, size of the sound clip
; outputs: sound played
; returns; 1 if error, 0 otherwise
; calls: _DMA_Allocate_Mem, _DMA_Start, _DMA_Stop, _DMA_Lock_Mem, _SB16Init, _SB16_GetChannel, 
;       _SB16_SetFormat, _SB16_SetMixers, _SB16_Start, _SB16_Stop, _SB16_Exit,
;       _LibInit, _LibExit
; -plays sound effects by setting the mix flag so DMA_Refill can mix
;  and foreground sound.
proc _PlaySFX
.fileOff2	arg	4
.filesize2	arg 4	
	mov	eax, [.fileOff2 + ebp]
	mov	[SFXOff], eax
	mov	[SFXPos], eax
	mov eax, [.filesize2 + ebp]
	mov	[SFXSize], eax
	mov	ebx, SIZE/2
	mov	edx, 0
	div	ebx
	mov	dword [MixCycle], eax
	;mov	dword [RemCycle], edx
	mov	byte [_DMA_Mix], 01h
	ret
endproc
_PlaySFX_arglen	equ	8


;-------------------------
;-- dword _InstallTmr() --
;-------------------------
; Inputs : -
; Outputs : -
; Returns : 1 if error; 0 otherwise
; Calls : _LockArea
; - Installs Timer ISR
_InstallTmr

	invoke	_LockArea, ds, dword _TimeTick, 2
	invoke	_LockArea, ds, dword _AnimateTick, 1
	invoke	_LockArea, ds, dword _CBallTick, 1
	mov	eax, _TmrISR_end
	sub	eax, _TmrISR
	invoke	_LockArea, cs, dword _TmrISR, eax

	invoke	_Install_Int, dword TIMER_INT, dword _TmrISR
	test	eax, eax
	jz	.done
	mov	eax, 1

.done
	ret


;-----------------------
;-- void _RemoveTmr() --
;-----------------------
; Inputs : -
; Outputs : -
; Returns : -
; Calls : -
; - Uninstalls Timer ISR
_RemoveTmr

	invoke	_Remove_Int, dword TIMER_INT
	ret


;--------------------
;-- void _TmrISR() --
;--------------------
; Inputs : -
; Outputs : [_TimeTick] - interrupt counter for controlling phase duration
;           [_AnimateTick] - counter for animation
;           [_CBallTick] - counter for updating cannon ball array
; Returns : -
; Calls : -
; - Increments [_TickCount]
_TmrISR

	inc	word [_TimeTick]
	inc	byte [_AnimateTick]
	inc	byte [_CBallTick]
	xor	eax, eax
	ret
_TmrISR_end


;-------------------------
;-- dword _InstallKbd() --
;-------------------------
; Inputs : -
; Outputs : -
; Returns : 1 if error; 0 otherwise
; Calls : _LockArea
; - Installs keyboard ISR
_InstallKbd

	invoke	_LockArea, ds, dword _kbINT, dword 1	;
	invoke	_LockArea, ds, dword _kbIRQ, dword 1	;
	invoke	_LockArea, ds, dword _kbPort, dword 2	;
	mov	eax, _KbdISR_end			;
	sub	eax, _KbdISR				;
	invoke	_LockArea, cs, dword _KbdISR, eax	; lock variables and handler

	movzx	eax, byte [_kbINT]
	invoke	_Install_Int, eax, dword _KbdISR
	test	eax, eax	; check for error
	jz	.done
	mov	eax, 1

.done
	ret


;-----------------------
;-- void _RemoveKbd() --
;-----------------------
; Inputs : -
; Outputs : -
; Returns : -
; Calls : -
; - Uninstalls keyboard ISR
_RemoveKbd

	movzx	eax, byte [_kbINT]
	invoke	_Remove_Int, eax
	ret


;--------------------
;-- void _KbdISR() --
;--------------------
; Inputs : key presses waiting at port [_kbPort], [_kbIRQ]
; Outputs : [_P1InputFlags], [_P2InputFlags], [_Flags]
; Returns : -
; Calls : -
; - Handles keyboard input
_KbdISR

	mov	dx, [_kbPort]
	in	al, dx
	cmp	al, ESC				; see if ESC was pressed
	je	near .escape
	test	al, 10000000b			; test whether it's a press or a release
	jz	near .keyPressed

.keyReleased
	and	al, 01111111b			; set MSB to 0

	cmp	al, [_P1_Up_Key]		;
	je	near .P1UpReleased		;
	cmp	al, [_P1_Down_Key]		;
	je	near .P1DownReleased		;
	cmp	al, [_P1_Left_Key]		;
	je	near .P1LeftReleased		;
	cmp	al, [_P1_Right_Key]		;
	je	near .P1RightReleased		;
	cmp	al, [_P1_Primary_Key]		;
	je	near .P1PrimaryReleased		;
	cmp	al, [_P1_Secondary_Key]		;
	je	near .P1SecondaryReleased	; check for P1 key release

	cmp	al, [_P2_Up_Key]		;
	je	near .P2UpReleased		;
	cmp	al, [_P2_Down_Key]		;
	je	near .P2DownReleased		;
	cmp	al, [_P2_Left_Key]		;
	je	near .P2LeftReleased		;
	cmp	al, [_P2_Right_Key]		;
	je	near .P2RightReleased		;
	cmp	al, [_P2_Primary_Key]		;
	je	near .P2PrimaryReleased		;
	cmp	al, [_P2_Secondary_Key]		;
	je	near .P2SecondaryReleased	; check for P2 key release

.keyPressed
	cmp	al, [_P1_Up_Key]		;
	je	near .P1UpPressed		;
	cmp	al, [_P1_Down_Key]		;
	je	near .P1DownPressed		;
	cmp	al, [_P1_Left_Key]		;
	je	near .P1LeftPressed		;
	cmp	al, [_P1_Right_Key]		;
	je	near .P1RightPressed		;
	cmp	al, [_P1_Primary_Key]		;
	je	near .P1PrimaryPressed		;
	cmp	al, [_P1_Secondary_Key]		;
	je	near .P1SecondaryPressed	; check for P1 key release

	cmp	al, [_P2_Up_Key]		;
	je	near .P2UpPressed		;
	cmp	al, [_P2_Down_Key]		;
	je	near .P2DownPressed		;
	cmp	al, [_P2_Left_Key]		;
	je	near .P2LeftPressed		;
	cmp	al, [_P2_Right_Key]		;
	je	near .P2RightPressed		;
	cmp	al, [_P2_Primary_Key]		;
	je	near .P2PrimaryPressed		;
	cmp	al, [_P2_Secondary_Key]		;
	je	near .P2SecondaryPressed	; check for P2 key release

.P1UpReleased
	and	byte [_P1_InputFlags], ~UP_FLAG
	jmp	near .ack

.P1DownReleased
	and	byte [_P1_InputFlags], ~DOWN_FLAG
	jmp	near .ack

.P1LeftReleased
	and	byte [_P1_InputFlags], ~LEFT_FLAG
	jmp	near .ack

.P1RightReleased
	and	byte [_P1_InputFlags], ~RIGHT_FLAG
	jmp	near .ack

.P1PrimaryReleased
	and	byte [_P1_InputFlags], ~PRIMARY_FLAG
	jmp	near .ack

.P1SecondaryReleased
	and	byte [_P1_InputFlags], ~SECONDARY_FLAG
	jmp	near .ack

.P2UpReleased
	and	byte [_P2_InputFlags], ~UP_FLAG
	jmp	near .ack

.P2DownReleased
	and	byte [_P2_InputFlags], ~DOWN_FLAG
	jmp	near .ack

.P2LeftReleased
	and	byte [_P2_InputFlags], ~LEFT_FLAG
	jmp	near .ack

.P2RightReleased
	and	byte [_P2_InputFlags], ~RIGHT_FLAG
	jmp	near .ack

.P2PrimaryReleased
	and	byte [_P2_InputFlags], ~PRIMARY_FLAG
	jmp	near .ack

.P2SecondaryReleased
	and	byte [_P2_InputFlags], ~SECONDARY_FLAG
	jmp	near .ack


.P1UpPressed
	or	byte [_P1_InputFlags], UP_FLAG
	jmp	near .ack

.P1DownPressed
	or	byte [_P1_InputFlags], DOWN_FLAG
	jmp	near .ack

.P1LeftPressed
	or	byte [_P1_InputFlags], LEFT_FLAG
	jmp	near .ack

.P1RightPressed
	or	byte [_P1_InputFlags], RIGHT_FLAG
	jmp	near .ack

.P1PrimaryPressed
	or	byte [_P1_InputFlags], PRIMARY_FLAG
	jmp	near .ack

.P1SecondaryPressed
	or	byte [_P1_InputFlags], SECONDARY_FLAG
	jmp	near .ack

.P2UpPressed
	or	byte [_P2_InputFlags], UP_FLAG
	jmp	near .ack

.P2DownPressed
	or	byte [_P2_InputFlags], DOWN_FLAG
	jmp	near .ack

.P2LeftPressed
	or	byte [_P2_InputFlags], LEFT_FLAG
	jmp	near .ack

.P2RightPressed
	or	byte [_P2_InputFlags], RIGHT_FLAG
	jmp	near .ack

.P2PrimaryPressed
	or	byte [_P2_InputFlags], PRIMARY_FLAG
	jmp	near .ack

.P2SecondaryPressed
	or	byte [_P2_InputFlags], SECONDARY_FLAG
	jmp	near .ack

.escape	
	or	byte[_Flags], EXIT_FLAG

.ack 	
	in	al, 61h
	or	al, 10000000b
	out	61h, al
	and	al, 01111111b
	out	61h, al
	mov	al, 20h
	out	20h, al
	cmp	byte [_kbIRQ], 8		; ACK with slave pic for [_kbIRQ] >= 8
	jb	.done
	out	0A0h, al
	xor	eax, eax			; do not chain to old int

.done
	ret
_KbdISR_end

