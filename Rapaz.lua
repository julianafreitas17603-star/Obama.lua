-- ==========================================================
--  💀 PAINEL PRO v5.3 — FINAL
--  AIM + Speed + ESP + Noclip + Voo + TP + Crosshair + Vida
--  🖤 Monochrome Edition
--  ✨ Bolinha premium com hover + pulse ring
--  ❤️ HEALTH v5.3 — 5 camadas + burst + detecção precisa
-- ==========================================================

repeat task.wait(0.1) until game:IsLoaded()

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Camera    = workspace.CurrentCamera

local THEME = {
    Bg = Color3.fromRGB(0, 0, 0), Bg2 = Color3.fromRGB(8, 8, 8),
    Surface = Color3.fromRGB(12, 12, 12), Card = Color3.fromRGB(18, 18, 18),
    CardHi = Color3.fromRGB(26, 26, 26), Accent = Color3.fromRGB(240, 240, 240),
    Accent2 = Color3.fromRGB(200, 200, 200), AccentSoft = Color3.fromRGB(180, 180, 180),
    Text = Color3.fromRGB(248, 248, 248), SubText = Color3.fromRGB(140, 140, 140),
    Muted = Color3.fromRGB(90, 90, 90), Success = Color3.fromRGB(220, 220, 220),
    Warning = Color3.fromRGB(200, 200, 200), Danger = Color3.fromRGB(255, 80, 80),
    Off = Color3.fromRGB(40, 40, 40), White = Color3.new(1, 1, 1),
    Black = Color3.new(0, 0, 0), Border = Color3.fromRGB(60, 60, 60),
}

local ESP_COLORS = {
    { "Branco",   Color3.fromRGB(255, 255, 255) },
    { "Cinza",    Color3.fromRGB(180, 180, 180) },
    { "Vermelho", Color3.fromRGB(255, 30, 30) },
    { "Ciano",    Color3.fromRGB(34, 211, 238) },
    { "Verde",    Color3.fromRGB(52, 211, 100) },
    { "Amarelo",  Color3.fromRGB(250, 204, 21) },
    { "Roxo",     Color3.fromRGB(170, 60, 255) },
    { "Rosa",     Color3.fromRGB(255, 100, 200) },
}
local CROSS_COLORS = {
    { "Branco",   Color3.fromRGB(255, 255, 255) },
    { "Cinza",    Color3.fromRGB(180, 180, 180) },
    { "Vermelho", Color3.fromRGB(255, 40, 40) },
    { "Verde",    Color3.fromRGB(80, 255, 80) },
    { "Ciano",    Color3.fromRGB(34, 211, 238) },
    { "Amarelo",  Color3.fromRGB(250, 220, 21) },
    { "Roxo",     Color3.fromRGB(200, 100, 255) },
    { "Rosa",     Color3.fromRGB(255, 100, 200) },
}

local BUBBLE = 56
local AnimEnabled = true

local connections = {}
local function connect(sig, fn)
    local c = sig:Connect(fn); table.insert(connections, c); return c
end

local function tween(o, p, t, style, dir)
    if not AnimEnabled then
        for k, v in pairs(p) do pcall(function() o[k] = v end) end
        return nil
    end
    local tw = TweenService:Create(o, TweenInfo.new(t or 0.28, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), p)
    tw:Play(); return tw
end

local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

local function round(o, r)
    return make("UICorner", { CornerRadius = UDim.new(0, r or 14) }, o)
end

local function stroke(o, c, t, tr)
    return make("UIStroke", {
        Color = c or THEME.White, Thickness = t or 1,
        Transparency = tr or 0.9, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end

local function innerHighlight(o, transparency)
    return make("Frame", {
        Size = UDim2.new(1, -12, 0, 1), Position = UDim2.new(0.5, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = THEME.White,
        BackgroundTransparency = transparency or 0.94,
        BorderSizePixel = 0, ZIndex = 3,
    }, o)
end

local orderN = 0
local function order() orderN += 1; return orderN end
local function isPointer(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch
end

-- GUI RAIZ
local gui = make("ScreenGui", {
    Name = "PainelPro", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true, DisplayOrder = 100,
}, playerGui)

local root = make("Frame", {
    Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(540, 460),
    BackgroundTransparency = 1, Visible = false, ZIndex = 100,
}, gui)

local fit = make("UIScale", {}, root)
local function updateFit()
    local vp = gui.AbsoluteSize
    if vp.X > 0 and vp.Y > 0 then
        fit.Scale = math.clamp(math.min(vp.X / 580, vp.Y / 500), 0.5, 1)
    end
end
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), updateFit)
updateFit()

local win = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, root)
local anim = make("UIScale", { Scale = 0.75 }, win)

local shadowOuter = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10),
    Size = UDim2.new(1, 20, 1, 20), BackgroundColor3 = THEME.Black,
    BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = -2,
}, win)
round(shadowOuter, 26)

local shadowInner = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 5),
    Size = UDim2.new(1, 8, 1, 8), BackgroundColor3 = THEME.Black,
    BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = -1,
}, win)
round(shadowInner, 20)

local main = make("Frame", {
    Name = "Main", Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = THEME.Bg, BorderSizePixel = 0,
    ClipsDescendants = true, ZIndex = 1,
}, win)
round(main, 18)
make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.Bg2),
        ColorSequenceKeypoint.new(0.5, THEME.Bg),
        ColorSequenceKeypoint.new(1, THEME.Bg),
    }), Rotation = 135,
}, main)
stroke(main, THEME.Border, 1, 0.4)
innerHighlight(main, 0.9)

-- HEADER
local top = make("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, ZIndex = 2 }, main)
local logoRing = make("Frame", {
    Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(38, 38),
    BackgroundColor3 = THEME.White, BackgroundTransparency = 1, ZIndex = 3,
}, top)
round(logoRing, 19)
stroke(logoRing, THEME.White, 1, 0.7)
local logo = make("Frame", {
    Position = UDim2.fromOffset(22, 18), Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = THEME.White, ZIndex = 4,
}, top)
round(logo, 15)
make("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
    Text = "💀", TextColor3 = THEME.Black, TextSize = 15,
    Font = Enum.Font.GothamBold, ZIndex = 5,
}, logo)
make("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(68, 12),
    Size = UDim2.new(1, -140, 0, 22), Text = "PAINEL PRO",
    TextColor3 = THEME.Text, TextSize = 16, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
}, top)
make("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(68, 36),
    Size = UDim2.new(1, -140, 0, 14), Text = "v5.3  ·  MONOCHROME",
    TextColor3 = THEME.Muted, TextSize = 10, Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
}, top)

local minBtn = make("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0),
    Size = UDim2.fromOffset(32, 32), BackgroundColor3 = THEME.Card,
    BackgroundTransparency = 0.15, Text = "–", TextColor3 = THEME.Text,
    TextSize = 20, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 4,
}, top)
round(minBtn, 16)
local minBtnStroke = stroke(minBtn, THEME.Border, 1, 0.6)
minBtn.MouseEnter:Connect(function()
    tween(minBtn, { BackgroundColor3 = THEME.Danger }, 0.22)
    tween(minBtnStroke, { Transparency = 1 }, 0.22)
end)
minBtn.MouseLeave:Connect(function()
    tween(minBtn, { BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.15 }, 0.22)
    tween(minBtnStroke, { Transparency = 0.6 }, 0.22)
end)

make("Frame", {
    Position = UDim2.new(0.5, 0, 0, 64), AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(1, -40, 0, 1), BackgroundColor3 = THEME.Border,
    BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 2,
}, main)

do
    local dragging, dragStart, startPos
    top.InputBegan:Connect(function(input)
        if isPointer(input) then
            dragging = true; dragStart = input.Position; startPos = root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and isMove(input) then
            local d = input.Position - dragStart
            root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- SIDEBAR
local sidebar = make("Frame", {
    Position = UDim2.fromOffset(12, 76),
    Size = UDim2.new(0, 146, 1, -88),
    BackgroundColor3 = THEME.Surface, BackgroundTransparency = 0.15,
    BorderSizePixel = 0, ZIndex = 2,
}, main)
round(sidebar, 16)
stroke(sidebar, THEME.Border, 1, 0.7)
innerHighlight(sidebar, 0.94)

local tabHolder = make("Frame", { Size = UDim2.new(1, 0, 1, -70), BackgroundTransparency = 1, ZIndex = 3 }, sidebar)
make("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, tabHolder)
make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, tabHolder)

local profile = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
    Size = UDim2.new(1, -16, 0, 52), BackgroundColor3 = THEME.Card,
    BackgroundTransparency = 0.15, Visible = true, ZIndex = 4,
}, sidebar)
round(profile, 14)
stroke(profile, THEME.Border, 1, 0.7)
innerHighlight(profile, 0.94)

local avatarWrap = make("Frame", {
    Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = THEME.Off, BackgroundTransparency = 0.3, ZIndex = 5,
}, profile)
round(avatarWrap, 18)
local avatar = make("ImageLabel", {
    Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(32, 32),
    BackgroundTransparency = 1, Image = "", ZIndex = 6,
}, avatarWrap)
round(avatar, 16)
stroke(avatarWrap, THEME.White, 1.5, 0.3)
task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok then avatar.Image = img end
end)
make("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(52, 10),
    Size = UDim2.new(1, -58, 0, 16), Text = player.DisplayName,
    TextColor3 = THEME.Text, TextSize = 12, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5,
}, profile)
make("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(52, 28),
    Size = UDim2.new(1, -58, 0, 12), Text = "● Online",
    TextColor3 = THEME.Success, TextSize = 10, Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
}, profile)

local content = make("Frame", {
    Position = UDim2.fromOffset(170, 76),
    Size = UDim2.new(1, -182, 1, -88),
    BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 2,
}, main)

-- SISTEMA DE ABAS
local pages, tabButtons = {}, {}
local currentTab

local function selectTab(name)
    currentTab = name
    for n, page in pairs(pages) do
        local active = (n == name)
        if active and not page.Visible then
            page.Position = UDim2.fromOffset(0, 16)
            tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.42, Enum.EasingStyle.Quint)
        end
        page.Visible = active
        local btn = tabButtons[n]
        local bar = btn:FindFirstChild("ActiveBar")
        if bar then
            tween(bar, { Size = active and UDim2.new(0, 3, 0.55, 0) or UDim2.new(0, 0, 0.55, 0) }, 0.28, Enum.EasingStyle.Quint)
        end
        tween(btn, {
            BackgroundTransparency = active and 0.25 or 1,
            TextColor3 = active and THEME.Text or THEME.SubText,
        }, 0.22)
    end
end

local function newTab(name, icon, tabOrder)
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 1, Text = "   " .. icon .. "   " .. name,
        TextColor3 = THEME.SubText, TextSize = 12, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
        LayoutOrder = tabOrder, ZIndex = 4,
    }, tabHolder)
    round(btn, 10)
    local bar = make("Frame", {
        Name = "ActiveBar", Size = UDim2.new(0, 0, 0.55, 0),
        Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = THEME.White, BorderSizePixel = 0, ZIndex = 5,
    }, btn)
    round(bar, 2)
    btn.MouseEnter:Connect(function()
        if currentTab ~= name then tween(btn, { BackgroundTransparency = 0.85, TextColor3 = THEME.Text }, 0.15) end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= name then tween(btn, { BackgroundTransparency = 1, TextColor3 = THEME.SubText }, 0.15) end
    end)
    local page = make("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageTransparency = 0.3,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, ZIndex = 2,
    }, content)
    page.ScrollBarImageColor3 = THEME.Accent
    make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 16), PaddingBottom = UDim.new(0, 14) }, page)
    pages[name], tabButtons[name] = page, btn
    btn.Activated:Connect(function() selectTab(name) end)
    return page
end

-- COMPONENTES
local function text(parent, str, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1, Text = str, TextSize = size,
        TextColor3 = color, Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        Size = UDim2.new(1, 0, 0, (size * 2) + 6), LayoutOrder = order(),
    }, parent)
end

local function card(parent, height)
    local c = make("Frame", {
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 0.05, LayoutOrder = order(), ZIndex = 2,
    }, parent)
    round(c, 16)
    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, THEME.CardHi),
            ColorSequenceKeypoint.new(1, THEME.Card),
        }), Rotation = 90,
    }, c)
    stroke(c, THEME.Border, 1, 0.75)
    innerHighlight(c, 0.94)
    return c
end

local function makeListHolder(parent, height)
    local h = make("Frame", {
        Size = UDim2.new(1, 0, 0, height or 0),
        BackgroundColor3 = THEME.Surface, BackgroundTransparency = 0.4,
        BorderSizePixel = 0, LayoutOrder = order(), ZIndex = 2,
    }, parent)
    round(h, 12)
    stroke(h, THEME.Border, 1, 0.75)
    make("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, h)
    make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, h)
    return h
end

local function addToggle(parent, label, default, callback)
    local state = default or false
    local row = card(parent, 52)
    make("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -92, 1, 0), Text = label,
        TextColor3 = THEME.Text, TextSize = 13, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
    }, row)
    local track = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(46, 26),
        BackgroundColor3 = state and THEME.White or THEME.Off,
        BackgroundTransparency = state and 0 or 0.2,
        Text = "", AutoButtonColor = false, ZIndex = 3,
    }, row)
    round(track, 13)
    local trackStroke = stroke(track, state and THEME.White or THEME.Border, 1, state and 0.4 or 0.8)
    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = state and THEME.Black or THEME.White,
        BorderSizePixel = 0, ZIndex = 4,
    }, track)
    round(knob, 9)
    track.Activated:Connect(function()
        state = not state
        tween(track, {
            BackgroundColor3 = state and THEME.White or THEME.Off,
            BackgroundTransparency = state and 0 or 0.2,
        }, 0.28)
        tween(knob, {
            Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
            BackgroundColor3 = state and THEME.Black or THEME.White,
        }, 0.32, Enum.EasingStyle.Back)
        tween(trackStroke, {
            Color = state and THEME.White or THEME.Border,
            Transparency = state and 0.4 or 0.8,
        }, 0.28)
        if callback then callback(state) end
    end)
    return row
end

local function addSlider(parent, label, min, max, default, callback, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    local value = default or min
    local row = card(parent, 70)
    make("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 12),
        Size = UDim2.new(1, -112, 0, 18), Text = label,
        TextColor3 = THEME.Text, TextSize = 13, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
    }, row)
    local valueLabel = make("TextLabel", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -18, 0, 12), Size = UDim2.fromOffset(90, 18),
        Text = tostring(value), TextColor3 = THEME.White, TextSize = 13,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3,
    }, row)
    local bar = make("Frame", {
        Position = UDim2.new(0, 18, 0, 50), Size = UDim2.new(1, -36, 0, 6),
        BackgroundColor3 = THEME.Off, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, ZIndex = 3,
    }, row)
    round(bar, 3)
    local fill = make("Frame", {
        Size = UDim2.fromScale((value - min) / (max - min), 1),
        BackgroundColor3 = THEME.White, BorderSizePixel = 0, ZIndex = 4,
    }, bar)
    round(fill, 3)
    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(18, 18), BackgroundColor3 = THEME.White,
        BorderSizePixel = 0, ZIndex = 5,
    }, fill)
    round(knob, 9)
    stroke(knob, THEME.Black, 2, 0)
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        value = math.floor((min + (max - min) * rel) * mult + 0.5) / mult
        valueLabel.Text = (decimals > 0) and string.format("%." .. decimals .. "f", value) or tostring(value)
        tween(fill, { Size = UDim2.fromScale(rel, 1) }, 0.08)
        if callback then callback(value) end
    end
    local sliding = false
    bar.InputBegan:Connect(function(input)
        if isPointer(input) then
            sliding = true
            parent.ScrollingEnabled = false
            tween(knob, { Size = UDim2.fromOffset(24, 24) }, 0.14)
            update(input)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if isPointer(input) and sliding then
            sliding = false
            parent.ScrollingEnabled = true
            tween(knob, { Size = UDim2.fromOffset(18, 18) }, 0.18, Enum.EasingStyle.Back)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if sliding and isMove(input) then update(input) end
    end)
    return row
end

local function addButton(parent, label, primary, callback)
    local holder = make("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = primary and THEME.White or THEME.Card,
        BackgroundTransparency = primary and 0 or 0.1,
        LayoutOrder = order(), ZIndex = 2,
    }, parent)
    round(holder, 14)
    if primary then stroke(holder, THEME.White, 1, 0.2)
    else stroke(holder, THEME.Border, 1, 0.75) end
    innerHighlight(holder, 0.9)
    local b = make("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = label, TextColor3 = primary and THEME.Black or THEME.Text, TextSize = 13,
        Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 3,
    }, holder)
    b.MouseEnter:Connect(function()
        if not primary then tween(holder, { BackgroundColor3 = THEME.CardHi, BackgroundTransparency = 0 }, 0.18)
        else tween(holder, { BackgroundTransparency = 0.15 }, 0.18) end
    end)
    b.MouseLeave:Connect(function()
        if not primary then tween(holder, { BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.1 }, 0.18)
        else tween(holder, { BackgroundTransparency = 0 }, 0.18) end
    end)
    b.Activated:Connect(function()
        tween(holder, { Size = UDim2.new(1, -8, 0, 42) }, 0.1)
        task.delay(0.1, function()
            tween(holder, { Size = UDim2.new(1, 0, 0, 46) }, 0.24, Enum.EasingStyle.Back)
        end)
        if callback then task.spawn(callback) end
    end)
    return holder
end

local function addButtonRow(parent, items, default, callback)
    local row = card(parent, 60)
    make("UIGridLayout", {
        CellSize = UDim2.new(1/3, -4, 0, 24), CellPadding = UDim2.fromOffset(4, 4),
        SortOrder = Enum.SortOrder.LayoutOrder, FillDirectionMaxCells = 3,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, row)
    make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, row)
    local btns = {}
    local selected = default
    for i, item in ipairs(items) do
        local b = make("TextButton", {
            BackgroundColor3 = item.value == selected and THEME.White or THEME.Card,
            Text = item.label,
            TextColor3 = item.value == selected and THEME.Black or THEME.Text,
            Font = Enum.Font.GothamBold, TextSize = 10,
            AutoButtonColor = false, LayoutOrder = i, ZIndex = 3,
        }, row)
        round(b, 6)
        btns[item.value] = b
        b.Activated:Connect(function()
            selected = item.value
            for k, btn in pairs(btns) do
                if k == selected then
                    tween(btn, { BackgroundColor3 = THEME.White }, 0.2)
                    btn.TextColor3 = THEME.Black
                else
                    tween(btn, { BackgroundColor3 = THEME.Card }, 0.2)
                    btn.TextColor3 = THEME.Text
                end
            end
            if callback then callback(selected) end
        end)
    end
    return row
end

-- NOTIFICAÇÃO
local function notify(msg)
    local toast = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -80),
        Size = UDim2.fromOffset(320, 54), BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 0.05, ZIndex = 200,
    }, gui)
    round(toast, 16)
    stroke(toast, THEME.Border, 1, 0.7)
    innerHighlight(toast, 0.9)
    make("Frame", {
        Position = UDim2.fromOffset(10, 12), Size = UDim2.new(0, 3, 1, -24),
        BackgroundColor3 = THEME.White, BorderSizePixel = 0, ZIndex = 201,
    }, toast)
    make("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -46, 1, 0), Text = msg,
        TextColor3 = THEME.Text, TextSize = 13, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201,
    }, toast)
    local s = make("UIScale", { Scale = 0.9 }, toast)
    tween(toast, { Position = UDim2.new(0.5, 0, 0, 24) }, 0.55, Enum.EasingStyle.Back)
    tween(s, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
    task.delay(2.3, function()
        tween(toast, { Position = UDim2.new(0.5, 0, 0, -80) }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tween(s, { Scale = 0.9 }, 0.28)
        task.wait(0.4)
        toast:Destroy()
    end)
end

-- TEAM CHECK
local NEUTRAL_COLORS = {
    ["Medium stone grey"] = true, ["Medium Stone Grey"] = true,
    ["Institutional white"] = true, ["White"] = true,
    ["Really black"] = true, ["Black"] = true,
}
local TEAM_ATTR_NAMES  = {"Team","team","TeamId","teamId","TeamName","teamName","Side","side","Faction","faction","Group","group"}
local TEAM_CHILD_NAMES = {"Team","team","TeamId","TeamName","Side","Faction"}

local function GetTeamKey(plr)
    if plr.Team then return "T:" .. plr.Team.Name end
    local tc = plr.TeamColor
    if tc and not NEUTRAL_COLORS[tc.Name] then return "C:" .. tc.Name end
    for _, a in ipairs(TEAM_ATTR_NAMES) do
        local v = plr:GetAttribute(a)
        if v ~= nil then return "A:" .. tostring(v) end
    end
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        for _, n in ipairs(TEAM_CHILD_NAMES) do
            local v = ls:FindFirstChild(n)
            if v and (v:IsA("StringValue") or v:IsA("IntValue") or v:IsA("NumberValue")) then
                return "L:" .. tostring(v.Value)
            end
        end
    end
    local char = plr.Character
    if char then
        for _, a in ipairs(TEAM_ATTR_NAMES) do
            local v = char:GetAttribute(a)
            if v ~= nil then return "CA:" .. tostring(v) end
        end
        for _, n in ipairs(TEAM_CHILD_NAMES) do
            local v = char:FindFirstChild(n)
            if v and (v:IsA("StringValue") or v:IsA("IntValue") or v:IsA("NumberValue")) then
                return "F:" .. tostring(v.Value)
            end
        end
    end
    return nil
end

local function AngleBetween(a, b)
    return math.deg(math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1)))
end

local function IsAliveHumanoid(h)
    if not h or h.Health <= 0 then return false end
    local ok, st = pcall(function() return h:GetState() end)
    if ok and st and (st == Enum.HumanoidStateType.Dead or st == Enum.HumanoidStateType.None) then
        return false
    end
    return true
end

-- AIM
local ACONFIG = {
    EnabledPlayers = false, MaxDistance = 5000, FOV = 360, TeamCheck = true,
    Prediction = false, PredictionSpeed = 400, Smoothness = 0,
    AutoFire = false, AFCooldownMin = 0.08, AFCooldownMax = 0.15, AFMinDot = 0.85,
    WeightDistance = 10.0, WeightAngle = 0.05, SwitchMargin = 15,
}

local AIM_LAST_SWITCH = 0
local AIM_LOCK_START  = 0
local AIM_LAST_SCAN   = 0
local AIM_SCAN_INTERVAL = 0.1
local lockTarget, lockPart = nil, nil
local lastFire = 0

local function TryAutoFire()
    if not lockTarget or not lockPart then return end
    if not ACONFIG.AutoFire then return end
    local now = tick()
    if now - lastFire < ACONFIG.AFCooldownMin + math.random() * (ACONFIG.AFCooldownMax - ACONFIG.AFCooldownMin) then return end
    local cam = Camera.CFrame
    local to = lockPart.Position - cam.Position
    if to.Magnitude < 0.01 then return end
    if cam.LookVector:Dot(to.Unit) < ACONFIG.AFMinDot then return end
    local myChar = player.Character
    local tool = myChar and myChar:FindFirstChildOfClass("Tool")
    if not tool then return end
    pcall(function() tool:Activate() end)
    lastFire = now
end

local function IsEnemy(plr)
    if plr == player then return false end
    if ACONFIG.TeamCheck then
        local m, h = GetTeamKey(player), GetTeamKey(plr)
        if m and h then return m ~= h end
        return false
    end
    return true
end

local function GetPlayerPart(plr)
    if not plr or not IsEnemy(plr) then return nil end
    local char = plr.Character
    if not char or not char.Parent then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not IsAliveHumanoid(hum) then return nil end
    local part = char:FindFirstChild("Head")
    if part then return part end
    for _, n in ipairs({"UpperTorso","Torso","HumanoidRootPart","LowerTorso"}) do
        local p = char:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return char.PrimaryPart
end

local function FindBestTarget()
    local mp, ml = Camera.CFrame.Position, Camera.CFrame.LookVector
    local best, bestPart, bestScore, bestDist = nil, nil, math.huge, nil
    for _, plr in ipairs(Players:GetPlayers()) do
        local part = GetPlayerPart(plr)
        if part then
            local to = part.Position - mp
            local d = to.Magnitude
            if d <= ACONFIG.MaxDistance then
                local ang = AngleBetween(ml, to)
                if ang <= ACONFIG.FOV then
                    local score = d * ACONFIG.WeightDistance + ang * ACONFIG.WeightAngle
                    if score < bestScore then
                        bestScore, best, bestPart, bestDist = score, plr, part, d
                    end
                end
            end
        end
    end
    return best, bestPart, bestScore, bestDist
end

local function GetDistToTarget()
    if not lockPart then return nil end
    return (lockPart.Position - Camera.CFrame.Position).Magnitude
end

local function IsLockValid()
    if not lockTarget or not lockPart then return false end
    if not lockPart.Parent then return false end
    if not IsEnemy(lockTarget) then return false end
    local char = lockTarget.Character
    if not char or not char.Parent then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not lockPart:IsDescendantOf(char) then return false end
    return true
end

local function UpdateLock()
    local myChar = player.Character
    if not myChar then lockTarget, lockPart = nil, nil; return end
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if not IsAliveHumanoid(myHum) then lockTarget, lockPart = nil, nil; return end
    if not ACONFIG.EnabledPlayers then lockTarget, lockPart = nil, nil; return end
    if lockTarget and not IsLockValid() then lockTarget, lockPart = nil, nil end

    local now = tick()
    local needScan = (not lockTarget) or (now - AIM_LAST_SCAN >= AIM_SCAN_INTERVAL)

    if needScan then
        AIM_LAST_SCAN = now
        local best, bestPart, _, bestDist = FindBestTarget()
        if best and bestPart then
            local shouldSwitch = false
            if not lockTarget then shouldSwitch = true
            elseif best ~= lockTarget then
                local curDist = GetDistToTarget()
                if not curDist then shouldSwitch = true
                elseif bestDist then
                    if (curDist - bestDist) >= math.max(ACONFIG.SwitchMargin or 0, 5) then
                        shouldSwitch = true
                    end
                end
            else lockPart = bestPart end
            if shouldSwitch then
                lockTarget, lockPart = best, bestPart
                AIM_LAST_SWITCH = now; AIM_LOCK_START = now
            end
        elseif not lockTarget then lockTarget, lockPart = nil, nil end
    end

    if lockTarget and lockPart then
        local mp = Camera.CFrame.Position
        local aimPos = lockPart.Position
        if ACONFIG.Prediction then
            local vel = lockPart.AssemblyLinearVelocity
            local dist = (aimPos - mp).Magnitude
            local tPredict = math.clamp(dist / math.max(ACONFIG.PredictionSpeed, 1), 0, 0.5)
            aimPos = aimPos + vel * tPredict
        end
        local des = CFrame.lookAt(mp, aimPos)
        if ACONFIG.Smoothness <= 0 then Camera.CFrame = des
        else Camera.CFrame = Camera.CFrame:Lerp(des, 1 - ACONFIG.Smoothness) end
        TryAutoFire()
    end
end

local okBind = pcall(function()
    RunService:BindToRenderStep("AimUnified", Enum.RenderPriority.Last.Value, UpdateLock)
end)
if not okBind then RunService.RenderStepped:Connect(UpdateLock) end

local function MaybeClearLock()
    if not ACONFIG.EnabledPlayers then
        lockTarget, lockPart = nil, nil
        AIM_LAST_SWITCH = 0; AIM_LOCK_START = 0; AIM_LAST_SCAN = 0
    end
end

-- SPEED / JUMP / FOV
local ConfigState = {
    SpeedEnabled = false, SpeedValue = 16,
    JumpEnabled = false, JumpValue = 50,
    FOVEnabled = false, FOVValue = 70,
}

local function GetHumanoid()
    local c = player.Character
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return nil end
    return h
end

local SPEED_ORIG   = setmetatable({}, { __mode = "k" })
local SPEED_HUM    = nil
local SPEED_CONNS  = {}
local SP_HEART_ACC = 0

local function spSafeSet(hum, prop, value)
    if not hum or not hum.Parent then return end
    pcall(function() hum[prop] = value end)
end

local function spSaveOrig(hum)
    if not hum or SPEED_ORIG[hum] then return end
    SPEED_ORIG[hum] = {
        WalkSpeed = hum.WalkSpeed, JumpPower = hum.JumpPower,
        JumpHeight = hum.JumpHeight, UseJumpPower = hum.UseJumpPower,
    }
end

local function spApply(hum, which)
    if not hum or hum.Health <= 0 or not hum.Parent then return end
    which = which or "all"
    if (which == "walk" or which == "all") and ConfigState.SpeedEnabled then
        if hum.WalkSpeed ~= ConfigState.SpeedValue then
            spSafeSet(hum, "WalkSpeed", ConfigState.SpeedValue)
        end
    end
    if (which == "jump" or which == "all") and ConfigState.JumpEnabled then
        if hum.UseJumpPower then
            if hum.JumpPower ~= ConfigState.JumpValue then
                spSafeSet(hum, "JumpPower", ConfigState.JumpValue)
            end
        else
            local target = ConfigState.JumpValue / 5
            if hum.JumpHeight ~= target then
                spSafeSet(hum, "JumpHeight", target)
            end
        end
    end
end

local function spRestore(hum, which)
    if not hum or not hum.Parent then return end
    which = which or "all"
    local o = SPEED_ORIG[hum]
    if which == "walk" or which == "all" then
        if o then spSafeSet(hum, "WalkSpeed", o.WalkSpeed)
        else spSafeSet(hum, "WalkSpeed", 16) end
    end
    if which == "jump" or which == "all" then
        if o then
            spSafeSet(hum, "JumpPower", o.JumpPower)
            spSafeSet(hum, "JumpHeight", o.JumpHeight)
            spSafeSet(hum, "UseJumpPower", o.UseJumpPower)
        else
            spSafeSet(hum, "JumpPower", 50)
            spSafeSet(hum, "JumpHeight", 7.2)
        end
    end
end

local function spUnhook()
    for _, c in ipairs(SPEED_CONNS) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    SPEED_CONNS = {}; SPEED_HUM = nil; SP_HEART_ACC = 0
end

local function spHook(hum)
    spUnhook()
    if not hum or hum.Health <= 0 then return end
    SPEED_HUM = hum
    spSaveOrig(hum)
    local function guard(prop, which)
        table.insert(SPEED_CONNS, hum:GetPropertyChangedSignal(prop):Connect(function()
            if not (ConfigState.SpeedEnabled or ConfigState.JumpEnabled) then return end
            spApply(hum, which)
        end))
    end
    guard("WalkSpeed", "walk"); guard("JumpPower", "jump")
    guard("JumpHeight", "jump"); guard("UseJumpPower", "jump")
    table.insert(SPEED_CONNS, hum.StateChanged:Connect(function()
        if not (ConfigState.SpeedEnabled or ConfigState.JumpEnabled) then return end
        spApply(hum, "all")
    end))
    table.insert(SPEED_CONNS, hum.Died:Connect(function() SPEED_ORIG[hum] = nil end))
    table.insert(SPEED_CONNS, hum.AncestryChanged:Connect(function()
        if not hum.Parent then spUnhook() end
    end))
    if ConfigState.SpeedEnabled or ConfigState.JumpEnabled then spApply(hum, "all") end
end

RunService.PreSimulation:Connect(function()
    if not (ConfigState.SpeedEnabled or ConfigState.JumpEnabled) then return end
    local h = SPEED_HUM
    if not h or not h.Parent or h.Health <= 0 then
        local cur = GetHumanoid()
        if cur and cur ~= h then spHook(cur) end
        return
    end
    spApply(h, "all")
end)

RunService.Heartbeat:Connect(function(dt)
    if not (ConfigState.SpeedEnabled or ConfigState.JumpEnabled) then return end
    SP_HEART_ACC += dt
    if SP_HEART_ACC < 0.1 then return end
    SP_HEART_ACC = 0
    local h = SPEED_HUM
    if not h or not h.Parent or h.Health <= 0 then
        local cur = GetHumanoid()
        if cur then spHook(cur) end
        return
    end
    spApply(h, "all")
end)

RunService.RenderStepped:Connect(function()
    if not Camera then return end
    if ConfigState.FOVEnabled and Camera.FieldOfView ~= ConfigState.FOVValue then
        Camera.FieldOfView = ConfigState.FOVValue
    end
end)

-- NOCLIP
local NoclipEnabled = false
local NOC_ORIG       = setmetatable({}, { __mode = "k" })
local NOC_PART_CONNS = {}
local NOC_CHAR_CONNS = {}
local NOC_CHAR       = nil
local NOC_TICK_ACC   = 0

local function noclipDefault(part)
    if part and part.Name == "HumanoidRootPart" then return true end
    return false
end
local function ncSafe(part, value)
    if not part or not part.Parent then return false end
    return pcall(function() part.CanCollide = value end)
end
local function ncApply(part)
    if not part or not part:IsA("BasePart") or not part.Parent then return end
    if NoclipEnabled and part.CanCollide then
        if NOC_ORIG[part] == nil then NOC_ORIG[part] = part.CanCollide end
        ncSafe(part, false)
    end
end
local function ncUnwatch(part)
    if not part then return end
    local c = NOC_PART_CONNS[part]
    if c then c:Disconnect(); NOC_PART_CONNS[part] = nil end
    NOC_ORIG[part] = nil
end
local function ncWatch(part)
    if not part or not part:IsA("BasePart") then return end
    if NOC_ORIG[part] == nil then NOC_ORIG[part] = part.CanCollide end
    ncApply(part)
    if NOC_PART_CONNS[part] then NOC_PART_CONNS[part]:Disconnect() end
    NOC_PART_CONNS[part] = part:GetPropertyChangedSignal("CanCollide"):Connect(function()
        ncApply(part)
    end)
end
local function ncUnhook()
    for _, c in ipairs(NOC_CHAR_CONNS) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    NOC_CHAR_CONNS = {}
    for _, c in pairs(NOC_PART_CONNS) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    NOC_PART_CONNS = {}
    NOC_ORIG = setmetatable({}, { __mode = "k" })
    NOC_CHAR = nil; NOC_TICK_ACC = 0
end
local function ncWatchChar(char)
    ncUnhook()
    if not char then return end
    NOC_CHAR = char
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then ncWatch(d) end
    end
    table.insert(NOC_CHAR_CONNS, char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then task.defer(function() ncWatch(d) end) end
    end))
    table.insert(NOC_CHAR_CONNS, char.DescendantRemoving:Connect(function(d)
        if d:IsA("BasePart") then ncUnwatch(d) end
    end))
    if NoclipEnabled then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then ncApply(d) end
        end
    end
end
local function ncRestoreChar(char)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            local orig = NOC_ORIG[d]
            local target = (orig ~= nil) and orig or noclipDefault(d)
            ncSafe(d, target)
        end
    end
end
local function NoclipStart()
    NoclipEnabled = true
    local char = player.Character
    if not char then return end
    if NOC_CHAR ~= char then ncWatchChar(char) end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then ncApply(d) end
    end
end
local function NoclipStop()
    NoclipEnabled = false
    local char = player.Character
    if char then ncRestoreChar(char) end
end

RunService.PreSimulation:Connect(function()
    if not NoclipEnabled then return end
    local char = NOC_CHAR
    if not char or char ~= player.Character or not char.Parent then
        local cur = player.Character
        if cur then ncWatchChar(cur) end
        return
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d.CanCollide then ncApply(d) end
    end
end)

RunService.Stepped:Connect(function(_, dt)
    if not NoclipEnabled then return end
    NOC_TICK_ACC += dt
    if NOC_TICK_ACC < 0.05 then return end
    NOC_TICK_ACC = 0
    local char = NOC_CHAR or player.Character
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d.CanCollide then ncApply(d) end
    end
end)

-- VOO
local FlyEnabled    = false
local FlySpeed      = 60
local FlyConnection = nil
local BodyVelocity  = nil
local BodyForce     = nil

local function GetRootPart()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function RemoveFlyParts()
    if BodyVelocity then pcall(function() BodyVelocity:Destroy() end) BodyVelocity = nil end
    if BodyForce then pcall(function() BodyForce:Destroy() end) BodyForce = nil end
end

local function StartFly()
    if FlyEnabled then return end
    FlyEnabled = true
    if FlyConnection then FlyConnection:Disconnect() end
    FlyConnection = RunService.RenderStepped:Connect(function()
        if not FlyEnabled then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root2 = GetRootPart()
        if not hum or not root2 then return end
        if not BodyVelocity or not BodyVelocity.Parent then
            RemoveFlyParts()
            BodyVelocity = Instance.new("BodyVelocity")
            BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            BodyVelocity.P = 1250
            BodyVelocity.Velocity = Vector3.new(0, 0, 0)
            BodyVelocity.Parent = root2
        end
        if not BodyForce or not BodyForce.Parent then
            BodyForce = Instance.new("BodyForce")
            BodyForce.Force = Vector3.new(0, 0, 0)
            BodyForce.Parent = root2
        end
        BodyForce.Force = Vector3.new(0, root2.AssemblyMass * workspace.Gravity, 0)
        local mDir = hum.MoveDirection
        local vel = Vector3.new(0, 0, 0)
        if mDir.Magnitude > 0 then
            local cf = Camera.CFrame
            local lf = cf.LookVector
            local rh = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
            local fh = Vector3.new(lf.X, 0, lf.Z)
            if fh.Magnitude > 0.001 then fh = fh.Unit else fh = Vector3.new(0, 0, -1) end
            if rh.Magnitude > 0.001 then rh = rh.Unit else rh = Vector3.new(1, 0, 0) end
            vel = (lf * mDir:Dot(fh) + rh * mDir:Dot(rh)) * FlySpeed
        end
        BodyVelocity.Velocity = BodyVelocity.Velocity:Lerp(vel, 0.15)
    end)
end

local function StopFly()
    if not FlyEnabled then return end
    FlyEnabled = false
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    RemoveFlyParts()
end

-- TP
local TPPoints = {}

local function TeleportTo(pos)
    local c = player.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not r then return false end
    pcall(function()
        r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        r.Velocity = Vector3.new(0, 0, 0)
    end)
    return true
end

local function TPToPlayer(plr)
    if not plr or plr == player then return false end
    local char = plr.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local offset = hrp.CFrame.LookVector * -3
    return TeleportTo(hrp.Position + offset)
end

-- ═══════════════════════════════════════════════════════════
--  ❤️ HEALTH REGEN v5.3 — 5 camadas + burst + detecção precisa
-- ═══════════════════════════════════════════════════════════
local HEALTH = {
    Enabled = false,
    TargetPct = 100,
    Speed = 50,

    Hum = nil,
    Conns = {},
    ExpectingHealth = nil,
    ServerFightCount = 0,
    BurstUntil = 0,
    HeartAcc = 0,
}

local function healthSafeSet(hum, value)
    if not hum or not hum.Parent then return false end
    local max = hum.MaxHealth
    if max and max > 0 then
        value = math.clamp(value, 0, max)
    end
    HEALTH.ExpectingHealth = value
    local ok = pcall(function() hum.Health = value end)
    if not ok then HEALTH.ExpectingHealth = nil end
    return ok
end

local function healthTarget(hum)
    if not hum then return 0 end
    local max = hum.MaxHealth
    if not max or max <= 0 then return 100 end
    return math.clamp(max * (HEALTH.TargetPct / 100), 0, max)
end

local function healthTick(hum, amount)
    if not hum or hum.Health <= 0 or not hum.Parent then return end
    local target = healthTarget(hum)
    if hum.Health >= target then return end
    if amount <= 0 then return end
    healthSafeSet(hum, math.min(hum.Health + amount, target))
end

local function healthUnhook()
    for _, c in ipairs(HEALTH.Conns) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    HEALTH.Conns = {}
    HEALTH.Hum = nil
    HEALTH.HeartAcc = 0
end

local function healthHook(hum)
    healthUnhook()
    if not hum or hum.Health <= 0 then return end
    HEALTH.Hum = hum

    -- L5: PropertyChanged preciso
    table.insert(HEALTH.Conns, hum:GetPropertyChangedSignal("Health"):Connect(function()
        if not HEALTH.Enabled then return end
        if hum.Health <= 0 then return end

        -- Foi escrita nossa ou do servidor?
        if HEALTH.ExpectingHealth ~= nil and math.abs(hum.Health - HEALTH.ExpectingHealth) < 0.01 then
            HEALTH.ExpectingHealth = nil
            return
        end

        -- Servidor sobrescreveu
        HEALTH.ServerFightCount += 1
        HEALTH.BurstUntil = math.max(HEALTH.BurstUntil, tick() + 1.0)

        task.defer(function()
            if not HEALTH.Enabled or not hum.Parent or hum.Health <= 0 then return end
            local t = healthTarget(hum)
            if hum.Health < t then
                local burst = math.min(HEALTH.Speed * 0.15, t - hum.Health)
                healthSafeSet(hum, math.min(hum.Health + burst, t))
            end
        end)
    end))

    table.insert(HEALTH.Conns, hum.AncestryChanged:Connect(function()
        if not hum.Parent then healthUnhook() end
    end))
end

-- Diagnóstico: network ownership
task.spawn(function()
    task.wait(2)
    local hum = GetHumanoid()
    if not hum then return end
    local hrp = hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local ok, owner = pcall(function() return hrp:GetNetworkOwner() end)
    if ok and owner and owner ~= player then
        warn("[HEALTH] Sem network ownership — regen pode não funcionar!")
    end
end)

-- L1: PreSimulation
RunService.PreSimulation:Connect(function(dt)
    if not HEALTH.Enabled then return end
    local hum = GetHumanoid()
    if not hum then
        if HEALTH.Hum then healthUnhook() end
        return
    end
    if HEALTH.Hum ~= hum then healthHook(hum) end
    local multi = (tick() < HEALTH.BurstUntil) and 3 or 1
    healthTick(hum, HEALTH.Speed * dt * multi)
end)

-- L2: PostSimulation
RunService.PostSimulation:Connect(function(dt)
    if not HEALTH.Enabled then return end
    local hum = HEALTH.Hum
    if not hum or not hum.Parent or hum.Health <= 0 then return end
    local target = healthTarget(hum)
    if hum.Health < target then
        local multi = (tick() < HEALTH.BurstUntil) and 2 or 0.5
        healthTick(hum, HEALTH.Speed * dt * multi)
    end
end)

-- L3: PreRender
RunService.PreRender:Connect(function(dt)
    if not HEALTH.Enabled then return end
    local hum = HEALTH.Hum
    if not hum or not hum.Parent or hum.Health <= 0 then return end
    local target = healthTarget(hum)
    if hum.Health < target and (tick() < HEALTH.BurstUntil) then
        healthTick(hum, HEALTH.Speed * dt * 0.5)
    end
end)

-- L4: Heartbeat
RunService.Heartbeat:Connect(function(dt)
    if not HEALTH.Enabled then return end
    HEALTH.HeartAcc += dt
    if HEALTH.HeartAcc < 0.1 then return end
    local step = HEALTH.HeartAcc
    HEALTH.HeartAcc = 0
    local hum = HEALTH.Hum or GetHumanoid()
    if not hum or hum.Health <= 0 or not hum.Parent then return end
    local multi = (tick() < HEALTH.BurstUntil) and 2 or 1
    healthTick(hum, HEALTH.Speed * step * multi)
end)

-- ESP
local ESP_CONFIG = {
    Enabled = true, Skeleton = true, Box = false, Distance = true, Name = true,
    TeamCheck = true, Color = Color3.fromRGB(255, 255, 255),
    MaxDistance = 1500, TextSize = 12, Thickness = 1,
}

local SKELETON_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local SKELETON_R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local ESP_DRAWS = {}
local ESP_MAX_LINES = 20

local ESPRemoveDraw
ESPRemoveDraw = function(plr)
    local d = ESP_DRAWS[plr]
    if d then
        for _, f in ipairs(d.skeleton) do pcall(function() f:Destroy() end) end
        for _, f in ipairs(d.box) do pcall(function() f:Destroy() end) end
        if d.name then pcall(function() d.name:Destroy() end) end
        if d.dist then pcall(function() d.dist:Destroy() end) end
        ESP_DRAWS[plr] = nil
    end
end

local function ESPIsEnemy(plr)
    if plr == player then return false end
    local char = plr.Character
    if not char or not char.Parent then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not ESP_CONFIG.TeamCheck then return true end
    local m, h = GetTeamKey(player), GetTeamKey(plr)
    if m and h then return m ~= h end
    return false
end

local function W2S(worldPos)
    local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
end

local function ESPCreateDraw(plr, char)
    ESPRemoveDraw(plr)
    local draw = { char = char, plr = plr, skeleton = {}, box = {}, name = nil, dist = nil }
    for i = 1, ESP_MAX_LINES do
        draw.skeleton[i] = make("Frame", {
            BackgroundColor3 = ESP_CONFIG.Color, BorderSizePixel = 0,
            Visible = false, ZIndex = 20, AnchorPoint = Vector2.new(0.5, 0.5),
        }, gui)
    end
    for i = 1, 4 do
        draw.box[i] = make("Frame", {
            BackgroundColor3 = ESP_CONFIG.Color, BorderSizePixel = 0,
            Visible = false, ZIndex = 19, AnchorPoint = Vector2.new(0.5, 0.5),
        }, gui)
    end
    draw.name = make("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = ESP_CONFIG.Color,
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0, 0, 0),
        Font = Enum.Font.GothamBold, TextSize = ESP_CONFIG.TextSize,
        TextXAlignment = Enum.TextXAlignment.Center, Visible = false,
        ZIndex = 21, Size = UDim2.fromOffset(200, 16), AnchorPoint = Vector2.new(0.5, 1),
    }, gui)
    draw.dist = make("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = ESP_CONFIG.Color,
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0, 0, 0),
        Font = Enum.Font.GothamBold, TextSize = ESP_CONFIG.TextSize,
        TextXAlignment = Enum.TextXAlignment.Center, Visible = false,
        ZIndex = 21, Size = UDim2.fromOffset(200, 16), AnchorPoint = Vector2.new(0.5, 0),
    }, gui)
    ESP_DRAWS[plr] = draw
end

local function ESPHideAll(draw)
    for _, f in ipairs(draw.skeleton) do f.Visible = false end
    for _, f in ipairs(draw.box) do f.Visible = false end
    if draw.name then draw.name.Visible = false end
    if draw.dist then draw.dist.Visible = false end
end

local function DrawLine2D(frame, p1, p2, color, thickness)
    local diff = p2 - p1
    local length = diff.Magnitude
    if length < 1 or length > 4000 then frame.Visible = false; return end
    local center = (p1 + p2) * 0.5
    frame.Visible = true
    frame.Position = UDim2.fromOffset(center.X, center.Y)
    frame.Size = UDim2.fromOffset(length, thickness or 1)
    frame.Rotation = math.deg(math.atan(diff.Y, diff.X))
    frame.BackgroundColor3 = color
end

local function ESPUpdateDraw(draw)
    local plr = draw.plr
    local char = plr.Character
    if not char or char ~= draw.char or not ESPIsEnemy(plr) then ESPHideAll(draw); return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then ESPHideAll(draw); return end
    local camPos = Camera.CFrame.Position
    local dist = (hrp.Position - camPos).Magnitude
    if dist > ESP_CONFIG.MaxDistance then ESPHideAll(draw); return end
    local toChar = hrp.Position - camPos
    if toChar.Magnitude > 0.01 and toChar.Unit:Dot(Camera.CFrame.LookVector) < -0.1 then ESPHideAll(draw); return end

    local color = ESP_CONFIG.Color
    local thickness = ESP_CONFIG.Thickness

    if ESP_CONFIG.Skeleton then
        local bones = char:FindFirstChild("UpperTorso") and SKELETON_R15 or SKELETON_R6
        local lineIdx = 0
        for _, pair in ipairs(bones) do
            local p1 = char:FindFirstChild(pair[1])
            local p2 = char:FindFirstChild(pair[2])
            if p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart") then
                local sp1, on1 = W2S(p1.Position)
                local sp2, on2 = W2S(p2.Position)
                if on1 and on2 then
                    lineIdx = lineIdx + 1
                    if draw.skeleton[lineIdx] then DrawLine2D(draw.skeleton[lineIdx], sp1, sp2, color, thickness) end
                end
            end
        end
        for i = lineIdx + 1, #draw.skeleton do draw.skeleton[i].Visible = false end
    else
        for _, f in ipairs(draw.skeleton) do f.Visible = false end
    end

    if ESP_CONFIG.Box then
        draw._boxAcc = (draw._boxAcc or 0) - (draw._lastDt or 0.016)
        if draw._boxAcc <= 0 then
            draw._boxAcc = 0.1
            local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
            if ok and cf then
                local corners = {}
                for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
                    table.insert(corners, cf:PointToWorldSpace(Vector3.new(size.X * x / 2, size.Y * y / 2, size.Z * z / 2)))
                end end end
                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                local anyOnScreen = false
                for _, wp in ipairs(corners) do
                    local sp, on = W2S(wp)
                    if on then
                        anyOnScreen = true
                        minX = math.min(minX, sp.X); minY = math.min(minY, sp.Y)
                        maxX = math.max(maxX, sp.X); maxY = math.max(maxY, sp.Y)
                    end
                end
                draw._boxCache = anyOnScreen and {minX, minY, maxX, maxY} or false
            else draw._boxCache = false end
        end
        local bb = draw._boxCache
        if bb then
            local tl = Vector2.new(bb[1], bb[2]); local tr = Vector2.new(bb[3], bb[2])
            local br = Vector2.new(bb[3], bb[4]); local bl = Vector2.new(bb[1], bb[4])
            DrawLine2D(draw.box[1], tl, tr, color, 2); DrawLine2D(draw.box[2], tr, br, color, 2)
            DrawLine2D(draw.box[3], br, bl, color, 2); DrawLine2D(draw.box[4], bl, tl, color, 2)
        else for _, f in ipairs(draw.box) do f.Visible = false end end
    else for _, f in ipairs(draw.box) do f.Visible = false end end

    if ESP_CONFIG.Name then
        local head = char:FindFirstChild("Head") or hrp
        local sp, on = W2S(head.Position + Vector3.new(0, 1.2, 0))
        if on then
            draw.name.Visible = true; draw.name.Text = plr.Name
            draw.name.TextColor3 = color; draw.name.Position = UDim2.fromOffset(sp.X, sp.Y)
        else draw.name.Visible = false end
    else draw.name.Visible = false end

    if ESP_CONFIG.Distance then
        local head = char:FindFirstChild("Head") or hrp
        local sp, on = W2S(head.Position + Vector3.new(0, -0.8, 0))
        if on then
            draw.dist.Visible = true
            draw.dist.Text = "[" .. math.floor(dist) .. "m]"
            draw.dist.TextColor3 = color; draw.dist.Position = UDim2.fromOffset(sp.X, sp.Y)
        else draw.dist.Visible = false end
    else draw.dist.Visible = false end
end

RunService.RenderStepped:Connect(function(dt)
    if not ESP_CONFIG.Enabled then
        for _, d in pairs(ESP_DRAWS) do ESPHideAll(d) end
        return
    end
    for _, d in pairs(ESP_DRAWS) do
        d._lastDt = dt
        ESPUpdateDraw(d)
    end
end)

local function ESPRefresh()
    if not ESP_CONFIG.Enabled then
        for plr, _ in pairs(ESP_DRAWS) do ESPRemoveDraw(plr) end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if ESPIsEnemy(plr) and plr.Character then
                local d = ESP_DRAWS[plr]
                if not d or d.char ~= plr.Character then ESPCreateDraw(plr, plr.Character) end
            else
                if ESP_DRAWS[plr] then ESPRemoveDraw(plr) end
            end
        end
    end
end

task.spawn(function()
    while true do ESPRefresh(); task.wait(0.3) end
end)

local function ESPApplyColor(newColor)
    ESP_CONFIG.Color = newColor
    for _, d in pairs(ESP_DRAWS) do
        for _, f in ipairs(d.skeleton) do f.BackgroundColor3 = newColor end
        for _, f in ipairs(d.box) do f.BackgroundColor3 = newColor end
        if d.name then d.name.TextColor3 = newColor end
        if d.dist then d.dist.TextColor3 = newColor end
    end
end

local function ESPClearAll()
    for plr, _ in pairs(ESP_DRAWS) do ESPRemoveDraw(plr) end
end

local function ESPUpdateTeamCheck()
    for plr, _ in pairs(ESP_DRAWS) do
        if not ESPIsEnemy(plr) then ESPRemoveDraw(plr) end
    end
    ESPRefresh()
end

-- ABA AIM
local aimTab = newTab("Aim", "🎯", 1)
text(aimTab, "Aimbot Players (mais próximo)", 20, THEME.Text, Enum.Font.GothamBold)
text(aimTab, "Trava no mais perto. Solta na hora se o alvo morrer.", 12, THEME.SubText)

addToggle(aimTab, "🎯 Ativar Aim 100% em Players", false, function(v)
    ACONFIG.EnabledPlayers = v; MaybeClearLock()
    notify(v and "🎯 Aim ON" or "Aim OFF")
end)
addToggle(aimTab, "🛡️ Team Check", true, function(v) ACONFIG.TeamCheck = v end)
addToggle(aimTab, "🎯 Predição", false, function(v) ACONFIG.Prediction = v end)
addToggle(aimTab, "🔥 Auto Fire", false, function(v) ACONFIG.AutoFire = v end)
addToggle(aimTab, "🎯 Ignorar ângulo (pega atrás)", true, function(v)
    ACONFIG.WeightAngle = v and 0.05 or 1.0
    notify(v and "🎯 Pega em qualquer direção" or "🎯 Só na mira")
end)

addSlider(aimTab, "FOV (graus)", 5, 360, 360, function(v) ACONFIG.FOV = v end)
addSlider(aimTab, "Distância máx", 20, 8000, 5000, function(v) ACONFIG.MaxDistance = v end)
addSlider(aimTab, "Velocidade da bala", 50, 3000, 400, function(v) ACONFIG.PredictionSpeed = v end)
addSlider(aimTab, "Suavidade (0 = colado)", 0, 1, 0, function(v) ACONFIG.Smoothness = v end, 2)
addSlider(aimTab, "Prioridade por distância", 1, 20, 10, function(v) ACONFIG.WeightDistance = v end)
addSlider(aimTab, "Tolerância de troca (studs)", 5, 100, 15, function(v) ACONFIG.SwitchMargin = v end)

addButton(aimTab, "🔄 Recontar alvos agora", true, function()
    lockTarget, lockPart = nil, nil
    AIM_LAST_SWITCH = 0; AIM_LOCK_START = 0; AIM_LAST_SCAN = 0
    notify("🔄 Vai escolher o mais próximo no próximo frame")
end)

-- ABA SPEED
local spdTab = newTab("Speed", "⚡", 2)
text(spdTab, "Speed / Pulo / FOV", 20, THEME.Text, Enum.Font.GothamBold)
text(spdTab, "Robusto: resiste a resets do servidor.", 12, THEME.SubText)

addToggle(spdTab, "⚡ Ativar Speed", false, function(v)
    ConfigState.SpeedEnabled = v
    local hum = GetHumanoid()
    if v then
        if hum then
            spSaveOrig(hum)
            if SPEED_HUM ~= hum then spHook(hum) end
            spApply(hum, "walk")
        end
    else
        if hum then spRestore(hum, "walk") end
    end
    notify(v and "⚡ Speed ON" or "Speed OFF")
end)
addSlider(spdTab, "Velocidade (WalkSpeed)", 16, 1000, 16, function(v)
    ConfigState.SpeedValue = v
    if ConfigState.SpeedEnabled then
        local hum = GetHumanoid()
        if hum then spApply(hum, "walk") end
    end
end)
addToggle(spdTab, "🦘 Pulo Alto", false, function(v)
    ConfigState.JumpEnabled = v
    local hum = GetHumanoid()
    if v then
        if hum then
            spSaveOrig(hum)
            if SPEED_HUM ~= hum then spHook(hum) end
            spApply(hum, "jump")
        end
    else
        if hum then spRestore(hum, "jump") end
    end
    notify(v and "🦘 Pulo Alto ON" or "Pulo normal")
end)
addSlider(spdTab, "Força do Pulo", 50, 500, 50, function(v)
    ConfigState.JumpValue = v
    if ConfigState.JumpEnabled then
        local hum = GetHumanoid()
        if hum then spApply(hum, "jump") end
    end
end)
addToggle(spdTab, "📷 FOV", false, function(v)
    ConfigState.FOVEnabled = v
    if Camera then
        if v then Camera.FieldOfView = ConfigState.FOVValue else Camera.FieldOfView = 70 end
    end
end)
addSlider(spdTab, "FOV da câmera", 40, 120, 70, function(v)
    ConfigState.FOVValue = v
    if ConfigState.FOVEnabled and Camera then Camera.FieldOfView = v end
end)

-- ABA NOCLIP
local noclipTab = newTab("Noclip", "🧱", 3)
text(noclipTab, "Noclip", 20, THEME.Text, Enum.Font.GothamBold)
text(noclipTab, "Robusto: guarda valor original de cada parte.", 12, THEME.SubText)
addToggle(noclipTab, "🧱 Ativar Noclip", false, function(v)
    if v then NoclipStart(); notify("🧱 Noclip ON")
    else NoclipStop(); notify("Noclip OFF") end
end)

-- ABA VOO
local vooTab = newTab("Voo", "🚀", 4)
text(vooTab, "Voo Livre", 20, THEME.Text, Enum.Font.GothamBold)
text(vooTab, "Ative e voe usando WASD + câmera.", 12, THEME.SubText)
addToggle(vooTab, "🚀 Ativar Voo", false, function(v)
    if v then StartFly(); notify("🚀 Voo ON")
    else StopFly(); notify("Voo OFF") end
end)
addSlider(vooTab, "Velocidade do Voo", 20, 500, 60, function(v) FlySpeed = v end)

-- ABA TP
local tpTab = newTab("TP", "📍", 5)
text(tpTab, "Teleportes", 20, THEME.Text, Enum.Font.GothamBold)
text(tpTab, "Vá para players ou locais salvos.", 12, THEME.SubText)

text(tpTab, "🌐 JOGADORES NO SERVIDOR", 12, THEME.SubText, Enum.Font.GothamBold)
local playerListHolder = makeListHolder(tpTab, 140)
playerListHolder.ClipsDescendants = true

text(tpTab, "📍 LOCAIS SALVOS", 12, THEME.SubText, Enum.Font.GothamBold)
local rebuildSavedList

addButton(tpTab, "📌 Salvar Posição Atual", true, function()
    local c = player.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local idx = #TPPoints + 1
    table.insert(TPPoints, {
        name = "Ponto " .. idx .. " (" .. math.floor(r.Position.X) .. ", " .. math.floor(r.Position.Z) .. ")",
        pos = r.Position,
    })
    if rebuildSavedList then rebuildSavedList() end
    notify("📍 Ponto " .. idx .. " salvo!")
end)

local savedHeader = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.3,
    Text = "📍 Pontos salvos: 0", TextColor3 = THEME.SubText,
    Font = Enum.Font.GothamBold, TextSize = 11, LayoutOrder = order(),
}, tpTab)
round(savedHeader, 10)

local savedListHolder = makeListHolder(tpTab, 130)
savedListHolder.ClipsDescendants = true

local function rebuildPlayerList()
    for _, ch in ipairs(playerListHolder:GetChildren()) do
        if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
    end
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            count = count + 1
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = THEME.Card, LayoutOrder = count,
            }, playerListHolder)
            round(row, 8)
            stroke(row, THEME.Border, 1, 0.85)
            make("TextLabel", {
                BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -70, 1, 0),
                Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
                TextColor3 = THEME.Text, TextSize = 11, Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)
            local goBtn = make("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(46, 22),
                BackgroundColor3 = THEME.White, Text = "IR",
                TextColor3 = THEME.Black, Font = Enum.Font.GothamBold, TextSize = 11,
                AutoButtonColor = false,
            }, row)
            round(goBtn, 6)
            goBtn.Activated:Connect(function()
                if TPToPlayer(plr) then notify("📍 TP → " .. plr.DisplayName)
                else notify("⚠️ Não foi possível teleportar") end
            end)
        end
    end
    if count == 0 then
        local empty = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
            Text = "Nenhum outro jogador no servidor",
            TextColor3 = THEME.Muted, TextSize = 11, Font = Enum.Font.Gotham,
        }, playerListHolder)
        empty.TextXAlignment = Enum.TextXAlignment.Center
    end
end

function rebuildSavedList()
    for _, ch in ipairs(savedListHolder:GetChildren()) do
        if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
    end
    savedHeader.Text = "📍 Pontos salvos: " .. #TPPoints
    if #TPPoints == 0 then
        local empty = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
            Text = "Nenhum local salvo ainda",
            TextColor3 = THEME.Muted, TextSize = 11, Font = Enum.Font.Gotham,
        }, savedListHolder)
        empty.TextXAlignment = Enum.TextXAlignment.Center
    else
        for i, p in ipairs(TPPoints) do
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = THEME.Card, LayoutOrder = i,
            }, savedListHolder)
            round(row, 8)
            stroke(row, THEME.Border, 1, 0.85)
            make("TextLabel", {
                BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -110, 1, 0), Text = p.name,
                TextColor3 = THEME.Text, TextSize = 11, Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)
            local goBtn = make("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -50, 0.5, 0),
                Size = UDim2.fromOffset(42, 22),
                BackgroundColor3 = THEME.White, Text = "IR",
                TextColor3 = THEME.Black, Font = Enum.Font.GothamBold, TextSize = 11,
                AutoButtonColor = false,
            }, row)
            round(goBtn, 6)
            goBtn.Activated:Connect(function()
                if TeleportTo(p.pos) then notify("📍 TP → " .. p.name)
                else notify("⚠️ Não foi possível teleportar") end
            end)
            local delBtn = make("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(38, 22),
                BackgroundColor3 = THEME.Danger, Text = "✕",
                TextColor3 = THEME.White, Font = Enum.Font.GothamBold, TextSize = 11,
                AutoButtonColor = false,
            }, row)
            round(delBtn, 6)
            delBtn.Activated:Connect(function()
                table.remove(TPPoints, i)
                rebuildSavedList()
                notify("🗑️ Ponto removido")
            end)
        end
    end
end

rebuildPlayerList()
rebuildSavedList()

Players.PlayerAdded:Connect(function() task.wait(0.3); rebuildPlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.3); rebuildPlayerList() end)

-- ABA ESP
local espTab = newTab("ESP", "👁️", 6)
text(espTab, "ESP Melhorado", 20, THEME.Text, Enum.Font.GothamBold)
text(espTab, "Ative só o que quiser ver.", 12, THEME.SubText)

addToggle(espTab, "👁️ Ativar ESP", true, function(v)
    ESP_CONFIG.Enabled = v
    if v then ESPRefresh() else ESPClearAll() end
    notify(v and "👁️ ESP ON" or "ESP OFF")
end)

text(espTab, "🎯 O QUE MOSTRAR", 12, THEME.SubText, Enum.Font.GothamBold)
addToggle(espTab, "🦴 Esqueleto (ossos)", true, function(v) ESP_CONFIG.Skeleton = v end)
addToggle(espTab, "📦 Caixa (box)", false, function(v) ESP_CONFIG.Box = v end)
addToggle(espTab, "📛 Nome", true, function(v) ESP_CONFIG.Name = v end)
addToggle(espTab, "📏 Distância", true, function(v) ESP_CONFIG.Distance = v end)
addToggle(espTab, "🛡️ Só time inimigo", true, function(v)
    ESP_CONFIG.TeamCheck = v; ESPUpdateTeamCheck()
end)

text(espTab, "⚙️ AJUSTES", 12, THEME.SubText, Enum.Font.GothamBold)
addSlider(espTab, "Distância máx (studs)", 50, 5000, 1500, function(v) ESP_CONFIG.MaxDistance = v end)
addSlider(espTab, "Tamanho do texto", 8, 24, 12, function(v)
    ESP_CONFIG.TextSize = v
    for _, d in pairs(ESP_DRAWS) do
        if d.name then d.name.TextSize = v end
        if d.dist then d.dist.TextSize = v end
    end
end)
addSlider(espTab, "Espessura das linhas", 1, 5, 1, function(v) ESP_CONFIG.Thickness = v end)

text(espTab, "🎨 COR DO ESP", 12, THEME.SubText, Enum.Font.GothamBold)
local espColorCard = card(espTab, 130)
make("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, espColorCard)
make("UIGridLayout", { CellSize = UDim2.new(1/4, -6, 0, 44), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, espColorCard)
local espColorStrokes = {}
for i, preset in ipairs(ESP_COLORS) do
    local name, c = preset[1], preset[2]
    local sw = make("Frame", { BackgroundColor3 = c, LayoutOrder = i }, espColorCard)
    round(sw, 10)
    local sst = stroke(sw, THEME.White, 3, 1)
    espColorStrokes[i] = sst
    local btn = make("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = name, TextColor3 = Color3.new(1, 1, 1),
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0, 0, 0),
        TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false,
    }, sw)
    btn.Activated:Connect(function()
        ESPApplyColor(c)
        for j, s in ipairs(espColorStrokes) do
            tween(s, { Transparency = (j == i) and 0 or 1 })
        end
        notify("Cor do ESP: " .. name)
    end)
end
espColorStrokes[1].Transparency = 0

-- ABA CROSSHAIR
local CROSSHAIR = {
    Enabled = false, Shape = "Cross", Size = 10, Thickness = 2, Gap = 4,
    Color = Color3.fromRGB(255, 255, 255), Opacity = 1.0, Outline = true,
}

local crossContainer = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(300, 300), BackgroundTransparency = 1,
    Visible = false, ZIndex = 40,
}, gui)

local function redrawCrosshair()
    for _, child in ipairs(crossContainer:GetChildren()) do child:Destroy() end
    if not CROSSHAIR.Enabled then crossContainer.Visible = false; return end
    crossContainer.Visible = true
    local color = CROSSHAIR.Color
    local transparency = 1 - CROSSHAIR.Opacity
    local size = CROSSHAIR.Size
    local thick = CROSSHAIR.Thickness
    local gap = CROSSHAIR.Gap
    local shape = CROSSHAIR.Shape
    local function makeLine(offsetX, offsetY, w, h, rotation)
        local ln = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, offsetX, 0.5, offsetY),
            Size = UDim2.fromOffset(w, h), BackgroundColor3 = color,
            BackgroundTransparency = transparency, BorderSizePixel = 0, ZIndex = 41,
        }, crossContainer)
        if rotation then ln.Rotation = rotation end
        if CROSSHAIR.Outline then stroke(ln, THEME.Black, 1, 0) end
        return ln
    end
    local halfSize = size / 2
    if shape == "Cross" or shape == "Full" then
        makeLine(0, -(gap + halfSize), thick, size)
        makeLine(0,  (gap + halfSize), thick, size)
        makeLine(-(gap + halfSize), 0, size, thick)
        makeLine( (gap + halfSize), 0, size, thick)
    elseif shape == "T" then
        makeLine(0, (gap + halfSize), thick, size)
        makeLine(-(gap + halfSize), 0, size, thick)
        makeLine( (gap + halfSize), 0, size, thick)
    elseif shape == "X" then
        makeLine(0, 0, thick, size * 2 + gap * 2, 45)
        makeLine(0, 0, thick, size * 2 + gap * 2, -45)
    elseif shape == "Circle" then
        local ring = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset((size + gap) * 2, (size + gap) * 2),
            BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 41,
        }, crossContainer)
        round(ring, (size + gap))
        stroke(ring, color, thick, transparency)
    end
    if shape == "Dot" or shape == "Full" then
        local dotSize = math.max(2, thick)
        local dot = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(dotSize, dotSize),
            BackgroundColor3 = color, BackgroundTransparency = transparency,
            BorderSizePixel = 0, ZIndex = 42,
        }, crossContainer)
        round(dot, dotSize / 2)
        if CROSSHAIR.Outline then stroke(dot, THEME.Black, 1, 0) end
    end
end

local crossTab = newTab("Crosshair", "✚", 7)
text(crossTab, "Crosshair Personalizável", 20, THEME.Text, Enum.Font.GothamBold)
text(crossTab, "Customize formato, tamanho, espessura e cor.", 12, THEME.SubText)
addToggle(crossTab, "✚ Ativar Crosshair", false, function(v)
    CROSSHAIR.Enabled = v
    redrawCrosshair()
    notify(v and "✚ Crosshair ON" or "Crosshair OFF")
end)

text(crossTab, "📐 FORMATO", 12, THEME.SubText, Enum.Font.GothamBold)
addButtonRow(crossTab, {
    { label = "Cross", value = "Cross" }, { label = "T", value = "T" },
    { label = "Dot", value = "Dot" }, { label = "Circle", value = "Circle" },
    { label = "X", value = "X" }, { label = "Full", value = "Full" },
}, CROSSHAIR.Shape, function(value)
    CROSSHAIR.Shape = value; redrawCrosshair()
end)

text(crossTab, "📏 DIMENSÕES", 12, THEME.SubText, Enum.Font.GothamBold)
addSlider(crossTab, "Tamanho", 2, 60, CROSSHAIR.Size, function(v) CROSSHAIR.Size = v; redrawCrosshair() end)
addSlider(crossTab, "Espessura", 1, 8, CROSSHAIR.Thickness, function(v) CROSSHAIR.Thickness = v; redrawCrosshair() end)
addSlider(crossTab, "Gap (distância do centro)", 0, 30, CROSSHAIR.Gap, function(v) CROSSHAIR.Gap = v; redrawCrosshair() end)
addSlider(crossTab, "Opacidade (%)", 10, 100, math.floor(CROSSHAIR.Opacity * 100), function(v) CROSSHAIR.Opacity = v / 100; redrawCrosshair() end)
addToggle(crossTab, "⬛ Contorno preto", CROSSHAIR.Outline, function(v)
    CROSSHAIR.Outline = v; redrawCrosshair()
end)

text(crossTab, "🎨 COR DO CROSSHAIR", 12, THEME.SubText, Enum.Font.GothamBold)
local crossColorCard = card(crossTab, 130)
make("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, crossColorCard)
make("UIGridLayout", { CellSize = UDim2.new(1/4, -6, 0, 44), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, crossColorCard)
local crossColorStrokes = {}
for i, preset in ipairs(CROSS_COLORS) do
    local name, c = preset[1], preset[2]
    local sw = make("Frame", { BackgroundColor3 = c, LayoutOrder = i }, crossColorCard)
    round(sw, 10)
    local sst = stroke(sw, THEME.White, 3, 1)
    crossColorStrokes[i] = sst
    local btn = make("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = name, TextColor3 = Color3.new(1, 1, 1),
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0, 0, 0),
        TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false,
    }, sw)
    btn.Activated:Connect(function()
        CROSSHAIR.Color = c
        for j, s in ipairs(crossColorStrokes) do
            tween(s, { Transparency = (j == i) and 0 or 1 })
        end
        redrawCrosshair()
        notify("Cor do crosshair: " .. name)
    end)
end
crossColorStrokes[1].Transparency = 0

-- ABA VIDA
local healthTab = newTab("Vida", "❤️", 8)
text(healthTab, "Regeneração de Vida", 20, THEME.Text, Enum.Font.GothamBold)
text(healthTab, "5 camadas + burst + detecção precisa.", 12, THEME.SubText)

addToggle(healthTab, "❤️ Ativar Regen", false, function(v)
    HEALTH.Enabled = v
    HEALTH.HeartAcc = 0
    if not v then HEALTH.ServerFightCount = 0 end
    notify(v and "❤️ Regen ON" or "Regen OFF")
end)

text(healthTab, "⚙️ AJUSTES", 12, THEME.SubText, Enum.Font.GothamBold)
addSlider(healthTab, "Alvo (% do HP máximo)", 10, 100, 100, function(v)
    HEALTH.TargetPct = v
end)
addSlider(healthTab, "Velocidade (HP/seg)", 1, 500, 50, function(v)
    HEALTH.Speed = v
end)

addButton(healthTab, "⚡ Cura Instantânea", true, function()
    local hum = GetHumanoid()
    if not hum then notify("⚠️ Sem Humanoid"); return end
    pcall(function() hum.Health = hum.MaxHealth end)
    notify("⚡ Vida restaurada ao máximo")
end)

selectTab("Aim")

-- MOUSE LIVRE
local isOpen, busy = false, false
local savedMouseBehavior = nil
local savedMouseIcon = nil
local mouseStateCaptured = false
local mouseFreeConn = nil

local function startMouseFree()
    if mouseFreeConn then return end
    if not mouseStateCaptured then
        pcall(function()
            savedMouseBehavior = UserInputService.MouseBehavior
            savedMouseIcon = UserInputService.MouseIconEnabled
        end)
        mouseStateCaptured = true
    end
    mouseFreeConn = RunService.RenderStepped:Connect(function()
        pcall(function()
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
            if not UserInputService.MouseIconEnabled then
                UserInputService.MouseIconEnabled = true
            end
        end)
    end)
end

local function stopMouseFree()
    if mouseFreeConn then
        mouseFreeConn:Disconnect()
        mouseFreeConn = nil
    end
    if mouseStateCaptured then
        pcall(function()
            UserInputService.MouseBehavior = savedMouseBehavior or Enum.MouseBehavior.Default
            if savedMouseIcon ~= nil then
                UserInputService.MouseIconEnabled = savedMouseIcon
            end
        end)
        mouseStateCaptured = false
        savedMouseBehavior = nil
        savedMouseIcon = nil
    end
end

-- BOLINHA PREMIUM COM HOVER
local bubble = make("Frame", {
    Name = "Bubble",
    Size = UDim2.fromOffset(BUBBLE, BUBBLE),
    Position = UDim2.fromOffset(16, 180),
    BackgroundColor3 = THEME.Bg2,
    Visible = false,
    ZIndex = 50,
    ClipsDescendants = false,
}, gui)
round(bubble, 14)

make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.Bg2),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 2, 2)),
    }),
    Rotation = 135,
}, bubble)

local bubbleGlow = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 26, 1, 26),
    BackgroundColor3 = THEME.White,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 48,
}, bubble)
round(bubbleGlow, 26)

local bubbleShadow = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 6),
    Size = UDim2.new(1, 8, 1, 8),
    BackgroundColor3 = THEME.Black,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    ZIndex = 47,
}, bubble)
round(bubbleShadow, 18)

local pulseRing = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 46,
}, bubble)
round(pulseRing, 14)
local pulseStroke = stroke(pulseRing, THEME.White, 1, 1)
local pulseScale = make("UIScale", { Scale = 1 }, pulseRing)

local bubbleStroke = stroke(bubble, THEME.Border, 1.5, 0.35)

local innerRing = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, -8, 1, -8),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 51,
}, bubble)
round(innerRing, 11)
local innerRingStroke = stroke(innerRing, THEME.White, 1, 0.88)

make("Frame", {
    Size = UDim2.new(1, -24, 0, 1),
    Position = UDim2.new(0.5, 0, 0, 4),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = THEME.White,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    ZIndex = 52,
}, bubble)

for _, pos in ipairs({
    UDim2.new(0, 7, 0, 7),
    UDim2.new(1, -7, 0, 7),
    UDim2.new(0, 7, 1, -7),
    UDim2.new(1, -7, 1, -7),
}) do
    local dot = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = pos,
        Size = UDim2.fromOffset(3, 3),
        BackgroundColor3 = THEME.White,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        ZIndex = 52,
    }, bubble)
    round(dot, 1.5)
end

local skullGlow = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = THEME.White,
    BackgroundTransparency = 0.93,
    BorderSizePixel = 0,
    ZIndex = 52,
}, bubble)
round(skullGlow, 17)

local skullLabel = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Text = "💀",
    TextColor3 = THEME.White,
    TextSize = 26,
    Font = Enum.Font.GothamBold,
    TextStrokeTransparency = 0.6,
    TextStrokeColor3 = THEME.Black,
    ZIndex = 53,
}, bubble)

local hit = make("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 54,
}, bubble)

local bubbleScale = make("UIScale", { Scale = 0 }, bubble)

local isHovering = false
local isPressing = false

local pulseActive = false
local function startPulse()
    if pulseActive then return end
    pulseActive = true
    task.spawn(function()
        while pulseActive and bubble.Visible do
            pulseScale.Scale = 1
            pulseStroke.Transparency = 0.75
            TweenService:Create(pulseScale, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.7 }):Play()
            TweenService:Create(pulseStroke, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
            task.wait(2.6)
        end
        pulseActive = false
    end)
end
local function stopPulse() pulseActive = false end

hit.MouseEnter:Connect(function()
    isHovering = true
    tween(bubble, { BackgroundColor3 = THEME.Card }, 0.2)
    tween(bubbleStroke, { Transparency = 0.05, Thickness = 2 }, 0.2)
    tween(bubbleGlow, { BackgroundTransparency = 0.82 }, 0.2)
    tween(skullGlow, { BackgroundTransparency = 0.85 }, 0.2)
    tween(skullLabel, { TextSize = 28 }, 0.2, Enum.EasingStyle.Back)
    tween(innerRingStroke, { Transparency = 0.5 }, 0.2)
    if not isPressing then
        tween(bubbleScale, { Scale = 1.08 }, 0.22, Enum.EasingStyle.Back)
    end
end)

hit.MouseLeave:Connect(function()
    isHovering = false
    if isPressing then return end
    tween(bubble, { BackgroundColor3 = THEME.Bg2 }, 0.24)
    tween(bubbleStroke, { Transparency = 0.35, Thickness = 1.5 }, 0.24)
    tween(bubbleGlow, { BackgroundTransparency = 1 }, 0.24)
    tween(skullGlow, { BackgroundTransparency = 0.93 }, 0.24)
    tween(skullLabel, { TextSize = 26 }, 0.24, Enum.EasingStyle.Back)
    tween(innerRingStroke, { Transparency = 0.88 }, 0.24)
    tween(bubbleScale, { Scale = 1 }, 0.24, Enum.EasingStyle.Back)
end)

local function showBubble(show)
    if show then
        bubble.Visible = true
        bubbleScale.Scale = 0
        tween(bubbleScale, { Scale = isHovering and 1.08 or 1 }, 0.5, Enum.EasingStyle.Back)
        startPulse()
    else
        stopPulse()
        tween(bubbleScale, { Scale = 0 }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.22, function() if isOpen then bubble.Visible = false end end)
    end
end

local function openWindow()
    if isOpen or busy then return end
    busy, isOpen = true, true
    showBubble(false)
    root.Visible = true
    anim.Scale = 0.75
    tween(anim, { Scale = 1 }, 0.55, Enum.EasingStyle.Back)
    startMouseFree()
    task.delay(0.55, function() busy = false end)
end

local function minimizeWindow()
    if not isOpen or busy then return end
    busy, isOpen = true, false
    tween(anim, { Scale = 0.6 }, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    task.delay(0.3, function()
        root.Visible = false
        showBubble(true)
        busy = false
        stopMouseFree()
    end)
end

minBtn.Activated:Connect(minimizeWindow)

local function clampPos(x, y)
    local vp = gui.AbsoluteSize
    return UDim2.fromOffset(
        math.clamp(x, 8, math.max(8, vp.X - BUBBLE - 8)),
        math.clamp(y, 30, math.max(30, vp.Y - BUBBLE - 8)))
end
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
    bubble.Position = clampPos(bubble.Position.X.Offset, bubble.Position.Y.Offset)
end)

do
    local function snapToSide()
        local vp = gui.AbsoluteSize
        local x = bubble.Position.X.Offset
        local target = (x + BUBBLE / 2 < vp.X / 2) and 10 or (vp.X - BUBBLE - 10)
        tween(bubble, { Position = UDim2.fromOffset(target, bubble.Position.Y.Offset) }, 0.5, Enum.EasingStyle.Back)
    end
    local moved, startMouse, startPos = false, nil, nil
    local justDragged = false

    hit.InputBegan:Connect(function(input)
        if isPointer(input) then
            isPressing = true
            moved = false; justDragged = false
            startMouse = input.Position; startPos = bubble.Position
            tween(bubbleScale, { Scale = 0.95 }, 0.12)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if isPressing and isMove(input) then
            local d = input.Position - startMouse
            if not moved and d.Magnitude > 8 then moved = true; justDragged = true end
            if moved then
                bubble.Position = clampPos(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
            end
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if not isPressing then return end
        if not isPointer(input) then return end
        isPressing = false
        local targetScale = isHovering and 1.08 or 1
        tween(bubbleScale, { Scale = targetScale }, 0.25, Enum.EasingStyle.Back)
        if moved then
            snapToSide()
            task.delay(0.12, function() justDragged = false end)
        end
    end)
    hit.MouseButton1Click:Connect(function()
        if justDragged then justDragged = false; return end
        openWindow()
    end)
end

connect(UserInputService.InputBegan, function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.RightShift then
        if isOpen then minimizeWindow() else openWindow() end
    end
end)

-- RESPAWN UNIFICADO
player.CharacterAdded:Connect(function(char)
    task.wait(0.15)
    if NoclipEnabled then ncWatchChar(char) end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        spSaveOrig(hum)
        if ConfigState.SpeedEnabled or ConfigState.JumpEnabled then spHook(hum) end
    end
    if ConfigState.FOVEnabled and Camera then
        Camera.FieldOfView = ConfigState.FOVValue
    end
    if FlyEnabled then
        FlyEnabled = false
        if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
        RemoveFlyParts()
        task.wait(0.3)
        StartFly()
    end
    task.wait(0.3)
    stopMouseFree()
    lockTarget, lockPart = nil, nil
    AIM_LAST_SWITCH = 0; AIM_LOCK_START = 0; AIM_LAST_SCAN = 0
    ESPClearAll()
    HEALTH.HeartAcc = 0
    HEALTH.ServerFightCount = 0
    HEALTH.BurstUntil = 0
    HEALTH.ExpectingHealth = nil
    task.wait(0.5)
    ESPRefresh()
    rebuildPlayerList()
end)

ESPRefresh()
showBubble(true)

print("✅ Painel Pro v5.3 — Monochrome Edition")
print("❤️ HEALTH v5.3 — 5 camadas + burst + detecção precisa")
print("✨ Bolinha premium com hover animado + pulse ring")
print("🎯 AIM hard lock + anti-oscilação + predição clampada")
print("⚡ Speed / Pulo independentes + robustos")
print("🧱 Noclip robusto + 🚀 Fly respawn corrigido")
print("🖱️ Mouse livre ao abrir painel")
