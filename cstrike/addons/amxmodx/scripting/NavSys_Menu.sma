/* UTF-8 func by www.DT-Club.net */

// 游戏中发送什么聊天信息可以开启导航系统菜单
#define dMenuCmd			"nsmenu"

new gNodeId_Aiming
new gMenuId_Main, gMenuId_Create, gMenuId_Edit, gMenuId_Test
NavSysMenu_Init()
{
	new menuName[32], itemName[32]
	format(menuName, 31, "%L", LANG_SERVER, "MENU_NAME_MAIN")
	gMenuId_Main = menu_create(menuName, "MenuHandler_Main")
	
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NODE_CREATE")
	menu_additem(gMenuId_Main, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NODE_EDIT")
	menu_additem(gMenuId_Main, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST")
	menu_additem(gMenuId_Main, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_SAVE")
	menu_additem(gMenuId_Main, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_RELOAD")
	menu_additem(gMenuId_Main, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_DELETE")
	menu_additem(gMenuId_Main, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_EDIT_OFF")
	menu_additem(gMenuId_Main, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_MENU_OFF")
	menu_setprop(gMenuId_Main, MPROP_EXITNAME, itemName)
	
	format(menuName, 31, "%L", LANG_SERVER, "MENU_NAME_NODE_CREATE")
	gMenuId_Create = menu_create(menuName, "MenuHandler_Create")
	
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_AUTO_GENERATION")
	menu_additem(gMenuId_Create, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_CREATE_TO_FOOT")
	menu_additem(gMenuId_Create, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_CREATE_TO_AIM")
	menu_additem(gMenuId_Create, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_AUTO_ALIGN")
	menu_additem(gMenuId_Create, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TO_MAIN")
	menu_setprop(gMenuId_Create, MPROP_EXITNAME, itemName)
	
	format(menuName, 31, "%L", LANG_SERVER, "MENU_NAME_NODE_EDIT")
	gMenuId_Edit = menu_create(menuName, "MenuHandler_Edit")
	
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NODE_SELECT")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NODE_CROUCH")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NODE_MERGE")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NODE_DELETE")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NODE_AUTO_MERGE1")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NODE_AUTO_MERGE2")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_PATH_CONNECT")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_PATH_SET_CROUCH")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_PATH_SET_CLIMB")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_PATH_SET_HEIGHT")
	menu_additem(gMenuId_Edit, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_BACK")
	menu_setprop(gMenuId_Edit, MPROP_BACKNAME, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NEXT")
	menu_setprop(gMenuId_Edit, MPROP_NEXTNAME, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TO_MAIN")
	menu_setprop(gMenuId_Edit, MPROP_EXITNAME, itemName)
	
	format(menuName, 31, "%L", LANG_SERVER, "MENU_NAME_TEST")
	gMenuId_Test = menu_create(menuName, "MenuHandler_Test")
	
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST1")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST2")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST3")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST4")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST5")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST6")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST7")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST8")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST9")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST10")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST11")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST12")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST13")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST14")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST15")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST16")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST17")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TEST18")
	menu_additem(gMenuId_Test, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_BACK")
	menu_setprop(gMenuId_Test, MPROP_BACKNAME, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_NEXT")
	menu_setprop(gMenuId_Test, MPROP_NEXTNAME, itemName)
	format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_TO_MAIN")
	menu_setprop(gMenuId_Test, MPROP_EXITNAME, itemName)
	
	gAutoAlign = true
	gArray_Selected = ArrayCreate()
}

public MenuHandler_Main(id, menuId, itemId)
{
	if (id != 1) return
	if (!is_user_alive(id)) return
	
	switch (itemId)
	{
		// 创建导航点
		case 0: menu_display(id, gMenuId_Create)
		// 编辑导航点
		case 1: menu_display(id, gMenuId_Edit)
		// 测试功能
		case 2: menu_display(id, gMenuId_Test)
		// 保存导航信息
		case 3:
		{
			NavSys_SaveFile(id)
			menu_display(id, gMenuId_Main)
		}
		// 重载导航信息
		case 4:
		{
			NavSys_LoadFile(id)
			menu_display(id, gMenuId_Main)
		}
		// 清除导航信息
		case 5:
		{
			NavSys_DeleteFile(id)
			menu_display(id, gMenuId_Main)
		}
		// 关闭编辑模式
		case 6:
		{
			NavSysMenu_Destroy()
			client_print(id, print_chat, "%L", LANG_SERVER, "EDIT_MODE_OFF")
		}
	}
}

public MenuHandler_Create(id, menuId, itemId)
{
	if (id != 1) return
	if (!is_user_alive(id)) return
	
	switch (itemId)
	{
		// 自动创建
		case 0: NavSysMenu_AutoCreating(id)
		// 创建到脚下
		case 1: NavSysMenu_CreateNodeOnGround(id)
		// 创建到准星
		case 2: NavSysMenu_CreateNodeInFront(id)
		// 自动对齐
		case 3:
		{
			gAutoAlign = !gAutoAlign
			new itemName[32]
			if (gAutoAlign)
			{
				format(itemName, 31, "%L", LANG_SERVER, "ITEM_NAME_AUTO_ALIGN")
				menu_item_setname(gMenuId_Create, 4, itemName)
				client_print(id, print_chat, "%L", LANG_SERVER, "AUTO_ALIGN_ON")
			}
			else
			{
				format(itemName, 31, "\d%L", LANG_SERVER, "ITEM_NAME_AUTO_ALIGN")
				menu_item_setname(gMenuId_Create, 4, itemName)
				client_print(id, print_chat, "%L", LANG_SERVER, "AUTO_ALIGN_OFF")
			}
		}
		case MENU_EXIT: { menu_display(id, gMenuId_Main); return; }
	}
	menu_display(id, gMenuId_Create)
}

public MenuHandler_Edit(id, menuId, itemId)
{
	if (id != 1) return
	if (!is_user_alive(id)) return
	
	switch (itemId)
	{
		// 导航点:选择/舍弃
		case 0: NavSysMenu_Selects(id)
		// 导航点:蹲下/站起
		case 1: NavSysMenu_Crouch(id)
		// 导航点:合并
		case 2: NavSysMenu_Merge(id)
		// 导航点:删除
		case 3: NavSysMenu_Delete(id)
		// 导航点:自动合并.短
		case 4: NavSysMenu_AutoMerging(id, false)
		// 导航点:自动合并.长
		case 5: NavSysMenu_AutoMerging(id, true)
		// 路径:创建/删除
		case 6: NavSysMenu_CreatePath(id)
		// 路径:蹲跑标志
		case 7: { menu_display(id, gMenuId_Edit, 1); NavSysMenu_ChangePathFlags(id, false); return; }
		// 路径:攀爬标志
		case 8: { menu_display(id, gMenuId_Edit, 1); NavSysMenu_ChangePathFlags(id, true); return; }
		// 路径:障碍高度
		case 9: { menu_display(id, gMenuId_Edit, 1); NavSysMenu_ChangePathHeight(id); return; }
		case MENU_EXIT: { menu_display(id, gMenuId_Main); return; }
	}
	menu_display(id, gMenuId_Edit)
}

public MenuHandler_Test(id, menuId, itemId)
{
	if (id != 1) return
	if (!is_user_alive(id)) return
	
	switch (itemId)
	{
		// NavSys_Pathfinding
		case 0: NavSysMenu_Test1(id)
		// NavSys_GetWaypointFinal
		case 1: NavSysMenu_Test2(id)
		// NavSys_GetWaypointSecond
		case 2: NavSysMenu_Test3(id)
		// NavSys_GetWaypointPathInfo
		case 3: NavSysMenu_Test4(id)
		// NavSys_GetSpawnPos
		case 4: NavSysMenu_Test5(id)
		// NavSys_GetLadder
		case 5: NavSysMenu_Test6(id)
		// NavBox_Exist&Contain&Nearest
		case 6: NavSysMenu_Test7(id)
		// NavBox_GetNodeArray
		case 7: { menu_display(id, gMenuId_Test, 1); NavSysMenu_Test8(id); return; }
		// NavBox_GetNode
		case 8: { menu_display(id, gMenuId_Test, 1); NavSysMenu_Test9(id); return; }
		// NavBox_GetNodeNearest
		case 9: { menu_display(id, gMenuId_Test, 1); NavSysMenu_Test10(id); return; }
		// NavBox_GetNodeContain
		case 10: { menu_display(id, gMenuId_Test, 1); NavSysMenu_Test11(id); return; }
		// NavBox_GetNodeIntersect
		case 11: { menu_display(id, gMenuId_Test, 1); NavSysMenu_Test12(id); return; }
		// NavNode_DrawBox
		case 12: { menu_display(id, gMenuId_Test, 1); NavSysMenu_Test13(id); return; }
		// NavNode_GetNearest
		case 13: { menu_display(id, gMenuId_Test, 1); NavSysMenu_Test14(id); return; }
		// NavNode_GetPathCoord
		case 14: { menu_display(id, gMenuId_Test, 2); NavSysMenu_Test15(id); return; }
		// NavNode_GetPathCoord2
		case 15: { menu_display(id, gMenuId_Test, 2); NavSysMenu_Test16(id); return; }
		// NavNode_PathExist
		case 16: { menu_display(id, gMenuId_Test, 2); NavSysMenu_Test17(id); return; }
		// NavNode_PathExist2
		case 17: { menu_display(id, gMenuId_Test, 2); NavSysMenu_Test18(id); return; }
		case MENU_EXIT: { menu_display(id, gMenuId_Main); return; }
	}
	menu_display(id, gMenuId_Test)
}

NavSysMenu_Destroy()
{
	if (0 <= gMenuId_Main)
	{
		menu_destroy(gMenuId_Main)
		gMenuId_Main = -1
	}
	if (0 <= gMenuId_Create)
	{
		menu_destroy(gMenuId_Create)
		gMenuId_Create = -1
	}
	if (0 <= gMenuId_Edit)
	{
		menu_destroy(gMenuId_Edit)
		gMenuId_Edit = -1
	}
	if (0 <= gMenuId_Test)
	{
		menu_destroy(gMenuId_Test)
		gMenuId_Test = -1
	}
	
	gNodeId_Aiming = -1
	ArrayDestroy(gArray_Selected)
}

NavSysMenu_AutoCreating(id)
{
	NavNode_AutoCreating()
	NavBox_Update()
	NavSys_SaveFile(id)
}

NavSysMenu_CreateNodeOnGround(id)
{
	new Float:vecSrc[3]
	pev(id, pev_origin, vecSrc)
	
	new hull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
	
	if (!NavSys_IsVacantSpace(vecSrc, hull))
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_CREATE_NODE")
		return
	}
	
	new Float:vecDest[3], Float:vecEndPos[3], Float:vecPlaneNormal[3]
	vecDest[0] = vecSrc[0]
	vecDest[1] = vecSrc[1]
	vecDest[2] = vecSrc[2] - 9999.0
	NavSys_Trace(vecSrc, vecDest, hull)
	get_tr2(0, TR_vecEndPos, vecEndPos)
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
	
	if (gAutoAlign)
	{
		vecDest[0] = 16.0 * floatround(vecEndPos[0] / 16.0)
		vecDest[1] = 16.0 * floatround(vecEndPos[1] / 16.0)
		vecDest[2] = vecEndPos[2]
		if (!VecEqual(vecEndPos, vecDest))
		{
			InclinedPlanePoint(vecEndPos, vecPlaneNormal, vecDest, vecEndPos)
			if (!NavSys_IsVacantSpace(vecEndPos, hull))
			{
				client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_CREATE_NODE")
				return
			}
			
			vecDest[0] = vecEndPos[0]
			vecDest[1] = vecEndPos[1]
			vecDest[2] = vecEndPos[2] - 9999.0
			NavSys_Trace(vecEndPos, vecDest, hull)
			get_tr2(0, TR_vecEndPos, vecEndPos)
			get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
		}
	}
	
	if (NavBox_Exist(vecEndPos) && 0 <= NavBox_GetNodeContain(vecEndPos))
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_CREATE_NODE")
		return
	}
	
	new nodeIndex = NavNode_Create(vecEndPos, vecPlaneNormal, (hull == HULL_HEAD))
	NavBox_AddNode(nodeIndex)
	
	NavNode_DrawMesh(id, nodeIndex, false, 5, 5, 25, 255, 0, 0)
	client_print(id, print_chat, "%L", LANG_SERVER, "CREATE_NODE", nodeIndex, nodeIndex + 1)
}

NavSysMenu_CreateNodeInFront(id)
{
	new Float:vecSrc[3], Float:vecIdeal[3], Float:vecDest[3], Float:vecEndPos[3], Float:vecPlaneNormal[3]
	pev(id, pev_origin, vecSrc)
	pev(id, pev_view_ofs, vecIdeal)
	VecAdd(vecSrc, vecIdeal, vecSrc)
	pev(id, pev_v_angle, vecIdeal)
	AngleVector(vecIdeal, ANGLEVECTOR_FORWARD, vecIdeal)
	VecMulScalar(vecIdeal, 9999.0, vecIdeal)
	VecAdd(vecSrc, vecIdeal, vecDest)
	NavSys_Trace(vecSrc, vecDest, -1)
	get_tr2(0, TR_vecEndPos, vecEndPos)
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
	
	if (gAutoAlign)
	{
		vecDest[0] = 16.0 * floatround(vecEndPos[0] / 16.0)
		vecDest[1] = 16.0 * floatround(vecEndPos[1] / 16.0)
		InclinedPlanePoint(vecEndPos, vecPlaneNormal, vecDest, vecEndPos)
	}
	
	new hull = HULL_HEAD
	
	vecEndPos[2] += 36.0
	vecDest[0] = vecEndPos[0]
	vecDest[1] = vecEndPos[1]
	vecDest[2] = vecEndPos[2] - 9999.0
	NavSys_Trace(vecEndPos, vecDest, hull)
	get_tr2(0, TR_vecEndPos, vecEndPos)
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal)
	
	if (!NavSys_IsVacantSpace(vecEndPos, hull))
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_CREATE_NODE")
		return
	}
	
	hull = HULL_HUMAN
	vecEndPos[2] += 18.0
	
	if (!NavSys_IsVacantSpace(vecEndPos, hull))
	{
		hull = HULL_HEAD
		vecEndPos[2] -= 18.0
	}
	
	if (NavBox_Exist(vecEndPos) && 0 <= NavBox_GetNodeContain(vecEndPos))
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_CREATE_NODE")
		return
	}
	
	new nodeIndex = NavNode_Create(vecEndPos, vecPlaneNormal, (hull == HULL_HEAD))
	NavBox_AddNode(nodeIndex)
	
	NavNode_DrawMesh(id, nodeIndex, false, 5, 5, 25, 255, 0, 0)
	client_print(id, print_chat, "%L", LANG_SERVER, "CREATE_NODE", nodeIndex, nodeIndex + 1)
}

NavSysMenu_Selects(id)
{
	if (gNodeId_Aiming < 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_SELECT_NODE")
		return
	}
	client_print(id, print_chat, "%L", LANG_SERVER, NavNode_Selects(gNodeId_Aiming) ? "SELECT_NODE" : "UNSELECT_NODE", gNodeId_Aiming)
}

NavSysMenu_Crouch(id)
{
	new nodeNums = ArraySize(gArray_Selected)
	if (!nodeNums)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_SET_NODE_CROUCH")
		return
	}
	
	new iNode, iPath
	new iNodeStart, iPathTemp
	new Array:arrayStart, Array:arrayEnd, Array:arrayDistance
	new bool:ducking, Float:origin[3], Float:absMax[3], Float:dest[3]
	
	for (new i = 0; i < nodeNums; i++)
	{
		iNode = ArrayGetCell(gArray_Selected, i)
		
		ArrayGetArray(gArray_NodePoint, iNode, origin)
		ArrayGetArray(gArray_NodeAbsMax, iNode, absMax)
		
		if (ArrayGetCell(gArray_NodeDucking, iNode))
		{
			ducking = false
			origin[2] += 18.0
			absMax[2] += 36.0
		}
		else
		{
			ducking = true
			dest[0] = origin[0]
			dest[1] = origin[1]
			dest[2] = origin[2] - 9999.0
			NavSys_Trace(origin, dest, HULL_HEAD)
			get_tr2(0, TR_vecEndPos, origin)
			absMax[2] -= 36.0
		}
		
		ArraySetArray(gArray_NodePoint, iNode, origin)
		ArraySetArray(gArray_NodeAbsMax, iNode, absMax)
		ArraySetCell(gArray_NodeDucking, iNode, ducking)
		
		arrayStart = ArrayGetCell(gArray_NodeStart, iNode)
		for (iPath = ArraySize(arrayStart) - 1; 0 <= iPath; iPath--)
		{
			iNodeStart = ArrayGetCell(arrayStart, iPath)
			
			ArrayGetArray(gArray_NodePoint, iNodeStart, dest)
			
			arrayEnd	= ArrayGetCell(gArray_NodeEnd,		iNodeStart)
			arrayDistance	= ArrayGetCell(gArray_NodeDistance,	iNodeStart)
			
			for (iPathTemp = ArraySize(arrayEnd) - 1; 0 <= iPathTemp; iPathTemp--)
			{
				if (ArrayGetCell(arrayEnd, iPathTemp) != iNode) continue
				
				ArraySetCell(arrayDistance, iPathTemp, VecDistance(origin, dest))
			}
		}
		
		arrayEnd	= ArrayGetCell(gArray_NodeEnd,		iNode)
		arrayDistance	= ArrayGetCell(gArray_NodeDistance,	iNode)
		for (iPath = ArraySize(arrayEnd) - 1; 0 <= iPath; iPath--)
		{
			ArrayGetArray(gArray_NodePoint, ArrayGetCell(arrayEnd, iPath), dest)
			
			ArraySetCell(arrayDistance, iPath, VecDistance(origin, dest))
		}
		
		client_print(id, print_chat, "%L", LANG_SERVER, ducking ? "SET_NODE_DUCKING" : "SET_NODE_STANDING", iNode)
	}
	
	ArrayClear(gArray_Selected)
	
	NavBox_Update()
}

NavSysMenu_Merge(id)
{
	new nodeNums = ArraySize(gArray_Selected)
	if (nodeNums != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE1")
		return
	}
	
	new iNodeStart = ArrayGetCell(gArray_Selected, 0)
	new iNodeEnd = ArrayGetCell(gArray_Selected, 1)
	ArrayClear(gArray_Selected)
	
	if (ArrayGetCell(gArray_NodeDucking, iNodeStart) != ArrayGetCell(gArray_NodeDucking, iNodeEnd))
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE2")
		return
	}
	
	new iPath, Array:arrayStart, Array:arrayEnd
	
	arrayStart = ArrayGetCell(gArray_NodeStart, iNodeStart)
	for (iPath = ArraySize(arrayStart) - 1; 0 <= iPath && ArrayGetCell(arrayStart, iPath) != iNodeEnd; iPath--) { }
	if (iPath < 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE3", iNodeEnd, iNodeStart)
		return
	}
	arrayEnd = ArrayGetCell(gArray_NodeEnd, iNodeStart)
	for (iPath = ArraySize(arrayEnd) - 1; 0 <= iPath && ArrayGetCell(arrayEnd, iPath) != iNodeEnd; iPath--) { }
	if (iPath < 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE3", iNodeStart, iNodeEnd)
		return
	}
	
	new Float:normal[2][3]
	ArrayGetArray(gArray_NodeNormal, iNodeStart, normal[0])
	ArrayGetArray(gArray_NodeNormal, iNodeEnd, normal[1])
	if (!VecEqual(normal[0], normal[1]))
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE4", iNodeStart, iNodeEnd)
		return
	}
	
	new Float:absMin[3][3], Float:absMax[3][3]
	new Float:width[2], Float:height[2]
	
	ArrayGetArray(gArray_NodeAbsMin, iNodeStart, absMin[0])
	ArrayGetArray(gArray_NodeAbsMax, iNodeStart, absMax[0])
	ArrayGetArray(gArray_NodeAbsMin, iNodeEnd, absMin[1])
	ArrayGetArray(gArray_NodeAbsMax, iNodeEnd, absMax[1])
	
	width[0] = absMax[0][0] - absMin[0][0]
	height[0] = absMax[0][1] - absMin[0][1]
	width[1] = absMax[1][0] - absMin[1][0]
	height[1] = absMax[1][1] - absMin[1][1]
	
	// 如果iNodeStart与iNodeEnd无法竖向对齐或横向对齐
	if ((absMin[0][0] != absMin[1][0] || absMax[0][0] != absMax[1][0]) && (absMin[0][1] != absMin[1][1] || absMax[0][1] != absMax[1][1]))
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE5", iNodeStart, iNodeEnd)
		return
	}
	
	new Float:origin[3], Float:dest[3], Float:mins[3], Float:maxs[3]
	for (new i = 0; i < 3; i++)
	{
		absMin[2][i] = floatmin(absMin[0][i], absMin[1][i])
		absMax[2][i] = floatmax(absMax[0][i], absMax[1][i])
		origin[i] = (absMin[2][i] + absMax[2][i]) * 0.5
		dest[i] = origin[i]
		mins[i] = absMin[2][i] - origin[i]
		maxs[i] = absMax[2][i] - origin[i]
	}
	
	switch (NavNode_Merge(iNodeStart, iNodeEnd, origin, absMin[2], absMax[2]))
	{
		case 0:
		{
			client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE6", iNodeStart, iNodeEnd)
			return
		}
		case -1:
		{
			client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE7", iNodeStart, iNodeEnd)
			return
		}
		case -2:
		{
			client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE8", iNodeStart, iNodeEnd)
			return
		}
		case -3:
		{
			client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE9", iNodeStart, iNodeEnd)
			return
		}
		case -4:
		{
			client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE10", iNodeStart, iNodeEnd)
			return
		}
		case -5:
		{
			client_print(id, print_chat, "%L", LANG_SERVER, "FAILED_TO_MERGE11", iNodeStart, iNodeEnd)
			return
		}
	}
	
	NavBox_Update()
	
	NavNode_DrawMesh(id, iNodeEnd < iNodeStart ? iNodeStart - 1 : iNodeStart, true, 5, 5, 25, 255, 0, 0)
	
	client_print(id, print_chat, "%L", LANG_SERVER, "MERGE", iNodeEnd, iNodeStart)
}

NavSysMenu_Delete(id)
{
	new nodeNums = ArraySize(gArray_Selected)
	if (!nodeNums)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "NODE_DELETION_FAILED")
		return
	}
	
	new i, j, k, l, iNode
	
	// 将已选中的导航点编号按照从大到小的顺序排列
	for (i = 0; i < nodeNums - 1; i++)
	{
		for (j = 0; j < nodeNums - 1 - i; j++)
		{
			k = ArrayGetCell(gArray_Selected, j)
			l = ArrayGetCell(gArray_Selected, j + 1)
			if (l > k)
			{
				ArraySetCell(gArray_Selected, j, l)
				ArraySetCell(gArray_Selected, j + 1, k)
			}
		}
	}
	
	for (i = 0; i < nodeNums; i++)
	{
		iNode = ArrayGetCell(gArray_Selected, i)
		NavNode_Delete(iNode)
		client_print(id, print_chat, "%L", LANG_SERVER, "NODE_DELETED", iNode)
	}
	
	ArrayClear(gArray_Selected)
	
	// 更新世界盒内导航点信息
	NavBox_Update()
}

NavSysMenu_AutoMerging(id, bool:longAllowed)
{
	if (!ArraySize(gArray_NodeDucking))
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "AUTO_MERGE_FAILED")
		return
	}
	
	ArrayClear(gArray_Selected)
	
	NavNode_AutoMerging(longAllowed)
	NavNode_AutoMerging(longAllowed)
	NavBox_Update()
	NavSys_SaveFile(id)
}

NavSysMenu_CreatePath(id)
{
	new nodeNums = ArraySize(gArray_Selected)
	if (nodeNums != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "PATH_CONNECT_FAILED")
		return
	}
	
	new iNodeStart	= ArrayGetCell(gArray_Selected, 0)
	new iNodeEnd	= ArrayGetCell(gArray_Selected, 1)
	ArrayClear(gArray_Selected)
	
	new Array:arrayStart
	new Array:arrayEnd	= ArrayGetCell(gArray_NodeEnd,		iNodeStart)
	new Array:arrayFlags	= ArrayGetCell(gArray_NodeFlags,	iNodeStart)
	new Array:arrayHeight	= ArrayGetCell(gArray_NodeHeight,	iNodeStart)
	new Array:arrayDistance	= ArrayGetCell(gArray_NodeDistance,	iNodeStart)
	
	for (new iPath = ArraySize(arrayEnd) - 1; 0 <= iPath; iPath--)
	{
		// 如果iNodeEnd是iNodeStart的终点之一
		if (ArrayGetCell(arrayEnd, iPath) == iNodeEnd)
		{
			/** 删除此路径 */
			ArrayDeleteItem(arrayEnd,	iPath)
			ArrayDeleteItem(arrayFlags,	iPath)
			ArrayDeleteItem(arrayHeight,	iPath)
			ArrayDeleteItem(arrayDistance,	iPath)
			
			/** iNodeStart不再是iNodeEnd的起点 */
			arrayStart = ArrayGetCell(gArray_NodeStart, iNodeEnd)
			for (iPath = ArraySize(arrayStart) - 1; 0 <= iPath; iPath--)
			{
				if (ArrayGetCell(arrayStart, iPath) == iNodeStart)
				{
					ArrayDeleteItem(arrayStart, iPath)
					break
				}
			}
			
			NavNode_DrawMesh(id, iNodeStart, true, 5, 5, 25, 255, 0, 0)
			NavNode_DrawMesh(id, iNodeEnd, false, 5, 5, 25, 255, 0, 0)
			client_print(id, print_chat, "%L", LANG_SERVER, "PATH_DISCONNECT", iNodeStart, iNodeEnd)
			return
		}
	}
	
	/** 将iNodeEnd设为iNodeStart的终点之一 */
	new Float:origin[3], Float:dest[3]
	ArrayGetArray(gArray_NodePoint, iNodeStart,	origin)
	ArrayGetArray(gArray_NodePoint, iNodeEnd,	dest)
	ArrayPushCell(arrayEnd,		iNodeEnd)
	ArrayPushCell(arrayFlags,	ArrayGetCell(gArray_NodeDucking, iNodeEnd) ? PF_CrouchRun : PF_Walk)
	ArrayPushCell(arrayHeight,	0.0)
	ArrayPushCell(arrayDistance,	VecDistance(origin, dest))
	
	/** 将iNodeStart设为iNodeEnd的起点之一 */
	ArrayPushCell(ArrayGetCell(gArray_NodeStart, iNodeEnd), iNodeStart)
	
	NavNode_DrawMesh(id, iNodeStart, true, 5, 5, 25, 255, 0, 0)
	NavNode_DrawMesh(id, iNodeEnd, false, 5, 5, 25, 255, 0, 0)
	client_print(id, print_chat, "%L", LANG_SERVER, "PATH_CONNECT", iNodeStart, iNodeEnd)
}

NavSysMenu_ChangePathFlags(id, bool:climb)
{
	new nodeNums = ArraySize(gArray_Selected)
	if (nodeNums != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, climb ? "PATH_CHANGE_FLAG_FAILED3" : "PATH_CHANGE_FLAG_FAILED1")
		return
	}
	
	new iNodeStart = ArrayGetCell(gArray_Selected, 0)
	new iNodeEnd = ArrayGetCell(gArray_Selected, 1)
	ArrayClear(gArray_Selected)
	
	new iPath, Array:arrayEnd = ArrayGetCell(gArray_NodeEnd, iNodeStart)
	for (iPath = ArraySize(arrayEnd) - 1; 0 <= iPath; iPath--)
	{
		if (ArrayGetCell(arrayEnd, iPath) == iNodeEnd)
		{
			new Array:arrayFlags = ArrayGetCell(gArray_NodeFlags, iNodeStart)
			
			new PathFlags:pathFlags = ArrayGetCell(arrayFlags, iPath)
			
			if (climb)
			{
				if (pathFlags & PF_Climb)
				{
					pathFlags &= ~PF_Climb
					client_print(id, print_chat, "%L", LANG_SERVER, "PATH_SUB_FLAG2", iNodeStart, iNodeEnd)
				}
				else
				{
					pathFlags |= PF_Climb
					client_print(id, print_chat, "%L", LANG_SERVER, "PATH_ADD_FLAG2", iNodeStart, iNodeEnd)
				}
			}
			else
			{
				if (pathFlags & PF_CrouchRun)
				{
					pathFlags &= ~PF_CrouchRun
					client_print(id, print_chat, "%L", LANG_SERVER, "PATH_SUB_FLAG1", iNodeStart, iNodeEnd)
				}
				else
				{
					pathFlags |= PF_CrouchRun
					client_print(id, print_chat, "%L", LANG_SERVER, "PATH_ADD_FLAG1", iNodeStart, iNodeEnd)
				}
			}
			ArraySetCell(arrayFlags, iPath, pathFlags)
			return
		}
	}
	
	client_print(id, print_chat, "%L", LANG_SERVER, climb ? "PATH_CHANGE_FLAG_FAILED4" : "PATH_CHANGE_FLAG_FAILED2", iNodeEnd, iNodeStart)
}

NavSysMenu_ChangePathHeight(id)
{
	new nodeNums = ArraySize(gArray_Selected)
	if (nodeNums != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "PATH_CHANGE_HEIGHT_FAILED1")
		return
	}
	
	new iNode1 = ArrayGetCell(gArray_Selected, 0)
	new iNode2 = ArrayGetCell(gArray_Selected, 1)
	
	new iPath, Array:arrayEnd = ArrayGetCell(gArray_NodeEnd, iNode1)
	for (iPath = ArraySize(arrayEnd) - 1; 0 <= iPath && ArrayGetCell(arrayEnd, iPath) != iNode2; iPath--) { }
	if (iPath < 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "PATH_CHANGE_HEIGHT_FAILED2", iNode2, iNode1)
		return
	}
	
	new Float:origin[3], Float:viewOfs[3]
	pev(id, pev_origin, origin)
	pev(id, pev_view_ofs, viewOfs)
	VecAdd(origin, viewOfs, origin)
	
	new Float:start[3], Float:mid[3], Float:end[3]
	NavNode_GetPathCoord(iNode1, iNode2, iPath, start, mid, end)
	
	new Float:vecX[3]
	vecX[0] = mid[0] - origin[0]
	vecX[1] = mid[1] - origin[1]
	new Float:vecLenX = VecLength2D(vecX)
	
	new Float:angles[3], Float:vecIdeal[3], Float:dest[3]
	pev(id, pev_v_angle, angles)
	angles[1] = floatatan2(vecX[1], vecX[0], degrees)
	AngleVector(angles, ANGLEVECTOR_FORWARD, vecIdeal)
	VecAddScaled(origin, vecIdeal, vecLenX * vecLenX / VecDot(vecX, vecIdeal), dest)
	
	start[2] -= ArrayGetCell(gArray_NodeDucking, iNode1) ? 12.0 : 30.0
	end[2] -= ArrayGetCell(gArray_NodeDucking, iNode2) ? 12.0 : 30.0
	
	new Array:arrayHeight = ArrayGetCell(gArray_NodeHeight, iNode1)
	new Float:oldHeight = ArrayGetCell(arrayHeight, iPath)
	new Float:height = float(clamp(floatround(dest[2] - start[2]), 0, floatround(dJumpHeight + 18)))
	ArraySetCell(arrayHeight, iPath, height)
	
	client_print(id, print_chat, "%L", LANG_SERVER, "PATH_CHANGE_HEIGHT", iNode1, iNode2, oldHeight, height)
	
	mid[2] = start[2] + height
	AngleVector(angles, ANGLEVECTOR_RIGHT, vecIdeal)
	VecAddScaled(mid, vecIdeal, 16.0, dest)
	
	SendMsg_BeamPoints(id, start, mid, gMdlId_BeamNode, 30, 10, 0, 218, 0, 0)
	SendMsg_BeamPoints(id, mid, end, gMdlId_BeamNode, 30, 10, 0, 218, 0, 0)
	SendMsg_BeamPoints(id, mid, dest, gMdlId_BeamNode, 30, 10, 0, 218, 0, 218)
}

native Array:NavSys_Pathfinding(iNodeOrigin, iNodeGoal, &iWaypointFinal, maxTickCount = -1)
NavSysMenu_Test1(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST1_NAME")
	
	if (ArraySize(gArray_Selected) != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST1_FAILED1")
		return
	}
	
	new iNodeOrigin = ArrayGetCell(gArray_Selected, 0)
	new iNodeGoal = ArrayGetCell(gArray_Selected, 1)
	
	new timeLeft = tickcount()
	new iWaypointFinal
	new Array:arrayWaypoint = NavSys_Pathfinding(iNodeOrigin, iNodeGoal, iWaypointFinal)
	
	timeLeft = tickcount() - timeLeft
	
	if (iWaypointFinal < 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST1_FAILED2", ArraySize(arrayWaypoint), timeLeft)
		return
	}
	
	new iColor, colorRGB[3][3]
	colorRGB[0] = { 255, 0, 0 }
	colorRGB[1] = { 0, 255, 0 }
	colorRGB[2] = { 0, 0, 255 }
	
	new nodeNums = -1
	new waypoint[7], Float:start[3], Float:end[3]
	while (0 < iWaypointFinal)
	{
		ArrayGetArray(arrayWaypoint, iWaypointFinal, waypoint)
		ArrayGetArray(gArray_NodePoint, waypoint[4], start)
		ArrayGetArray(gArray_NodePoint, waypoint[0], end)
		SendMsg_BeamPoints(id, start, end, gMdlId_BeamNode, 50, 10, 0, colorRGB[iColor][0], colorRGB[iColor][1], colorRGB[iColor][2])
		iColor = (iColor + 1) % 3
		nodeNums++
		iWaypointFinal = waypoint[5]
	}
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST1", iNodeOrigin, iNodeGoal, nodeNums, ArraySize(arrayWaypoint), timeLeft)
}

native NavSys_GetWaypointFinal(Array:arrayWaypoint, const Float:goal[3])
NavSysMenu_Test2(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST2_NAME")
	
	if (ArraySize(gArray_Selected) != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST2_FAILED")
		return
	}
	
	new iNodeOrigin = ArrayGetCell(gArray_Selected, 0)
	new iNodeGoal = ArrayGetCell(gArray_Selected, 1)
	
	new iWaypointFinal
	new Array:arrayWaypoint = NavSys_Pathfinding(iNodeOrigin, iNodeGoal, iWaypointFinal, 0)
	if (iWaypointFinal < 0)
	{
		new Float:goal[3]
		ArrayGetArray(gArray_NodePoint, iNodeGoal, goal)
		iWaypointFinal = NavSys_GetWaypointFinal(arrayWaypoint, goal)
	}
	
	new iColor, colorRGB[3][3]
	colorRGB[0] = { 255, 0, 0 }
	colorRGB[1] = { 0, 255, 0 }
	colorRGB[2] = { 0, 0, 255 }
	
	new iNodeFinal = -1
	new waypoint[7], Float:start[3], Float:end[3]
	while (0 < iWaypointFinal)
	{
		ArrayGetArray(arrayWaypoint, iWaypointFinal, waypoint)
		ArrayGetArray(gArray_NodePoint, waypoint[4], start)
		ArrayGetArray(gArray_NodePoint, waypoint[0], end)
		SendMsg_BeamPoints(id, start, end, gMdlId_BeamNode, 50, 10, 0, colorRGB[iColor][0], colorRGB[iColor][1], colorRGB[iColor][2])
		iColor = (iColor + 1) % 3
		iWaypointFinal = waypoint[5]
		
		if (iNodeFinal < 0) iNodeFinal = waypoint[0]
	}
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST2", iNodeFinal)
}

native NavSys_GetWaypointSecond(Array:arrayWaypoint, iWaypointFinal, waypoint[7])
NavSysMenu_Test3(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST3_NAME")
	
	if (ArraySize(gArray_Selected) != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST3_FAILED")
		return
	}
	
	new iNodeOrigin = ArrayGetCell(gArray_Selected, 0)
	new iNodeGoal = ArrayGetCell(gArray_Selected, 1)
	
	new iWaypointFinal
	new Array:arrayWaypoint = NavSys_Pathfinding(iNodeOrigin, iNodeGoal, iWaypointFinal, 0)
	
	if (iWaypointFinal < 0)
	{
		new Float:goal[3]
		ArrayGetArray(gArray_NodePoint, iNodeGoal, goal)
		iWaypointFinal = NavSys_GetWaypointFinal(arrayWaypoint, goal)
	}
	
	new waypoint[7], Float:start[3], Float:end[3]
	NavSys_GetWaypointSecond(arrayWaypoint, iWaypointFinal, waypoint)
	ArrayGetArray(gArray_NodePoint, waypoint[4], start)
	ArrayGetArray(gArray_NodePoint, waypoint[0], end)
	SendMsg_BeamPoints(id, start, end, gMdlId_BeamNode, 50, 10, 0, 255, 0, 0)
	
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST3", waypoint[0])
}

native NavSys_GetWaypointPathInfo(Array:arrayWaypoint, iWaypointFinal, const Float:origin[3], &iNodeStart, &iNodeEnd, &iPath)
NavSysMenu_Test4(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST4_NAME")
	
	if (ArraySize(gArray_Selected) != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST4_FAILED")
		return
	}
	
	new iNodeOrigin = ArrayGetCell(gArray_Selected, 0)
	new iNodeGoal = ArrayGetCell(gArray_Selected, 1)
	
	new iWaypointFinal
	new Array:arrayWaypoint = NavSys_Pathfinding(iNodeOrigin, iNodeGoal, iWaypointFinal, 0)
	
	if (iWaypointFinal < 0)
	{
		new Float:goal[3]
		ArrayGetArray(gArray_NodePoint, iNodeGoal, goal)
		iWaypointFinal = NavSys_GetWaypointFinal(arrayWaypoint, goal)
	}
	
	new waypoint[7], Float:origin[3], iNodeStart, iNodeEnd, iPath
	pev(id, pev_origin, origin)
	NavSys_GetWaypointPathInfo(arrayWaypoint, iWaypointFinal, origin, iNodeStart, iNodeEnd, iPath)
	
	new iColor, colorRGB[3][3]
	colorRGB[0] = { 255, 0, 0 }
	colorRGB[1] = { 0, 255, 0 }
	colorRGB[2] = { 0, 0, 255 }
	
	new nodeNums = -1
	new Float:start[3], Float:end[3]
	while (0 < iWaypointFinal && (nodeNums < 0 || waypoint[4] != iNodeStart))
	{
		ArrayGetArray(arrayWaypoint, iWaypointFinal, waypoint)
		ArrayGetArray(gArray_NodePoint, waypoint[4], start)
		ArrayGetArray(gArray_NodePoint, waypoint[0], end)
		SendMsg_BeamPoints(id, start, end, gMdlId_BeamNode, 50, 10, 0, colorRGB[iColor][0], colorRGB[iColor][1], colorRGB[iColor][2])
		iColor = (iColor + 1) % 3
		nodeNums++
		iWaypointFinal = waypoint[5]
	}
	SendMsg_BeamPoints(id, origin, start, gMdlId_BeamNode, 50, 10, 0, 255, 255, 255)
	
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST4", iNodeStart, iPath, iNodeEnd)
}

native Array:NavSys_GetSpawnPos()
NavSysMenu_Test5(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST5_NAME")
	
	new Array:arraySpawnPos = NavSys_GetSpawnPos()
	new spawnPosNums = ArraySize(arraySpawnPos)
	new Float:spawnPos[6], Float:vecSrc[3], Float:vecDest[3]
	for (new i; i < spawnPosNums; i++)
	{
		ArrayGetArray(arraySpawnPos, i, spawnPos)
		vecSrc[0] = spawnPos[0]
		vecSrc[1] = spawnPos[1]
		vecSrc[2] = spawnPos[2] - 36.0
		vecDest[0] = vecSrc[0]
		vecDest[1] = vecSrc[1]
		vecDest[2] = vecSrc[2] + 72.0
		SendMsg_BeamPoints(id, vecSrc, vecDest, gMdlId_BeamNode, 50, 10, 0, 0, 255, 0)
		vecDest[0] = vecSrc[0] + spawnPos[3] * 32.0
		vecDest[1] = vecSrc[1] + spawnPos[4] * 32.0
		vecDest[2] = vecSrc[2] + spawnPos[5] * 32.0
		SendMsg_BeamPoints(id, vecSrc, vecDest, gMdlId_BeamNode, 50, 20, 0, 255, 0, 255)
	}
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST5", spawnPosNums)
}

native Array:NavSys_GetLadder()
NavSysMenu_Test6(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST6_NAME")
	
	new Array:arrayLadder = NavSys_GetLadder()
	new iLadderEnt, solidType
	new ladderNums = ArraySize(arrayLadder)
	new Float:absMin[3], Float:absMax[3], Float:origin[3], Float:start[3], Float:end[3], Float:normal[3]
	new iVec, Float:vecLong[8][3], Float:vecShort[8][3]
	vecLong[0] = Float:{ 9999.0, 9999.0, 0.0 }
	vecLong[1] = Float:{ -9999.0, 9999.0, 0.0 }
	vecLong[2] = Float:{ -9999.0, -9999.0, 0.0 }
	vecLong[3] = Float:{ 9999.0, -9999.0, 0.0 }
	vecLong[4] = Float:{ 0.0, 9999.0, 9999.0 }
	vecLong[5] = Float:{ 0.0, -9999.0, 9999.0 }
	vecLong[6] = Float:{ 0.0, -9999.0, -9999.0 }
	vecLong[7] = Float:{ 0.0, 9999.0, -9999.0 }
	vecShort[0] = Float:{ 0.01, 0.01, 0.0 }
	vecShort[1] = Float:{ -0.01, 0.01, 0.0 }
	vecShort[2] = Float:{ -0.01, -0.01, 0.0 }
	vecShort[3] = Float:{ 0.01, -0.01, 0.0 }
	vecShort[4] = Float:{ 0.0, 0.01, 0.01 }
	vecShort[5] = Float:{ 0.0, -0.01, 0.01 }
	vecShort[6] = Float:{ 0.0, -0.01, -0.01 }
	vecShort[7] = Float:{ 0.0, 0.01, -0.01 }
	
	for (new i; i < ladderNums; i++)
	{
		iLadderEnt = ArrayGetCell(arrayLadder, i)
		solidType = pev(iLadderEnt, pev_solid)
		set_pev(iLadderEnt, pev_solid, SOLID_BSP)
		
		pev(iLadderEnt, pev_mins, absMin)
		pev(iLadderEnt, pev_maxs, absMax)
		pev(iLadderEnt, pev_origin, origin)
		
		VecAdd(origin, absMin, absMin)
		VecAdd(origin, absMax, absMax)
		origin[0] = (absMin[0] + absMax[0]) * 0.5
		origin[1] = (absMin[1] + absMax[1]) * 0.5
		origin[2] = (absMin[2] + absMax[2]) * 0.5
		
		for (iVec = 3; 0 <= iVec; iVec--)
		{
			VecAdd(origin, vecLong[iVec], end)
			
			engfunc(EngFunc_TraceLine, origin, end, dTraceIgnore, iLadderEnt, 0)
			get_tr2(0, TR_vecEndPos, end)
			
			VecAdd(end, vecShort[iVec], end)
			
			engfunc(EngFunc_TraceLine, end, origin, dTraceIgnore, 0, 0)
			if (get_tr2(0, TR_pHit) == iLadderEnt) break
		}
		if (iVec < 0)
		{
			set_pev(iLadderEnt, pev_solid, solidType)
			continue
		}
		
		get_tr2(0, TR_vecPlaneNormal, normal)
		
		if (normal[2] == 0.0)
		{
			start[0] = origin[0]
			start[1] = origin[1]
			start[2] = absMin[2]
			end[0] = origin[0]
			end[1] = origin[1]
			end[2] = absMax[2]
		}
		else
		{
			VectorAngle(normal, normal)
			normal[0] *= -1.0
			AngleVector(normal, ANGLEVECTOR_UP, normal)
			VecAddScaled(origin, normal, 72.0, end)
			VecSubScaled(origin, normal, (origin[2] - absMin[2]) / normal[2], start)
			VecAddScaled(origin, normal, (absMax[2] - origin[2]) / normal[2], end)
		}
		SendMsg_BeamPoints(id, start, end, gMdlId_BeamNode, 50, 10, 0, 255, 0, 255)
		
		set_pev(iLadderEnt, pev_solid, solidType)
	}
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST6", ladderNums)
}

NavSysMenu_Test7(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST7_NAME")
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	new Float:absMin[3], Float:absMax[3]
	if (NavBox_Exist(origin))
	{
		NavBox_GetContain(origin, absMin, absMax)
		NavBox_Draw(id, absMin, absMax, 50, 10, 0, 255, 0, 255)
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST7_DRAW_CONTAIN")
	}
	else
	{
		NavBox_GetNearest(origin, absMin, absMax)
		NavBox_Draw(id, absMin, absMax, 50, 10, 0, 255, 0, 0)
		NavBox_Draw(id, gMapAbsMin, gMapAbsMax, 50, 10, 0, 255, 0, 0)
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST7_DRAW_NEAREST")
	}
}

NavSysMenu_Test8(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST8_NAME")
	
	if (ArraySize(gArray_NodeDucking) == 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "NODE_NOT_FOUND")
		return
	}
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	new Float:absMin[3], Float:absMax[3]
	if (NavBox_Exist(origin))
	{
		NavBox_GetContain(origin, absMin, absMax)
		NavBox_Draw(id, absMin, absMax, 50, 10, 0, 16, 16, 16)
		new iNode, Array:arrayNode = NavBox_GetNodeArray(origin)
		for (new i = ArraySize(arrayNode) - 1; 0 <= i; i--)
		{
			iNode = ArrayGetCell(arrayNode, i)
			NavNode_DrawMesh(id, iNode, false, 50, 10, 0, 128, 0, 128)
		}
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST8_DRAW_CONTAIN", ArraySize(arrayNode))
	}
	else
	{
		NavBox_GetNearest(origin, absMin, absMax)
		NavBox_Draw(id, absMin, absMax, 50, 10, 0, 16, 16, 16)
		new iNode, Array:arrayNode = NavBox_GetNodeArray(absMin)
		for (new i = ArraySize(arrayNode) - 1; 0 <= i; i--)
		{
			iNode = ArrayGetCell(arrayNode, i)
			NavNode_DrawMesh(id, iNode, false, 50, 10, 0, 128, 0, 0)
		}
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST8_DRAW_NEAREST", ArraySize(arrayNode))
	}
}

NavSysMenu_Test9(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST9_NAME")
	
	if (ArraySize(gArray_NodeDucking) == 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "NODE_NOT_FOUND")
		return
	}
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	new timeLeft = tickcount()
	new iNode = NavBox_GetNode(origin)
	timeLeft = tickcount() - timeLeft
	
	NavNode_DrawMesh(id, iNode, false, 50, 10, 0, 255, 0, 255)
	
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST9", iNode, timeLeft)
}

NavSysMenu_Test10(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST10_NAME")
	
	if (ArraySize(gArray_NodeDucking) == 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "NODE_NOT_FOUND")
		return
	}
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	new timeLeft = tickcount()
	new iNode = NavBox_GetNodeNearest(origin)
	timeLeft = tickcount() - timeLeft
	
	NavNode_DrawMesh(id, iNode, false, 50, 10, 0, 255, 0, 255)
	
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST10", iNode, timeLeft)
}

NavSysMenu_Test11(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST11_NAME")
	
	if (ArraySize(gArray_NodeDucking) == 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "NODE_NOT_FOUND")
		return
	}
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	if (NavBox_Exist(origin))
	{
		new timeLeft = tickcount()
		new iNode = NavBox_GetNodeContain(origin)
		timeLeft = tickcount() - timeLeft
		
		if (iNode < 0) client_print(id, print_chat, "%L", LANG_SERVER, "TEST11_FAILED")
		else
		{
			NavNode_DrawMesh(id, iNode, false, 50, 10, 0, 255, 0, 255)
			
			client_print(id, print_chat, "%L", LANG_SERVER, "TEST11", iNode, timeLeft)
		}
	}
	else client_print(id, print_chat, "%L", LANG_SERVER, "TEST11_FAILED")
}

NavSysMenu_Test12(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST12_NAME")
	
	if (ArraySize(gArray_NodeDucking) == 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "NODE_NOT_FOUND")
		return
	}
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	if (NavBox_Exist(origin))
	{
		new Float:absMin[3], Float:absMax[3]
		pev(id, pev_mins, absMin)
		pev(id, pev_maxs, absMax)
		VecAdd(origin, absMin, absMin)
		VecAdd(origin, absMax, absMax)
		
		new timeLeft = tickcount()
		new iNode = NavBox_GetNodeIntersect(absMin, absMax)
		timeLeft = tickcount() - timeLeft
		
		if (iNode < 0) client_print(id, print_chat, "%L", LANG_SERVER, "TEST12_FAILED")
		else
		{
			NavNode_DrawMesh(id, iNode, false, 50, 10, 0, 255, 0, 255)
			
			client_print(id, print_chat, "%L", LANG_SERVER, "TEST12", iNode, timeLeft)
		}
	}
	else client_print(id, print_chat, "%L", LANG_SERVER, "TEST12_FAILED")
}

NavSysMenu_Test13(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST13_NAME")
	
	if (!ArraySize(gArray_Selected))
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST13_FAILED")
		return
	}
	
	new iNode
	for (new i = ArraySize(gArray_Selected) - 1; 0 <= i; i--)
	{
		iNode = ArrayGetCell(gArray_Selected, i)
		
		NavNode_DrawBox(id, iNode, 50, 10, 0, 255, 0, 255)
	}
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST13", ArraySize(gArray_Selected))
}

NavSysMenu_Test14(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST14_NAME")
	
	if (ArraySize(gArray_NodeDucking) == 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "NODE_NOT_FOUND")
		return
	}
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	new timeLeft = tickcount()
	new iNode = NavNode_GetNearest(origin)
	timeLeft = tickcount() - timeLeft
	
	NavNode_DrawMesh(id, iNode, false, 50, 10, 0, 255, 0, 255)
	
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST14", iNode, timeLeft)
}

NavSysMenu_Test15(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST15_NAME")
	
	if (ArraySize(gArray_Selected) != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST15_FAILED1")
		return
	}
	
	new iNodeStart = ArrayGetCell(gArray_Selected, 0)
	new iNodeEnd = ArrayGetCell(gArray_Selected, 1)
	
	new Array:arrayEnd = ArrayGetCell(gArray_NodeEnd, iNodeStart)
	new iPath
	for (iPath = ArraySize(arrayEnd) - 1; 0 <= iPath && ArrayGetCell(arrayEnd, iPath) != iNodeEnd; iPath--) { }
	
	if (iPath < 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST15_FAILED2", iNodeStart, iNodeEnd)
		return
	}
	
	new Float:start[3], Float:mid[3], Float:end[3]
	NavNode_GetPathCoord(iNodeStart, iNodeEnd, iPath, start, mid, end)
	
	SendMsg_BeamPoints(id, start, mid, gMdlId_BeamNode, 50, 10, 0, 192, 0, 0)
	SendMsg_BeamPoints(id, mid, end, gMdlId_BeamNode, 50, 10, 0, 0, 0, 192)
	
	if (ArrayGetCell(gArray_NodeDucking, iNodeStart)) { start[2] -= 12.0; mid[2] -= 12.0; }
	else { start[2] -= 30.0; mid[2] -= 30.0; }
	end[2] -= ArrayGetCell(gArray_NodeDucking, iNodeEnd) ? 12.0 : 30.0
	
	SendMsg_BeamPoints(id, start, mid, gMdlId_BeamPath1, 50, 20, 0, 255, 0, 0)
	SendMsg_BeamPoints(id, mid, end, gMdlId_BeamPath1, 50, 20, 0, 0, 0, 255)
	
	NavNode_DrawBox(id, iNodeStart, 50, 10, 0, 16, 16, 16)
	NavNode_DrawBox(id, iNodeEnd, 50, 10, 0, 16, 16, 16)
	
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST15", iNodeStart, iNodeEnd)
}

NavSysMenu_Test16(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST16_NAME")
	
	if (ArraySize(gArray_Selected) != 2)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST16_FAILED1")
		return
	}
	
	new iNodeStart = ArrayGetCell(gArray_Selected, 0)
	new iNodeEnd = ArrayGetCell(gArray_Selected, 1)
	
	new Array:arrayEnd = ArrayGetCell(gArray_NodeEnd, iNodeStart)
	new iPath
	for (iPath = ArraySize(arrayEnd) - 1; 0 <= iPath && ArrayGetCell(arrayEnd, iPath) != iNodeEnd; iPath--) { }
	
	if (iPath < 0)
	{
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST16_FAILED2", iNodeStart, iNodeEnd)
		return
	}
	
	new PathFlags:flags, Float:height, Float:top[3], Float:bottom[3]
	NavNode_GetPathCoord2(iNodeStart, iNodeEnd, iPath, flags, height, top)
	
	bottom[0] = top[0]
	bottom[1] = top[1]
	bottom[2] = top[2] - (ArrayGetCell(gArray_NodeDucking, iNodeEnd) ? 12.0 : 30.0)
	
	SendMsg_BeamPoints(id, top, bottom, gMdlId_BeamNode, 50, 10, 0, 255, 0, 255)
	
	NavNode_DrawBox(id, iNodeStart, 50, 10, 0, 16, 16, 16)
	NavNode_DrawBox(id, iNodeEnd, 50, 10, 0, 16, 16, 16)
	
	if (flags == PF_Walk)		client_print(id, print_chat, "%L", LANG_SERVER, "TEST16_WALK", height)
	else if (flags == PF_CrouchRun)	client_print(id, print_chat, "%L", LANG_SERVER, "TEST16_CROHCURUN", height)
	else if (flags == PF_Climb)	client_print(id, print_chat, "%L", LANG_SERVER, "TEST16_CLIMb", height)
	else 				client_print(id, print_chat, "%L", LANG_SERVER, "TEST16_CROUCHCLIMB", height)
	
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST16", iNodeStart, iNodeEnd)
}

NavSysMenu_Test17(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST17_NAME")
	
	new bool:duckingStart, Float:start[3], Float:goal[3]
	new bool:duckingEnd, Float:end[3], Float:normal[3]
	new bool:crouchRun, Float:height
	
	duckingStart = pev(id, pev_flags) & FL_DUCKING ? true : false
	pev(id, pev_origin, start)
	pev(id, pev_v_angle, goal)
	goal[0] = start[0] + floatcos(goal[1], degrees) * 32.0
	goal[1] = start[1] + floatsin(goal[1], degrees) * 32.0
	
	if (NavPath_Exist(duckingStart, start, goal, duckingEnd, end, normal, crouchRun, height))
	{
		start[2] -= duckingStart ? 18.0 : 36.0
		end[2] -= duckingEnd ? 18.0 : 36.0
		SendMsg_BeamPoints(id, start, end, gMdlId_BeamPath1, 50, 10, 0, 255, 0, 255)
		
		client_print(id, print_chat, "%L", LANG_SERVER, duckingEnd ? "TEST17_END_STATE2" : "TEST17_END_STATE1")
		client_print(id, print_chat, "%L", LANG_SERVER, crouchRun ? "TEST17_CROUCHRUN2" : "TEST17_CROUCHRUN1")
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST17_HEIGHT", height)
		
		return
	}
	
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST17_FAILED")
}


NavSysMenu_Test18(id)
{
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST18_NAME")
	
	new bool:duckingStart, Float:start[3], Float:goal[3]
	new bool:duckingEnd, Float:end[3], Float:normal[3]
	new bool:crouchRun, Float:height
	
	duckingStart = pev(id, pev_flags) & FL_DUCKING ? true : false
	pev(id, pev_origin, start)
	pev(id, pev_v_angle, goal)
	goal[0] = start[0] + floatcos(goal[1], degrees) * 32.0
	goal[1] = start[1] + floatsin(goal[1], degrees) * 32.0
	
	if (NavPath_Exist2(duckingStart, start, goal, duckingEnd, end, normal, crouchRun, height))
	{
		start[2] -= duckingStart ? 18.0 : 36.0
		end[2] -= duckingEnd ? 18.0 : 36.0
		SendMsg_BeamPoints(id, start, end, gMdlId_BeamPath1, 50, 10, 0, 255, 0, 255)
		
		client_print(id, print_chat, "%L", LANG_SERVER, duckingEnd ? "TEST18_END_STATE2" : "TEST18_END_STATE1")
		client_print(id, print_chat, "%L", LANG_SERVER, crouchRun ? "TEST18_CROUCHRUN2" : "TEST18_CROUCHRUN1")
		client_print(id, print_chat, "%L", LANG_SERVER, "TEST18_HEIGHT", height)
		
		return
	}
	
	client_print(id, print_chat, "%L", LANG_SERVER, "TEST18_FAILED")
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg936\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset134 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2052\\ f0\\ fs16 \n\\ par }
*/
