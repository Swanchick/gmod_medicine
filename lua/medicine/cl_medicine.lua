---
--- Fonts
---

surface.CreateFont("Med.Large", {
    font = "Roboto",
	extended = true,
	size = ScreenScale(14),
	weight = 800
})

surface.CreateFont("Med.Small", {
    font = "Roboto",
	extended = true,
	size = ScreenScale(9),
	weight = 800
})

---
--- Local variables
---

---
--- Damage
---

local DAMAGE_DEFAULT = {
    [HITGROUP_HEAD] = 50,
    [HITGROUP_CHEST] = 75,
    [HITGROUP_STOMACH] = 75,
    [HITGROUP_LEFTARM] = 100,
    [HITGROUP_RIGHTARM] = 100,
    [HITGROUP_LEFTLEG] = 100,
    [HITGROUP_RIGHTLEG] = 100
}

local DAMAGE = {}

net.Receive("Damage.Update", function (len)
    local health = net.ReadTable()

    DAMAGE = health
end)

---
--- Death
---

---
--- Death panel
---

do
    local PANEL = {}
    
    function PANEL:Init()
        self.CurTime = CurTime()
        self.TimeToWait = MED.Death.TimeRespawn
        self.CurrentText = MED.Text.Death.Revive
    end

    function PANEL:PerformLayout()
        local wide, tall = ScrW(), ScrH()

        self:SetSize(wide, tall)
    end

    function PANEL:ChangeText()
        self.TimeToWait = MED.Death.TimeToDie
        self.CurrentText = MED.Text.Death.Dead
    end

    function PANEL:Paint(w, h)
        surface.SetDrawColor(COLOR_BACKGROUND)
        surface.DrawRect(0, 0, w, h)

        local time = math.Round(self.TimeToWait - (CurTime() - self.CurTime))

        draw.DrawText(string.format(self.CurrentText, time), "Med.Large", w/2, h/2, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end

    vgui.Register("Death.Menu", PANEL)
end

---
--- Death net
---

if IsValid(DEATH_MENU) then
    DEATH_MENU:Remove()
end

net.Receive("Death.UpdateState", function (len)
    local open = net.ReadBool()

    if open then
        DEATH_MENU = vgui.Create("Death.Menu", GetHUDPanel())
    else
        if IsValid(DEATH_MENU) then
            DEATH_MENU:Remove()
        end
    end
end)

net.Receive("Death.ChangeText", function (len)
    if IsValid(DEATH_MENU) then
        DEATH_MENU:ChangeText()
    end
end)

---
--- Medicine
--- 


-- Button

do
    local PANEL = {}

    function PANEL:Init()
        self:SetText("")

        self.SlotName = "NONE"
        self.SlotQuantity = "0"

        self.Active = false
        self.CurrentColor = COLOR_BACKGROUND

        self.Hovered = false
    end

    function PANEL:SetSwep(swep)
        self.Swep = swep
    end

    function PANEL:UpdateInfo()
        local swep = self.Swep
        if not IsValid(swep) then return end
        
        self.SlotName = swep.PrintName
        self.SlotQuantity = swep:Clip1()

        local slotModel = vgui.Create("DModelPanel", self)
        if IsValid(slotModel) then
            slotModel:SetModel(swep.WorldModel)
            slotModel:Dock(LEFT)
            slotModel:SetCamPos(Vector(0, 0, 50))
            slotModel:SetFOV(30)
        end
    end

    function PANEL:SetSlotName(name)
        self.SlotName = name or "NONE"
    end

    function PANEL:SetSlotQuantity(quantity)
        self.SlotQuantity = quantity or "0"
    end

    function PANEL:SetSlotModel(model)
        if not model then return end
        
        local slotModel = vgui.Create("DModelPanel", self)
        if IsValid(slotModel) then
            slotModel:SetModel(model)
            slotModel:Dock(LEFT)
            slotModel:SetCamPos(Vector(0, 0, 50))
            slotModel:SetFOV(30)
        end
    end


    function PANEL:PerformLayout()
        local tall = ScreenScale(20)
        self:SetTall(tall)

        local margin = ScreenScale(5)
        self:DockMargin(0, 0, 0, margin)
    end

    function PANEL:Paint(w, h)
        if self.Active then
            self.CurrentColor = LerpColor(FrameTime() * 100, self.CurrentColor, COLOR_BACKGROUND_ACTIVATED)
        elseif self:IsHovered() then
            self.CurrentColor = LerpColor(FrameTime() * 100, self.CurrentColor, COLOR_BACKGROUND_HOVERED)
        else
            self.CurrentColor = LerpColor(FrameTime() * 100, self.CurrentColor, COLOR_BACKGROUND)
        end
        
        surface.SetDrawColor(self.CurrentColor)
        surface.DrawRect(0, 0, w, h)

        local margin = ScreenScale(5)

        draw.DrawText(self.SlotName, "Med.Large", w/2, ScreenScale(3), COLOR_WHITE, TEXT_ALIGN_CENTER)
        draw.DrawText(self.SlotQuantity, "Med.Large", w - margin, ScreenScale(3), COLOR_WHITE, TEXT_ALIGN_RIGHT)
    end

    vgui.Register("Medicine.Slot", PANEL, "DButton")
end

-- Main menu

do
    local PANEL = {}

    function PANEL:Init()
        self:MakePopup()

        local model = vgui.Create("DModelPanel", self)
        if IsValid(model) then
            self.PlayerModel = model
            
            model:SetModel(LocalPlayer():GetModel())
            model:Dock(LEFT)
            model:SetCamPos(Vector(0, -40, 50))
            model:SetFOV(35)
        end
        
        self.CurrentHeal = HITGROUP_HEAD
        self.CurrentPos = 0

        self.ArrowMaterial = Material("arrow.png", "smooth")

        self.Buttons = {}

        local inventory = vgui.Create("DScrollPanel", self)
        if IsValid(inventory) then
            self.Inventory = inventory

            inventory:Dock(RIGHT)

            function inventory:PerformLayout()
                local invWide = ScreenScale(125)
                
                self:SetWide(invWide)
            end

            local invLabel = vgui.Create("EditablePanel")
            if IsValid(invLabel) then
                self.InvLabel = invLabel

                invLabel:Dock(TOP)

                function invLabel:Paint(w, h)
                    surface.SetDrawColor(COLOR_BACKGROUND)
                    surface.DrawRect(0, 0, w, h)

                    draw.DrawText(MED.Text.Menu.Inventory, "Med.Large", w/2, ScreenScale(3), COLOR_WHITE, TEXT_ALIGN_CENTER)
                end

                inventory:AddItem(invLabel)
            end
        end

        self.HealPower = "+ 0"
        self.CurrentSwep = NULL

        local closeButton = vgui.Create("Medicine.Slot", self)
        if IsValid(closeButton) then
            self.CloseButton = closeButton

            closeButton:SetSlotName("Close")
            closeButton:SetSlotQuantity("")
            closeButton:Dock(BOTTOM)

            closeButton.DoClick = function ()
                self:Remove()
            end
        end
    end

    function PANEL:DisableButtons()
        for k, button in ipairs(self.Buttons) do
            if not IsValid(button) then continue end

            button.Active = false
        end
    end

    function PANEL:SetActiveButton(name)
        for k, button in ipairs(self.Buttons) do
            if not IsValid(button) then continue end
            
            if button.SlotName == name then
                button.Active = true
                local swep = button.Swep
                self.CurrentSwep = swep
                
                self.HealPower = "+ " .. swep.MedGroupsMultiplier[self.CurrentHeal] * swep.MedHealth

                return
            end
        end
    end

    function PANEL:OnMousePressed(mouse)
        if mouse ~= MOUSE_LEFT then return end

        local mouseX, mouseY = input.GetCursorPos()        
        
        local playerModel = self.PlayerModel
        if not IsValid(playerModel) then return end
        
        local healthWide = ScreenScale(100)
        local wide, tall = playerModel:GetSize()
        local posX, posY = playerModel:GetPos()
        local size = #DAMAGE_DEFAULT
        local maxX = posX + wide + healthWide
        local minX = posX + wide
        if mouseX > maxX or mouseX < minX then return end

        if not IsValid(self.CurrentSwep) then return end

        local damage = DAMAGE[self.CurrentHeal]
        local damageDefault = DAMAGE_DEFAULT[self.CurrentHeal]
        if damage >= damageDefault then return end

        surface.PlaySound("items/medshot4.wav")

        net.Start("Med.MakeHeal")
            net.WriteString(self.CurrentSwep:GetClass())
            net.WriteInt(self.CurrentHeal, 5)
        net.SendToServer()

        timer.Simple(0.1, function ()
            self:InitButtons()
        end)
    end

    function PANEL:InitButtons()
        local inventory = self.Inventory
        if not IsValid(inventory) then return end
        
        if IsValid(self.EmptyLabel) then
            self.EmptyLabel:Remove()
        end

        if not table.IsEmpty(self.Buttons) then
            for k, button in ipairs(self.Buttons) do
                if not IsValid(button) then continue end
                
                button:Remove()
            end

            self.Buttons = {}
        end

        local sweps = LocalPlayer():GetWeapons()
        for k, swep in ipairs(sweps) do
            if not IsValid(swep) then continue end
            if not swep.Medicine then continue end
            
            local button = vgui.Create("Medicine.Slot")
            
            button:SetSlotName(swep.PrintName)
            button:Dock(TOP)
            button:SetSwep(swep)
            button:UpdateInfo()
            inventory:AddItem(button)

            table.insert(self.Buttons, button)

            button.DoClick = function ()
                self:DisableButtons()
                button.Active = true
                self.CurrentSwep = button.Swep

                surface.PlaySound("UI/buttonclick.wav")

                net.Start("Med.ChageWeapon")
                    net.WriteString(button.Swep:GetClass())
                net.SendToServer()

                self.HealPower = "+ " .. swep.MedGroupsMultiplier[self.CurrentHeal] * swep.MedHealth
            end
        end

        if table.IsEmpty(self.Buttons) then
            local label = vgui.Create("EditablePanel")
            if not IsValid(label) then return end
            self.EmptyLabel = label

            label:Dock(TOP)

            function label:Paint(w, h)
                draw.DrawText(MED.Text.Menu.Empty, "Med.Large", w/2, ScreenScale(3), COLOR_WHITE, TEXT_ALIGN_CENTER)
            end

            inventory:AddItem(label)
        end
    end

    function PANEL:PerformLayout()
        local wide, tall = ScrW(), ScrH()

        self:SetSize(wide, tall)

        local margin = ScreenScale(25)
        local marginLeftRight = ScreenScale(50)

        local playerModel = self.PlayerModel
        if IsValid(playerModel) then
            local playerModelWide = ScreenScale(100)
            
            playerModel:DockMargin(marginLeftRight, margin, 0, margin)
            playerModel:SetWide(playerModelWide)
        end

        local inventory = self.Inventory
        if IsValid(inventory) then
            inventory:DockMargin(0, margin, marginLeftRight, margin)
        end

        local emptyLabel = self.EmptyLabel
        if IsValid(emptyLabel) then
            local tall = ScreenScale(20)
            
            emptyLabel:SetTall(tall)
        end

        local invLabel = self.InvLabel
        if IsValid(invLabel) then
            local tall = ScreenScale(20)
            
            invLabel:SetTall(tall)
        end
    end

    function PANEL:Think()
        local mouseX, mouseY = input.GetCursorPos()        
        
        local playerModel = self.PlayerModel
        if not IsValid(playerModel) then return end
        
        local healthWide = ScreenScale(100)
        local wide, tall = playerModel:GetSize()
        local posX, posY = playerModel:GetPos()
        local size = #DAMAGE_DEFAULT
        local maxX = posX + wide + healthWide
        local minX = posX + wide

        if mouseX > maxX or mouseX < minX then return end

        self.CurrentHeal = math.Clamp(math.Round(((mouseY - posY) + (tall / size)) / (tall / size)), 1, size)

        local swep = self.CurrentSwep
        if not IsValid(swep) then return end

        self.HealPower = "+ " .. swep.MedGroupsMultiplier[self.CurrentHeal] * swep.MedHealth
    end

    function PANEL:Paint(w, h)
        surface.SetDrawColor(COLOR_BACKGROUND)
        surface.DrawRect(0, 0, w, h)

        local playerModel = self.PlayerModel
        if not IsValid(playerModel) then return end

        local posX, posY = playerModel:GetPos()
        local wide = playerModel:GetWide()
        local tall = playerModel:GetTall()

        local healthWide = ScreenScale(100)
        local healthTall = ScreenScale(20)

        local size = #DAMAGE_DEFAULT
        local x = posX + wide

        for k, health in ipairs(DAMAGE_DEFAULT) do
            if not DAMAGE[k] then return end
            
            local y = posY + (k - 1) * (tall / size)
            local currentHealth = (DAMAGE[k] / DAMAGE_DEFAULT[k])
            local barSize = currentHealth * healthWide
            local barTall = ScreenScale(5)

            surface.SetDrawColor(COLOR_BACKGROUND_HOVERED)
            surface.DrawRect(x, y, healthWide, healthTall)

            surface.SetDrawColor(255 * (1 - currentHealth), 255 * currentHealth, 0)
            surface.DrawRect(x, y + healthTall - barTall, barSize, barTall)

            draw.DrawText(MED.Text.HitGroupsNames[k], "Med.Large", x + healthWide / 2, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
        end

        if not IsValid(self.CurrentSwep) then return end 

        local arrowSize = ScreenScale(15)
        local arrowX = x + healthWide
        local arrowY = posY + arrowSize + (self.CurrentHeal - 1) * (tall / size) - healthTall / 2
        self.CurrentPos = Lerp(FrameTime() * 10, self.CurrentPos, arrowY)

        draw.DrawText(self.HealPower, "Med.Large", arrowX, self.CurrentPos, COLOR_HEALTH, TEXT_ALIGN_LEFT)
    end

    vgui.Register("Medicine.HealthFullPanel", PANEL, "EditablePanel")
end

if IsValid(MENU_HEALTH) then
    MENU_HEALTH:Remove()
end


local function createHealthMenu(buttonName)
    if IsValid(MENU_HEALTH) then return end

    MENU_HEALTH = vgui.Create("Medicine.HealthFullPanel")
    MENU_HEALTH:InitButtons()

    if buttonName then
        MENU_HEALTH:SetActiveButton(buttonName)
    end
end


net.Receive("Med.MenuOpen", function (len)
    local buttonName = net.ReadString()
    
    createHealthMenu(buttonName)
end)

net.Receive("Med.UpdateButtons", function (len)
    if not IsValid(MENU_HEALTH) then return end

    MENU_HEALTH:InitButtons()
end)

---
--- Little health panel
---

do
    local PANEL = {}

    function PANEL:Init()
        self.CurrentColor = COLOR_BACKGROUND
    end

    function PANEL:PerformLayout()
        local marginLeft = ScreenScale(10)
        
        local wide, tall = ScreenScale(60), ScreenScale(150)

        self:CenterVertical()
        self:SetX(marginLeft)

        self:SetSize(wide, tall)
    end

    function PANEL:OnMousePressed(mouse)
        if mouse ~= MOUSE_LEFT then return end

        createHealthMenu()

        self:Remove()
    end

    function PANEL:Paint(w, h)
        if self:IsHovered() then
            self.CurrentColor = LerpColor(FrameTime() * 50, self.CurrentColor, COLOR_BACKGROUND_HOVERED)
        else
            self.CurrentColor = LerpColor(FrameTime() * 50, self.CurrentColor, COLOR_BACKGROUND)
        end
        
        local marginTop = ScreenScale(14)

        surface.SetDrawColor(COLOR_BACKGROUND_HOVERED)
        surface.DrawRect(0, 0, w, marginTop)

        surface.SetDrawColor(self.CurrentColor)
        surface.DrawRect(0, marginTop, w, h - marginTop)

        draw.DrawText("YOU", "Med.Large", w/2, 0, COLOR_WHITE, TEXT_ALIGN_CENTER)

        for k, defaultHealth in pairs(DAMAGE_DEFAULT) do
            local health = DAMAGE[k]

            if not health then continue end

            local posY = ScreenScale(30) + (k-1) * ScreenScale(17)

            draw.DrawText(MED.Text.HitGroupsNames[k], "Med.Small", w/2, posY, COLOR_WHITE, TEXT_ALIGN_CENTER)

            local margin = ScreenScale(4)
            local wide = w - margin * 2

            surface.SetDrawColor(COLOR_WHITE)
            surface.DrawRect(margin, posY + ScreenScale(10), wide, ScreenScale(5))

            surface.SetDrawColor(COLOR_HEALTH)
            surface.DrawRect(margin, posY + ScreenScale(10), wide * (health / defaultHealth), ScreenScale(5))
        end
    end

    vgui.Register("Medicine.Health", PANEL)
end

---
--- hooks
---

if IsValid(HEALTH_PANEL) then
    HEALTH_PANEL:Remove()
end

hook.Add("ScoreboardShow", "Medicine.ShowButton", function ()
    if not IsValid(HEALTH_PANEL) then 
        HEALTH_PANEL = vgui.Create("Medicine.Health")
    end
    
    HEALTH_PANEL:Show()
    
end)

hook.Add("ScoreboardHide", "Medicine.HideButton", function ()
    if IsValid(HEALTH_PANEL) then
        HEALTH_PANEL:Hide()
    end
end)