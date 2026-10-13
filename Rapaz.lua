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
		Position = UDim2.fromScale((i - 1) / #TABS, 0), Size = UDim2.fromScale(1 / #TABS, 1), BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, ZIndex = 2,
	}, tabBar)
	local content = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = false, ZIndex = 2 }, b)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)
	local ic = makeIcon(def[2], content, 16, C.muted)
	ic.root.LayoutOrder = 1
	local lbl = new("TextLabel", {
		Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = def[1],
		Font = F.bold, TextSize = 13, TextColor3 = C.muted, LayoutOrder = 2, Active = false,
	}, content)
	local page = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, PAGE_Y), Size = UDim2.new(1, 0, 1, -PAGE_Y), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.green, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Active = true, Visible = false,
	}, win)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, page)
	tabs[i] = { btn = b, ic = ic, lbl = lbl, page = page }
	conn(b.Activated:Connect(function() selectTab(i) end))
end

-- ═══ COMPONENTES ═══
local orders = {}
local function ord(page) orders[page] = (orders[page] or 0) + 1 return orders[page] end

local function section(page, text)
	local up = string.upper(text)
	local f = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = ord(page), Active = false }, page)
	new("TextLabel", {
		Position = UDim2.fromOffset(2, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
		Text = up, Font = F.bold, TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, Active = false,
	}, f)
	local w = 60
	pcall(function() w = TextService:GetTextSize(up, 11, F.bold, Vector2.new(1000, 26)).X end)
	new("Frame", { Position = UDim2.new(0, w + 14, 0.5, 0), Size = UDim2.new(1, -(w + 14), 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0, Active = false }, f)
end

local function infoCard(page)
	local l = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card, Text = "…",
		Font = F.reg, TextSize = 12, TextColor3 = C.muted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = ord(page),
	}, page)
	round(l, 12); stroke(l, C.line, 1, 0)
	new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, l)
	return l
end

local function toggle(page, name, key, desc)
	local h = desc and (ROW + 10) or ROW
	local row = new("TextButton", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.card, Text = "", AutoButtonColor = false, LayoutOrder = ord(page) }, page)
	round(row, 12)
	local rs = stroke(row, C.line, 1, 0)
	new("TextLabel", {
		Position = UDim2.fromOffset(14, desc and 9 or 0), Size = UDim2.new(1, -86, 0, desc and 20 or h), BackgroundTransparency = 1,
		Text = name, Font = F.med, TextSize = 15, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Active = false,
	}, row)
	if desc then
		new("TextLabel", {
			Position = UDim2.fromOffset(14, 31), Size = UDim2.new(1, -86, 0, 18), BackgroundTransparency = 1, Text = desc,
			Font = F.reg, TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Active = false,
		}, row)
	end
	local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(48, 26), BackgroundColor3 = C.card2, BorderSizePixel = 0, Active = false }, row)
	round(track, 13)
	local ts = stroke(track, C.line2, 1, 0)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = C.muted, BorderSizePixel = 0, Active = false }, track)
	round(knob, 10)
	local function render(instant)
		local on, t = S[key], instant and 0 or 0.2
		tw(track, { BackgroundColor3 = on and C.green or C.card2 }, t)
		tw(ts, { Color = on and C.green or C.line2 }, t)
		tw(rs, { Color = on and C.greenDim or C.line }, t)
		tw(knob, { Position = on and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = on and C.bg or C.muted }, t, Enum.EasingStyle.Back)
	end
	render(true)
	refresh[key] = render
	conn(row.MouseButton1Down:Connect(function() tw(row, { BackgroundColor3 = C.card2 }, 0.08) end))
	conn(row.InputEnded:Connect(function(i) if isPtr(i) then tw(row, { BackgroundColor3 = C.card }, 0.2) end end))
	conn(row.Activated:Connect(function() S[key] = not S[key]; render() end))
end

local function slider(page, name, key, mn, mx, suffix, step)
	suffix, step = suffix or "", step or 1
	local fmt = (step % 1 == 0) and "%d" or "%.1f"
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = C.card, LayoutOrder = ord(page) }, page)
	round(row, 12); stroke(row, C.line, 1, 0)
	new("TextLabel", {
		Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -100, 0, 22), BackgroundTransparency = 1, Text = name,
		Font = F.med, TextSize = 15, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Active = false,
	}, row)
	local chip = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 9), Size = UDim2.fromOffset(70, 22),
		BackgroundColor3 = C.greenDim, BackgroundTransparency = 0.55, Font = F.bold, TextSize = 13, TextColor3 = C.green, Active = false,
	}, row)
	round(chip, 7)
	local track = new("Frame", { Position = UDim2.new(0, 14, 0, 47), Size = UDim2.new(1, -28, 0, 5), BackgroundColor3 = C.card2, BorderSizePixel = 0, Active = false }, row)
	round(track, 3)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = false }, track)
	round(fill, 3); grad(fill, Color3.fromRGB(20, 190, 95), C.green, 0)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = false }, track)
	round(knob, 10); stroke(knob, C.green, 2, 0)
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = C.green, BorderSizePixel = 0, Active = false }, knob)
		:FindFirstChildOfClass("UICorner") -- (sem efeito; o cantinho é criado abaixo)
	for _, ch in ipairs(knob:GetChildren()) do
		if ch:IsA("Frame") then round(ch, 3) end
	end
	local function render()
		local a = (S[key] - mn) / (mx - mn)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		chip.Text = string.format(fmt, S[key]) .. suffix
	end
	render()
	refresh[key] = render
	local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5 }, row)
	local act
	local function set(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = math.floor((mn + (mx - mn) * a) / step + 0.5) * step
		S[key] = math.clamp(math.floor(v * 1000 + 0.5) / 1000, mn, mx)
		render()
	end
	conn(hit.InputBegan:Connect(function(i)
		if isPtr(i) then
			act = i
			page.ScrollingEnabled = false
			tw(knob, { Size = UDim2.fromOffset(26, 26) }, 0.12)
			set(i.Position.X)
		end
	end))
	conn(UIS.InputChanged:Connect(function(i)
		if act and (i == act or i.UserInputType == Enum.UserInputType.MouseMovement) then set(i.Position.X) end
	end))
	conn(UIS.InputEnded:Connect(function(i)
		if act and sameIn(act, i) then
			act = nil
			page.ScrollingEnabled = true
			tw(knob, { Size = UDim2.fromOffset(20, 20) }, 0.12)
		end
	end))
end

local function button(page, text, primary, fn, iconKind)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, ROW), BackgroundColor3 = primary and Color3.new(1, 1, 1) or C.card, Text = "",
		AutoButtonColor = false, LayoutOrder = ord(page),
	}, page)
	round(b, 12)
	if primary then grad(b, Color3.fromRGB(80, 255, 155), Color3.fromRGB(20, 200, 100), 90) else stroke(b, C.green, 1, 0.55) end
	local col = primary and C.bg or C.green
	local content = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = false }, b)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)
	if iconKind then
		local ic = makeIcon(iconKind, content, 18, col)
		ic.root.LayoutOrder = 1
	end
	new("TextLabel", {
		Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = text,
		Font = F.bold, TextSize = 15, TextColor3 = col, LayoutOrder = 2, Active = false,
	}, content)
	pressScale(b)
	conn(b.Activated:Connect(fn))
end

-- Aviso (toast) embaixo, no centro: longe do joystick e do botão de pulo
local toastObj
local function toast(msg)
	if toastObj then toastObj:Destroy() end
	local g = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.card, GroupTransparency = 1, Active = false, ZIndex = 50,
	}, gui)
	round(g, 20); stroke(g, C.green, 1, 0.45)
	local inner = new("Frame", { Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Active = false }, g)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	}, inner)
	new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 18) }, inner)
	local d = new("Frame", { Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.green, BorderSizePixel = 0, LayoutOrder = 1, Active = false }, inner)
	round(d, 99)
	new("TextLabel", {
		Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = msg,
		Font = F.bold, TextSize = 14, TextColor3 = C.text, LayoutOrder = 2, Active = false,
	}, inner)
	toastObj = g
	tw(g, { GroupTransparency = 0, Position = UDim2.new(0.5, 0, 1, -16) }, 0.25, Enum.EasingStyle.Back)
	task.delay(1.8, function()
		if g.Parent then
			tw(g, { GroupTransparency = 1 }, 0.3)
			task.delay(0.35, function() if g.Parent then g:Destroy() end end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ESTADO E SELEÇÃO PERSISTENTE
-- ═══════════════════════════════════════════════════════════════════════════
local target = nil
local outTime, blockTime = 0, 0
local lastSwitch = -1e9
local holdOff = 0
local pick = false
local dropped = {}
local ctx = { camPos = Vector3.zero, now = 0, cam = nil, center = Vector2.zero }
local stats = { players = 0, noChar = 0, dead = 0, ally = 0, noPart = 0, valid = 0, inRange = 0, inCircle = 0, blocked = 0 }

-- Trava de câmera: guarda a PRÓPRIA rotação (funciona com câmera Custom e Scriptable)
local Lock = { weight = 0, aim = nil, rot = nil, final = nil, active = false }
local function resetLock()
	Lock.weight, Lock.aim, Lock.rot, Lock.final, Lock.active = 0, nil, nil, nil, false
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
local rayBase = {}

-- ─── Esqueleto ───────────────────────────────────────────────────────────────
local SKEL_KEYS = { "head", "torso", "root", "armL", "armR", "legL", "legR" }
local CORE_KEYS = { "torso", "root", "head" }
local SKEL_NAMES = {
	head = { "Head" },
	torso = { "UpperTorso", "Torso" },
	root = { "HumanoidRootPart" },
	armL = { "LeftUpperArm", "Left Arm" },
	armR = { "RightUpperArm", "Right Arm" },
	legL = { "LeftUpperLeg", "Left Leg" },
	legR = { "RightUpperLeg", "Right Leg" },
}
local skelCache = {}

--- Resolve as partes do corpo (R15 e R6) e guarda por 1 s; revalida se alguma sumir.
local function getSkeleton(m)
	local sk = skelCache[m]
	if sk and ctx.now - sk.t < 1 then
		local ok = true
		for _, p in pairs(sk.parts) do
			if not p.Parent then ok = false break end
		end
		if ok then return sk end
	end
	local parts = {}
	for key, names in pairs(SKEL_NAMES) do
		for _, n in ipairs(names) do
			local p = m:FindFirstChild(n)
			if p and p:IsA("BasePart") then parts[key] = p break end
		end
	end
	if not (parts.root or parts.torso or parts.head) then
		local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
		if pp then parts.root = pp end
	end
	sk = { t = ctx.now, parts = parts, vis = {} }
	skelCache[m] = sk
	return sk
end

local function setTarget(en, now)
	local newModel = en and en.m or nil
	if newModel ~= target then
		if target then dropped[target] = now end
		target = newModel
		lastSwitch = now
		outTime, blockTime = 0, 0
	end
end

--- Há cenário sólido entre a câmera e o ponto? Partes quase invisíveis (>= 0.9) são ignoradas.
--- Personagens NÃO bloqueiam (rayBase os exclui): alguém passando na frente não derruba a trava.
local function lineBlockedTo(pos)
	local filter = table.clone(rayBase)
	rayParams.FilterDescendantsInstances = filter
	local origin = ctx.camPos
	local dir = pos - origin
	for _ = 1, 4 do
		local hit = WS:Raycast(origin, dir, rayParams)
		if not hit then return false end
		if hit.Instance.Transparency < 0.9 then return true end
		filter[#filter + 1] = hit.Instance
		rayParams.FilterDescendantsInstances = filter
	end
	return true
end

local function partVisible(en, key)
	local part = en.sk.parts[key]
	if not part then return false end
	local c = en.sk.vis[key]
	if c and ctx.now - c.t < TUNING.LosInterval then return c.ok end
	local ok = not lineBlockedTo(part.Position)
	if c then c.t, c.ok = ctx.now, ok else en.sk.vis[key] = { t = ctx.now, ok = ok } end
	return ok
end

--- Visível por tronco/raiz/cabeça (usado para ESCOLHER o alvo: precisão).
local function visibleCore(en)
	if not S.WallCheck then return true end
	if en.visC ~= nil then return en.visC end
	en.visC = false
	for _, k in ipairs(CORE_KEYS) do
		if partVisible(en, k) then en.visC = true break end
	end
	return en.visC
end

--- Visível por QUALQUER parte do esqueleto (usado para MANTER o alvo: persistência).
local function visibleAny(en)
	if not S.WallCheck then return true end
	if en.visA ~= nil then return en.visA end
	en.visA = false
	for _, k in ipairs(S.SkelPersist and SKEL_KEYS or CORE_KEYS) do
		if partVisible(en, k) then en.visA = true break end
	end
	return en.visA
end

--- Menor distância (px) ao centro entre as partes do esqueleto: o alvo só é "perdido"
--- quando TODAS as partes saem do círculo + tolerância.
local function keepDistance(en)
	if not S.SkelPersist then return en.sd end
	local best = en.sd
	for _, key in ipairs(SKEL_KEYS) do
		local part = en.sk.parts[key]
		if part then
			local v = ctx.cam:WorldToViewportPoint(part.Position)
			if v.Z > 0 then
				local d = (Vector2.new(v.X, v.Y) - ctx.center).Magnitude
				if d < best then best = d end
			end
		end
	end
	return best
end

local function eligible(en, r)
	return en.sd <= r and en.dist <= S.MaxDist and visibleCore(en)
end

local function better(a, b)
	if math.abs(a.ang - b.ang) > TUNING.TieDeg then return a.ang < b.ang end
	return a.dist < b.dist
end

local function pickBest(list, r, exclude, voluntary, now)
	local best
	for _, en in ipairs(list) do
		if en.m ~= exclude and eligible(en, r) then
			local recent = voluntary and dropped[en.m] and (now - dropped[en.m]) < S.MinSwitch
			if not recent and (not best or better(en, best)) then best = en end
		end
	end
	return best
end

local function selectTarget(list, byModel, r, dt, now)
	local cur = target and byModel[target] or nil
	local forced = false

	if target then
		if not cur then
			forced = true -- morreu, saiu, perdeu personagem, virou aliado ou ficou inválido
		elseif cur.dist > S.MaxDist * TUNING.RangeMargin then
			forced = true -- passou da distância máxima
		else
			cur.sdKeep = keepDistance(cur)
			cur.blocked = S.WallCheck and not visibleAny(cur)
			blockTime = cur.blocked and (blockTime + dt) or 0 -- volta a ficar visível → zera
			outTime = (cur.sdKeep > r + S.Tol) and (outTime + dt) or 0
			if blockTime > S.ObstructTol or outTime > TUNING.OutGrace then forced = true end
		end
	end

	if forced then
		local best = pickBest(list, r, target, false, now)
		setTarget(best, now)
		cur = best
	elseif target and S.Auto then
		if now - lastSwitch >= S.MinSwitch then
			local penalty = (cur.blocked and TUNING.BlockedPenalty or 0) + (cur.sd > r and TUNING.OutsidePenalty or 0)
			if penalty > 0 then
				local best = pickBest(list, r, target, true, now)
				if best then
					local curEff = cur.ang + penalty
					if best.ang <= curEff * (1 - S.AdvPct / 100) and (curEff - best.ang) >= TUNING.AbsAdvDeg then
						setTarget(best, now)
						cur = best
					end
				end
			end
		end
	elseif not target and S.Auto and now >= holdOff then
		local best = pickBest(list, r, nil, false, now)
		if best then setTarget(best, now); cur = best end
	end

	if pick then
		pick = false
		local best = pickBest(list, r, nil, false, now)
		if best then
			setTarget(best, now)
			cur = best
			toast("Alvo: " .. (best.player and best.player.DisplayName or best.m.Name))
		else
			toast("Nenhum alvo no círculo")
		end
	end
	return cur
end

-- ─── Ponto de mira por esqueleto ────────────────────────────────────────────────
-- Mistura CONTÍNUA (sem troca brusca): tronco ↔ cabeça (slider) e, se ambos estiverem
-- ocultos, a primeira parte visível. Os pesos são suavizados, então a câmera não salta.
local Aim = { model = nil, wH = 0, wT = 1, wO = 0, key = nil }

local function aimWeights(en)
	local parts = en.sk.parts
	local head = parts.head
	local tKey = parts.torso and "torso" or (parts.root and "root" or nil)
	local bias = S.AimBias / 100
	local hv = head ~= nil and (not S.WallCheck or partVisible(en, "head"))
	local tv = tKey ~= nil and (not S.WallCheck or partVisible(en, tKey))
	if hv and tv then return bias, 1 - bias, 0, nil end
	if hv then return 1, 0, 0, nil end
	if tv then return 0, 1, 0, nil end
	for _, k in ipairs(SKEL_KEYS) do
		if parts[k] and partVisible(en, k) then return 0, 0, 1, k end
	end
	return nil -- nada visível: mantém os pesos atuais (a trava continua na última mira)
end

local function updateAimPoint(en, dt)
	local wH, wT, wO, key = aimWeights(en)
	if Aim.model ~= en.m then
		Aim.model = en.m
		if wH then
			Aim.wH, Aim.wT, Aim.wO, Aim.key = wH, wT, wO, key
		else
			Aim.wH, Aim.wT, Aim.wO, Aim.key = 0, 1, 0, nil
		end
	elseif wH then
		local k = 1 - math.exp(-TUNING.WeightRate * dt)
		Aim.wH += (wH - Aim.wH) * k
		Aim.wT += (wT - Aim.wT) * k
		Aim.wO += (wO - Aim.wO) * k
		if key then Aim.key = key end
	end
	local parts = en.sk.parts
	local pT = (parts.torso or parts.root or parts.head).Position
	local pH = parts.head and parts.head.Position or pT
	local pO = (Aim.key and parts[Aim.key]) and parts[Aim.key].Position or pT
	local sum = Aim.wH + Aim.wT + Aim.wO
	if sum < 1e-3 then
		en.aim = pT
	else
		en.aim = (pH * Aim.wH + pT * Aim.wT + pO * Aim.wO) / sum
	end
end

-- ═══ AÇÕES ═══
local actions = {}
function actions.pick() pick = true end
function actions.release()
	setTarget(nil, os.clock())
	holdOff = os.clock() + 1
	toast("Alvo solto")
end

-- ═══ ABAS ═══
local pMira, pEsp, pFiltros, pConfig = tabs[1].page, tabs[2].page, tabs[3].page, tabs[4].page

section(pMira, "Diagnóstico")
local diagLabel = infoCard(pMira)
section(pMira, "Sistema")
toggle(pMira, "Sistema ativo", "Enabled")
toggle(pMira, "Câmera acompanha o alvo", "Lock")
toggle(pMira, "Seleção automática", "Auto", "Desligado = manual (botão ALVO)")
toggle(pMira, "Mostrar círculo", "ShowFov")
section(pMira, "Círculo e câmera")
slider(pMira, "Tamanho do círculo", "Radius", 8, 48, "%")
slider(pMira, "Suavidade da câmera", "Smooth", 0, 95, "%", 5)
slider(pMira, "Tolerância de saída", "Tol", 0, 80, " px", 4)
section(pMira, "Esqueleto")
slider(pMira, "Ponto de mira (tronco ↔ cabeça)", "AimBias", 0, 100, "%", 5)
toggle(pMira, "Persistência por esqueleto", "SkelPersist", "Qualquer parte no círculo mantém o alvo")
section(pMira, "Alvo")
button(pMira, "Selecionar alvo no círculo", true, actions.pick, "target")
button(pMira, "Limpar alvo", false, actions.release, "close")

section(pEsp, "Geral")
toggle(pEsp, "ESP ativo", "ESP")
slider(pEsp, "Alcance do ESP", "EspDist", 50, 1500, " st", 50)
section(pEsp, "Elementos")
toggle(pEsp, "Caixas", "Box")
toggle(pEsp, "Nomes", "Name")
toggle(pEsp, "Distância", "Dist")
toggle(pEsp, "Barra de vida", "Health")
toggle(pEsp, "Linhas (tracers)", "Tracer")
toggle(pEsp, "Marcador do ponto de mira", "AimDot")

section(pFiltros, "Validade")
toggle(pFiltros, "Ignorar aliados", "Team", "Desligue se todos estão na mesma equipe")
slider(pFiltros, "Distância máxima", "MaxDist", 50, 2000, " st", 25)
section(pFiltros, "Persistência do alvo")
toggle(pFiltros, "Exigir linha de visão", "WallCheck", "Paredes atrasam a troca")
slider(pFiltros, "Tolerância de obstrução", "ObstructTol", 0.2, 3, " s", 0.1)
slider(pFiltros, "Intervalo entre trocas", "MinSwitch", 0.5, 5, " s", 0.1)
slider(pFiltros, "Vantagem para trocar", "AdvPct", 10, 80, "%", 5)

section(pConfig, "Botões na tela")
toggle(pConfig, "Mostrar LOCK / ALVO", "Hud", "Arraste para reposicionar")
slider(pConfig, "Tamanho dos botões", "HudScale", 70, 150, "%", 5)
section(pConfig, "Geral")
button(pConfig, "Restaurar padrões", false, function()
	for k, v in pairs(DEFAULT) do
		S[k] = v
		if refresh[k] then refresh[k](true) end
	end
	toast("Padrões restaurados")
end, "reset")

selectTab(1, true)

-- ═══ MINIMIZAR / FECHAR ═══
local float = new("TextButton", {
	AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(54, 54), Position = UDim2.fromOffset(38, 64),
	BackgroundColor3 = C.bg, Text = "", AutoButtonColor = false, Visible = false,
}, gui)
round(float, 27); stroke(float, C.green, 2, 0.1)
local floatIcon = makeIcon("target", float, 26, C.green)
floatIcon.root.AnchorPoint = Vector2.new(0.5, 0.5)
floatIcon.root.Position = UDim2.fromScale(0.5, 0.5)
local floatScale = new("UIScale", { Scale = 0 }, float)

local shown = true
local function setShown(v)
	if v == shown then return end
	shown = v
	if v then
		UI.root.Visible = true
		tw(UI.winScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		tw(floatScale, { Scale = 0 }, 0.15)
		task.delay(0.16, function() if shown then float.Visible = false end end)
	else
		tw(UI.winScale, { Scale = 0 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.21, function() if not shown then UI.root.Visible = false end end)
		float.Visible = true
		tw(floatScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	end
end
drag(UI.header, UI.root)
drag(float, float, function() setShown(true) end)
conn(minBtn.Activated:Connect(function() setShown(false) end))

local function shutdown()
	pcall(function() RunService:UnbindFromRenderStep(STEP) end)
	pcall(function() pulseTween:Cancel() end)
	for _, c in ipairs(conns) do c:Disconnect() end
	gui:Destroy()
end
local armed = false
conn(closeBtn.Activated:Connect(function()
	if armed then shutdown() return end
	armed = true
	toast("Toque em × novamente para fechar")
	task.delay(2.2, function() armed = false end)
end))
conn(UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightControl then setShown(not shown) end
end))

-- ═══ BOTÕES NA TELA (LOCK / ALVO) ═══
local function hudBtn(kind, text, y, fn)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(vp0.X - 52, y), Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = C.bg, BackgroundTransparency = 0.1, Text = "", AutoButtonColor = false, Visible = S.Hud,
	}, gui)
	round(b, 32)
	local st = stroke(b, C.muted, 2, 0.3)
	local ic = makeIcon(kind, b, 22, C.muted)
	ic.root.AnchorPoint = Vector2.new(0.5, 0)
	ic.root.Position = UDim2.new(0.5, 0, 0, 11)
	local lbl = new("TextLabel", {
		Position = UDim2.new(0, 0, 1, -23), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = text,
		Font = F.bold, TextSize = 10, TextColor3 = C.muted, Active = false,
	}, b)
	local sc = pressScale(b)
	drag(b, b, fn)
	return { btn = b, stroke = st, scale = sc, icon = ic, label = lbl }
end
local hudLock = hudBtn("lock", "LOCK", vp0.Y * 0.3, function()
	S.Lock = not S.Lock
	if refresh.Lock then refresh.Lock() end
	toast(S.Lock and "Trava ativada" or "Trava desativada")
end)
local hudTarget = hudBtn("target", "ALVO", vp0.Y * 0.3 + 78, function()
	if target then actions.release() else actions.pick() end
end)

local lastVp = vp0
conn(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	local w, h, vp = metrics()
	if vp.X < 1 then return end
	local rx, ry = vp.X / lastVp.X, vp.Y / lastVp.Y
	lastVp = vp
	UI.root.Size = UDim2.fromOffset(w, h)
	for _, o in ipairs({ UI.root, float, hudLock.btn, hudTarget.btn }) do
		o.Position = UDim2.fromOffset(o.Position.X.Offset * rx, o.Position.Y.Offset * ry)
		clampToScreen(o)
	end
	selectTab(table.find(tabs, (function()
		for _, t in ipairs(tabs) do if t.page.Visible then return t end end
		return tabs[1]
	end)()) or 1, true)
end))

-- ═══ PERSONAGENS VÁLIDOS ═══
-- Alguns jogos não preenchem Player.Character na partida (personagem customizado).
-- Fallback: procura um Model com o nome do jogador (1x por segundo, escalonado).
local charCache = {}
local function characterOf(p)
	local c = p.Character
	if c and c.Parent then return c end
	local e = charCache[p]
	if not e then
		e = { m = nil, t = ctx.now - 1 + math.random() }
		charCache[p] = e
	end
	if e.m and not e.m.Parent then e.m = nil end
	if ctx.now - e.t >= 1 then
		e.t = ctx.now
		local found = WS:FindFirstChild(p.Name, true)
		if found and found:IsA("Model") and found:FindFirstChildOfClass("Humanoid") then
			e.m = found
		else
			e.m = nil
		end
	end
	return e.m
end
conn(Players.PlayerRemoving:Connect(function(p) charCache[p] = nil end))

-- Revalidado TODO frame: vivo, esqueleto resolvido, não é você e não é aliado.
local function listTargets()
	local out, seen = {}, {}
	stats.players, stats.noChar, stats.dead, stats.ally, stats.noPart, stats.valid = 0, 0, 0, 0, 0, 0
	local function add(m, p)
		if seen[m] or m == lp.Character or not m.Parent then return end
		seen[m] = true
		local hum = m:FindFirstChildOfClass("Humanoid")
		if not hum then stats.noPart += 1 return end
		local sk = getSkeleton(m)
		local anchor = sk.parts.root or sk.parts.torso or sk.parts.head
		if not anchor then stats.noPart += 1 return end
		if hum.Health <= 0 then stats.dead += 1 return end
		if S.Team and p and lp.Team and p.Team == lp.Team then stats.ally += 1 return end
		out[#out + 1] = { m = m, hum = hum, hrp = anchor, sk = sk, player = p }
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			stats.players += 1
			local c = characterOf(p)
			if c then add(c, p) else stats.noChar += 1 end
		end
	end
	for _, m in ipairs(CS:GetTagged("AuthorizedTarget")) do
		if m:IsA("Model") then add(m, Players:GetPlayerFromCharacter(m)) end
	end
	stats.valid = #out
	return out
end

-- ═══ ESP ═══
local esp = {}
local function espFor(m)
	local e = esp[m]
	if e then return e end
	local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = false }, UI.espLayer)
	local box = new("Frame", { BackgroundTransparency = 1, Active = false }, holder)
	local function label(ay)
		return new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, ay), Size = UDim2.fromOffset(180, 16), BackgroundTransparency = 1,
			Font = F.bold, TextSize = 13, TextStrokeTransparency = 0.45, Active = false,
		}, holder)
	end
	local hb = new("Frame", { AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Active = false }, holder)
	local hf = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BackgroundColor3 = C.green, BorderSizePixel = 0, Active = false }, hb)
	e = {
		holder = holder, box = box, st = stroke(box, C.text, 1.5, 0), nm = label(1), ds = label(0), hb = hb, hf = hf,
		tr = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Active = false }, holder), nmText = "", dsText = "",
	}
	esp[m] = e
	return e
end

local function drawEsp(cam, list)
	local alive = {}
	if S.ESP then
		table.sort(list, function(a, b) return a.dist < b.dist end)
		local vp, n = cam.ViewportSize, 0
		for _, en in ipairs(list) do
			if en.dist <= S.EspDist and (n < 12 or en.m == target) then
				n += 1
				local e = espFor(en.m)
				alive[en.m] = true
				local pos = en.hrp.Position
				local top = cam:WorldToViewportPoint(pos + Vector3.new(0, 2.8, 0))
				local bot = cam:WorldToViewportPoint(pos - Vector3.new(0, 3.1, 0))
				if top.Z > 0 and bot.Z > 0 then
					e.holder.Visible = true
					local isT = en.m == target
					local col = isT and C.green or C.text
					local h = math.abs(bot.Y - top.Y)
					local w = h * 0.55
					local cx, y0 = (top.X + bot.X) / 2, math.min(top.Y, bot.Y)
					local y1 = y0 + h

					e.box.Visible = S.Box
					e.box.Position = UDim2.fromOffset(cx - w / 2, y0)
					e.box.Size = UDim2.fromOffset(w, h)
					e.st.Color, e.st.Thickness = col, isT and 2.25 or 1.5

					e.nm.Visible = S.Name
					e.nm.Position = UDim2.fromOffset(cx, y0 - 3)
					e.nm.TextColor3 = col
					local nmText = en.player and en.player.DisplayName or en.m.Name
					if e.nmText ~= nmText then e.nmText = nmText; e.nm.Text = nmText end

					e.ds.Visible = S.Dist
					e.ds.Position = UDim2.fromOffset(cx, y1 + 3)
					e.ds.TextColor3 = col
					local dsText = math.floor(en.dist) .. " st"
					if e.dsText ~= dsText then e.dsText = dsText; e.ds.Text = dsText end

					e.hb.Visible = S.Health
					if S.Health then
						local ratio = en.hum.MaxHealth > 0 and math.clamp(en.hum.Health / en.hum.MaxHealth, 0, 1) or 0
						e.hb.Position = UDim2.fromOffset(cx - w / 2 - 5, y0)
						e.hb.Size = UDim2.fromOffset(3, h)
						e.hf.Size = UDim2.fromScale(1, ratio)
						e.hf.BackgroundColor3 = C.red:Lerp(C.green, ratio)
					end

					e.tr.Visible = S.Tracer
					if S.Tracer then
						local from, to = Vector2.new(vp.X / 2, vp.Y), Vector2.new(cx, y1)
						local d = to - from
						e.tr.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
						e.tr.Size = UDim2.fromOffset(d.Magnitude, isT and 2 or 1)
						e.tr.Rotation = math.deg(math.atan2(d.Y, d.X))
						e.tr.BackgroundColor3 = col
						e.tr.BackgroundTransparency = isT and 0.1 or 0.5
					end
				else
					e.holder.Visible = false
				end
			end
		end
	end
	for m, e in pairs(esp) do
		if not alive[m] then e.holder:Destroy(); esp[m] = nil end
	end
end

-- ═══ TRAVA DE CÂMERA ═══
-- Mantém uma rotação PRÓPRIA (Lock.rot) que persegue o ponto de mira com suavização
-- exponencial (independente de FPS, com limite de velocidade angular). O resultado final
-- mistura a rotação que a câmera do jogo produziu neste frame com a nossa, por um "peso"
-- com easing: entrar e soltar a trava nunca causa puxão. Funciona com câmera Custom e Scriptable.
local MAX_TURN = math.rad(540)

local function updateCameraLock(cam, dt, cur)
	local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	local alive = not (hum and hum.Health <= 0)
	local want = alive and S.Lock and cur ~= nil

	if want then Lock.weight = math.min(1, Lock.weight + dt / 0.35)
	else Lock.weight = math.max(0, Lock.weight - dt / 0.25) end

	if want then
		local p = cur.aim or cur.hrp.Position
		Lock.aim = Lock.aim and Lock.aim:Lerp(p, 1 - math.exp(-TUNING.AimFilter * dt)) or p
	end

	if Lock.weight <= 0 or not Lock.aim then
		resetLock()
		return
	end

	local base = cam.CFrame
	local pos = base.Position
	if not Lock.rot then Lock.rot = base.Rotation end

	local off = Lock.aim - pos
	if off.Magnitude > 1 then
		local d = off.Unit
		if math.abs(d.Y) > 0.94 then -- limita a inclinação (~70°)
			local flat = Vector3.new(d.X, 0, d.Z)
			if flat.Magnitude < 1e-3 then
				d = nil
			else
				d = flat.Unit * 0.342 + Vector3.new(0, math.sign(d.Y) * 0.94, 0)
			end
		end
		if d then
			local ang = math.acos(math.clamp(Lock.rot.LookVector:Dot(d), -1, 1))
			if ang > math.rad(0.1) then
				local rate = 2 + 38 * (1 - S.Smooth / 100) ^ 2
				local a = math.min(1 - math.exp(-rate * dt), MAX_TURN * dt / ang)
				Lock.rot = Lock.rot:Lerp(CFrame.lookAt(Vector3.zero, d), a)
			end
		end
	end

	local e = Lock.weight * Lock.weight * (3 - 2 * Lock.weight) -- smoothstep
	Lock.final = base.Rotation:Lerp(Lock.rot, e)
	Lock.active = true
	cam.CFrame = CFrame.new(pos) * Lock.final
end

-- ═══ LOOP PRINCIPAL ═══
local cache = { sub = "", lock = -1, tgt = -1, scale = -1, diagT = 0, mode = "" }

local function update(dt)
	local cam = WS.CurrentCamera
	if not cam then return end
	dt = math.min(dt, 0.1)
	local now = os.clock()
	local vp = cam.ViewportSize
	local center = vp / 2
	ctx.now, ctx.cam, ctx.center = now, cam, center
	local r = S.Radius / 100 * math.min(vp.X, vp.Y)

	UI.circle.Size = UDim2.fromOffset(r * 2, r * 2)
	UI.circle.Visible = S.Enabled and S.ShowFov
	UI.circleStroke.Color = target and C.green or Color3.fromRGB(40, 200, 105)
	UI.circleStroke.Transparency = target and 0.05 or 0.35

	local list = (S.Enabled or S.ESP) and listTargets() or {}
	local camCF = cam.CFrame
	local camPos, look = camCF.Position, camCF.LookVector
	ctx.camPos = camPos

	local byModel = {}
	stats.inRange, stats.inCircle, stats.blocked = 0, 0, 0
	table.clear(rayBase)
	if lp.Character then rayBase[1] = lp.Character end
	local bias = S.AimBias / 100
	for _, en in ipairs(list) do
		local parts = en.sk.parts
		local torsoPart = parts.torso or parts.root or parts.head
		local headPart = parts.head or torsoPart
		-- âncora de seleção: tronco ↔ cabeça pelo slider (estável e precisa)
		local anchor = torsoPart.Position:Lerp(headPart.Position, bias)
		local off = anchor - camPos
		local dist = off.Magnitude
		en.dist = (en.hrp.Position - camPos).Magnitude
		en.ang = dist > 0.01 and math.deg(math.acos(math.clamp(look:Dot(off / dist), -1, 1))) or 0
		local v = cam:WorldToViewportPoint(anchor)
		en.sd = v.Z > 0 and (Vector2.new(v.X, v.Y) - center).Magnitude or math.huge
		byModel[en.m] = en
		rayBase[#rayBase + 1] = en.m
	end
	for _, en in ipairs(list) do
		if en.dist <= S.MaxDist then
			stats.inRange += 1
			if en.sd <= r then
				stats.inCircle += 1
				if S.WallCheck and S.Enabled and not visibleCore(en) then stats.blocked += 1 end
			end
		end
	end
	for m in pairs(skelCache) do if not byModel[m] then skelCache[m] = nil end end
	for m, t in pairs(dropped) do
		if now - t > 10 or not byModel[m] then dropped[m] = nil end
	end

	local cur
	if S.Enabled then
		cur = selectTarget(list, byModel, r, dt, now)
	else
		setTarget(nil, now)
		pick = false
	end

	if cur then updateAimPoint(cur, dt) else Aim.model = nil end
	updateCameraLock(cam, dt, cur)
	drawEsp(cam, list)

	-- Marcador do ponto de mira (onde a câmera realmente está mirando)
	local showDot = false
	if S.AimDot and S.Enabled and cur and Lock.aim then
		local v = cam:WorldToViewportPoint(Lock.aim)
		if v.Z > 0 then
			UI.aimDot.Position = UDim2.fromOffset(v.X, v.Y)
			showDot = true
		end
	end
	UI.aimDot.Visible = showDot

	-- Status do cabeçalho (ponto colorido + pulso quando travado)
	local text, col, pulse
	if not S.Enabled then
		text, col, pulse = "Desligado", C.muted, false
	elseif target and cur then
		local nm = cur.player and cur.player.DisplayName or cur.m.Name
		if cur.blocked then
			text, col, pulse = "Obstruído · " .. nm, C.amber, false
		else
			local locked = Lock.weight > 0.5
			text, col, pulse = (locked and "Travado · " or "Alvo · ") .. nm, C.green, locked
		end
	else
		text, col, pulse = "Pronto · sem alvo", C.muted, false
	end
	if text ~= cache.sub then
		cache.sub = text
		UI.sub.Text = text
		UI.sub.TextColor3 = col
		tw(UI.dot, { BackgroundColor3 = col }, 0.2)
		UI.pulse.BackgroundColor3 = col
		UI.pulse.Visible = pulse
	end

	-- Diagnóstico (4x por segundo)
	if now - cache.diagT > 0.25 then
		cache.diagT = now
		local sum = Aim.wH + Aim.wT + Aim.wO
		local mira = "—"
		if cur and sum > 1e-3 then
			mira = string.format("cabeça %d%% · tronco %d%%%s", Aim.wH / sum * 100, Aim.wT / sum * 100,
				Aim.wO / sum > 0.05 and (" · " .. (Aim.key or "?")) or "")
		end
		diagLabel.Text = string.format(
			"Jogadores: %d · válidos: %d\nAliados ignorados: %d · sem personagem: %d · mortos: %d · sem parte: %d\nNo alcance: %d · no círculo: %d · bloqueados: %d\nCâmera: %s · alvo: %s\nMira: %s",
			stats.players, stats.valid, stats.ally, stats.noChar, stats.dead, stats.noPart,
			stats.inRange, stats.inCircle, stats.blocked, cam.CameraType.Name, target and target.Name or "nenhum", mira)
	end

	-- Botões na tela
	hudLock.btn.Visible = S.Hud
	hudTarget.btn.Visible = S.Hud and not S.Auto
	if cache.scale ~= S.HudScale then
		cache.scale = S.HudScale
		hudLock.scale.Scale, hudTarget.scale.Scale = S.HudScale / 100, S.HudScale / 100
	end
	local ls = (S.Enabled and S.Lock) and ((Lock.weight > 0.5) and 2 or 1) or 0
	if ls ~= cache.lock then
		cache.lock = ls
		local fg = ls == 2 and C.bg or (ls == 1 and C.green or C.muted)
		tw(hudLock.btn, { BackgroundColor3 = ls == 2 and C.green or C.bg }, 0.2)
		tw(hudLock.label, { TextColor3 = fg }, 0.2)
		tw(hudLock.stroke, { Color = ls == 0 and C.muted or C.green, Transparency = ls == 2 and 0 or 0.35 }, 0.2)
		hudLock.icon.setColor(fg)
	end
	local ts = target and 1 or 0
	if ts ~= cache.tgt then
		cache.tgt = ts
		local fg = ts == 1 and C.bg or C.green
		hudTarget.label.Text = ts == 1 and "SOLTAR" or "ALVO"
		tw(hudTarget.btn, { BackgroundColor3 = ts == 1 and C.green or C.bg }, 0.2)
		tw(hudTarget.label, { TextColor3 = fg }, 0.2)
		tw(hudTarget.stroke, { Color = C.green, Transparency = ts == 1 and 0 or 0.35 }, 0.2)
		hudTarget.icon.setColor(fg)
	end
end

-- Roda no ÚLTIMO passo de renderização: depois da câmera padrão e de câmeras da partida
-- ligadas por BindToRenderStep.
RunService:BindToRenderStep(STEP, Enum.RenderPriority.Last.Value, function(dt)
	local ok, err = pcall(update, dt)
	if not ok then warn("[Obsidian] " .. tostring(err)) end
end)

-- Reaplica a rotação da trava em RenderStepped: se uma câmera da partida escrever
-- DEPOIS do passo acima, a trava não é apagada (funciona em qualquer ordem).
conn(RunService.RenderStepped:Connect(function()
	local cam = WS.CurrentCamera
	if cam and Lock.active and Lock.final then
		cam.CFrame = CFrame.new(cam.CFrame.Position) * Lock.final
	end
end))

-- ═══ EVENTOS: transição lobby → partida, respawn, equipe, câmera ═══
conn(lp.CharacterAdded:Connect(function()
	resetLock()
	setTarget(nil, os.clock())
end))
conn(lp.CharacterRemoving:Connect(function()
	resetLock()
	setTarget(nil, os.clock())
end))
conn(lp:GetPropertyChangedSignal("Team"):Connect(function()
	setTarget(nil, os.clock()) -- revalida equipes do zero
end))
conn(WS:GetPropertyChangedSignal("CurrentCamera"):Connect(resetLock))

tw(UI.winScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
toast("OBSIDIAN carregado")
