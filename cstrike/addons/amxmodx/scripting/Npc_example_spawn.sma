#include <amxmodx>
#include <zombieplague>
#include <fakemeta>
#include <fakemeta_util>
#include <float>
#include <xs>

native zl_zombie_delete();
native zl_zombie_create(Float:Origin[3], Health, Speed, Damage);

new const ZmSpawnModel[] = "models/cross.mdl";

#define TASK_ZMTASKSPAWNTIME                                                 65842

new Float:Spawnzombie[3]

public plugin_init()
{
    register_plugin("Npc_example_spawn", "11.01.2026", "Robert7791")
    register_clcmd("say /set", "clcmd_set")
}

public plugin_precache()
{  
    precache_model(ZmSpawnModel);
}



public clcmd_set(id)

{

        new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))

        if(!pev_valid(ent) || !is_user_alive(id) || !is_user_connected(id))

        {

                return

        }

        engfunc(EngFunc_SetModel, ent, ZmSpawnModel)

        new Float:iOrigin[3]

        fm_get_aim_origin(id, iOrigin)

        iOrigin[2] += 100.0

        engfunc(EngFunc_SetOrigin, ent, iOrigin)

        engfunc(EngFunc_DropToFloor, ent)

        Spawnzombie[0] = iOrigin[0]
        Spawnzombie[1] = iOrigin[1]
        Spawnzombie[2] = iOrigin[2]

        set_task(3.0, "spawn_zobmie", TASK_ZMTASKSPAWNTIME, _, _, "b")
}

public spawn_zobmie()
{
    zl_zombie_create(Spawnzombie, 100, 320, 5) // 100 хп, 320 скорость, урон 5
}