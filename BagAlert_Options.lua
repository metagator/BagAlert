BagAlertOptionsPanel = CreateFrame("Frame", "BagAlertOptionsPanel", UIParent)
BagAlertOptionsPanel.name = "BagAlert"
local P = BagAlertOptionsPanel

local LEFT, RIGHT = 16, -24
local y = -16

local function nextLine(px)
  y = y - (px or 24)
  return y
end

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function update()
  if BagAlert and BagAlert.UpdateAlert then BagAlert.UpdateAlert() end
end

local function wrap(fs)
  fs:SetJustifyH("LEFT")
  fs:SetJustifyV("TOP")
  if fs.SetWordWrap then fs:SetWordWrap(true) end
  if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
end

local function title()
  local t = P:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  t:SetPoint("TOPLEFT", LEFT, y)
  t:SetText("BagAlert")
  nextLine(26)
end

local function desc()
  local d = P:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  d:SetPoint("TOPLEFT", P, "TOPLEFT", LEFT, y)
  d:SetPoint("TOPRIGHT", P, "TOPRIGHT", RIGHT, y)
  wrap(d)
  d:SetHeight(28)
  d:SetText("Shows a bag warning icon when your free bag slots are at or below the threshold.")
  nextLine(44)
end

local function header(text)
  local h = P:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  h:SetPoint("TOPLEFT", LEFT, y)
  h:SetText(text)
  nextLine(22)
end

local function checkbox(name, label, get, set)
  local cb = CreateFrame("CheckButton", name, P, "InterfaceOptionsCheckButtonTemplate")
  cb:SetPoint("TOPLEFT", LEFT, y)

  local txt = _G[name .. "Text"]
  if txt then
    txt:SetText(label)
    txt:ClearAllPoints()
    txt:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    txt:SetPoint("RIGHT", P, "RIGHT", RIGHT, 0)
    wrap(txt)
    txt:SetHeight(26)
  end

  cb:SetScript("OnShow", function(self)
    self:SetChecked(get() and true or false)
  end)

  cb:SetScript("OnClick", function(self)
    set(self:GetChecked() and true or false)
    update()
  end)

  nextLine(26)
  return cb
end

local function slider(name, label, minv, maxv, step, get, set, fmt)
  local lbl = P:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  lbl:SetPoint("TOPLEFT", P, "TOPLEFT", LEFT, y)
  lbl:SetPoint("TOPRIGHT", P, "TOPRIGHT", RIGHT - 120, y)
  lbl:SetJustifyH("LEFT")
  lbl:SetText(label)

  local val = P:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  val:SetPoint("TOPRIGHT", P, "TOPRIGHT", RIGHT, y)
  val:SetJustifyH("RIGHT")
  val:SetText("")

  nextLine(18)

  local s = CreateFrame("Slider", name, P, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", LEFT, y)
  s:SetWidth(280)
  s:SetMinMaxValues(minv, maxv)
  s:SetValueStep(step)

  if _G[name .. "Text"] then _G[name .. "Text"]:SetText("") end
  _G[name .. "Low"]:SetText(tostring(minv))
  _G[name .. "High"]:SetText(tostring(maxv))

  local function setVal(v)
    val:SetText(fmt and fmt(v) or tostring(v))
  end

  s:SetScript("OnShow", function(self)
    local v = get()
    v = clamp(v, minv, maxv)
    self:SetValue(v)
    setVal(v)
  end)

  s:SetScript("OnValueChanged", function(self, v)
    v = math.floor((v / step) + 0.5) * step
    v = clamp(v, minv, maxv)
    set(v)
    setVal(v)
    update()
  end)

  nextLine(44)
  return s
end

local function button(name, text, x, yoff, fn)
  local b = CreateFrame("Button", name, P, "UIPanelButtonTemplate")
  b:SetSize(110, 20)
  b:SetPoint("BOTTOMLEFT", P, "BOTTOMLEFT", x, yoff)
  b:SetText(text)
  b:SetScript("OnClick", fn)
  local fs = b:GetFontString()
  if fs then fs:SetFontObject(GameFontHighlightSmall) end
  return b
end

title()
desc()

checkbox("BagAlertEnableCB", "Enable", function()
  return BagAlertDB and (BagAlertDB.enabled ~= false)
end, function(v)
  BagAlertDB.enabled = v
end)

checkbox("BagAlertShowTextCB", "Show text", function()
  return BagAlertDB and (BagAlertDB.showText ~= false)
end, function(v)
  BagAlertDB.showText = v
end)

checkbox("BagAlertShowIconCB", "Show icon", function()
  return BagAlertDB and (BagAlertDB.showIcon ~= false)
end, function(v)
  BagAlertDB.showIcon = v
end)

checkbox("BagAlertLockCB", "Lock position", function()
  return BagAlertDB and (BagAlertDB.locked == true)
end, function(v)
  BagAlertDB.locked = v
  if BagAlert and BagAlert.ApplyLockState then BagAlert.ApplyLockState() end
end)

slider("BagAlertThresholdSlider", "Threshold:", 0, 100, 1,
  function() return (BagAlertDB and tonumber(BagAlertDB.threshold)) or 10 end,
  function(v) BagAlertDB.threshold = v end)

slider("BagAlertScaleSlider", "Scale:", 0.5, 2.0, 0.1,
  function() return (BagAlertDB and tonumber(BagAlertDB.scale)) or 1.0 end,
  function(v) BagAlertDB.scale = v end,
  function(v) return string.format("%.1f", v) end)

header("Alert")

checkbox("BagAlertSoundCB", "Play sound", function()
  return BagAlertDB and (BagAlertDB.soundEnabled ~= false)
end, function(v)
  BagAlertDB.soundEnabled = v
end)

button("BagAlertTestBtn", "Test", 16, 56, function()
  if SlashCmdList and SlashCmdList.BAGALERT then SlashCmdList.BAGALERT("test") end
end)

button("BagAlertSoundTestBtn", "Sound", 132, 56, function()
  if SlashCmdList and SlashCmdList.BAGALERT then SlashCmdList.BAGALERT("sound") end
end)

button("BagAlertResetBtn", "Reset", 248, 56, function()
  if SlashCmdList and SlashCmdList.BAGALERT then SlashCmdList.BAGALERT("reset") end
end)

local author = P:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
author:SetPoint("BOTTOMLEFT", P, "BOTTOMLEFT", LEFT, 32)
author:SetPoint("BOTTOMRIGHT", P, "BOTTOMRIGHT", RIGHT, 32)
wrap(author)
author:SetHeight(14)
author:SetText("|cFFAAAAAAAuthor: Ewbrotha  •  Tips: mail Ewbrotha on Ebenhold|r")

-- register category (InterfaceOptions is load-on-demand in WotLK)
local registered = false
local function tryRegister()
  if registered then return true end
  if not InterfaceOptions_AddCategory then return false end
  InterfaceOptions_AddCategory(BagAlertOptionsPanel)
  registered = true
  return true
end

local reg = CreateFrame("Frame")
reg:RegisterEvent("PLAYER_LOGIN")
reg:RegisterEvent("ADDON_LOADED")
reg:SetScript("OnEvent", function(self, event, arg1)
  if event == "PLAYER_LOGIN" then
    if LoadAddOn then pcall(LoadAddOn, "Blizzard_InterfaceOptions") end
    tryRegister()
  elseif event == "ADDON_LOADED" and arg1 == "Blizzard_InterfaceOptions" then
    tryRegister()
  end
end)