#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <xs>
#include <zombieplague>
#include <NavigationSystem>
#include <reapi>

//native zl_boss_map();												// Проверка на карты Боссов [boss_basic.sma]
//native zl_boss_valid(id);											// Проверка валидности Босса [boss_basic.sma]

const zombie_blood = 83;											// Цвет крови Зомби
const zombie_limit = 16;											// Лимит NPC Зомби
const Float:time_attack = 0.5;										// Время атаки при соприкосновении с игроком
const Float:time_delete = 1.5;										// Время на удаление NPC

new const ZmClassicMdl[] = "models/npc_zombies/classic/classic.mdl";
new const ZmDeimosMdl[] = "models/npc_zombies/deimos/deimos.mdl";
new const ZmGhostMdl[] = "models/npc_zombies/ghost/ghost.mdl";
new const ZmHealMdl[] = "models/npc_zombies/heal/heal.mdl";
new const ZmWitchMdl[] = "models/npc_zombies/witch/witch.mdl";
new const ZmBigMdl[] = "models/npc_zombies/big/big.mdl";
new const ZmHoundMdl[] = "models/npc_zombies/hound/hound.mdl";
new const GrenadeMdl[] = "models/weapons/w_models8.mdl";

new const SoundClassic[][] = { "npc_zombies/allfunc/classic_dead_1.wav", "npc_zombies/allfunc/hitnormal_personage.wav", "npc_zombies/allfunc/classic_idle_1.wav" };
new const SoundDeimos[][] = { "npc_zombies/allfunc/deimos_dead_1.wav", "npc_zombies/allfunc/hitnormal_personage.wav", "npc_zombies/allfunc/deimos_idle_1.wav" };
new const SoundGhost[][] = { "npc_zombies/allfunc/ghost_dead_1.wav", "npc_zombies/allfunc/hitnormal_personage.wav", "npc_zombies/allfunc/ghost_idle_1.wav" };
new const SoundHeal[][] = { "npc_zombies/allfunc/healer_dead_1.wav", "npc_zombies/allfunc/hitnormal_personage.wav", "npc_zombies/allfunc/healer_idle_1.wav" };
new const SoundWitch[][] = { "npc_zombies/allfunc/witch_dead_1.wav", "npc_zombies/allfunc/hitnormal_personage.wav", "npc_zombies/allfunc/witch_idle_1.wav" };
new const SoundBig[][] = { "npc_zombies/allfunc/big_dead_2.wav", "npc_zombies/allfunc/hitnormal_personage.wav", "npc_zombies/allfunc/big_idle_2.wav" };
new const SoundHound[][] = { "npc_zombies/allfunc/hound_dead_1.wav", "npc_zombies/allfunc/hitnormal_personage.wav", "npc_zombies/allfunc/hound_idle_1.wav" };

// === PATCH: per-NPC target + roaming ===

const Float:ZM_RETARGET_TIME = 2.0;  // как часто пересчитывать ближайшую цель
const Float:ZM_ROAM_REACH_DIST = 120.0; // насколько близко к roam-точке считать "дошел"

// === PATHFIND OPT CACHE ===
const Float:ZM_PATH_UPDATE_TIME = 0.6;   // как часто реально пересчитывать путь (0.3-0.6)
const Float:ZM_THINK_TIME = 0.25;         // базовый think
const ZM_PATHFIND_TICK_LIMIT = 5;         // было 20, уменьшаем лимит

//#define MAX_EDICTS 2048
#define TASK_REMOVE_TEMP 9000

new g_lastNodeOrigin[MAX_EDICTS+1];
new g_lastNodeGoal[MAX_EDICTS+1];
new Float:g_nextPathUpdate[MAX_EDICTS+1];

new bool:g_haveCachedStep[MAX_EDICTS+1];
new Float:g_cachedDest[MAX_EDICTS+1][3];
new PathFlags:g_cachedFlags[MAX_EDICTS+1];
new Float:g_cachedHeight[MAX_EDICTS+1];
// === PATHFIND OPT CACHE END===

// === ADAPTIVE THINK (CPU saver) ===
const Float:ZM_THINK_NEAR = 0.18;   // близко к игроку
const Float:ZM_THINK_MID  = 0.28;   // средняя дистанция
const Float:ZM_THINK_FAR  = 0.45;   // далеко
const Float:ZM_THINK_IDLE = 0.65;   // нет живой цели (roam)

const Float:ZM_NEAR_DIST = 600.0;
const Float:ZM_FAR_DIST  = 1400.0;
// === ADAPTIVE THINK (CPU saver) END ===


// === OPT PATCH: fast NPC type (no classname contain) ===
enum _:ZombieType
{
 ZT_NONE = 0,
 ZT_CLASSIC,
 ZT_DEIMOS,
 ZT_GHOST,
 ZT_HEAL,
 ZT_WITCH,
 ZT_BIG,
 ZT_HOUND
};

#define ZM_PEV_TYPE pev_iuser4
// === OPT PATCH END ===

// цель (игрок) должна реально сместиться, чтобы мы пересчитали путь, иначе будет дерготня на границах нодов
const Float:ZM_GOAL_REPATH_DIST = 120.0;   // 80-160 обычно норм
new Float:g_lastGoalPos[MAX_EDICTS+1][3];  // позиция DEST при последнем успешном поиске пути


// === SMOOTH MOVE (anti-jitter) ===
const Float:ZM_VEL_LERP = 0.35;          // 0.25..0.45 (больше = резче)
const Float:ZM_MAX_YAW_SPEED = 240.0;      // градусов за think (меньше = плавнее)
const Float:ZM_STEP_REACH_DIST = 28.0;   // когда близко к шагу — разрешаем пересчёт
new bool:g_smoothInit[MAX_EDICTS+1];
new Float:g_smoothYaw[MAX_EDICTS+1];
new Float:g_smoothVel[MAX_EDICTS+1][3];
new Float:g_lastYawTime[MAX_EDICTS+1];
// === SMOOTH MOVE (anti-jitter) END ===

// === OPT PATCH: cache alive humans list ===
new g_humans[33];
new g_humanCount;
// === OPT PATCH END ===

static bool:TakeDamageFromZM;
static ZombieNpc[zombie_limit];
static ZombieNum, ZombieCount;
static Float:DamageHitPlayer[33];

static Healer_Sprite, Deimos_Sprite_Line, Deimos_Sprite_Exp, Grenade_Sprite_Exp;

const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4));

public plugin_init()
{
	register_plugin("Продвинутая система NPC-зомби для Zombie Plague с навигацией", "2.0b", "Alexander.3/[cfn]/Robert7791");
	
	// Останавливаем плагин, если не идет битва с Боссом или идет битва с Джаггернаутом
	//if(!zl_boss_map() || zl_boss_map() == 14) {
	//	pause("ad");
	//	return;
	//}
	
	//if(!zl_boss_map()) {
	//	pause("ad");
	//	return;
	//}


	RegisterHam(Ham_BloodColor, "monster_hevsuit_dead", "Hook_BloodColor");
	RegisterHam(Ham_Think, "monster_hevsuit_dead", "Hook_Think");
	RegisterHam(Ham_Touch, "monster_hevsuit_dead", "Hook_Touch");
	RegisterHam(Ham_Killed, "monster_hevsuit_dead", "Hook_Killed");
	
	register_touch("grenade_skill", "*", "fw_Weapon_Touch");
	
	register_touch("nst_deimos_skill", "*", "fw_DeimosSkill_Touch");
	
	TakeDamageFromZM = true;

	set_task(0.5, "ZM_RefreshHumans", .flags="b");

	register_forward(FM_ShouldCollide, "fw_ShouldCollide"); //NPC могли проходить друг через друга
	RegisterHookChain(RH_SV_AllowPhysent, "SV_AllowPhysent_Pre") //зомби-игроки могли проходить через npc-зомби
}

public plugin_precache()
{
	// Убираем прекеш, если не идет битва с Боссом или идет битва с Джаггернаутом
	//if(!zl_boss_map())
		//return;
		
	precache_model(ZmClassicMdl);
	precache_model(ZmDeimosMdl);
	precache_model(ZmGhostMdl);
	precache_model(ZmHealMdl);
	precache_model(ZmWitchMdl);
	precache_model(ZmBigMdl);
	precache_model(ZmHoundMdl);
	precache_model(GrenadeMdl);
	
	Healer_Sprite = precache_model("sprites/npc_zombies/abilityfunc/restore_health.spr");
	Deimos_Sprite_Line = precache_model("sprites/npc_zombies/abilityfunc/laserbeam.spr");
	Deimos_Sprite_Exp = precache_model("sprites/npc_zombies/abilityfunc/deimos_exp.spr");
	Grenade_Sprite_Exp = precache_model("sprites/npc_zombies/abilityfunc/deimos_exp.spr");
	
	for(new i; i < sizeof SoundClassic; ++i)
		precache_sound(SoundClassic[i]);
	
	for(new i; i < sizeof SoundDeimos; ++i)
		precache_sound(SoundDeimos[i]);
	
	for(new i; i < sizeof SoundGhost; ++i)
		precache_sound(SoundGhost[i]);
	
	for(new i; i < sizeof SoundHeal; ++i)
		precache_sound(SoundHeal[i]);
	
	for(new i; i < sizeof SoundWitch; ++i)
		precache_sound(SoundWitch[i]);
	
	for(new i; i < sizeof SoundBig; ++i)
		precache_sound(SoundBig[i]);
	
	for(new i; i < sizeof SoundHound; ++i)
		precache_sound(SoundHound[i]);
	
	precache_sound("npc_zombies/abilityfunc/td_heal.wav");
	precache_sound("npc_zombies/abilityfunc/deimos_start.wav");
	precache_sound("npc_zombies/abilityfunc/deimos_hit.wav");
	precache_sound("npc_zombies/abilityfunc/invisable_active.wav");
	precache_sound("npc_zombies/abilityfunc/zombie_bomb_explode01.wav");
}

public plugin_natives()
{
	register_native("zl_zmclassic_valid", "native_zl_zmclassic_valid", 1);
	register_native("zl_zmdeimos_valid", "native_zl_zmdeimos_valid", 1);
	register_native("zl_zmghost_valid", "native_zl_zmghost_valid", 1);
	register_native("zl_zmheal_valid", "native_zl_zmheal_valid", 1);
	register_native("zl_zmwitch_valid", "native_zl_zmwitch_valid", 1);
	register_native("zl_zmbig_valid", "native_zl_zmbig_valid", 1);
	register_native("zl_zmhound_valid", "native_zl_zmhound_valid", 1);
	
	register_native("zl_zombie_count", "native_zl_zombie_count", 1);
	register_native("zl_zombie_create", "native_zl_zombie_create", 1);
	register_native("zl_zombie_delete", "native_zl_zombie_delete", 1);
}

public ZM_RefreshHumans()
{
 g_humanCount = 0;

 for (new i = 1; i <= get_maxplayers(); i++)
 {
  if (!is_user_alive(i)) continue;
  if (zp_get_user_zombie(i)) continue;

  g_humans[g_humanCount++] = i;
 }
}

public native_zl_zombie_delete()
{
	for(new i = 0; i < zombie_limit; i++)
	{
			new ent = ZombieNpc[i];
			if (!pev_valid(ent)) continue;
			if (pev(ent, pev_deadflag) == DEAD_DYING) continue;
			{
				// Удаляем задачи, связанные с этим NPC
	         if(task_exists(ent+101)) remove_task(ent+101);
	         if(task_exists(ent+202)) remove_task(ent+202);
	         if(task_exists(ent+303)) remove_task(ent+303);
	         if(task_exists(ent+404)) remove_task(ent+404);
	         if(task_exists(ent+505)) remove_task(ent+505);
	         if(task_exists(ent+606)) remove_task(ent+606);

	         set_pev(ent, pev_velocity, {0.0, 0.0, 0.0});
	         set_pev(ent, pev_solid, SOLID_NOT);
	         set_pev(ent, pev_deadflag, DEAD_DYING);

	         static ClassName[63];
	         pev(ent, pev_classname, ClassName, charsmax(ClassName));

	         if(contain(ClassName, "NpcHound_" ) != -1)
	             Anim(ent, random_num(14, 15), 1.1);
	         else
	             Anim(ent, random_num(101, 102), 1.1);

	         set_task(time_delete, "Zombie_Delete", ent);
				
			 if(contain(ClassName, "NpcClassic_" ) != -1) engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, SoundClassic[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					
			 if(contain(ClassName, "NpcDeimos_" ) != -1) engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, SoundDeimos[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					
			 if(contain(ClassName, "NpcGhost_" ) != -1) engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, SoundGhost[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					
			 if(contain(ClassName, "NpcHeal_" ) != -1) engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, SoundHeal[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					
			 if(contain(ClassName, "NpcWitch_" ) != -1) engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, SoundWitch[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					
			 if(contain(ClassName, "NpcBig_" ) != -1) engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, SoundBig[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					
			 if(contain(ClassName, "NpcHound_" ) != -1) engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, SoundHound[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
		
	}
	
	//TakeDamageFromZM = false;
}

public native_zl_zombie_create(Float:Origin[3], Health, speed, damage)
{
	//if(ZombieCount >= zombie_limit)
		//return;
		
	ZombieNum = -1;
	for(new i = 0; i < zombie_limit; i++)
	{
		if(!pev_valid(ZombieNpc[i]))
		{
			ZombieNum = i;
			break;
		}
	}

	if (ZombieNum == -1)
    	return;
	
	param_convert(1);
	
	ZombieNpc[ZombieNum] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "monster_hevsuit_dead"));
	ClearPathCache(ZombieNpc[ZombieNum]);
	
	switch(random_num(1, 7))
	{
		case 1:
		{
			engfunc(EngFunc_SetModel, ZombieNpc[ZombieNum], ZmClassicMdl);
			engfunc(EngFunc_SetSize, ZombieNpc[ZombieNum], Float:{-15.0, -15.0, -36.0}, Float:{15.0, 15.0, 96.0});
			engfunc(EngFunc_SetOrigin, ZombieNpc[ZombieNum], Origin);
			
			new ClassName[32];
			formatex(ClassName, charsmax(ClassName), "NpcClassic_%d", ZombieCount);
			
			set_pev(ZombieNpc[ZombieNum], pev_classname, ClassName);
			set_pev(ZombieNpc[ZombieNum], ZM_PEV_TYPE, ZT_CLASSIC);
			set_pev(ZombieNpc[ZombieNum], pev_solid, SOLID_BBOX);
			set_pev(ZombieNpc[ZombieNum], pev_movetype, MOVETYPE_PUSHSTEP);
			set_pev(ZombieNpc[ZombieNum], pev_takedamage, DAMAGE_YES);
			set_pev(ZombieNpc[ZombieNum], pev_health, (float(Health) * 0.25));
			set_pev(ZombieNpc[ZombieNum], pev_deadflag, DEAD_NO);
			set_pev(ZombieNpc[ZombieNum], pev_nextthink, get_gametime() + 0.1);
			set_pev(ZombieNpc[ZombieNum], pev_body, random_num(0, 2));
			
			drop_to_floor(ZombieNpc[ZombieNum]);
			Anim(ZombieNpc[ZombieNum], 4, 1.0);
			
			engfunc(EngFunc_EmitSound, ZombieNpc[ZombieNum], CHAN_VOICE, SoundClassic[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			
			new ability_grenade_classic = random_num(1, 3);
			
			if(ability_grenade_classic == 1 && zp_player_alive() > 0)
				set_task(5.0, "SkillGrenade", 505+ZombieNpc[ZombieNum]);
		}
		case 2:
		{
			engfunc(EngFunc_SetModel, ZombieNpc[ZombieNum], ZmDeimosMdl);
			engfunc(EngFunc_SetSize, ZombieNpc[ZombieNum], Float:{-15.0, -15.0, -36.0}, Float:{15.0, 15.0, 96.0});
			engfunc(EngFunc_SetOrigin, ZombieNpc[ZombieNum], Origin);
			
			new ClassName[32];
			formatex(ClassName, charsmax(ClassName), "NpcDeimos_%d", ZombieCount);
			
			set_pev(ZombieNpc[ZombieNum], pev_classname, ClassName);
			set_pev(ZombieNpc[ZombieNum], ZM_PEV_TYPE, ZT_DEIMOS);
			set_pev(ZombieNpc[ZombieNum], pev_solid, SOLID_BBOX);
			set_pev(ZombieNpc[ZombieNum], pev_movetype, MOVETYPE_PUSHSTEP);
			set_pev(ZombieNpc[ZombieNum], pev_takedamage, DAMAGE_YES);
			set_pev(ZombieNpc[ZombieNum], pev_health, (float(Health) * 1));
			set_pev(ZombieNpc[ZombieNum], pev_deadflag, DEAD_NO);
			set_pev(ZombieNpc[ZombieNum], pev_nextthink, get_gametime() + 0.1);
			set_pev(ZombieNpc[ZombieNum], pev_body, random_num(0, 1));
			
			drop_to_floor(ZombieNpc[ZombieNum]);
			Anim(ZombieNpc[ZombieNum], 4, 1.0);
			
			engfunc(EngFunc_EmitSound, ZombieNpc[ZombieNum], CHAN_VOICE, SoundDeimos[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			
			new ability_deimos = random_num(1, 3);
			
			if(ability_deimos == 1 && zp_player_alive() > 0)
				set_task(3.0, "SkillDeimos", 202+ZombieNpc[ZombieNum]);
		}
		case 3:
		{
			engfunc(EngFunc_SetModel, ZombieNpc[ZombieNum], ZmGhostMdl);
			engfunc(EngFunc_SetSize, ZombieNpc[ZombieNum], Float:{-15.0, -15.0, -36.0}, Float:{15.0, 15.0, 96.0});
			engfunc(EngFunc_SetOrigin, ZombieNpc[ZombieNum], Origin);
			
			new ClassName[32];
			formatex(ClassName, charsmax(ClassName), "NpcGhost_%d", ZombieCount);
			
			set_pev(ZombieNpc[ZombieNum], pev_classname, ClassName);
			set_pev(ZombieNpc[ZombieNum], ZM_PEV_TYPE, ZT_GHOST);
			set_pev(ZombieNpc[ZombieNum], pev_solid, SOLID_BBOX);
			set_pev(ZombieNpc[ZombieNum], pev_movetype, MOVETYPE_PUSHSTEP);
			set_pev(ZombieNpc[ZombieNum], pev_takedamage, DAMAGE_YES);
			set_pev(ZombieNpc[ZombieNum], pev_health, (float(Health) * 0.5));
			set_pev(ZombieNpc[ZombieNum], pev_deadflag, DEAD_NO);
			set_pev(ZombieNpc[ZombieNum], pev_nextthink, get_gametime() + 0.1);
			set_pev(ZombieNpc[ZombieNum], pev_body, random_num(0, 1));
			
			drop_to_floor(ZombieNpc[ZombieNum]);
			Anim(ZombieNpc[ZombieNum], 4, 1.0);
			
			engfunc(EngFunc_EmitSound, ZombieNpc[ZombieNum], CHAN_VOICE, SoundGhost[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			
			new ability_ghost = random_num(1, 3);
			
			if(ability_ghost == 1 && zp_player_alive() > 0)
				set_task(3.0, "SkillGhost", 303+ZombieNpc[ZombieNum]);
		}
		case 4:
		{
			engfunc(EngFunc_SetModel, ZombieNpc[ZombieNum], ZmHealMdl);
			engfunc(EngFunc_SetSize, ZombieNpc[ZombieNum], Float:{-15.0, -15.0, -36.0}, Float:{15.0, 15.0, 96.0});
			engfunc(EngFunc_SetOrigin, ZombieNpc[ZombieNum], Origin);
			
			new ClassName[32];
			formatex(ClassName, charsmax(ClassName), "NpcHeal_%d", ZombieCount);
			
			set_pev(ZombieNpc[ZombieNum], pev_classname, ClassName);
			set_pev(ZombieNpc[ZombieNum], ZM_PEV_TYPE, ZT_HEAL);
			set_pev(ZombieNpc[ZombieNum], pev_solid, SOLID_BBOX);
			set_pev(ZombieNpc[ZombieNum], pev_movetype, MOVETYPE_PUSHSTEP);
			set_pev(ZombieNpc[ZombieNum], pev_takedamage, DAMAGE_YES);
			set_pev(ZombieNpc[ZombieNum], pev_health, (float(Health) * 0.5));
			set_pev(ZombieNpc[ZombieNum], pev_deadflag, DEAD_NO);
			set_pev(ZombieNpc[ZombieNum], pev_nextthink, get_gametime() + 0.1);
			set_pev(ZombieNpc[ZombieNum], pev_body, random_num(0, 1));
			
			drop_to_floor(ZombieNpc[ZombieNum]);
			Anim(ZombieNpc[ZombieNum], 4, 1.0);
			
			engfunc(EngFunc_EmitSound, ZombieNpc[ZombieNum], CHAN_VOICE, SoundHeal[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			
			new ability_heal = random_num(1, 3);
			
			if(ability_heal == 1 && zp_player_alive() > 0)
				set_task(3.0, "SkillHeal", 101+ZombieNpc[ZombieNum]);
		}
		case 5:
		{
			engfunc(EngFunc_SetModel, ZombieNpc[ZombieNum], ZmWitchMdl);
			engfunc(EngFunc_SetSize, ZombieNpc[ZombieNum], Float:{-15.0, -15.0, -36.0}, Float:{15.0, 15.0, 96.0});
			engfunc(EngFunc_SetOrigin, ZombieNpc[ZombieNum], Origin);
			
			new ClassName[32];
			formatex(ClassName, charsmax(ClassName), "NpcWitch_%d", ZombieCount);
			
			set_pev(ZombieNpc[ZombieNum], pev_classname, ClassName);
			set_pev(ZombieNpc[ZombieNum], ZM_PEV_TYPE, ZT_WITCH);
			set_pev(ZombieNpc[ZombieNum], pev_solid, SOLID_BBOX);
			set_pev(ZombieNpc[ZombieNum], pev_movetype, MOVETYPE_PUSHSTEP);
			set_pev(ZombieNpc[ZombieNum], pev_takedamage, DAMAGE_YES);
			set_pev(ZombieNpc[ZombieNum], pev_health, (float(Health) * 0.5));
			set_pev(ZombieNpc[ZombieNum], pev_deadflag, DEAD_NO);
			set_pev(ZombieNpc[ZombieNum], pev_nextthink, get_gametime() + 0.1);
			set_pev(ZombieNpc[ZombieNum], pev_body, random_num(0, 1));
			
			drop_to_floor(ZombieNpc[ZombieNum]);
			Anim(ZombieNpc[ZombieNum], 4, 1.0);
			
			engfunc(EngFunc_EmitSound, ZombieNpc[ZombieNum], CHAN_VOICE, SoundWitch[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			
			new ability_grenade_witch = random_num(1, 3);
			
			if(ability_grenade_witch == 1 && zp_player_alive() > 0)
				set_task(5.0, "SkillGrenade", 505+ZombieNpc[ZombieNum]);
		}
		case 6:
		{
			engfunc(EngFunc_SetModel, ZombieNpc[ZombieNum], ZmBigMdl);
			engfunc(EngFunc_SetSize, ZombieNpc[ZombieNum], Float:{-15.0, -15.0, -36.0}, Float:{15.0, 15.0, 96.0});
			engfunc(EngFunc_SetOrigin, ZombieNpc[ZombieNum], Origin);
			
			new ClassName[32];
			formatex(ClassName, charsmax(ClassName), "NpcBig_%d", ZombieCount);
			
			set_pev(ZombieNpc[ZombieNum], pev_classname, ClassName);
			set_pev(ZombieNpc[ZombieNum], ZM_PEV_TYPE, ZT_BIG);
			set_pev(ZombieNpc[ZombieNum], pev_solid, SOLID_BBOX);
			set_pev(ZombieNpc[ZombieNum], pev_movetype, MOVETYPE_PUSHSTEP);
			set_pev(ZombieNpc[ZombieNum], pev_takedamage, DAMAGE_YES);
			set_pev(ZombieNpc[ZombieNum], pev_health, (float(Health) * 2));
			set_pev(ZombieNpc[ZombieNum], pev_deadflag, DEAD_NO);
			set_pev(ZombieNpc[ZombieNum], pev_nextthink, get_gametime() + 0.1);
			set_pev(ZombieNpc[ZombieNum], pev_body, random_num(0, 1));
			
			drop_to_floor(ZombieNpc[ZombieNum]);
			Anim(ZombieNpc[ZombieNum], 4, 1.0);
			
			engfunc(EngFunc_EmitSound, ZombieNpc[ZombieNum], CHAN_VOICE, SoundBig[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			
			new ability_grenade_big = random_num(1, 3);
			
			if(ability_grenade_big == 1 && zp_player_alive() > 0)
				set_task(5.0, "SkillGrenade", 505+ZombieNpc[ZombieNum]);
		}
		case 7:
		{
			engfunc(EngFunc_SetModel, ZombieNpc[ZombieNum], ZmHoundMdl);
			engfunc(EngFunc_SetSize, ZombieNpc[ZombieNum], Float:{-5.1, -5.1, -5.1}, Float:{5.1, 5.1, 15.1});
			engfunc(EngFunc_SetOrigin, ZombieNpc[ZombieNum], Origin);
			
			new ClassName[32];
			formatex(ClassName, charsmax(ClassName), "NpcHound_%d", ZombieCount);
			
			set_pev(ZombieNpc[ZombieNum], pev_classname, ClassName);
			set_pev(ZombieNpc[ZombieNum], ZM_PEV_TYPE, ZT_HOUND);
			set_pev(ZombieNpc[ZombieNum], pev_solid, SOLID_BBOX);
			set_pev(ZombieNpc[ZombieNum], pev_movetype, MOVETYPE_PUSHSTEP);
			set_pev(ZombieNpc[ZombieNum], pev_takedamage, DAMAGE_YES);
			set_pev(ZombieNpc[ZombieNum], pev_health, (float(Health) * 1));
			set_pev(ZombieNpc[ZombieNum], pev_deadflag, DEAD_NO);
			set_pev(ZombieNpc[ZombieNum], pev_nextthink, get_gametime() + 0.1);
			set_pev(ZombieNpc[ZombieNum], pev_body, 0);
			
			drop_to_floor(ZombieNpc[ZombieNum]);
			Anim(ZombieNpc[ZombieNum], 4, 1.0);
			
			engfunc(EngFunc_EmitSound, ZombieNpc[ZombieNum], CHAN_VOICE, SoundHound[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	set_pev(ZombieNpc[ZombieNum], pev_fuser2, float(speed));
	set_pev(ZombieNpc[ZombieNum], pev_iuser2, damage);

 
  	// === PATCH: индивидуальная цель и roam ===
  	set_pev(ZombieNpc[ZombieNum], pev_enemy, FindClosestAlivePlayer(ZombieNpc[ZombieNum]));
  	set_pev(ZombieNpc[ZombieNum], pev_fuser3, get_gametime() + random_float(0.1, 0.6)); // таймер ретаргета
 	set_pev(ZombieNpc[ZombieNum], pev_iuser3, 0); // roam не активен (НЕ iuser2!)

	ZombieCount++;

}

public Hook_Think(Ent)
{
	 if(!pev_valid(Ent))
	  return HAM_IGNORED;

	 if (Ent < 1 || Ent > MAX_EDICTS)
	 {
     set_pev(Ent, pev_nextthink, get_gametime() + 0.5);
     return HAM_HANDLED;
	 }

	 if (!IsZombieNpc(Ent))
	  return HAM_IGNORED;

	 if(pev(Ent, pev_deadflag) == DEAD_DYING)
	  return HAM_IGNORED;

	 new Float:gt = get_gametime();

	 // === PATCH: персональный ближайший таргет (раз в ZM_RETARGET_TIME) ===
	 new target = pev(Ent, pev_enemy);

	 //pev(Ent, pev_enemy, target);
	 new Float:nextRetarget;
	 pev(Ent, pev_fuser3, nextRetarget);

	 if (nextRetarget <= gt)
	 {
	  target = FindClosestAlivePlayer(Ent);
	  set_pev(Ent, pev_enemy, target);
	  set_pev(Ent, pev_fuser3, gt + ZM_RETARGET_TIME);

	 }

	 // Сброс анимации после удара
	 if(pev(Ent, pev_fuser1) == 500.0)
	 {
	  set_pev(Ent, pev_fuser1, 0.0);
	  Anim(Ent, 4, 1.0);
	 }
	
	 Npc_SetCrouch(Ent, false);

	 new Float:Speed;
	 pev(Ent, pev_fuser2, Speed);

	// === Определяем точку назначения: игрок или roam-точка ===

	 new bool:havePlayer = (is_user_alive(target) != 0);

	 static Float:NPC[3], Float:DEST[3];
	 pev(Ent, pev_origin, NPC);
 
	 if (havePlayer)
	 {
	  pev(target, pev_origin, DEST);
	  // если был roam - выключаем, т.к. есть цель
	  set_pev(Ent, pev_iuser3, 0);
	 }
	 else
	 {
	  // нет игроков -> roaming
	  static Float:roam[3];
	  if (!GetRoamGoal(Ent, roam))
	   SetRandomRoamGoal(Ent);

	  if (GetRoamGoal(Ent, roam))
	   xs_vec_copy(roam, DEST);
	  else
	  {
	   set_pev(Ent, pev_nextthink, gt + 0.5);
	   return HAM_HANDLED;
	  }
	 }

	new Float:distToGoal = get_distance_f(NPC, DEST);
	new Float:thinkDelay = ZM_GetThinkDelay(havePlayer, distToGoal);
	// небольшой рандом, чтобы 16 NPC не просыпались в один тик
	thinkDelay += random_float(0.0, 0.06);

	 // Поворот NPC на DEST
	 static Float:Angle[3], Float:Vector[3];

		 // === PATHFINDING (OPT CACHE) ===
	 new iNodeOrigin = NavBox_GetNode(NPC);
	 new iNodeGoal = NavBox_GetNodeNearest(DEST);

	 if (iNodeOrigin < 0 || iNodeGoal < 0)
	 {
		// идем напрямую
		xs_vec_sub(DEST, NPC, Vector);
		vector_to_angle(Vector, Angle);
		Angle[0] = 0.0;
		Angle[2] = 0.0;
		xs_vec_normalize(Vector, Vector);
		xs_vec_mul_scalar(Vector, Speed, Vector);
		Vector[2] = 0.0;
		ApplySmoothYaw(Ent, Angle[1], gt);
		set_pev(Ent, pev_velocity, Vector);
		set_pev(Ent, pev_nextthink, gt + thinkDelay);
		return HAM_HANDLED;
	 }

		// Если очень близко к цели — бежим напрямую (без поиска пути)
	 if (iNodeOrigin == iNodeGoal)
	 {
		// ... идем напрямую (как выше, но без проверки нодов)
		xs_vec_sub(DEST, NPC, Vector);
		vector_to_angle(Vector, Angle);
		Angle[0] = 0.0;
		Angle[2] = 0.0;
		xs_vec_normalize(Vector, Vector);
		xs_vec_mul_scalar(Vector, Speed, Vector);
		Vector[2] = 0.0;
		ApplySmoothYaw(Ent, Angle[1], gt);
		set_pev(Ent, pev_velocity, Vector);

		if (!havePlayer)
		 {
		   if (get_distance_f(NPC, DEST) <= ZM_ROAM_REACH_DIST)
		         SetRandomRoamGoal(Ent);
		 }

		 set_pev(Ent, pev_nextthink, gt + thinkDelay);
		 return HAM_HANDLED;
	 }

	// Решаем: надо ли пересчитывать путь? (anti-jitter)
	new bool:needRepath = false;

	new Float:distToStep = g_haveCachedStep[Ent] ? get_distance_f(NPC, g_cachedDest[Ent]) : 999999.0;

	if (!g_haveCachedStep[Ent] || 
	    (gt >= g_nextPathUpdate[Ent] && distToStep <= ZM_STEP_REACH_DIST) ||
	    iNodeOrigin != g_lastNodeOrigin[Ent] ||
	    iNodeGoal != g_lastNodeGoal[Ent] ||
	    get_distance_f(DEST, g_lastGoalPos[Ent]) >= ZM_GOAL_REPATH_DIST)
	{
	    needRepath = true;
	}

	if (needRepath)
{
    g_lastNodeOrigin[Ent] = iNodeOrigin;
    g_lastNodeGoal[Ent]   = iNodeGoal;

    new iWaypointFinal = -1;
    new Array:arrayWaypoint = NavSys_Pathfinding(iNodeOrigin, iNodeGoal, iWaypointFinal, ZM_PATHFIND_TICK_LIMIT);

    if (arrayWaypoint != Invalid_Array)
    {
        if (iWaypointFinal >= 0)
        {
            new waypoint[7];
            NavSys_GetWaypointSecond(arrayWaypoint, iWaypointFinal, waypoint);

            new iNodeCurrent = waypoint[4];
            new iNodeNext    = waypoint[0];
            new iPath        = waypoint[6];

            new PathFlags:flags, Float:height, Float:stepDest[3];
            NavNode_GetPathCoord2(iNodeCurrent, iNodeNext, iPath, flags, height, stepDest);

            xs_vec_copy(stepDest, g_cachedDest[Ent]);
            g_cachedFlags[Ent] = flags;
            g_cachedHeight[Ent] = height;
            g_haveCachedStep[Ent] = true;

            xs_vec_copy(DEST, g_lastGoalPos[Ent]);
            g_nextPathUpdate[Ent] = gt + ZM_PATH_UPDATE_TIME + random_float(0.0, 0.15);
        }
        else
        {
            // -2 недоступно, -1 не успел
            g_haveCachedStep[Ent] = false;

            if (iWaypointFinal == -2)
            {
                if (havePlayer)
                {
                    set_pev(Ent, pev_enemy, FindClosestAlivePlayer(Ent));
                    set_pev(Ent, pev_fuser3, gt + 0.2);
                }
                else
                {
                    SetRandomRoamGoal(Ent);
                }
                g_nextPathUpdate[Ent] = gt + 0.8;
            }
            else
            {
                // -1: не успел за ticklimit -> пробуем реже
                g_nextPathUpdate[Ent] = gt + 1.0;
            }
        }

        ArrayDestroy(arrayWaypoint);
    }
    else
    {
        // на всякий случай
        g_haveCachedStep[Ent] = false;
        g_nextPathUpdate[Ent] = gt + 1.0;
    }
}
		
	if (!g_haveCachedStep[Ent])
	{
	    set_pev(Ent, pev_velocity, {0.0, 0.0, 0.0});
	    set_pev(Ent, pev_nextthink, gt + thinkDelay); // или 0.35
	    return HAM_HANDLED;
	}
	 // используем кешированный шаг
	 new PathFlags:flags = g_cachedFlags[Ent];
	 new Float:height = g_cachedHeight[Ent];

	 new Float:dest[3];
	 xs_vec_copy(g_cachedDest[Ent], dest);
	 // Поворачиваемся по направлению движения (к waypoint), а не на игрока => меньше дерготни
	 xs_vec_sub(dest, NPC, Vector);
	 vector_to_angle(Vector, Angle);
	 Angle[0] = 0.0;
	 Angle[2] = 0.0;

	 // скорость к следующей точке
	 new Float:oldVelocity[3];
	 pev(Ent, pev_velocity, oldVelocity);

	 new Float:velocity[3];
	 velocity[0] = dest[0] - NPC[0];
	 velocity[1] = dest[1] - NPC[1];

	 new Float:length = floatsqroot(velocity[0] * velocity[0] + velocity[1] * velocity[1]);
	 if (length < 1.0) length = 1.0;

	 velocity[0] = velocity[0] * Speed / length;
	 velocity[1] = velocity[1] * Speed / length;

	 if (pev(Ent, pev_flags) & FL_ONGROUND)
	 {
	  if (0.0 < height) velocity[2] = floatsqroot(45.0 * 2.0 * 800.0);
	  else velocity[2] = 0.0;
	 }
	 else
	 {
	  velocity[2] = oldVelocity[2];
	 }

	 set_pev(Ent, pev_velocity, velocity);

	 if (flags & PF_CrouchRun || 45.0 < height)
	  Npc_SetCrouch(Ent, true, 45.0 < height);

	 ApplySmoothYaw(Ent, Angle[1], gt);

	 set_pev(Ent, pev_nextthink, gt + thinkDelay);
	 return HAM_HANDLED;
}

Npc_SetCrouch(npc, bool:on, bool:jumping = false)
{
	new flags = pev(npc, pev_flags)
	if (on)
	{
		if (flags & FL_DUCKING) return
		
		set_pev(npc, pev_flags, flags | FL_DUCKING)
		//engfunc(EngFunc_SetSize, npc, { -16.0, -16.0, -18.0 }, { 16.0, 16.0, 18.0 })
		if (flags & FL_ONGROUND && !jumping)
		{
			new Float:vecSrc[3], Float:vecDest[3]
			pev(npc, pev_origin, vecSrc)
			vecDest[0] = vecSrc[0]
			vecDest[1] = vecSrc[1]
			vecDest[2] = vecSrc[2] - 18.0
			engfunc(EngFunc_TraceHull, vecSrc, vecDest, DONT_IGNORE_MONSTERS, HULL_HEAD, npc, 0)
			get_tr2(0, TR_vecEndPos, vecDest)
			set_pev(npc, pev_origin, vecDest)
		}
		return
	}
	
	if ((flags & FL_DUCKING) == 0) return
	if ((flags & FL_ONGROUND) == 0) return
	
	new Float:origin[3]
	pev(npc, pev_origin, origin)
	origin[2] += 18.0
	if (IsHullVacant(origin))
	{
		set_pev(npc, pev_flags, flags & ~FL_DUCKING)
		//engfunc(EngFunc_SetSize, npc, { -16.0, -16.0, -36.0 }, { 16.0, 16.0, 36.0 })
		
		set_pev(npc, pev_origin, origin)
	}
}


stock bool:IsHullVacant(const Float:origin[3], hull = HULL_HUMAN)
{
	engfunc(EngFunc_TraceHull, origin, origin, DONT_IGNORE_MONSTERS, hull, 0, 0)
	if (!get_tr2(0, TR_InOpen) || get_tr2(0, TR_AllSolid) || get_tr2(0, TR_StartSolid)) return false
	return true
}

public Hook_Killed(victim, attacker, corpse)
{
	 if (!IsZombieNpc(victim))
	  return HAM_IGNORED;
	
	if(pev(victim, pev_deadflag) == DEAD_DYING)
		return HAM_IGNORED;
	
	set_pev(victim, pev_velocity, {0.0, 0.0, 0.0});
	set_pev(victim, pev_solid, SOLID_NOT);
	set_pev(victim, pev_deadflag, DEAD_DYING);
	
	static ClassName[63];
	pev(victim, pev_classname, ClassName, charsmax(ClassName));
	
	new ZombieType:t = ZombieType:pev(victim, ZM_PEV_TYPE);

	switch (t)
	{
	    case ZT_HOUND: Anim(victim, random_num(14, 15), 1.1);
	    default:       Anim(victim, random_num(101, 102), 1.1);
	}
	
	set_task(time_delete, "Zombie_Delete", victim);

	switch (t)
	{
    case ZT_CLASSIC: engfunc(EngFunc_EmitSound, victim, CHAN_VOICE, SoundClassic[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    case ZT_DEIMOS:  engfunc(EngFunc_EmitSound, victim, CHAN_VOICE, SoundDeimos[0],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    case ZT_GHOST: engfunc(EngFunc_EmitSound, victim, CHAN_VOICE, SoundGhost[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    case ZT_HEAL: engfunc(EngFunc_EmitSound, victim, CHAN_VOICE, SoundHeal[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    case ZT_WITCH: engfunc(EngFunc_EmitSound, victim, CHAN_VOICE, SoundWitch[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    case ZT_BIG: engfunc(EngFunc_EmitSound, victim, CHAN_VOICE, SoundBig[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	
	zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + 100);
	
	return HAM_SUPERCEDE;
}

public Zombie_Delete(id)
{
	// safety: прибить связанные задачи, даже если кто-то забыл их снять
    if(task_exists(id+101)) remove_task(id+101);
    if(task_exists(id+202)) remove_task(id+202);
    if(task_exists(id+303)) remove_task(id+303);
    if(task_exists(id+404)) remove_task(id+404);
    if(task_exists(id+505)) remove_task(id+505);
    if(task_exists(id+606)) remove_task(id+606);

	if (pev_valid(id)) set_pev(id, ZM_PEV_TYPE, ZT_NONE);

	ClearPathCache(id);

	engfunc(EngFunc_RemoveEntity, id);

	// очистим слот массива, чтобы не было переиспользования старого ID
	for (new i = 0; i < zombie_limit; i++)
	{
		if (ZombieNpc[i] == id)
	    {
	    	ZombieNpc[i] = 0;
	    	break;
	    }
	}
	
	if (ZombieCount > 0) ZombieCount--;
}

public Hook_Touch(Ent, id)
{
    if (!IsZombieNpc(Ent))
        return HAM_IGNORED;

    if (id < 1 || id > get_maxplayers()) return HAM_IGNORED;

    // Игнорируем зомби-игроков
    if (is_user_alive(id) && zp_get_user_zombie(id))
        return HAM_SUPERCEDE;
        
    if(pev(Ent, pev_deadflag) == DEAD_DYING)
        return HAM_IGNORED;
    
    if(!TakeDamageFromZM)
        return HAM_IGNORED;

    if (!is_user_alive(id)) return HAM_IGNORED;

    // Игнорируем зомби-игроков (повторная проверка для безопасности)
    if(zp_get_user_zombie(id))
        return HAM_IGNORED;
    
    if(DamageHitPlayer[id] <= get_gametime())
    {
        new damage = pev(Ent, pev_iuser2);
        zm_damage(id, damage);

        
        DamageHitPlayer[id] = get_gametime() + 0.5;
    }
    
    set_pev(Ent, pev_nextthink, get_gametime() + time_attack);
    set_pev(Ent, pev_fuser1, 500.0);
    
    Anim(Ent, 76, 1.0);
    
    engfunc(EngFunc_EmitSound, Ent, CHAN_VOICE, SoundClassic[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    
    return HAM_HANDLED;
}
public SkillHeal(id)
{
	id -= 101;
	
	if(pev_valid(id) && pev(id, pev_deadflag) != DEAD_DYING)
	{
		new Float:Origin[3];
		pev(id, pev_origin, Origin);
		
		Origin[2] -= 35.0;
		
		Heal_Effect(Origin);
		
		set_pev(id, pev_health, 500.0);
		
		engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "npc_zombies/abilityfunc/td_heal.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

public SkillDeimos(id)
{
	id -= 202;
	
	if(pev_valid(id) && (pev(id, pev_deadflag) != DEAD_DYING) && zp_player_alive() > 0)
	{
		Anim(id, 10, 2.0);
		
		set_task(0.5, "SkillUpdateAnim", 606+id);
		
		new Float:fOrigin[3], Float:fAngle[3], Float:fVelocity[3];
		new Player;
		
		Player = FindClosestAlivePlayer(id)
	
		pev(id, pev_origin, fOrigin);
		pev(id, pev_view_ofs, fAngle);
		
		fm_velocity_by_aim(2.0, fVelocity, fAngle, Player);
		fAngle[0] *= -1.0;
		
		new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		
		set_pev(ent, pev_classname, "nst_deimos_skill");
		engfunc(EngFunc_SetModel, ent, "models/w_hegrenade.mdl");
		
		set_pev(ent, pev_mins, Float:{-1.0, -1.0, -1.0});
		set_pev(ent, pev_maxs, Float:{1.0, 1.0, 1.0});
		set_pev(ent, pev_origin, fOrigin);
		
		fOrigin[0] += fVelocity[0];
		fOrigin[1] += fVelocity[1];
		fOrigin[2] += fVelocity[2];
		
		set_pev(ent, pev_movetype, MOVETYPE_BOUNCE);
		set_pev(ent, pev_gravity, 0.01);
		
		fVelocity[0] *= -1000;
		fVelocity[1] *= -1000;
		fVelocity[2] *= -1000;
		
		set_pev(ent, pev_velocity, fVelocity);
		set_pev(ent, pev_owner, id);
		set_pev(ent, pev_angles, fAngle);
		set_pev(ent, pev_solid, SOLID_BBOX);
		ScheduleRemoveEntity(ent, 6.0);
		
		set_rendering(ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(ent);
		write_short(Deimos_Sprite_Line);
		write_byte(5);
		write_byte(3);
		write_byte(209);
		write_byte(120);
		write_byte(9);
		write_byte(200);
		message_end();
		
		engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "npc_zombies/abilityfunc/deimos_start.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

public SkillGhost(id)
{
	id -= 303;
	
	if(pev_valid(id) && pev(id, pev_deadflag) != DEAD_DYING)
	{
		engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "npc_zombies/abilityfunc/invisable_active.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 10);
		
		set_task(5.0, "SkillGhostEnd", 404+id);
	}
}

public SkillGhostEnd(id)
{
	id -= 404;
	
	if(pev_valid(id) && pev(id, pev_deadflag) != DEAD_DYING)
	{
		engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "npc_zombies/abilityfunc/invisable_active.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		set_rendering(id);
	}
}

public SkillGrenade(id)
{
	id -= 505;
	
	if(pev_valid(id) && (pev(id, pev_deadflag) != DEAD_DYING) && zp_player_alive() > 0)
	{
		Anim(id, 57, 2.0);
		
		set_task(0.5, "SkillUpdateAnim", 606+id);
		
		static Float:StartOrigin[3], Float:TargetOrigin[3], Float:angles[3], Float:angles_fix[3];
	
		get_weapon_position(id, StartOrigin, .add_forward = 30.0, .add_right = 8.0, .add_up = 10.0);
		
		pev(id, pev_v_angle, angles);
		
		static Ent;
		Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		
		if(!pev_valid(Ent))
			return;
		
		angles_fix[0] = 360.0 - angles[0];
		angles_fix[1] = angles[1];
		angles_fix[2] = angles[2];
		
		set_pev(Ent, pev_movetype, MOVETYPE_TOSS);
		set_pev(Ent, pev_owner, id);
		
		entity_set_string(Ent, EV_SZ_classname, "grenade_skill");
		engfunc(EngFunc_SetModel, Ent, GrenadeMdl);
		set_pev(Ent, pev_body, 1);
		set_pev(Ent, pev_mins, {-0.1, -0.1, -0.1});
		set_pev(Ent, pev_maxs, {0.1, 0.1, 0.1});
		set_pev(Ent, pev_origin, StartOrigin);
		set_pev(Ent, pev_angles, angles_fix);
		set_pev(Ent, pev_gravity, 1.0);
		set_pev(Ent, pev_solid, SOLID_BBOX);
		set_pev(Ent, pev_frame, 0.0);
		
		static Float:Velocity[3];
		static Player;
		
		Player = FindClosestAlivePlayer(Ent);
		
		pev(Player, pev_origin, TargetOrigin);
		
		get_speed_vector(StartOrigin, TargetOrigin, 700.0, Velocity);
		
		set_pev(Ent, pev_velocity, Velocity);
		ScheduleRemoveEntity(Ent, 8.0)
	}
}

public SkillUpdateAnim(id)
{
	id -= 606;
	
	if(pev_valid(id) && pev(id, pev_deadflag) != DEAD_DYING)
		Anim(id, 4, 1.0);
}

public Hook_BloodColor(Ent)
{
	if (!IsZombieNpc(Ent))
 	return HAM_IGNORED;
	
	SetHamReturnInteger(zombie_blood);
	
	return HAM_SUPERCEDE;
}

public fw_DeimosSkill_Touch(ent, victim)
{
    if (!pev_valid(ent)) return;

    light_exp(ent, victim);
    engfunc(EngFunc_RemoveEntity, ent);
}

light_exp(ent, victim)
{
	if(!pev_valid(ent))
		return;
	
	if(is_user_alive(victim))
	{
		new wpn, wpnname[32];
		wpn = get_user_weapon(victim);
		
		if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)))
			engclient_cmd(victim, "drop", wpnname);
	}
	
	static Float:origin[3];
	pev(ent, pev_origin, origin);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	write_coord(floatround(origin[0]));
	write_coord(floatround(origin[1]));
	write_coord(floatround(origin[2]));
	write_short(Deimos_Sprite_Exp);
	write_byte(40);
	write_byte(30);
	write_byte(14);
	message_end();
	
	engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, "npc_zombies/abilityfunc/deimos_hit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public fw_Weapon_Touch(ent, id)
{
	if(!pev_valid(ent))
		return;
	
	new Float:flOrigin[3];
	pev(ent, pev_origin, flOrigin);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord,flOrigin[0]);
	engfunc(EngFunc_WriteCoord,flOrigin[1]);
	engfunc(EngFunc_WriteCoord,flOrigin[2] + 45.0);
	write_short(Grenade_Sprite_Exp);
	write_byte(35);
	write_byte(186);
	message_end();

	engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, "npc_zombies/abilityfunc/zombie_bomb_explode01.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	for(new i = 1; i <= get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue;
		
		new Float:flVictimOrigin[3];
		pev(i, pev_origin, flVictimOrigin);
		
		new Float:flDistance = get_distance_f(flOrigin, flVictimOrigin);
		
		if(flDistance <= 300.0)
		{
			static Float:flSpeed;
			flSpeed = 800.0;
			
			static Float:flNewSpeed;
			flNewSpeed = flSpeed * (1.0 - (flDistance / 300.0));
			
			static Float:flVelocity[3];
			get_speed_vector(flOrigin, flVictimOrigin, flNewSpeed, flVelocity);
			
			set_pev(i, pev_velocity, flVelocity);
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, i);
			write_short((1<<12)*4);
			write_short((1<<12)*10);
			write_short((1<<12)*10);
			message_end();
			
			if(pev(i, pev_health) - 10.0 <= 0)
				ExecuteHamB(Ham_Killed, i, i, 1);
			else
			{
				static Float:Origin[3];
		
				pev(i, pev_origin, Origin);
				
				ExecuteHamB(Ham_TakeDamage, i, 0, i, 10.0, DMG_BLAST);
				
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), {0,0,0}, i);
				write_byte(0);
				write_byte(100);
				write_long((1<<1));
				engfunc(EngFunc_WriteCoord, Origin[0]);
				engfunc(EngFunc_WriteCoord, Origin[1]);
				engfunc(EngFunc_WriteCoord, Origin[2]);
				message_end();
			}
		}
	}
	
	remove_entity(ent);
}

public fw_ShouldCollide(ent1, ent2)
{
    // NPC <-> NPC
    if (IsZombieNpc(ent1) && IsZombieNpc(ent2))
    {
        forward_return(FMV_CELL, 0);
        return FMRES_SUPERCEDE;
    }

    // NPC <-> PlayerZombie (полностью без коллизии => без touch)
    if (IsZombieNpc(ent1) && IsZombiePlayer(ent2))
    {
            forward_return(FMV_CELL, 0);
            return FMRES_SUPERCEDE;
    }
    if (IsZombieNpc(ent2) && IsZombiePlayer(ent1))
    {
            forward_return(FMV_CELL, 0);
            return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}

public SV_AllowPhysent_Pre(const entity, const player)
{
    // Проверка на валидность
    if (entity <= 0 || player <= 0)
        return HC_CONTINUE;
    
    // Первый объект - NPC, второй - зомби-игрок
    if (IsZombieNpc(entity) && IsZombiePlayer(player))
    {
        SetHookChainReturn(ATYPE_BOOL, false);
        return HC_BREAK;
    }
    
    // NPC <-> Неживые объекты (коробки, двери и т.д.)
    // Если нужно, можно добавить исключения
    
    return HC_CONTINUE;
}

fm_velocity_by_aim(Float:fDistance, Float:fVelocity[3], Float:fViewAngle[3], Player)
{
	pev(Player, pev_angles, fViewAngle);
	
	fVelocity[0] = floatcos(fViewAngle[1], degrees) * fDistance;
	fVelocity[1] = floatsin(fViewAngle[1], degrees) * fDistance;
	fVelocity[2] = floatcos(fViewAngle[0]+90.0, degrees) * fDistance;
	
	return 1;
}

public zp_player_alive()
{
	new iAlive, id, CsTeams:team;
	
	for(id = 1; id <= get_maxplayers(); id++)
	{
		if(!is_user_alive(id) || is_user_bot(id))
			continue;
		
		team = cs_get_user_team(id);
			
		if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
			continue;
		
		iAlive++;
	}
	
	return iAlive;
}

stock get_weapon_position(id, Float:fOrigin[3], Float:add_forward = 0.0, Float:add_right = 0.0, Float:add_up = 0.0)
{
	static Float:Angles[3], Float:ViewOfs[3], Float:vAngles[3];
	static Float:Forward[3], Float:Right[3], Float:Up[3];
	
	pev(id, pev_v_angle, vAngles);
	pev(id, pev_origin, fOrigin);
	pev(id, pev_view_ofs, ViewOfs);
	
	xs_vec_add(fOrigin, ViewOfs, fOrigin);
	
	pev(id, pev_v_angle, Angles);
	
	engfunc(EngFunc_MakeVectors, Angles);
	
	global_get(glb_v_forward, Forward);
	global_get(glb_v_right, Right);
	global_get(glb_v_up, Up);
	
	xs_vec_mul_scalar(Forward, add_forward, Forward);
	xs_vec_mul_scalar(Right, add_right, Right);
	xs_vec_mul_scalar(Up, add_up, Up);
	
	fOrigin[0] = fOrigin[0] + Forward[0] + Right[0] + Up[0];
	fOrigin[1] = fOrigin[1] + Forward[1] + Right[1] + Up[1];
	fOrigin[2] = fOrigin[2] + Forward[2] + Right[2] + Up[2];
}

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0];
	new_velocity[1] = origin2[1] - origin1[1];
	new_velocity[2] = origin2[2] - origin1[2];
	
	static Float:num;
	num = floatsqroot(speed * speed / (new_velocity[0] * new_velocity[0] + new_velocity[1] * new_velocity[1] + new_velocity[2] * new_velocity[2]));
	
	new_velocity[0] *= num;
	new_velocity[1] *= num;
	new_velocity[2] *= num;
	
	return 1;
}

stock Heal_Effect(Float:Origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2] + 45);
	write_short(Healer_Sprite);
	write_byte(15);
	write_byte(255);
	message_end();
}

stock Anim(ent, sequence, Float:speed)
{		
	set_pev(ent, pev_sequence, sequence);
	set_pev(ent, pev_animtime, halflife_time());
	set_pev(ent, pev_framerate, speed);
}

public native_zl_zmclassic_valid(index)
{
 return (pev_valid(index) && pev(index, ZM_PEV_TYPE) == ZT_CLASSIC) ? 1 : 0;
}
public native_zl_zmdeimos_valid(index)
{
 return (pev_valid(index) && pev(index, ZM_PEV_TYPE) == ZT_DEIMOS) ? 1 : 0;
}
public native_zl_zmghost_valid(index)
{
 return (pev_valid(index) && pev(index, ZM_PEV_TYPE) == ZT_GHOST) ? 1 : 0;
}
public native_zl_zmheal_valid(index)
{
 return (pev_valid(index) && pev(index, ZM_PEV_TYPE) == ZT_HEAL) ? 1 : 0;
}
public native_zl_zmwitch_valid(index)
{
 return (pev_valid(index) && pev(index, ZM_PEV_TYPE) == ZT_WITCH) ? 1 : 0;
}
public native_zl_zmbig_valid(index)
{
 return (pev_valid(index) && pev(index, ZM_PEV_TYPE) == ZT_BIG) ? 1 : 0;
}
public native_zl_zmhound_valid(index)
{
 return (pev_valid(index) && pev(index, ZM_PEV_TYPE) == ZT_HOUND) ? 1 : 0;
}

public native_zl_zombie_count() return ZombieCount;

public plugin_end()
{
    // снять циклический task обновления людей (у тебя он с id=0)
    remove_task(0);

    // снять все scheduled удаления temp-entity и NPC-скиллов (на всякий)
    // (опционально) можно просто remove_task() всех id, но у AMXX нет "remove all" кроме id=0.
    // поэтому точечно по нашим диапазонам:
    for (new ent = 1; ent <= MAX_EDICTS; ent++)
    {
        remove_task(TASK_REMOVE_TEMP + ent);
        remove_task(ent + 101);
        remove_task(ent + 202);
        remove_task(ent + 303);
        remove_task(ent + 404);
        remove_task(ent + 505);
        remove_task(ent + 606);
    }

    // удалить всех зомби НЕМЕДЛЕННО
    for (new i = 0; i < zombie_limit; i++)
    {
        new ent = ZombieNpc[i];
        if (!pev_valid(ent)) continue;

        // прямое удаление без анимаций/таймеров
        Zombie_Delete(ent);
    }
}

stock FindClosestAlivePlayer(ent)
{
 if (g_humanCount <= 0) return 0;

 new Float:entOrg[3];
 pev(ent, pev_origin, entOrg);

 new best = 0;
 new Float:bestDist = 999999.0;

 for (new k = 0; k < g_humanCount; k++)
 {
  new i = g_humans[k];
  // на всякий случай, т.к. кеш обновляется раз в 0.5 сек
  if (!is_user_alive(i) || zp_get_user_zombie(i)) continue;

  new Float:org[3];
  pev(i, pev_origin, org);

  new Float:d = get_distance_f(entOrg, org);
  if (d < bestDist)
  {
   bestDist = d;
   best = i;
  }
 }
 return best;
}

stock bool:GetRoamGoal(ent, Float:goal[3])
{
 new active = pev(ent, pev_iuser3); // 1 = есть roam цель
 if (active != 1) return false;

 pev(ent, pev_vuser1, goal);
 return true;
}

stock SetRandomRoamGoal(ent)
{
    new Array:arr = NavSys_GetSpawnPos();
    if (arr == Invalid_Array)
    {
        set_pev(ent, pev_iuser3, 0);
        
        return;
    }

    new n = ArraySize(arr);
    if (n <= 0)
    {
        set_pev(ent, pev_iuser3, 0);
       
        return;
    }

    new idx = random(n);

    new Float:spawn[6];
    ArrayGetArray(arr, idx, spawn);

    new Float:goal[3];
    goal[0] = spawn[0];
    goal[1] = spawn[1];
    goal[2] = spawn[2];

    set_pev(ent, pev_vuser1, goal);
    set_pev(ent, pev_iuser3, 1);

}

stock zm_damage(id, damage)
{
	if(!is_user_alive(id))
		return;
		
	new hp = pev(id, pev_health);
	
	if(hp - damage <= 0)
		ExecuteHamB(Ham_Killed, id, id, 2);
	else
	{
		static Float:Origin[3];
		
		pev(id, pev_origin, Origin);
		
		ExecuteHamB(Ham_TakeDamage, id, 0, id, float(damage), DMG_BLAST);
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), {0,0,0}, id);
		write_byte(0);
		write_byte(100);
		write_long((1<<1));
		engfunc(EngFunc_WriteCoord, Origin[0]);
		engfunc(EngFunc_WriteCoord, Origin[1]);
		engfunc(EngFunc_WriteCoord, Origin[2]);
		message_end();
	}
}

stock ClearPathCache(ent)
{
 if (ent < 0 || ent > MAX_EDICTS) return;

 g_lastNodeOrigin[ent] = -999999;
 g_lastNodeGoal[ent] = -999999;
 g_nextPathUpdate[ent] = 0.0;

 g_haveCachedStep[ent] = false; 
 g_cachedDest[ent][0] = 0.0;
 g_cachedDest[ent][1] = 0.0;
 g_cachedDest[ent][2] = 0.0;
 g_cachedFlags[ent] = PathFlags:0;
 g_cachedHeight[ent] = 0.0;
 g_smoothInit[ent] = false;
 g_smoothYaw[ent] = 0.0;
 g_smoothVel[ent][0] = 0.0;
 g_smoothVel[ent][1] = 0.0;
 g_smoothVel[ent][2] = 0.0;
 g_lastGoalPos[ent][0] = 0.0;
 g_lastGoalPos[ent][1] = 0.0;
 g_lastGoalPos[ent][2] = 0.0;
 g_lastYawTime[ent] = 0.0;
}

stock Float:NormalizeAngle(Float:a)
{
 while (a > 180.0) a -= 360.0;
 while (a < -180.0) a += 360.0;
 return a;
}

stock Float:ApproachAngle(Float:cur, Float:target, Float:maxStep)
{
 new Float:delta = NormalizeAngle(target - cur);
 if (delta > maxStep) delta = maxStep;
 else if (delta < -maxStep) delta = -maxStep;
 return NormalizeAngle(cur + delta);
}

stock Float:LerpFloat(Float:a, Float:b, Float:t)
{
    return a + (b - a) * t;
}

stock LerpVec3(const Float:from[3], const Float:to[3], Float:t, Float:out[3])
{
    out[0] = LerpFloat(from[0], to[0], t);
    out[1] = LerpFloat(from[1], to[1], t);
    out[2] = LerpFloat(from[2], to[2], t);
}

// Плавный поворот NPC по yaw, ограниченный скоростью (как у игрока)
stock ApplySmoothYaw(ent, Float:targetYaw, Float:gt)
{
    targetYaw = NormalizeAngle(targetYaw);

    if (!g_smoothInit[ent])
    {
        new Float:ang[3];
        pev(ent, pev_angles, ang);

        g_smoothYaw[ent] = NormalizeAngle(ang[1]);
        g_lastYawTime[ent] = gt;
        g_smoothInit[ent] = true;
    }

    new Float:dt = gt - g_lastYawTime[ent];
    if (dt < 0.0) dt = 0.0;
    if (dt > 0.5) dt = 0.5; // защита от больших пауз/лагов

    g_lastYawTime[ent] = gt;

    new Float:maxStep = ZM_MAX_YAW_SPEED * dt; // град за этот тик
    if (maxStep < 0.1) maxStep = 0.1;

    g_smoothYaw[ent] = ApproachAngle(g_smoothYaw[ent], targetYaw, maxStep);

    new Float:outAng[3];
    outAng[0] = 0.0;
    outAng[1] = g_smoothYaw[ent];
    outAng[2] = 0.0;
    set_pev(ent, pev_angles, outAng);
}

// === ADAPTIVE THINK (CPU saver) ===
stock Float:ZM_GetThinkDelay(bool:havePlayer, Float:distToGoal)
{
    if (!havePlayer) return ZM_THINK_IDLE;

    if (distToGoal <= ZM_NEAR_DIST) return ZM_THINK_NEAR;
    if (distToGoal <= ZM_FAR_DIST)  return ZM_THINK_MID;
    return ZM_THINK_FAR;
}
// === ADAPTIVE THINK (CPU saver) ===

// === OPT PATCH: fast NPC type (no classname contain) ===
stock bool:IsZombieNpc(ent)
{
 return (pev_valid(ent) && pev(ent, ZM_PEV_TYPE) != ZT_NONE);
}
// === OPT PATCH END ===


stock ScheduleRemoveEntity(ent, Float:delay)
{
    if (!pev_valid(ent)) return;
    set_task(delay, "Task_RemoveEntity", TASK_REMOVE_TEMP + ent);
}

public Task_RemoveEntity(taskid)
{
    new ent = taskid - TASK_REMOVE_TEMP;
    if (pev_valid(ent)) engfunc(EngFunc_RemoveEntity, ent);
}

stock bool:IsZombiePlayer(id)
{
    return (1 <= id <= get_maxplayers() && is_user_alive(id) && zp_get_user_zombie(id));
}