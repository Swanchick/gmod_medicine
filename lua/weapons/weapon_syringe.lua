AddCSLuaFile()

SWEP.Base = "weapon_medicine_base"

SWEP.PrintName = "Syringe"
SWEP.Author = "Swanchick"
SWEP.Purpose = ""

SWEP.Spawnable = true

SWEP.MedGroupsMultiplier = {
	[HITGROUP_HEAD] = 0.1,
    [HITGROUP_CHEST] = 1,
    [HITGROUP_STOMACH] = 1,
    [HITGROUP_LEFTARM] = 0.5,
    [HITGROUP_RIGHTARM] = 0.5,
    [HITGROUP_LEFTLEG] = 0.5,
    [HITGROUP_RIGHTLEG] = 0.5
}

SWEP.MedHealth = 20