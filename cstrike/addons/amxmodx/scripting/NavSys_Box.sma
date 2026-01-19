/* UTF-8 func by www.DT-Club.net */

/* === PATCH NavSys_Box: safe destroy + bounds check (v1) === */

new Float:gMapAbsMin[3], Float:gMapAbsMax[3]
new Array:gArray_XBox = Invalid_Array   // FIX: явная инициализация

NavBox_Draw(id, const Float:absMin[3], const Float:absMax[3], life, width, noise, r, g, b)
{
	new Float:point[8][3]
	point[0][0] = absMax[0]
	point[0][1] = absMax[1]
	point[0][2] = absMax[2]
	point[1][0] = absMin[0]
	point[1][1] = absMax[1]
	point[1][2] = absMax[2]
	point[2][0] = absMin[0]
	point[2][1] = absMin[1]
	point[2][2] = absMax[2]
	point[3][0] = absMax[0]
	point[3][1] = absMin[1]
	point[3][2] = absMax[2]
	point[4][0] = absMax[0]
	point[4][1] = absMax[1]
	point[4][2] = absMin[2]
	point[5][0] = absMin[0]
	point[5][1] = absMax[1]
	point[5][2] = absMin[2]
	point[6][0] = absMin[0]
	point[6][1] = absMin[1]
	point[6][2] = absMin[2]
	point[7][0] = absMax[0]
	point[7][1] = absMin[1]
	point[7][2] = absMin[2]
	SendMsg_BeamPoints(id, point[0], point[1], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[1], point[2], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[2], point[3], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[3], point[0], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[4], point[5], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[5], point[6], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[6], point[7], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[7], point[4], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[0], point[4], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[1], point[5], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[2], point[6], gMdlId_BeamNode, life, width, noise, r, g, b)
	SendMsg_BeamPoints(id, point[3], point[7], gMdlId_BeamNode, life, width, noise, r, g, b)
}

bool:NavBox_Exist(const Float:origin[3])
{
	return	(gMapAbsMin[0] <= origin[0] < gMapAbsMax[0]) &&
		(gMapAbsMin[1] <= origin[1] < gMapAbsMax[1]) &&
		(gMapAbsMin[2] <= origin[2] < gMapAbsMax[2])
}

NavBox_AddNode(nodeIndex)
{
	NavBox_DestroyGrid();
	/** 以下代码:将导航点分配到有所接触的盒子 */
	new Float:absMin[3], Float:absMax[3], Float:boxAbsMin[3], Float:boxAbsMax[3], Float:nodePoint[3]
	ArrayGetArray(gArray_NodeAbsMin, nodeIndex, absMin)
	ArrayGetArray(gArray_NodeAbsMax, nodeIndex, absMax)
	
	new bool:boxExist = true
	for (new i; i < 3; i++)
	{
		boxAbsMin[i] = 128.0 * floatround(absMin[i] / 128.0, floatround_floor)
		boxAbsMax[i] = 128.0 * floatround(absMax[i] / 128.0, floatround_ceil)
		if (boxAbsMin[i] < gMapAbsMin[i] || gMapAbsMax[i] < boxAbsMax[i]) boxExist = false
	}
	
	if (boxExist)
	{
		// 节点最多能接触8个盒子
		for (nodePoint[2] = boxAbsMin[2]; nodePoint[2] < boxAbsMax[2]; nodePoint[2] += 128.0)
		{
			for (nodePoint[1] = boxAbsMin[1]; nodePoint[1] < boxAbsMax[1]; nodePoint[1] += 128.0)
			{
				for (nodePoint[0] = boxAbsMin[0]; nodePoint[0] < boxAbsMax[0]; nodePoint[0] += 128.0)
				{
					ArrayPushCell(NavBox_GetNodeArray(nodePoint), nodeIndex)
				}
			}
		}
		return
	}
	/** 以上代码:将导航点分配到有所接触的盒子 */
	
	/** 以下代码:销毁所有盒子 */
	new x, y, z, Array:arrayYBox, Array:arrayZBox, Array:arrayBox
	if (gArray_XBox != Invalid_Array)
	{
		for (x = ArraySize(gArray_XBox) - 1; 0 <= x; x--)
		{
			arrayYBox = ArrayGetCell(gArray_XBox, x)
			for (y = ArraySize(arrayYBox) - 1; 0 <= y; y--)
			{
				arrayZBox = ArrayGetCell(arrayYBox, y)
				for (z = ArraySize(arrayZBox) - 1; 0 <= z; z--)
				{
					arrayBox = ArrayGetCell(arrayZBox, z)
					ArrayDestroy(arrayBox)
					gArray_XBox = Invalid_Array; // FIX
				}
				ArrayDestroy(arrayZBox)
			}
			ArrayDestroy(arrayYBox)
		}
		ArrayDestroy(gArray_XBox)
		gArray_XBox = Invalid_Array; // FIX
	}
	/** 以上代码:销毁所有盒子 */
	
	/** 以下代码:更新地图盒子尺寸,计算各轴盒子数量 */
	new boxNums[3]
	for (new i; i < 3; i++)
	{
		if (gMapAbsMin[i] == gMapAbsMax[i])
		{
			gMapAbsMin[i] = boxAbsMin[i]
			gMapAbsMax[i] = boxAbsMax[i]
		}
		else
		{
			if (boxAbsMin[i] < gMapAbsMin[i]) gMapAbsMin[i] = boxAbsMin[i]
			if (gMapAbsMax[i] < boxAbsMax[i]) gMapAbsMax[i] = boxAbsMax[i]
		}
		
		boxNums[i] = floatround((gMapAbsMax[i] - gMapAbsMin[i]) / 128.0)
	}
	/** 以上代码:更新地图盒子尺寸,计算各轴盒子数量 */
	
	/** 以下代码:重新创建盒子 */
	gArray_XBox = ArrayCreate(1, boxNums[0])
	for (x = 0; x < boxNums[0]; x++)
	{
		arrayYBox = ArrayCreate(1, boxNums[1])
		for (y = 0; y < boxNums[1]; y++)
		{
			arrayZBox = ArrayCreate(1, boxNums[2])
			for (z = 0; z < boxNums[2]; z++) ArrayPushCell(arrayZBox, ArrayCreate())
			ArrayPushCell(arrayYBox, arrayZBox)
		}
		ArrayPushCell(gArray_XBox, arrayYBox)
	}
	/** 以上代码:重新创建盒子 */
	
	/** 以下代码:将所有导航点分配到有所接触的盒子内 */
	for (new i = ArraySize(gArray_NodeAbsMin) - 1; 0 <= i; i--)
	{
		ArrayGetArray(gArray_NodeAbsMin, i, absMin)
		ArrayGetArray(gArray_NodeAbsMax, i, absMax)
		for (new j; j < 3; j++)
		{
			boxAbsMin[j] = 128.0 * floatround(absMin[j] / 128.0, floatround_floor)
			boxAbsMax[j] = 128.0 * floatround(absMax[j] / 128.0, floatround_ceil)
		}
		// 每个节点最多能接触8个盒子
		for (nodePoint[2] = boxAbsMin[2]; nodePoint[2] < boxAbsMax[2]; nodePoint[2] += 128.0)
		{
			for (nodePoint[1] = boxAbsMin[1]; nodePoint[1] < boxAbsMax[1]; nodePoint[1] += 128.0)
			{
				for (nodePoint[0] = boxAbsMin[0]; nodePoint[0] < boxAbsMax[0]; nodePoint[0] += 128.0)
				{
					ArrayPushCell(NavBox_GetNodeArray(nodePoint), i)
				}
			}
		}
	}
	/** 以上代码:将所有导航点分配到有所接触的盒子内 */
}

NavBox_Update()
{
    // вместо ручного destroy - используем безопасный
    NavBox_DestroyGrid();

    new i, j, boxNums[3];
    new Float:absMin[3], Float:absMax[3], Float:boxAbsMin[3], Float:boxAbsMax[3];

    // FIX: корректная инициализация границ
    new bool:first = true;

    for (i = ArraySize(gArray_NodePoint) - 1; 0 <= i; i--)
    {
        ArrayGetArray(gArray_NodeAbsMin, i, absMin);
        ArrayGetArray(gArray_NodeAbsMax, i, absMax);

        for (j = 0; j < 3; j++)
        {
            boxAbsMin[j] = 128.0 * floatround(absMin[j] / 128.0, floatround_floor);
            boxAbsMax[j] = 128.0 * floatround(absMax[j] / 128.0, floatround_ceil);

            if (first)
            {
                gMapAbsMin[j] = boxAbsMin[j];
                gMapAbsMax[j] = boxAbsMax[j];
            }
            else
            {
                if (boxAbsMin[j] < gMapAbsMin[j]) gMapAbsMin[j] = boxAbsMin[j];
                if (gMapAbsMax[j] < boxAbsMax[j]) gMapAbsMax[j] = boxAbsMax[j];
            }
        }
        first = false;
    }

    if (first)
    {
        // нет нодов
        gMapAbsMin[0] = gMapAbsMin[1] = gMapAbsMin[2] = 0.0;
        gMapAbsMax[0] = gMapAbsMax[1] = gMapAbsMax[2] = 0.0;
        gArray_XBox = Invalid_Array;
        return;
    }
for (j = 0; j < 3; j++)
        boxNums[j] = floatround((gMapAbsMax[j] - gMapAbsMin[j]) / 128.0);

    if (boxNums[0] <= 0 || boxNums[1] <= 0 || boxNums[2] <= 0)
    {
        gArray_XBox = Invalid_Array;
        return;
    }

    // пересоздание боксов (как было)
    new x, y, z, Array:arrayYBox, Array:arrayZBox;
    gArray_XBox = ArrayCreate(1, boxNums[0]);
    for (x = 0; x < boxNums[0]; x++)
    {
        arrayYBox = ArrayCreate(1, boxNums[1]);
        for (y = 0; y < boxNums[1]; y++)
        {
            arrayZBox = ArrayCreate(1, boxNums[2]);
            for (z = 0; z < boxNums[2]; z++) ArrayPushCell(arrayZBox, ArrayCreate());
            ArrayPushCell(arrayYBox, arrayZBox);
        }
        ArrayPushCell(gArray_XBox, arrayYBox);
    }

    // распределение нодов по боксам (добавить CHECK на Invalid_Array)
    new Float:nodePoint[3];
    for (i = ArraySize(gArray_NodeAbsMin) - 1; 0 <= i; i--)
    {
        ArrayGetArray(gArray_NodeAbsMin, i, absMin);
        ArrayGetArray(gArray_NodeAbsMax, i, absMax);

        for (j = 0; j < 3; j++)
        {
            boxAbsMin[j] = 128.0 * floatround(absMin[j] / 128.0, floatround_floor);
            boxAbsMax[j] = 128.0 * floatround(absMax[j] / 128.0, floatround_ceil);
        }

        for (nodePoint[2] = boxAbsMin[2]; nodePoint[2] < boxAbsMax[2]; nodePoint[2] += 128.0)
        for (nodePoint[1] = boxAbsMin[1]; nodePoint[1] < boxAbsMax[1]; nodePoint[1] += 128.0)
        for (nodePoint[0] = boxAbsMin[0]; nodePoint[0] < boxAbsMax[0]; nodePoint[0] += 128.0)
        {
            new Array:cell = NavBox_GetNodeArray(nodePoint);
            if (cell != Invalid_Array) ArrayPushCell(cell, i); // FIX: не пушим в Invalid_Array
        }
    }
}

// --- FIX: make NavBox_GetNodeArray safe ---
Array:NavBox_GetNodeArray(const Float:origin[3])
{
    if (gArray_XBox == Invalid_Array) return Invalid_Array;

    new xId = floatround((origin[0] - gMapAbsMin[0]) / 128.0, floatround_floor);
    new yId = floatround((origin[1] - gMapAbsMin[1]) / 128.0, floatround_floor);
    new zId = floatround((origin[2] - gMapAbsMin[2]) / 128.0, floatround_floor);

    // bounds check (prevents ArrayGetCell out-of-range)
    if (xId < 0 || yId < 0 || zId < 0) return Invalid_Array;

    new xSize = ArraySize(gArray_XBox);
    if (xId >= xSize) return Invalid_Array;

    new Array:arrayYBox = ArrayGetCell(gArray_XBox, xId);
    if (arrayYBox == Invalid_Array) return Invalid_Array;

    new ySize = ArraySize(arrayYBox);
    if (yId >= ySize) return Invalid_Array;

    new Array:arrayZBox = ArrayGetCell(arrayYBox, yId);
    if (arrayZBox == Invalid_Array) return Invalid_Array;

    new zSize = ArraySize(arrayZBox);
    if (zId >= zSize) return Invalid_Array;

    return ArrayGetCell(arrayZBox, zId);
}

NavBox_GetContain(const Float:origin[3], Float:absMin[3], Float:absMax[3])
{
	for (new i; i < 3; i++)
	{
		absMin[i] = 128.0 * floatround(origin[i] / 128.0, floatround_floor)
		absMax[i] = absMin[i] + 128.0
	}
}

NavBox_GetNearest(const Float:origin[3], Float:absMin[3], Float:absMax[3])
{
	for (new i; i < 3; i++)
	{
		if (origin[i] < gMapAbsMin[i])
		{
			absMin[i] = gMapAbsMin[i]
			absMax[i] = gMapAbsMax[i] + 128.0
		}
		else if (gMapAbsMax[i] <= origin[i])
		{
			absMin[i] = gMapAbsMax[i] - 128.0
			absMax[i] = gMapAbsMax[i]
		}
		else
		{
			absMin[i] = 128.0 * floatround(origin[i] / 128.0, floatround_floor)
			absMax[i] = absMin[i] + 128.0
		}
	}
}

NavBox_GetNode(const Float:origin[3]) 
{
	new iNodeSelect = NavBox_GetNodeNearest(origin)
	if (0 <= iNodeSelect)
	{
		new bool:ducking, Float:point[3], Float:absMin[3], Float:absMax[3], Float:normal[3]
		ducking = ArrayGetCell(gArray_NodeDucking, iNodeSelect)
		ArrayGetArray(gArray_NodePoint, iNodeSelect, point)
		ArrayGetArray(gArray_NodeAbsMin, iNodeSelect, absMin)
		ArrayGetArray(gArray_NodeAbsMax, iNodeSelect, absMax)
		ArrayGetArray(gArray_NodeNormal, iNodeSelect, normal)
		absMin[2] = InclinedPlaneZ(point, normal, origin) - (ducking ? 18.0 : 36.0)
		absMax[2] = absMin[2] + (ducking ? 36.0 : 72.0)
		point[2] = (absMin[2] + absMax[2]) * 0.5
		new Float:dist1 = (point[2] - origin[2]) * (point[2] - origin[2])
		new Float:dist2
		new Float:vecDist[3]
		new Float:lastDist
		new iNodeSelect2 = -1
		
		new Array:arrayStart = ArrayGetCell(gArray_NodeStart, iNodeSelect)
		new Array:arrayEnd, Array:arrayHeight
		new i, j, k, iNodeStart
		for (i = ArraySize(arrayStart) - 1; 0 <= i; i--)
		{
			iNodeStart = ArrayGetCell(arrayStart, i)
			arrayEnd = ArrayGetCell(gArray_NodeEnd, iNodeStart)
			arrayHeight = ArrayGetCell(gArray_NodeHeight, iNodeStart)
			for (j = ArraySize(arrayEnd) - 1; 0 <= j; j--)
			{
				if (ArrayGetCell(arrayEnd, j) == iNodeSelect)
				{
					if (0.0 < Float:ArrayGetCell(arrayHeight, j))
					{
						ducking = ArrayGetCell(gArray_NodeDucking, iNodeStart)
						ArrayGetArray(gArray_NodePoint, iNodeStart, point)
						ArrayGetArray(gArray_NodeAbsMin, iNodeStart, absMin)
						ArrayGetArray(gArray_NodeAbsMax, iNodeStart, absMax)
						ArrayGetArray(gArray_NodeNormal, iNodeStart, normal)
						absMin[2] = InclinedPlaneZ(point, normal, origin) - (ducking ? 18.0 : 36.0)
						absMax[2] = absMin[2] + (ducking ? 36.0 : 72.0)
						point[2] = (absMin[2] + absMax[2]) * 0.5
						dist2 = (point[2] - origin[2]) * (point[2] - origin[2])
						if (dist2 <= dist1)
						{
							for (k = 0; k < 3; k++)
							{
								if (absMax[k] < origin[k])	vecDist[k] = origin[k] - absMax[k]
								else if (origin[k] < absMin[k])	vecDist[k] = absMin[k] - origin[k]
								else				vecDist[k] = 0.0
							}
							
							dist2 =	(vecDist[0]) * (vecDist[0]) +
								(vecDist[1]) * (vecDist[1]) +
								(vecDist[2]) * (vecDist[2])
							
							if (dist2 < lastDist || iNodeSelect2 < 0) { lastDist = dist2; iNodeSelect2 = iNodeStart; }
						}
					}
					break
				}
			}
		}
		if (0 <= iNodeSelect2) return iNodeSelect2
	}
	return iNodeSelect
}

NavBox_GetNodeNearest(const Float:origin[3])
{
	if (!ArraySize(gArray_NodeDucking)) return -1
	
	new i, Float:point[3]
	for (; i < 3; i++)
	{
		if (origin[i] < gMapAbsMin[i])		point[i] = gMapAbsMin[i]
		else if (gMapAbsMax[i] <= origin[i])	point[i] = gMapAbsMax[i] - 128.0
		else					point[i] = 128.0 * floatround(origin[i] / 128.0, floatround_floor)
	}
	
	new Array:cell = NavBox_GetNodeArray(point);
	if (cell == Invalid_Array) return -1; // FIX
	new iNodeSelect = _GetNodeNearest(cell, origin);

	if (0 <= iNodeSelect) return iNodeSelect
	
	new bool:boxExist = true
	new Float:boxCoord[3], Float:boxAbsMin[3], Float:boxAbsMax[3]
	new iNode, Float:dist, Float:lastDist
	new layers
	for (layers = 1; boxExist; layers++)
	{
		for (i = 0; i < 3; i++)
		{
			boxAbsMin[i] = point[i] - 128.0 * layers
			boxAbsMax[i] = point[i] + 128.0 * layers
		}
		
		boxExist = false
		
		// 底面
		if (gMapAbsMin[2] <= boxAbsMin[2])
		{
			boxCoord[2] = boxAbsMin[2]
			for (boxCoord[1] = boxAbsMin[1] + 128.0; boxCoord[1] < boxAbsMax[1] - 128.0; boxCoord[1] += 128.0)
			{
				if (boxCoord[1] < gMapAbsMin[1]) continue
				if (gMapAbsMax[1] <= boxCoord[1]) break
				
				for (boxCoord[0] = boxAbsMin[0] + 128.0; boxCoord[0] < boxAbsMax[0] - 128.0; boxCoord[0] += 128.0)
				{
					if (boxCoord[0] < gMapAbsMin[0]) continue
					if (gMapAbsMax[0] <= boxCoord[0]) break
					
					boxExist = true
					
					iNode = _GetNodeNearest2(NavBox_GetNodeArray(boxCoord), origin, dist)
					
					if (0 <= iNode && (dist < lastDist || iNodeSelect < 0)) { lastDist = dist; iNodeSelect = iNode; }
				}
			}
		}
		// 顶面
		if (boxAbsMax[2] < gMapAbsMax[2])
		{
			boxCoord[2] = boxAbsMax[2]
			for (boxCoord[1] = boxAbsMin[1] + 128.0; boxCoord[1] < boxAbsMax[1] - 128.0; boxCoord[1] += 128.0)
			{
				if (boxCoord[1] < gMapAbsMin[1]) continue
				if (gMapAbsMax[1] <= boxCoord[1]) break
				
				for (boxCoord[0] = boxAbsMin[0] + 128.0; boxCoord[0] < boxAbsMax[0] - 128.0; boxCoord[0] += 128.0)
				{
					if (boxCoord[0] < gMapAbsMin[0]) continue
					if (gMapAbsMax[0] <= boxCoord[0]) break
					
					boxExist = true
					
					iNode = _GetNodeNearest2(NavBox_GetNodeArray(boxCoord), origin, dist)
					
					if (0 <= iNode && (dist < lastDist || iNodeSelect < 0)) { lastDist = dist; iNodeSelect = iNode; }
				}
			}
		}
		// 南面
		if (gMapAbsMin[1] <= boxAbsMin[1])
		{
			boxCoord[1] = boxAbsMin[1]
			for (boxCoord[2] = boxAbsMin[2]; boxCoord[2] < boxAbsMax[2]; boxCoord[2] += 128.0)
			{
				if (boxCoord[2] < gMapAbsMin[2]) continue
				if (gMapAbsMax[2] <= boxCoord[2]) break
				
				for (boxCoord[0] = boxAbsMin[0]; boxCoord[0] < boxAbsMax[0] - 128.0; boxCoord[0] += 128.0)
				{
					if (boxCoord[0] < gMapAbsMin[0]) continue
					if (gMapAbsMax[0] <= boxCoord[0]) break
					
					boxExist = true
					
					iNode = _GetNodeNearest2(NavBox_GetNodeArray(boxCoord), origin, dist)
					
					if (0 <= iNode && (dist < lastDist || iNodeSelect < 0)) { lastDist = dist; iNodeSelect = iNode; }
				}
			}
		}
		// 北面
		if (boxAbsMax[1] < gMapAbsMax[1])
		{
			boxCoord[1] = boxAbsMax[1]
			for (boxCoord[2] = boxAbsMin[2]; boxCoord[2] < boxAbsMax[2]; boxCoord[2] += 128.0)
			{
				if (boxCoord[2] < gMapAbsMin[2]) continue
				if (gMapAbsMax[2] <= boxCoord[2]) break
				
				for (boxCoord[0] = boxAbsMax[0] - 128.0; boxAbsMin[0] < boxCoord[0]; boxCoord[0] -= 128.0)
				{
					if (boxCoord[0] < gMapAbsMin[0]) continue
					if (gMapAbsMax[0] <= boxCoord[0]) break
					
					boxExist = true
					
					iNode = _GetNodeNearest2(NavBox_GetNodeArray(boxCoord), origin, dist)
					
					if (0 <= iNode && (dist < lastDist || iNodeSelect < 0)) { lastDist = dist; iNodeSelect = iNode; }
				}
			}
		}
		// 西面
		if (gMapAbsMin[0] <= boxAbsMin[0])
		{
			boxCoord[0] = boxAbsMin[0]
			for (boxCoord[2] = boxAbsMin[2]; boxCoord[2] < boxAbsMax[2]; boxCoord[2] += 128.0)
			{
				if (boxCoord[2] < gMapAbsMin[2]) continue
				if (gMapAbsMax[2] <= boxCoord[2]) break
				
				for (boxCoord[1] = boxAbsMax[1] - 128.0; boxAbsMin[1] < boxCoord[1]; boxCoord[1] -= 128.0)
				{
					if (boxCoord[1] < gMapAbsMin[1]) continue
					if (gMapAbsMax[1] <= boxCoord[1]) break
					
					boxExist = true
					
					iNode = _GetNodeNearest2(NavBox_GetNodeArray(boxCoord), origin, dist)
					
					if (0 <= iNode && (dist < lastDist || iNodeSelect < 0)) { lastDist = dist; iNodeSelect = iNode; }
				}
			}
		}
		// 东面
		if (boxAbsMax[0] < gMapAbsMax[0])
		{
			boxCoord[0] = boxAbsMax[0]
			for (boxCoord[2] = boxAbsMin[2]; boxCoord[2] < boxAbsMax[2]; boxCoord[2] += 128.0)
			{
				if (boxCoord[2] < gMapAbsMin[2]) continue
				if (gMapAbsMax[2] <= boxCoord[2]) break
				
				for (boxCoord[1] = boxAbsMin[1]; boxCoord[1] < boxAbsMax[1] - 128.0; boxCoord[1] += 128.0)
				{
					if (boxCoord[1] < gMapAbsMin[1]) continue
					if (gMapAbsMax[1] <= boxCoord[1]) break
					
					boxExist = true
					
					iNode = _GetNodeNearest2(NavBox_GetNodeArray(boxCoord), origin, dist)
					
					if (0 <= iNode && (dist < lastDist || iNodeSelect < 0)) { lastDist = dist; iNodeSelect = iNode; }
				}
			}
		}
		if (0 <= iNodeSelect) return iNodeSelect
	}
	
	return -1
}

_GetNodeNearest(Array:arrayNode, const Float:origin[3])
{
	new j, iNode, iNodeSelect = -1
	new bool:bContain
	new Float:dist, Float:lastDist, Float:bottom, Float:height, Float:vecDist[3], Float:vecDest[3]
	new bool:ducking, Float:point[3], Float:absMin[3], Float:absMax[3], Float:normal[3]
	for (new i = ArraySize(arrayNode) - 1; 0 <= i; i--)
	{
		iNode = ArrayGetCell(arrayNode, i)
		
		ducking = ArrayGetCell(gArray_NodeDucking, iNode)
		ArrayGetArray(gArray_NodePoint, iNode, point)
		ArrayGetArray(gArray_NodeAbsMin, iNode, absMin)
		ArrayGetArray(gArray_NodeAbsMax, iNode, absMax)
		ArrayGetArray(gArray_NodeNormal, iNode, normal)
		
		for (j = 0; j < 2; j++)
		{
			if (origin[j] < absMin[j])	{ vecDist[j] = absMin[j] - origin[j];	vecDest[j] = absMin[j]; }
			else if (absMax[j] < origin[j])	{ vecDist[j] = origin[j] - absMax[j];	vecDest[j] = absMax[j]; }
			else				{ vecDist[j] = 0.0;			vecDest[j] = origin[j]; }
		}
		
		point[2] -= ducking ? 18.0 : 36.0
		bottom = InclinedPlaneZ(point, normal, vecDest)
		height = bottom + (ducking ? 36.0 : 72.0)
		if (origin[2] < bottom)		vecDist[2] = bottom - origin[2]
		else if (height < origin[2])	vecDist[2] = origin[2] - height
		else				vecDist[2] = 0.0
		
		if (vecDist[0] == 0.0 && vecDist[1] == 0.0 && vecDist[2] == 0.0)
		{
			dist = ((height + bottom) * 0.5 - origin[2]) * ((height + bottom) * 0.5 - origin[2])
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

_GetNodeNearest2(Array:arrayNode, const Float:origin[3], &Float:distance)
{
	distance = 0.0
	
	new j, iNode, iNodeSelect = -1
	new Float:dist, Float:bottom, Float:height, Float:vecDist[3], Float:vecDest[3]
	new bool:ducking, Float:point[3], Float:absMin[3], Float:absMax[3], Float:normal[3]
	for (new i = ArraySize(arrayNode) - 1; 0 <= i; i--)
	{
		iNode = ArrayGetCell(arrayNode, i)
		
		ducking = ArrayGetCell(gArray_NodeDucking, iNode)
		ArrayGetArray(gArray_NodePoint, iNode, point)
		ArrayGetArray(gArray_NodeAbsMin, iNode, absMin)
		ArrayGetArray(gArray_NodeAbsMax, iNode, absMax)
		ArrayGetArray(gArray_NodeNormal, iNode, normal)
		
		for (j = 0; j < 2; j++)
		{
			if (origin[j] < absMin[j])	{ vecDist[j] = absMin[j] - origin[j];	vecDest[j] = absMin[j]; }
			else if (absMax[j] < origin[j])	{ vecDist[j] = origin[j] - absMax[j];	vecDest[j] = absMax[j]; }
			else				{ vecDist[j] = 0.0;			vecDest[j] = origin[j]; }
		}
		
		point[2] -= ducking ? 18.0 : 36.0
		bottom = InclinedPlaneZ(point, normal, vecDest)
		height = bottom + (ducking ? 36.0 : 72.0)
		if (origin[2] < bottom)		vecDist[2] = bottom - origin[2]
		else if (height < origin[2])	vecDist[2] = origin[2] - height
		else				vecDist[2] = 0.0
		
		dist =	(vecDist[0]) * (vecDist[0]) +
			(vecDist[1]) * (vecDist[1]) +
			(vecDist[2]) * (vecDist[2])
		
		if (dist < distance || iNodeSelect < 0) { distance = dist; iNodeSelect = iNode; }
	}
	return iNodeSelect
}

NavBox_GetNodeContain(const Float:origin[3])
{
	new bool:ducking
	new Float:absMin[3], Float:absMax[3], Float:point[3], Float:normal[3], Float:vecDest[3]
	new iNode, Array:arrayNode = NavBox_GetNodeArray(origin)

	if (arrayNode == Invalid_Array) return -1; // FIX

	for (new i = ArraySize(arrayNode) - 1; 0 <= i; i--)
	{
		iNode = ArrayGetCell(arrayNode, i)
		ArrayGetArray(gArray_NodeAbsMin, iNode, absMin)
		if (origin[0] < absMin[0]) continue
		if (origin[1] < absMin[1]) continue
		ArrayGetArray(gArray_NodeAbsMax, iNode, absMax)
		if (absMax[0] <= origin[0]) continue
		if (absMax[1] <= origin[1]) continue
		
		ducking = ArrayGetCell(gArray_NodeDucking, iNode)
		ArrayGetArray(gArray_NodePoint, iNode, point)
		ArrayGetArray(gArray_NodeNormal, iNode, normal)
		
		point[2] -= ducking ? 18.0 : 36.0
		vecDest[0] = origin[0]
		vecDest[1] = origin[1]
		vecDest[2] = InclinedPlaneZ(point, normal, vecDest)
		if (origin[2] < vecDest[2]) continue
		vecDest[2] += ducking ? 36.0 : 72.0
		if (vecDest[2] <= origin[2]) continue
		
		return iNode
	}
	return -1
}

NavBox_GetNodeIntersect(const Float:absMin[3], const Float:absMax[3])
{
	new i, Float:center[3], Float:boxAbsMin[3], Float:boxAbsMax[3]
	for (; i < 3; i++)
	{
		boxAbsMin[i] = floatmax(gMapAbsMin[i], 128.0 * floatround(absMin[i] / 128.0, floatround_floor))
		boxAbsMax[i] = floatmin(gMapAbsMax[i], 128.0 * floatround(absMax[i] / 128.0, floatround_ceil))
		center[i] = (absMin[i] + absMax[i]) * 0.5
	}
	
	new j, iNode, iNodeSelect = -1
	new bool:bContain
	new Array:arrayNode
	new Float:dist, Float:lastDist
	new Float:boxCoord[3], Float:vecDist[3]
	new bool:ducking, Float:nodeAbsMin[3], Float:nodeAbsMax[3], Float:nodePoint[3], Float:nodeNormal[3]
	
	for (boxCoord[2] = boxAbsMin[2]; boxCoord[2] < boxAbsMax[2]; boxCoord[2] += 128.0)
	{
		for (boxCoord[1] = boxAbsMin[1]; boxCoord[1] < boxAbsMax[1]; boxCoord[1] += 128.0)
		{
			for (boxCoord[0] = boxAbsMin[0]; boxCoord[0] < boxAbsMax[0]; boxCoord[0] += 128.0)
			{
				if (!NavBox_Exist(boxCoord)) continue
				
				arrayNode = NavBox_GetNodeArray(boxCoord);
				if (arrayNode == Invalid_Array) continue;

				for (i = ArraySize(arrayNode) - 1; 0 <= i; i--)
				{
					iNode = ArrayGetCell(arrayNode, i)
					
					ArrayGetArray(gArray_NodeAbsMin, iNode, nodeAbsMin)
					if (absMax[0] < nodeAbsMin[0]) continue
					if (absMax[1] < nodeAbsMin[1]) continue
					ArrayGetArray(gArray_NodeAbsMax, iNode, nodeAbsMax)
					if (nodeAbsMax[0] <= absMin[0]) continue
					if (nodeAbsMax[1] <= absMin[1]) continue
					
					ducking = ArrayGetCell(gArray_NodeDucking, iNode)
					ArrayGetArray(gArray_NodePoint, iNode, nodePoint)
					ArrayGetArray(gArray_NodeNormal, iNode, nodeNormal)
					
					nodePoint[2] -= ducking ? 18.0 : 36.0
					nodeAbsMin[2] = InclinedPlaneZ(nodePoint, nodeNormal, center)
					nodeAbsMax[2] = nodeAbsMin[2] + (ducking ? 36.0 : 72.0)
					
					if (absMax[2] < nodeAbsMin[2]) continue
					if (nodeAbsMax[2] <= absMin[2]) continue
					
					if (	nodeAbsMin[0] <= center[0] < nodeAbsMax[0] && 
						nodeAbsMin[1] <= center[1] < nodeAbsMax[1] &&
						nodeAbsMin[2] <= center[2] < nodeAbsMax[2] )
					{
						dist = ((nodeAbsMin[2] + nodeAbsMax[2]) * 0.5 - center[2]) * ((nodeAbsMin[2] + nodeAbsMax[2]) * 0.5 - center[2])
						if (dist < lastDist || !bContain) { lastDist = dist; bContain = true; iNodeSelect = iNode; }
						continue
					}
					if (bContain) continue
					
					for (j = 0; j < 3; j++)
					{
						if (nodeAbsMax[j] < absMin[j])		vecDist[j] = absMin[j] - nodeAbsMax[j]
						else if (absMax[j] < nodeAbsMin[j])	vecDist[j] = nodeAbsMin[j] - absMax[j]
						else					vecDist[j] = 0.0
					}
					
					dist =	(vecDist[0]) * (vecDist[0]) +
						(vecDist[1]) * (vecDist[1]) +
						(vecDist[2]) * (vecDist[2])
					
					if (dist < lastDist || iNodeSelect < 0) { lastDist = dist; iNodeSelect = iNode; }
				}
			}
		}
	}
	return iNodeSelect
}

NavBox_GetNodeInFront(id)
{
	if (gArray_XBox == Invalid_Array) return -1
	
	new i, j, loop, Float:rayLength, Float:dist, Float:lastDist = -1.0
	new Float:rayStart[3], Float:rayDir[3], Float:rayEnd[3], Float:lastRayEnd[3], Float:boxAbsMin[3], Float:boxAbsMax[3]
	
	pev(id, pev_origin, rayStart)
	pev(id, pev_view_ofs, rayDir)
	VecAdd(rayStart, rayDir, rayStart)
	pev(id, pev_v_angle, rayDir)
	AngleVector(rayDir, ANGLEVECTOR_FORWARD, rayDir)
	VecAddScaled(rayStart, rayDir, 9999.0, rayEnd)
	NavSys_Trace(rayStart, rayEnd, -1)
	get_tr2(0, TR_vecEndPos, rayEnd)
	
	rayLength = VecDistance(rayStart, rayEnd)
	
	if (NavBox_Exist(rayStart)) NavBox_GetNearest(rayStart, boxAbsMin, boxAbsMax)
	else
	{
		for (i = 0; i < 3; i++)
		{
			if (rayDir[i] == 0.0) continue
			
			if (rayDir[i] < 0.0)
			{
				// 不可能命中世界盒
				if (rayStart[i] <= gMapAbsMin[i]) return -1
				// 不可能命中世界盒
				if (rayStart[i] < gMapAbsMax[i]) continue
				dist = (gMapAbsMax[i] - rayStart[i]) / rayDir[i]
			}
			else
			{
				// 不可能命中世界盒
				if (gMapAbsMax[i] <= rayStart[i]) return -1
				// 不可能命中世界盒
				if (gMapAbsMin[i] < rayStart[i]) continue
				dist = (gMapAbsMin[i] - rayStart[i]) / rayDir[i]
			}
			VecAddScaled(rayStart, rayDir, dist, rayEnd)
			
			for (j = 2; 0 <= j; j--)
			{
				if (j == i) continue
				if (gMapAbsMin[j] <= rayEnd[j] <= gMapAbsMax[j]) continue
				break
			}
			if (j < 0)
			{
				for (j = 0; j < 3; j++)
				{
					rayStart[j] = rayEnd[j]
					if (rayEnd[j] == gMapAbsMin[j] && 0.0 < rayDir[j])		boxAbsMin[j] = gMapAbsMin[j]
					else if (rayEnd[j] == gMapAbsMax[j] && rayDir[j] < 0.0)		boxAbsMin[j] = gMapAbsMax[j] - 128.0
					else								boxAbsMin[j] = 128.0 * floatround(rayEnd[j] / 128.0, floatround_floor)
					boxAbsMax[j] = boxAbsMin[j] + 128.0
				}
				break
			}
		}
		// 未命中世界盒
		if (i == 3) return -1
		// 世界盒被遮挡
		if (rayLength < dist) return -1
		rayLength -= dist
	}
	
	new nodeIndex, nodeId, Array:arrayNode
	new Float:lenVecTemp, Float:lenVecX, Float:lenVecY, Float:cosA
	new Float:origin[3], Float:vecTemp[3], Float:vecX[3], Float:vecY[3], Float:rayHit[3], Float:absMin[3], Float:absMax[3]
	
	LoopStart:
	
	nodeIndex = -1
	arrayNode = NavBox_GetNodeArray(boxAbsMin)
	for (new i = ArraySize(arrayNode) - 1; 0 <= i; i--)
	{
		nodeId = ArrayGetCell(arrayNode, i)
		
		ArrayGetArray(gArray_NodePoint, nodeId, origin)
		origin[2] -= ArrayGetCell(gArray_NodeDucking, nodeId) ? 13.0 : 31.0
		
		VecSub(rayStart, origin, vecTemp)
		lenVecTemp = VecLength(vecTemp)
		if (0.0 <= VecDot(rayDir, vecTemp) / lenVecTemp) continue
		
		ArrayGetArray(gArray_NodeNormal, nodeId, vecX)
		
		lenVecX = VecDot(vecX, vecTemp)
		VecAddScaled(origin, vecX, lenVecX, vecTemp)
		VecSub(rayStart, vecTemp, vecY)
		VecMulScalar(rayDir, -1.0, vecTemp)
		lenVecTemp = VecLength(vecY)
		cosA = VecDot(vecX, vecTemp)
		lenVecY = lenVecTemp - floattan(floatacos(cosA, degrees), degrees) * lenVecX
		VecAddScaled(origin, vecY, lenVecY / lenVecTemp, vecTemp)
		dist = lenVecX / cosA
		if (rayLength < dist) continue
		VecAddScaled(rayStart, rayDir, dist, rayHit)
		
		ArrayGetArray(gArray_NodeAbsMin, nodeId, absMin)
		if (rayHit[0] < absMin[0] || rayHit[1] < absMin[1]) continue
		ArrayGetArray(gArray_NodeAbsMax, nodeId, absMax)
		if (absMax[0] <= rayHit[0] || absMax[1] <= rayHit[1]) continue
		
		dist = floatabs(rayHit[2] - rayStart[2])
		if (dist < lastDist || nodeIndex < 0) { lastDist = dist; nodeIndex = nodeId; }
	}
	if (0 <= nodeIndex) return nodeIndex
	
	for (i = 0; i < 3; i++)
	{
		if (rayDir[i] == 0.0) continue
		
		if (rayDir[i] < 0.0)
		{
			// 不可能命中盒子
			if (rayStart[i] < boxAbsMin[i]) continue
			dist = (boxAbsMin[i] - rayStart[i]) / rayDir[i]
		}
		else
		{
			// 不可能命中盒子
			if (boxAbsMax[i] < rayStart[i]) continue
			dist = (boxAbsMax[i] - rayStart[i]) / rayDir[i]
		}
		VecAddScaled(rayStart, rayDir, dist, rayEnd)
		if (loop && VecEqual(rayEnd, lastRayEnd)) continue
		lastRayEnd = rayEnd
		
		for (j = 2; 0 <= j; j--)
		{
			if (j == i) continue
			if (boxAbsMin[j] <= rayEnd[j] <= boxAbsMax[j]) continue
			break
		}
		if (j < 0)
		{
			for (j = 0; j < 3; j++)
			{
				rayStart[j] = rayEnd[j]
				if (rayEnd[j] == boxAbsMin[j] && rayDir[j] < 0.0)	boxAbsMin[j] -= 128.0
				else if (rayEnd[j] == boxAbsMax[j] && 0.0 < rayDir[j])	boxAbsMin[j] = boxAbsMax[j]
				else							boxAbsMin[j] = 128.0 * floatround(rayEnd[j] / 128.0, floatround_floor)
				boxAbsMax[j] = boxAbsMin[j] + 128.0
				
				// 超出世界盒范围
				if (boxAbsMin[j] < gMapAbsMin[j] || gMapAbsMax[j] <= boxAbsMin[j]) return -1
			}
			// 下一个被遮挡
			if (rayLength < dist) return -1
			
			loop++
			rayLength -= dist
			
			goto LoopStart
		}
	}
	
	// 超出世界盒范围(上面已经有同样的条件.此行代码不可能运行.写此代码只是为了消除编译器警告)
	return -1	
}

// --- helper: destroy grid safely ---
stock NavBox_DestroyGrid()
{
    if (gArray_XBox == Invalid_Array) return;

    new x, y, z, Array:arrayYBox, Array:arrayZBox, Array:arrayBox;

    for (x = ArraySize(gArray_XBox) - 1; 0 <= x; x--)
    {
        arrayYBox = ArrayGetCell(gArray_XBox, x);
        for (y = ArraySize(arrayYBox) - 1; 0 <= y; y--)
        {
            arrayZBox = ArrayGetCell(arrayYBox, y);
            for (z = ArraySize(arrayZBox) - 1; 0 <= z; z--)
            {
                arrayBox = ArrayGetCell(arrayZBox, z);
                ArrayDestroy(arrayBox);
            }
            ArrayDestroy(arrayZBox);
        }
        ArrayDestroy(arrayYBox);
    }

    ArrayDestroy(gArray_XBox);
    gArray_XBox = Invalid_Array; // FIX: сбрасываем, чтобы не было use-after-free
}




/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg936\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset134 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2052\\ f0\\ fs16 \n\\ par }
*/
