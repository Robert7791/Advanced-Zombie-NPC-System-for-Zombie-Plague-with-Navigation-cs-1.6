/* UTF-8 func by www.DT-Club.net */

#include <amxmodx>
#include <fakemeta>

#define dPluginName			"NavigationSystem"
#define dPluginVersion			"20211117"
#define dPluginAuthor			"251020worm"
#define dPluginLastChangeTime		"20220410143300"

new gMdlId_BeamNode, gMdlId_BeamPath1, gMdlId_BeamPath2

new Array:gArray_SpawnPos, Array:gArray_Ladder, Array:gArray_TraceIgnoreEnt

new gForward_ReturnValue
new gForward_NodeLoading, gForward_NodeLoaded
new gForward_NodeSaving, gForward_NodeSaved

new gBeamCount[33]
new Float:gTimer_Update

#include "NavSys_Node.sma"
#include "NavSys_Box.sma"
#include "NavSys_Menu.sma"

public plugin_precache()
{
	gMdlId_BeamNode		= precache_model("sprites/white.spr")
	gMdlId_BeamPath1	= precache_model("sprites/arrow1.spr")
	gMdlId_BeamPath2	= precache_model("sprites/shellchrome.spr")
	
	gArray_SpawnPos		= ArrayCreate(6)
	gArray_Ladder		= ArrayCreate()
	gArray_TraceIgnoreEnt	= ArrayCreate(2)
	
	gArray_NodeDucking	= ArrayCreate()
	gArray_NodePoint	= ArrayCreate(3)
	gArray_NodeAbsMin	= ArrayCreate(3)
	gArray_NodeAbsMax	= ArrayCreate(3)
	gArray_NodeNormal	= ArrayCreate(3)
	gArray_NodeStart	= ArrayCreate()
	gArray_NodeEnd		= ArrayCreate()
	gArray_NodeFlags	= ArrayCreate()
	gArray_NodeHeight	= ArrayCreate()
	gArray_NodeDistance	= ArrayCreate()
	
	gMenuId_Main = gMenuId_Create = gMenuId_Edit = gMenuId_Test = -1
	
	register_forward(FM_Spawn, "fw_Spawn_Post", 1)
}

public fw_Spawn_Post(ent)
{
	if (!pev_valid(ent)) return
	
	new className[32]
	pev(ent, pev_classname, className, 31)
	
	if (equal(className, "info_vip_start"))		{ NavSys_AddSpawnPos(ent); return; }
	if (equal(className, "info_player_start"))	{ NavSys_AddSpawnPos(ent); return; }
	if (equal(className, "info_player_deathmatch"))	{ NavSys_AddSpawnPos(ent); return; }
	
	if (equal(className, "func_ladder")) ArrayPushCell(gArray_Ladder, ent)
	else if (equal(className, "func_breakable"))
	{
		new Float:takeDamage
		pev(ent, pev_takedamage, takeDamage)
		if (takeDamage == DAMAGE_NO) return
		
		new param[2]
		param[0] = ent
		param[1] = pev(ent, pev_solid)
		ArrayPushArray(gArray_TraceIgnoreEnt, param)
	}
	else if (contain(className, "func_door") == -1)
	{
		if (pev(ent, pev_spawnflags) == SF_DOOR_USE_ONLY) return
		
		new param[2]
		param[0] = ent
		param[1] = pev(ent, pev_solid)
		ArrayPushArray(gArray_TraceIgnoreEnt, param)
	}
}

NavSys_AddSpawnPos(ent)
{
	new Float:vecSrc[3], Float:vecDest[3]
	pev(ent, pev_origin, vecSrc)
	vecDest[0] = vecSrc[0]
	vecDest[1] = vecSrc[1]
	vecDest[2] = vecSrc[2] - 9999.0
	NavSys_Trace(vecSrc, vecDest, HULL_HUMAN)
	
	new Float:vecEndPos[3], Float:vecPlaneNormal[3]
	get_tr2(0, TR_vecEndPos, vecEndPos)
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
	
	new Float:spawnPos[6]
	spawnPos[0] = vecEndPos[0]
	spawnPos[1] = vecEndPos[1]
	spawnPos[2] = vecEndPos[2]
	spawnPos[3] = vecPlaneNormal[0]
	spawnPos[4] = vecPlaneNormal[1]
	spawnPos[5] = vecPlaneNormal[2]
	ArrayPushArray(gArray_SpawnPos, spawnPos)
}

public plugin_init()
{
	register_plugin(dPluginName, dPluginVersion, dPluginAuthor)
	
	register_dictionary("NavigationSystem.txt")
	
	register_clcmd("nsmenu", "clcmd_NSMenu")
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	gForward_NodeLoading = CreateMultiForward("NavSys_NodeLoading", ET_STOP, FP_CELL)
	gForward_NodeLoaded = CreateMultiForward("NavSys_NodeLoaded", ET_STOP, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL)
	gForward_NodeSaving = CreateMultiForward("NavSys_NodeSaving", ET_STOP, FP_CELL)
	gForward_NodeSaved = CreateMultiForward("NavSys_NodeSaved", ET_STOP, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL)
	
	if (!NavSys_LoadFile(0))
	{
		NavNode_AutoCreating()
		NavNode_AutoMerging(false)
		NavBox_Update()
		NavSys_SaveFile(0)
	}
}

public clcmd_NSMenu(id)
{
	if (id != 1) return PLUGIN_CONTINUE
	
	NavSys_EditMode(id)
	return PLUGIN_HANDLED
}

NavSys_EditMode(id)
{
	if (gMenuId_Main < 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "EDIT_MODE_ON")
		
		NavSysMenu_Init()
	}
	
	menu_display(id, gMenuId_Main)
}

public fw_PlayerPreThink(id)
{
	if (id != 1) return
	if (gMenuId_Main < 0) return
	if (!is_user_alive(id)) return
	
	gBeamCount[id] = 0
	
	new Float:gameTime = get_gametime()
	if (gTimer_Update < gameTime)
	{
		gTimer_Update = gameTime + 0.08
		
		gNodeId_Aiming = NavBox_GetNodeInFront(id)
		
		new nodeId, bool:drawnAiming
		new Array:arrayEnd, Array:arrayPath = ArrayCreate()
		
		if (0 <= gNodeId_Aiming)
		{
			arrayEnd = ArrayGetCell(gArray_NodeEnd, gNodeId_Aiming)
			for (new i = ArraySize(arrayEnd) - 1; 0 <= i; i--) ArrayPushCell(arrayPath, ArrayGetCell(arrayEnd, i))
		}
		
		for (new i = ArraySize(gArray_Selected) - 1; 0 <=i; i--)
		{
			nodeId = ArrayGetCell(gArray_Selected, i)
			
			if (nodeId == gNodeId_Aiming)
			{
				drawnAiming = true
				NavNode_DrawMesh(id, gNodeId_Aiming, true, 1, 10, 0, 255, 255, 255)
				continue
			}
			
			NavNode_DrawMesh(id, nodeId, false, 1, 10, 0, 255, 255, 255)
			
			for (new j = ArraySize(arrayPath) - 1; 0 <= j; j--)
			{
				if (ArrayGetCell(arrayPath, j) == nodeId)
				{
					ArrayDeleteItem(arrayPath, j)
					break
				}
			}
		}
		
		if (0 <= gNodeId_Aiming && !drawnAiming) NavNode_DrawMesh(id, gNodeId_Aiming, true, 1, 10, 0, 255, 255, 0)
		for (new i = ArraySize(arrayPath) - 1; 0 <= i; i--) NavNode_DrawMesh(id, ArrayGetCell(arrayPath, i), false, 1, 10, 0, 255, 0, 0)
		
		ArrayDestroy(arrayPath)
	}
	
	new button = pev(id, pev_button)
	new oldButtons = pev(id, pev_oldbuttons)
	
	if ( (button & IN_ATTACK) && !(oldButtons & IN_ATTACK) )
	{
		if (gNodeId_Aiming < 0)	NavSysMenu_CreateNodeInFront(id)
		else			NavSysMenu_Selects(id)
	}
	else if ( (button & IN_ATTACK2) && !(oldButtons & IN_ATTACK2) )
	{
		if (gNodeId_Aiming < 0)	menu_display(id, gMenuId_Main)
		else			menu_display(id, gMenuId_Edit)
	}
}

NavSys_SaveFile(id)
{
	ExecuteForward(gForward_NodeSaving, gForward_ReturnValue, id)
	
	new nodeNums = ArraySize(gArray_NodeDucking)
	if (!nodeNums)
	{
		if (id)	client_print(id, print_chat, "%L", LANG_SERVER, "NODE_NOT_FOUND")
		else	server_print("%L", LANG_SERVER, "NODE_NOT_FOUND")
		
		ExecuteForward(gForward_NodeSaved, gForward_ReturnValue, id,
		gArray_NodeDucking, gArray_NodePoint, gArray_NodeAbsMin, gArray_NodeAbsMax, gArray_NodeNormal,
		gArray_NodeStart, gArray_NodeEnd, gArray_NodeFlags, gArray_NodeHeight, gArray_NodeDistance)
		
		return false
	}
	
	new filePath[128]
	get_localinfo("amxx_datadir", filePath, 127)
	format(filePath, 127, "%s/NavigationSystem", filePath)
	if (!dir_exists(filePath)) mkdir(filePath)
	
	new mapName[32]
	get_mapname(mapName, 31)
	format(filePath, 127, "%s/%s.navsys", filePath, mapName)
	
	new fileHandle = fopen(filePath, "wb")
	if (!fileHandle)
	{
		if (id)	client_print(id, print_chat, "%L", LANG_SERVER, "NAV_SAVE_ERROR")
		else	server_print("%L", LANG_SERVER, "NAV_SAVE_ERROR")
		
		ExecuteForward(gForward_NodeSaved, gForward_ReturnValue, id,
		gArray_NodeDucking, gArray_NodePoint, gArray_NodeAbsMin, gArray_NodeAbsMax, gArray_NodeNormal,
		gArray_NodeStart, gArray_NodeEnd, gArray_NodeFlags, gArray_NodeHeight, gArray_NodeDistance)
		
		return false
	}
	
	fwrite(fileHandle, get_systime(), BLOCK_INT)
	
	new iNode
	new coord[3]
	new Array:arrayStart, Array:arrayEnd, Array:arrayFlags, Array:arrayHeight, Array:arrayDistance
	new iPath, pathNums
	
	for (iNode = 0; iNode < nodeNums; iNode++)
	{
		fwrite(fileHandle, ArrayGetCell(gArray_NodeDucking, iNode), BLOCK_BYTE)
		
		ArrayGetArray(gArray_NodePoint, iNode, coord)
		fwrite_blocks(fileHandle, coord, 3, BLOCK_INT)
		
		ArrayGetArray(gArray_NodeAbsMin, iNode, coord)
		fwrite_blocks(fileHandle, coord, 3, BLOCK_INT)
		
		ArrayGetArray(gArray_NodeAbsMax, iNode, coord)
		fwrite_blocks(fileHandle, coord, 3, BLOCK_INT)
		
		ArrayGetArray(gArray_NodeNormal, iNode, coord)
		fwrite_blocks(fileHandle, coord, 3, BLOCK_INT)
		
		arrayStart	= ArrayGetCell(gArray_NodeStart,	iNode)
		arrayEnd	= ArrayGetCell(gArray_NodeEnd,		iNode)
		arrayFlags	= ArrayGetCell(gArray_NodeFlags,	iNode)
		arrayHeight	= ArrayGetCell(gArray_NodeHeight,	iNode)
		arrayDistance	= ArrayGetCell(gArray_NodeDistance,	iNode)
		
		pathNums = ArraySize(arrayStart)
		fwrite(fileHandle, pathNums, BLOCK_INT)
		
		for (iPath = 0; iPath < pathNums; iPath++)
		{
			fwrite(fileHandle, ArrayGetCell(arrayStart,	iPath), BLOCK_INT)
		}
		
		pathNums = ArraySize(arrayEnd)
		fwrite(fileHandle, pathNums, BLOCK_INT)
		
		for (iPath = 0; iPath < pathNums; iPath++)
		{
			fwrite(fileHandle, ArrayGetCell(arrayEnd,	iPath), BLOCK_INT)
			fwrite(fileHandle, ArrayGetCell(arrayFlags,	iPath), BLOCK_BYTE)
			fwrite(fileHandle, ArrayGetCell(arrayHeight,	iPath), BLOCK_INT)
			fwrite(fileHandle, ArrayGetCell(arrayDistance,	iPath), BLOCK_INT)
		}
	}
	
	fclose(fileHandle)
	
	if (id)	client_print(id, print_chat, "%L", LANG_SERVER, "NAV_SAVED", nodeNums)
	else	server_print("%L", LANG_SERVER, "NAV_SAVED", nodeNums)
	
	ExecuteForward(gForward_NodeSaved, gForward_ReturnValue, id,
	gArray_NodeDucking, gArray_NodePoint, gArray_NodeAbsMin, gArray_NodeAbsMax, gArray_NodeNormal,
	gArray_NodeStart, gArray_NodeEnd, gArray_NodeFlags, gArray_NodeHeight, gArray_NodeDistance)
	
	return true
}

NavSys_LoadFile(id)
{
	ExecuteForward(gForward_NodeLoading, gForward_ReturnValue, id)
	
	new filePath[128]
	get_localinfo("amxx_datadir", filePath, 127)
	format(filePath, 127, "%s/NavigationSystem", filePath)
	if (!dir_exists(filePath))
	{
		if (id)	client_print(id, print_chat, "%L", LANG_SERVER, "NAV_FILE_NOT_FOUND")
		else	server_print("%L", LANG_SERVER, "NAV_FILE_NOT_FOUND")
		
		ExecuteForward(gForward_NodeLoaded, gForward_ReturnValue, id,
		gArray_NodeDucking, gArray_NodePoint, gArray_NodeAbsMin, gArray_NodeAbsMax, gArray_NodeNormal,
		gArray_NodeStart, gArray_NodeEnd, gArray_NodeFlags, gArray_NodeHeight, gArray_NodeDistance)
		
		return false
	}
	
	new mapName[32]
	get_mapname(mapName, 31)
	format(filePath, 127, "%s/%s.navsys", filePath, mapName)
	
	new fileHandle = fopen(filePath, "rb")
	if (!fileHandle)
	{
		if (id)	client_print(id, print_chat, "%L", LANG_SERVER, "NAV_LOAD_ERROR")
		else	server_print("%L", LANG_SERVER, "NAV_LOAD_ERROR")
		
		ExecuteForward(gForward_NodeLoaded, gForward_ReturnValue, id,
		gArray_NodeDucking, gArray_NodePoint, gArray_NodeAbsMin, gArray_NodeAbsMax, gArray_NodeNormal,
		gArray_NodeStart, gArray_NodeEnd, gArray_NodeFlags, gArray_NodeHeight, gArray_NodeDistance)
		
		return false
	}
	
	new nodeNums = ArraySize(gArray_NodeDucking)
	if (nodeNums) NavNode_Clear()
	
	new iNode
	new Array:arrayStart, Array:arrayEnd, Array:arrayFlags, Array:arrayHeight, Array:arrayDistance
	
	new fileSize = file_size(filePath)
	
	new warning, bool:error
	new value, coord[3]
	new iPath, pathNums
	
	if (fileSize < 4) { error = true; goto LoopEnd; }
	fread(fileHandle, value, BLOCK_INT)
	if (value <= parse_time(dPluginLastChangeTime, "%Y%m%d%H%M%S")) { error = true; goto LoopEnd; }
	
	LoopStart:
	
	if (fileSize - ftell(fileHandle) < 1) { error = true; goto LoopEnd; }
	fread(fileHandle, value, BLOCK_BYTE)
	ArrayPushCell(gArray_NodeDucking, value)
	
	if (fileSize - ftell(fileHandle) < 12) { error = true; goto LoopEnd; }
	fread_blocks(fileHandle, coord, 3, BLOCK_INT)
	ArrayPushArray(gArray_NodePoint, coord)
	
	if (fileSize - ftell(fileHandle) < 12) { error = true; goto LoopEnd; }
	fread_blocks(fileHandle, coord, 3, BLOCK_INT)
	ArrayPushArray(gArray_NodeAbsMin, coord)
	
	if (fileSize - ftell(fileHandle) < 12) { error = true; goto LoopEnd; }
	fread_blocks(fileHandle, coord, 3, BLOCK_INT)
	ArrayPushArray(gArray_NodeAbsMax, coord)
	
	if (fileSize - ftell(fileHandle) < 12) { error = true; goto LoopEnd; }
	fread_blocks(fileHandle, coord, 3, BLOCK_INT)
	ArrayPushArray(gArray_NodeNormal, coord)
	
	arrayStart	= ArrayCreate()
	arrayEnd	= ArrayCreate()
	arrayFlags	= ArrayCreate()
	arrayHeight	= ArrayCreate()
	arrayDistance	= ArrayCreate()
	ArrayPushCell(gArray_NodeStart,		arrayStart)
	ArrayPushCell(gArray_NodeEnd,		arrayEnd)
	ArrayPushCell(gArray_NodeFlags,		arrayFlags)
	ArrayPushCell(gArray_NodeHeight,	arrayHeight)
	ArrayPushCell(gArray_NodeDistance,	arrayDistance)
	
	if (fileSize - ftell(fileHandle) < 4) { error = true; goto LoopEnd; }
	fread(fileHandle, pathNums, BLOCK_INT)
	
	for (iPath = 0; iPath < pathNums; iPath++)
	{
		if (fileSize - ftell(fileHandle) < 4) { error = true; goto LoopEnd; }
		fread(fileHandle, value, BLOCK_INT)
		ArrayPushCell(arrayStart, value)
	}
	
	if (fileSize - ftell(fileHandle) < 4) { error = true; goto LoopEnd; }
	fread(fileHandle, pathNums, BLOCK_INT)
	
	for (iPath = 0; iPath < pathNums; iPath++)
	{
		if (fileSize - ftell(fileHandle) < 4) { error = true; goto LoopEnd; }
		fread(fileHandle, value, BLOCK_INT)
		ArrayPushCell(arrayEnd, value)
		
		if (fileSize - ftell(fileHandle) < 1) { error = true; goto LoopEnd; }
		fread(fileHandle, value, BLOCK_BYTE)
		ArrayPushCell(arrayFlags, value)
		
		if (fileSize - ftell(fileHandle) < 4) { error = true; goto LoopEnd; }
		fread(fileHandle, value, BLOCK_INT)
		ArrayPushCell(arrayHeight, value)
		
		if (fileSize - ftell(fileHandle) < 4) { error = true; goto LoopEnd; }
		fread(fileHandle, value, BLOCK_INT)
		ArrayPushCell(arrayDistance, value)
	}
	
	if (fileSize - ftell(fileHandle) < 61)	goto LoopEnd
	else					goto LoopStart
	
	LoopEnd:
	
	warning = fileSize - ftell(fileHandle)
	fclose(fileHandle)
	
	if (error)
	{
		nodeNums = ArraySize(gArray_NodeStart)
		for (iNode = 0; iNode < nodeNums; iNode++)
		{
			arrayStart = ArrayGetCell(gArray_NodeStart, iNode)
			ArrayDestroy(arrayStart)
		}
		nodeNums = ArraySize(gArray_NodeEnd)
		for (iNode = 0; iNode < nodeNums; iNode++)
		{
			arrayEnd	= ArrayGetCell(gArray_NodeEnd,		iNode)
			arrayFlags	= ArrayGetCell(gArray_NodeFlags,	iNode)
			arrayHeight	= ArrayGetCell(gArray_NodeHeight,	iNode)
			arrayDistance	= ArrayGetCell(gArray_NodeDistance,	iNode)
			ArrayDestroy(arrayEnd)
			ArrayDestroy(arrayFlags)
			ArrayDestroy(arrayHeight)
			ArrayDestroy(arrayDistance)
		}
		
		ArrayClear(gArray_NodeDucking)
		ArrayClear(gArray_NodePoint)
		ArrayClear(gArray_NodeAbsMin)
		ArrayClear(gArray_NodeAbsMax)
		ArrayClear(gArray_NodeNormal)
		ArrayClear(gArray_NodeStart)
		ArrayClear(gArray_NodeEnd)
		ArrayClear(gArray_NodeFlags)
		ArrayClear(gArray_NodeHeight)
		ArrayClear(gArray_NodeDistance)
		
		NavBox_Update()
		
		if (id)	client_print(id, print_chat, "%L", LANG_SERVER, "NAV_LOAD_ERROR2")
		else	server_print("%L", LANG_SERVER, "NAV_LOAD_ERROR2")
		
		ExecuteForward(gForward_NodeLoaded, gForward_ReturnValue, id,
		gArray_NodeDucking, gArray_NodePoint, gArray_NodeAbsMin, gArray_NodeAbsMax, gArray_NodeNormal,
		gArray_NodeStart, gArray_NodeEnd, gArray_NodeFlags, gArray_NodeHeight, gArray_NodeDistance)
		
		return false
	}
	
	NavBox_Update()
	
	if (id)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "NAV_LOADED", ArraySize(gArray_NodeDucking))
		if (warning) client_print(id, print_chat, "%L", LANG_SERVER, "NAV_WARNING", warning)
	}
	else
	{
		server_print("%L", LANG_SERVER, "NAV_LOADED", ArraySize(gArray_NodeDucking))
		if (warning) server_print("%L", LANG_SERVER, "NAV_WARNING", warning)
	}
	
	ExecuteForward(gForward_NodeLoaded, gForward_ReturnValue, id,
	gArray_NodeDucking, gArray_NodePoint, gArray_NodeAbsMin, gArray_NodeAbsMax, gArray_NodeNormal,
	gArray_NodeStart, gArray_NodeEnd, gArray_NodeFlags, gArray_NodeHeight, gArray_NodeDistance)
	
	return true
}

NavSys_DeleteFile(id)
{
	new filePath[128]
	get_localinfo("amxx_datadir", filePath, 127)
	format(filePath, 127, "%s/NavigationSystem", filePath)
	if (dir_exists(filePath))
	{
		new mapName[32]
		get_mapname(mapName, 31)
		format(filePath, 127, "%s/%s.navsys", filePath, mapName)
		if (file_exists(filePath)) delete_file(filePath)
	}
	
	NavNode_Clear()
	NavBox_Update()
	
	if (id)	client_print(id, print_chat, "%L", LANG_SERVER, "NAV_DELETED")
	else	server_print("%L", LANG_SERVER, "NAV_DELETED")
}

NavSys_Trace(const Float:vecSrc[3], const Float:vecDest[3], hull)
{
	new i, param[2]
	for (i = ArraySize(gArray_Ladder) - 1; 0 <= i; i--) set_pev(ArrayGetCell(gArray_Ladder, i), pev_solid, SOLID_BSP)
	for (i = ArraySize(gArray_TraceIgnoreEnt) - 1; 0 <= i; i--)
	{
		ArrayGetArray(gArray_TraceIgnoreEnt, i, param)
		param[1] = pev(param[0], pev_solid)
		set_pev(param[0], pev_solid, SOLID_NOT)
		ArraySetArray(gArray_TraceIgnoreEnt, i, param)
	}
	
	if (hull < 0)	engfunc(EngFunc_TraceLine, vecSrc, vecDest, dTraceIgnore, -1, 0)
	else		engfunc(EngFunc_TraceHull, vecSrc, vecDest, dTraceIgnore, hull, -1, 0)
	
	for (i = ArraySize(gArray_Ladder) - 1; 0 <= i; i--) set_pev(ArrayGetCell(gArray_Ladder, i), pev_solid, SOLID_NOT)
	for (i = ArraySize(gArray_TraceIgnoreEnt) - 1; 0 <= i; i--)
	{
		ArrayGetArray(gArray_TraceIgnoreEnt, i, param)
		set_pev(param[0], pev_solid, param[1])
	}
}

bool:NavSys_IsVacantSpace(const Float:origin[3], hull)
{
	NavSys_Trace(origin, origin, hull)
	
	if (!get_tr2(0, TR_InOpen) || get_tr2(0, TR_AllSolid) || get_tr2(0, TR_StartSolid)) return false
	
	return true
}

stock AngleVector(const Float:angles[3], dirt, Float:vector[3])
{
	new Float:cp, Float:cy, Float:sy, Float:sp
	cp = floatcos(M_PI * angles[0] / 180.0)
	cy = floatcos(M_PI * angles[1] / 180.0)
	sy = floatsin(M_PI * angles[1] / 180.0)
	sp = floatsin(M_PI * angles[0] / 180.0)
	if (dirt == ANGLEVECTOR_FORWARD)
	{
		vector[0] = cp * cy
		vector[1] = cp * sy
		vector[2] = -sp
	}
	if (dirt == ANGLEVECTOR_RIGHT)
	{
		new Float:sr, Float:cr
		sr = floatsin(M_PI * angles[2] / 180.0)
		cr = floatcos(M_PI * angles[2] / 180.0)
		vector[0] = (-1.0 * sr * sp * cy + -1.0 * cr * -sy)
		vector[1] = (-1.0 * sr * sp * sy + -1.0 * cr * cy)
		vector[2] = -1.0 * sr * cp
	}
	if (dirt == ANGLEVECTOR_UP)
	{
		new Float:sr, Float:cr
		sr = floatsin(M_PI * angles[2] / 180.0)
		cr = floatcos(M_PI * angles[2] / 180.0)
		vector[0] = (cr * sp * cy + -sr * -sy)
		vector[1] = (cr * sp * sy + -sr * cy)
		vector[2] = cr * cp
	}
}
stock VectorAngle(const Float:vector[3], Float:angles[3])
{
	if (vector[1] == 0.0 && vector[0] == 0.0)
        {
		angles[0] = vector[2] > 0.0 ? 90.0 : 270.0
		angles[1] = 0.0
		angles[2] = 0.0
		return
	}
	new Float:yaw, Float:pitch, Float:tmp
	yaw = floatatan2(vector[1], vector[0], degrees)
	if (yaw < 0.0) yaw += 360
	
	tmp = floatsqroot(vector[0] * vector[0] + vector[1] * vector[1])
	pitch = floatatan2(vector[2], tmp, degrees)
	if (pitch < 0.0) pitch += 360
	
	angles[0] = pitch
	angles[1] = yaw
	angles[2] = 0.0
}
stock bool:VecEqual(const Float:vec1[], const Float:vec2[])
{
	return vec1[0] == vec2[0] && vec1[1] == vec2[1] && vec1[2] == vec2[2]
}
stock VecAdd(const Float:vec1[], const Float:vec2[], Float:vecOut[])
{
	vecOut[0] = vec1[0] + vec2[0]
	vecOut[1] = vec1[1] + vec2[1]
	vecOut[2] = vec1[2] + vec2[2]
}
stock VecSub(const Float:vec1[], const Float:vec2[], Float:vecOut[])
{
	vecOut[0] = vec1[0] - vec2[0]
	vecOut[1] = vec1[1] - vec2[1]
	vecOut[2] = vec1[2] - vec2[2]
}
stock VecMulScalar(const Float:vec[], Float:scalar, Float:vecOut[])
{
	vecOut[0] = vec[0] * scalar
	vecOut[1] = vec[1] * scalar
	vecOut[2] = vec[2] * scalar
}
stock VecAddScaled(const Float:vec1[], const Float:vec2[], Float:scalar, Float:vecOut[])
{
	vecOut[0] = vec1[0] + vec2[0] * scalar
	vecOut[1] = vec1[1] + vec2[1] * scalar
	vecOut[2] = vec1[2] + vec2[2] * scalar
}
stock VecSubScaled(const Float:vec1[], const Float:vec2[], Float:scalar, Float:vecOut[])
{
	vecOut[0] = vec1[0] - vec2[0] * scalar
	vecOut[1] = vec1[1] - vec2[1] * scalar
	vecOut[2] = vec1[2] - vec2[2] * scalar
}
stock Float:VecLength(const Float:vec[])
{
	return floatsqroot((vec[0]) * (vec[0]) + (vec[1]) * (vec[1]) + (vec[2]) * (vec[2]))
}
stock Float:VecLength2D(const Float:vec[])
{
	return floatsqroot((vec[0]) * (vec[0]) + (vec[1]) * (vec[1]))
}
stock Float:VecDistance(const Float:vec1[], const Float:vec2[])
{
	return floatsqroot
	(
		(vec1[0] - vec2[0]) * (vec1[0] - vec2[0]) +
		(vec1[1] - vec2[1]) * (vec1[1] - vec2[1]) +
		(vec1[2] - vec2[2]) * (vec1[2] - vec2[2])
	)                                       
}
stock Float:VecDistance2D(const Float:vec1[], const Float:vec2[])
{
	return floatsqroot
	(
		(vec1[0] - vec2[0]) * (vec1[0] - vec2[0]) +
		(vec1[1] - vec2[1]) * (vec1[1] - vec2[1])
	)
}
stock Float:VecDot(const Float:vec1[], const Float:vec2[])
{
	return vec1[0] * vec2[0] + vec1[1] * vec2[1] + vec1[2] * vec2[2]
}
stock InclinedPlanePoint(const Float:pointOnPlane[3], const Float:normal[3], const Float:pointIn[3], Float:pointOut[3])
{
	if (VecEqual(pointOnPlane, pointIn))
	{
		pointOut = pointOnPlane
		return
	}
	
	new Float:vecTemp[3]
	VecSub(pointIn, pointOnPlane, vecTemp)
	
	new Float:length = vector_length(vecTemp)
	length *= -VecDot(normal, vecTemp) / length
	
	pointOut[0] = pointIn[0]
	pointOut[1] = pointIn[1]
	pointOut[2] = pointIn[2] + length / normal[2]
}
stock Float:InclinedPlaneZ(const Float:pointOnPlane[3], const Float:normal[3], const Float:point[3])
{
	if (VecEqual(pointOnPlane, point)) return pointOnPlane[2]
	
	new Float:vecTemp[3]
	VecSub(point, pointOnPlane, vecTemp)
	
	new Float:length = vector_length(vecTemp)
	length *= -VecDot(normal, vecTemp) / length
	
	return point[2] + length / normal[2]
}

stock GetPlaneType(Float:planeNormalZ)
{
	// 天花板
	if (planeNormalZ == -1.0)	return 0
	// 倾斜天花板
	else if (planeNormalZ < 0.0)	return 1
	// 地面
	else if (planeNormalZ == 1.0)	return 2
	// 倾斜地面
	else if (0.0 < planeNormalZ)	return 3
	// 墙面
	return 4
}

stock bool:IsPlaneFloor(const Float:planeNormalZ)
{
	return 0.7 <= planeNormalZ
}

stock bool:IsPlaneSteep(const Float:planeNormalZ)
{
	return 0.0 < planeNormalZ < 0.7
}

stock SendMsg_BeamPoints(id, const Float:start[3], const Float:end[3], mdlId, life, width, noise, r, g, b, scrollSpeed = 0)
{
	if (127 < gBeamCount[id]) return
	
	gBeamCount[id]++
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, end, id)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	engfunc(EngFunc_WriteCoord, start[0])
	engfunc(EngFunc_WriteCoord, start[1])
	engfunc(EngFunc_WriteCoord, start[2])
	write_short(mdlId)
	write_byte(0)
	write_byte(1)
	write_byte(life)
	write_byte(width)
	write_byte(noise)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(255)		// brightness
	write_byte(scrollSpeed)	// scroll speed in 0.1's
	message_end()
}

public plugin_natives()
{
	register_native("NavSys_Pathfinding",		"_Sys_Pathfinding")
	register_native("NavSys_Pathfinding2",		"_Sys_Pathfinding2")
	register_native("NavSys_GetWaypointFinal",	"_Sys_GetWaypointFinal")
	register_native("NavSys_GetWaypointSecond",	"_Sys_GetWaypointSecond")
	register_native("NavSys_GetWaypointPathInfo",	"_Sys_GetWaypointPathInfo")
	register_native("NavSys_GetSpawnPos",		"_Sys_GetSpawnPos")
	register_native("NavSys_GetLadder",		"_Sys_GetLadder")
	register_native("NavBox_Exist",			"_Box_Exist")
	register_native("NavBox_Draw",			"_Box_Draw")
	register_native("NavBox_GetArea",		"_Box_GetArea")
	register_native("NavBox_GetContain",		"_Box_GetContain")
	register_native("NavBox_GetNearest",		"_Box_GetNearest")
	register_native("NavBox_GetNodeArray",		"_Box_GetNodeArray")
	register_native("NavBox_GetNode",		"_Box_GetNode")
	register_native("NavBox_GetNodeNearest",	"_Box_GetNodeNearest")
	register_native("NavBox_GetNodeContain",	"_Box_GetNodeContain")
	register_native("NavBox_GetNodeIntersect",	"_Box_GetNodeIntersect")
	register_native("NavBox_GetNodeInFront",	"_Box_GetNodeInFront")
	register_native("NavNode_DrawMesh",		"_Node_DrawMesh")
	register_native("NavNode_DrawBox",		"_Node_DrawBox")
	register_native("NavNode_GetNearest",		"_Node_GetNearest")
	register_native("NavNode_GetPathCoord",		"_Node_GetPathCoord")
	register_native("NavNode_GetPathCoord2",	"_Node_GetPathCoord2")
	register_native("NavNode_PathExist",		"_Node_PathExist")
	register_native("NavNode_PathExist2",		"_Node_PathExist2")
}

public Array:_Sys_Pathfinding()
{
	new tickStart = tickcount()
	
	new iNodeOrigin = get_param(1)
	new iNodeGoal = get_param(2)
	new maxTickCount = get_param(4)
	
	new Float:origin[3], Float:goal[3]
	ArrayGetArray(gArray_NodePoint, iNodeOrigin, origin)
	ArrayGetArray(gArray_NodePoint, iNodeGoal, goal)
	
	new waypointNums = 1
	new waypoint[7], Array:arrayWaypoint = ArrayCreate(7)
	waypoint[0] = iNodeOrigin			// 表示当前路点的导航点下标
	waypoint[1] = any:false				// 表示路径点的gArray_NodeEnd属性已被访问
	waypoint[2] = any:0.0				// 表示起点到路径点的实际路程
	waypoint[3] = any:VecDistance(origin, goal)	// 表示起点到路径点的实际路程+路径点到终点的直线路程
	waypoint[4] = -1				// 表示上一个路径点的导航点下标
	waypoint[5] = -1				// 表示上一个路径点下标
	waypoint[6] = -1				// 关系式:waypoint[0] == ArrayGetCell(ArrayGetCell(gArray_NodeEnd, waypoint[4]), waypoint[6])
	ArrayPushArray(arrayWaypoint, waypoint)
	
	new iWaypoint, iWaypointSelect, waypointSelect[7], Float:lastDist
	new iPath, Array:arrayEnd, Array:arrayFlags, Array:arrayHeight, Array:arrayDistance
	new iNodeEnd, PathFlags:pathFlags, Float:pathHeight, Float:pathDist, Float:nodePoint[3]
	new newWaypoint[7]
	
	LoopStart:
	
	iWaypointSelect = -1
	for (iWaypoint = 0; iWaypoint < waypointNums; iWaypoint++)
	{
		ArrayGetArray(arrayWaypoint, iWaypoint, waypoint)
		if (waypoint[1]) continue
		if (Float:waypoint[3] < lastDist || iWaypointSelect < 0) { lastDist = Float:waypoint[3]; iWaypointSelect = iWaypoint; }
	}
	
	if (iWaypointSelect < 0)
	{
		set_param_byref(3, -2)
		return arrayWaypoint
	}
	
	ArrayGetArray(arrayWaypoint, iWaypointSelect, waypointSelect)
	waypointSelect[1] = any:true
	ArraySetArray(arrayWaypoint, iWaypointSelect, waypointSelect)
	
	arrayEnd	= ArrayGetCell(gArray_NodeEnd,		waypointSelect[0])
	arrayFlags	= ArrayGetCell(gArray_NodeFlags,	waypointSelect[0])
	arrayHeight	= ArrayGetCell(gArray_NodeHeight,	waypointSelect[0])
	arrayDistance	= ArrayGetCell(gArray_NodeDistance,	waypointSelect[0])
	
	for (iPath = ArraySize(arrayEnd) - 1; 0 <= iPath; iPath--)
	{
		iNodeEnd	= ArrayGetCell(arrayEnd,	iPath)
		pathFlags	= ArrayGetCell(arrayFlags,	iPath)
		pathHeight	= ArrayGetCell(arrayHeight,	iPath)
		pathDist	= ArrayGetCell(arrayDistance,	iPath)
		
		if (pathFlags & PF_CrouchRun || 45.0 < pathHeight)	newWaypoint[2] = any:(Float:waypointSelect[2] + pathDist * 3.0)
		else if (18.0 < pathHeight)				newWaypoint[2] = any:(Float:waypointSelect[2] + pathDist * 1.5)
		else							newWaypoint[2] = any:(Float:waypointSelect[2] + pathDist)
		
		if (iNodeEnd == iNodeGoal)
		{
			newWaypoint[0] = iNodeEnd
			newWaypoint[1] = any:false
			newWaypoint[3] = newWaypoint[2]
			newWaypoint[4] = waypointSelect[0]
			newWaypoint[5] = iWaypointSelect
			newWaypoint[6] = iPath
			ArrayPushArray(arrayWaypoint, newWaypoint)
			set_param_byref(3, waypointNums)
			return arrayWaypoint
		}
		
		for (iWaypoint = 0; iWaypoint < waypointNums; iWaypoint++)
		{
			ArrayGetArray(arrayWaypoint, iWaypoint, waypoint)
			if (waypoint[0] == iNodeEnd) break
		}
		if (iWaypoint == waypointNums)
		{
			ArrayGetArray(gArray_NodePoint, iNodeEnd, nodePoint)
			newWaypoint[0] = iNodeEnd
			newWaypoint[1] = any:false
			newWaypoint[3] = any:(Float:newWaypoint[2] + VecDistance(nodePoint, goal))
			newWaypoint[4] = waypointSelect[0]
			newWaypoint[5] = iWaypointSelect
			newWaypoint[6] = iPath
			waypointNums++
			ArrayPushArray(arrayWaypoint, newWaypoint)
			continue
		}
		
		// 若iNode到iNode2的路程比路径点记载的路程更短,则重定义路径点的父路径点
		if (Float:newWaypoint[2] < Float:waypoint[2])
		{
			ArrayGetArray(gArray_NodePoint, iNodeEnd, nodePoint)
			waypoint[0] = iNodeEnd
			waypoint[3] = any:(Float:newWaypoint[2] + (Float:waypoint[3] - Float:waypoint[2]))
			waypoint[4] = waypointSelect[0]
			waypoint[5] = iWaypointSelect
			waypoint[6] = iPath
			ArraySetArray(arrayWaypoint, iWaypoint, waypoint)
		}
	}
	
	if (maxTickCount >= 0 && (tickcount() - tickStart) > maxTickCount)
	{
		set_param_byref(3, -1)
		return arrayWaypoint
	}
	
	goto LoopStart
}
public _Sys_Pathfinding2()
{
	new tickStart = tickcount()
	
	new Array:arrayWaypoint = any:get_param(1)
	new iNodeGoal = get_param(2)
	new maxTickCount = get_param(3)
	
	new Float:goal[3]
	ArrayGetArray(gArray_NodePoint, iNodeGoal, goal)
	
	new waypointNums = ArraySize(arrayWaypoint)
	new waypoint[7]
	
	new iWaypoint, iWaypointSelect, waypointSelect[7], Float:lastDist
	new iPath, Array:arrayEnd, Array:arrayFlags, Array:arrayHeight, Array:arrayDistance
	new iNodeEnd, PathFlags:pathFlags, Float:pathHeight, Float:pathDist, Float:nodePoint[3]
	new newWaypoint[7]
	
	LoopStart:
	
	iWaypointSelect = -1
	for (iWaypoint = 0; iWaypoint < waypointNums; iWaypoint++)
	{
		ArrayGetArray(arrayWaypoint, iWaypoint, waypoint)
		if (waypoint[1]) continue
		if (Float:waypoint[3] < lastDist || iWaypointSelect < 0) { lastDist = Float:waypoint[3]; iWaypointSelect = iWaypoint; }
	}
	
	if (iWaypointSelect < 0) return -2
	
	ArrayGetArray(arrayWaypoint, iWaypointSelect, waypointSelect)
	waypointSelect[1] = any:true
	ArraySetArray(arrayWaypoint, iWaypointSelect, waypointSelect)
	
	arrayEnd	= ArrayGetCell(gArray_NodeEnd,		waypointSelect[0])
	arrayFlags	= ArrayGetCell(gArray_NodeFlags,	waypointSelect[0])
	arrayHeight	= ArrayGetCell(gArray_NodeHeight,	waypointSelect[0])
	arrayDistance	= ArrayGetCell(gArray_NodeDistance,	waypointSelect[0])
	
	for (iPath = ArraySize(arrayEnd) - 1; 0 <= iPath; iPath--)
	{
		iNodeEnd	= ArrayGetCell(arrayEnd,	iPath)
		pathFlags	= ArrayGetCell(arrayFlags,	iPath)
		pathHeight	= ArrayGetCell(arrayHeight,	iPath)
		pathDist	= ArrayGetCell(arrayDistance,	iPath)
		
		if (pathFlags & PF_CrouchRun || 45.0 < pathHeight)	newWaypoint[2] = any:(Float:waypointSelect[2] + pathDist * 3.0)
		else if (18.0 < pathHeight)				newWaypoint[2] = any:(Float:waypointSelect[2] + pathDist * 1.5)
		else							newWaypoint[2] = any:(Float:waypointSelect[2] + pathDist)
		
		if (iNodeEnd == iNodeGoal)
		{
			newWaypoint[0] = iNodeEnd
			newWaypoint[1] = any:false
			newWaypoint[3] = newWaypoint[2]
			newWaypoint[4] = waypointSelect[0]
			newWaypoint[5] = iWaypointSelect
			newWaypoint[6] = iPath
			ArrayPushArray(arrayWaypoint, newWaypoint)
			return waypointNums
		}
		
		for (iWaypoint = 0; iWaypoint < waypointNums; iWaypoint++)
		{
			ArrayGetArray(arrayWaypoint, iWaypoint, waypoint)
			if (waypoint[0] == iNodeEnd) break
		}
		if (iWaypoint == waypointNums)
		{
			ArrayGetArray(gArray_NodePoint, iNodeEnd, nodePoint)
			newWaypoint[0] = iNodeEnd
			newWaypoint[1] = any:false
			newWaypoint[3] = any:(Float:newWaypoint[2] + VecDistance(nodePoint, goal))
			newWaypoint[4] = waypointSelect[0]
			newWaypoint[5] = iWaypointSelect
			newWaypoint[6] = iPath
			waypointNums++
			ArrayPushArray(arrayWaypoint, newWaypoint)
			continue
		}
		
		// 若iNode到iNode2的路程比路径点记载的路程更短,则重定义路径点的父路径点
		if (Float:newWaypoint[2] < Float:waypoint[2])
		{
			ArrayGetArray(gArray_NodePoint, iNodeEnd, nodePoint)
			waypoint[0] = iNodeEnd
			waypoint[3] = any:(Float:newWaypoint[2] + (Float:waypoint[3] - Float:waypoint[2]))
			waypoint[4] = waypointSelect[0]
			waypoint[5] = iWaypointSelect
			waypoint[6] = iPath
			ArraySetArray(arrayWaypoint, iWaypoint, waypoint)
		}
	}
	
	if (maxTickCount >= 0 && (tickcount() - tickStart) > maxTickCount) return -1
	
	goto LoopStart
}
public _Sys_GetWaypointFinal()
{
	new Array:arrayWaypoint = any:get_param(1)
	
	new Float:goal[3]
	get_array_f(2, goal, 3)
	
	new iWaypointFinal = -1
	new waypoint[7]
	new bool:ducking, Float:point[3], Float:absMin[3], Float:absMax[3], Float:normal[3]
	new i, bool:bContain, Float:dist, Float:lastDist, Float:vecDist[3], Float:vecDest[3]
	for (new iWaypoint = ArraySize(arrayWaypoint) - 1; 0 < iWaypoint; iWaypoint--)
	{
		ArrayGetArray(arrayWaypoint, iWaypoint, waypoint)
		ducking = ArrayGetCell(gArray_NodeDucking, waypoint[0])
		ArrayGetArray(gArray_NodePoint, waypoint[0], point)
		ArrayGetArray(gArray_NodeAbsMin, waypoint[0], absMin)
		ArrayGetArray(gArray_NodeAbsMax, waypoint[0], absMax)
		ArrayGetArray(gArray_NodeNormal, waypoint[0], normal)
		
		for (i = 0; i < 2; i++)
		{
			if (goal[i] < absMin[i])	{ vecDist[i] = absMin[i] - goal[i];	vecDest[i] = absMin[i]; }
			else if (absMax[i] < goal[i])	{ vecDist[i] = goal[i] - absMax[i];	vecDest[i] = absMax[i]; }
			else				{ vecDist[i] = 0.0;			vecDest[i] = goal[i]; }
		}
		
		point[2] -= ducking ? 18.0 : 36.0
		absMin[2] = InclinedPlaneZ(point, normal, goal)
		absMax[2] = absMin[2] + (ducking ? 36.0 : 72.0)
		point[2] = (absMin[2] + absMax[2]) * 0.5
		if (goal[2] < absMin[2])	vecDist[2] = absMin[2] - goal[2]
		else if (absMax[2] < goal[2])	vecDist[2] = goal[2] - absMax[2]
		else				vecDist[2] = 0.0
		
		if (vecDist[0] == 0.0 && vecDist[1] == 0.0 && vecDist[2] == 0.0)
		{
			dist = (point[2] - goal[2]) * (point[2] - goal[2])
			if (dist < lastDist || !bContain)
			{
				lastDist = dist
				bContain = true
				iWaypointFinal = iWaypoint
			}
			continue
		}
		if (bContain) continue
		
		dist =	(vecDist[0]) * (vecDist[0]) +
			(vecDist[1]) * (vecDist[1]) +
			(vecDist[2]) * (vecDist[2])
		
		if (dist < lastDist || iWaypointFinal < 0)
		{
			lastDist = dist
			iWaypointFinal = iWaypoint
		}
	}
	return iWaypointFinal
}
public _Sys_GetWaypointSecond()
{
	new Array:arrayWaypoint = any:get_param(1)
	
	new waypoint[7]
	waypoint[5] = get_param(2)
	
	do ArrayGetArray(arrayWaypoint, waypoint[5], waypoint)
	while (0 < waypoint[5])
	
	set_array(3, waypoint, 7)
}
public _Sys_GetWaypointPathInfo()
{
	new Array:arrayWaypoint = any:get_param(1)
	new iWaypointFinal = get_param(2)
	
	new Float:origin[3]
	get_array_f(3, origin, 3)
	
	new waypoint[7]
	new bool:ducking, Float:point[3], Float:absMin[3], Float:absMax[3], Float:normal[3], Float:vecDist[3], Float:vecDest[3]
	new i, bool:bContain, Float:dist, Float:lastDist = -1.0
	new iWaypointNearest, iWaypointNext, iWaypointTemp = -1
	while (0 <= iWaypointFinal)
	{
		ArrayGetArray(arrayWaypoint, iWaypointFinal, waypoint)
		
		ducking = ArrayGetCell(gArray_NodeDucking, waypoint[0])
		ArrayGetArray(gArray_NodePoint, waypoint[0], point)
		ArrayGetArray(gArray_NodeAbsMin, waypoint[0], absMin)
		ArrayGetArray(gArray_NodeAbsMax, waypoint[0], absMax)
		ArrayGetArray(gArray_NodeNormal, waypoint[0], normal)
		
		for (i = 0; i < 2; i++)
		{
			if (origin[i] < absMin[i])	{ vecDist[i] = absMin[i] - origin[i];	vecDest[i] = absMin[i]; }
			else if (absMax[i] < origin[i])	{ vecDist[i] = origin[i] - absMax[i];	vecDest[i] = absMax[i]; }
			else				{ vecDist[i] = 0.0;			vecDest[i] = origin[i]; }
		}
		
		point[2] -= ducking ? 18.0 : 36.0
		absMin[2] = InclinedPlaneZ(point, normal, origin)
		absMax[2] = absMin[2] + (ducking ? 36.0 : 72.0)
		point[2] = (absMin[2] + absMax[2]) * 0.5
		if (origin[2] < absMin[2])	vecDist[2] = absMin[2] - origin[2]
		else if (absMax[2] < origin[2])	vecDist[2] = origin[2] - absMax[2]
		else				vecDist[2] = 0.0
		
		if (vecDist[0] == 0.0 && vecDist[1] == 0.0 && vecDist[2] == 0.0)
		{
			dist = (point[2] - origin[2]) * (point[2] - origin[2])
			if (dist < lastDist || !bContain)
			{
				lastDist = dist
				bContain = true
				iWaypointNearest = iWaypointFinal
				iWaypointNext = iWaypointTemp
			}
		}
		else if (!bContain)
		{
			dist =	(vecDist[0]) * (vecDist[0]) +
				(vecDist[1]) * (vecDist[1]) +
				(vecDist[2]) * (vecDist[2])
			
			if (dist < lastDist || lastDist < 0.0)
			{
				lastDist = dist
				iWaypointNearest = iWaypointFinal
				iWaypointNext = iWaypointTemp
			}
		}
		
		iWaypointTemp = iWaypointFinal
		iWaypointFinal = waypoint[5]
	}
	
	ArrayGetArray(arrayWaypoint, iWaypointNearest, waypoint)
	if (0 <= waypoint[5])
	{
		if (0.0 < Float:ArrayGetCell(ArrayGetCell(gArray_NodeHeight, waypoint[4]), waypoint[6]))
		{
			ArrayGetArray(gArray_NodePoint, waypoint[0], point)
			dist = (point[2] - origin[2]) * (point[2] - origin[2])
			ArrayGetArray(gArray_NodePoint, waypoint[4], point)
			lastDist = (point[2] - origin[2]) * (point[2] - origin[2])
			if (lastDist < dist)
			{
				set_param_byref(4, waypoint[4])
				set_param_byref(5, waypoint[0])
				set_param_byref(6, waypoint[6])
				return
			}
		}
	}
	
	if (iWaypointNext < 0)
	{
		set_param_byref(4, waypoint[0])
		set_param_byref(5, -1)
		set_param_byref(6, -1)
		return
	}
	
	ArrayGetArray(arrayWaypoint, iWaypointNext, waypoint)
	set_param_byref(4, waypoint[4])
	set_param_byref(5, waypoint[0])
	set_param_byref(6, waypoint[6])
}
public Array:_Sys_GetSpawnPos() { return gArray_SpawnPos; }
public Array:_Sys_GetLadder() { return gArray_Ladder; }
public bool:_Box_Exist()
{
	new Float:origin[3]
	get_array_f(1, origin, 3)
	return NavBox_Exist(origin)
}
public _Box_Draw()
{
	new Float:absMin[3], Float:absMax[3]
	get_array_f(2, absMin, 3)
	get_array_f(3, absMax, 3)
	NavBox_Draw(get_param(1), absMin, absMax, get_param(4), get_param(5), get_param(6), get_param(7), get_param(8), get_param(9))
}
public _Box_GetArea()
{
	set_array_f(1, gMapAbsMin, 3)
	set_array_f(2, gMapAbsMax, 3)
}
public _Box_GetContain()
{
	new Float:origin[3], Float:absMin[3], Float:absMax[3]
	get_array_f(1, origin, 3)
	NavBox_GetContain(origin, absMin, absMax)
	set_array_f(2, absMin, 3)
	set_array_f(3, absMax, 3)
}
public _Box_GetNearest()
{
	new Float:origin[3], Float:absMin[3], Float:absMax[3]
	get_array_f(1, origin, 3)
	NavBox_GetNearest(origin, absMin, absMax)
	set_array_f(2, absMin, 3)
	set_array_f(3, absMax, 3)
}
public Array:_Box_GetNodeArray()
{
	new Float:origin[3]
	get_array_f(1, origin, 3)
	return NavBox_GetNodeArray(origin)
}
public _Box_GetNode()
{
	new Float:origin[3]
	get_array_f(1, origin, 3)
	return NavBox_GetNode(origin)
}
public _Box_GetNodeNearest()
{
	new Float:origin[3]
	get_array_f(1, origin, 3)
	return NavBox_GetNodeNearest(origin)
}
public _Box_GetNodeContain()
{
	new Float:origin[3]
	get_array_f(1, origin, 3)
	return NavBox_GetNodeContain(origin)
}
public _Box_GetNodeIntersect()
{
	new Float:absMin[3], Float:absMax[3]
	get_array_f(1, absMin, 3)
	get_array_f(2, absMax, 3)
	return NavBox_GetNodeIntersect(absMin, absMax)
}
public _Box_GetNodeInFront() { return NavBox_GetNodeInFront(get_param(1)); }
public _Node_DrawMesh()
{
	NavNode_DrawMesh(get_param(1), get_param(2), bool:get_param(3), get_param(4), get_param(5), get_param(6), get_param(7), get_param(8), get_param(9))
}
public _Node_DrawBox() { NavNode_DrawBox(get_param(1), get_param(2), get_param(3), get_param(4), get_param(5), get_param(6), get_param(7), get_param(8)); }
public _Node_GetNearest()
{
	new Float:origin[3]
	get_array_f(1, origin, 3)
	return NavNode_GetNearest(origin)
}
public _Node_GetPathCoord()
{
	new Float:start[3], Float:mid[3], Float:end[3]
	NavNode_GetPathCoord(get_param(1), get_param(2), get_param(3), start, mid, end)
	set_array_f(4, start, 3)
	set_array_f(5, mid, 3)
	set_array_f(6, end, 3)
}
public _Node_GetPathCoord2()
{
	new PathFlags:flags, Float:height, Float:end[3]
	NavNode_GetPathCoord2(get_param(1), get_param(2), get_param(3), flags, height, end)
	set_param_byref(4, any:flags)
	set_param_byref(5, any:height)
	set_array_f(6, end, 3)
}
public bool:_Node_PathExist()
{
	new bool:duckingStart, Float:start[3], Float:goal[3]
	new bool:duckingEnd, Float:end[3], Float:normal[3]
	new bool:crouchRun, Float:height
	new bool:exist
	
	duckingStart = any:get_param(1)
	get_array_f(2, start, 3)
	get_array_f(3, goal, 3)
	
	exist = NavPath_Exist(duckingStart, start, goal, duckingEnd, end, normal, crouchRun, height)
	
	set_param_byref(4, any:duckingEnd)
	set_array_f(5, end, 3)
	set_array_f(6, normal, 3)
	set_param_byref(7, any:crouchRun)
	set_param_byref(8, any:height)
	
	return exist
}
public bool:_Node_PathExist2()
{
	new bool:duckingStart, Float:start[3], Float:goal[3]
	new bool:duckingEnd, Float:end[3], Float:normal[3]
	new bool:crouchRun, Float:height
	new bool:exist
	
	duckingStart = any:get_param(1)
	get_array_f(2, start, 3)
	get_array_f(3, goal, 3)
	
	exist = NavPath_Exist2(duckingStart, start, goal, duckingEnd, end, normal, crouchRun, height)
	
	set_param_byref(4, any:duckingEnd)
	set_array_f(5, end, 3)
	set_array_f(6, normal, 3)
	set_param_byref(7, any:crouchRun)
	set_param_byref(8, any:height)
	
	return exist
}

