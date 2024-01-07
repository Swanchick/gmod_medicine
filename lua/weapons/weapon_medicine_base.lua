AddCSLuaFile()

if SERVER then
	util.AddNetworkString("weapon_medicene_base.clip_update")
end

SWEP.PrintName = "Base"
SWEP.Author = "Swanchick"
SWEP.Purpose = ""

SWEP.Slot = 5
SWEP.SlotPos = 3

SWEP.Spawnable = false

SWEP.ViewModel = Model( "models/weapons/c_medkit.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_medkit.mdl" )
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

SWEP.Primary.ClipSize = 5
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Amount = 1

SWEP.HoldType = "slam"

SWEP.HealSound = Sound( "HealthKit.Touch" )
SWEP.DenySound = Sound( "WallHealth.Deny" )

SWEP.HealCooldown = 0.5
SWEP.DenyCooldown = 1

SWEP.Medicine = true

SWEP.MedGroupsMultiplier = {
	[HITGROUP_HEAD] = 1,
    [HITGROUP_CHEST] = 1,
    [HITGROUP_STOMACH] = 1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 1,
    [HITGROUP_RIGHTLEG] = 1
}

SWEP.MedHealth = 50

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)

	if CLIENT then
		self.AmmoDisplay = {
			Draw = true,
			PrimaryClip = 0
		}
	end
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "LastAmmoRegen" )
	self:NetworkVar( "Float", 1, "NextIdle" )
end

function SWEP:PrimaryAttack()
	if not SERVER then return end

    net.Start("Med.MenuOpen")
		net.WriteString(self.PrintName)
    net.Send(self:GetOwner())
end

function SWEP:UpdateClClip(className, clip)
	net.Start("weapon_medicene_base.clip_update")
		net.WriteString(className)
		net.WriteInt(clip, 4)
	net.Send(self:GetOwner())
end

function SWEP:EquipAmmo(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return end

    local className = self:GetClass()
    if not ply:HasWeapon(className) then return end

    local swep = ply:GetWeapon(className)
    if not IsValid(swep) then return end

	local clip = swep:Clip1() + 1
	
	if clip > self.Primary.ClipSize then return end
	swep:SetClip1(clip)

	self:UpdateClClip(className, clip)
end

function SWEP:TakeClip1()
	local clip = self:Clip1() - 1

	if clip <= 0 then
		self:Remove()

		return
	end

	local className = self:GetClass()
	self:SetClip1(clip)
	
	
	self:UpdateClClip(className, clip)
end

if CLIENT then
	net.Receive("weapon_medicene_base.clip_update", function (len, ply)
		local className = net.ReadString()
		local amount = net.ReadInt(4)

		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local swep = ply:GetWeapon(className)
		if not IsValid(swep) then return end

		swep:SetClip1(amount)
	end)
end

function SWEP:Reload()
end

function SWEP:HealSuccess()
	self:EmitSound( self.HealSound )
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

	local owner = self:GetOwner()

	if ( owner:IsValid() ) then
		owner:SetAnimation( PLAYER_ATTACK1 )
	end

	local curtime = CurTime()

	local endtime = curtime + self:SequenceDuration()
	self:SetNextIdle( endtime )

	endtime = endtime + self.HealCooldown
	self:SetNextPrimaryFire( endtime )
end

function SWEP:Think()
	self:Idle()
end

function SWEP:Idle()
	local curtime = CurTime()

	if curtime < self:GetNextIdle() then return false end

	self:SendWeaponAnim( ACT_VM_IDLE )
	self:SetNextIdle( curtime + self:SequenceDuration() )

	return true
end

if SERVER then return end

function SWEP:CustomAmmoDisplay()
	local display = self.AmmoDisplay
	display.PrimaryClip = self:Clip1()
	return display
end