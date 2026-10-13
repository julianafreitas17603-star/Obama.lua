-- ==========================================================
--  💀 PAINEL PRO — AIM + ESP + PvP
--  ✅ AIM solta alvo morto IMEDIATAMENTE
--  ✅ Team Check robusto
--  ✅ ESP (esqueleto, nome, distância, box)
--  ✅ PvP Rush (cola no inimigo + auto attack, SÓ em partida)
--  ✨ Bolinha flutuante animada
-- ==========================================================

repeat task.wait(0.1) until game:IsLoaded()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local VirtualUser      = game:GetService("VirtualUser")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Camera    = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════
--  TEMA
-- ═══════════════════════════════════════════════════════════
local THEME = {
    Bg         = Color3.fromRGB(12, 13, 20),
    Bg2        = Color3.fromRGB(20, 22, 34),
    Surface    = Color3.fromRGB(18, 20, 32),
    Card       = Color3.fromRGB(26, 28, 42),
    CardHi     = Color3.fromRGB(34, 37, 54),
    Accent     = Color3.fromRGB(167, 139, 250),
    Accent2    = Color3.fromRGB(125, 211, 252),
    Text       = Color3.fromRGB(241, 245, 249),
    SubText    = Color3.fromRGB(148, 163, 184),
    Muted      = Color3.fromRGB(100, 116, 139),
    Success    = Color3.fromRGB(74, 222, 128),
    Danger     = Color3.fromRGB(248, 113, 113),
    Off        = Color3.fromRGB(51, 65, 85),
    White      = Color3.new(1, 1, 1),
    Black      = Color3.new(0, 0, 0),
}

local ESP_COLORS = {
    { "Vermelho", Color3.fromRGB(255, 30, 30) },
    { "Azul",     Color3.fromRGB(56, 130, 255) },
    { "Verde",    Color3.fromRGB(52, 211, 100) },
    { "Amarelo",  Color3.fromRGB(250, 204, 21) },
    { "Roxo",     Color3.fromRGB(170, 60, 255) },
    { "Ciano",    Color3.fromRGB(34, 211, 238) },
    { "Rosa",     Color3.fromRGB(255, 100, 200) },
    { "Branco",   Color3.fromRGB(255, 255, 255) },
}

local BUBBLE = 64
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
    local tw = TweenService:Create(o, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), p)
    tw:Play(); return tw
end

local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

local function round(o, r)
    return make("UICorner", { CornerRadius = UDim.new(0, r or 12) }, o)
end

local function stroke(o, c, t, tr)
    return make("UIStroke", {
        Color = c or THEME.White,
        Thickness = t or 1,
        Transparency = tr or 0.9,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end

local updaters = {}
local function themed(fn) table.insert(updaters, fn); fn() end
local function accentSeq() return ColorSequence.new(THEME.Accent, THEME.Accent2) end
local function accentGradient(obj, rot)
    local g = make("UIGradient", { Rotation = rot or 0 }, obj)
    themed(function() g.Color = accentSeq() end)
    return g
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

-- ═══════════════════════════════════════════════════════════
--  GUI RAIZ
-- ═══════════════════════════════════════════════════════════
local gui = make("ScreenGui", {
    Name = "PainelPro",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 100,
}, playerGui)

local root = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(540, 440),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 100,
}, gui)

local PanelScaleMult = 1.0
local fit = make("UIScale", {}, root)
local function updateFit()
    local vp = gui.AbsoluteSize
    if vp.X > 0 and vp.Y > 0 then
        local base = math.clamp(math.min(vp.X / 580, vp.Y / 480), 0.5, 1)
        fit.Scale = base * PanelScaleMult
    end
end
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), updateFit)
updateFit()

local win = make("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
}, root)
local anim = make("UIScale", { Scale = 0.7 }, win)

local shadowOuter = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 8),
    Size = UDim2.new(1, 16, 1, 16),
    BackgroundColor3 = THEME.Black,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    ZIndex = -2,
}, win)
round(shadowOuter, 26)

local shadowInner = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 4),
    Size = UDim2.new(1, 6, 1, 6),
    BackgroundColor3 = THEME.Black,
    BackgroundTransparency = 0.7,
    BorderSizePixel = 0,
    ZIndex = -1,
}, win)
round(shadowInner, 22)

local main = make("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = THEME.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 1,
}, win)
round(main, 20)

make("UIGradient", {
    Color = ColorSequence.new(THEME.Bg2, THEME.Bg),
    Rotation = 135,
}, main)

local borderStroke = stroke(main, THEME.Accent, 1.5, 0.4)
local borderGrad = make("UIGradient", {}, borderStroke)
themed(function()
    borderGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.Accent),
        ColorSequenceKeypoint.new(0.5, THEME.Accent2),
        ColorSequenceKeypoint.new(1, THEME.Accent),
    })
end)
TweenService:Create(
    borderGrad,
    TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
    { Rotation = 360 }
):Play()

make("Frame", {
    Size = UDim2.new(1, -40, 0, 1),
    Position = UDim2.new(0.5, 0, 0, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = THEME.White,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    ZIndex = 3,
}, main)

-- ═══════════════════════════════════════════════════════════
--  HEADER
-- ═══════════════════════════════════════════════════════════
local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundTransparency = 1,
    ZIndex = 2,
}, main)

local logo = make("Frame", {
    Position = UDim2.fromOffset(18, 14),
    Size = UDim2.fromOffset(38, 38),
    BackgroundColor3 = THEME.Accent,
    ZIndex = 3,
}, top)
round(logo, 19)
accentGradient(logo, 45)
stroke(logo, THEME.White, 1.5, 0.7)

make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Text = "💀",
    TextColor3 = THEME.White,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    ZIndex = 4,
}, logo)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(68, 14),
    Size = UDim2.new(1, -140, 0, 22),
    Text = "Painel Pro",
    TextColor3 = THEME.Text,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
}, top)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(68, 36),
    Size = UDim2.new(1, -140, 0, 14),
    Text = "AIM · ESP · PvP",
    TextColor3 = THEME.Muted,
    TextSize = 11,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
}, top)

local minBtn = make("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -18, 0.5, 0),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = THEME.Card,
    BackgroundTransparency = 0.2,
    Text = "–",
    TextColor3 = THEME.Text,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 4,
}, top)
round(minBtn, 17)
stroke(minBtn, THEME.White, 1, 0.85)

minBtn.MouseEnter:Connect(function()
    tween(minBtn, { BackgroundColor3 = THEME.Danger, BackgroundTransparency = 0.1 }, 0.2)
end)
minBtn.MouseLeave:Connect(function()
    tween(minBtn, { BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.2 }, 0.2)
end)

make("Frame", {
    Position = UDim2.new(0.5, 0, 0, 64),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(1, -32, 0, 1),
    BackgroundColor3 = THEME.White,
    BackgroundTransparency = 0.9,
    BorderSizePixel = 0,
    ZIndex = 2,
}, main)

do
    local dragging, dragStart, startPos
    top.InputBegan:Connect(function(input)
        if isPointer(input) then
            dragging = true; dragStart = input.Position; startPos = root.Position
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if isPointer(input) then dragging = false end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and isMove(input) then
            local d = input.Position - dragStart
            root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  SIDEBAR + PROFILE
-- ═══════════════════════════════════════════════════════════
local sidebar = make("Frame", {
    Position = UDim2.fromOffset(12, 76),
    Size = UDim2.new(0, 146, 1, -88),
    BackgroundColor3 = THEME.Surface,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    ZIndex = 2,
}, main)
round(sidebar, 16)
stroke(sidebar, THEME.White, 1, 0.9)

local tabHolder = make("Frame", {
    Size = UDim2.new(1, 0, 1, -70),
    BackgroundTransparency = 1,
    ZIndex = 3,
}, sidebar)
make("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, tabHolder)
make("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
}, tabHolder)

local profile = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -10),
    Size = UDim2.new(1, -16, 0, 52),
    BackgroundColor3 = THEME.Card,
    BackgroundTransparency = 0.2,
    ZIndex = 4,
}, sidebar)
round(profile, 14)
stroke(profile, THEME.White, 1, 0.85)

local avatarWrap = make("Frame", {
    Position = UDim2.fromOffset(8, 8),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = THEME.Off,
    BackgroundTransparency = 0.3,
    ZIndex = 5,
}, profile)
round(avatarWrap, 18)

local avatar = make("ImageLabel", {
    Position = UDim2.fromOffset(2, 2),
    Size = UDim2.fromOffset(32, 32),
    BackgroundTransparency = 1,
    ZIndex = 6,
}, avatarWrap)
round(avatar, 16)
stroke(avatarWrap, THEME.Accent, 2, 0)

task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok then avatar.Image = img end
end)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(52, 10),
    Size = UDim2.new(1, -58, 0, 16),
    Text = player.DisplayName,
    TextColor3 = THEME.Text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 5,
}, profile)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(52, 28),
    Size = UDim2.new(1, -58, 0, 12),
    Text = "● Online",
    TextColor3 = THEME.Success,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
}, profile)

-- ═══════════════════════════════════════════════════════════
--  SISTEMA DE ABAS
-- ═══════════════════════════════════════════════════════════
local content = make("Frame", {
    Position = UDim2.fromOffset(170, 76),
    Size = UDim2.new(1, -182, 1, -88),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 2,
}, main)

local pages, tabButtons = {}, {}
local currentTab

local function selectTab(name)
    currentTab = name
    for n, page in pairs(pages) do
        local active = (n == name)
        if active and not page.Visible then
            page.Position = UDim2.fromOffset(0, 20)
            tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.4, Enum.EasingStyle.Quart)
        end
        page.Visible = active

        local btn = tabButtons[n]
        local bar = btn:FindFirstChild("ActiveBar")
        if bar then
            tween(bar, { Size = active and UDim2.new(0, 3, 0.6, 0) or UDim2.new(0, 0, 0.6, 0) }, 0.25, Enum.EasingStyle.Quart)
        end
        tween(btn, {
            BackgroundTransparency = active and 0.1 or 1,
            TextColor3 = active and THEME.Text or THEME.SubText,
        }, 0.25)
    end
end

local function newTab(name, icon, tabOrder)
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 1,
        Text = "   " .. icon .. "   " .. name,
        TextColor3 = THEME.SubText,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = tabOrder,
        ZIndex = 4,
    }, tabHolder)
    round(btn, 10)
    themed(function() btn.BackgroundColor3 = THEME.Card end)

    local bar = make("Frame", {
        Name = "ActiveBar",
        Size = UDim2.new(0, 0, 0.6, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, btn)
    round(bar, 2)
    themed(function() bar.BackgroundColor3 = THEME.Accent end)

    btn.MouseEnter:Connect(function()
        if currentTab ~= name then
            tween(btn, { BackgroundTransparency = 0.85, TextColor3 = THEME.Text }, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= name then
            tween(btn, { BackgroundTransparency = 1, TextColor3 = THEME.SubText }, 0.15)
        end
    end)

    local page = make("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageTransparency = 0.3,
        ScrollBarImageColor3 = THEME.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 2,
    }, content)
    make("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 14),
    }, page)

    pages[name], tabButtons[name] = page, btn
    btn.Activated:Connect(function() selectTab(name) end)
    return page
end

-- ═══════════════════════════════════════════════════════════
--  COMPONENTES
-- ═══════════════════════════════════════════════════════════
local function text(parent, str, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = str,
        TextSize = size,
        TextColor3 = color,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, (size * 2) + 6),
        LayoutOrder = order(),
    }, parent)
end

local function card(parent, height)
    local c = make("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 0.1,
        LayoutOrder = order(),
        ZIndex = 2,
    }, parent)
    round(c, 14)
    stroke(c, THEME.White, 1, 0.9)

    make("Frame", {
        Size = UDim2.new(1, -16, 0, 1),
        Position = UDim2.new(0.5, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = THEME.White,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, c)

    return c
end

local function addToggle(parent, label, default, callback)
    local state = default or false
    local row = card(parent, 48)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -90, 1, 0),
        Text = label,
        TextColor3 = THEME.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, row)

    local track = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(44, 24),
        BackgroundColor3 = state and THEME.Accent or THEME.Off,
        BackgroundTransparency = state and 0 or 0.2,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    }, row)
    round(track, 12)

    local trackStroke = stroke(track, state and THEME.Accent or THEME.White, 1, state and 0.6 or 0.88)

    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = THEME.White,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, track)
    round(knob, 9)

    track.Activated:Connect(function()
        state = not state
        tween(track, {
            BackgroundColor3 = state and THEME.Accent or THEME.Off,
            BackgroundTransparency = state and 0 or 0.2,
        }, 0.25)
        tween(trackStroke, {
            Color = state and THEME.Accent or THEME.White,
            Transparency = state and 0.6 or 0.88,
        }, 0.25)
        tween(knob, {
            Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        }, 0.28, Enum.EasingStyle.Back)
        if callback then callback(state) end
    end)
    return row
end

local function addSlider(parent, label, min, max, default, callback, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    local value = default or min
    local row = card(parent, 66)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -110, 0, 18),
        Text = label,
        TextColor3 = THEME.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, row)

    local valueLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 10),
        Size = UDim2.fromOffset(90, 18),
        Text = tostring(value),
        TextColor3 = THEME.Accent2,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 3,
    }, row)

    local bar = make("Frame", {
        Position = UDim2.new(0, 16, 0, 46),
        Size = UDim2.new(1, -32, 0, 6),
        BackgroundColor3 = THEME.Off,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, row)
    round(bar, 3)

    local fill = make("Frame", {
        Size = UDim2.fromScale((value - min) / (max - min), 1),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, bar)
    round(fill, 3)
    accentGradient(fill, 0)

    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = THEME.White,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, fill)
    round(knob, 9)
    stroke(knob, THEME.Accent, 2.5, 0)

    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        value = math.floor((min + (max - min) * rel) * mult + 0.5) / mult
        valueLabel.Text = (decimals > 0) and string.format("%." .. decimals .. "f", value) or tostring(value)
        tween(fill, { Size = UDim2.fromScale(rel, 1) }, 0.06)
        if callback then callback(value) end
    end

    local sliding = false
    bar.InputBegan:Connect(function(input)
        if isPointer(input) then
            sliding = true
            parent.ScrollingEnabled = false
            tween(knob, { Size = UDim2.fromOffset(24, 24) }, 0.12)
            update(input)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if isPointer(input) and sliding then
            sliding = false
            parent.ScrollingEnabled = true
            tween(knob, { Size = UDim2.fromOffset(18, 18) }, 0.15, Enum.EasingStyle.Back)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if sliding and isMove(input) then update(input) end
    end)
    return row
end

local function addButton(parent, label, primary, callback)
    local holder = make("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = primary and THEME.Accent or THEME.Card,
        BackgroundTransparency = primary and 0 or 0.1,
        LayoutOrder = order(),
        ZIndex = 2,
    }, parent)
    round(holder, 14)

    if primary then
        accentGradient(holder, 20)
        stroke(holder, THEME.Accent, 1, 0.4)
    else
        stroke(holder, THEME.White, 1, 0.88)
    end

    local b = make("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = THEME.White,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ZIndex = 3,
    }, holder)

    b.Activated:Connect(function()
        tween(holder, { Size = UDim2.new(1, -8, 0, 40) }, 0.08)
        task.delay(0.09, function()
            tween(holder, { Size = UDim2.new(1, 0, 0, 44) }, 0.22, Enum.EasingStyle.Back)
        end)
        if callback then task.spawn(callback) end
    end)
    return holder
end

local function notify(msg)
    local toast = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -80),
        Size = UDim2.fromOffset(300, 50),
        BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 0.05,
        ZIndex = 200,
    }, gui)
    round(toast, 16)
    stroke(toast, THEME.White, 1, 0.75)

    make("Frame", {
        Position = UDim2.fromOffset(10, 12),
        Size = UDim2.new(0, 3, 1, -24),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0,
        ZIndex = 201,
    }, toast)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -46, 1, 0),
        Text = msg,
        TextColor3 = THEME.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 201,
    }, toast)

    tween(toast, { Position = UDim2.new(0.5, 0, 0, 24) }, 0.5, Enum.EasingStyle.Back)
    task.delay(2.2, function()
        tween(toast, { Position = UDim2.new(0.5, 0, 0, -80) }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.wait(0.35)
        toast:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TEAM CHECK
-- ═══════════════════════════════════════════════════════════
local NEUTRAL_COLORS = {
    ["Medium stone grey"] = true, ["Medium Stone Grey"] = true,
    ["Institutional white"] = true, ["White"] = true,
    ["Really black"] = true, ["Black"] = true,
}
local TEAM_ATTR_NAMES  = {"Team","team","TeamId","teamId","TeamName","teamName","Side","side","Faction","faction"}
local TEAM_CHILD_NAMES = {"Team","team","TeamId","TeamName","Side","Faction"}

local function GetTeamKey(plr)
    if not plr then return nil end
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
    end
    return nil
end

local function IsAliveHumanoid(h)
    if not h or h.Health <= 0 then return false end
    local ok, st = pcall(function() return h:GetState() end)
    if ok and st and (st == Enum.HumanoidStateType.Dead or st == Enum.HumanoidStateType.None) then
        return false
    end
    return true
end

local function AngleBetween(a, b)
    return math.deg(math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1)))
end

-- ═══════════════════════════════════════════════════════════
--  AIM
-- ═══════════════════════════════════════════════════════════
local ACONFIG = {
    Enabled = false,
    MaxDistance = 5000,
    FOV = 360,
    TeamCheck = true,
    Prediction = false,
    PredictionSpeed = 400,
    Smoothness = 0,
    AutoFire = false,
    AFMinDot = 0.85,
    WeightDistance = 10.0,
    WeightAngle = 0.05,
    SwitchMargin = 0,
}

local lockTarget, lockPart = nil, nil
local lastFire = 0

local function IsEnemy(plr)
    if plr == player then return false end
    if not ACONFIG.TeamCheck then return true end
    local m, h = GetTeamKey(player), GetTeamKey(plr)
    if m and h then return m ~= h end
    return false
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

local function IsLockValid()
    if not lockTarget or not lockPart then return false end
    if not lockPart.Parent then return false end
    if not IsEnemy(lockTarget) then return false end
    local char = lockTarget.Character
    if not char or not char.Parent then return false end
    if not lockPart:IsDescendantOf(char) then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
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
    return best, bestPart, bestDist
end

local function TryAutoFire()
    if not ACONFIG.AutoFire then return end
    if not lockTarget or not lockPart then return end
    local now = tick()
    if now - lastFire < 0.1 then return end
    local cam = Camera.CFrame
    local to = lockPart.Position - cam.Position
    if to.Magnitude < 0.01 then return end
    if cam.LookVector:Dot(to.Unit) < ACONFIG.AFMinDot then return end
    local ch = player.Character
    local tool = ch and ch:FindFirstChildOfClass("Tool")
    if not tool then return end
    pcall(function() tool:Activate() end)
    lastFire = now
end

local function UpdateAim()
    local myChar = player.Character
    if not myChar then lockTarget, lockPart = nil, nil; return end
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if not IsAliveHumanoid(myHum) then lockTarget, lockPart = nil, nil; return end

    if not ACONFIG.Enabled then return end

    if lockTarget and not IsLockValid() then
        lockTarget, lockPart = nil, nil
    end

    local best, bestPart, bestDist = FindBestTarget()

    if best and bestPart then
        local shouldSwitch = false
        if not lockTarget then
            shouldSwitch = true
        elseif best ~= lockTarget then
            local curDist = lockPart and (lockPart.Position - Camera.CFrame.Position).Magnitude
            if not curDist then
                shouldSwitch = true
            elseif bestDist and (curDist - bestDist) >= (ACONFIG.SwitchMargin or 0) then
                shouldSwitch = true
            end
        else
            lockPart = bestPart
        end

        if shouldSwitch then
            lockTarget, lockPart = best, bestPart
        end
    else
        lockTarget, lockPart = nil, nil
    end

    if lockTarget and lockPart then
        local mp = Camera.CFrame.Position
        local aimPos = lockPart.Position
        if ACONFIG.Prediction then
            local vel = lockPart.AssemblyLinearVelocity
            local dist = (aimPos - mp).Magnitude
            aimPos = aimPos + vel * (dist / math.max(ACONFIG.PredictionSpeed, 1))
        end
        local des = CFrame.lookAt(mp, aimPos)
        if ACONFIG.Smoothness <= 0 then
            Camera.CFrame = des
        else
            Camera.CFrame = Camera.CFrame:Lerp(des, 1 - ACONFIG.Smoothness)
        end
        TryAutoFire()
    end
end

RunService:BindToRenderStep("PainelProAim", Enum.RenderPriority.Camera.Value + 1, UpdateAim)

-- ═══════════════════════════════════════════════════════════
--  ESP
-- ═══════════════════════════════════════════════════════════
local ESP_CONFIG = {
    Enabled = true,
    Skeleton = true,
    Box = false,
    Distance = true,
    Name = true,
    TeamCheck = true,
    Color = Color3.fromRGB(255, 30, 30),
    MaxDistance = 1500,
    TextSize = 12,
    Thickness = 1,
}

local SKELETON_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local SKELETON_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}

local ESP_DRAWS = {}
local ESP_MAX_LINES = 20

local function ESPRemoveDraw(plr)
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
    local draw = {
        char = char, plr = plr,
        skeleton = {}, box = {}, name = nil, dist = nil,
    }
    for i = 1, ESP_MAX_LINES do
        local f = make("Frame", {
            BackgroundColor3 = ESP_CONFIG.Color,
            BorderSizePixel = 0, Visible = false, ZIndex = 20,
            AnchorPoint = Vector2.new(0.5, 0.5),
        }, gui)
        draw.skeleton[i] = f
    end
    for i = 1, 4 do
        local f = make("Frame", {
            BackgroundColor3 = ESP_CONFIG.Color,
            BorderSizePixel = 0, Visible = false, ZIndex = 19,
            AnchorPoint = Vector2.new(0.5, 0.5),
        }, gui)
        draw.box[i] = f
    end
    draw.name = make("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = ESP_CONFIG.Color,
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0,0,0),
        Font = Enum.Font.GothamBold, TextSize = ESP_CONFIG.TextSize,
        TextXAlignment = Enum.TextXAlignment.Center, Visible = false,
        ZIndex = 21, Size = UDim2.fromOffset(200, 16),
        AnchorPoint = Vector2.new(0.5, 1),
    }, gui)
    draw.dist = make("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = ESP_CONFIG.Color,
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0,0,0),
        Font = Enum.Font.GothamBold, TextSize = ESP_CONFIG.TextSize,
        TextXAlignment = Enum.TextXAlignment.Center, Visible = false,
        ZIndex = 21, Size = UDim2.fromOffset(200, 16),
        AnchorPoint = Vector2.new(0.5, 0),
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
    if length < 1 or length > 4000 then
        frame.Visible = false
        return
    end
    local center = (p1 + p2) * 0.5
    local angle = math.deg(math.atan(diff.Y, diff.X))
    frame.Visible = true
    frame.Position = UDim2.fromOffset(center.X, center.Y)
    frame.Size = UDim2.fromOffset(length, thickness or 1)
    frame.Rotation = angle
    frame.BackgroundColor3 = color
end

local function ESPUpdateDraw(draw)
    local plr = draw.plr
    local char = plr.Character
    if not char or char ~= draw.char or not ESPIsEnemy(plr) then
        ESPHideAll(draw); return
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then ESPHideAll(draw); return end

    local camPos = Camera.CFrame.Position
    local dist = (hrp.Position - camPos).Magnitude
    if dist > ESP_CONFIG.MaxDistance then ESPHideAll(draw); return end

    local camLook = Camera.CFrame.LookVector
    local toChar = hrp.Position - camPos
    if toChar.Magnitude > 0.01 and toChar.Unit:Dot(camLook) < -0.1 then
        ESPHideAll(draw); return
    end

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
                    if draw.skeleton[lineIdx] then
                        DrawLine2D(draw.skeleton[lineIdx], sp1, sp2, color, thickness)
                    end
                end
            end
        end
        for i = lineIdx + 1, #draw.skeleton do
            draw.skeleton[i].Visible = false
        end
    else
        for _, f in ipairs(draw.skeleton) do f.Visible = false end
    end

    if ESP_CONFIG.Box then
        local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
        if ok and cf then
            local corners = {}
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        table.insert(corners, cf:PointToWorldSpace(Vector3.new(
                            size.X * x / 2, size.Y * y / 2, size.Z * z / 2)))
                    end
                end
            end
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
            if anyOnScreen then
                local tl = Vector2.new(minX, minY)
                local tr = Vector2.new(maxX, minY)
                local br = Vector2.new(maxX, maxY)
                local bl = Vector2.new(minX, maxY)
                DrawLine2D(draw.box[1], tl, tr, color, 2)
                DrawLine2D(draw.box[2], tr, br, color, 2)
                DrawLine2D(draw.box[3], br, bl, color, 2)
                DrawLine2D(draw.box[4], bl, tl, color, 2)
            else
                for _, f in ipairs(draw.box) do f.Visible = false end
            end
        else
            for _, f in ipairs(draw.box) do f.Visible = false end
        end
    else
        for _, f in ipairs(draw.box) do f.Visible = false end
    end

    if ESP_CONFIG.Name then
        local head = char:FindFirstChild("Head") or hrp
        local sp, on = W2S(head.Position + Vector3.new(0, 1.2, 0))
        if on then
            draw.name.Visible = true
            draw.name.Text = plr.Name
            draw.name.TextColor3 = color
            draw.name.Position = UDim2.fromOffset(sp.X, sp.Y)
        else
            draw.name.Visible = false
        end
    else
        draw.name.Visible = false
    end

    if ESP_CONFIG.Distance then
        local head = char:FindFirstChild("Head") or hrp
        local sp, on = W2S(head.Position + Vector3.new(0, -0.8, 0))
        if on then
            draw.dist.Visible = true
            draw.dist.Text = "[" .. math.floor(dist) .. "m]"
            draw.dist.TextColor3 = color
            draw.dist.Position = UDim2.fromOffset(sp.X, sp.Y)
        else
            draw.dist.Visible = false
        end
    else
        draw.dist.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if not ESP_CONFIG.Enabled then
        for _, d in pairs(ESP_DRAWS) do ESPHideAll(d) end
        return
    end
    for _, d in pairs(ESP_DRAWS) do ESPUpdateDraw(d) end
end)

local function ESPRefresh()
    if not ESP_CONFIG.Enabled then
        for plr in pairs(ESP_DRAWS) do ESPRemoveDraw(plr) end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if ESPIsEnemy(plr) and plr.Character then
                local d = ESP_DRAWS[plr]
                if not d or d.char ~= plr.Character then
                    ESPCreateDraw(plr, plr.Character)
                end
            else
                if ESP_DRAWS[plr] then ESPRemoveDraw(plr) end
            end
        end
    end
end

task.spawn(function()
    while true do
        ESPRefresh()
        task.wait(0.3)
    end
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
    for plr in pairs(ESP_DRAWS) do ESPRemoveDraw(plr) end
end

local function ESPUpdateTeamCheck()
    for plr in pairs(ESP_DRAWS) do
        if not ESPIsEnemy(plr) then ESPRemoveDraw(plr) end
    end
    ESPRefresh()
end

-- ═══════════════════════════════════════════════════════════
--  PVP RUSH
-- ═══════════════════════════════════════════════════════════
local PVP = {
    Enabled = false,
    OnlyInMatch = true,
    ForceActive = false,
    Distance = 3,           -- studs que fica do alvo
    AttackRange = 6,        -- distância pra atacar
    AutoAttack = true,
    AttackDelay = 0.1,
    Smooth = 0,             -- 0 = instantâneo | 1 = lerp suave
    FaceTarget = true,
}

local lastPvpAttack = 0

-- Detecção de partida — tenta várias fontes comuns
local function IsInMatch()
    if PVP.ForceActive then return true end
    if not PVP.OnlyInMatch then return true end

    -- Atributos no Player
    for _, attr in ipairs({"InMatch","inMatch","IsInMatch","isInMatch","Playing","playing","InGame","inGame","InRound","inRound"}) do
        local v = player:GetAttribute(attr)
        if v == true then return true end
    end

    -- Atributos no Character
    local ch = player.Character
    if ch then
        for _, attr in ipairs({"InMatch","inMatch","Playing","playing"}) do
            if ch:GetAttribute(attr) == true then return true end
        end
    end

    -- Pastas no workspace (arenas / rounds)
    for _, name in ipairs({"Arena","arena","Match","match","Round","round","InMatch","inMatch","InRound","Playing"}) do
        local f = workspace:FindFirstChild(name)
        if f then return true end
    end

    return false
end

local function UpdatePVP()
    if not PVP.Enabled then return end
    if not IsInMatch() then return end

    local myChar = player.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not IsAliveHumanoid(myHum) then return end

    -- Precisa de um alvo válido do AIM
    if not lockTarget or not lockPart or not IsLockValid() then return end
    local targetChar = lockTarget.Character
    if not targetChar then return end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") or lockPart
    if not targetHRP then return end

    local myPos = myHRP.Position
    local targetPos = targetHRP.Position
    local dist = (targetPos - myPos).Magnitude

    -- Move em direção ao alvo (só se estiver longe)
    if dist > PVP.Distance then
        local dir = targetPos - myPos
        local flatDir = Vector3.new(dir.X, 0, dir.Z)
        if flatDir.Magnitude > 0.01 then
            flatDir = flatDir.Unit
            local desiredPos = targetPos - flatDir * PVP.Distance
            local newCFrame = CFrame.new(desiredPos, PVP.FaceTarget and targetPos or desiredPos)

            if PVP.Smooth > 0 then
                myHRP.CFrame = myHRP.CFrame:Lerp(newCFrame, 1 - PVP.Smooth)
            else
                myHRP.CFrame = newCFrame
            end
        end
    elseif PVP.FaceTarget then
        -- Já colado: só olha pro alvo
        local flatDir = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z)
        if flatDir.Magnitude > 0.01 then
            myHRP.CFrame = CFrame.lookAt(myPos, myPos + flatDir.Unit)
        end
    end

    -- Auto attack
    if PVP.AutoAttack and dist <= PVP.AttackRange then
        local now = tick()
        if now - lastPvpAttack >= PVP.AttackDelay then
            local tool = myChar:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
            end
            lastPvpAttack = now
        end
    end
end

RunService.RenderStepped:Connect(UpdatePVP)

-- ═══════════════════════════════════════════════════════════
--  ABA AIM
-- ═══════════════════════════════════════════════════════════
local aimTab = newTab("Aim", "🎯", 1)
text(aimTab, "Aimbot Players", 20, THEME.Text, Enum.Font.GothamBold)
text(aimTab, "Trava no inimigo mais próximo. Solta na hora se o alvo morrer.", 12, THEME.SubText)

addToggle(aimTab, "🎯 Ativar AIM", false, function(v)
    ACONFIG.Enabled = v
    if not v then lockTarget, lockPart = nil, nil end
    notify(v and "🎯 AIM ON" or "AIM OFF")
end)
addToggle(aimTab, "🛡️ Team Check (ignora aliados)", true, function(v)
    ACONFIG.TeamCheck = v
    if v and lockTarget and not IsLockValid() then
        lockTarget, lockPart = nil, nil
    end
    notify(v and "🛡️ Team Check ON" or "Team Check OFF")
end)
addToggle(aimTab, "🎯 Predição", false, function(v)
    ACONFIG.Prediction = v
    notify(v and "🎯 Predição ON" or "OFF")
end)
addToggle(aimTab, "🔥 Auto Fire", false, function(v)
    ACONFIG.AutoFire = v
    notify(v and "🔥 Auto Fire ON" or "OFF")
end)

text(aimTab, "⚙️ Ajustes", 12, THEME.SubText, Enum.Font.GothamBold)
addSlider(aimTab, "FOV (graus)", 5, 360, 360, function(v) ACONFIG.FOV = v end)
addSlider(aimTab, "Distância máx", 20, 8000, 5000, function(v) ACONFIG.MaxDistance = v end)
addSlider(aimTab, "Velocidade da bala", 50, 3000, 400, function(v) ACONFIG.PredictionSpeed = v end)
addSlider(aimTab, "Suavidade (0 = colado)", 0, 1, 0, function(v) ACONFIG.Smoothness = v end, 2)
addSlider(aimTab, "Prioridade por distância", 1, 20, 10, function(v) ACONFIG.WeightDistance = v end)
addSlider(aimTab, "Tolerância de troca (studs)", 0, 100, 0, function(v) ACONFIG.SwitchMargin = v end)

addButton(aimTab, "🔄 Soltar alvo agora", true, function()
    lockTarget, lockPart = nil, nil
    notify("🔄 Alvo solto")
end)

-- ═══════════════════════════════════════════════════════════
--  ABA ESP
-- ═══════════════════════════════════════════════════════════
local espTab = newTab("ESP", "👁️", 2)
text(espTab, "ESP", 20, THEME.Text, Enum.Font.GothamBold)
text(espTab, "Mostra caixas, nomes e distância dos inimigos.", 12, THEME.SubText)

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
    ESP_CONFIG.TeamCheck = v
    ESPUpdateTeamCheck()
end)

text(espTab, "⚙️ Ajustes", 12, THEME.SubText, Enum.Font.GothamBold)
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
local colorCard = card(espTab, 130)
make("UIPadding", {
    PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
}, colorCard)
make("UIGridLayout", {
    CellSize = UDim2.new(1/4, -6, 0, 44),
    CellPadding = UDim2.fromOffset(8, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, colorCard)

local colorStrokes = {}
for i, preset in ipairs(ESP_COLORS) do
    local name, c = preset[1], preset[2]
    local sw = make("Frame", { BackgroundColor3 = c, LayoutOrder = i }, colorCard)
    round(sw, 10)
    local sst = stroke(sw, THEME.White, 3, 1)
    colorStrokes[i] = sst

    local btn = make("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = name, TextColor3 = Color3.new(1, 1, 1),
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0, 0, 0),
        TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false,
    }, sw)
    btn.Activated:Connect(function()
        ESPApplyColor(c)
        for j, s in ipairs(colorStrokes) do
            tween(s, { Transparency = (j == i) and 0 or 1 })
        end
        notify("Cor do ESP: " .. name)
    end)
end
colorStrokes[1].Transparency = 0

-- ═══════════════════════════════════════════════════════════
--  ABA PVP
-- ═══════════════════════════════════════════════════════════
local pvpTab = newTab("PvP", "⚔️", 3)
text(pvpTab, "PvP Rush", 20, THEME.Text, Enum.Font.GothamBold)
text(pvpTab, "Cola no inimigo e ataca. Só funciona em partida — não faz nada no lobby.", 12, THEME.SubText)

addToggle(pvpTab, "⚔️ Ativar PvP Rush", false, function(v)
    PVP.Enabled = v
    if v and not IsInMatch() and PVP.OnlyInMatch and not PVP.ForceActive then
        notify("⚠️ Não em partida — ativo mas inerte")
    elseif v then
        notify("⚔️ PvP Rush ON")
    else
        notify("PvP Rush OFF")
    end
end)

addToggle(pvpTab, "🎮 Só em partida (protege lobby)", true, function(v)
    PVP.OnlyInMatch = v
    notify(v and "🛡️ Proteção de lobby ON" or "Proteção OFF")
end)

addToggle(pvpTab, "🔓 Forçar ativo (ignora detecção)", false, function(v)
    PVP.ForceActive = v
    if v then
        notify("🔓 Forçado — cuidado no lobby!")
    else
        notify("Detecção normal")
    end
end)

text(pvpTab, "⚔️ COMBATE", 12, THEME.SubText, Enum.Font.GothamBold)

addToggle(pvpTab, "🗡️ Auto Attack", true, function(v)
    PVP.AutoAttack = v
    notify(v and "🗡️ Auto Attack ON" or "OFF")
end)

addToggle(pvpTab, "👀 Olhar pro alvo", true, function(v)
    PVP.FaceTarget = v
end)

text(pvpTab, "⚙️ AJUSTES", 12, THEME.SubText, Enum.Font.GothamBold)

addSlider(pvpTab, "Distância de cola (studs)", 1, 15, 3, function(v) PVP.Distance = v end, 1)
addSlider(pvpTab, "Alcance do ataque (studs)", 3, 20, 6, function(v) PVP.AttackRange = v end, 1)
addSlider(pvpTab, "Delay do ataque (s)", 0.05, 1, 0.1, function(v) PVP.AttackDelay = v end, 2)
addSlider(pvpTab, "Suavidade (0 = teleporte)", 0, 1, 0, function(v) PVP.Smooth = v end, 2)

addButton(pvpTab, "🔍 Checar se estou em partida", true, function()
    if IsInMatch() then
        notify("✅ Em partida — PvP vai funcionar")
    else
        notify("❌ Não detectei partida")
    end
end)

text(pvpTab, "ℹ️ Requer AIM ligado (usa o mesmo alvo travado).", 11, THEME.Muted)

selectTab("Aim")

-- ═══════════════════════════════════════════════════════════
--  BOLINHA FLUTUANTE
-- ═══════════════════════════════════════════════════════════
local bubble = make("Frame", {
    Name = "Bubble",
    Size = UDim2.fromOffset(BUBBLE, BUBBLE),
    Position = UDim2.fromOffset(16, 180),
    BackgroundColor3 = THEME.Accent,
    Visible = false,
    ZIndex = 50,
}, gui)
round(bubble, BUBBLE / 2)
accentGradient(bubble, 45)

local bubbleShadow = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 6, 1, 6),
    BackgroundColor3 = THEME.Black,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    ZIndex = -1,
}, bubble)
round(bubbleShadow, BUBBLE / 2 + 3)

local bubbleStroke = stroke(bubble, THEME.White, 2, 0.5)
local bubbleScale = make("UIScale", { Scale = 0 }, bubble)

TweenService:Create(
    bubbleStroke,
    TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Transparency = 0.15 }
):Play()

local ring = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 49,
}, bubble)
round(ring, BUBBLE / 2)
local ringStroke = stroke(ring, THEME.White, 2, 0.35)
local ringScale = make("UIScale", { Scale = 1 }, ring)
local ringInfo = TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, false)
TweenService:Create(ringScale, ringInfo, { Scale = 1.7 }):Play()
TweenService:Create(ringStroke, ringInfo, { Transparency = 1 }):Play()

local hit = make("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "💀",
    TextColor3 = THEME.White,
    TextSize = 30,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 51,
}, bubble)

local isOpen, busy = false, false

local function showBubble(show)
    if show then
        bubble.Visible = true
        bubbleScale.Scale = 0
        tween(bubbleScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
    else
        tween(bubbleScale, { Scale = 0 }, 0.18)
        task.delay(0.2, function()
            if isOpen then bubble.Visible = false end
        end)
    end
end

local function openWindow()
    if isOpen or busy then return end
    busy, isOpen = true, true
    showBubble(false)
    root.Visible = true
    anim.Scale = 0.7
    tween(anim, { Scale = 1 }, 0.55, Enum.EasingStyle.Back)
    task.delay(0.55, function() busy = false end)
end

local function minimizeWindow()
    if not isOpen or busy then return end
    busy, isOpen = true, false
    tween(anim, { Scale = 0.5 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay(0.27, function()
        root.Visible = false
        showBubble(true)
        busy = false
    end)
end

minBtn.Activated:Connect(minimizeWindow)

local function clampPos(x, y)
    local vp = gui.AbsoluteSize
    return UDim2.fromOffset(
        math.clamp(x, 8, math.max(8, vp.X - BUBBLE - 8)),
        math.clamp(y, 30, math.max(30, vp.Y - BUBBLE - 8))
    )
end

connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
    bubble.Position = clampPos(bubble.Position.X.Offset, bubble.Position.Y.Offset)
end)

do
    local function snapToSide()
        local vp = gui.AbsoluteSize
        local x = bubble.Position.X.Offset
        local target = (x + BUBBLE / 2 < vp.X / 2) and 10 or (vp.X - BUBBLE - 10)
        tween(bubble, { Position = UDim2.fromOffset(target, bubble.Position.Y.Offset) }, 0.45, Enum.EasingStyle.Back)
    end

    local pressing, moved, startMouse, startPos = false, false, nil, nil
    local justDragged = false

    hit.InputBegan:Connect(function(input)
        if isPointer(input) then
            pressing = true
            moved = false
            justDragged = false
            startMouse = input.Position
            startPos = bubble.Position
            tween(bubbleScale, { Scale = 0.9 }, 0.1)
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if pressing and isMove(input) then
            local d = input.Position - startMouse
            if not moved and d.Magnitude > 8 then
                moved = true
                justDragged = true
            end
            if moved then
                bubble.Position = clampPos(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
            end
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if not pressing then return end
        if not isPointer(input) then return end
        pressing = false
        tween(bubbleScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
        if moved then
            snapToSide()
            task.delay(0.1, function() justDragged = false end)
        end
    end)

    hit.MouseButton1Click:Connect(function()
        if justDragged then
            justDragged = false
            return
        end
        openWindow()
    end)
end

connect(UserInputService.InputBegan, function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.RightShift then
        if isOpen then minimizeWindow() else openWindow() end
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    lockTarget, lockPart = nil, nil
    ESPClearAll()
    task.wait(1)
    ESPRefresh()
end)

ESPRefresh()
showBubble(true)

print("✅ Painel Pro — AIM + ESP + PvP carregado")
print("👉 Clique na bolinha 💀 pra abrir (ou tecla J)")
