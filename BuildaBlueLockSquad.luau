local Players = game:GetService("Players")
if getgenv == nil then getgenv = function() return _G end end
local HAS_STATE = typeof(STATE) == "table" and typeof((STATE :: any).alive) == "function"
local function engineAlive()
  if HAS_STATE then return (STATE :: any).alive() end
  return true
end
local LocalPlayer = Players.LocalPlayer
local MPS = game:GetService("MarketplaceService")
local bstore = require(LocalPlayer.PlayerScripts.Client.Stores.BuilderStore)
local cstore = require(LocalPlayer.PlayerScripts.Client.Stores.CollectionStore)
local mpsAny = MPS :: any
local storeAny = bstore :: any

if getgenv().FreeAutoRoll == nil then getgenv().FreeAutoRoll = false end
if getgenv().FreeRollBaru == nil then getgenv().FreeRollBaru = false end
getgenv().FreeSkip_On = true
if getgenv().FreeRollSpeed == nil then getgenv().FreeRollSpeed = 10 end
if type(getgenv().UIToggleKeyName) ~= "string" then getgenv().UIToggleKeyName = "RightControl" end
local function toggleKeyCode()
  local ok, kc = pcall(function() return (Enum.KeyCode :: any)[getgenv().UIToggleKeyName] end)
  if ok and kc then return kc end
  return Enum.KeyCode.RightControl
end

local function defaultFilter()
  return {
    Rarities = {},
    Variants = {},
    Teams = {},
    MinOverall = 0, 
  }
end
if type(getgenv().FreeFilter) ~= "table" then
  getgenv().FreeFilter = defaultFilter()
else
  local old = getgenv().FreeFilter :: any
  if old.Rarities == nil and old.Variants == nil then
    local nf = defaultFilter()
    if old.Elusive then table.insert(nf.Rarities, "Elusive") end
    if old.Shiny then table.insert(nf.Variants, "Shiny") end
    if old.Awakened then table.insert(nf.Variants, "Awakened") end
    if old.New ~= false then table.insert(nf.Variants, "New") end
    nf.MinOverall = tonumber(old.MinOverall) or 0
    getgenv().FreeFilter = nf
  else
    if old.Rarities == nil then old.Rarities = {} end
    if old.Variants == nil then old.Variants = {} end
    if old.Teams == nil then old.Teams = {} end
    if old.MinOverall == nil then old.MinOverall = 0 end
  end
end
local filt = getgenv().FreeFilter :: any

local RARITY_KEYS = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Elusive" }
local VARIANT_KEYS = { "Shiny", "Awakened", "New" }

local function normalizeList(v)
  local out = {}
  if type(v) == "string" then
    if v ~= "" then table.insert(out, v) end
  elseif type(v) == "table" then
    for k, vv in pairs(v) do
      if type(k) == "number" and type(vv) == "string" and vv ~= "" then
        table.insert(out, vv)
      elseif vv == true and type(k) == "string" then
        table.insert(out, k)
      end
    end
  end
  return out
end

local function syncFilters()
  local f = getgenv().FreeFilter :: any
  local rar = normalizeList(f.Rarities)
  local varr = normalizeList(f.Variants)
  local teams = normalizeList(f.Teams)
  f.Rarities, f.Variants, f.Teams = rar, varr, teams
  pcall(function()
    local gf = (bstore :: any).AutoRollFilters()
    for _, k in ipairs(RARITY_KEYS) do gf[k] = nil end
    for _, k in ipairs(VARIANT_KEYS) do gf[k] = nil end
    for k, _ in pairs(gf) do
      if type(k) == "string" and string.sub(k, 1, 5) == "Team:" then gf[k] = nil end
    end
    for _, k in ipairs(rar) do gf[k] = true end
    for _, k in ipairs(varr) do gf[k] = true end
    for _, t in ipairs(teams) do gf["Team:" .. t] = true end
  end)
end

pcall(function()
  mpsAny.PromptGamePassPurchase = function(...) return nil end
  mpsAny.PromptProductPurchase = function(...) return nil end
end)
pcall(function()
  LocalPlayer:SetAttribute("OwnsQuickRollGamePass", true)
  LocalPlayer:SetAttribute("OwnsAutoRollGamePass", true)
  storeAny.RefreshQuickRoll()
  pcall(function() storeAny.RefreshAutoRoll() end)
end)
local function applySpeed(v)
  getgenv().FreeRollSpeed = v
  pcall(function()
    storeAny.RollSpeed = function() return v end
  end)
end
applySpeed(getgenv().FreeRollSpeed)
syncFilters()

local function cardHit(c)
  local gf = getgenv().FreeFilter :: any
  if #(gf.Rarities or {}) == 0 and #(gf.Variants or {}) == 0 and #(gf.Teams or {}) == 0
    and (tonumber(gf.MinOverall) or 0) <= 0 then
    local cc0 = c :: any
    return true, tostring(cc0.Name or cc0.Id or "card") .. " (empty filter)"
  end
  local ok, m = pcall(function() return storeAny.MatchesAutoRoll(c) end)
  if ok and m then
    local cc = c :: any
    return true, tostring(cc.Name or cc.Id or "card")
  end
  local mo = tonumber((getgenv().FreeFilter :: any).MinOverall) or 0
  if mo > 0 then
    local ovr = tonumber((c :: any).Overall or 0) or 0
    if ovr >= mo then return true, tostring((c :: any).Name or "card") .. " (OVR" .. tostring((c :: any).Overall) .. ")" end
  end
  return false, ""
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/main/main.lua"))()
local Accent = WindUI:Gradient({
  ["0"] = { Color = Color3.fromHex("050507"), Transparency = 0 },
  ["100"] = { Color = Color3.fromHex("23262f"), Transparency = 0 },
}, { Rotation = 135 })
local Window = WindUI:CreateWindow({
  Title = "Blue Lock Squad Helper",
  Icon = "zap",
  Author = "Enjoy",
  Folder = "BLSquadHelper",
  Theme = "Dark",
  Acrylic = true,
  Background = Accent,
  BackgroundImageTransparency = 0.85,
  Radius = 16,
  ToggleKey = toggleKeyCode(),
  OpenButton = {
    Title = "Blue Lock Squad Helper",
    Icon = "zap",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
      Color3.fromHex("2a2d37"),
      Color3.fromHex("0a0a0d")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
  },
})
if HAS_STATE then
  (STATE :: any).onCleanup(function()
    pcall(function() Window:Destroy() end)
  end)
end
Window:Tag({ Title = "v1.0", Color = Color3.fromHex("#3a3d47") })

local Tab = Window:Tab({ Title = "Builders", Icon = "users" })

local SkipSec = Tab:Section({ Title = "Fast Skip", Icon = "fast-forward", Opened = true })
local AutoSec = Tab:Section({ Title = "Auto Modes", Icon = "bot", Opened = true })
local ManSec = Tab:Section({ Title = "Manual", Icon = "hand", Opened = true })

local freeToggle, autoToggle, rollBaruToggle

freeToggle = SkipSec:Toggle({
  Title = "Free Skip",
  Desc = "Skip draw card animation instantly",
  Icon = "fast-forward",
  Value = true,
  Callback = function(s)
    getgenv().FreeSkip_On = s
    if s and autoToggle then pcall(function() autoToggle:Set(false) end) end
  end,
})

autoToggle = AutoSec:Toggle({
  Title = "Custom Auto Roll",
  Desc = "Recommend to set filters first. Stops on a filter match.",
  Icon = "repeat",
  Value = getgenv().FreeAutoRoll == true,
  Callback = function(s)
    getgenv().FreeAutoRoll = s
    if s and freeToggle then pcall(function() freeToggle:Set(false) end) end
    if s and rollBaruToggle then pcall(function() rollBaruToggle:Set(false) end) getgenv().FreeRollBaru = false end
  end,
})

rollBaruToggle = AutoSec:Toggle({
  Title = "Fresh Roll",
  Desc = "Roll → Check Filters → Restart (If matching filters → Stop). Recommend to set filters first. Stops on a filter match. Ff you're stuck and can't turn on the fresh roll, just click restart first.",
  Icon = "refresh-ccw",
  Value = getgenv().FreeRollBaru == true,
  Callback = function(s)
    getgenv().FreeRollBaru = s
    if s and autoToggle then pcall(function() autoToggle:Set(false) end) getgenv().FreeAutoRoll = false end
  end,
})

ManSec:Slider({
  Title = "Roll Speed",
  Desc = "Team animation speed (1 = SLOW, 10 = INSTANT)",
  Value = { Min = 1, Max = 10, Default = getgenv().FreeRollSpeed },
  Step = 1,
  Callback = function(v) applySpeed(v) end,
})

ManSec:Button({
  Title = "Single Roll",
  Desc = "Roll once manually",
  Icon = "dices",
  Callback = function() pcall(function() storeAny.Roll() end) end,
})

ManSec:Button({
  Title = "Stop All Auto",
  Desc = "Turns off Custom Auto Roll and Fresh Roll",
  Icon = "octagon-x",
  Color = Color3.fromRGB(255, 100, 100),
  Callback = function()
    getgenv().FreeAutoRoll = false
    getgenv().FreeRollBaru = false
    pcall(function() autoToggle:Set(false) end)
    pcall(function() rollBaruToggle:Set(false) end)
  end,
})

local FTab = Window:Tab({ Title = "Filters", Icon = "list-filter" })

local RarSec = FTab:Section({ Title = "Rarity", Icon = "gem", Opened = true })
local VarSec = FTab:Section({ Title = "Variants", Icon = "sparkles", Opened = true })
local TeamSec = FTab:Section({ Title = "Teams / Categories", Icon = "shield", Opened = true })
local OvrSec = FTab:Section({ Title = "Overall", Icon = "star", Opened = true })

RarSec:Dropdown({
  Title = "Rarity",
  Desc = "Empty = No Filter.",
  Values = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Elusive" },
  Value = filt.Rarities,
  Multi = true,
  AllowNone = true,
  Callback = function(s)
    (getgenv().FreeFilter :: any).Rarities = normalizeList(s);
    (syncFilters)()
  end,
})

VarSec:Dropdown({
  Title = "Variants",
  Desc = "Empty = No Filter.",
  Values = { "Shiny", "Awakened", "New" },
  Value = filt.Variants,
  Multi = true,
  AllowNone = true,
  Callback = function(s)
    (getgenv().FreeFilter :: any).Variants = normalizeList(s);
    (syncFilters)()
  end,
})

TeamSec:Dropdown({
  Title = "Teams / Categories",
  Desc = "Empty = No Filter.",
  Values = {
    "First Selection",
    "Second Selection",
    "Third Selection",
    "Japan vs U-20 Match",
    "B Munchen",
    "FC Barcha",
    "Ubers",
    "Manshine City",
    "PXG",
    "Pros / Master Strikers",
    "New Generation World XI",
    "Nigeria U-20 Squad",
    "Japan U-20 Squad",
    "France U-20 Squad",
    "Side-B",
  },
  Value = filt.Teams,
  Multi = true,
  AllowNone = true,
  Callback = function(s)
    (getgenv().FreeFilter :: any).Teams = normalizeList(s);
    (syncFilters)()
  end,
})

OvrSec:Slider({
  Title = "Min Overall",
  Desc = "0 = OFF. Extra filter: stops when a card reaches this OVR.",
  Value = { Min = 0, Max = 120, Default = filt.MinOverall or 0 },
  Step = 1,
  Callback = function(v) (getgenv().FreeFilter :: any).MinOverall = v end,
})

-- TAB 3: Settings --
local STab = Window:Tab({ Title = "Setting", Icon = "settings" })

local KeySec = STab:Section({ Title = "Window", Icon = "keyboard", Opened = true })

KeySec:Dropdown({
  Title = "UI Toggle Key",
  Desc = "Keyboard shortcut to show/hide this window.",
  Values = {
    "RightControl",
    "RightShift",
    "LeftControl",
    "LeftShift",
    "Insert",
    "Delete",
    "Home",
    "End",
    "K",
    "H",
    "G",
    "J",
    "L",
    "M",
    "N",
    "P",
    "U",
    "Y",
    "F4",
  },
  Value = getgenv().UIToggleKeyName,
  Callback = function(s)
    local pick = s
    if type(s) == "table" then pick = s[1] end
    if type(pick) ~= "string" or pick == "" then return end
    local kc = (Enum.KeyCode :: any)[pick]
    if not kc then return end
    getgenv().UIToggleKeyName = pick
    pcall(function() Window:SetToggleKey(kc) end)
    pcall(function() Window:SetAuthor("Enjoy") end)
  end,
})

pcall(function() Window:SelectTab(Tab) end)

print("[bl-helper] template active")

task.spawn(function()
  local tick = 0
  local lastSkip = 0
  while engineAlive() do
    tick = tick + 1
    if tick % 16 == 0 then
      pcall(function()
        LocalPlayer:SetAttribute("OwnsQuickRollGamePass", true)
        LocalPlayer:SetAttribute("OwnsAutoRollGamePass", true)
      end)
    end
    local drawing, spinning = false, false
    pcall(function() drawing = (bstore :: any).Drawing() end)
    pcall(function() spinning = (bstore :: any).Spinning() end)
    if (drawing or spinning) and getgenv().FreeSkip_On == true and (os.clock() - lastSkip > 0.4) then
      lastSkip = os.clock()
      pcall(function() (bstore :: any).SkipDraw() end)
      pcall(function() storeAny.FinishDraw() end)
      pcall(function()
        local cp = storeAny.CategoryPop()
        if type(cp) == "table" then cp.Duration = 0 end
      end)
    end
    if getgenv().FreeAutoRoll == true and not drawing and not spinning then
      local cards = nil
      pcall(function() cards = (bstore :: any).Draw().Cards or {} end)
      local hit = false
      local hitName = ""
      if type(cards) == "table" then
        for _, c in ipairs(cards) do
          local h, n = cardHit(c)
          if h then hit = true hitName = n break end
        end
      end
      if hit then
        getgenv().FreeAutoRoll = false
        pcall(function() autoToggle:Set(false) end)
        print("[free-auto] STOP: " .. hitName)
        pcall(function() storeAny.SetMessage("AUTO STOP: " .. hitName) end)
      else
        local canRoll = false
        pcall(function() canRoll = (bstore :: any).CanRoll() end)
        if canRoll then
          pcall(function() storeAny.Roll() end)
          task.wait(0.6)
        else
          task.wait(0.5)
        end
      end
    end
    if getgenv().FreeRollBaru == true and not drawing and not spinning then
      local cards = nil
      pcall(function() cards = (bstore :: any).Draw().Cards or {} end)
      if type(cards) == "table" and #cards > 0 then
        local hit = false
        local hitName = ""
        for _, c in ipairs(cards) do
          local h, n = cardHit(c)
          if h then hit = true hitName = n break end
        end
        if hit then
          getgenv().FreeRollBaru = false
          pcall(function() rollBaruToggle:Set(false) end)
          print("[roll-baru] STOP: " .. hitName)
          pcall(function() storeAny.SetMessage("FRESH ROLL STOP: " .. hitName) end)
        else
          pcall(function() storeAny.Restart() end)
          task.wait(0.8)
        end
      else
        local canRoll = false
        pcall(function() canRoll = (bstore :: any).CanRoll() end)
        if canRoll then
          pcall(function() storeAny.Roll() end)
          task.wait(0.6)
        else
          task.wait(0.5)
        end
      end
    end
    task.wait(0.15)
  end
end)
