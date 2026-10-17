-- ==========================================================
--  💀 PAINEL PRO v3.4.1 — AIM + Assist + NPC + ESP + Speed + Noclip + Voo + TP + AutoClick + Config
--  ✅ Patch: AIM escolhe SEMPRE o mais próximo + fix math.atan
--  ✅ Patch: AIM solta IMEDIATAMENTE quando alvo morre/invalida (não gruda em cadáver)
--  ✨ Interface moderna: glass + sombras + micro-animações
-- ==========================================================

repeat task.wait(0.1) until game:IsLoaded()

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Stats             = game:GetService("Stats")
local Lighting          = game:GetService("Lighting")
local VirtualUser       = game:GetService("VirtualUser")
local CollectionService = game:GetService("CollectionService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Camera    = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════
--  TEMA (modernizado)
-- ═══════════════════════════════════════════════════════════
local THEME = {
    Bg         = Color3.fromRGB(12, 13, 20),
    Bg2        = Color3.fromRGB(20, 22, 34),
    Surface    = Color3.fromRGB(18, 20, 32),
    Card       = Color3.fromRGB(26, 28, 42),
    CardHi     = Color3.fromRGB(34, 37, 54),
    Accent     = Color3.fromRGB(167, 139, 250),
    Accent2    = Color3.fromRGB(125, 211, 252),
    AccentSoft = Color3.fromRGB(139, 108, 255),
    Text       = Color3.fromRGB(241, 245, 249),
    SubText    = Color3.fromRGB(148, 163, 184),
    Muted      = Color3.fromRGB(100, 116, 139),
    Success    = Color3.fromRGB(74, 222, 128),
    Warning    = Color3.fromRGB(251, 191, 36),
    Danger     = Color3.fromRGB(248, 113, 113),
    Off        = Color3.fromRGB(51, 65, 85),
    White      = Color3.new(1, 1, 1),
    Black      = Color3.new(0, 0, 0),
    Border     = Color3.fromRGB(255, 255, 255),
}

local PRESETS = {
    { "Roxo",    Color3.fromRGB(167, 139, 250), Color3.fromRGB(125, 211, 252) },
    { "Rosa",    Color3.fromRGB(244, 114, 182), Color3.fromRGB(251, 146, 60) },
    { "Verde",   Color3.fromRGB(74, 222, 128),  Color3.fromRGB(125, 211, 252) },
    { "Laranja", Color3.fromRGB(251, 146, 60),  Color3.fromRGB(250, 204, 21) },
    { "Azul",    Color3.fromRGB(96, 165, 250),  Color3.fromRGB(167, 139, 250) },
    { "Ciano",   Color3.fromRGB(34, 211, 238),  Color3.fromRGB(74, 222, 128) },
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

-- ═══════════════════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════════════════
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
local function applyTheme(a, b)
    THEME.Accent, THEME.Accent2 = a, b
    for _, fn in ipairs(updaters) do fn() end
end
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
    Name = "Root",
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

-- Sombra externa (2 camadas)
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

-- Janela principal
local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = THEME.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 1,
}, win)
round(main, 20)

make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.Bg2),
        ColorSequenceKeypoint.new(1, THEME.Bg),
    }),
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

-- Linha de brilho no topo
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
    Text = "v3.4.1  ·  Interface Moderna",
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
    tween(minBtn.UIStroke, { Transparency = 0.5 }, 0.2)
end)
minBtn.MouseLeave:Connect(function()
    tween(minBtn, { BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.2 }, 0.2)
    tween(minBtn.UIStroke, { Transparency = 0.85 }, 0.2)
end)

-- Divisor
make("Frame", {
    Position = UDim2.new(0.5, 0, 0, 64),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(1, -32, 0, 1),
    BackgroundColor3 = THEME.White,
    BackgroundTransparency = 0.9,
    BorderSizePixel = 0,
    ZIndex = 2,
}, main)

-- Drag do header
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
    Visible = true,
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
    Image = "",
    ZIndex = 6,
}, avatarWrap)
round(avatar, 16)

local avatarStroke = stroke(avatarWrap, THEME.Accent, 2, 0)
themed(function() avatarStroke.Color = THEME.Accent end)

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

-- Content
local content = make("Frame", {
    Position = UDim2.fromOffset(170, 76),
    Size = UDim2.new(1, -182, 1, -88),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 2,
}, main)

-- ═══════════════════════════════════════════════════════════
--  SISTEMA DE ABAS
-- ═══════════════════════════════════════════════════════════
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
            tween(bar, {
                Size = active and UDim2.new(0, 3, 0.6, 0) or UDim2.new(0, 0, 0.6, 0),
            }, 0.25, Enum.EasingStyle.Quart)
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
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 2,
    }, content)
    themed(function() page.ScrollBarImageColor3 = THEME.Accent end)
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
--  COMPONENTES DE UI
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

local function makeListHolder(parent)
    local h = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        LayoutOrder = order(),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, parent)
    make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, h)
    return h
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
    themed(function()
        track.BackgroundColor3 = state and THEME.Accent or THEME.Off
        trackStroke.Color = state and THEME.Accent or THEME.White
    end)

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
    themed(function() valueLabel.TextColor3 = THEME.Accent2 end)

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
    local knobStroke = stroke(knob, THEME.Accent, 2.5, 0)
    themed(function() knobStroke.Color = THEME.Accent end)

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

    b.MouseEnter:Connect(function()
        if not primary then
            tween(holder, { BackgroundColor3 = THEME.CardHi, BackgroundTransparency = 0 }, 0.15)
        else
            tween(holder, { BackgroundColor3 = THEME.AccentSoft }, 0.15)
        end
    end)
    b.MouseLeave:Connect(function()
        if not primary then
            tween(holder, { BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.1 }, 0.15)
        else
            tween(holder, { BackgroundColor3 = THEME.Accent }, 0.15)
        end
    end)

    b.Activated:Connect(function()
        tween(holder, { Size = UDim2.new(1, -8, 0, 40) }, 0.08)
        task.delay(0.09, function()
            tween(holder, { Size = UDim2.new(1, 0, 0, 44) }, 0.22, Enum.EasingStyle.Back)
        end)
        if callback then task.spawn(callback) end
    end)
    return holder
end

-- ═══════════════════════════════════════════════════════════
--  NOTIFICAÇÃO
-- ═══════════════════════════════════════════════════════════
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

    local accentBar = make("Frame", {
        Position = UDim2.fromOffset(10, 12),
        Size = UDim2.new(0, 3, 1, -24),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0,
        ZIndex = 201,
    }, toast)
    round(accentBar, 2)
    themed(function() accentBar.BackgroundColor3 = THEME.Accent end)

    local dot = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0,
        ZIndex = 202,
    }, toast)
    round(dot, 3)
    themed(function() dot.BackgroundColor3 = THEME.Accent end)
    TweenService:Create(
        dot,
        TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { BackgroundTransparency = 0.6 }
    ):Play()

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

-- ═══════════════════════════════════════════════════════════
--  AIM (Players + NPCs)
-- ═══════════════════════════════════════════════════════════
local ACONFIG = {
    EnabledPlayers = false, EnabledNPCs = false,
    MaxDistance = 5000, FOV = 360, TeamCheck = true,
    Prediction = false, PredictionSpeed = 400, Smoothness = 0,
    AutoFire = false, AFCooldownMin = 0.08, AFCooldownMax = 0.15, AFMinDot = 0.85,
    WeightDistance = 10.0,
    WeightAngle = 0.05,
    SwitchMargin = 0,
    MaxLockTime = 999,
    OnlyZombies = false,
    NPCTeamCheck = false,
}

local ASSIST = {
    Enabled = false, Strength = 0.35, FOV = 90, MaxDistance = 800,
    TeamCheck = true, Prediction = false, PredictionSpeed = 400, SmoothStrength = 6,
}

local NPC_CACHE = {}
local NPC_CACHE_TIME = 0

local ZOMBIE_KEYWORDS = {
    "zombie","zumbi","walker","undead","infected","ghoul","monster","mob","enemy","npc","bot","dummy",
    "creature","hostile","demon","skeleton","target","training","test",
    "morto","infectado","monstro","inimigo","criatura","esqueleto","fantasma",
    "chefe","horda","onda","ataque","carniceiro","mutante","podre",
    "boneco","puppet","manequim","stand","clone","sombra",
}
local ZOMBIE_FOLDERS = {
    "zombie","zumbi","mob","enemy","inimigo","monster","monstro","npc","bots","dummy","dummies",
    "creature","spawn","hostile","horda","onda","ataque","spawner",
    "bonecos","boneco","puppets","puppet","stands","stand","clones","clone",
}

local function NameHasZombieKeyword(nome)
    local lower = string.lower(tostring(nome))
    for _, kw in ipairs(ZOMBIE_KEYWORDS) do
        if string.find(lower, kw, 1, true) then return true end
    end
    return false
end

local function IsInsideZombieFolder(model)
    local p = model.Parent
    local depth = 0
    while p and p ~= workspace and depth < 4 do
        local lower = string.lower(p.Name)
        for _, kw in ipairs(ZOMBIE_FOLDERS) do
            if string.find(lower, kw, 1, true) then return true end
        end
        p = p.Parent
        depth = depth + 1
    end
    return false
end

local function IsPlayerCharacter(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then return true end
    end
    return false
end

local function IsNPC(model)
    if not model or not model.Parent then return false end
    if not model:IsA("Model") then return false end
    if IsPlayerCharacter(model) then return false end
    if player.Character == model then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not IsAliveHumanoid(hum) then return false end
    if not ACONFIG.OnlyZombies then return true end
    if NameHasZombieKeyword(model.Name) then return true end
    if IsInsideZombieFolder(model) then return true end
    if model.Parent and NameHasZombieKeyword(model.Parent.Name) then return true end
    if hum.WalkSpeed and hum.WalkSpeed > 0 and hum.WalkSpeed ~= 16 then return true end
    for _, tag in ipairs(CollectionService:GetTags(model)) do
        local lt = string.lower(tag)
        if string.find(lt, "zombie") or string.find(lt, "zumbi") or string.find(lt, "enemy") or string.find(lt, "inimigo") then
            return true
        end
    end
    local head  = model:FindFirstChild("Head")
    local torso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
    if head and torso and hum.Health > 0 and hum.MaxHealth > 0 then
        if not model:FindFirstChild("leaderstats") then return true end
    end
    return false
end

local function NPCGetPart(model)
    if not IsNPC(model) then return nil end
    local part = model:FindFirstChild("Head")
    if part then return part end
    for _, n in ipairs({"UpperTorso","Torso","HumanoidRootPart","LowerTorso"}) do
        local p = model:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    if model.PrimaryPart then return model.PrimaryPart end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then return p end
    end
    return nil
end

local function RefreshNPCCache()
    local now = tick()
    if now - NPC_CACHE_TIME < 0.5 then return end
    NPC_CACHE_TIME = now
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if IsNPC(obj) then table.insert(list, obj) end
    end
    NPC_CACHE = list
end

local function GetAllNPCs()
    RefreshNPCCache()
    return NPC_CACHE
end

local NPC_TEAM_KEYWORDS = {
    ["red"] = "RED", ["blue"] = "BLUE", ["green"] = "GREEN", ["yellow"] = "YELLOW",
    ["team1"] = "T1", ["team2"] = "T2", ["team3"] = "T3", ["team4"] = "T4",
    ["ally"] = "ALLY", ["enemy"] = "ENEMY", ["neutral"] = "NEUTRAL",
    ["vermelho"] = "RED", ["azul"] = "BLUE", ["verde"] = "GREEN", ["amarelo"] = "YELLOW",
    ["aliado"] = "ALLY", ["inimigo"] = "ENEMY", ["neutro"] = "NEUTRAL",
}

local function NameToTeamKey(name)
    local lower = string.lower(tostring(name))
    for kw, key in pairs(NPC_TEAM_KEYWORDS) do
        if string.find(lower, kw, 1, true) then return key end
    end
    return nil
end

local function GetNPCTeamKey(npc)
    if not npc then return nil end
    for _, a in ipairs(TEAM_ATTR_NAMES) do
        local v = npc:GetAttribute(a)
        if v ~= nil then
            local key = NameToTeamKey(v)
            return "A:" .. (key or tostring(v))
        end
    end
    for _, n in ipairs(TEAM_CHILD_NAMES) do
        local v = npc:FindFirstChild(n)
        if v and (v:IsA("StringValue") or v:IsA("IntValue") or v:IsA("NumberValue")) then
            return "C:" .. (NameToTeamKey(v.Value) or tostring(v.Value))
        end
    end
    local nameKey = NameToTeamKey(npc.Name)
    if nameKey then return "N:" .. nameKey end
    local p = npc.Parent
    local depth = 0
    while p and p ~= workspace and depth < 4 do
        local fk = NameToTeamKey(p.Name)
        if fk then return "F:" .. fk end
        p = p.Parent
        depth = depth + 1
    end
    for _, tag in ipairs(CollectionService:GetTags(npc)) do
        local tk = NameToTeamKey(tag)
        if tk then return "T:" .. tk end
    end
    return nil
end

local function NPCIsEnemy(npc)
    if not ACONFIG.NPCTeamCheck then return true end
    local npcKey = GetNPCTeamKey(npc)
    local myKey  = GetTeamKey(player)
    if not npcKey or not myKey then return true end
    local function strip(s) return s:match("^%a+:(.+)$") or s end
    return strip(npcKey) ~= strip(myKey)
end

local AIM_LAST_SWITCH = 0
local AIM_LOCK_START  = 0
local lockTarget, lockPart, lockKind = nil, nil, nil
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
    local best, bestPart, bestScore, bestDist, bestKind = nil, nil, math.huge, nil, nil
    if ACONFIG.EnabledPlayers then
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
                            bestScore, best, bestPart, bestDist, bestKind = score, plr, part, d, "player"
                        end
                    end
                end
            end
        end
    end
    if ACONFIG.EnabledNPCs then
        for _, npc in ipairs(GetAllNPCs()) do
            if NPCIsEnemy(npc) then
                local part = NPCGetPart(npc)
                if part then
                    local to = part.Position - mp
                    local d = to.Magnitude
                    if d <= ACONFIG.MaxDistance then
                        local ang = AngleBetween(ml, to)
                        if ang <= ACONFIG.FOV then
                            local score = d * ACONFIG.WeightDistance + ang * ACONFIG.WeightAngle
                            if score < bestScore then
                                bestScore, best, bestPart, bestDist, bestKind = score, npc, part, d, "npc"
                            end
                        end
                    end
                end
            end
        end
    end
    return best, bestPart, bestScore, bestDist, bestKind
end

local function GetDistToTarget()
    if not lockPart then return nil end
    return (lockPart.Position - Camera.CFrame.Position).Magnitude
end

local assistTarget, assistPart = nil, nil

local function AssistFindTarget()
    local mp, ml = Camera.CFrame.Position, Camera.CFrame.LookVector
    local best, bestPart, bestDist = nil, nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local ok = true
            if ASSIST.TeamCheck then
                local m, h = GetTeamKey(player), GetTeamKey(plr)
                if m and h then ok = (m ~= h) else ok = false end
            end
            if ok then
                local char = plr.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if IsAliveHumanoid(hum) then
                    local part = char:FindFirstChild("Head")
                        or char:FindFirstChild("HumanoidRootPart")
                        or char.PrimaryPart
                    if part then
                        local to = part.Position - mp
                        local d = to.Magnitude
                        if d <= ASSIST.MaxDistance then
                            local ang = AngleBetween(ml, to)
                            if ang <= ASSIST.FOV then
                                if d < bestDist then
                                    bestDist, best, bestPart = d, plr, part
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best, bestPart
end

-- ═══════════════════════════════════════════════════════════
--  ✅ FIX: VALIDA SE O ALVO TRAVADO AINDA ESTÁ VIVO
--  Solta imediatamente se morreu, saiu do jogo, virou aliado, etc.
-- ═══════════════════════════════════════════════════════════
local function IsLockValid()
    if not lockTarget or not lockPart then return false end
    if not lockPart.Parent then return false end

    if lockKind == "player" then
        if not IsEnemy(lockTarget) then return false end
        local char = lockTarget.Character
        if not char or not char.Parent then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        if not lockPart:IsDescendantOf(char) then return false end
    elseif lockKind == "npc" then
        if not lockTarget.Parent then return false end
        local hum = lockTarget:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        if not lockPart:IsDescendantOf(lockTarget) then return false end
    else
        return false
    end
    return true
end

local function UpdateLock()
    local myChar = player.Character
    if not myChar then
        lockTarget, lockPart, lockKind = nil, nil, nil
        assistTarget, assistPart = nil, nil
        return
    end
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if not IsAliveHumanoid(myHum) then
        lockTarget, lockPart, lockKind = nil, nil, nil
        assistTarget, assistPart = nil, nil
        return
    end

    if ACONFIG.EnabledPlayers or ACONFIG.EnabledNPCs then
        -- 🔥 FIX: Se o alvo atual morreu/saiu/invalidou, solta AGORA (antes de buscar novo)
        if lockTarget and not IsLockValid() then
            lockTarget, lockPart, lockKind = nil, nil, nil
        end

        local now = tick()
        local best, bestPart, _, bestDist, bestKind = FindBestTarget()

        if best and bestPart then
            local shouldSwitch = false
            if not lockTarget then
                shouldSwitch = true
            elseif best ~= lockTarget then
                local curDist = GetDistToTarget()
                if not curDist then
                    shouldSwitch = true
                elseif bestDist and (curDist - bestDist) >= (ACONFIG.SwitchMargin or 0) then
                    shouldSwitch = true
                end
            else
                lockPart = bestPart
            end

            if shouldSwitch then
                lockTarget, lockPart, lockKind = best, bestPart, bestKind
                AIM_LAST_SWITCH = now
                AIM_LOCK_START = now
            end
        else
            lockTarget, lockPart, lockKind = nil, nil, nil
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
        return
    end

    if ASSIST.Enabled then
        assistTarget, assistPart = AssistFindTarget()
        if assistTarget and assistPart then
            local mp = Camera.CFrame.Position
            local aimPos = assistPart.Position
            if ASSIST.Prediction then
                local vel = assistPart.AssemblyLinearVelocity
                local dist = (aimPos - mp).Magnitude
                aimPos = aimPos + vel * (dist / math.max(ASSIST.PredictionSpeed, 1))
            end
            local des = CFrame.lookAt(mp, aimPos)
            local strength = math.clamp(ASSIST.Strength, 0, 1)
            local factor = math.clamp(strength * (ASSIST.SmoothStrength / 60), 0, 0.9)
            Camera.CFrame = Camera.CFrame:Lerp(des, factor)
        end
        return
    end

    lockTarget, lockPart, lockKind = nil, nil, nil
    assistTarget, assistPart = nil, nil
end

local okBind = pcall(function()
    RunService:BindToRenderStep("AimUnified", Enum.RenderPriority.Last.Value, UpdateLock)
end)
if not okBind then
    RunService.RenderStepped:Connect(UpdateLock)
end

local function MaybeClearLock()
    if not ACONFIG.EnabledPlayers and not ACONFIG.EnabledNPCs then
        lockTarget, lockPart, lockKind = nil, nil, nil
        AIM_LAST_SWITCH = 0
        AIM_LOCK_START = 0
    end
    assistTarget, assistPart = nil, nil
end

-- ═══════════════════════════════════════════════════════════
--  VOO
-- ═══════════════════════════════════════════════════════════
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
            if fh.Magnitude > 0.001 then fh = fh.Unit else fh = Vector3.new(0,0,-1) end
            if rh.Magnitude > 0.001 then rh = rh.Unit else rh = Vector3.new(1,0,0) end
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

player.CharacterAdded:Connect(function()
    if FlyEnabled then
        task.wait(0.5)
        RemoveFlyParts()
        StartFly()
    end
end)

-- ═══════════════════════════════════════════════════════════
--  SPEED / JUMP / FOV
-- ═══════════════════════════════════════════════════════════
local ConfigState = {
    SpeedEnabled = false, SpeedValue = 16,
    JumpEnabled  = false, JumpValue  = 50,
    FOVEnabled   = false, FOVValue   = 70,
}

local function GetHumanoid()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local SpeedPropConn = nil
local function ApplySpeed()
    local hum = GetHumanoid()
    if not hum then return end
    if ConfigState.SpeedEnabled then hum.WalkSpeed = ConfigState.SpeedValue end
end
local function AttachSpeedTrap()
    if SpeedPropConn then SpeedPropConn:Disconnect() end
    local hum = GetHumanoid()
    if not hum then return end
    SpeedPropConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if ConfigState.SpeedEnabled and hum.WalkSpeed ~= ConfigState.SpeedValue then
            hum.WalkSpeed = ConfigState.SpeedValue
        end
    end)
end

RunService.RenderStepped:Connect(function()
    local hum = GetHumanoid()
    if not hum then return end
    if ConfigState.SpeedEnabled and hum.WalkSpeed ~= ConfigState.SpeedValue then
        hum.WalkSpeed = ConfigState.SpeedValue
    end
    if ConfigState.JumpEnabled then
        if not hum.UseJumpPower then hum.UseJumpPower = true end
        if hum.JumpPower ~= ConfigState.JumpValue then
            hum.JumpPower = ConfigState.JumpValue
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not Camera then return end
    if ConfigState.FOVEnabled and Camera.FieldOfView ~= ConfigState.FOVValue then
        Camera.FieldOfView = ConfigState.FOVValue
    end
end)

player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if ConfigState.SpeedEnabled then ApplySpeed(); AttachSpeedTrap() end
    if ConfigState.JumpEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = ConfigState.JumpValue
        end
    end
    if ConfigState.FOVEnabled and Camera then
        Camera.FieldOfView = ConfigState.FOVValue
    end
end)

-- ═══════════════════════════════════════════════════════════
--  NOCLIP
-- ═══════════════════════════════════════════════════════════
local NoclipEnabled = false
local NoclipConn    = nil

local function NoclipApplyToChar(char)
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.CanCollide = false end)
        end
    end
end

local function NoclipStart()
    if NoclipConn then NoclipConn:Disconnect() end
    NoclipConn = RunService.Stepped:Connect(function()
        if not NoclipEnabled then return end
        local char = player.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                pcall(function() p.CanCollide = false end)
            end
        end
    end)
end

local function NoclipStop()
    if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
    local char = player.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = true end)
            end
        end
    end
end

player.CharacterAdded:Connect(function(char)
    if NoclipEnabled then
        task.wait(0.2)
        NoclipApplyToChar(char)
        NoclipStart()
    end
end)

-- ═══════════════════════════════════════════════════════════
--  FULLBRIGHT
-- ═══════════════════════════════════════════════════════════
local FullbrightEnabled = false
local FullbrightConns   = {}
local FullbrightBackup  = nil

local function SaveOriginalLighting()
    FullbrightBackup = {
        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, FogColor = Lighting.FogColor,
        GlobalShadows = Lighting.GlobalShadows,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        ExposureCompensation = Lighting.ExposureCompensation,
        Effects = {},
    }
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("Atmosphere") then
            FullbrightBackup.Effects[e] = { Density = e.Density, Haze = e.Haze, Glare = e.Glare, Color = e.Color, Decay = e.Decay }
        elseif e:IsA("ColorCorrectionEffect") then
            FullbrightBackup.Effects[e] = { Brightness = e.Brightness, Contrast = e.Contrast, Saturation = e.Saturation, TintColor = e.TintColor }
        elseif e:IsA("BloomEffect") then
            FullbrightBackup.Effects[e] = { Intensity = e.Intensity }
        elseif e:IsA("BlurEffect") then
            FullbrightBackup.Effects[e] = { Size = e.Size }
        elseif e:IsA("SunRaysEffect") then
            FullbrightBackup.Effects[e] = { Intensity = e.Intensity }
        end
    end
end

local function FullbrightApply()
    if not FullbrightBackup then SaveOriginalLighting() end
    Lighting.Ambient = Color3.fromRGB(130, 130, 130)
    Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000; Lighting.FogStart = 100000
    Lighting.GlobalShadows = true
    Lighting.EnvironmentDiffuseScale = 0.5
    Lighting.EnvironmentSpecularScale = 0.5
    Lighting.ExposureCompensation = 0
    for _, ef in ipairs(Lighting:GetChildren()) do
        if ef:IsA("Atmosphere") then ef.Density = 0.1; ef.Haze = 0; ef.Glare = 0
        elseif ef:IsA("ColorCorrectionEffect") then ef.Brightness = 0; ef.Contrast = 0; ef.Saturation = 0; ef.TintColor = Color3.fromRGB(255, 255, 255)
        elseif ef:IsA("BloomEffect") then ef.Intensity = 0
        elseif ef:IsA("BlurEffect") then ef.Size = 0
        elseif ef:IsA("SunRaysEffect") then ef.Intensity = 0 end
    end
end

local function FullbrightStart()
    FullbrightApply()
    for _, c in ipairs(FullbrightConns) do if c and c.Disconnect then pcall(function() c:Disconnect() end) end end
    FullbrightConns = {}
    table.insert(FullbrightConns, Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
        if FullbrightEnabled and (Lighting.ClockTime < 10 or Lighting.ClockTime > 17) then Lighting.ClockTime = 14 end
    end))
    table.insert(FullbrightConns, Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
        if FullbrightEnabled and Lighting.Brightness < 1.5 then Lighting.Brightness = 2 end
    end))
end

local function FullbrightStop()
    for _, c in ipairs(FullbrightConns) do if c and c.Disconnect then pcall(function() c:Disconnect() end) end end
    FullbrightConns = {}
    if FullbrightBackup then
        Lighting.Ambient = FullbrightBackup.Ambient
        Lighting.OutdoorAmbient = FullbrightBackup.OutdoorAmbient
        Lighting.Brightness = FullbrightBackup.Brightness
        Lighting.ClockTime = FullbrightBackup.ClockTime
        Lighting.FogEnd = FullbrightBackup.FogEnd
        Lighting.FogStart = FullbrightBackup.FogStart
        Lighting.FogColor = FullbrightBackup.FogColor
        Lighting.GlobalShadows = FullbrightBackup.GlobalShadows
        Lighting.EnvironmentDiffuseScale = FullbrightBackup.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = FullbrightBackup.EnvironmentSpecularScale
        Lighting.ExposureCompensation = FullbrightBackup.ExposureCompensation
        for ef, vals in pairs(FullbrightBackup.Effects) do
            if ef and ef.Parent then for k, v in pairs(vals) do pcall(function() ef[k] = v end) end end
        end
        FullbrightBackup = nil
    end
end

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
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0, 0, 0),
        Font = Enum.Font.GothamBold, TextSize = ESP_CONFIG.TextSize,
        TextXAlignment = Enum.TextXAlignment.Center, Visible = false,
        ZIndex = 21, Size = UDim2.fromOffset(200, 16),
        AnchorPoint = Vector2.new(0.5, 1),
    }, gui)
    draw.dist = make("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = ESP_CONFIG.Color,
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0, 0, 0),
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
        ESPHideAll(draw)
        return
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        ESPHideAll(draw)
        return
    end
    local camPos = Camera.CFrame.Position
    local dist = (hrp.Position - camPos).Magnitude
    if dist > ESP_CONFIG.MaxDistance then
        ESPHideAll(draw)
        return
    end
    local camLook = Camera.CFrame.LookVector
    local toChar = hrp.Position - camPos
    if toChar.Magnitude > 0.01 and toChar.Unit:Dot(camLook) < -0.1 then
        ESPHideAll(draw)
        return
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
                            size.X * x / 2, size.Y * y / 2, size.Z * z / 2
                        )))
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
        for plr, _ in pairs(ESP_DRAWS) do ESPRemoveDraw(plr) end
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
    for plr, _ in pairs(ESP_DRAWS) do ESPRemoveDraw(plr) end
end

local function ESPUpdateTeamCheck()
    for plr, _ in pairs(ESP_DRAWS) do
        if not ESPIsEnemy(plr) then ESPRemoveDraw(plr) end
    end
    ESPRefresh()
end

-- ═══════════════════════════════════════════════════════════
--  TP
-- ═══════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════
--  AUTO CLICK
-- ═══════════════════════════════════════════════════════════
local AutoClick = { Enabled = false, CPS = 30, Thread = nil, Touching = false, BubbleVisible = false }
local AC_BUBBLE = 80

local acBubble = make("Frame", {
    Name = "AutoClickBubble",
    Size = UDim2.fromOffset(AC_BUBBLE, AC_BUBBLE),
    Position = UDim2.fromOffset(200, 300),
    BackgroundColor3 = THEME.Danger,
    Visible = false,
    ZIndex = 300,
}, gui)
round(acBubble, AC_BUBBLE / 2)
make("UIGradient", {
    Color = ColorSequence.new(THEME.Danger, THEME.Warning),
    Rotation = 45,
}, acBubble)
stroke(acBubble, THEME.White, 2, 0.3)

local acShadow = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 6, 1, 6),
    BackgroundColor3 = THEME.Black,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    ZIndex = -1,
}, acBubble)
round(acShadow, AC_BUBBLE / 2 + 3)

local acScale = make("UIScale", { Scale = 0 }, acBubble)

make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Text = "👆",
    TextColor3 = THEME.White,
    TextSize = 38,
    Font = Enum.Font.GothamBold,
    ZIndex = 301,
}, acBubble)

local acHit = make("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    ZIndex = 302,
}, acBubble)

local function ACStartClickLoop()
    if AutoClick.Thread then return end
    AutoClick.Thread = task.spawn(function()
        while AutoClick.Touching and AutoClick.Enabled do
            pcall(function() VirtualUser:Button1Down(Vector2.new(0, 0)) end)
            pcall(function() VirtualUser:Button1Up(Vector2.new(0, 0)) end)
            task.wait(1 / math.max(AutoClick.CPS, 1))
        end
        AutoClick.Thread = nil
    end)
end

local function ACStopClickLoop()
    AutoClick.Touching = false
end

local function ACShowBubble(show)
    AutoClick.BubbleVisible = show
    if show then
        acBubble.Visible = true
        acScale.Scale = 0
        tween(acScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
    else
        tween(acScale, { Scale = 0 }, 0.2)
        task.delay(0.22, function()
            if not AutoClick.BubbleVisible then acBubble.Visible = false end
        end)
        ACStopClickLoop()
    end
end

do
    local dragging, dragStart, startPos, moved = false, nil, nil, false
    acHit.InputBegan:Connect(function(input)
        if isPointer(input) then
            dragging = true; moved = false
            dragStart = input.Position; startPos = acBubble.Position
            if AutoClick.Enabled then
                AutoClick.Touching = true
                ACStartClickLoop()
                tween(acScale, { Scale = 0.9 }, 0.08)
            end
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and isMove(input) then
            local d = input.Position - dragStart
            if not moved and d.Magnitude > 8 then
                moved = true
                ACStopClickLoop()
                tween(acScale, { Scale = 1 }, 0.15)
            end
            if moved then
                local vp = gui.AbsoluteSize
                acBubble.Position = UDim2.fromOffset(
                    math.clamp(startPos.X.Offset + d.X, 8, vp.X - AC_BUBBLE - 8),
                    math.clamp(startPos.Y.Offset + d.Y, 30, vp.Y - AC_BUBBLE - 8)
                )
            end
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if not dragging then return end
        if not isPointer(input) then return end
        dragging = false
        tween(acScale, { Scale = 1 }, 0.15)
        ACStopClickLoop()
    end)
end

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        ACStopClickLoop()
    end
end)

-- ═══════════════════════════════════════════════════════════
--  ABAS
-- ═══════════════════════════════════════════════════════════

-- AIM
local aimTab = newTab("Aim", "🎯", 1)
text(aimTab, "Aimbot Players (mais próximo)", 20, THEME.Text, Enum.Font.GothamBold)
text(aimTab, "Trava no mais perto. Solta na hora se o alvo morrer.", 12, THEME.SubText)

addToggle(aimTab, "🎯 Ativar Aim 100% em Players", false, function(v)
    ACONFIG.EnabledPlayers = v
    MaybeClearLock()
    notify(v and "🎯 Aim Players ON" or "Aim Players OFF")
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
addSlider(aimTab, "Tolerância de troca (studs)", 0, 100, 0, function(v) ACONFIG.SwitchMargin = v end)

addButton(aimTab, "🔄 Recontar alvos agora", true, function()
    lockTarget, lockPart, lockKind = nil, nil, nil
    AIM_LAST_SWITCH = 0
    AIM_LOCK_START = 0
    notify("🔄 Vai escolher o mais próximo no próximo frame")
end)

-- ASSIST
local assistTab = newTab("Assist", "✨", 2)
text(assistTab, "Aim Assist (suave)", 20, THEME.Text, Enum.Font.GothamBold)
text(assistTab, "Puxa a mira suavemente.", 12, THEME.SubText)

addToggle(assistTab, "✨ Ativar Aim Assist", false, function(v)
    ASSIST.Enabled = v
    notify(v and "✨ Assist ON" or "Assist OFF")
end)
addToggle(assistTab, "🛡️ Team Check", true, function(v) ASSIST.TeamCheck = v end)
addToggle(assistTab, "🎯 Predição", false, function(v) ASSIST.Prediction = v end)

addSlider(assistTab, "Força (%)", 5, 100, 35, function(v) ASSIST.Strength = v / 100 end)
addSlider(assistTab, "FOV", 5, 360, 90, function(v) ASSIST.FOV = v end)
addSlider(assistTab, "Distância máx", 50, 5000, 800, function(v) ASSIST.MaxDistance = v end)
addSlider(assistTab, "Reajuste (suavidade)", 1, 30, 6, function(v) ASSIST.SmoothStrength = v end)

-- AIM NPC
local npcTab = newTab("Aim NPC", "👹", 3)
text(npcTab, "Aimbot NPCs", 20, THEME.Text, Enum.Font.GothamBold)
text(npcTab, "Cola em NPCs / zumbis / bonecos.", 12, THEME.SubText)

addToggle(npcTab, "👹 Ativar Aim 100% em NPCs", false, function(v)
    ACONFIG.EnabledNPCs = v
    MaybeClearLock()
    notify(v and "👹 Aim NPCs ON" or "Aim NPCs OFF")
end)
addToggle(npcTab, "🛡️ Team Check (ignora aliados)", false, function(v)
    ACONFIG.NPCTeamCheck = v
    NPC_CACHE_TIME = 0
    notify(v and "🛡️ Team Check NPCs ON" or "Team Check OFF")
end)
addToggle(npcTab, "🧟 Só zumbis / bonecos", false, function(v)
    ACONFIG.OnlyZombies = v
    NPC_CACHE_TIME = 0
    notify(v and "🧟 Só zumbis ON" or "Todos os NPCs")
end)

addButton(npcTab, "🔍 Contar NPCs", true, function()
    NPC_CACHE_TIME = 0
    local npcs = GetAllNPCs()
    local inimigos = 0
    for _, npc in ipairs(npcs) do
        if NPCIsEnemy(npc) then inimigos = inimigos + 1 end
    end
    if ACONFIG.NPCTeamCheck then
        notify("👹 " .. #npcs .. " NPCs | " .. inimigos .. " inimigos")
    else
        notify("👹 " .. #npcs .. " NPCs")
    end
end)

-- SPEED
local spdTab = newTab("Speed", "⚡", 4)
text(spdTab, "Speed / Pulo / FOV", 20, THEME.Text, Enum.Font.GothamBold)
text(spdTab, "Ajustes persistentes.", 12, THEME.SubText)

addToggle(spdTab, "⚡ Ativar Speed", false, function(v)
    ConfigState.SpeedEnabled = v
    local hum = GetHumanoid()
    if hum then
        if v then
            hum.WalkSpeed = ConfigState.SpeedValue
            AttachSpeedTrap()
        else
            hum.WalkSpeed = 16
            if SpeedPropConn then SpeedPropConn:Disconnect() SpeedPropConn = nil end
        end
    end
    notify(v and "⚡ Speed ON" or "Speed OFF")
end)
addSlider(spdTab, "Velocidade (WalkSpeed)", 16, 1000, 16, function(v)
    ConfigState.SpeedValue = v
    if ConfigState.SpeedEnabled then
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = v end
    end
end)
addToggle(spdTab, "🦘 Pulo Alto", false, function(v)
    ConfigState.JumpEnabled = v
    local hum = GetHumanoid()
    if hum then
        if v then
            hum.UseJumpPower = true
            hum.JumpPower = ConfigState.JumpValue
        else
            hum.UseJumpPower = true
            hum.JumpPower = 50
        end
    end
    notify(v and "🦘 Pulo Alto ON" or "Pulo normal")
end)
addSlider(spdTab, "Força do Pulo", 50, 500, 50, function(v)
    ConfigState.JumpValue = v
    if ConfigState.JumpEnabled then
        local hum = GetHumanoid()
        if hum then hum.UseJumpPower = true; hum.JumpPower = v end
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

-- ESP
local espTab = newTab("ESP", "👁️", 5)
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
    ESP_CONFIG.TeamCheck = v
    ESPUpdateTeamCheck()
end)

text(espTab, "⚙️ AJUSTES", 12, THEME.SubText, Enum.Font.GothamBold)
addSlider(espTab, "Distância máx (studs)", 50, 5000, 1500, function(v)
    ESP_CONFIG.MaxDistance = v
end)
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

-- NOCLIP
local noclipTab = newTab("Noclip", "🧱", 6)
text(noclipTab, "Noclip", 20, THEME.Text, Enum.Font.GothamBold)
text(noclipTab, "Atravessa paredes.", 12, THEME.SubText)
addToggle(noclipTab, "🧱 Ativar Noclip", false, function(v)
    NoclipEnabled = v
    if v then
        NoclipStart(); NoclipApplyToChar(player.Character); notify("Noclip ON")
    else
        NoclipStop(); notify("Noclip OFF")
    end
end)

-- VOO
local vooTab = newTab("Voo", "🚀", 7)
text(vooTab, "Voo", 20, THEME.Text, Enum.Font.GothamBold)
text(vooTab, "Voe livre.", 12, THEME.SubText)
addToggle(vooTab, "🚀 Ativar Voo", false, function(v)
    if v then StartFly(); notify("Voo ON") else StopFly(); notify("Voo OFF") end
end)
addSlider(vooTab, "Velocidade do Voo", 20, 800, 60, function(v) FlySpeed = v end)

-- FULLBRIGHT
local fullTab = newTab("Fullbright", "🔦", 8)
text(fullTab, "Fullbright", 20, THEME.Text, Enum.Font.GothamBold)
text(fullTab, "Clareia o mapa.", 12, THEME.SubText)
addToggle(fullTab, "🔦 Ativar Fullbright", false, function(v)
    FullbrightEnabled = v
    if v then
        FullbrightStart(); notify("Fullbright ON")
    else
        FullbrightStop(); notify("Fullbright OFF")
    end
end)

-- TP
local tpTab = newTab("TP", "📍", 9)
text(tpTab, "Teleportes", 20, THEME.Text, Enum.Font.GothamBold)
text(tpTab, "Salve pontos e volte pra eles.", 12, THEME.SubText)
addButton(tpTab, "📍 Salvar Posição Atual", true, function()
    local c = player.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local idx = #TPPoints + 1
    table.insert(TPPoints, {
        name = "Ponto " .. idx .. " (" .. math.floor(r.Position.X) .. ", " .. math.floor(r.Position.Z) .. ")",
        pos = r.Position,
    })
    if _G.RefreshTPList then _G.RefreshTPList() end
    notify("Ponto " .. idx .. " salvo!")
end)

local savedHeader = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = THEME.Off,
    BackgroundTransparency = 0.4,
    Text = "📍 Pontos salvos: 0",
    TextColor3 = THEME.SubText,
    Font = Enum.Font.GothamBold, TextSize = 12,
    LayoutOrder = order(),
}, tpTab)
round(savedHeader, 10)

local savedHolder = makeListHolder(tpTab)
_G.RefreshTPList = function()
    for _, ch in ipairs(savedHolder:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    savedHeader.Text = "📍 Pontos salvos: " .. #TPPoints
    if #TPPoints == 0 then
        local empty = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = THEME.Off,
            BackgroundTransparency = 0.6,
            Text = "Nenhum ponto salvo ainda",
            TextColor3 = THEME.SubText,
            Font = Enum.Font.Gotham, TextSize = 12,
        }, savedHolder)
        round(empty, 10)
    else
        for i, p in ipairs(TPPoints) do
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = THEME.Card,
                LayoutOrder = i,
            }, savedHolder)
            round(row, 12)
            stroke(row, THEME.White, 1, 0.85)
            make("TextLabel", {
                Size = UDim2.new(1, -110, 1, 0),
                Position = UDim2.fromOffset(12, 0),
                BackgroundTransparency = 1,
                Text = p.name,
                TextColor3 = THEME.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamMedium, TextSize = 12,
            }, row)
            local irBtn = make("TextButton", {
                Size = UDim2.fromOffset(50, 26),
                Position = UDim2.new(1, -96, 0.5, -13),
                BackgroundColor3 = THEME.Accent,
                Text = "IR", TextColor3 = THEME.White,
                Font = Enum.Font.GothamBold, TextSize = 12,
                AutoButtonColor = false,
            }, row)
            round(irBtn, 6)
            irBtn.Activated:Connect(function() TeleportTo(p.pos); notify("TP feito!") end)

            local delBtn = make("TextButton", {
                Size = UDim2.fromOffset(34, 26),
                Position = UDim2.new(1, -40, 0.5, -13),
                BackgroundColor3 = THEME.Danger,
                Text = "X", TextColor3 = THEME.White,
                Font = Enum.Font.GothamBold, TextSize = 12,
                AutoButtonColor = false,
            }, row)
            round(delBtn, 6)
            delBtn.Activated:Connect(function()
                table.remove(TPPoints, i)
                _G.RefreshTPList()
                notify("Ponto removido")
            end)
        end
    end
end
_G.RefreshTPList()

-- AUTO CLICK
local acTab = newTab("Auto Click", "🖱️", 10)
text(acTab, "Auto Click com Bolinha", 20, THEME.Text, Enum.Font.GothamBold)
text(acTab, "Ativa → bolinha pra arrastar e segurar.", 12, THEME.SubText)
addToggle(acTab, "🖱️ Ativar Auto Click", false, function(v)
    AutoClick.Enabled = v
    if v then
        ACShowBubble(true); notify("👆 Bolinha apareceu!")
    else
        ACShowBubble(false)
        AutoClick.Touching = false
        if AutoClick.Thread then pcall(task.cancel, AutoClick.Thread); AutoClick.Thread = nil end
        notify("🖱️ Auto Click OFF")
    end
end)
addSlider(acTab, "CPS", 1, 500, 30, function(v) AutoClick.CPS = v end)
addButton(acTab, "🔥 MODO INSANO (300 CPS)", true, function() AutoClick.CPS = 300; notify("🔥 CPS 300") end)
addButton(acTab, "⚡ MODO TURBO (500 CPS)", false, function() AutoClick.CPS = 500; notify("⚡ CPS 500") end)

-- CONFIG
local cfgTab = newTab("Config", "⚙️", 11)
text(cfgTab, "Config", 20, THEME.Text, Enum.Font.GothamBold)
text(cfgTab, "Personalize o painel.", 12, THEME.SubText)

text(cfgTab, "🎨 COR DA INTERFACE", 12, THEME.SubText, Enum.Font.GothamBold)
local themeCard = card(cfgTab, 132)
make("UIPadding", {
    PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
}, themeCard)
make("UIGridLayout", {
    CellSize = UDim2.new(1/3, -6, 0, 50),
    CellPadding = UDim2.fromOffset(8, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, themeCard)

local themeStrokes = {}
for i, preset in ipairs(PRESETS) do
    local name, c1, c2 = preset[1], preset[2], preset[3]
    local sw = make("Frame", { BackgroundColor3 = c1, LayoutOrder = i }, themeCard)
    round(sw, 12)
    make("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = 30 }, sw)
    local sst = stroke(sw, THEME.White, 2.5, i == 1 and 0 or 1)
    themeStrokes[i] = sst

    local btn = make("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = name, TextColor3 = THEME.White,
        TextSize = 13, Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, sw)
    btn.Activated:Connect(function()
        applyTheme(c1, c2)
        for j, s in ipairs(themeStrokes) do
            tween(s, { Transparency = (j == i) and 0 or 1 })
        end
        notify("Tema " .. name)
    end)
end

text(cfgTab, "📏 PAINEL", 12, THEME.SubText, Enum.Font.GothamBold)
addSlider(cfgTab, "Escala (%)", 60, 130, 100, function(v)
    PanelScaleMult = v / 100
    updateFit()
end)
addSlider(cfgTab, "Transparência (%)", 0, 60, 0, function(v)
    main.BackgroundTransparency = v / 100
end)

text(cfgTab, "✨ COMPORTAMENTO", 12, THEME.SubText, Enum.Font.GothamBold)
addToggle(cfgTab, "✨ Animações", true, function(v)
    AnimEnabled = v
    notify(v and "Animações ON" or "Animações OFF")
end)
addToggle(cfgTab, "👤 Mostrar perfil", true, function(v) profile.Visible = v end)

selectTab("Aim")

-- ═══════════════════════════════════════════════════════════
--  BOLINHA DO PAINEL
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
local savedMouseBehavior, savedMouseIcon

local function unlockMouse()
    pcall(function()
        savedMouseBehavior = UserInputService.MouseBehavior
        savedMouseIcon = UserInputService.MouseIconEnabled
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end

local function lockMouse()
    pcall(function()
        UserInputService.MouseBehavior = savedMouseBehavior or Enum.MouseBehavior.LockCenter
        if savedMouseIcon ~= nil then
            UserInputService.MouseIconEnabled = savedMouseIcon
        end
    end)
end

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
    unlockMouse()
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
        lockMouse()
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
    lockTarget, lockPart, lockKind = nil, nil, nil
    assistTarget, assistPart = nil, nil
    AIM_LAST_SWITCH = 0
    AIM_LOCK_START = 0
    ESPClearAll()
    task.wait(1)
    ESPRefresh()
end)

-- Estado inicial
ESPRefresh()
showBubble(true)

print("✅ Painel Pro v3.4.1 — Interface Moderna + AIM não gruda em cadáver")
print("✨ Glass + sombras + micro-animações")
print("🎯 AIM escolhe SEMPRE o mais próximo E solta na hora se o alvo morrer")
