if SERVER then
    include("medicine/sh_config.lua")
    include("medicine/sv_medicine.lua")

    AddCSLuaFile("medicine/cl_utils.lua")
    AddCSLuaFile("medicine/sh_config.lua")
    AddCSLuaFile("medicine/cl_medicine.lua")
end

if CLIENT then
    include("medicine/cl_utils.lua")
    include("medicine/sh_config.lua")
    include("medicine/cl_medicine.lua")
end