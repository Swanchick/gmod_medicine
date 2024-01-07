MED = MED or {}

-- Colors 
COLOR_BACKGROUND = Color(0, 0, 0, 200)
COLOR_BACKGROUND_HOVERED = Color(0, 0, 0, 240)
COLOR_BACKGROUND_ACTIVATED = Color(50, 50, 50, 200)
COLOR_WHITE = Color(255, 255, 255)
COLOR_HEALTH = Color(86, 254, 77)

-- Damage options 
MED.Damage = {}
MED.Damage.FallScale = 0.7

-- Death options
MED.Death = {}
MED.Death.TimeRespawn = 10
MED.Death.TimeToDie = 30

-- Text
MED.Text = {}
MED.Text.HitGroupsNames = {
    [HITGROUP_HEAD] = "Head",
    [HITGROUP_CHEST] = "Chest",
    [HITGROUP_STOMACH] = "Stomach",
    [HITGROUP_LEFTARM] = "Left arm",
    [HITGROUP_RIGHTARM] = "Right arm",
    [HITGROUP_LEFTLEG] = "Left leg",
    [HITGROUP_RIGHTLEG] = "Right leg"
}
MED.Text.Death = {}
MED.Text.Death.Revive = "You will be able to be revived in %s seconds."
MED.Text.Death.Dead = "You will completely die in %s seconds."

MED.Text.Menu = {}
MED.Text.Menu.Empty = "Inventory is empty"
MED.Text.Menu.Inventory = "Inventory"