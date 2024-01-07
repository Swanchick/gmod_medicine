---
--- Network keys
---

util.AddNetworkString("Damage.Update")
util.AddNetworkString("Death.UpdateState")
util.AddNetworkString("Death.ChangeText")
util.AddNetworkString("Med.MenuOpen")
util.AddNetworkString("Med.UpdateButtons")
util.AddNetworkString("Med.ChageWeapon")
util.AddNetworkString("Med.MakeHeal")

---
--- Local variables
---

local swep_base = "weapon_medicine_base"

---
--- Player functions
---

local PLAYER = FindMetaTable("Player")

function PLAYER:EnablePhysicsRagdoll()
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(self:GetModel())
    ragdoll:SetPos(self:GetPos())
    ragdoll:SetAngles(self:GetAngles())
    ragdoll:Spawn()

    ragdoll:SetNWEntity("Player", self)
    ragdoll:SetVelocity(self:GetVelocity())

    self:SetNWEntity("Ragdoll", ragdoll)

    self:Spectate(OBS_MODE_CHASE)
    self:SpectateEntity(ragdoll)
    self:SetActiveWeapon(NULL)
end

function PLAYER:DisablePhysicsRagdoll()
    local ragdoll = self:GetNWEntity("Ragdoll")
    if not IsValid(ragdoll) then return end

    self:SetAngles(ragdoll:GetAngles())
    local pos = ragdoll:GetPos()
    
    ragdoll:Remove()

    self:SetNWBool("MedDead", false)
    self:Spectate(OBS_MODE_NONE)
    self:Spawn()
    self:SetPos(pos)
end

function PLAYER:MedKill()
    local curTime = CurTime()
    self:SetNWFloat("SetLastTimeDeath", curTime)
    self:EnablePhysicsRagdoll()
    self:SetNWBool("MedDead", true)
    self:SetNWBool("CouldBeRevived", false)

    net.Start("Death.UpdateState")
        net.WriteBool(true)
    net.Send(self)

    timer.Simple(MED.Death.TimeRespawn, function ()
        if not self:IsMedDead() then return end
        
        self:SetNWBool("CouldBeRevived", true)
        net.Start("Death.ChangeText")
        net.Send(self)
    end)

    timer.Create(self:SteamID() .. "_spawn", MED.Death.TimeToDie, 0, function ()
        if not self:IsMedDead() then return end
        
        self:MedSpawn()
    end)
end

function PLAYER:MedSpawn()
    self:DisablePhysicsRagdoll()
    self:KillSilent()
    self:Spawn()

    local timerId = self:SteamID() .. "_spawn"

    if timer.Exists(timerId) then
        timer.Remove(timerId)
    end

    self:SetNWBool("MedDead", false)
end

function PLAYER:IsMedDead()
    return self:GetNWBool("MedDead", false)
end

---
--- Damage metaclass
---

local DAMAGE = {}
DAMAGE.Players = {}

-- Default player
DAMAGE.Players["Default"] = {
    [HITGROUP_HEAD] = 50,
    [HITGROUP_CHEST] = 75,
    [HITGROUP_STOMACH] = 75,
    [HITGROUP_LEFTARM] = 100,
    [HITGROUP_RIGHTARM] = 100,
    [HITGROUP_LEFTLEG] = 100,
    [HITGROUP_RIGHTLEG] = 100
}

-- Methods for damage

function DAMAGE:PlayerExist(steamid)
    return DAMAGE.Players[steamid] ~= nil
end

function DAMAGE:UpdatePlayerClient(ply)
    local steamid = ply:SteamID()
  
    net.Start("Damage.Update")
        net.WriteTable(self.Players[steamid])
    net.Send(ply)
end

function DAMAGE:PlayerReset(ply)
    local steamid = ply:SteamID()
    
    self.Players[steamid] = table.Copy(DAMAGE.Players["Default"])
    self:UpdatePlayerClient(ply)
end

function DAMAGE:GetHealth(steamid, hitGroup)
    return self.Players[steamid][hitGroup]
end

function DAMAGE:ApplyDamage(steamid, hitGroup, damage)
    if hitGroup == 0 then
        hitGroup = 2
    end
    
    local health = self:GetHealth(steamid, hitGroup)

    health = health - damage

    self.Players[steamid][hitGroup] = health

    return health
end

function DAMAGE:IsPlayerDead(target)
    local steamid = target:SteamID()
    
    if not self:PlayerExist(steamid) then 
        self:PlayerReset(target)
    end
    
    local healthes = self.Players[steamid]

    for k, health in pairs(healthes) do
        if health <= 0 then
            return true
        end
    end

    return false
end

function DAMAGE:KillPlayer(ply)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID()
    
    if self:IsPlayerDead(ply) then return end

    for k, v in pairs(self.Players[steamid]) do
        self.Players[steamid][k] = 0
    end

    ply:MedKill()
end

function DAMAGE:TakeDamage(target, dmg, hitGroup)
    local steamid = target:SteamID()
    
    if self:IsPlayerDead(target) then
        return false
    end

    local damage = dmg:GetDamage()
    local currentHealth = self:ApplyDamage(steamid, hitGroup, damage)
    
    self:UpdatePlayerClient(target)

    if currentHealth <= 0 then
        local attacker = dmg:GetAttacker()
        local inflictor = dmg:GetInflictor()

        target:MedKill()
    end

    return true
end

function DAMAGE:TakeDamageAll(target, dmg)
    local steamid = target:SteamID()
    if self:IsPlayerDead(target) then
        return false
    end

    local hitGroups = table.GetKeys(self.Players["Default"])
    for k, hitGroup in ipairs(hitGroups) do
        self:TakeDamage(target, dmg, hitGroup)
    end

    return true
end

function DAMAGE:TakeDamageLegs(target, dmg)
    local steamid = target:SteamID()
    if self:IsPlayerDead(target) then
        return false
    end

    local damage = dmg:GetDamage()

    dmg:SetDamage(damage * MED.Damage.FallScale)

    local leftLeg = self:TakeDamage(target, dmg, HITGROUP_LEFTLEG)
    local rightLeg = self:TakeDamage(target, dmg, HITGROUP_RIGHTLEG)

    return true
end

function DAMAGE:Heal(ply, heal, hitGroup)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID()

    if not self:PlayerExist(steamid) then
        self:PlayerReset(ply)
    end
    
    local health = self.Players[steamid][hitGroup]
    local defaultHealth = self.Players["Default"][hitGroup]
    
    
    self.Players[steamid][hitGroup] = math.Clamp(health + heal, 0, defaultHealth)

    self:UpdatePlayerClient(ply)
end

---
--- Medicine
---

net.Receive("Med.MakeHeal", function (len, ply)
    local className = net.ReadString()
    local hitGroup = net.ReadInt(5)

    local swep = ply:GetWeapon(className)
    if not IsValid(swep) then return end
    
    DAMAGE:Heal(ply, swep.MedHealth * swep.MedGroupsMultiplier[hitGroup], hitGroup)
    swep:TakeClip1()
end)

net.Receive("Med.ChageWeapon", function (len, ply)
    local className = net.ReadString()

    local swep = ply:GetWeapon(className)
    if not IsValid(swep) then return end

    ply:SetActiveWeapon(swep)
end)

---
--- Hooks
--- 

hook.Add("EntityTakeDamage", "Medicine.RegisterDamage", function (target, dmg)
    if not IsValid(target) or not target:IsPlayer() then return end
    
    if dmg:IsBulletDamage() then
        local hitGroup = target:LastHitGroup()
        
        local kill = DAMAGE:TakeDamage(target, dmg, hitGroup)
        
        return kill
    elseif dmg:IsFallDamage() then
        local kill = DAMAGE:TakeDamageLegs(target, dmg)

        return kill
    else
        local kill = DAMAGE:TakeDamageAll(target, dmg)

        return kill
    end
end)

hook.Add("PlayerSpawn", "Medicine.ResetHealth", function (ply, tr)
    DAMAGE:PlayerReset(ply)

    net.Start("Death.UpdateState")
        net.WriteBool(false)
    net.Send(ply)
end)

hook.Add("PlayerCanPickupWeapon", "Med.SwepPickup", function (ply, wep)
    if not IsValid(wep) then return end
    
    if wep.Base == swep_base then
        local className = wep:GetClass()

        local plyWep = ply:GetWeapon(className)
        if IsValid(plyWep) then
            local clip = plyWep:Clip1()
            if clip >= plyWep.Primary.ClipSize then return false end

            net.Start("Med.UpdateButtons")
            net.Send(ply)
        end
    end
    
    return true
end)

hook.Add("WeaponEquip", "Med.UpdateWeapon", function (wep, ply)
    if not (IsValid(wep) and IsValid(ply)) then return end
    if wep.Base == swep_base then return end

    net.Start("Med.UpdateButtons")
    net.Send(ply)
end)

hook.Add("CanPlayerSuicide", "Med.BlockCommandKill", function (ply)
    DAMAGE:KillPlayer(ply)
    
    return false
end)

hook.Add("PlayerCanPickupWeapon", "Med.BlockPickupWeapon", function (ply, wep)
    return not DAMAGE:IsPlayerDead(ply)
end)

hook.Add("PlayerSpawnSWEP", "Med.BlockSpawnSwep", function (ply, classname, swep)
    return not DAMAGE:IsPlayerDead(ply)
end)