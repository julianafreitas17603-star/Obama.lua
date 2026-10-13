-- OBSIDIAN Pro v2.4 — trava por esqueleto + interface redesenhada (LocalScript)
-- Alvos: outros jogadores (respeita equipe) e NPCs com a tag "AuthorizedTarget".
-- Local: StarterPlayer > StarterPlayerScripts (LocalScript).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local CS = game:GetService("CollectionService")
local WS = game:GetService("Workspace")
local TextService = game:GetService("TextService")
local lp = Players.LocalPlayer
local IS_TOUCH = UIS.TouchEnabled
local STEP = "ObsidianPro"

-- ═══ TEMA OBSIDIAN BLACK ═══
local C = {
	bg = Color3.fromRGB(0, 0, 0),
	bg2 = Color3.fromRGB(11, 12, 13),
	card = Color3.fromRGB(17, 19, 20),
	card2 = Color3.fromRGB(27, 30, 32),
	line = Color3.fromRGB(36, 40, 42),
	line2 = Color3.fromRGB(54, 59, 62),
	green = Color3.fromRGB(46, 255, 126),
	greenDim = Color3.fromRGB(14, 92, 50),
	text = Color3.fromRGB(238, 243, 240),
	muted = Color3.fromRGB(125, 134, 139),
	red = Color3.fromRGB(255, 82, 82),
	amber = Color3.fromRGB(255, 200, 80),
}
local F = { reg = Enum.Font.Gotham, med = Enum.Font.GothamMedium, bold = Enum.Font.GothamBold, black = Enum.Font.GothamBlack }
local ROW = IS_TOUCH and 54 or 50

-- ═══ CONFIGURAÇÕES ═══
local S = {
	Enabled = true, Lock = true, Auto = true, ShowFov = true,
	Radius = 25,       -- círculo: % do menor lado da tela
	Smooth = 60,       -- suavidade da câmera (%)
	Tol = 24,          -- tolerância de saída do círculo (px)
	MaxDist = 700,     -- distância máxima (studs)
	Team = true,       -- nunca selecionar aliados
	WallCheck = false, -- exige visibilidade (parede/obstáculo)
	ObstructTol = 0.8, -- s de obstrução tolerados antes de soltar o alvo
	MinSwitch = 1.5,   -- s mínimos entre trocas voluntárias
	AdvPct = 35,       -- % de vantagem angular para troca antecipada
	AimBias = 35,      -- ponto de mira: 0 = tronco, 100 = cabeça
	SkelPersist = true,-- mantém o alvo se QUALQUER parte do esqueleto estiver no círculo/visível
	ESP = true, Box = true, Name = true, Dist = true, Health = true, Tracer = false, AimDot = true,
	EspDist = 500,
	Hud = IS_TOUCH, HudScale = 100,
}
local DEFAULT = table.clone(S)
local refresh = {}

local TUNING = {
	OutGrace = 0.2, RangeMargin = 1.05, TieDeg = 0.25, AbsAdvDeg = 2.5,
	BlockedPenalty = 10, OutsidePenalty = 5, LosInterval = 0.1,
	AimFilter = 24,   -- 1/s: filtro do ponto de mira (remove balanço de animação)
	WeightRate = 12,  -- 1/s: velocidade da mistura tronco/cabeça/outra parte
}

-- ═══ LIMPEZA ═══
pcall(function() RunService:UnbindFromRenderStep(STEP) end)
local old = lp:WaitForChild("PlayerGui"):FindFirstChild("ObsidianPro")
if old then old:Destroy() end
local conns = {}
local function conn(c) conns[#conns + 1] = c return c end

-- ═══ HELPERS ═══
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, col, th, tr)
	return new("UIStroke", { Color = col, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function grad(o, c0, c1, rot) return new("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = rot or 90 }, o) end
local function tw(o, props, t, style, dir)
	pcall(function()
		TS:Create(o, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
	end)
end
local function isPtr(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function sameIn(a, i)
	return a ~= nil and (i == a or (a.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1))
end

-- ═══ TELA ═══
local gui = new("ScreenGui", {
	Name = "ObsidianPro", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, lp.PlayerGui)
-- Se algum script do jogo remover/mover a interface, tenta reanexar.
conn(gui.AncestryChanged:Connect(function()
	if not gui:IsDescendantOf(game) then
		pcall(function() gui.Parent = lp.PlayerGui end)
	end
end))

local UI = {} -- referências da interface

UI.espLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = false }, gui)
UI.circle = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Active = false }, gui)
round(UI.circle, 9999)
UI.circleStroke = stroke(UI.circle, C.green, 1.5, 0.2)
UI.aimDot = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Active = false, Visible = false,
}, gui)
round(UI.aimDot, 9999)
stroke(UI.aimDot, C.green, 2, 0)

local function vpSize()
	local s = gui.AbsoluteSize
	if s.X < 1 or s.Y < 1 then local c = WS.CurrentCamera return c and c.ViewportSize or Vector2.new(800, 400) end
	return s
end
local function clampToScreen(o)
	local vp = vpSize()
	local hx, hy = o.Size.X.Offset / 2, o.Size.Y.Offset / 2
	o.Position = UDim2.fromOffset(
		math.clamp(o.Position.X.Offset, hx, math.max(hx, vp.X - hx)),
		math.clamp(o.Position.Y.Offset, hy, math.max(hy, vp.Y - hy)))
end
local function drag(handle, target, onTap)
	local on, moved, start, pos, act = false, false
	conn(handle.InputBegan:Connect(function(i)
		if isPtr(i) then on, moved, act, start, pos = true, false, i, i.Position, target.Position end
	end))
	conn(UIS.InputChanged:Connect(function(i)
		if on and (i == act or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - start
			if not moved and d.Magnitude > 8 then moved = true end
			if moved then
				target.Position = UDim2.fromOffset(pos.X.Offset + d.X, pos.Y.Offset + d.Y)
				clampToScreen(target)
			end
		end
	end))
	conn(UIS.InputEnded:Connect(function(i)
		if on and sameIn(act, i) then
			on = false
			if not moved and onTap then onTap() end
		end
	end))
end
local function pressScale(btn)
	local sc = new("UIScale", { Scale = 1 }, btn)
	conn(btn.InputBegan:Connect(function(i) if isPtr(i) then tw(sc, { Scale = 0.95 }, 0.08) end end))
	conn(btn.InputEnded:Connect(function(i) if isPtr(i) then tw(sc, { Scale = 1 }, 0.14, Enum.EasingStyle.Back) end end))
	return sc
end

-- ═══ ÍCONES (desenhados com formas, sem depender de assets) ═══
-- Tipos: target, eye, filter, gear, close, minus, lock, reset
local function makeIcon(kind, parent, size, color)
	local root = new("Frame", { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Active = false }, parent)
	local fills, strokes = {}, {}
	local u = size / 24
	local function px(v) return math.max(1, math.floor(v * u + 0.5)) end
	local function place(f, cx, cy, w, h, rot)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset(math.floor(cx * u + 0.5), math.floor(cy * u + 0.5))
		f.Size = UDim2.fromOffset(px(w), px(h))
		if rot then f.Rotation = rot end
	end
	local function solid(cx, cy, w, h, rot, rad)
		local f = new("Frame", { BackgroundColor3 = color, BorderSizePixel = 0, Active = false }, root)
		place(f, cx, cy, w, h, rot)
		if rad then new("UICorner", { CornerRadius = UDim.new(rad, 0) }, f) end
		fills[#fills + 1] = f
	end
	local function outline(cx, cy, w, h, th, rad, rot)
		local f = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Active = false }, root)
		place(f, cx, cy, w, h, rot)
		if rad then new("UICorner", { CornerRadius = UDim.new(rad, 0) }, f) end
		strokes[#strokes + 1] = new("UIStroke", { Color = color, Thickness = th, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
	end

	if kind == "target" then
		outline(12, 12, 15, 15, 1.6, 0.5)
		solid(12, 12, 3.5, 3.5, nil, 0.5)
		solid(12, 2.5, 2, 4); solid(12, 21.5, 2, 4); solid(2.5, 12, 4, 2); solid(21.5, 12, 4, 2)
	elseif kind == "eye" then
		outline(12, 12, 21, 12, 1.6, 0.5)
		solid(12, 12, 6, 6, nil, 0.5)
	elseif kind == "filter" then
		solid(12, 6, 18, 2, nil, 0.5); solid(12, 12, 18, 2, nil, 0.5); solid(12, 18, 18, 2, nil, 0.5)
		solid(8, 6, 5, 5, nil, 0.5); solid(16, 12, 5, 5, nil, 0.5); solid(10, 18, 5, 5, nil, 0.5)
	elseif kind == "gear" then
		outline(12, 12, 13, 13, 1.6, 0.12)
		outline(12, 12, 13, 13, 1.6, 0.12, 45)
		outline(12, 12, 6, 6, 1.6, 0.5)
	elseif kind == "close" then
		solid(12, 12, 18, 2.4, 45, 0.5); solid(12, 12, 18, 2.4, -45, 0.5)
	elseif kind == "minus" then
		solid(12, 12, 16, 2.4, nil, 0.5)
	elseif kind == "lock" then
		outline(12, 8.5, 9, 11, 2, 0.5)
		solid(12, 15.5, 15, 11, nil, 0.18)
	elseif kind == "reset" then
		outline(12, 12, 15, 15, 1.8, 0.5)
		solid(19, 6, 5, 5, 45)
	end

	return {
		root = root,
		setColor = function(c)
			for _, f in ipairs(fills) do f.BackgroundColor3 = c end
			for _, s in ipairs(strokes) do s.Color = c end
		end,
	}
end

-- ═══ JANELA ═══
local HEADER_H, TAB_Y, TAB_H, PAGE_Y = 60, 62, 40, 112

local function metrics()
	local vp = vpSize()
	local portrait = vp.X < vp.Y
	local w, h
	if portrait then
		w = math.clamp(vp.X * 0.95, 250, 400)
		h = math.clamp(vp.Y * 0.62, 320, 520)
	else
		w = math.clamp(vp.X * (IS_TOUCH and 0.5 or 0.9), 300, 400)
		h = math.clamp(vp.Y - 20, 280, 520)
	end
	return w, h, vp
end
local W, H, vp0 = metrics()

UI.root = new("Frame", {
	Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	Position = UDim2.fromOffset(vp0.X / 2, IS_TOUCH and (H / 2 + 10) or (vp0.Y / 2)),
	BackgroundTransparency = 1, Active = false,
}, gui)
UI.winScale = new("UIScale", { Scale = 0.9 }, UI.root)

-- brilho suave atrás da janela
for _, g in ipairs({ { 22, 0.975 }, { 10, 0.95 } }) do
	local glow = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, g[1], 1, g[1]),
		BackgroundColor3 = C.green, BackgroundTransparency = g[2], BorderSizePixel = 0, Active = false,
	}, UI.root)
	round(glow, 22)
end

local win = new("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	Active = true, ClipsDescendants = true, -- Active: tocar na janela NÃO gira a câmera
}, UI.root)
round(win, 16)
grad(win, C.bg2, C.bg, 90)
grad(stroke(win, C.green, 1, 0.5), C.green, C.greenDim, 45)
local topLine = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = false }, win)
new("UIGradient", {
	Color = ColorSequence.new(C.green), Rotation = 0,
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
}, topLine)

-- Cabeçalho
UI.header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = 1, Active = true }, win)
local badge = new("Frame", { Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = false }, UI.header)
round(badge, 12)
grad(badge, Color3.fromRGB(90, 255, 160), Color3.fromRGB(20, 190, 95), 135)
local badgeIcon = makeIcon("target", badge, 24, C.bg)
badgeIcon.root.AnchorPoint = Vector2.new(0.5, 0.5)
badgeIcon.root.Position = UDim2.fromScale(0.5, 0.5)

new("TextLabel", {
	Position = UDim2.fromOffset(62, 10), Size = UDim2.new(1, -170, 0, 20), BackgroundTransparency = 1, Text = "OBSIDIAN",
	Font = F.black, TextSize = 17, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Active = false,
}, UI.header)
UI.pulse = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(66, 40), Size = UDim2.fromOffset(8, 8),
	BackgroundColor3 = C.green, BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, Active = false,
}, UI.header)
round(UI.pulse, 99)
UI.dot = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(66, 40), Size = UDim2.fromOffset(8, 8),
	BackgroundColor3 = C.muted, BorderSizePixel = 0, Active = false,
}, UI.header)
round(UI.dot, 99)
UI.sub = new("TextLabel", {
	Position = UDim2.fromOffset(78, 32), Size = UDim2.new(1, -190, 0, 16), BackgroundTransparency = 1, Text = "Pronto · sem alvo",
	Font = F.med, TextSize = 12, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Active = false,
}, UI.header)
local pulseTween = TS:Create(UI.pulse,
	TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, false, 0),
	{ Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1 })
pulseTween:Play()

local function headerBtn(kind, x, col)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = C.card, Text = "", AutoButtonColor = false,
	}, UI.header)
	round(b, 11); stroke(b, C.line, 1, 0)
	local ic = makeIcon(kind, b, 16, col)
	ic.root.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.root.Position = UDim2.fromScale(0.5, 0.5)
	pressScale(b)
	return b
end
local closeBtn = headerBtn("close", -12, C.red)
local minBtn = headerBtn("minus", -54, C.text)

-- Abas: controle segmentado com ícone e indicador deslizante
local TABS = { { "Mira", "target" }, { "ESP", "eye" }, { "Filtros", "filter" }, { "Config", "gear" } }
local tabBar = new("Frame", { Position = UDim2.fromOffset(14, TAB_Y), Size = UDim2.new(1, -28, 0, TAB_H), BackgroundColor3 = C.card, BorderSizePixel = 0, Active = true }, win)
round(tabBar, 12); stroke(tabBar, C.line, 1, 0)
local indicator = new("Frame", {
	Position = UDim2.new(0, 3, 0, 3), Size = UDim2.new(1 / #TABS, -6, 1, -6),
	BackgroundColor3 = C.green, BackgroundTransparency = 0.88, BorderSizePixel = 0, Active = false,
}, tabBar)
round(indicator, 9); stroke(indicator, C.green, 1, 0.45)

local tabs = {}
local function selectTab(i, instant)
	local narrow = UI.root.Size.X.Offset < 340
	for j, t in ipairs(tabs) do
		local on = (j == i)
		local col = on and C.green or C.muted
		t.page.Visible = on
		t.ic.setColor(col)
		t.lbl.Visible = on or not narrow
		tw(t.lbl, { TextColor3 = col }, instant and 0 or 0.15)
	end
	tw(indicator, { Position = UDim2.new((i - 1) / #TABS, 3, 0, 3) }, instant and 0 or 0.28, Enum.EasingStyle.Quint)
	if not instant then
		tabs[i].page.Position = UDim2.fromOffset(0, PAGE_Y + 12)
		tw(tabs[i].page, { Position = UDim2.fromOffset(0, PAGE_Y) }, 0.25, Enum.EasingStyle.Quint)
	end
end
for i, def in ipairs(TABS) do
	local b = new("TextButton", {
		Position = UDim2.fromScale((i - 1) / #TABS, 0), Size = UD
