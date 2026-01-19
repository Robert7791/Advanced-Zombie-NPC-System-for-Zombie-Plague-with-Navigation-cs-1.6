
#if defined _NavigationSystem_included
  #endinput
#endif
#define _NavigationSystem_included

enum PathFlags
{
	PF_Walk,
	PF_CrouchRun,
	PF_Climb
}

forward NavSys_NodeLoading(id)
forward NavSys_NodeLoaded(id, Array:arrayNodeDucking, Array:arrayNodePoint, Array:arrayNodeAbsMin, Array:arrayNodeAbsMax, Array:arrayNodeNormal, Array:arrayNodeStart, Array:arrayNodeEnd, Array:arrayNodeFlags, Array:arrayNodeHeight, Array:arrayNodeDistance)
forward NavSys_NodeSaving(id)
forward NavSys_NodeSaved(id, Array:arrayNodeDucking, Array:arrayNodePoint, Array:arrayNodeAbsMin, Array:arrayNodeAbsMax, Array:arrayNodeNormal, Array:arrayNodeStart, Array:arrayNodeEnd, Array:arrayNodeFlags, Array:arrayNodeHeight, Array:arrayNodeDistance)

/**
 * 用A*算法寻找一个导航点到另一个导航点的最短路径.
 *
 * @note 返回值是存有路径点的动态数组.路径点是长度为7的数组.
 *	 用法如下:
 *	 new Float:origin[3], Float:goal[3]
 *	 pev(npc, pev_origin, origin)
 *	 pev(target, pev_origin, goal)
 *	 new iNodeOrigin = NavBox_GetNode(origin)
 *	 new iNodeGoal = NavBox_GetNodeNearest(goal)
 *	 new iWaypointFinal
 *	 new Array:arrayWaypoint = NavSys_Pathfinding(iNodeOrigin, iNodeGoal, iWaypointFinal)
 *	 if (iWaypointFinal < 0) iWaypointFinal = NavSys_GetWaypointFinal(arrayWaypoint, goal)
 *	 new waypoint[7]
 *	 NavSys_GetWaypointSecond(arrayWaypoint, iWaypointFinal, waypoint)
 *	 //waypoint[0]		表示当前路点的导航点下标.
 *	 //bool:waypoint[1]	表示当前路径点能抵达的所有相邻导航点已经被访问(gArray_NodeEnd属性已被访问).
 *	 //Float:waypoint[2]	表示路径起点到当前路径点的实际路程.
 *	 //Float:waypoint[3]	表示路径起点到当前路径点的实际路程+路径点到终点的直线路程.
 *	 //waypoint[4]		表示上一个路径点的导航点下标.
 *	 //waypoint[5]		表示上一个路径点下标.
 *	 //waypoint[6]		表示waypoint[4]导航点至waypoint[0]导航点的路径下标.
 *	 ArrayDestory(arrayWaypoint)
 *
 * @note waypoint[6]的用法如下:
 *	new Float:start[3], Float:mid[3], Float:end[3]
 * 	NavNode_GetPathCoord(waypoint[4], waypoint[0], waypoint[6], start, mid, end)
 *
 * @note 若超时,iWaypointFinal将被赋值为-1.若无法抵达终点,iWaypointFinal将被赋值为-2.
 *
 * @note 返回值需要被ArrayDestory()函数销毁.
 *
 * @param iNodeOrigin		导航点下标,路径的起点.
 * @param iNodeGoal		导航点下标,路径的终点.
 * @param iWaypointFinal	将用于储存路径终点的路径点下标.
 * @param maxTickCount		设定函数运行时间不能超过多少毫秒.设为-1则不限时.
 *
 * @return     			路径点动态数组句柄.
*/
native Array:NavSys_Pathfinding(iNodeOrigin, iNodeGoal, &iWaypointFinal, maxTickCount = -1)
/**
 * 当NavSys_Pathfinding()函数获取的iWaypointFinal为-1时可以使用NavSys_Pathfinding2()函数继续寻路.
 *
 * @note 若超时,返回值为-1.若无法抵达终点,返回值为-2.
 *
 * @param Array:arrayWaypoint	路径点动态数组句柄.NavSys_Pathfinding()函数的返回值.
 * @param iNodeGoal		导航点下标,NavSys_Pathfinding()函数使用过的路径终点.
 * @param maxTickCount		设定函数运行时间不能超过多少毫秒.设为-1则不限时.
 *
 * @return     			-1,-2或路径终点的路径点下标.
*/
native NavSys_Pathfinding2(Array:arrayWaypoint, iNodeGoal, maxTickCount = -1)
/**
 * 寻找最接近指定坐标的路径点.
 *
 * @note 从NavSys_Pathfinding()函数获取的iWaypointFinal为-1时可使用此函数.此函数返回值必然大于0
 *
 * @param arrayWaypoint		路径点动态数组句柄.
 * @param goal			终点坐标,例如玩家实体的pev_origin(高于地面18或36距离的).
 *
 * @return     			路径点下标.
*/
native NavSys_GetWaypointFinal(Array:arrayWaypoint, const Float:goal[3])
/**
 * 获取第二个路径点.
 *
 * @param arrayWaypoint		路径点动态数组句柄.
 * @param iWaypointFinal	路径终点的路径点下标.
 * @param waypoint		将会用于储存路径点数据.
 *
 * @noreturn
*/
native NavSys_GetWaypointSecond(Array:arrayWaypoint, iWaypointFinal, waypoint[7])
/**
 * 从NavSys_Pathfinding()获取路径点后,当你不确认追踪者在路径的哪个位置,可用此函数获取最接近追踪者的一段路径信息.
 *
 * @note iNodeStart,iNodeEnd,iPath的用法如下:
 *	new Float:start[3], Float:mid[3], Float:end[3]
 * 	NavNode_GetPathCoord(iNodeStart, iNodeEnd, iPath, start, mid, end)
 *
 * @note 如果iNodeStart是终点,则iNodeEnd和iPath为-1.
 *
 * @param arrayWaypoint		路径点动态数组句柄.
 * @param iWaypointFinal	路径终点的路径点下标.
 * @param origin		追踪者坐标,例如玩家实体的pev_origin(高于地面18或36距离的).
 * @param iNodeStart		将用于储存最接近origin的导航点下标.
 * @param iNodeEnd		将用于储存-1或iNodeStart的下一个导航点下标.
 * @param iPath			将会储存-1或iNodeStart至iNodeEnd的路径下标.
 *
 * @noreturn
*/
native NavSys_GetWaypointPathInfo(Array:arrayWaypoint, iWaypointFinal, const Float:origin[3], &iNodeStart, &iNodeEnd, &iPath)
/**
 * 获取当前地图所有出生点坐标和地面法向量.
 *
 * @note 用法如下:
 * 	new Array:arraySpawnPos = NavSys_GetSpawnPos()
 *	new Float:spawnPos[6], Float:origin[3], Float:normal[3]
 *	ArrayGetArray(arraySpawnPos, random(ArraySize(arraySpawnPos)), spawnPos)
 *	origin[0] = spawnPos[0]; origin[1] = spawnPos[1]; origin[2] = spawnPos[2];
 *	normal[0] = spawnPos[3]; normal[1] = spawnPos[4]; normal[2] = spawnPos[5];
 *
 * @note 不要销毁返回值.
 *
 * @return			坐标和法向量的动态数组句柄
*/
native Array:NavSys_GetSpawnPos()
/**
 * 获取当前地图所有func_ladder实体索引.
 *
 * @note 用法如下:
 * 	new Array:arrayLadder = NavSys_GetLadder()
 *	new iLadderEntity = ArrayGetCell(arraySpawnPos, random(ArraySize(arrayLadder)))
 *
 * @note 不要销毁返回值.
 *
 * @return			实体索引的动态数组句柄
*/
native Array:NavSys_GetLadder()
/**
 * 判断坐标位置是否有导航盒存在.
 *
 * @note 所有导航点被一个巨大的世界盒包裹.世界盒可平均分割为128*128*128尺寸的导航盒.
 *
 * @param origin		任意坐标.
 *
 * @return			true或false.
*/
native bool:NavBox_Exist(const Float:origin[3])
/**
 * 根据西北下,东北上两个角坐标,为指定玩家画出一个盒子.
 *
 * @param id			玩家实体索引.
 * @param absMin		盒子的西北下角坐标.
 * @param absMax		盒子的东北上角坐标.
 * @param life			激光显示多久(1表示0.1秒).
 * @param width			激光宽度(0至255).
 * @param noise			激光扭曲程度(0-255).
 * @param red			红色浓度(0至255).
 * @param green			绿色浓度(0至255).
 * @param blue			蓝色浓度(0至255).
 *
 * @noreturn
*/
native NavBox_Draw(id, const Float:absMin[3], const Float:absMax[3], life, width, noise, red, green, blue)
/**
 * 获取导航盒的覆盖范围.
 *
 * @param absMin		将用于储存世界盒的西北下角坐标.
 * @param absMax		将用于储存世界盒的东北上角坐标.
 *
 * @noreturn
*/
native NavBox_GetArea(Float:absMin[3], Float:absMax[3])
/**
 * 获取包裹指定坐标的导航盒的西南下,东北上角坐标.
 *
 * @param origin		任意被导航盒包裹的坐标.
 * @param absMin		将用于储存导航盒的西北下角坐标.
 * @param absMax		将用于储存导航盒的东北上角坐标.
 *
 * @noreturn
*/
native NavBox_GetContain(const Float:origin[3], Float:absMin[3], Float:absMax[3])
/**
 * 寻找最接近指定坐标的导航盒,获取其西南下,东北上角坐标.
 *
 * @param origin		任意坐标.
 * @param absMin		将用于储存导航盒的西北下角坐标.
 * @param absMax		将用于储存导航盒的东北上角坐标.
 *
 * @noreturn
*/
native NavBox_GetNearest(const Float:origin[3], Float:absMin[3], Float:absMax[3])
/**
 * 寻找包裹指定坐标的导航盒,获取所有与其相交的导航点.
 *
 * @note 用法如下:
 *	new iNode, Array:arrayNode = NavBox_GetNodeArray(origin)
 *	for (new i = ArraySize(arrayNode) - 1; 0 <= i; i--)
 *	{
 *		iNode = ArrayGetCell(arrayNode, i)
 *		NavNode_DrawBox(player, iNode, 10, 10, 0, 255, 0, 0)
 *	}
 *
 * @note 不要销毁返回值.
 *
 * @param origin		任意被导航盒包裹的坐标.
 *
 * @return			导航点的动态数组句柄.
*/
native Array:NavBox_GetNodeArray(const Float:origin[3])
/**
 * 寻找最接近指定坐标的起始导航点.与NavBox_GetNodeNearest()函数的区别是:寻路时,此函数更适合查找追踪者位置.
 *
 * @param origin		用于寻找导航点的坐标.例如玩家实体的pev_origin(高于地面18或36距离的).
 *
 * @return			-1或导航点下标.
*/
native NavBox_GetNode(const Float:origin[3])
/**
 * 寻找最接近指定坐标的导航点.与NavBox_GetNode()函数的区别是:寻路时,此函数更适合查找目标位置.
 *
 * @param origin		用于寻找导航点的坐标.例如玩家实体的pev_origin(高于地面18或36距离的).
 *
 * @return			-1或导航点下标.
*/
native NavBox_GetNodeNearest(const Float:origin[3])
/**
 * 寻找包裹指定坐标的导航点.
 *
 * @param origin		用于寻找导航点的坐标.例如玩家实体的pev_origin(高于地面18或36距离的).
 *
 * @return			-1或导航点下标.
*/
native NavBox_GetNodeContain(const Float:origin[3])
/**
 * 寻找与指定盒子相交的导航点.
 *
 * @param absMin		盒子的西南下角坐标.例如玩家的pev_origin+pev_mins.不建议使用pev_absmin.
 * @param absMax		盒子的东北上角坐标.例如玩家的pev_origin+pev_maxs.不建议使用pev_absmax.
 *
 * @return			-1或导航点下标.
*/
native NavBox_GetNodeIntersect(const Float:absMin[3], const Float:absMax[3])
/**
 * 寻找实体正在瞄准的导航点.
 *
 * @param id			实体索引.根据pev_v_angle计算方向.
 *
 * @return			-1或导航点下标.
*/
native NavBox_GetNodeInFront(id)
/**
 * 为指定玩家画导航点的BBOX.
 *
 * @param id			玩家实体索引.
 * @param iNode			导航点索引.
 * @param life			激光显示多久(1表示0.1秒).
 * @param width			激光宽度(0至255).
 * @param noise			激光扭曲程度(0-255).
 * @param red			红色浓度(0至255).
 * @param green			绿色浓度(0至255).
 * @param blue			蓝色浓度(0至255).
 *
 * @noreturn
*/
native NavNode_DrawBox(id, iNode, life, width, noise, red, green, blue)
/**
 * 为指定玩家画出导航点的底面.
 *
 * @param id			玩家实体索引.
 * @param iNode			导航点索引.
 * @param drawPath		true为画出导航点的所有路径,false不画.
 * @param life			激光显示多久(1表示0.1秒).
 * @param width			激光宽度(0至255).
 * @param noise			激光扭曲程度(0-255).
 * @param red			红色浓度(0至255).
 * @param green			绿色浓度(0至255).
 * @param blue			蓝色浓度(0至255).
 *
 * @noreturn
*/
native NavNode_DrawMesh(id, iNode, bool:drawPath, life, width, noise, red, green, blue)
/**
 * 寻找最接近指定坐标的导航点.与NavBox_GetNodeNearest()函数的区别是:此函数遍历所有导航点.而NavBox_GetNodeNearest()函数只查询origin周围的导航点.
 *
 * @param origin		用于寻找导航点的坐标.例如玩家实体的pev_origin(高于地面18或36距离的).
 *
 * @return			-1或导航点下标.
*/
native NavNode_GetNearest(const Float:origin[3])
/**
 * 从指定的路径中获取路径起点,中间点,终点坐标.
 *
 * @note iNodeEnd必须是iNodeStart的终点之一.
 *
 * @param iNodeStart		路径起点的导航点下标.
 * @param iNodeEnd		路径终点的导航点下标.
 * @param iPath			iNodeStart至iNodeEnd的路径下标.
 * @param start			将会用于储存路径起点坐标.该坐标位于iNodeStart导航点的内部.
 * @param mid			将会用于储存路径中间坐标.
 * @param end			将会用于储存路径终点坐标.该坐标位于iNodeEnd导航点的内部.
 *
 * @noreturn
*/
native NavNode_GetPathCoord(iNodeStart, iNodeEnd, iPath, Float:start[3], Float:mid[3], Float:end[3])
/**
 * 从指定的路径中获取路径终点坐标.以及如何抵达终点坐标.
 *
 * @note iNodeEnd必须是iNodeStart的终点之一.
 *
 * @param iNodeStart		路径起点的导航点下标.
 * @param iNodeEnd		路径终点的导航点下标.
 * @param iPath			iNodeStart至iNodeEnd的路径下标.
 * @param flags			将会用于储存iNodeStart至iNodeEnd的移动标志.
 * @param Height			将会用于储存iNodeStart至iNodeEnd的障碍高度.
 * @param end			将会用于储存路径终点坐标.该坐标位于iNodeEnd导航点的内部.
 *
 * @noreturn
*/
native NavNode_GetPathCoord2(iNodeStart, iNodeEnd, iPath, &PathFlags:flags, &Float:Height, Float:end[3])



