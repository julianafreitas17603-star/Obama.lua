-- OBSIDIAN Pro v2.3 — trava funciona no lobby e na partida (LocalScript)
-- Alvos: outros jogadores (respeita equipe) e NPCs com a tag "AuthorizedTarget".
-- Local: StarterPlayer > StarterPlayerScripts (LocalScript). Se lobby e partida forem
-- places diferentes, o script precisa estar nos dois.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local CS = game:GetService("CollectionService")
local WS = game:GetService("Workspace")
local lp = Players.LocalPlayer
local IS_TOUCH = UIS.TouchEnabled
local STEP = "ObsidianPro"

-- ═══ TEMA ═══
local C = {
	bg = Color3.fromRGB(0, 0, 0),
	bg2 = Color3.fromRGB(14, 16, 17),
	card = Color3.fromRGB(19, 22, 23),
	card2 = Color3.fromRGB(30, 34, 36),
	line = Color3.fromRGB(40, 45, 47),
	green = Color3.fromRGB(46, 255, 126),
	greenDim = Color3.fromRGB(16, 100, 54),
	text = Color3.fromRGB(238, 243, 240),
	muted = Color3.fromRGB(125, 134, 139),
	red = Color3.fromRGB(255, 82, 82),
}
local GOTHAM, GOTHAM_B = Enum.Font.GothamMedium, Enum.Font.GothamBold

-- ═══ CONFIGURAÇÕES ═══
local S = {
	Enabled = true, Lock = true, Auto = true, ShowFov = true,
	Radius = 25,       -- círculo: % do menor lado da tela
	Smooth = 60,       -- suavidade da câmera (%)
	Tol = 24,          -- tolerância de saída do círculo (px)
	MaxDist = 700,     -- distância máxima (studs)
	Team = true,       -- nunca selecionar aliados
	WallCheck = false, -- LIGUE só se precisar; paredes/barreiras da partida podem bloquear tudo
	ObstructTol = 0.8, -- s de obstrução tolerados antes de soltar o alvo
	MinSwitch = 1.5,   -- s mínimos entre trocas voluntárias
	AdvPct = 35,       -- % de vantagem angular para troca antecipada
	ESP = true, Box = true, Name = true, Dist = true, Health = true, Tracer = false,
	EspDist = 500,
	Hud = IS_TOUCH, HudScale = 100,
}
local DEFAULT = table.clone(S)
local refresh = {}

local TUNING = {
	OutGrace = 0.2, RangeMargin = 1.05, TieDeg = 0.25, AbsAdvDeg = 2.5,
	BlockedPenalty = 10, OutsidePenalty = 5, LosInterval = 0.1,
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
-- Se algum script da partida remover/mover a interface, tenta reanexar.
conn(gui.AncestryChanged:Connect(function()
	if not gui:IsDescendantOf(game) then
		pcall(function() gui.Parent = lp.PlayerGui end)
	end
end))

local espLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = false }, gui)
local circle = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Active = false }, gui)
round(circle, 9999)
local circleStroke = stroke(circle, C.green, 1.5, 0.2)

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

-- ═══ JANELA ═══
local function metrics()
	local vp = vpSize()
	local portrait = vp.X < vp.Y
	local w = portrait and math.clamp(vp.X * 0.94, 250, 380) or math.clamp(vp.X * (IS_TOUCH and 0.52 or 0.9), 290, 380)
	local h = portrait and math.clamp(vp.Y * 0.6, 300, 480) or math.clamp(vp.Y - 20, 270, 480)
	return w, h, vp
end
local W, H, vp0 = metrics()

local win = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	Position = UDim2.fromOffset(vp0.X / 2, IS_TOUCH and (H / 2 + 10) or (vp0.Y / 2)),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = true, ClipsDescendants = true,
}, gui)
round(win, 16)
grad(win, C.bg2, C.bg, 90)
local winStroke = stroke(win, C.green, 1, 0.45)
grad(winStroke, C.green, C.greenDim, 45)
local winScale = new("UIScale", { Scale = 0.9 }, win)
local topLine = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, win)
new("UIGradient", {
	Color = ColorSequence.new(C.green), Rotation = 0,
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
}, topLine)

local header = new("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Active = true }, win)
local badge = new("Frame", { Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, header)
round(badge, 11)
grad(badge, Color3.fromRGB(90, 255, 160), Color3.fromRGB(20, 190, 95), 135)
new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "O", Font = GOTHAM_B, TextSize = 20, TextColor3 = C.bg }, badge)
new("TextLabel", {
	Position = UDim2.fromOffset(58, 8), Size = UDim2.new(1, -150, 0, 20), BackgroundTransparency = 1, Text = "OBSIDIAN",
	Font = GOTHAM_B, TextSize = 17, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
}, header)
local sub = new("TextLabel", {
	Position = UDim2.fromOffset(58, 29), Size = UDim2.new(1, -150, 0, 16), BackgroundTransparency = 1, Text = "Pronto · sem alvo",
	Font = GOTHAM, TextSize = 12, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, header)

local function hBtn(text, x, col)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = C.card, Text = text, Font = GOTHAM_B, TextSize = 20, TextColor3 = col, AutoButtonColor = false,
	}, header)
	round(b, 10); stroke(b, C.line, 1, 0)
	pressScale(b)
	return b
end
local closeBtn = hBtn("×", -10, C.red)
local minBtn = hBtn("–", -50, C.text)

local TABS = { "Mira", "ESP", "Filtros", "Config" }
local tabBar = new("Frame", { Position = UDim2.fromOffset(12, 58), Size = UDim2.new(1, -24, 0, 38), BackgroundColor3 = C.card, BorderSizePixel = 0, Active = true }, win)
round(tabBar, 12); stroke(tabBar, C.line, 1, 0)
local indicator = new("Frame", {
	Position = UDim2.new(0, 3, 0, 3), Size = UDim2.new(1 / #TABS, -6, 1, -6),
	BackgroundColor3 = C.green, BackgroundTransparency = 0.85, BorderSizePixel = 0,
}, tabBar)
round(indicator, 9); stroke(indicator, C.green, 1, 0.3)

local pages, tabBtns = {}, {}
local function selectTab(i, instant)
	for j, p in ipairs(pages) do
		p.Visible = (j == i)
		tw(tabBtns[j], { TextColor3 = (j == i) and C.green or C.muted }, instant and 0 or 0.15)
	end
	tw(indicator, { Position = UDim2.new((i - 1) / #TABS, 3, 0, 3) }, instant and 0 or 0.28, Enum.EasingStyle.Quint)
	if not instant then
		pages[i].Position = UDim2.fromOffset(0, 114)
		tw(pages[i], { Position = UDim2.fromOffset(0, 102) }, 0.25, Enum.EasingStyle.Quint)
	end
end
for i, name in ipairs(TABS) do
	local b = new("TextButton", {
		Position = UDim2.fromScale((i - 1) / #TABS, 0), Size = UDim2.fromScale(1 / #TABS, 1), BackgroundTransparency = 1,
		Text = name, Font = GOTHAM_B, TextSize = 14, TextColor3 = C.muted, AutoButtonColor = false, ZIndex = 2,
	}, tabBar)
	tabBtns[i] = b
	local p = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 102), Size = UDim2.new(1, 0, 1, -102), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.green, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Active = true, Visible = false,
	}, win)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, p)
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, p)
	pages[i] = p
	conn(b.Activated:Connect(function() selectTab(i) end))
end

-- ═══ COMPONENTES ═══
local orders = {}
local function ord(page) orders[page] = (orders[page] or 0) + 1 return orders[page] end

local function section(page, text)
	local f = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = ord(page) }, page)
	local bar = new("Frame", { Position = UDim2.fromOffset(2, 6), Size = UDim2.fromOffset(3, 11), BackgroundColor3 = C.green, BorderSizePixel = 0 }, f)
	round(bar, 2)
	new("TextLabel", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0), BackgroundTransparency = 1, Text = string.upper(text),
		Font = GOTHAM_B, TextSize = 12, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
end

local function infoCard(page)
	local l = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card, Text = "…",
		Font = GOTHAM, TextSize = 12, TextColor3 = C.muted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = ord(page),
	}, page)
	round(l, 12); stroke(l, C.line, 1, 0)
	new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, l)
	return l
end

local function toggle(page, name, key, desc)
	local h = desc and 58 or 50
	local row = new("TextButton", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.card, Text = "", AutoButtonColor = false, LayoutOrder = ord(page) }, page)
	round(row, 12)
	local rs = stroke(row, C.line, 1, 0)
	new("TextLabel", {
		Position = UDim2.fromOffset(14, desc and 9 or 0), Size = UDim2.new(1, -84, 0, desc and 20 or h), BackgroundTransparency = 1,
		Text = name, Font = GOTHAM, TextSize = 15, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
	if desc then
		new("TextLabel", {
			Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -84, 0, 18), BackgroundTransparency = 1, Text = desc,
			Font = GOTHAM, TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
	end
	local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(48, 26), BackgroundColor3 = C.card2, BorderSizePixel = 0 }, row)
	round(track, 13)
	local ts = stroke(track, C.line, 1, 0)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = C.muted, BorderSizePixel = 0 }, track)
	round(knob, 10)
	local function render(instant)
		local on, t = S[key], instant and 0 or 0.2
		tw(track, { BackgroundColor3 = on and C.green or C.card2 }, t)
		tw(ts, { Color = on and C.green or C.line }, t)
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
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = C.card, LayoutOrder = ord(page) }, page)
	round(row, 12); stroke(row, C.line, 1, 0)
	new("TextLabel", {
		Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -100, 0, 22), BackgroundTransparency = 1, Text = name,
		Font = GOTHAM, TextSize = 15, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
	local chip = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(70, 22),
		BackgroundColor3 = C.greenDim, BackgroundTransparency = 0.55, Font = GOTHAM_B, TextSize = 13, TextColor3 = C.green,
	}, row)
	round(chip, 7)
	local track = new("Frame", { Position = UDim2.new(0, 14, 0, 45), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = C.card2, BorderSizePixel = 0 }, row)
	round(track, 3)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, track)
	round(fill, 3); grad(fill, Color3.fromRGB(20, 190, 95), C.green, 0)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = C.text, BorderSizePixel = 0 }, track)
	round(knob, 10); stroke(knob, C.green, 2, 0)
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

local function button(page, text, primary, fn)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = primary and Color3.new(1, 1, 1) or C.card, Text = text,
		Font = GOTHAM_B, TextSize = 15, TextColor3 = primary and C.bg or C.green, AutoButtonColor = false, LayoutOrder = ord(page),
	}, page)
	round(b, 12)
	if primary then grad(b, Color3.fromRGB(80, 255, 155), Color3.fromRGB(20, 200, 100), 90) else stroke(b, C.green, 1, 0.5) end
	pressScale(b)
	conn(b.Activated:Connect(fn))
end

local toastObj
local function toast(msg)
	if toastObj then toastObj:Destroy() end
	local g = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.fromOffset(0, 38),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.card, GroupTransparency = 1, Active = false, ZIndex = 50,
	}, gui)
	round(g, 19); stroke(g, C.green, 1, 0.4)
	new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, g)
	new("TextLabel", {
		Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = msg,
		Font = GOTHAM_B, TextSize = 14, TextColor3 = C.text,
	}, g)
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
local ctx = { camPos = Vector3.zero, now = 0 }
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
local losCache = {}

local function setTarget(en, now)
	local newModel = en and en.m or nil
	if newModel ~= target then
		if target then dropped[target] = now end
		target = newModel
		lastSwitch = now
		outTime, blockTime = 0, 0
	end
end

--- Há cenário sólido entre a câmera e o alvo? Partes quase invisíveis (>= 0.9) são ignoradas.
local function lineBlocked(en)
	local filter = table.clone(rayBase)
	rayParams.FilterDescendantsInstances = filter
	local origin = ctx.camPos
	local dir = en.hrp.Position - origin
	for _ = 1, 4 do
		local hit = WS:Raycast(origin, dir, rayParams)
		if not hit then return false end
		if hit.Instance.Transparency < 0.9 then return true end
		filter[#filter + 1] = hit.Instance
		rayParams.FilterDescendantsInstances = filter
	end
	return true
end

local function visible(en)
	if not S.WallCheck then return true end
	if en.vis ~= nil then return en.vis end
	local c = losCache[en.m]
	if c and ctx.now - c.t < TUNING.LosInterval then
		en.vis = c.ok
		return c.ok
	end
	local ok = not lineBlocked(en)
	losCache[en.m] = { t = ctx.now, ok = ok }
	en.vis = ok
	return ok
end

local function eligible(en, r)
	return en.sd <= r and en.dist <= S.MaxDist and visible(en)
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
			cur.blocked = S.WallCheck and not visible(cur)
			blockTime = cur.blocked and (blockTime + dt) or 0 -- volta a ficar visível → zera
			outTime = (cur.sd > r + S.Tol) and (outTime + dt) or 0
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

local actions = {}
function actions.pick() pick = true end
function actions.release()
	setTarget(nil, os.clock())
	holdOff = os.clock() + 1
	toast("Alvo solto")
end

-- ═══ ABAS ═══
local pMira, pEsp, pFiltros, pConfig = pages[1], pages[2], pages[3], pages[4]

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
section(pMira, "Alvo")
button(pMira, "Selecionar alvo no círculo", true, actions.pick)
button(pMira, "Limpar alvo", false, actions.release)

section(pEsp, "Geral")
toggle(pEsp, "ESP ativo", "ESP")
slider(pEsp, "Alcance do ESP", "EspDist", 50, 1500, " st", 50)
section(pEsp, "Elementos")
toggle(pEsp, "Caixas", "Box")
toggle(pEsp, "Nomes", "Name")
toggle(pEsp, "Distância", "Dist")
toggle(pEsp, "Barra de vida", "Health")
toggle(pEsp, "Linhas (tracers)", "Tracer")

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
end)

selectTab(1, true)

-- ═══ MINIMIZAR / FECHAR ═══
local float = new("TextButton", {
	AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(38, 64),
	BackgroundColor3 = C.bg, Text = "O", Font = GOTHAM_B, TextSize = 22, TextColor3 = C.green, AutoButtonColor = false, Visible = false,
}, gui)
round(float, 26); stroke(float, C.green, 2, 0.1)
local floatScale = new("UIScale", { Scale = 0 }, float)

local shown = true
local function setShown(v)
	if v == shown then return end
	shown = v
	if v then
		win.Visible = true
		tw(winScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		tw(floatScale, { Scale = 0 }, 0.15)
		task.delay(0.16, function() if shown then float.Visible = false end end)
	else
		tw(winScale, { Scale = 0 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.21, function() if not shown then win.Visible = false end end)
		float.Visible = true
		tw(floatScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	end
end
drag(header, win)
drag(float, float, function() setShown(true) end)
conn(minBtn.Activated:Connect(function() setShown(false) end))

local function shutdown()
	pcall(function() RunService:UnbindFromRenderStep(STEP) end)
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

-- ═══ BOTÕES NA TELA ═══
local function hudBtn(text, y, fn)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(vp0.X - 52, y), Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = C.bg, BackgroundTransparency = 0.12, Text = text, Font = GOTHAM_B, TextSize = 13,
		TextColor3 = C.muted, AutoButtonColor = false, Visible = S.Hud,
	}, gui)
	round(b, 32)
	local st = stroke(b, C.muted, 2, 0.3)
	local sc = pressScale(b)
	drag(b, b, fn)
	return b, st, sc
end
local hudLock, hudLockStroke, hudLockScale = hudBtn("LOCK", vp0.Y * 0.3, function()
	S.Lock = not S.Lock
	if refresh.Lock then refresh.Lock() end
	toast(S.Lock and "Trava ativada" or "Trava desativada")
end)
local hudTarget, hudTargetStroke, hudTargetScale = hudBtn("ALVO", vp0.Y * 0.3 + 78, function()
	if target then actions.release() else actions.pick() end
end)

local lastVp = vp0
conn(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	local w, h, vp = metrics()
	if vp.X < 1 then return end
	local rx, ry = vp.X / lastVp.X, vp.Y / lastVp.Y
	lastVp = vp
	win.Size = UDim2.fromOffset(w, h)
	for _, o in ipairs({ win, float, hudLock, hudTarget }) do
		o.Position = UDim2.fromOffset(o.Position.X.Offset * rx, o.Position.Y.Offset * ry)
		clampToScreen(o)
	end
end))

-- ═══ PERSONAGENS VÁLIDOS ═══
local function aimPartOf(m)
	local names = { "HumanoidRootPart", "UpperTorso", "Torso", "Head" }
	for _, n in ipairs(names) do
		local p = m:FindFirstChild(n)
		if p and p:IsA("BasePart") then return p end
	end
	return m.PrimaryPart
end

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

-- Revalidado TODO frame: vivo, parte de mira, não é você e não é aliado.
local function listTargets()
	local out, seen = {}, {}
	stats.players, stats.noChar, stats.dead, stats.ally, stats.noPart, stats.valid = 0, 0, 0, 0, 0, 0
	local function add(m, p)
		if seen[m] or m == lp.Character or not m.Parent then return end
		seen[m] = true
		local hum = m:FindFirstChildOfClass("Humanoid")
		local part = aimPartOf(m)
		if not hum or not part then stats.noPart += 1 return end
		if hum.Health <= 0 then stats.dead += 1 return end
		if S.Team and p and lp.Team and p.Team == lp.Team then stats.ally += 1 return end
		out[#out + 1] = { m = m, hum = hum, hrp = part, player = p }
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
	local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = false }, espLayer)
	local box = new("Frame", { BackgroundTransparency = 1 }, holder)
	local function label(ay)
		return new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, ay), Size = UDim2.fromOffset(180, 16), BackgroundTransparency = 1,
			Font = GOTHAM_B, TextSize = 13, TextStrokeTransparency = 0.45,
		}, holder)
	end
	local hb = new("Frame", { AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0 }, holder)
	local hf = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BackgroundColor3 = C.green, BorderSizePixel = 0 }, hb)
	e = {
		holder = holder, box = box, st = stroke(box, C.text, 1.5, 0), nm = label(1), ds = label(0), hb = hb, hf = hf,
		tr = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0 }, holder), nmText = "", dsText = "",
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
-- Mantém uma rotação PRÓPRIA (Lock.rot) que persegue o alvo com suavização exponencial
-- (independente de FPS, com limite de velocidade angular). O resultado final mistura a
-- rotação que a câmera do jogo produziu neste frame com a nossa, por um "peso" com easing:
-- entrar e soltar a trava nunca causa puxão. Funciona com câmera Custom e Scriptable.
local MAX_TURN = math.rad(540)

local function updateCameraLock(cam, dt, cur)
	local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	local alive = not (hum and hum.Health <= 0)
	local want = alive and S.Lock and cur ~= nil

	if want then Lock.weight = math.min(1, Lock.weight + dt / 0.35)
	else Lock.weight = math.max(0, Lock.weight - dt / 0.25) end

	if want then
		local p = cur.hrp.Position
		Lock.aim = Lock.aim and Lock.aim:Lerp(p, 1 - math.exp(-28 * dt)) or p
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
local cache = { sub = "", lock = -1, tgt = -1, scale = -1, diagT = 0 }

local function update(dt)
	local cam = WS.CurrentCamera
	if not cam then return end
	dt = math.min(dt, 0.1)
	local now = os.clock()
	ctx.now = now

	local vp = cam.ViewportSize
	local center = vp / 2
	local r = S.Radius / 100 * math.min(vp.X, vp.Y)

	circle.Size = UDim2.fromOffset(r * 2, r * 2)
	circle.Visible = S.Enabled and S.ShowFov
	circleStroke.Color = target and C.green or Color3.fromRGB(40, 200, 105)
	circleStroke.Transparency = target and 0.05 or 0.35

	local list = (S.Enabled or S.ESP) and listTargets() or {}
	local camCF = cam.CFrame
	local camPos, look = camCF.Position, camCF.LookVector
	ctx.camPos = camPos

	local byModel = {}
	stats.inRange, stats.inCircle, stats.blocked = 0, 0, 0
	table.clear(rayBase)
	if lp.Character then rayBase[1] = lp.Character end
	for _, en in ipairs(list) do
		local p = en.hrp.Position
		local off = p - camPos
		en.dist = off.Magnitude
		en.ang = en.dist > 0.01 and math.deg(math.acos(math.clamp(look:Dot(off / en.dist), -1, 1))) or 0
		local v = cam:WorldToViewportPoint(p)
		en.sd = v.Z > 0 and (Vector2.new(v.X, v.Y) - center).Magnitude or math.huge
		byModel[en.m] = en
		rayBase[#rayBase + 1] = en.m
	end
	for _, en in ipairs(list) do
		if en.dist <= S.MaxDist then
			stats.inRange += 1
			if en.sd <= r then
				stats.inCircle += 1
				if S.WallCheck and S.Enabled and not visible(en) then stats.blocked += 1 end
			end
		end
	end
	for m in pairs(losCache) do if not byModel[m] then losCache[m] = nil end end
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

	updateCameraLock(cam, dt, cur)
	drawEsp(cam, list)

	-- Status
	local text, col
	if not S.Enabled then
		text, col = "Desligado", C.muted
	elseif target and cur then
		local nm = cur.player and cur.player.DisplayName or cur.m.Name
		if cur.blocked then
			text, col = "Obstruído · " .. nm, Color3.fromRGB(255, 200, 80)
		else
			text, col = ((Lock.weight > 0.5) and "Travado · " or "Alvo · ") .. nm, C.green
		end
	else
		text, col = "Pronto · sem alvo", C.muted
	end
	if text ~= cache.sub then cache.sub = text; sub.Text = text; sub.TextColor3 = col end

	-- Diagnóstico (4x por segundo)
	if now - cache.diagT > 0.25 then
		cache.diagT = now
		diagLabel.Text = string.format(
			"Jogadores: %d · válidos: %d\nAliados ignorados: %d · sem personagem: %d · mortos: %d · sem parte: %d\nNo alcance: %d · no círculo: %d · bloqueados: %d\nCâmera: %s · alvo: %s",
			stats.players, stats.valid, stats.ally, stats.noChar, stats.dead, stats.noPart,
			stats.inRange, stats.inCircle, stats.blocked, cam.CameraType.Name, target and target.Name or "nenhum")
	end

	-- Botões na tela
	hudLock.Visible = S.Hud
	hudTarget.Visible = S.Hud and not S.Auto
	if cache.scale ~= S.HudScale then
		cache.scale = S.HudScale
		hudLockScale.Scale, hudTargetScale.Scale = S.HudScale / 100, S.HudScale / 100
	end
	local ls = (S.Enabled and S.Lock) and ((Lock.weight > 0.5) and 2 or 1) or 0
	if ls ~= cache.lock then
		cache.lock = ls
		tw(hudLock, { BackgroundColor3 = ls == 2 and C.green or C.bg, TextColor3 = ls == 2 and C.bg or (ls == 1 and C.green or C.muted) }, 0.2)
		tw(hudLockStroke, { Color = ls == 0 and C.muted or C.green, Transparency = ls == 2 and 0 or 0.35 }, 0.2)
	end
	local ts = target and 1 or 0
	if ts ~= cache.tgt then
		cache.tgt = ts
		hudTarget.Text = ts == 1 and "SOLTAR" or "ALVO"
		tw(hudTarget, { BackgroundColor3 = ts == 1 and C.green or C.bg, TextColor3 = ts == 1 and C.bg or C.green }, 0.2)
		tw(hudTargetStroke, { Color = C.green, Transparency = ts == 1 and 0 or 0.35 }, 0.2)
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

tw(winScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
toast("OBSIDIAN carregado")
