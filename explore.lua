--[[
  Project Explore  --  ESP + Aimbot
  Place 14772802900.

  Target sources, in order:
    1. entity.GetPlayers()  - canonical. Gives GetBounds/GetBonesScreen/DistanceTo
       for free, plus Name, Team and RigType.
    2. Workspace scan (automatic, only when the cache finds nobody) - for characters
       the entity cache misses. This game wraps characters in a Part, so the walk
       descends into Folders and unwraps Parts looking for a Model with a Humanoid:
         Workspace.Lobby.Players.Port<N> [Part] -> <Role> Model

  Teams: the lobby only has Teams.Gangstas, but once a round starts the game
  creates Blue and Red and both fill up. Which side you are on is not readable
  on this loader, so the Your Side dropdown under Team Check is the only source
  and has to be set to match. Change side, change the dropdown.
]]

-- One name for the menu tab, the loader log tag and the notifications, so they cannot
-- drift apart and the next rename is a single edit.
local SCRIPT_NAME = "Explore"
local TAG = "[" .. SCRIPT_NAME .. "]"

-- Name of a sound the game already owns, played once the script is live. The place ships
-- hundreds of them so there is nothing to upload. Change the name to try another:
-- Notification_Game, Purchase_1, RewardLevel1, Round_Start1, Intermission_Begin, Credit_1.
-- An empty string plays nothing.
local START_SOUND = "MatchFound"

print(TAG .. " loading")

--------------------------------------------------------------------------------------
-- compat layer
-- Every API name is resolved once at load: snake_case, then camelCase, then
-- PascalCase. pcall(nil_fn) returns false with no message, so an unresolved name
-- is otherwise a silent no-op that never reports why nothing happened.
--------------------------------------------------------------------------------------
local A = {
   Draw = {}, Input = {}, Camera = {}, Raycast = {},
   Entity = {}, Menu = {}, Notify = {}, Utility = {}, Thread = {},
   Game = {},
}

local function bind(out, ns, snake, pascal, camel)
   if type(ns) ~= "table" then return end
   out[pascal] = ns[snake] or ns[camel] or ns[pascal]
end

bind(A.Game,    _G.game,       "get_service",        "GetService",       "getService")
bind(A.Game,    _G.game,       "local_player",       "LocalPlayer",      "localPlayer")

bind(A.Draw,    _G.draw,       "get_screen_size",    "GetScreenSize",    "getScreenSize")
bind(A.Draw,    _G.draw,       "world_to_screen",    "WorldToScreen",    "worldToScreen")
bind(A.Draw,    _G.draw,       "box",                "Box",              "box")
bind(A.Draw,    _G.draw,       "corner_box",         "CornerBox",        "cornerBox")
bind(A.Draw,    _G.draw,       "text",               "Text",             "text")
bind(A.Draw,    _G.draw,       "get_text_size",      "GetTextSize",      "getTextSize")
bind(A.Draw,    _G.draw,       "line",               "Line",             "line")
bind(A.Draw,    _G.draw,       "circle",             "Circle",           "circle")
bind(A.Draw,    _G.draw,       "rect",               "Rect",             "rect")
bind(A.Draw,    _G.draw,       "rect_filled",        "RectFilled",       "rectFilled")

bind(A.Input,   _G.input,      "is_key_down",        "IsKeyDown",        "isKeyDown")
bind(A.Input,   _G.input,      "move_mouse",         "MoveMouse",        "moveMouse")
bind(A.Input,   _G.input,      "get_mouse_position", "GetMousePosition", "getMousePosition")
bind(A.Input,   _G.input,      "get_screen_center",  "GetScreenCenter",  "getScreenCenter")

bind(A.Camera,  _G.camera,     "get_position",       "GetPosition",      "getPosition")
bind(A.Camera,  _G.camera,     "get_look_vector",    "GetLookVector",    "getLookVector")
bind(A.Camera,  _G.camera,     "look_at",            "LookAt",           "lookAt")

bind(A.Raycast, _G.raycast,    "is_ready",           "IsReady",          "isReady")
bind(A.Raycast, _G.raycast,    "is_player_visible",  "IsPlayerVisible",  "isPlayerVisible")
bind(A.Raycast, _G.raycast,    "is_visible",         "IsVisible",        "isVisible")

bind(A.Entity,  _G.entity,     "get_local_player",   "GetLocalPlayer",   "getLocalPlayer")
bind(A.Entity,  _G.entity,     "get_players",        "GetPlayers",       "getPlayers")
bind(A.Entity,  _G.entity,     "get_player_count",   "GetPlayerCount",   "getPlayerCount")

bind(A.Menu,    _G.menu,       "add_tab",            "AddTab",           "addTab")
bind(A.Menu,    _G.menu,       "add_group",          "AddGroup",         "addGroup")
bind(A.Menu,    _G.menu,       "add_label",          "AddLabel",         "addLabel")
bind(A.Menu,    _G.menu,       "add_separator",      "AddSeparator",     "addSeparator")
bind(A.Menu,    _G.menu,       "add_input",          "AddInput",         "addInput")
bind(A.Menu,    _G.menu,       "add_checkbox",       "AddCheckbox",      "addCheckbox")
bind(A.Menu,    _G.menu,       "add_slider_int",     "AddSliderInt",     "addSliderInt")
bind(A.Menu,    _G.menu,       "add_combo",          "AddCombo",         "addCombo")
bind(A.Menu,    _G.menu,       "add_hotkey",         "AddHotkey",        "addHotkey")
bind(A.Menu,    _G.menu,       "add_button",         "AddButton",        "addButton")
bind(A.Menu,    _G.menu,       "add_colorpicker",    "AddColorpicker",   "addColorpicker")
bind(A.Menu,    _G.menu,       "get",                "Get",              "get")
bind(A.Menu,    _G.menu,       "get_key",            "GetKey",           "getKey")
bind(A.Menu,    _G.menu,       "get_color",          "GetColor",         "getColor")
bind(A.Menu,    _G.menu,       "set_key",            "SetKey",           "setKey")
bind(A.Menu,    _G.menu,       "set",                "Set",              "set")
bind(A.Menu,    _G.menu,       "set_visible",        "SetVisible",       "setVisible")
bind(A.Menu,    _G.menu,       "set_color",          "SetColor",         "setColor")

bind(A.Notify,  _G.notify,     "success",            "Success",          "success")
bind(A.Notify,  _G.notify,     "error",              "Error",            "error")

bind(A.Utility, _G.utility,    "world_to_screen",    "WorldToScreen",    "worldToScreen")
bind(A.Utility, _G.utility,    "get_screen_size",    "GetScreenSize",    "getScreenSize")
bind(A.Utility, _G.utility,    "get_delta_time",     "GetDeltaTime",     "getDeltaTime")
bind(A.Utility, _G.utility,    "get_tick_count",     "GetTickCount",     "getTickCount")
bind(A.Utility, _G.utility,    "is_valid",           "IsValid",          "isValid")

bind(A.Thread,  _G.thread,     "create",             "Create",           "create")
bind(A.Thread,  _G.thread,     "is_running",         "IsRunning",        "isRunning")

--------------------------------------------------------------------------------------
-- aliases
--------------------------------------------------------------------------------------
local math_abs, math_floor = math.abs, math.floor
local math_min, math_max, math_sqrt = math.min, math.max, math.sqrt
local format = string.format

local VK = {
   LMB = 0x01, RMB = 0x02, MMB = 0x04,
   ENTER = 0x0D,
   SHIFT = 0x10, CTRL = 0x11, ALT = 0x12, SPACE = 0x20,
   F1 = 0x70, F2 = 0x71, F3 = 0x72,
   X = 0x58, C = 0x43, V = 0x56, F = 0x46, G = 0x47,
}

--------------------------------------------------------------------------------------
-- instance helpers
-- The API mixes casings across objects, so every read is case-tolerant.
--------------------------------------------------------------------------------------
local function fld(obj, snake, pascal)
   if obj == nil then return nil end
   local v = obj[snake]
   if v == nil then v = obj[pascal] end
   return v
end

local function vec_xyz(v)
   if v == nil then return nil end
   local x = fld(v, "x", "X")
   if type(x) ~= "number" then return nil end
   local y = fld(v, "y", "Y")
   local z = fld(v, "z", "Z")
   if type(y) ~= "number" or type(z) ~= "number" then return nil end
   return x, y, z
end

local function inst_ok(o)
   if o == nil then return false end
   if A.Utility.IsValid then
      local ok, res = pcall(A.Utility.IsValid, o)
      if ok then return res and true or false end
   end
   return true
end

local function class_of(o)
   return fld(o, "classname", "ClassName")
end

local function children(p)
   local out = {}
   if p == nil then return out end
   local ok, list = pcall(function() return p:GetChildren() end)
   if ok and type(list) == "table" then
      for i = 1, #list do out[i] = list[i] end
   end
   return out
end

-- Case-insensitive child lookup: body part names are consistent, but the wrapper
-- names this game uses are not.
local function child_of(p, name)
   if p == nil then return nil end
   local ok, direct = pcall(function() return p:FindFirstChild(name) end)
   if ok and direct ~= nil then return direct end
   local lowered = name:lower()
   for _, ch in ipairs(children(p)) do
      local n = fld(ch, "name", "Name")
      if type(n) == "string" and n:lower() == lowered then return ch end
   end
   return nil
end

local function part_pos(p)
   if p == nil then return nil end
   local x, y, z = vec_xyz(fld(p, "position", "Position"))
   if x then return x, y, z end
   local cf = fld(p, "cframe", "CFrame")
   if cf then
      local pivot = fld(cf, "p", "p")
      if pivot == nil then pivot = fld(cf, "position", "Position") end
      x, y, z = vec_xyz(pivot)
      if x then return x, y, z end
   end
   return nil
end

-- Only the bone names the API actually projects. R6 and R15 are both covered, and
-- pairs whose parts are missing are simply skipped, so no rig branching is needed.
local BONE_LINKS = {
   { "Head", "Torso" },
   { "Torso", "HumanoidRootPart" },
   { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
   { "Head", "UpperTorso" },
   { "UpperTorso", "LowerTorso" }, { "UpperTorso", "HumanoidRootPart" },
   { "LowerTorso", "HumanoidRootPart" },
   { "UpperTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" },
   { "LeftLowerLeg", "LeftFoot" },
   { "UpperTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" },
   { "RightLowerLeg", "RightFoot" },
}

-- Kept apart from the trunk so the arms can be switched off on their own.
local BONE_ARMS = {
   { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" },
   { "LeftLowerArm", "LeftHand" },
   { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" },
   { "RightLowerArm", "RightHand" },
}

-- GetBonesScreen hands back a dictionary and leaves the arm bones out of it, so the
-- bulk call on its own draws a trunk with nothing either side of it. Every documented
-- name is then requested one at a time and only the ones the bulk call missed are kept.
local BONE_FETCH = {
   "Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso",
   "Left Arm", "Right Arm", "Left Leg", "Right Leg",
   "LeftUpperArm", "LeftLowerArm", "LeftHand",
   "RightUpperArm", "RightLowerArm", "RightHand",
   "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
   "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

-- The bone dictionary is keyed by exact name and the API documents those names as
-- case-sensitive. Canonicalising on the way in means a differently-spelled key still
-- resolves instead of silently dropping every line, and both target paths end up with
-- the same key format.
local function canon_bone(k)
   if type(k) ~= "string" then return nil end
   local s = string.lower(k)
   s = string.gsub(s, "%s+", "")
   return s
end

local function normalize_bones(raw)
   if type(raw) ~= "table" then return nil end
   local out = {}
   for k, v in pairs(raw) do
      local ck = canon_bone(k)
      if ck and type(v) == "table" and v[1] then out[ck] = { v[1], v[2] } end
   end
   if next(out) == nil then return nil end
   return out
end

local function bone_at(t, name)
   if not t.bones then return nil end
   return t.bones[name] or t.bones[canon_bone(name) or ""]
end

local AIM_BONES = {
   { "Head" },
   { "UpperTorso", "Torso" },
   { "HumanoidRootPart", "LowerTorso", "Torso" },
}
local AIM_BONE_LABELS = { "Head", "UpperTorso / Torso", "HumanoidRootPart" }

-- The game calls its two sides Team Blue and Team Red. The menu shows Defenders and
-- Attackers because that is what they actually mean, and each label carries the word to
-- match on in the real team name, so the label and the game can disagree safely. Only
-- these two sides are listed: the spectator team is deliberately not offered, because
-- nobody wants their own side decided by picking spectators.
local TEAM_SIDES = {
   { "Defenders", "blue" },
   { "Attackers", "red" },
}
local TEAM_LABELS = { TEAM_SIDES[1][1], TEAM_SIDES[2][1] }

local function side_key(i)
   local s = TEAM_SIDES[(i or 0) + 1]
   return s and s[2] or ""
end

local function side_label(i)
   return TEAM_LABELS[(i or 0) + 1] or "-"
end

-- ESP colours as a fixed palette instead of a colour picker. A picker puts four
-- draggable bars in the menu, which is a lot of room to spend on one value, and picking
-- a near-black blue that reads as grey costs more effort than choosing a named colour.
-- Index order here is the order the dropdown shows, and Red is first so it stays the
-- default the script has always used.
local COLOURS = {
   { "Red",    { 1.00, 0.20, 0.20, 1 } },
   { "Blue",   { 0.25, 0.50, 1.00, 1 } },
   { "Green",  { 0.25, 0.90, 0.35, 1 } },
   { "Yellow", { 1.00, 0.90, 0.20, 1 } },
   { "Orange", { 1.00, 0.55, 0.10, 1 } },
   { "Purple", { 0.70, 0.35, 1.00, 1 } },
   { "Pink",   { 1.00, 0.40, 0.75, 1 } },
   { "Cyan",   { 0.20, 0.90, 0.95, 1 } },
   { "Lime",   { 0.60, 1.00, 0.10, 1 } },
   { "White",  { 1.00, 1.00, 1.00, 1 } },
   { "Grey",   { 0.65, 0.65, 0.65, 1 } },
   { "Black",  { 0.10, 0.10, 0.10, 1 } },
}
local COLOUR_LABELS = {}
for i, entry in ipairs(COLOURS) do COLOUR_LABELS[i] = entry[1] end

local function colour_at(i)
   local entry = COLOURS[(i or 0) + 1]
   return entry and entry[2] or COLOURS[1][2]
end

local function colour_name(i)
   return COLOUR_LABELS[(i or 0) + 1] or "-"
end

-- The FOV slider is shown in display units so it reads 0 to 180, while the radius actually
-- drawn and tested against is in pixels. The two ends are named rather than written into the
-- call so the relationship sits in one place: the slider runs 0 to FOV_DISPLAY_MAX, and
-- FOV_DISPLAY_MAX maps to FOV_REAL_MAX pixels, which is the largest radius worth having.
local FOV_DISPLAY_MAX = 180
local FOV_REAL_MAX = 1300
local FOV_DISPLAY_DEFAULT = 42
local FOV_REAL_DEFAULT = 300

-- Clamped, because a menu can still be holding a value from a build whose slider ran to
-- 2500, and an out-of-range read is not something the draw path should have to survive.
local function fov_display(v)
   v = tonumber(v) or FOV_DISPLAY_DEFAULT
   if v < 0 then v = 0
   elseif v > FOV_DISPLAY_MAX then v = FOV_DISPLAY_MAX end
   return math_floor(v + 0.5)
end

local function fov_real(d)
   return math_floor(d * FOV_REAL_MAX / FOV_DISPLAY_MAX + 0.5)
end

-- The visibility check is one dropdown rather than a checkbox plus a Dim/Hide box plus a
-- separate Colour box. None is the off state, Dim fades the players behind a wall, and
-- Colour paints them a second colour. The two colour pickers hang off this dropdown, and
-- only the Hidden one is conditional on the mode, because a visible colour is used in
-- every mode.
local VIS_NONE, VIS_DIM, VIS_COLOUR = 0, 1, 2
local VIS_MODE_ITEMS = { "None", "Dim", "Colour" }

--------------------------------------------------------------------------------------
-- menu
--------------------------------------------------------------------------------------

-- The default of every control is recorded here as it is registered. This build accepts
-- the default argument but does not reflect it in the widget, so everything opens
-- switched off; the recorded values are pushed back through menu.Set further down.
local DEFAULTS = {}
local KEY_DEFAULTS = {}

-- The parent tree, recorded as each control is registered. The parent option on the menu
-- is undocumented for combos and hotkeys and was letting children of a hidden ESP stay
-- on screen, so it is kept only for the nesting indent and menu.SetVisible is made the
-- real authority further down. ORDER matters: a parent is always registered before its
-- children, so one pass in registration order resolves the whole tree in a single sweep.
local ORDER = {}
local PARENT = {}

-- PARENT_TOUCH: ids whose own value must not decide whether their children show. Normally a
-- parent gates on its value, so ticking or setting a parent reveals its options. A combo
-- whose index 0 is a real choice cannot work that way, or picking the first option would
-- hide everything nested under it. The Hidden Players dropdown is the one case: index 0 is
-- None, a real selection, and hiding the colour pickers for it would be exactly backwards,
-- since None still draws the ESP in the visible colour.
local PARENT_TOUCH = {}

-- GATE: an extra condition on a child itself, for when a visible parent is not enough. The
-- Hidden Colour picker is the only one: its parent is the Hidden Players dropdown, which is
-- on whenever Visable Check is ticked, but the picker means nothing unless the mode picked is
-- the one that paints behind-a-wall players a second colour.
local GATE = {}

local function record(id, opts)
   ORDER[#ORDER + 1] = id
   PARENT[id] = (opts and opts.parent) or nil
end

-- One tab holding three groups. Splitting into separate half-width tabs was tried and
-- came back with an unusable menu, so the single tab stays: it is the layout known to
-- render, and the section headings below break the long column up just as well.
local TAB = SCRIPT_NAME
local LAYOUT = {
   P = { TAB, "Players" },
   A = { TAB, "Aim" },
   S = { TAB, "Setup" },
}
local function tg(k) return LAYOUT[k][1], LAYOUT[k][2] end

-- Section headings. Left in as no-ops: the heading text is in the label itself, and
-- AddLabel is not called because a decorative element is not worth a broken menu.
local function sec() end
local function note() end

-- Forward declarations. Both bodies need S, the team tables and the frame counters, all of
-- which are declared further down, so writing them here would capture globals instead.
local diag_text
local copy_text

-- Menu button. Nothing to cache and nothing to nest, so it stays out of DEFAULTS and ORDER:
-- a button in the Setup group is a top level action like Info Text, not a feature option,
-- and a value-less id in ORDER would be read back as a missing setting every frame.
local function btn(k, id, label, cb)
   local tab, grp = tg(k)
   pcall(A.Menu.AddButton, tab, grp, id, label, cb)
end

local function cbox(k, id, label, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddCheckbox, tab, grp, id, label, def, opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function vsl(k, id, label, lo, hi, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddSliderInt, tab, grp, id, label, lo, hi, def, "%d", opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function vco(k, id, label, items, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddCombo, tab, grp, id, label, items, def, opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function abox(k, id, label, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddCheckbox, tab, grp, id, label, def, opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function asl(k, id, label, lo, hi, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddSliderInt, tab, grp, id, label, lo, hi, def, "%d", opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function aco(k, id, label, items, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddCombo, tab, grp, id, label, items, def, opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function akey(k, id, label, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddHotkey, tab, grp, id, label, def, opts)
   record(id, opts)
   -- kept apart from DEFAULTS on purpose: Set writes the wrong field on a hotkey,
   -- so these are pushed back through SetKey instead
   KEY_DEFAULTS[id] = def
end

if A.Menu.AddTab then pcall(A.Menu.AddTab, TAB, "M") end
if A.Menu.AddGroup then
   -- same_line is the built-in second column: Players takes the left half, Aim takes the
   -- right half of the same row, and Setup flows onto the next row under them. Group order
   -- is what places the columns, so Aim has to be added second even though its widgets are
   -- registered further down the file. This only moves boxes around; no id, default, parent
   -- or binding is touched.
   pcall(A.Menu.AddGroup, TAB, "Players")
   pcall(A.Menu.AddGroup, TAB, "Aim", 0, true)
   pcall(A.Menu.AddGroup, TAB, "Setup")
end

-- has to run before the team combo is registered, since the combo copies this list

-- Every checkbox in this menu loads OFF, masters and children alike. Ticking ESP only
-- reveals the sub-options, it does not switch any of them on: which parts of the ESP you
-- want is your call, not a side effect of opening the group. The same goes for Aimbot.
-- Sliders and dropdowns keep their values, since those are settings rather than switches
-- and are only read once their own parent is on.
--
-- One exception: Info Text stays on, because it is the only way to tell the script loaded
-- at all, and it sits at the top level rather than inside a feature.

note("P", "Draw players through walls")
cbox("P", "esp_on", "ESP", false, { key = VK.F2 })
vsl("P", "max_distance", "Max Distance", 10, 10000, 3000, { parent = "esp_on" })

-- Each feature sits inside ESP, and the options that edit that feature hang off the
-- feature itself, so ticking Tracers or Teammates reveals its own settings and nothing
-- else. Head Dot is the exception: it hangs straight off ESP. Nested under Skeleton it
-- stayed on screen with ESP off, and a checkbox parented to a parented checkbox is the
-- one combination that reliably does not hide.
sec("P", "-- Box --")
-- Style hangs off the Box toggle, not off ESP, so picking a box style is something you do
-- once you have decided you want a box. 2D is the full outline and Corner is the bracket
-- style; both come from the same bounds, so switching between them costs nothing.
cbox("P", "box_on", "Box", false, { parent = "esp_on" })
vco("P", "box_style", "Style", { "2D", "Corner" }, 0, { parent = "box_on" })
cbox("P", "skeleton", "Skeleton", false, { parent = "esp_on" })
cbox("P", "skel_head", "Head Dot", false, { parent = "esp_on" })

sec("P", "-- Labels --")
cbox("P", "names", "Names", false, { parent = "esp_on" })
cbox("P", "distance", "Distance", false, { parent = "esp_on" })

-- Tracers carry their own colour and their own origin. Width is fixed, same reasoning
-- as the skeleton width: one line of menu for a value that never changes.
sec("P", "-- Tracers --")
cbox("P", "tracers", "Tracers", false, { parent = "esp_on" })
vco("P", "tracer_color", "Tracer Colour", COLOUR_LABELS, 0, { parent = "tracers" })
vco("P", "tracer_from", "Tracer From", { "Bottom", "Centre" }, 0, { parent = "tracers" })

sec("P", "-- Team Check --")
-- Your Side is set by hand and it is the only thing the filter uses: the game reports
-- Blue and Red correctly but this loader will not say which one you are on, so there is
-- nothing to read. Pick the side you are playing and Tick Team Check hides that side.
cbox("P", "friendly", "Team Check", false, { parent = "esp_on" })
vco("P", "friendly_side", "Your Side", TEAM_LABELS, 0, { parent = "friendly" })
akey("P", "side_key", "Switch Side Key", VK.ENTER, { parent = "friendly" })

sec("P", "-- Filters --")
sec("P", "-- Visibility --")
-- The Visable Check tick is the master: off, no player is ever treated differently. On, the
-- Hidden Players dropdown decides how, and it has three entries rather than two. None is
-- the do-nothing case, Dim fades the players behind a wall, and Colour paints them a
-- second hue. Colour used to be a tick of its own under this dropdown, which meant ticking
-- Dim and forgetting it silently did nothing; as an entry in the list it cannot be missed.
--
-- The colour pickers hang off the dropdown, not off a box of their own. Visible Colour
-- shows in every mode because it is the ESP colour; Hidden Colour only shows when the mode
-- is Colour, since Dim uses alpha instead of a second hue and None has no hidden players to
-- colour. apply_visibility drives both.
cbox("P", "visible", "Visable Check", false, { parent = "esp_on" })
vco("P", "vis_mode", "Hidden Players", VIS_MODE_ITEMS, 0, { parent = "visible" })
vco("P", "vis_color", "Visible Colour", COLOUR_LABELS, 0, { parent = "vis_mode" })
vco("P", "hidden_color", "Hidden Colour", COLOUR_LABELS, 10, { parent = "vis_mode" })

note("A", "Aim at whoever is nearest the crosshair")
abox("A", "aim_on", "Aimbot", false, { key = VK.F1 })
-- sits directly under the toggle and is the only gate there is: bind a key and the
-- aimbot only fires while it is held, clear it and the aimbot runs on its own
-- Mouse button 2, the right button, on the usual 1/2/3 convention where 1 is left and 3 is
-- middle. The scroll wheel was the default before and never reported held on this machine,
-- so the lock could not be engaged with it. Still rebindable if right click is spoken for.
akey("A", "lock_key", "Lock Key", VK.RMB, { parent = "aim_on" })

sec("A", "-- Target --")
aco("A", "aim_bone", "Aim At", AIM_BONE_LABELS, 0, { parent = "aim_on" })
abox("A", "sticky", "Stick To One Target", false, { parent = "aim_on" })
abox("A", "only_visible", "Only Visible", false, { parent = "aim_on" })
abox("A", "aim_ignore_friends", "Ignore Teammates", false, { parent = "aim_on" })

sec("A", "-- Movement --")
asl("A", "smooth", "Smoothness", 1, 100, 50, { parent = "aim_on" })
aco("A", "aim_method", "Aim Method", { "Mouse", "Camera" }, 0, { parent = "aim_on" })

sec("A", "-- FOV --")
-- 0 to 180 on screen, which is FOV_REAL_MAX pixels of real radius. See the FOV constants.
asl("A", "fov", "FOV Radius", 0, FOV_DISPLAY_MAX, FOV_DISPLAY_DEFAULT, { parent = "aim_on" })
abox("A", "fov_circle", "Show FOV Circle", false, { parent = "aim_on" })
aco("A", "fov_shape", "FOV Shape", { "Circle", "Square" }, 0, { parent = "aim_on" })

note("S", "F2 = ESP     F1 = Aimbot")
sec("S", "-- Crosshair --")
cbox("S", "crosshair", "Crosshair", false)
aco("S", "cross_type", "Crosshair Type", { "Cross", "Dot", "Circle", "T-Shape" }, 0, { parent = "crosshair" })
vsl("S", "cross_size", "Crosshair Size", 2, 60, 10, { parent = "crosshair" })

sec("S", "-- Display --")
cbox("S", "hud", "Info Text", true)
note("S", "counts, visibility and aim state")

sec("S", "-- Debug --")
btn("S", "btn_diag", "Copy Diagnostics", function()
   local text = ""
   local okg = pcall(function() text = diag_text() end)
   if not okg or type(text) ~= "string" or text == "" then
      if A.Notify.Error then pcall(A.Notify.Error, "Diagnostics not ready", nil, 5) end
      return
   end
   local done = false
   pcall(function() done = copy_text(text) end)
   if done then
      if A.Notify.Success then pcall(A.Notify.Success, "Diagnostics copied", "paste them back") end
   else
      if A.Notify.Error then pcall(A.Notify.Error, "Clipboard unavailable", nil, 5) end
      print(TAG .. " " .. text)
   end
end)
note("S", "team data, targets and toggles")


-- Push the registered defaults back into the widgets. AddCheckbox/AddSliderInt/AddCombo
-- all take a default argument and this build stores it, but does not render it, so every
-- control opens looking switched off even though the code already treats it as on.
for id, v in pairs(DEFAULTS) do
   if A.Menu.Set then pcall(A.Menu.Set, id, v) end
end
-- hotkeys go through SetKey, never Set, or the widget ends up showing a stale key
for id, v in pairs(KEY_DEFAULTS) do
   if A.Menu.SetKey then pcall(A.Menu.SetKey, id, v) end
end

--------------------------------------------------------------------------------------
-- settings
--------------------------------------------------------------------------------------
local S = {}
local tracer_color = COLOURS[1][2]
local vis_color = COLOURS[1][2]
local hidden_color = COLOURS[11][2]
-- There is no separate fallback ESP colour. The Visible Colour picker is reachable in every
-- mode, including None, so it is simply the colour the ESP draws in.

-- Teammate matching reads team membership from the Teams service and compares it against
-- the side picked in the menu. There is no attempt to work out the local side by itself:
-- three separate reads were tried for it and none of them answered on this loader, so the
-- dropdown is the only source and Your Side has to be set to match. Changing side means
-- changing that dropdown.
local name_team = {}
local team_count = 0
-- Every team name that currently has members, lowercased. The teammate test looks for the
-- word the dropdown carries inside each real team name, so Blue and Red are matched
-- without either name being hardcoded anywhere else in the script.
local team_names = {}

local function refresh_from_cache()
   local list = nil
   if A.Entity.GetPlayers then
      local ok, r = pcall(A.Entity.GetPlayers)
      if ok and type(r) == "table" then list = r end
   end
   if list == nil then return end
   local teams, names = {}, {}
   for _, p in ipairs(list) do
      local nm = fld(p, "name", "Name")
      local dnm = fld(p, "display_name", "DisplayName")
      local tm = fld(p, "team", "Team")
      local ht = fld(p, "has_team", "HasTeam")
      if type(nm) == "string" and type(tm) == "string" then
         name_team[string.lower(nm)] = { tm, ht }
      end
      if type(dnm) == "string" and type(tm) == "string" then
         name_team[string.lower(dnm)] = { tm, ht }
      end
      if type(tm) == "string" then
         teams[string.lower(tm)] = true
         names[string.lower(tm)] = tm
      end
   end
   team_count = 0
   for _ in pairs(teams) do team_count = team_count + 1 end
   team_names = names
end

-- Live team membership, read straight from the Teams service. A Roblox Team holds its
-- members as children and instance children are readable, so this needs no property
-- access at all and, unlike the cached Team string on the player object, it cannot go
-- stale when a round starts and moves everyone into different teams.
local function refresh_from_service()
   if not A.Game.GetService then return false end
   local oks, svc = pcall(A.Game.GetService, "Teams")
   if not oks or not svc then return false end
   local okt, list = pcall(function() return svc:GetChildren() end)
   if not okt or type(list) ~= "table" then return false end

   local live, used, names = {}, 0, {}
   for _, team in ipairs(list) do
      local tn = fld(team, "name", "Name")
      if type(tn) == "string" and tn ~= "" then
         local okm, members = pcall(function() return team:GetChildren() end)
         if okm and type(members) == "table" and #members > 0 then
            used = used + 1
            names[string.lower(tn)] = tn
            for _, m in ipairs(members) do
               local mn = fld(m, "name", "Name")
               -- stored as {team, hasTeam} so this map matches the cached one exactly
               if type(mn) == "string" then live[string.lower(mn)] = { tn, true } end
            end
         end
      end
   end
   if used == 0 then return false end

   name_team = live
   team_count = used
   team_names = names
   return true
end

local function refresh_local_team()
   name_team = {}
   team_count = 0
   team_names = {}
   if refresh_from_service() then return end
   refresh_from_cache()
end

-- Nothing may show in the menu unless every master above it is on. The parent option on
-- the menu cannot be relied on for that: parent is documented only for checkbox and slider
-- options tables, and in practice a combo child of a hidden ESP stayed on screen. This
-- reads the recorded tree and drives the documented menu.SetVisible instead, so the
-- dropdowns under ESP, and under Aimbot, are gone the moment their master is unticked.
-- Declared above cache_settings because that is what calls it.
local VIS_NOW = {}
local VIS_WAS = {}

-- The Hidden Players dropdown is a parent whose children do not generally depend on which
-- entry is picked, so PARENT_TOUCH stops index 0 being read as off and hiding the colour
-- pickers exactly when None leaves the ESP drawing in the visible colour. The Hidden Colour
-- picker is the one child that does depend on the entry, and the gate keeps it on screen
-- only for the mode that reads it. Placed here rather than beside the menu block because it
-- reads S, which is not declared until the settings section below.
PARENT_TOUCH.vis_mode = true
GATE.hidden_color = function() return S.vis_mode == VIS_COLOUR end

-- Every parent in this menu is a checkbox, so the value is a boolean. A number is treated
-- as a dropdown index and 0 counts as off, purely so a future combo parent cannot silently
-- read as on and expose everything beneath it.
local function parent_on(pid)
   local v = S[pid]
   if v == nil and A.Menu.Get then
      local ok, got = pcall(A.Menu.Get, pid)
      if ok then v = got end
   end
   if type(v) == "number" then return v ~= 0 end
   return v and true or false
end

local function apply_visibility()
   if not A.Menu.SetVisible then return end
   for i = 1, #ORDER do
      local id = ORDER[i]
      local pid = PARENT[id]
      -- registration order guarantees VIS_NOW[pid] was already settled this frame, so a
      -- child is only ever shown when its whole chain above it is on
      local vis = true
      if pid then
         local gate_parent = PARENT_TOUCH[pid] and true or parent_on(pid)
         vis = ((VIS_NOW[pid] == true) and gate_parent) or false
      end
      local g = GATE[id]
      if g and not g() then vis = false end
      VIS_NOW[id] = vis
      -- only pushed on a change, so this costs nothing on a steady frame
      if VIS_WAS[id] ~= vis then
         VIS_WAS[id] = vis
         pcall(A.Menu.SetVisible, id, vis)
      end
   end
end

local function cache_settings()
   local Get = A.Menu.Get

   S.esp_on     = Get("esp_on")
   S.max_dist   = Get("max_distance") or 3000
   S.box_on     = Get("box_on")
   S.box_style  = Get("box_style") or 0
   S.skeleton   = Get("skeleton")
   S.skel_head  = Get("skel_head")
   S.names      = Get("names")
   S.distance   = Get("distance")
   S.tracers    = Get("tracers")
   S.tracer_from = Get("tracer_from") or 0
   S.tracer_colour_idx = Get("tracer_color") or 0
   tracer_color = colour_at(S.tracer_colour_idx)
   S.visible    = Get("visible")
   S.vis_mode   = Get("vis_mode") or VIS_NONE
   S.vis_colour_idx = Get("vis_color") or 0
   S.hidden_colour_idx = Get("hidden_color") or 10
   vis_color    = colour_at(S.vis_colour_idx)
   hidden_color = colour_at(S.hidden_colour_idx)
   S.friendly     = Get("friendly")
   S.side_idx   = Get("friendly_side") or 0
   S.side_key   = (A.Menu.GetKey and A.Menu.GetKey("side_key")) or 0
   S.aim_ignore_friends = Get("aim_ignore_friends")

   S.aim_on     = Get("aim_on")
   S.fov_display = fov_display(Get("fov"))
   S.fov        = fov_real(S.fov_display)
   S.smooth     = Get("smooth") or 50
   S.aim_bone   = Get("aim_bone") or 0
   S.aim_method = Get("aim_method") or 0
   S.only_visible = Get("only_visible")
   S.sticky     = Get("sticky")
   S.fov_circle = Get("fov_circle")
   S.fov_shape  = Get("fov_shape") or 0
   -- GetKey can return 0 when the hotkey was never touched; that is not a reason to
   -- disable aiming, so fall back to left mouse
   S.lock_key   = (A.Menu.GetKey and A.Menu.GetKey("lock_key")) or 0
   -- 0 is left alone on purpose: it means no key is bound, so the aimbot is not gated

   S.crosshair  = Get("crosshair")
   S.cross_type = Get("cross_type") or 0
   S.cross_size = Get("cross_size") or 10
   S.hud        = Get("hud")

   apply_visibility()
end

-- Flips the picked side on a keypress. Edge triggered off the previous frame state,
-- otherwise holding the key would alternate the teams on every single frame. The menu
-- is written as well as the local value, so the dropdown follows and the cache on the
-- next frame reads the new index back instead of undoing the switch.
local side_key_held = false

local function update_side_key()
   local key = S.side_key or 0
   if key == 0 or not A.Input.IsKeyDown then return end
   local ok, down = pcall(A.Input.IsKeyDown, key)
   down = (ok and down) and true or false
   if down and side_key_held == false then
      local nxt = ((S.side_idx or 0) + 1) % #TEAM_SIDES
      S.side_idx = nxt
      if A.Menu.Set then pcall(A.Menu.Set, "friendly_side", nxt) end
   end
   side_key_held = down
end

--------------------------------------------------------------------------------------
-- screen helpers
--------------------------------------------------------------------------------------
-- both components must be numbers: returning a pair with a nil in it would blow up
-- every caller that does arithmetic or string.format on the second value
local function screen_center()
   if A.Input.GetScreenCenter then
      local ok, cx, cy = pcall(A.Input.GetScreenCenter)
      if ok and type(cx) == "number" and type(cy) == "number" then return cx, cy end
   end
   if A.Draw.GetScreenSize then
      local ok, sw, sh = pcall(A.Draw.GetScreenSize)
      if ok and type(sw) == "number" and type(sh) == "number" then
         return sw * 0.5, sh * 0.5
      end
   end
   return 0, 0
end

local function screen_size()
   if A.Draw.GetScreenSize then
      local ok, sw, sh = pcall(A.Draw.GetScreenSize)
      if ok and type(sw) == "number" and type(sh) == "number" then return sw, sh end
   end
   if A.Utility.GetScreenSize then
      local ok, sw, sh = pcall(A.Utility.GetScreenSize)
      if ok and type(sw) == "number" and type(sh) == "number" then return sw, sh end
   end
   return 0, 0
end

local function mouse_pos()
   if A.Input.GetMousePosition then
      local ok, mx, my = pcall(A.Input.GetMousePosition)
      if ok and mx then return mx, my end
   end
   return screen_center()
end

local function w2s(x, y, z)
   if x == nil then return nil end
   if A.Utility.WorldToScreen then
      local ok, sx, sy, on = pcall(A.Utility.WorldToScreen, x, y, z)
      if ok and sx then return sx, sy, on end
   end
   if A.Draw.WorldToScreen then
      local ok, sx, sy, on = pcall(A.Draw.WorldToScreen, x, y, z)
      if ok and sx then return sx, sy, on end
   end
   return nil
end

local function text_w(s, size)
   if A.Draw.GetTextSize then
      local ok, w = pcall(A.Draw.GetTextSize, s, size)
      if ok and type(w) == "number" then return w end
   end
   return #s * (size * 0.5)
end

local function round(v)
   if v >= 0 then return math_floor(v + 0.5) end
   return -math_floor(-v + 0.5)
end


--------------------------------------------------------------------------------------
-- workspace scan (supplement)
--------------------------------------------------------------------------------------
local function get_workspace()
   local g = _G.game
   if type(g) ~= "table" then return nil end
   if g.Workspace then return g.Workspace end
   if g.GetService then
      local ok, res = pcall(g.GetService, "Workspace")
      if ok then return res end
   end
   return nil
end

-- Descends Folders, and unwraps one level out of Part wrappers (Port1 etc.).
-- Stops as soon as a Humanoid turns up, so the map geometry is never traversed.
local function collect_models()
   local out = {}
   local ws = get_workspace()
   if ws == nil then return out end

   local function add_model(m)
      if inst_ok(m) == false then return end
      local hum = child_of(m, "Humanoid")
      if hum then out[#out + 1] = { model = m, hum = hum } end
   end

   local function walk(node, depth)
      if depth > 4 then return end
      for _, ch in ipairs(children(node)) do
         local cn = class_of(ch)
         if cn == "Model" then
            add_model(ch)
         elseif cn == "Folder" then
            walk(ch, depth + 1)
         elseif cn == "Part" or cn == "BasePart" then
            for _, inner in ipairs(children(ch)) do
               if class_of(inner) == "Model" then add_model(inner) end
            end
         end
      end
   end

   walk(ws, 1)
   return out
end

--------------------------------------------------------------------------------------
-- target collection
--------------------------------------------------------------------------------------
local targets = {}
local cam_x, cam_y, cam_z

local function aim_world(t)
   if t.aim_wx then return t.aim_wx, t.aim_wy, t.aim_wz end
   return t.hwx, t.hwy, t.hwz
end

-- entity path: the API supplies bounds, bone screens and distance directly
local function build_from_entity(p)
   if fld(p, "is_local", "IsLocal") then return nil end
   if fld(p, "is_alive", "IsAlive") == false then return nil end

   local char = fld(p, "character", "Character")
   if inst_ok(char) == false then return nil end

   local dist = 0
   local ok, d = pcall(function() return p:DistanceTo() end)
   if ok and type(d) == "number" then dist = d end

   local t = {
      ent = p,
      model = char,
      hum = fld(p, "humanoid", "Humanoid"),
      name = fld(p, "name", "Name") or fld(p, "display_name", "DisplayName") or "?",
      team = fld(p, "team", "Team"),
      has_team = fld(p, "has_team", "HasTeam"),
      rig = fld(p, "rig_type", "RigType"),
      tool = fld(p, "tool_name", "ToolName"),
      dist = dist,
      -- both must start defined: a nil vis makes every visibility test read as
      -- "not false" and the option looks like it does nothing
      vis = true, friend = false,
   }

   local okb, b = pcall(function() return p:GetBounds() end)
   if okb and type(b) == "table" and b.valid and b.w and b.h and b.w > 0 then
      t.bx, t.by, t.bw, t.bh = b.x, b.y, b.w, b.h
      t.box_valid = true
   end

   local hx, hy, hz = vec_xyz(fld(p, "head_position", "HeadPosition"))
   if hx then t.hwx, t.hwy, t.hwz = hx, hy, hz end

   local okh, hxs, hys, hon = pcall(function() return p:GetBoneScreen("Head") end)
   if okh and hon and hxs then t.hsx, t.hsy, t.hon = hxs, hys, true end

   -- aim bone, first candidate the rig actually has
   local set = AIM_BONES[(S.aim_bone or 0) + 1] or AIM_BONES[1]
   for _, bn in ipairs(set) do
      local oka, ax, ay, aon = pcall(function() return p:GetBoneScreen(bn) end)
      if oka and aon and ax then
         t.asx, t.asy, t.aon = ax, ay, true
         t.aim_bone = bn
         local part = child_of(char, bn)
         local wx, wy, wz = part_pos(part)
         if wx then t.aim_wx, t.aim_wy, t.aim_wz = wx, wy, wz end
         break
      end
   end
   if t.asx == nil and t.hsx then
      t.asx, t.asy, t.aon = t.hsx, t.hsy, t.hon
   end

   -- GetBounds can report invalid even for a player standing in plain view, and
   -- GetBoneScreen can come back 0,0,false. Project the head and root directly as a
   -- fallback so a visible player is never invisible for want of a bounds call.
   if t.hwx then
      if t.hsx == nil then
         local wx, wy, won = w2s(t.hwx, t.hwy, t.hwz)
         if wx then t.hsx, t.hsy, t.hon = wx, wy, won end
      end

      if not t.box_valid and t.hsx and t.hon then
         local rx, ry, rz = vec_xyz(fld(p, "position", "Position"))
         local fx, fy, fon
         if rx then
            local hip = fld(t.hum, "hip_height", "HipHeight") or 0
            fx, fy, fon = w2s(rx, ry - (hip + 1), rz)
         end
         if not (fx and fon) then
            fx, fy = t.hsx, t.hsy + 60
         end
         local w = math_abs(t.hsx - fx)
         local h = fy - t.hsy
         if w >= 1 and h >= 1 then
            t.bx = math_min(t.hsx, fx)
            t.by = t.hsy - 3
            t.bw = math_max(4, w)
            t.bh = h + 6
            t.box_valid = true
         end
      end
   end

   if S.skeleton then
      local acc = {}
      local oks, bones = pcall(function() return p:GetBonesScreen() end)
      if oks and type(bones) == "table" then
         for k, v in pairs(bones) do
            local ck = canon_bone(k)
            if ck and type(v) == "table" and v[1] then acc[ck] = { v[1], v[2] } end
         end
      end
      -- the arms are the bones the dictionary leaves out, so each name is asked for alone
      for _, bn in ipairs(BONE_FETCH) do
         if acc[canon_bone(bn)] == nil then
            local okb, bx, by, bon = pcall(function() return p:GetBoneScreen(bn) end)
            if okb and bon and tonumber(bx) and tonumber(by) then
               acc[canon_bone(bn)] = { bx, by }
            end
         end
      end
      t.bones = normalize_bones(acc)
   end

   return t
end

-- workspace path: no entity wrapper, so project the parts directly
local function build_from_model(m, local_x, local_y, local_z)
   local model, hum = m.model, m.hum
   if inst_ok(model) == false then return nil end

   local head = child_of(model, "Head")
   if head == nil then return nil end
   local hx, hy, hz = part_pos(head)
   if not hx then return nil end

   local root = child_of(model, "HumanoidRootPart")
   if root == nil then root = child_of(model, "LowerTorso") end
   if root == nil then root = child_of(model, "Torso") end
   local rx, ry, rz = part_pos(root)
   if not rx then rx, ry, rz = hx, hy, hz end

   if local_x then
      local dx, dy, dz = rx - local_x, ry - local_y, rz - local_z
      if (dx * dx + dy * dy + dz * dz) < 9 then return nil end
   end

   local dist = 0
   if local_x then
      local dx, dy, dz = rx - local_x, ry - local_y, rz - local_z
      dist = math_sqrt(dx * dx + dy * dy + dz * dz)
   end

   local mname = fld(model, "name", "Name") or "?"
   local t = {
      model = model, hum = hum,
      name = mname,
      dist = dist,
      hwx = hx, hwy = hy, hwz = hz,
      vis = true, friend = false,
   }

   -- no entity wrapper on this path, so the team comes from the player that owns the
   -- model. Without it a teammate found by the scan is never filtered by team.
   local nt = name_team[string.lower(mname)]
   if nt then t.team, t.has_team = nt[1], nt[2] end

   local sx, sy, on = w2s(hx, hy, hz)
   if sx then t.hsx, t.hsy, t.hon = sx, sy, on end

   local set = AIM_BONES[(S.aim_bone or 0) + 1] or AIM_BONES[1]
   for _, bn in ipairs(set) do
      local part = child_of(model, bn)
      if part then
         local wx, wy, wz = part_pos(part)
         if wx then
            t.aim_wx, t.aim_wy, t.aim_wz = wx, wy, wz
            local ax, ay, aon = w2s(wx, wy, wz)
            if ax then t.asx, t.asy, t.aon = ax, ay, aon end
            t.aim_bone = bn
            break
         end
      end
   end
   if t.asx == nil and t.hsx then
      t.asx, t.asy, t.aon = t.hsx, t.hsy, t.hon
   end

   -- screen bones for the skeleton
   if S.skeleton then
      local acc = {}
      for _, bn in ipairs(BONE_FETCH) do
         if acc[bn] == nil then
            local part = child_of(model, bn)
            if part then
               local wx, wy, wz = part_pos(part)
               if wx then
                  local bx, by, bon = w2s(wx, wy, wz)
                  if bx and bon then acc[bn] = { bx, by } end
               end
            end
         end
      end
      t.bones = normalize_bones(acc)
   end

   -- box from head top to feet: root pushed down by hip height plus half the root
   if t.hsx and t.hon and rx then
      local hip = fld(hum, "hip_height", "HipHeight") or 0
      local root_h = vec_xyz(fld(root, "size", "Size"))
      local fx, fy, fon = w2s(rx, ry - (hip + (root_h and root_h or 2) * 0.5), rz)
      if fx and fon then
         local top, bot = t.hsy, fy
         local left = math_min(t.hsx, fx)
         local w = math_abs(t.hsx - fx)
         local h = bot - top
         if w < 1 or h < 1 then return nil end
         t.bx, t.by, t.bw, t.bh = left, top - 3, math_max(4, w), h + 6
         t.box_valid = true
      end
   end

   return t
end

local n_entity, n_scan = 0, 0
local anim_t = 0
local team_tick = 0

local function collect_targets()
   targets = {}
   n_entity, n_scan = 0, 0

   local list = A.Entity.GetPlayers and A.Entity.GetPlayers() or nil
   if type(list) == "table" then
      for i = 1, #list do
         local t = build_from_entity(list[i])
         if t then
            targets[#targets + 1] = t
            n_entity = n_entity + 1
         end
      end
   end

   -- The entity cache is filled by the tracker and can legitimately come back empty on a
   -- game whose characters are not standard. There used to be a Scan Workspace box for
   -- this, but the honest behaviour is to scan whenever the entity path found nobody and
   -- never otherwise: as a tick it was either dead weight or the thing the ESP depended on,
   -- and there is no setting in between. If the cache is healthy this costs one comparison
   -- per frame, and if it is not, this is the only thing that draws anybody at all.
   if n_entity == 0 then
      local lp = A.Entity.GetLocalPlayer and A.Entity.GetLocalPlayer() or nil
      local lx, ly, lz = vec_xyz(lp and fld(lp, "position", "Position"))
      if lx == nil then lx, ly, lz = cam_x, cam_y, cam_z end
      for _, m in ipairs(collect_models()) do
         -- dedupe against every path, not just this one, or a character that is both
         -- an entity player and a workspace model gets drawn twice
         local dup = false
         for _, t in ipairs(targets) do
            if t.model == m.model then dup = true break end
            if dup == false and t.hwx then
               local hx, hy, hz = part_pos(child_of(m.model, "Head"))
               if hx then
                  local dx, dy, dz = hx - t.hwx, hy - t.hwy, hz - t.hwz
                  if (dx * dx + dy * dy + dz * dz) < 1 then dup = true break end
               end
            end
         end
         if dup == false then
            local t = build_from_model(m, lx, ly, lz)
            if t then
               targets[#targets + 1] = t
               n_scan = n_scan + 1
            end
         end
      end
   end

   -- Teammate flags, computed once per frame rather than once per draw.
   --
   -- A target is a teammate when the word behind the Your Side dropdown appears inside the
   -- team name the game reports for them. Blue and Red is what this game actually calls its
   -- two sides, and each dropdown entry carries the word to look for, so the menu label and
   -- the real team name never have to match each other.
   --
   -- There is deliberately no attempt to work out which side the local player is on. Three
   -- separate reads were tried for that and none of them answered on this loader, so the
   -- dropdown is the only source and it has to be set by hand.
   --
   -- Two gates. At least two teams have to have members, because with one populated team,
   -- as in the lobby, flagging everybody would blank the ESP. And a target with no reported
   -- team is never flagged: hiding everyone because data is missing looks like a dead cheat.
   local side = side_key(S.side_idx)
   local usable = (side ~= "" and team_count >= 2)
   for _, t in ipairs(targets) do
      local tn = (type(t.team) == "string") and string.lower(t.team) or nil
      t.friend = (tn ~= nil and usable
                  and string.find(tn, side, 1, true) ~= nil) or false
   end

   -- Visibility. The old version gated the whole block on IsReady and then relied on
   -- IsPlayerVisible, which is documented to fail open until its cache is warm: with a
   -- cold cache the block was skipped, vis stayed nil, and nil == false is false, so
   -- Visible Only and Wall Check did nothing at all. A direct camera-to-head segment
   -- test is used first because it needs no cache and is what a wall check means;
   -- IsPlayerVisible is only the fallback. The check now always runs: the visuals pick
   -- a different colour per visibility, so it cannot be tied to whether anything is
   -- being hidden outright. A target with no resolvable result keeps vis nil, and nil is
   -- not false, so it is treated as visible and drawn rather than dropped.
   local have_cam = type(cam_x) == "number"
   for _, t in ipairs(targets) do
      local res = nil
      if have_cam and t.hwx and A.Raycast.IsVisible then
         local ok, v = pcall(A.Raycast.IsVisible,
                             cam_x, cam_y, cam_z, t.hwx, t.hwy, t.hwz)
         if ok and type(v) == "boolean" then res = v end
      end
      if res == nil and A.Raycast.IsPlayerVisible and t.model then
         local ok, v = pcall(A.Raycast.IsPlayerVisible, t.model)
         if ok and type(v) == "boolean" then res = v end
      end
      if res ~= nil then t.vis = res end
   end

   return targets
end

--------------------------------------------------------------------------------------
-- drawing
--------------------------------------------------------------------------------------
-- What a behind-a-wall player is drawn at when there is no second colour to draw them in.
-- Dropping alpha rather than scaling the RGB is deliberate: scaling toward black makes a
-- target disappear on a dark background, whereas alpha reads as further away on any
-- background. This is what Dim did back when there was only ever one colour.
local DIM_ALPHA = 0.4

-- One place decides what colour the ESP is in, so the box, skeleton, head dot, name,
-- distance and the aimbot FOV ring cannot drift apart from each other. is_hidden says
-- whether this particular draw is for a player behind a wall. The ring passes no target
-- and no is_hidden, so it takes the colour a player in the open would be drawn in, which
-- is the visible palette entry.
--
-- is_hidden is only ever true when the mode is Dim or Colour, so None cannot reach the dim
-- branch. Dim and Colour differ only in how the split is made: one drops the alpha, the
-- other switches hue. Both are always in effect for their mode, which is the point of
-- having them as entries in one list rather than as two things to remember to tick.
local function esp_colour(is_hidden)
   if not is_hidden then return vis_color end
   if S.vis_mode == VIS_COLOUR then return hidden_color end
   local c = vis_color
   return { c[1], c[2], c[3], DIM_ALPHA }
end

-- Two passes: a fat dark outline, then the coloured core on top. A single thin pass
-- disappears against bright walls and roofs, which is what made the old one look broken.
-- Width is fixed: the slider it came from was one line of menu for a value nobody
-- changes after the first attempt, and the outline pass is derived from it anyway.
local SKEL_W = 2

local function draw_skeleton(t, col)
   if t.bones == nil then return end
   local w = SKEL_W
   -- the outline alpha follows the core: a fixed opaque black outline would leave a
   -- dimmed skeleton reading stronger than the undimmed one, which is backwards
   local dark = { 0, 0, 0, (col[4] or 1) * 0.8 }

   -- every segment is collected first so both passes draw exactly the same geometry
   local segs = {}
   local function link(a, b)
      if a and b then segs[#segs + 1] = { a[1], a[2], b[1], b[2] } end
   end

   for i = 1, #BONE_LINKS do
      link(bone_at(t, BONE_LINKS[i][1]), bone_at(t, BONE_LINKS[i][2]))
   end

   -- Arms. On R15 each joint is its own bone, so those links are used as they are. On R6
   -- the whole arm is a single block and the API hands back one point in the middle of
   -- it, so the arm is a single straight line from the torso out to that point. Two
   -- points and nothing else, so it cannot fall apart when a bone goes missing.
   for i = 1, #BONE_ARMS do
      link(bone_at(t, BONE_ARMS[i][1]), bone_at(t, BONE_ARMS[i][2]))
   end

   local torso = bone_at(t, "Torso")
   if torso then
      for _, side in ipairs({ "Left", "Right" }) do
         link(torso, bone_at(t, side .. " Arm"))
      end
   end

   for pass = 1, 2 do
      local c, lw = dark, w + 2
      if pass == 2 then c, lw = col, w end
      for i = 1, #segs do
         local s = segs[i]
         pcall(A.Draw.Line, s[1], s[2], s[3], s[4], c, lw)
      end
   end

   -- a plain truthy test, not "not false": a nil from a missing widget has to count as
   -- off, otherwise the head dot would be the one feature nothing could switch off
   if S.skel_head then
      local h = bone_at(t, "Head")
      if h then
         local r = w * 1.7
         pcall(A.Draw.Circle, h[1], h[2], r, dark, 20, w + 2)
         pcall(A.Draw.Circle, h[1], h[2], r, col, 20, w)
      end
   end
end

local function draw_esp(t, index, now)
   if t.dist > (S.max_dist or 3000) then return end
   if t.friend and S.friendly then return end

   -- Visable Check off means no player is ever treated differently. On, the Hidden Players
   -- dropdown decides how: None draws everyone the same, Dim fades the ones behind a wall,
   -- and Colour paints them a second hue. There is no separate Hide mode, so no target is
   -- ever dropped here. A target with no resolved visibility keeps vis nil, and nil is not
   -- false, so it counts as in the open.
   local col = esp_colour(S.visible and S.vis_mode ~= VIS_NONE and t.vis == false)

   if S.skeleton then draw_skeleton(t, col) end

   if not t.box_valid then
      -- No box could be computed. If the head still projects, mark it, so a player who is
      -- on screen is never invisible while the box was asked for. Each half obeys its own
      -- switch though: with Box and Names both off there is nothing to stand in
      -- for, and drawing anyway would put a feature on that nobody ticked.
      if t.hsx and t.hon and (S.box_on or S.names) then
         if S.box_on then
            local s = 5
            pcall(A.Draw.Line, t.hsx - s, t.hsy, t.hsx + s, t.hsy, col, 2)
            pcall(A.Draw.Line, t.hsx, t.hsy - s, t.hsx, t.hsy + s, col, 2)
         end
         if S.names then
            pcall(A.Draw.Text, t.hsx + 8, t.hsy - 7, t.name, col, 13)
         end
      end
      return
   end

   -- 2D is the full outline and Corner is the bracket style. Corner reads cleaner at
   -- distance because the four edges cross the character, but the outline is easier to
   -- track up close, so it is a choice rather than a fixed answer. Both take the same
   -- bounds, and both validate (x,y) against (x+w, y+h) before drawing.
   if S.box_on then
      if S.box_style == 1 then
         pcall(A.Draw.CornerBox, t.bx, t.by, t.bw, t.bh, col)
      else
         pcall(A.Draw.Box, t.bx, t.by, t.bw, t.bh, col)
      end
   end

   local ccx = t.bx + t.bw * 0.5

   if S.tracers then
      local sw, sh = screen_size()
      if sw > 0 then
         local ox, oy = ccx, sh - 2
         if S.tracer_from == 1 then ox, oy = sw * 0.5, sh * 0.5 end
         -- the tracer has its own picker and always uses it: it is a separate visual and
         -- overriding it would make the dropdown a lie
         pcall(A.Draw.Line, ox, oy, ccx, t.by + t.bh, tracer_color, 2)
      end
   end

   local ly = t.by - 4

   if S.names then
      local nm = t.name
      pcall(A.Draw.Text, ccx - text_w(nm, 13) * 0.5, ly - 14, nm, col, 13)
      ly = ly - 14
   end

   if S.distance then
      local dt = format("%d", t.dist)
      pcall(A.Draw.Text, ccx - text_w(dt, 11) * 0.5, ly - 12, dt, col, 11)
   end
end

-- A live swatch of the picked colours, bottom left. The dropdown itself cannot preview:
-- a combo hands over plain strings, so the entry text is drawn in one fixed colour and
-- there is no way to tint "Blue" blue. A rectangle filled by the script is the only
-- honest preview, and it doubles as proof the pick reached the draw calls.
local function draw_colour_swatches(sh)
   if not (A.Draw.RectFilled) then return end

   -- built first, drawn second, so the strip is anchored to the bottom edge however many
   -- rows there happen to be rather than assuming a fixed count
   local rows = {}
   -- The visible colour is the ESP colour in every mode, so it always gets a row. The
   -- second row is whichever split the picked mode actually applies, drawn at the value it
   -- is really used at so the mode can be judged without hunting for a wall.
   rows[#rows + 1] = { vis_color, "Visible", colour_name(S.vis_colour_idx) }
   if S.visible and S.vis_mode == VIS_DIM then
      local c = vis_color
      rows[#rows + 1] = { { c[1], c[2], c[3], DIM_ALPHA }, "Hidden", "dimmed" }
   elseif S.visible and S.vis_mode == VIS_COLOUR then
      rows[#rows + 1] = { hidden_color, "Hidden", colour_name(S.hidden_colour_idx) }
   end

   if S.tracers then
      rows[#rows + 1] = { tracer_color, "Tracer", colour_name(S.tracer_colour_idx) }
   end

   -- the ring shares the ESP colour now, so it gets a row too: the only way to confirm the
   -- two actually match is to see both squares side by side
   if S.aim_on and S.fov_circle then
      rows[#rows + 1] = { esp_colour(false), "FOV", "matches ESP" }
   end

   local y = sh - 16 - 19 * (#rows - 1)
   for i = 1, #rows do
      local r = rows[i]
      pcall(A.Draw.RectFilled, 10, y, 14, 14, r[1], 2)
      -- a light outline keeps Black and Grey readable against a dark background
      pcall(A.Draw.Rect, 10, y, 14, 14, { 1, 1, 1, 0.45 }, 2, 1)
      pcall(A.Draw.Text, 30, y, r[2] .. "  " .. r[3], { 1, 1, 1, 0.85 }, 13)
      y = y + 19
   end
end

local function draw_crosshair(cx, cy)
   local s = S.cross_size or 10
   local col = { 1, 1, 1, 0.9 }
   local kind = S.cross_type or 0
   if kind == 1 then
      pcall(A.Draw.Line, cx - 2, cy, cx + 2, cy, col, 2)
   elseif kind == 2 then
      pcall(A.Draw.Circle, cx, cy, s * 0.5, col, 20, 1.5)
   elseif kind == 3 then
      pcall(A.Draw.Line, cx - s, cy, cx + s, cy, col, 2)
      pcall(A.Draw.Line, cx, cy, cx, cy + s * 0.6, col, 2)
   else
      pcall(A.Draw.Line, cx - s, cy, cx - 2, cy, col, 2)
      pcall(A.Draw.Line, cx + 2, cy, cx + s, cy, col, 2)
      pcall(A.Draw.Line, cx, cy - s, cx, cy - 2, col, 2)
      pcall(A.Draw.Line, cx, cy + 2, cx, cy + s, col, 2)
   end
end

local function draw_fov(cx, cy)
   -- the ring is drawn at the real pixel radius, not the number the slider shows
   local r = S.fov or FOV_REAL_DEFAULT
   local w = 2
   -- the ring is drawn in the ESP colour rather than white, so the aiming area and the
   -- players inside it read as one thing and follow the palette like everything else.
   -- It keeps the hue but stays translucent: at full alpha an outline this large is a hard
   -- border across the screen rather than a guide. A fresh table, because vis_color and
   -- friends are shared and are replaced wholesale each frame.
   local src = esp_colour(false)
   local col = { src[1], src[2], src[3], 0.5 }
   if S.fov_shape == 1 then
      pcall(A.Draw.Line, cx - r, cy - r, cx + r, cy - r, col, w)
      pcall(A.Draw.Line, cx - r, cy + r, cx + r, cy + r, col, w)
      pcall(A.Draw.Line, cx - r, cy - r, cx - r, cy + r, col, w)
      pcall(A.Draw.Line, cx + r, cy - r, cx + r, cy + r, col, w)
   else
      pcall(A.Draw.Circle, cx, cy, r, col, 48, w)
   end
end

--------------------------------------------------------------------------------------
-- aimbot
--------------------------------------------------------------------------------------
local sticky_ht = nil

-- cx,cy is the crosshair (screen centre), NOT the mouse cursor. In Roblox third
-- person the character faces wherever the camera looks, which is screen centre; the
-- cursor is a desktop artefact and its distance to a target means nothing to the
-- shot. Measuring from the cursor is what stops the aimbot ever acquiring anything.
local function pick_target(cx, cy)
   local function eligible(t)
      if t.dist > (S.max_dist or 3000) then return false end
      if S.aim_ignore_friends and t.friend then return false end
      if S.only_visible and t.vis == false then return false end
      if not (t.aon and t.asx) then return false end
      local dx, dy = t.asx - cx, t.asy - cy
      return math_sqrt(dx * dx + dy * dy) <= (S.fov or FOV_REAL_DEFAULT)
   end

   if S.sticky and sticky_ht then
      for _, t in ipairs(targets) do
         if t.hum == sticky_ht and eligible(t) then return t end
      end
      sticky_ht = nil
   end

   -- Always nearest to the crosshair, never nearest in world space. Screen distance is what
   -- the player is actually pointing at, and picking by studs would swing the camera to
   -- someone standing next to them instead of the one under the reticle.
   local best, best_d = nil, nil
   for _, t in ipairs(targets) do
      if eligible(t) then
         local dx, dy = t.asx - cx, t.asy - cy
         local d = math_sqrt(dx * dx + dy * dy)
         if best_d == nil or d < best_d then
            best, best_d = t, d
         end
      end
   end

   if best then sticky_ht = best.hum end
   return best
end

-- returns target, firing, held
local function run_aimbot(cx, cy)
   local t = pick_target(cx, cy)
   if t == nil then return nil, false, false end

   -- The Aim When dropdown is gone, so the Lock Key is the only gate. A bound key must
   -- be held; an unbound key (0) lets the aimbot run on its own. This replaces the old
   -- three-way mode with one control that still covers both cases.
   local held = true
   local key = S.lock_key or 0
   if key ~= 0 and A.Input.IsKeyDown then
      local ok, d = pcall(A.Input.IsKeyDown, key)
      held = (ok and d) and true or false
   end

   if held == false then return t, false, false end

   local wx, wy, wz = aim_world(t)

   if (S.aim_method or 0) == 1 then
      pcall(A.Camera.LookAt, wx, wy, wz, math_max(1.001, (101 - (S.smooth or 50)) / 8))
   else
      local smooth = S.smooth or 50
      local dt = 0.016
      if A.Utility.GetDeltaTime then
         local ok, d = pcall(A.Utility.GetDeltaTime)
         if ok and type(d) == "number" then dt = d end
      end
      -- Smoothness runs 1 to 100 where 100 is the slowest, most tracked movement. The
      -- scale is mirrored about the midpoint so the number matches what the name says:
      -- dragging it up eases the aim off rather than snapping it.
      local factor = ((101 - smooth) / 100) * math_min(1, dt * 60)
      local dx = (t.asx - cx) * factor
      local dy = (t.asy - cy) * factor
      if math_abs(dx) >= 0.5 or math_abs(dy) >= 0.5 then
         pcall(A.Input.MoveMouse, round(dx), round(dy))
      end
   end

   return t, true, true
end

--------------------------------------------------------------------------------------
-- start sound
--------------------------------------------------------------------------------------
-- Plays once the frame loop has proved itself, not at load, because a script that loads and
-- then dies is worse than one honest about it. Every step is pcall wrapped: audio is the one
-- part of this that depends on instances the loader may not expose, and a sound that fails
-- to play must never take the ESP down with it.
local sounded = false

local function play_start_sound()
   if sounded then return end
   sounded = true
   if type(START_SOUND) ~= "string" or START_SOUND == "" then return end
   if not A.Game.GetService then return end

   -- recursive because the clips sit deep in ReplicatedStorage, and both services are
   -- tried because the place keeps sounds in more than one. Cloned rather than played in
   -- place so the game keeps its own instance and a reload cannot stack copies.
   for _, sn in ipairs({ "SoundService", "ReplicatedStorage" }) do
      local ok, root = pcall(A.Game.GetService, sn)
      if ok and root then
         local okf, s = pcall(function() return root:FindFirstChild(START_SOUND, true) end)
         if okf and s then
            local okp = pcall(function()
               local c = s:Clone()
               c.Volume = 1
               c.Parent = A.Game.GetService("SoundService")
               c:Play()
            end)
            print(TAG .. (okp and " sound " .. START_SOUND or " sound would not play"))
            return
         end
      end
   end
   print(TAG .. " no sound named " .. START_SOUND)
end

--------------------------------------------------------------------------------------
-- frame
--------------------------------------------------------------------------------------
local boot_frames = 0
local frame_targets, frame_visible = 0, 0
local onframe_fired   -- forward declaration: set by the frame hook defined further down

local function frame()
   -- anim_t is our own accumulated clock rather than GetTickCount. That clock is allowed
   -- to be frozen, unavailable, or to return the same value twice, and anything timed off
   -- it would then sit on screen forever or never appear. Accumulating the frame delta
   -- ourselves means it advances for exactly as long as this loop runs.
   local dt = 0.016
   if A.Utility.GetDeltaTime then
      local ok, v = pcall(A.Utility.GetDeltaTime)
      if ok and type(v) == "number" and v > 0 and v < 1 then dt = v end
   end
   anim_t = anim_t + dt
   local now = anim_t

   cache_settings()
   update_side_key()
   if team_tick <= 0 then
      refresh_local_team()
      team_tick = 120
   end
   team_tick = team_tick - 1

   local cx, cy = screen_center()

   if A.Camera.GetPosition then
      local ok, c = pcall(A.Camera.GetPosition)
      if ok then cam_x, cam_y, cam_z = vec_xyz(c) end
   end

   collect_targets()

   frame_targets, frame_visible, frame_aimable, frame_friends = 0, 0, 0, 0
   local nearest, nearest_d = nil, nil
   for _, t in ipairs(targets) do
      frame_targets = frame_targets + 1
      if t.vis then frame_visible = frame_visible + 1 end
      if t.aon and t.asx then frame_aimable = frame_aimable + 1 end
      if t.friend then frame_friends = frame_friends + 1 end
      if nearest_d == nil or t.dist < nearest_d then
         nearest, nearest_d = t.name, t.dist
      end
   end

   local aim_t, firing, held = nil, false, false
   if S.aim_on then
      if S.fov_circle then draw_fov(cx, cy) end
      aim_t, firing, held = run_aimbot(cx, cy)
   end

   if S.crosshair then draw_crosshair(cx, cy) end

   if S.esp_on then
      for i, t in ipairs(targets) do
         draw_esp(t, i, now)
      end
   end

   if S.hud then
      local y = 10
      local function line(str, col)
         pcall(A.Draw.Text, 10, y, str, col or { 1, 1, 1, 0.9 }, 13)
         y = y + 16
      end
      line(TAG .. " targets " .. tostring(frame_targets) ..
           (frame_visible > 0 and ("  visible " .. tostring(frame_visible)) or "") ..
           "  ent " .. tostring(n_entity) .. "  scan " .. tostring(n_scan))
      -- nearest distance and on-screen box count: if targets is non-zero but boxes is
      -- zero, it is the distance filter, not the draw path
      local boxes = 0
      for _, t in ipairs(targets) do
         if t.box_valid then boxes = boxes + 1 end
      end
      line("boxes " .. tostring(boxes) .. "  nearest " ..
           (nearest_d and (nearest .. " " .. format("%d", nearest_d)) or "-") ..
           "  cutoff " .. format("%d", S.max_dist or 3000))
      if S.aim_on then
         line((aim_t and ("aim " .. aim_t.name .. "  " .. format("%d studs", aim_t.dist))
                    or "aim NONE") ..
              "  fired " .. (firing and "1" or "0"), { 1, 1, 0.5, 0.9 })
         -- aimable = targets that projected an aim bone. gate reads open when no key is
         -- bound, held when the bound key is down, idle when it is not.
         line("aimable " .. tostring(frame_aimable) ..
              "  " .. ((S.lock_key or 0) == 0 and "open"
                 or (held and "HELD" or "idle")) ..
              "  lock " .. tostring(S.lock_key or 0) ..
              -- shown as the slider shows it, so the HUD and the menu never disagree about
         -- what the number is
         "  fov " .. format("%d", S.fov_display or FOV_DISPLAY_DEFAULT) ..
              "  smooth " .. format("%d", S.smooth or 50), { 1, 1, 0.5, 0.75 })
      end
      local n = -1
      if A.Entity.GetPlayerCount then
         local ok, v = pcall(A.Entity.GetPlayerCount)
         if ok and type(v) == "number" then n = v end
      end
      if n >= 0 then line("players " .. tostring(n)) end
      -- GetScreenCenter and GetScreenSize/2 must agree or the FOV circle is off-centre;
      -- print both so a mismatch is visible rather than inferred
      local sw, sh = screen_size()
      if S.aim_on and S.fov_circle then
         line("centre " .. format("%.0f,%.0f", cx, cy) ..
              "  size/2 " .. format("%.0f,%.0f", sw * 0.5, sh * 0.5) ..
              ((math_abs(cx - sw * 0.5) > 2 or math_abs(cy - sh * 0.5) > 2)
                 and "  MISMATCH" or "  ok"), { 0.6, 0.9, 1, 0.7 })
      end
      -- teammates and visibility both read as zero when the underlying call is not
      -- answering, so both are printed rather than left to be inferred. "names" lists every
      -- team that currently has members and "side" is the dropdown entry in force, so a
      -- filter that hides the wrong people can be read off the screen: the two have to
      -- agree on the word for the result to make sense.
      local names_shown = {}
      for _, v in pairs(team_names) do names_shown[#names_shown + 1] = v end
      table.sort(names_shown)
      local names_joined = #names_shown > 0 and table.concat(names_shown, "+") or "-"
      line("teammates " .. tostring(frame_friends) ..
           "  off " .. tostring(S.friendly ~= true) ..
           "  side " .. side_label(S.side_idx) ..
           "  key " .. tostring(side_key(S.side_idx) ~= "" and side_key(S.side_idx) or "-") ..
           "  names " .. names_joined ..
           "  teams " .. tostring(team_count) ..
           ((S.friendly and team_count <= 1)
              and "  GAME-REPORTS-ONE-TEAM" or "") ..
           "  vis " .. tostring(frame_visible) .. "/" .. tostring(frame_targets) ..
           "  anim " .. format("%.1f", anim_t), { 0.7, 1, 0.7, 0.7 })
       -- the picked palette entries, so a colour that looks wrong can be named rather
       -- than guessed at. hid names the split the mode actually applies and reads none
       -- when the check is off, which matches the swatch strip row for row.
       local hid_name = "none"
       if S.visible then
          if S.vis_mode == VIS_DIM then hid_name = "dimmed"
          elseif S.vis_mode == VIS_COLOUR then hid_name = colour_name(S.hidden_colour_idx) end
       end
       line("colour vis " .. colour_name(S.vis_colour_idx) ..
            "  hid " .. hid_name ..
            "  tracer " .. colour_name(S.tracer_colour_idx),
            { 1, 1, 1, 0.6 })
   end

   -- the swatch is the real preview, so it follows ESP rather than the text HUD: it has
   -- to stay up when Info Text is off, otherwise picking a colour gives nothing to look at
   if S.esp_on then
      local sw, sh = screen_size()
      if sh > 0 then draw_colour_swatches(sh) end
   end

   boot_frames = boot_frames + 1
   if boot_frames == 30 then
      local msg = "targets=" .. tostring(frame_targets) ..
                  " visible=" .. tostring(frame_visible) ..
                  " (entity=" .. tostring(n_entity) ..
                  " scan=" .. tostring(n_scan) ..
                  " hook=" .. tostring(onframe_fired) .. ")"
      print(TAG .. " " .. msg)
      if A.Notify.Success then pcall(A.Notify.Success, SCRIPT_NAME .. " loaded", msg) end
      play_start_sound()
   end
end

--------------------------------------------------------------------------------------
-- diagnostics
--------------------------------------------------------------------------------------
-- Everything the HUD shows, gathered into one block that can be pasted back whole. The HUD
-- exists to be read at a glance; when something is actually wrong the person reading it
-- cannot copy small text off the screen, so this carries the same facts in a form that can.
local function diag_build()
   local names = {}
   for _, v in pairs(team_names) do names[#names + 1] = v end
   table.sort(names)
   local shown = (#names > 0) and table.concat(names, "+") or "-"

   local t = {}
   t[#t + 1] = SCRIPT_NAME .. " diagnostics"
   t[#t + 1] = "teams=" .. tostring(team_count) ..
               "  names=" .. shown ..
               "  side=" .. side_label(S.side_idx) ..
               "  side_key=" .. side_key(S.side_idx) ..
               "  filtering=" .. tostring(team_count >= 2 and "yes" or "one-team")
   t[#t + 1] = "friends=" .. tostring(frame_friends) ..
               "  team_check=" .. tostring(S.friendly) ..
               "  ignore_teammates=" .. tostring(S.aim_ignore_friends)
   t[#t + 1] = "targets=" .. tostring(frame_targets) ..
               "  visible=" .. tostring(frame_visible) ..
               "  entity=" .. tostring(n_entity) ..
               "  scan=" .. tostring(n_scan)
   t[#t + 1] = "esp=" .. tostring(S.esp_on) ..
               "  aim=" .. tostring(S.aim_on) ..
               "  vis_check=" .. tostring(S.visible) ..
               "  vis_mode=" .. tostring(S.vis_mode) ..
               "  max_dist=" .. tostring(S.max_dist)
   return table.concat(t, "\n")
end

-- Clipboard. GuiService:SetClipboard is the supported route and setclipboard is what most
-- loaders expose directly, so both are tried. Returns false rather than raising, because
-- the caller reports it and a failure to copy is not worth stopping the script over.
local function diag_copy(text)
   if A.Game.GetService then
      local oks, gui = pcall(A.Game.GetService, "GuiService")
      if oks and gui then
         local okc = pcall(function() gui:SetClipboard(text) end)
         if okc then return true end
      end
   end
   if type(setclipboard) == "function" then
      local okc = pcall(setclipboard, text)
      if okc then return true end
   end
   return false
end

diag_text = diag_build
copy_text = diag_copy

--------------------------------------------------------------------------------------
-- entry point
-- The doc says OnFrame/onFrame/on_frame all work, but all three are set anyway: it is
-- free, and if only one of them is actually wired up this is the difference between
-- working and silently doing nothing.
--------------------------------------------------------------------------------------
local halted = false
local last_run = 0

local function now_ms()
   if A.Utility.GetTickCount then
      local ok, v = pcall(A.Utility.GetTickCount)
      if ok and type(v) == "number" then return v end
   end
   return 0
end

local function run_frame()
   if halted then return end
   local ok, err = pcall(frame)
   last_run = now_ms()
   if ok == false then
      halted = true
      print(TAG .. " HALTED: " .. tostring(err))
      if A.Notify.Error then pcall(A.Notify.Error, SCRIPT_NAME .. " halted", tostring(err), 8) end
   end
end

local function on_frame()
   onframe_fired = true
   run_frame()
end

_G.OnFrame = on_frame
_G.onFrame = on_frame
_G.on_frame = on_frame

-- Watchdog: only drives frames if OnFrame has not run for a while, so this can never
-- double-run the loop when OnFrame is healthy.
if A.Thread.Create then
   pcall(A.Thread.Create, function()
      if halted then return end
      if now_ms() - last_run > 200 then run_frame() end
   end, 16)
end

--------------------------------------------------------------------------------------
-- load audit: name anything that failed to resolve instead of dying quietly
--------------------------------------------------------------------------------------
local REQUIRED = {
   { "draw.GetScreenSize",     A.Draw.GetScreenSize },
   { "draw.CornerBox",         A.Draw.CornerBox },
   { "draw.Text",              A.Draw.Text },
   { "draw.Line",              A.Draw.Line },
   { "draw.Circle",            A.Draw.Circle },
   { "input.IsKeyDown",        A.Input.IsKeyDown },
   { "input.MoveMouse",        A.Input.MoveMouse },
   { "input.GetMousePosition", A.Input.GetMousePosition },
   { "camera.GetPosition",     A.Camera.GetPosition },
   { "camera.LookAt",          A.Camera.LookAt },
   { "entity.GetLocalPlayer",  A.Entity.GetLocalPlayer },
   { "entity.GetPlayers",      A.Entity.GetPlayers },
   { "raycast.IsPlayerVisible", A.Raycast.IsPlayerVisible },
   { "utility.WorldToScreen",  A.Utility.WorldToScreen },
   { "utility.GetDeltaTime",   A.Utility.GetDeltaTime },
   { "menu.Get",               A.Menu.Get },
   { "menu.GetKey",            A.Menu.GetKey },
   { "thread.Create",          A.Thread.Create },
}

do
   local missing = {}
   for _, r in ipairs(REQUIRED) do
      if r[2] == nil then missing[#missing + 1] = r[1] end
   end

   -- printed at load, not on frame 30, so it is visible even if the frame loop is dead
   local sw, sh = screen_size()
   local gl = {}
   for _, n in ipairs({ "draw", "entity", "menu", "input", "camera",
                        "raycast", "utility", "notify", "thread", "game" }) do
      gl[#gl + 1] = n .. "=" .. tostring(_G[n] ~= nil)
   end

   print(TAG .. " screen " .. tostring(sw) .. "x" .. tostring(sh))
   print(TAG .. " globals " .. table.concat(gl, " "))
   print(TAG .. " frame hook " .. (onframe_fired and "fired" or "pending") ..
         "  thread=" .. tostring(A.Thread.Create ~= nil))
   if #missing > 0 then
      local msg = "Unresolved: " .. table.concat(missing, ", ")
      print(TAG .. " " .. msg)
      if A.Notify.Error then pcall(A.Notify.Error, msg, nil, 8) end
   else
      print(TAG .. " all APIs resolved")
   end
end
