
AddCSLuaFile()

SWEP.PrintName = "Defibrilator"
SWEP.Author = "Swanchick"
SWEP.Purpose = ""

SWEP.Slot = 5
SWEP.SlotPos = 3

SWEP.Spawnable = true

SWEP.ViewModel = Model( "models/weapons/c_medkit.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_medkit.mdl" )
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = SWEP.Primary.ClipSize
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

SWEP.HoldType = "slam"

SWEP.HealSound = Sound( "HealthKit.Touch" )
SWEP.DenySound = Sound( "WallHealth.Deny" )

SWEP.HealCooldown = 0.5
SWEP.DenyCooldown = 1

SWEP.HealAmount = 20
SWEP.HealRange = 64

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self:SetLastAmmoRegen(CurTime())
end

function SWEP:SetupDataTables()

	self:NetworkVar( "Float", 0, "LastAmmoRegen" )
	self:NetworkVar( "Float", 1, "NextIdle" )

end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	local dolagcomp = SERVER and owner:IsPlayer()

	if ( dolagcomp ) then
		owner:LagCompensation( true )
	end

	local startpos = owner:GetShootPos()
	local tr = util.TraceLine( {
		start = startpos,
		endpos = startpos + owner:GetAimVector() * self.HealRange,
		filter = owner
	} )

	if ( dolagcomp ) then
		owner:LagCompensation( false )
	end

    local ragdoll = tr.Entity
    if not (IsValid(ragdoll) and ragdoll:IsRagdoll()) then return end

    local ply = ragdoll:GetNWEntity("Player")
    if not IsValid(ply) then return end
    if not ply:GetNWBool("CouldBeRevived") then return end

    if SERVER then
        self:Revive(ply)
    end

    self:HealSuccess()
end

function SWEP:Revive(ply)
    if not ply:IsMedDead() then return end

    ply:DisablePhysicsRagdoll()
end


function SWEP:Reload()
end

function SWEP:HealSuccess()
	-- Do effects
	self:EmitSound( self.HealSound )
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

	local owner = self:GetOwner()

	if owner:IsValid() then
		owner:SetAnimation( PLAYER_ATTACK1 )
	end

	local curtime = CurTime()
	self:SetLastAmmoRegen( curtime )

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

	if ( curtime < self:GetNextIdle() ) then return false end

	self:SendWeaponAnim( ACT_VM_IDLE )
	self:SetNextIdle( curtime + self:SequenceDuration() )

	return true

end