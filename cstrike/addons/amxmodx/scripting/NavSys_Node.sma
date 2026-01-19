/* UTF-8 func by www.DT-Club.net */

#define dJumpHeight		45.0					// 跳跃高度(空中按蹲可缩短下半身18高度.导致玩家能跳上63高度的障碍物)
#define dSafeHeight		161.0					// 安全高度理论上=500*500/2/800,然而实测为161

// 哪些障碍物可以被轨迹线忽略(不要改这个东西)
#define dTraceIgnore		IGNORE_MONSTERS

enum PathFlags
{
	PF_Walk,
	PF_CrouchRun	= 1,
	PF_Climb	= 2,
}

new Array:gArray_NodeDucking
new Array:gArray_NodePoint, Array:gArray_NodeAbsMin, Array:gArray_NodeAbsMax, Array:gArray_NodeNormal
new Array:gArray_NodeStart, Array:gArray_NodeEnd, Array:gArray_NodeFlags, Array:gArray_NodeHeight, Array:gArray_NodeDistance

new bool:gAutoAlign
new Array:gArray_Selected

NavNode_Create(const Float:origin[3], const Float:normal[3], bool:ducking)
{
	new nodeIndex = ArraySize(gArray_NodePoint)
	
	new Float:height = ducking ? 18.0 : 36.0
	
	new Float:absMin[3], Float:absMax[3]
	absMin[0] = origin[0] - 16.0
	absMin[1] = origin[1] - 16.0
	absMin[2] = origin[2] - height
	absMax[0] = origin[0] + 16.0
	absMax[1] = origin[1] + 16.0
	absMax[2] = origin[2] + height
	
	ArrayPushCell(gArray_NodeDucking, ducking)
	ArrayPushArray(gArray_NodePoint, origin)
	ArrayPushArray(gArray_NodeAbsMin, absMin)
	ArrayPushArray(gArray_NodeAbsMax, absMax)
	ArrayPushArray(gArray_NodeNormal, normal)
	ArrayPushCell(gArray_NodeStart, ArrayCreate())
	ArrayPushCell(gArray_NodeEnd, ArrayCreate())
	ArrayPushCell(gArray_NodeFlags, ArrayCreate())
	ArrayPushCell(gArray_NodeHeight, ArrayCreate())
	ArrayPushCell(gArray_NodeDistance, ArrayCreate())
	
	return nodeIndex
}

NavNode_Clear()
{
	new iNode, nodeNums
	new Array:arrayStart, Array:arrayEnd, Array:arrayFlags, Array:arrayHeight, Array:arrayDistance
	nodeNums = ArraySize(gArray_NodeDucking)
	for (iNode = 0; iNode < nodeNums; iNode++)
	{
		arrayStart	= ArrayGetCell(gArray_NodeStart,	iNode)
		arrayEnd	= ArrayGetCell(gArray_NodeEnd,		iNode)
		arrayFlags	= ArrayGetCell(gArray_NodeFlags,	iNode)
		arrayHeight	= ArrayGetCell(gArray_NodeHeight,	iNode)
		arrayDistance	= ArrayGetCell(gArray_NodeDistance,	iNode)
		ArrayDestroy(arrayStart)
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
}

NavNode_DrawMesh(id, nodeIndex, bool:drawPaths, life, width, noise, r, g, b)
{
	new bool:ducking, Float:nodePoint[3], Float:absMin[3], Float:absMax[3], Float:normal[3]
	ducking = ArrayGetCell(gArray_NodeDucking, nodeIndex)
	ArrayGetArray(gArray_NodePoint, nodeIndex, nodePoint)
	ArrayGetArray(gArray_NodeAbsMin, nodeIndex, absMin)
	ArrayGetArray(gArray_NodeAbsMax, nodeIndex, absMax)
	ArrayGetArray(gArray_NodeNormal, nodeIndex, normal)
	
	nodePoint[2] -= ducking ? 13.0 : 31.0
	
	new Float:cornerPoint[4][3]
	cornerPoint[0][0] = absMax[0] - 2.0
	cornerPoint[0][1] = absMax[1] - 2.0
	cornerPoint[0][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[0])
	cornerPoint[1][0] = absMin[0] + 2.0
	cornerPoint[1][1] = absMax[1] - 2.0
	cornerPoint[1][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[1])
	cornerPoint[2][0] = absMin[0] + 2.0
	cornerPoint[2][1] = absMin[1] + 2.0
	cornerPoint[2][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[2])
	cornerPoint[3][0] = absMax[0] - 2.0
	cornerPoint[3][1] = absMin[1] + 2.0
	cornerPoint[3][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[3])
	
	SendMsg_BeamPoints(id, cornerPoint[0], cornerPoint[1], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[1], cornerPoint[2], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[2], cornerPoint[3], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[3], cornerPoint[0], gMdlId_BeamNode, life, width, noise, r, g, b)
	if (ducking)
	{
		SendMsg_BeamPoints(id, cornerPoint[0], cornerPoint[2], gMdlId_BeamNode, life, width, noise, r, g, b)
		SendMsg_BeamPoints(id, cornerPoint[1], cornerPoint[3], gMdlId_BeamNode, life, width, noise, r, g, b)
	}
	
	if (drawPaths)
	{
		nodePoint[2] += 1.0
		
		new nodeId, PathFlags:pathFlags, Float:height
		new iPathStart, iPathEnd
		new Array:arrayStart	= ArrayGetCell(gArray_NodeStart,	nodeIndex)
		new Array:arrayEnd	= ArrayGetCell(gArray_NodeEnd,		nodeIndex)
		new Array:arrayFlags	= ArrayGetCell(gArray_NodeFlags,	nodeIndex)
		new Array:arrayHeight	= ArrayGetCell(gArray_NodeHeight,	nodeIndex)
		
		new Float:dest[3], Float:destAbsMin[3], Float:destAbsMax[3], Float:mid[3], Float:start[3], Float:end[3], Float:vecF[3]
		new j, mdlId, pathWidth, r, g, b
		for (iPathEnd = ArraySize(arrayEnd) - 1; 0 <= iPathEnd; iPathEnd--)
		{
			nodeId		= ArrayGetCell(arrayEnd,	iPathEnd)
			pathFlags	= ArrayGetCell(arrayFlags,	iPathEnd)
			height		= ArrayGetCell(arrayHeight,	iPathEnd)
			
			ArrayGetArray(gArray_NodePoint, nodeId, dest)
			ArrayGetArray(gArray_NodeAbsMin, nodeId, destAbsMin)
			ArrayGetArray(gArray_NodeAbsMax, nodeId, destAbsMax)
			ArrayGetArray(gArray_NodeNormal, nodeId, vecF)
			
			dest[2] -= ArrayGetCell(gArray_NodeDucking, nodeId) ? 12.0 : 30.0
			
			for (j = 0; j < 2; j++)
			{
				if (dest[j] < nodePoint[j])	mid[j] = floatmin(nodePoint[j], floatmax(dest[j], (destAbsMax[j] + absMin[j]) * 0.5))
				else				mid[j] = floatmax(nodePoint[j], floatmin(dest[j], (absMax[j] + destAbsMin[j]) * 0.5))
				if (mid[j] == absMin[j])	{ start[j] = absMin[j] + 16.0; end[j] = absMin[j] - 16.0; }
				else if (mid[j] == absMax[j])	{ start[j] = absMax[j] - 16.0; end[j] = absMax[j] + 16.0; }
				else				{ start[j] = end[j] = mid[j]; }
			}
			start[2]	= InclinedPlaneZ(nodePoint, normal, start)
			mid[2]		= InclinedPlaneZ(nodePoint, normal, mid) + height
			end[2]		= InclinedPlaneZ(dest, vecF, end)
			
			for (iPathStart = ArraySize(arrayStart) - 1; 0 <= iPathStart && ArrayGetCell(arrayStart, iPathStart) != nodeId; iPathStart--) { }
			
			if (pathFlags & PF_Climb)	{ mdlId = gMdlId_BeamPath2; pathWidth = width + 15; }
			else				{ mdlId = gMdlId_BeamPath1; pathWidth = width + 10; }
			if (pathFlags & PF_CrouchRun)	{ r = 200; g = 0; b = iPathStart < 0 ? 0 : 200; }
			else				{ r = 0; g = iPathStart < 0 ? 0 : 200; b = 200; }
			
			if (0.0 < height)
			{
				SendMsg_BeamPoints(id, start, mid, gMdlId_BeamNode, life, width, noise, r, g, b)
				SendMsg_BeamPoints(id, mid, end, mdlId, life, pathWidth, noise, r, g, b)
			}
			else	SendMsg_BeamPoints(id, start, end, mdlId, life, pathWidth, noise, r, g, b)
		}
	}
}

NavNode_DrawBox(id, nodeIndex, life, width, noise, r, g, b)
{
	new bool:ducking, Float:nodePoint[3], Float:absMin[3], Float:absMax[3], Float:normal[3]
	ducking = ArrayGetCell(gArray_NodeDucking, nodeIndex)
	ArrayGetArray(gArray_NodePoint, nodeIndex, nodePoint)
	ArrayGetArray(gArray_NodeAbsMin, nodeIndex, absMin)
	ArrayGetArray(gArray_NodeAbsMax, nodeIndex, absMax)
	ArrayGetArray(gArray_NodeNormal, nodeIndex, normal)
	
	nodePoint[2] -= ducking ? 18.0 : 36.0
	
	new Float:cornerPoint[8][3]
	cornerPoint[0][0] = absMax[0]
	cornerPoint[0][1] = absMax[1]
	cornerPoint[0][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[0])
	cornerPoint[1][0] = absMin[0]
	cornerPoint[1][1] = absMax[1]
	cornerPoint[1][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[1])
	cornerPoint[2][0] = absMin[0]
	cornerPoint[2][1] = absMin[1]
	cornerPoint[2][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[2])
	cornerPoint[3][0] = absMax[0]
	cornerPoint[3][1] = absMin[1]
	cornerPoint[3][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[3])
	
	nodePoint[2] += ducking ? 36.0 : 72.0
	
	cornerPoint[4][0] = absMax[0]
	cornerPoint[4][1] = absMax[1]
	cornerPoint[4][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[4])
	cornerPoint[5][0] = absMin[0]
	cornerPoint[5][1] = absMax[1]
	cornerPoint[5][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[5])
	cornerPoint[6][0] = absMin[0]
	cornerPoint[6][1] = absMin[1]
	cornerPoint[6][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[6])
	cornerPoint[7][0] = absMax[0]
	cornerPoint[7][1] = absMin[1]
	cornerPoint[7][2] = InclinedPlaneZ(nodePoint, normal, cornerPoint[7])
	
	SendMsg_BeamPoints(id, cornerPoint[0], cornerPoint[1], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[1], cornerPoint[2], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[2], cornerPoint[3], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[3], cornerPoint[0], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[4], cornerPoint[5], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[5], cornerPoint[6], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[6], cornerPoint[7], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[7], cornerPoint[4], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[0], cornerPoint[4], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[1], cornerPoint[5], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[2], cornerPoint[6], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, cornerPoint[3], cornerPoint[7], gMdlId_BeamNode, life, width, noise, r, g, b)
}

bool:NavNode_Selects(nodeIndex)
{
	for (new i = ArraySize(gArray_Selected) - 1; 0 <= i; i--)
	{
		if (ArrayGetCell(gArray_Selected, i) == nodeIndex)
		{
			ArrayDeleteItem(gArray_Selected, i)
			return false
		}
	}
	ArrayPushCell(gArray_Selected, nodeIndex)
	return true
}

NavNode_Delete(iNodeSelect)
{
	new iNodeStart, iNodeMid, iNodeEnd, iPath
	new Array:arrayStart, Array:arrayEnd, Array:arrayFlags, Array:arrayHeight, Array:arrayDistance
	
	// 删除所有终点是iNodeSelect的路径,并更新节点id
	for (iNodeMid = ArraySize(gArray_NodeDucking) - 1; 0 <= iNodeMid; iNodeMid--)
	{
		arrayStart	= ArrayGetCell(gArray_NodeStart,	iNodeMid)
		arrayEnd	= ArrayGetCell(gArray_NodeEnd,		iNodeMid)
		arrayFlags	= ArrayGetCell(gArray_NodeFlags,	iNodeMid)
		arrayHeight	= ArrayGetCell(gArray_NodeHeight,	iNodeMid)
		arrayDistance	= ArrayGetCell(gArray_NodeDistance,	iNodeMid)
		
		// 遍历iNodeMid的所有起点,有则删除iNodeSelect,更新其他起点id
		for (iPath = ArraySize(arrayStart) - 1; 0 <= iPath; iPath--)
		{
			iNodeStart = ArrayGetCell(arrayStart, iPath)
			if (iNodeStart == iNodeSelect) ArrayDeleteItem(arrayStart, iPath)
			else if (iNodeSelect < iNodeStart) ArraySetCell(arrayStart, iPath, iNodeStart - 1)
		}
		// 遍历iNodeMid的所有终点,删除终点是iNodeSelect的路径,或更新终点id
		for (iPath = ArraySize(arrayEnd) - 1; 0 <= iPath; iPath--)
		{
			iNodeEnd = ArrayGetCell(arrayEnd, iPath)
			if (iNodeEnd == iNodeSelect)
			{
				ArrayDeleteItem(arrayEnd,	iPath)
				ArrayDeleteItem(arrayFlags,	iPath)
				ArrayDeleteItem(arrayHeight,	iPath)
				ArrayDeleteItem(arrayDistance,	iPath)
			}
			else if (iNodeSelect < iNodeEnd) ArraySetCell(arrayEnd, iPath, iNodeEnd - 1)
		}
	}
	
	// 删除iNodeSelect节点的所有信息
	arrayStart	= ArrayGetCell(gArray_NodeStart,	iNodeSelect)
	arrayEnd	= ArrayGetCell(gArray_NodeEnd,		iNodeSelect)
	arrayFlags	= ArrayGetCell(gArray_NodeFlags,	iNodeSelect)
	arrayHeight	= ArrayGetCell(gArray_NodeHeight,	iNodeSelect)
	arrayDistance	= ArrayGetCell(gArray_NodeDistance,	iNodeSelect)
	ArrayDestroy(arrayStart)
	ArrayDestroy(arrayEnd)
	ArrayDestroy(arrayFlags)
	ArrayDestroy(arrayHeight)
	ArrayDestroy(arrayDistance)
	
	ArrayDeleteItem(gArray_NodeDucking,	iNodeSelect)
	ArrayDeleteItem(gArray_NodePoint,	iNodeSelect)
	ArrayDeleteItem(gArray_NodeAbsMax,	iNodeSelect)
	ArrayDeleteItem(gArray_NodeAbsMin,	iNodeSelect)
	ArrayDeleteItem(gArray_NodeNormal,	iNodeSelect)
	ArrayDeleteItem(gArray_NodeStart,	iNodeSelect)
	ArrayDeleteItem(gArray_NodeEnd,		iNodeSelect)
	ArrayDeleteItem(gArray_NodeFlags,	iNodeSelect)
	ArrayDeleteItem(gArray_NodeHeight,	iNodeSelect)
	ArrayDeleteItem(gArray_NodeDistance,	iNodeSelect)
}

NavNode_AutoCreating()
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
	
	new iVecDir, Float:vecDir[8][2] =
	{
		{	32.0,	0.0	},
		{	32.0,	32.0	},
		{	0.0,	32.0	},
		{	-32.0,	32.0	},
		{	-32.0,	0.0	},
		{	-32.0,	-32.0	},
		{	0.0,	-32.0	},
		{	32.0,	-32.0	}
	}
	
	new iSpawnPos, spawnPosNums, Float:spawnPos[6]
	new iNodeSelect, iNode, nodeNums
	new bool:ducking, Float:coord[3], Float:normal[3], Float:absMin[3], Float:absMax[3]
	new bool:nodeDucking, Float:nodePoint[3], Float:nodeNormal[3], bool:crouchRun, Float:height
	
	nodeNums = ArraySize(gArray_NodeDucking)
	if (nodeNums) NavNode_Clear()
	
	spawnPosNums = ArraySize(gArray_SpawnPos)
	for (iSpawnPos = 0; iSpawnPos < spawnPosNums; iSpawnPos++)
	{
		ArrayGetArray(gArray_SpawnPos, iSpawnPos, spawnPos)
		coord[0] = spawnPos[0]
		coord[1] = spawnPos[1]
		coord[2] = spawnPos[2]
		
		nodeNums = ArraySize(gArray_NodeDucking)
		for (iNode = 0; iNode < nodeNums; iNode++)
		{
			ArrayGetArray(gArray_NodeAbsMin, iNode, absMin)
			if (coord[0] < absMin[0]) continue
			if (coord[1] < absMin[1]) continue
			if (coord[2] < absMin[2]) continue
			ArrayGetArray(gArray_NodeAbsMax, iNode, absMax)
			if (absMax[0] <= coord[0]) continue
			if (absMax[1] <= coord[1]) continue
			if (absMax[2] <= coord[2]) continue
			break
		}
		if (nodeNums && iNode < nodeNums) continue
		
		normal[0] = spawnPos[3]
		normal[1] = spawnPos[4]
		normal[2] = spawnPos[5]
		iNodeSelect = NavNode_Create(coord, normal, ducking)
		nodeNums++
		
		LoopStart:
		
		for (iVecDir = 0; iVecDir < 8; iVecDir++)
		{
			nodePoint[0] = coord[0] + vecDir[iVecDir][0]
			nodePoint[1] = coord[1] + vecDir[iVecDir][1]
			nodePoint[2] = coord[2]
			if (NavPath_Exist2(ducking, coord, nodePoint, nodeDucking, nodePoint, nodeNormal, crouchRun, height))
			{
				for (iNode = 0; iNode < nodeNums; iNode++)
				{
					if (iNode == iNodeSelect) continue
					ArrayGetArray(gArray_NodeAbsMin, iNode, absMin)
					if (nodePoint[0] < absMin[0]) continue
					if (nodePoint[1] < absMin[1]) continue
					if (nodePoint[2] < absMin[2]) continue
					ArrayGetArray(gArray_NodeAbsMax, iNode, absMax)
					if (absMax[0] <= nodePoint[0]) continue
					if (absMax[1] <= nodePoint[1]) continue
					if (absMax[2] <= nodePoint[2]) continue
					break
				}
				
				if (iNode == nodeNums)
				{
					iNode = NavNode_Create(nodePoint, nodeNormal, nodeDucking)
					nodeNums++
				}
				else 	ArrayGetArray(gArray_NodePoint, iNode, nodePoint)
				
				ArrayPushCell(ArrayGetCell(gArray_NodeStart,		iNode),		iNodeSelect)
				ArrayPushCell(ArrayGetCell(gArray_NodeEnd,		iNodeSelect),	iNode)
				ArrayPushCell(ArrayGetCell(gArray_NodeFlags,		iNodeSelect),	crouchRun ? PF_CrouchRun : PF_Walk)
				ArrayPushCell(ArrayGetCell(gArray_NodeHeight,		iNodeSelect),	height)
				ArrayPushCell(ArrayGetCell(gArray_NodeDistance,		iNodeSelect),	VecDistance(coord, nodePoint))
			}
		}
		
		if (++iNodeSelect < nodeNums)
		{
			ducking = ArrayGetCell(gArray_NodeDucking, iNodeSelect)
			ArrayGetArray(gArray_NodePoint, iNodeSelect, coord)
			goto LoopStart
		}
	}
	
	for (i = ArraySize(gArray_Ladder) - 1; 0 <= i; i--) set_pev(ArrayGetCell(gArray_Ladder, i), pev_solid, SOLID_NOT)
	for (i = ArraySize(gArray_TraceIgnoreEnt) - 1; 0 <= i; i--)
	{
		ArrayGetArray(gArray_TraceIgnoreEnt, i, param)
		set_pev(param[0], pev_solid, param[1])
	}
}

bool:NavPath_Exist(bool:duckingStart, const Float:start[3], const Float:goal[3], &bool:duckingEnd, Float:end[3], Float:normal[3], &bool:crouchRun, &Float:height)
{
	new hull
	new bool:isPlaneSteep, bool:startOnSteep, bool:safeHeight
	new Float:fraction, Float:z
	new Float:vecSrc[3], Float:vecDest[3], Float:vecPlaneNormal[3], Float:vecEndPos[3], Float:vecTemp[3]
	
	vecSrc[0] = start[0]
	vecSrc[1] = start[1]
	vecSrc[2] = start[2] - 9999.0
	engfunc(EngFunc_TraceHull, start, vecSrc, dTraceIgnore, HULL_HEAD, -1, 0)
	get_tr2(0, TR_vecEndPos, vecSrc)
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
	
	vecDest[0] = goal[0]
	vecDest[1] = goal[1]
	vecDest[2] = vecSrc[2]
	startOnSteep = IsPlaneSteep(vecPlaneNormal[2])
	
	engfunc(EngFunc_TraceHull, vecSrc, vecDest, dTraceIgnore, HULL_HEAD, -1, 0)
	
	get_tr2(0, TR_flFraction, fraction)
	if (fraction < 1.0)
	{
		if (startOnSteep) return false
		
		get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
		new bool:isPlaneFloor = IsPlaneFloor(vecPlaneNormal[2])
		
		vecTemp[0] = vecDest[0]
		vecTemp[1] = vecDest[1]
		vecTemp[2] = vecSrc[2] + (duckingStart ? dJumpHeight : dJumpHeight + 18.0)
		
		engfunc(EngFunc_TraceHull, vecDest, vecTemp, dTraceIgnore, HULL_HEAD, -1, 0)
		get_tr2(0, TR_vecEndPos, vecDest)
		
		vecTemp[2] = vecSrc[2] - 9999.0
		
		engfunc(EngFunc_TraceHull, vecDest, vecTemp, dTraceIgnore, HULL_HEAD, -1, 0)
		get_tr2(0, TR_vecEndPos, vecEndPos)
		get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
		
		engfunc(EngFunc_TraceHull, vecEndPos, vecEndPos, dTraceIgnore, HULL_HEAD, -1, 0)
		if (!get_tr2(0, TR_InOpen) || get_tr2(0, TR_AllSolid) || get_tr2(0, TR_StartSolid)) return false
		
		if (vecEndPos[2] <= vecSrc[2])
		{
			isPlaneSteep = IsPlaneSteep(vecPlaneNormal[2])
			safeHeight = vecDest[2] - vecEndPos[2] <= dSafeHeight
			
			/* 尝试将坐标提升到与直立玩家的坐标相同的高度 */
			vecEndPos[2] += 18.0
			engfunc(EngFunc_TraceHull, vecEndPos, vecEndPos, dTraceIgnore, HULL_HUMAN, -1, 0)
			if (get_tr2(0, TR_InOpen) && !get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid)) hull = HULL_HUMAN
			else { hull = HULL_HEAD; vecEndPos[2] -= 18.0; }
			
			// 会摔伤.此路不通
			if (!isPlaneSteep && dSafeHeight < vecDest[2] - vecEndPos[2]) return false
		}
		else
		{
			safeHeight = true
			if (isPlaneFloor)
			{
				z = 0.0
				
				engfunc(EngFunc_TraceHull, vecSrc, vecEndPos, dTraceIgnore, HULL_HEAD, -1, 0)
				get_tr2(0, TR_flFraction, fraction)
				if (fraction < 1.0)
				{
					get_tr2(0, TR_vecPlaneNormal, vecTemp)
					if (!IsPlaneFloor(vecTemp[2]))	z = float(floatround(vecEndPos[2] - vecSrc[2], floatround_ceil))
				}
			}
			else
			{
				if (IsPlaneSteep(vecPlaneNormal[2]))	z = 45.0
				else					z = float(floatround(vecEndPos[2] - vecSrc[2], floatround_ceil))
				
				vecSrc[2] = vecEndPos[2]
				engfunc(EngFunc_TraceHull, vecEndPos, vecSrc, dTraceIgnore, HULL_HEAD, -1, 0)
				get_tr2(0, TR_flFraction, fraction)
				if (fraction < 1.0) return false
			}
			
			/* 尝试将坐标提升到与直立玩家的坐标相同的高度 */
			vecEndPos[2] += 18.0
			engfunc(EngFunc_TraceHull, vecEndPos, vecEndPos, dTraceIgnore, HULL_HUMAN, -1, 0)
			if (get_tr2(0, TR_InOpen) && !get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid)) hull = HULL_HUMAN
			else { hull = HULL_HEAD; vecEndPos[2] -= 18.0; }
		}
	}
	else
	{
		vecTemp[0] = vecDest[0]
		vecTemp[1] = vecDest[1]
		vecTemp[2] = vecDest[2] - 9999.0
		
		engfunc(EngFunc_TraceHull, vecDest, vecTemp, dTraceIgnore, HULL_HEAD, -1, 0)
		
		get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
		get_tr2(0, TR_vecEndPos, vecEndPos)
		
		isPlaneSteep = IsPlaneSteep(vecPlaneNormal[2])
		safeHeight = vecDest[2] - vecEndPos[2] <= dSafeHeight
		
		/* 尝试将坐标提升到与直立玩家的坐标相同的高度 */
		vecEndPos[2] += 18.0
		engfunc(EngFunc_TraceHull, vecEndPos, vecEndPos, dTraceIgnore, HULL_HUMAN, -1, 0)
		if (get_tr2(0, TR_InOpen) && !get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid)) hull = HULL_HUMAN
		else { hull = HULL_HEAD; vecEndPos[2] -= 18.0; }
		
		// 会摔伤.此路不通
		if (!isPlaneSteep && dSafeHeight < vecDest[2] - vecEndPos[2]) return false
	}
	
	// 终点是否需要蹲下
	duckingEnd = (hull == HULL_HEAD)
	// 路径终点坐标
	end = vecEndPos
	// 路径终点面向
	normal = vecPlaneNormal
	// 如果直立跳崖会跌伤,或终点为下蹲尺寸.则需要蹲跑才能抵达终点
	crouchRun = (!safeHeight || duckingEnd)
	// 路径中间的障碍物高度
	height = z
	
	return true
}

bool:NavPath_Exist2(bool:duckingStart, const Float:start[3], const Float:goal[3], &bool:duckingEnd, Float:end[3], Float:normal[3], &bool:crouchRun, &Float:height)
{
	new planeType
	new bool:isPlaneSteep, bool:startOnSteep
	new Float:z, Float:lastZ, Float:fraction
	new Float:lastPlaneInfo[5][4], Float:lastGround[2]
	new Float:vecSrc[3], Float:vecDest[3], Float:vecPlaneNormal[3], Float:vecTemp[3]
	
	vecSrc[0] = start[0]
	vecSrc[1] = start[1]
	vecSrc[2] = start[2] - 9999.0
	engfunc(EngFunc_TraceHull, start, vecSrc, dTraceIgnore, HULL_HEAD, -1, 0)
	get_tr2(0, TR_vecEndPos, vecSrc)
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
	
	vecDest[0] = goal[0]
	vecDest[1] = goal[1]
	vecDest[2] = vecSrc[2]
	startOnSteep = IsPlaneSteep(vecPlaneNormal[2])
	
	LoopStart:
	
	engfunc(EngFunc_TraceHull, vecSrc, vecDest, dTraceIgnore, HULL_HEAD, -1, 0)
	
	get_tr2(0, TR_flFraction, fraction)
	if (fraction < 1.0)					// 如果射线被障碍物阻挡
	{
		get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
		
		planeType = GetPlaneType(vecPlaneNormal[2])	// 根据障碍物类型(0:天花板,1:倾斜天花板,2:地面,3:倾斜地面,4:墙面)
		
		isPlaneSteep = IsPlaneSteep(vecPlaneNormal[2])
		
		get_tr2(0, TR_vecEndPos, vecSrc)
		
		if (lastPlaneInfo[planeType][3])		// 如果不是第一次被这种地形阻挡
		{
			// 如果这一次的命中点与上一次的命中点相同.说明死循环了.无法前进
			if (VecEqual(vecSrc, lastPlaneInfo[planeType])) return false
			
			// 如果这一个垂直墙壁不等于上一个垂直墙壁.则重新计算跳跃高度
			if (planeType == 4 && 0.0 < fraction) z = 0.0
		}
		
		/* 记住这个地形的坐标 */
		lastPlaneInfo[planeType] = vecSrc
		lastPlaneInfo[planeType][3] = 1.0
		
		switch (planeType)
		{
			case 0:	// 击中天花板
			{
				if (vecDest[0] == vecSrc[0] && vecDest[1] == vecSrc[1])
				{
					vecDest[0] = goal[0]
					vecDest[1] = goal[1]
				}
				vecDest[2] = vecSrc[2]
			}
			case 1:	// 击中倾斜天花板
			{
				if (vecDest[0] == vecSrc[0] && vecDest[1] == vecSrc[1])
				{
					vecDest[0] = goal[0]
					vecDest[1] = goal[1]
				}
				vecDest[2] = InclinedPlaneZ(vecSrc, vecPlaneNormal, vecDest)
			}
			case 2:	// 击中地面
			{
				vecDest[2] = vecSrc[2]
			}
			case 3:	// 击中倾斜地面
			{
				vecDest[2] = InclinedPlaneZ(vecSrc, vecPlaneNormal, vecDest)
				if (!startOnSteep && isPlaneSteep) lastZ = dJumpHeight
			}
			case 4:	// 击中墙面
			{
				// 起点为下蹲尺寸,禁止测试跳跃
				if (duckingStart)
				{
					if (dJumpHeight <= z) return false
				}
				// 跳跃测试的高度已经到达极限,无法越过墙面
				else if (dJumpHeight + 18.0 <= z) return false
				
				if (z == 0.0)
				{
					vecTemp[0] = vecSrc[0]
					vecTemp[1] = vecSrc[1]
					vecTemp[2] = vecSrc[2] - 9999.0
					engfunc(EngFunc_TraceHull, vecSrc, vecTemp, dTraceIgnore, HULL_HEAD, -1, 0)
					
					get_tr2(0, TR_vecEndPos, vecSrc)
					if (vecSrc[0] == lastGround[0] && vecSrc[1] == lastGround[1]) return false
					
					lastGround[0] = vecSrc[0]
					lastGround[1] = vecSrc[1]
				}
				
				z++
				if (lastZ < z) lastZ = z
				
				/* 垂直向上发射轨迹盒.有3种结果:无障碍物/命中倾斜天花板/命中天花板 */
				vecDest[0] = vecSrc[0]
				vecDest[1] = vecSrc[1]
				vecDest[2] = vecSrc[2] + 1.0
			}
		}
		goto LoopStart
	}
	
	if (vecDest[0] == vecSrc[0] && vecDest[1] == vecSrc[1])
	{
		vecSrc[2] = vecDest[2]
		vecDest[0] = goal[0]
		vecDest[1] = goal[1]
		goto LoopStart
	}
	
	vecTemp[0] = vecDest[0]
	vecTemp[1] = vecDest[1]
	vecTemp[2] = vecDest[2] - 9999.0
	engfunc(EngFunc_TraceHull, vecDest, vecTemp, dTraceIgnore, HULL_HEAD, -1, 0)
	
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
	get_tr2(0, TR_vecEndPos, vecTemp)
	
	isPlaneSteep = IsPlaneSteep(vecPlaneNormal[2])
	new bool:safeHeight = vecDest[2] - vecTemp[2] <= dSafeHeight
	
	/* 尝试将坐标提升到与直立玩家的坐标相同的高度 */
	new hull
	vecTemp[2] += 18.0
	engfunc(EngFunc_TraceHull, vecTemp, vecTemp, dTraceIgnore, HULL_HUMAN, -1, 0)
	if (!get_tr2(0, TR_InOpen) || get_tr2(0, TR_AllSolid) || get_tr2(0, TR_StartSolid)) { hull = HULL_HEAD; vecTemp[2] -= 18.0; }
	else hull = HULL_HUMAN
	
	if (isPlaneSteep)	// 终点是陡坡
	{
		// 太陡了
		if (vecPlaneNormal[2] < 0.35) return false
		// 起点是陡坡,起点低于终点.此路不通
		if (startOnSteep && start[2] <= vecTemp[2]) return false
	}
	else			// 终点不是陡坡
	{
		// 会摔伤.此路不通
		if (dSafeHeight < vecDest[2] - vecTemp[2]) return false
	}
	
	// 终点是否需要蹲下
	duckingEnd = (hull == HULL_HEAD)
	// 路径终点坐标
	end = vecTemp
	// 路径终点面向
	normal = vecPlaneNormal
	// 如果路途中顶部有障碍物,或直立跳崖会跌伤而蹲跑不会,或终点为下蹲尺寸.则需要蹲跑才能抵达终点
	//crouchRun = (lastPlaneInfo[0][3] || lastPlaneInfo[1][3] || !safeHeight || ducking)
	// 如果直立跳崖会跌伤,或终点为下蹲尺寸.则需要蹲跑才能抵达终点
	crouchRun = (!safeHeight || duckingEnd)
	// 路径中间的障碍物高度
	height = lastZ
	
	return true
}

NavNode_AutoMerging(bool:longAllowed)
{
	new i, bool:loopEnable
	new iNodeStart, iNodeEnd, bool:ducking
	new Float:normal[2][3], Float:absMin[3][3], Float:absMax[3][3]
	new Float:origin[3], Float:dest[3], Float:mins[3], Float:maxs[3]
	new Float:width[2], Float:height[2]
	new iPath[2]
	new Array:arrayStart, Array:arrayEnd
	
	LoopStart:
	
	if (ArraySize(gArray_NodeDucking) <= iNodeStart)
	{
		if (loopEnable)
		{
			loopEnable = false
			iNodeStart = 0
			goto LoopStart
		}
		
		return
	}
	
	ducking = ArrayGetCell(gArray_NodeDucking, iNodeStart)
	ArrayGetArray(gArray_NodeAbsMin, iNodeStart, absMin[0])
	ArrayGetArray(gArray_NodeAbsMax, iNodeStart, absMax[0])
	ArrayGetArray(gArray_NodeNormal, iNodeStart, normal[0])
	
	width[0] = absMax[0][0] - absMin[0][0]
	height[0] = absMax[0][1] - absMin[0][1]
	
	arrayStart	= ArrayGetCell(gArray_NodeStart,	iNodeStart)
	arrayEnd	= ArrayGetCell(gArray_NodeEnd,		iNodeStart)
	for (iPath[0] = ArraySize(arrayEnd) - 1; 0 <= iPath[0]; iPath[0]--)
	{
		/** 如果iNodeEnd不是iNodeStart的起点之一(如果是单向路径),则不能融合 */
		iNodeEnd = ArrayGetCell(arrayEnd, iPath[0])
		for (iPath[1] = ArraySize(arrayStart) - 1; 0 <= iPath[1] && ArrayGetCell(arrayStart, iPath[1]) != iNodeEnd; iPath[1]--) { }
		if (iPath[1] < 0) continue
		
		// iNodeStart与iNodeEnd的姿态不同,不能融合
		if (ducking != ArrayGetCell(gArray_NodeDucking, iNodeEnd)) continue
		
		// iNodeStart与iNodeEnd的面向不同,不能融合
		ArrayGetArray(gArray_NodeNormal, iNodeEnd, normal[1])
		if (!VecEqual(normal[0], normal[1])) continue
		
		ArrayGetArray(gArray_NodeAbsMin, iNodeEnd, absMin[1])
		ArrayGetArray(gArray_NodeAbsMax, iNodeEnd, absMax[1])
		
		width[1] = absMax[1][0] - absMin[1][0]
		height[1] = absMax[1][1] - absMin[1][1]
		
		// 如果iNodeStart与iNodeEnd的所有横线的minX相等,maxX相等(排列出四行对齐的横线)
		if (absMin[0][0] == absMin[1][0] && absMax[0][0] == absMax[1][0])
		{
			// 如果iNodeStart或iNodeEnd的横线比竖线短,则不能融合
			if (!longAllowed && (width[0] < height[0] || width[1] < height[1])) continue
		}
		// 如果iNodeStart与iNodeEnd的所有竖线的minY相等,maxY相等(排列出四列对齐的竖线)
		else if (absMin[0][1] == absMin[1][1] && absMax[0][1] == absMax[1][1])
		{
			// 如果iNodeStart或iNodeEnd的竖线比横线短,则不能融合
			if (!longAllowed && (height[0] < width[0] || height[1] < width[1])) continue
		}
		// 如果iNodeStart与iNodeEnd的所有横线竖线都不能对齐,则不能融合
		else continue
		
		for (i = 0; i < 3; i++)
		{
			absMin[2][i] = floatmin(absMin[0][i], absMin[1][i])
			absMax[2][i] = floatmax(absMax[0][i], absMax[1][i])
			origin[i] = (absMin[2][i] + absMax[2][i]) * 0.5
			dest[i] = origin[i]
			mins[i] = absMin[2][i] - origin[i]
			maxs[i] = absMax[2][i] - origin[i]
		}
		
		if (NavNode_Merge(iNodeStart, iNodeEnd, origin, absMin[2], absMax[2]) == 1)
		{
			if (iNodeEnd < iNodeStart) iNodeStart--
			
			loopEnable = true
			
			break
		}
	}
	
	iNodeStart++
	goto LoopStart
}

NavNode_Merge(iNode1, iNode2, const Float:origin[3], const Float:absMin[3], const Float:absMax[3])
{
	new Array:arrayStart[3], Array:arrayEnd[3], Array:arrayFlags[3], Array:arrayHeight[3], Array:arrayDistance[3]
	arrayStart[0]		= ArrayGetCell(gArray_NodeStart,	iNode1)
	arrayEnd[0]		= ArrayGetCell(gArray_NodeEnd,		iNode1)
	arrayFlags[0]		= ArrayGetCell(gArray_NodeFlags,	iNode1)
	arrayHeight[0]		= ArrayGetCell(gArray_NodeHeight,	iNode1)
	arrayDistance[0]	= ArrayGetCell(gArray_NodeDistance,	iNode1)
	arrayStart[1]		= ArrayGetCell(gArray_NodeStart,	iNode2)
	arrayEnd[1]		= ArrayGetCell(gArray_NodeEnd,		iNode2)
	arrayFlags[1]		= ArrayGetCell(gArray_NodeFlags,	iNode2)
	arrayHeight[1]		= ArrayGetCell(gArray_NodeHeight,	iNode2)
	arrayDistance[1]	= ArrayGetCell(gArray_NodeDistance,	iNode2)
	
	new iPath, iPath2, iPathTemp, iNodeStart, iNodeEnd, iNodeTemp, Float:p1[3], Float:p2[3], Float:dest[3]
	new flags, height
	
	/** 对iNode1&2进行同样的操作
	 *  如果iNode1&2属于某个单向路径的终点(iNode1&2位于悬崖底部或顶部)
	 *  则不能融合 */
	for (new i = 0; i < 2; i++)
	{
		for (iPath = ArraySize(arrayStart[i]) - 1; 0 <= iPath; iPath--)
		{
			iNodeStart = ArrayGetCell(arrayStart[i], iPath)
			if (iNodeStart == iNode1 || iNodeStart == iNode2) continue
			
			for (iPath2 = ArraySize(arrayEnd[i]) - 1; 0 <= iPath2 && ArrayGetCell(arrayEnd[i], iPath2) != iNodeStart; iPath2--) { }
			// 如果iNodeStart抵达iNode1&2但是无法原路返回(iNodeStart可能在悬崖顶部),则不能融合
			if (iPath2 < 0) return 0
			
			iNodeTemp = -1
			arrayEnd[2] = ArrayGetCell(gArray_NodeEnd, iNodeStart)
			for (iPath2 = ArraySize(arrayEnd[2]) - 1; 0 <= iPath2; iPath2--)
			{
				iNodeEnd = ArrayGetCell(arrayEnd[2], iPath2)
				if (iNodeEnd == (i ? iNode1 : iNode2)) iNodeTemp = iNodeEnd
				if (iNodeEnd == (i ? iNode2 : iNode1)) height = ArrayGetCell(ArrayGetCell(gArray_NodeHeight, iNodeStart), iPath2)
			}
			// 如果iNodeStart的终点不同时包含iNode1和iNode2,并且iNodeStart需要跳跃才能抵达iNode1&2
			if (iNodeTemp < 0 && 0.0 < height)
			{
				ArrayGetArray(gArray_NodePoint, iNode1, p1)
				ArrayGetArray(gArray_NodePoint, iNode2, p2)
				ArrayGetArray(gArray_NodePoint, iNodeStart, dest)
				// 如果iNode1和iNode2位于一个顶面倾斜的悬崖顶部.则不能融合
				if (dest[2] < p1[2] && dest[2] < p2[2] && p1[2] != p2[2]) return -1
			}
		}
	}
	
	/** 如果iNode1和iNode2抵达同一个终点的方式不同
	 *  如果iNode1往返iNode2的方式不同
	 *  则不能融合 */
	for (iPath = ArraySize(arrayEnd[0]) - 1; 0 <= iPath; iPath--)
	{
		iNodeEnd = ArrayGetCell(arrayEnd[0], iPath)
		
		flags	= ArrayGetCell(arrayFlags[0],	iPath)
		height	= ArrayGetCell(arrayHeight[0],	iPath)
		
		for (iPath2 = ArraySize(arrayEnd[1]) - 1; 0 <= iPath2; iPath2--)
		{
			iNodeTemp = ArrayGetCell(arrayEnd[1], iPath2)
			// 如果 iNodeEnd是iNode1和iNode2的共有终点
			if (iNodeTemp == iNodeEnd)
			{
				// 走路姿态不同
				if (ArrayGetCell(arrayFlags[1], iPath2) != flags) return -2
				// 障碍高度不同
				if (ArrayGetCell(arrayHeight[1], iPath2) != height) return -3
				break
			}
			// 否则如果 iNode1与iNode2之间可相互往返
			else if (iNodeEnd == iNode2 && iNodeTemp == iNode1)
			{
				// 走路姿态不同
				if (ArrayGetCell(arrayFlags[1], iPath2) != flags) return -4
				// 障碍高度不同
				if (ArrayGetCell(arrayHeight[1], iPath2) != height) return -5
				break
			}
		}
	}
	
	ArraySetArray(gArray_NodePoint,		iNode1, origin)
	ArraySetArray(gArray_NodeAbsMin,	iNode1, absMin)
	ArraySetArray(gArray_NodeAbsMax,	iNode1, absMax)
	
	/** 遍历iNode1的所有起点,更新他们抵达iNode1的路径长度 */
	for (iPath = ArraySize(arrayStart[0]) - 1; 0 <= iPath; iPath--)
	{
		iNodeStart = ArrayGetCell(arrayStart[0], iPath)
		
		// 起点是iNode2,不需要更新,因为iNode2至iNode1的路径将被删除
		if (iNodeStart == iNode2) continue
		
		arrayEnd[2]		= ArrayGetCell(gArray_NodeEnd,		iNodeStart)
		arrayDistance[2]	= ArrayGetCell(gArray_NodeDistance,	iNodeStart)
		
		ArrayGetArray(gArray_NodePoint, iNodeStart, dest)
		
		for (iPathTemp = ArraySize(arrayEnd[2]) - 1; 0 <= iPathTemp; iPathTemp--)
		{
			if (ArrayGetCell(arrayEnd[2], iPathTemp) == iNode1)
			{
				ArraySetCell(arrayDistance[2],	iPathTemp, VecDistance(origin, dest))
				break
			}
		}
	}
	
	/** 遍历iNode1的所有终点,更新iNode1抵达终点的路径长度 */
	for (iPath = ArraySize(arrayEnd[0]) - 1; 0 <= iPath; iPath--)
	{
		iNodeEnd = ArrayGetCell(arrayEnd[0], iPath)
		
		// 终点是iNode2,不需要更新,因为iNode1至iNode2的路径将被删除
		if (iNodeEnd == iNode2) continue
		
		ArrayGetArray(gArray_NodePoint, iNodeEnd, dest)
		
		ArraySetCell(arrayDistance[0], iPath, VecDistance(origin, dest))
	}
	
	/** 遍历iNode2的所有起点,复制给iNode1,更新他们抵达iNode2的路径终点和路径长度 */
	for (iPath = ArraySize(arrayStart[1]) - 1; 0 <= iPath; iPath--)
	{
		iNodeStart = ArrayGetCell(arrayStart[1], iPath)
		
		// 起点是iNode1,不需要复制,因为iNode1至iNode2的路径将被删除
		if (iNodeStart == iNode1) continue
		
		/** 如果iNode1已经拥有此起点,则无需复制 */
		for (iPath2 = ArraySize(arrayStart[0]) - 1; 0 <= iPath2 && ArrayGetCell(arrayStart[0], iPath2) != iNodeStart; iPath2--) { }
		if (0 <= iPath2) continue
		
		ArrayGetArray(gArray_NodePoint, iNodeStart, dest)
		
		// iNodeStart成为iNode1的起点
		ArrayPushCell(arrayStart[0], iNodeStart)
		
		/** 将iNodeStart至iNode2的路径终点改为iNode1,并更新长度 */
		arrayEnd[2]		= ArrayGetCell(gArray_NodeEnd,		iNodeStart)
		arrayDistance[2]	= ArrayGetCell(gArray_NodeDistance,	iNodeStart)
		
		for (iPathTemp = ArraySize(arrayEnd[2]) - 1; 0 <= iPathTemp; iPathTemp--)
		{
			if (ArrayGetCell(arrayEnd[2], iPathTemp) == iNode2)
			{
				ArraySetCell(arrayEnd[2],	iPathTemp,	iNode1)
				ArraySetCell(arrayDistance[2],	iPathTemp,	VecDistance(origin, dest))
				break
			}
		}
	}
	
	/** 变量iNode2的所有终点,复制给iNode1,更新iNode1抵达终点的路径长度 */
	for (iPath = ArraySize(arrayEnd[1]) - 1; 0 <= iPath; iPath--)
	{
		iNodeEnd = ArrayGetCell(arrayEnd[1], iPath)
		
		// 终点是iNode1,不需要复制,因为iNode2至iNode1的路径将被删除
		if (iNodeEnd == iNode1) continue
		
		/** 如果iNode1已经拥有此终点,则无需复制 */
		for (iPath2 = ArraySize(arrayEnd[0]) - 1; 0 <= iPath2 && ArrayGetCell(arrayEnd[0], iPath2) != iNodeEnd; iPath2--) { }
		if (0 <= iPath2) continue
		
		ArrayGetArray(gArray_NodePoint, iNodeEnd, dest)
		
		/** 将iNodeEnd成为iNode1的终点 */
		ArrayPushCell(arrayEnd[0],	iNodeEnd)
		ArrayPushCell(arrayFlags[0],	ArrayGetCell(arrayFlags[1], iPath))
		ArrayPushCell(arrayHeight[0],	ArrayGetCell(arrayHeight[1], iPath))
		ArrayPushCell(arrayDistance[0],	VecDistance(origin, dest))
		
		/** iNodeEnd的起点依然是iNode2,需要改成iNode1 */
		arrayStart[2]		= ArrayGetCell(gArray_NodeStart,	iNodeEnd)
		
		for (iPathTemp = ArraySize(arrayStart[2]) - 1; 0 <= iPathTemp; iPathTemp--)
		{
			if (ArrayGetCell(arrayStart[2], iPathTemp) == iNode2)
			{
				ArraySetCell(arrayStart[2], iPathTemp, iNode1)
				break
			}
		}
	}
	
	NavNode_Delete(iNode2)
	
	return 1
}

NavNode_GetNearest(const Float:origin[3])
{
	new iNodeSelect = -1
	new i, bool:bContain, Float:dist, Float:lastDist, Float:vecDist[3], Float:vecDest[3]
	new bool:ducking, Float:point[3], Float:absMin[3], Float:absMax[3], Float:normal[3]
	
	for (new iNode = ArraySize(gArray_NodeDucking) - 1; 0 <= iNode; iNode--)
	{
		ducking = ArrayGetCell(gArray_NodeDucking, iNode)
		ArrayGetArray(gArray_NodePoint, iNode, point)
		ArrayGetArray(gArray_NodeAbsMin, iNode, absMin)
		ArrayGetArray(gArray_NodeAbsMax, iNode, absMax)
		ArrayGetArray(gArray_NodeNormal, iNode, normal)
		
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
			if (dist < lastDist || !bContain) { lastDist = dist; bContain = true; iNodeSelect = iNode; }
			continue
		}
		if (bContain) continue
		
		dist =	(vecDist[0]) * (vecDist[0]) +
			(vecDist[1]) * (vecDist[1]) +
			(vecDist[2]) * (vecDist[2])
		
		if (dist < lastDist || iNodeSelect < 0) { lastDist = dist; iNodeSelect = iNode; }
	}
	
	return iNodeSelect
}

NavNode_GetPathCoord(iNodeStart, iNodeEnd, iPath, Float:start[3], Float:mid[3], Float:end[3])
{
	new Float:nodePoint[2][3], Float:absMin[2][3], Float:absMax[2][3], Float:normal[2][3]
	ArrayGetArray(gArray_NodePoint, iNodeStart, nodePoint[0])
	ArrayGetArray(gArray_NodeAbsMin, iNodeStart, absMin[0])
	ArrayGetArray(gArray_NodeAbsMax, iNodeStart, absMax[0])
	ArrayGetArray(gArray_NodeNormal, iNodeStart, normal[0])
	
	ArrayGetArray(gArray_NodePoint, iNodeEnd, nodePoint[1])
	ArrayGetArray(gArray_NodeAbsMin, iNodeEnd, absMin[1])
	ArrayGetArray(gArray_NodeAbsMax, iNodeEnd, absMax[1])
	ArrayGetArray(gArray_NodeNormal, iNodeEnd, normal[1])
	
	for (new j = 0; j < 2; j++)
	{
		if (nodePoint[1][j] < nodePoint[0][j])	mid[j] = floatmin(nodePoint[0][j], floatmax(nodePoint[1][j], (absMax[1][j] + absMin[0][j]) * 0.5))
		else					mid[j] = floatmax(nodePoint[0][j], floatmin(nodePoint[1][j], (absMax[0][j] + absMin[1][j]) * 0.5))
		if (mid[j] == absMin[0][j])		{ start[j] = absMin[0][j] + 16.0; end[j] = absMin[0][j] - 16.0; }
		else if (mid[j] == absMax[0][j])	{ start[j] = absMax[0][j] - 16.0; end[j] = absMax[0][j] + 16.0; }
		else					{ start[j] = end[j] = mid[j]; }
	}
	
	start[2] = InclinedPlaneZ(nodePoint[0], normal[0], start)
	mid[2] = InclinedPlaneZ(nodePoint[0], normal[0], mid) + Float:ArrayGetCell(ArrayGetCell(gArray_NodeHeight, iNodeStart), iPath)
	end[2] = InclinedPlaneZ(nodePoint[1], normal[1], end)
}

NavNode_GetPathCoord2(iNodeStart, iNodeEnd, iPath, &PathFlags:flags, &Float:height, Float:end[3])
{
	flags	= ArrayGetCell(ArrayGetCell(gArray_NodeFlags, iNodeStart), iPath)
	height	= ArrayGetCell(ArrayGetCell(gArray_NodeHeight, iNodeStart), iPath)
	
	new Float:nodePoint[2][3], Float:absMin[2][3], Float:absMax[2][3], Float:normal[2][3], Float:mid[3]
	ArrayGetArray(gArray_NodePoint, iNodeStart, nodePoint[0])
	ArrayGetArray(gArray_NodeAbsMin, iNodeStart, absMin[0])
	ArrayGetArray(gArray_NodeAbsMax, iNodeStart, absMax[0])
	ArrayGetArray(gArray_NodeNormal, iNodeStart, normal[0])
	
	ArrayGetArray(gArray_NodePoint, iNodeEnd, nodePoint[1])
	ArrayGetArray(gArray_NodeAbsMin, iNodeEnd, absMin[1])
	ArrayGetArray(gArray_NodeAbsMax, iNodeEnd, absMax[1])
	ArrayGetArray(gArray_NodeNormal, iNodeEnd, normal[1])
	
	for (new j = 0; j < 2; j++)
	{
		if (nodePoint[1][j] < nodePoint[0][j])	mid[j] = floatmin(nodePoint[0][j], floatmax(nodePoint[1][j], (absMax[1][j] + absMin[0][j]) * 0.5))
		else					mid[j] = floatmax(nodePoint[0][j], floatmin(nodePoint[1][j], (absMax[0][j] + absMin[1][j]) * 0.5))
		if (mid[j] == absMin[0][j])		end[j] = absMin[0][j] - 16.0
		else if (mid[j] == absMax[0][j])	end[j] = absMax[0][j] + 16.0
		else					end[j] = mid[j]
	}
	
	end[2] = InclinedPlaneZ(nodePoint[1], normal[1], end)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg936\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset134 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2052\\ f0\\ fs16 \n\\ par }
*/
