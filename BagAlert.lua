local ADDON_NAME = ...

BagAlert = BagAlert or {}
BagAlertDB = BagAlertDB or {}

local defaults = {
  enabled = true,
  threshold = 10,
  scale = 1.0,
  showText = true,
  showIcon = true,
  locked = false,
  icon = "Interface\\Icons\\INV_Misc_Bag_22",
  pos = { point = "CENTER", relPoint = "CENTER", x = 0, y = 260 },

  soundEnabled = true,

  textPrefix = "Time to vendor!",
  textSuffix = "spaces remaining.",
}

local function copyDefaults(src, dst)
  if type(dst) ~= "table" then dst = {} end
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      copyDefaults(v, dst[k])
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end

local function clamp(n, a, b)
  n = tonumber(n)
  if n == nil then return a end
  if n < a then return a end
  if n > b then return b end
  return n
end

local function freeSlots()
  local total = 0
  for bag = 0, 4 do
    local n = GetContainerNumFreeSlots(bag)
    if n then total = total + n end
  end
  return total
end

local function playCoin()
  if BagAlertDB.soundEnabled == false then return end
  if PlaySound then pcall(PlaySound, "LOOTWINDOWCOINSOUND") end
end

local function formatText(n)
  local prefix = BagAlertDB.textPrefix or defaults.textPrefix
  local suffix = BagAlertDB.textSuffix or defaults.textSuffix
  local num = "|cFFFFFF66(" .. tostring(n) .. ")|r"
  return prefix .. " " .. num .. " " .. suffix
end

local btn, txt
local wasShown = false

local function applyPos()
  if not btn then return end
  local p = BagAlertDB.pos or defaults.pos
  btn:ClearAllPoints()
  btn:SetPoint(p.point or "CENTER", UIParent, p.relPoint or "CENTER", p.x or 0, p.y or 260)
end

function BagAlert.ApplyLockState()
  if not btn then return end
  btn:EnableMouse(not BagAlertDB.locked)
end

local function applyIcon()
  if not btn then return end
  local icon = _G["BagAlertFrameIcon"]

  if BagAlertDB.showIcon == false then
    if icon then icon:Hide() end
    btn:SetAlpha(0) -- keep as anchor for text + dragging
  else
    if icon then
      icon:Show()
      icon:SetTexture(BagAlertDB.icon or defaults.icon)
    end
    btn:SetAlpha(1)
  end
end

local function createFrame()
  if btn then return end

  btn = CreateFrame("Button", "BagAlertFrame", UIParent, "ActionButtonTemplate")
  btn:SetSize(64, 64)
  btn:SetFrameStrata("TOOLTIP")
  btn:SetFrameLevel(100)

  local n = _G["BagAlertFrameNormalTexture"]
  local p = _G["BagAlertFramePushedTexture"]
  local h = _G["BagAlertFrameHighlightTexture"]
  if n then n:Hide() end
  if p then p:Hide() end
  if h then h:Hide() end
  btn:SetNormalTexture(nil)
  btn:SetPushedTexture(nil)
  btn:SetHighlightTexture(nil)

  local icon = _G["BagAlertFrameIcon"]
  if icon then
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetDrawLayer("OVERLAY", 7)
    icon:SetTexture(BagAlertDB.icon or defaults.icon)
  end

  txt = UIParent:CreateFontString("BagAlertText", "OVERLAY", "GameFontNormalLarge")
  txt:SetPoint("TOP", btn, "BOTTOM", 0, -6)
  txt:SetTextColor(1, 0.82, 0)
  txt:SetJustifyH("CENTER")
  txt:Hide()

  btn:SetMovable(true)
  btn:RegisterForDrag("LeftButton")
  btn:SetScript("OnDragStart", function(self)
    if not BagAlertDB.locked then self:StartMoving() end
  end)
  btn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, xOfs, yOfs = self:GetPoint(1)
    BagAlertDB.pos = { point = point, relPoint = relPoint, x = xOfs, y = yOfs }
  end)

  applyPos()
  BagAlert.ApplyLockState()
  btn:Hide()
end

local function setShown(show, n)
  if not btn then return end

  if show and not wasShown then
    playCoin()
  end
  wasShown = show and true or false

  if show then
    btn:SetScale(clamp(BagAlertDB.scale or defaults.scale, 0.5, 2.0))
    btn:Show()
    applyIcon()

    if BagAlertDB.showText ~= false then
      txt:SetText(formatText(n))
      txt:Show()
    else
      txt:Hide()
    end
  else
    btn:Hide()
    txt:Hide()
  end
end

function BagAlert.UpdateAlert()
  if not btn then return end
  if BagAlertDB.enabled == false then
    setShown(false)
    return
  end

  local n = freeSlots()
  local t = tonumber(BagAlertDB.threshold) or defaults.threshold

  if n <= t then
    setShown(true, n)
  else
    setShown(false)
  end
end

SLASH_BAGALERT1 = "/bagalert"
SLASH_BAGALERT2 = "/ba"

SlashCmdList["BAGALERT"] = function(msg)
  msg = (msg and string.lower(msg)) or ""

  if msg == "test" then
    if not btn then createFrame() end
    setShown(true, freeSlots())
    return
  elseif msg == "reset" then
    BagAlertDB.pos = copyDefaults(defaults.pos, {})
    applyPos()
    return
  elseif msg == "sound" then
    playCoin()
    return
  end

  if InterfaceOptionsFrame_OpenToCategory and BagAlertOptionsPanel then
    InterfaceOptionsFrame_OpenToCategory(BagAlertOptionsPanel)
    InterfaceOptionsFrame_OpenToCategory(BagAlertOptionsPanel)
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("BAG_UPDATE")
ev:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "BagAlert" then
    BagAlertDB = copyDefaults(defaults, BagAlertDB)
    createFrame()
    BagAlert.UpdateAlert()
  elseif event == "PLAYER_ENTERING_WORLD" or event == "BAG_UPDATE" then
    if btn then BagAlert.UpdateAlert() end
  end
end)