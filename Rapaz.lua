-- OBSIDIAN Lite: círculo + trava de câmera suave + ESP simples (LocalScript)
-- Alvos: outros jogadores (respeita equipe) e NPCs com a tag "AuthorizedTarget".
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CS = game:GetService("CollectionService")
local WS = game:GetService("Workspace")
local lp = Players.LocalPlayer

local GREEN = Color3.fromRGB(46, 255, 126)
local GRAY = Color3.fromRGB(22, 24, 26)
local MUTED = Color3.fromRGB(130, 136, 142)
local WHITE = Color3.fromRGB(236, 241, 238)
local STEP = "ObsidianLite"

-- Configurações (a interface altera estes valores)
local S = {
	Enabled = true, -- sistema ligado
	Lock = true,    -- câmera acompanha o alvo
	Auto = true,    -- seleção automática (desligado = manual)
	ESP = true,
	Team = true,    -- ignora mesma equipe
	Radius = 25,    -- tamanho do círculo (% do menor lado da tela)
	Smooth = 60,    -- suavidade da câmera (%)
	Tol = 24,       -- tolerância de saída do círculo (px)
	MaxDist = 300,  -- alcance (studs)
}

-- Limpeza ao reexecutar / fechar
pcall(function() RunService:UnbindFromRenderStep(STEP) end)
local old = lp.PlayerGui:FindFirstChild("ObsidianLite")
if old then old:Destroy() end
local conns = {}
local function conn(c) conns[#conns + 1] = c return c end

-- Helpers de UI
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) end

local gui = new("ScreenGui", { Name = "ObsidianLite", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10 }, lp.PlayerGui)
local espLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = false }, gui)

local circle = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1, Active = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, circle)
local circleStroke = new("UIStroke", { Color = GREEN, Thickness = 1.5, Transparency = 0.2 }, circle)

-- Janela (Active = true: tocar nela NÃO gira a câmera)
local vp0 = WS.CurrentCamera.ViewportSize
local W = math.clamp(vp0.X * 0.6, 260, 320)
local bodyH = math.clamp(vp0.Y * 0.55, 160, 300)
local win = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(W, 40 + bodyH), BackgroundColor3 = Color3.new(0, 0, 0),
	BorderSizePixel = 0, Active = true, ClipsDescendants = true,
}, gui)
round(win, 12)
new("UIStroke", { Color = GREEN, Transparency = 0.5 }, win)

local header = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Active = true }, win)
new("TextLabel", {
	Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
	Text = "OBSIDIAN", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = GREEN,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local function headerBtn(text, x, color)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(34, 30),
		BackgroundColor3 = GRAY, Text = text, Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = color,
	}, header)
	round(b, 8)
	return b
end
local closeBtn = headerBtn("×", -6, Color3.fromRGB(255, 82, 82))
local minBtn = headerBtn("–", -46, WHITE)

local body = new("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, Active = true,
}, win)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, body)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, body)

-- Arrastar a janela pelo cabeçalho
do
	local drag, start, pos
	conn(header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag, start, pos = i, i.Position, win.Position
		end
	end))
	conn(UIS.InputChanged:Connect(function(i)
		if drag and (i == drag or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - start
			win.Position = UDim2.new(pos.X.Scale, pos.X.Offset + d.X, pos.Y.Scale, pos.Y.Offset + d.Y)
		end
	end))
	conn(UIS.InputEnded:Connect(function(i)
		if drag and (i == drag or (drag.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1)) then
			drag = nil
		end
	end))
end

-- Minimizar / fechar
local minimized = false
conn(minBtn.Activated:Connect(function()
	minimized = not minimized
	body.Visible = not minimized
	win.Size = UDim2.fromOffset(W, minimized and 40 or 40 + bodyH)
end))
local function close()
	pcall(function() RunService:UnbindFromRenderStep(STEP) end)
	for _, c in ipairs(conns) do c:Disconnect() end
	gui:Destroy()
end
conn(closeBtn.Activated:Connect(close))

-- Componentes
local order = 0
local function nextOrder() order += 1 return order end

local function toggle(name, key)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = GRAY, Font = Enum.Font.GothamMedium,
		TextSize = 16, AutoButtonColor = false, LayoutOrder = nextOrder(),
	}, body)
	round(b)
	local function refresh()
		b.Text = name .. ":  " .. (S[key] and "ON" or "OFF")
		b.TextColor3 = S[key] and GREEN or MUTED
	end
	refresh()
	conn(b.Activated:Connect(function() S[key] = not S[key]; refresh() end))
	return refresh
end

local function slider(name, key, min, max)
	local row = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = GRAY, Text = "", AutoButtonColor = false, LayoutOrder = nextOrder(),
	}, body)
	round(row)
	local label = new("TextLabel", {
		Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 2), BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local fill = new("Frame", { Position = UDim2.new(0, 8, 1, -12), Size = UDim2.fromOffset(0, 5), BackgroundColor3 = GREEN, BorderSizePixel = 0 }, row)
	local function refresh()
		label.Text = name .. ": " .. S[key]
		fill.Size = UDim2.new((S[key] - min) / (max - min), -16 * ((S[key] - min) / (max - min)), 0, 5)
	end
	refresh()
	local drag
	local function set(x)
		local a = math.clamp((x - row.AbsolutePosition.X) / row.AbsoluteSize.X, 0, 1)
		S[key] = math.floor(min + (max - min) * a + 0.5)
		refresh()
	end
	conn(row.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = i
			body.ScrollingEnabled = false -- não rola a lista enquanto ajusta
			set(i.Position.X)
		end
	end))
	conn(UIS.InputChanged:Connect(function(i)
		if drag and (i == drag or i.UserInputType == Enum.UserInputType.MouseMovement) then set(i.Position.X) end
	end))
	conn(UIS.InputEnded:Connect(function(i)
		if drag and (i == drag or (drag.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1)) then
			drag = nil
			body.ScrollingEnabled = true
		end
	end))
end

local wantPick = false
local function button(name, fn)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = GRAY, Text = name, Font = Enum.Font.GothamBold,
		TextSize = 16, TextColor3 = GREEN, AutoButtonColor = false, LayoutOrder = nextOrder(),
	}, body)
	round(b)
	conn(b.Activated:Connect(fn))
end

toggle("Sistema", "Enabled")
local refreshLock = toggle("Câmera acompanha", "Lock")
toggle("Seleção automática", "Auto")
toggle("ESP", "ESP")
toggle("Ignorar equipe", "Team")
slider("Tamanho do círculo (%)", "Radius", 8, 48)
slider("Suavidade da câmera (%)", "Smooth", 0, 95)
slider("Tolerância de saída (px)", "Tol", 0, 80)
slider("Alcance (studs)", "MaxDist", 50, 1000)
button("Selecionar alvo (manual)", function() wantPick = true end)

-- Botão LOCK na tela (lado direito, acima do botão de pulo)
local hud = new("TextButton", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -52, 0.3, 0), Size = UDim2.fromOffset(64, 64),
	BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.15, Text = "LOCK",
	Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, hud)
local hudStroke = new("UIStroke", { Thickness = 2 }, hud)
conn(hud.Activated:Connect(function() S.Lock = not S.Lock; refreshLock() end))

-- Lógica de alvos
local function valid(m, p)
	if not m or not m.Parent or m == lp.Character then return false end
	local h = m:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 or not m:FindFirstChild("HumanoidRootPart") then return false end
	if S.Team and p and lp.Team and p.Team == lp.Team then return false end
	return true
end

local function listTargets()
	local t, seen = {}, {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if p ~= lp and c and valid(c, p) then t[#t + 1] = c; seen[c] = true end
	end
	for _, m in ipairs(CS:GetTagged("AuthorizedTarget")) do
		if m:IsA("Model") and not seen[m] and valid(m, nil) then t[#t + 1] = m end
	end
	return t
end

-- ESP (um Frame por personagem)
local esp = {}
local function drawEsp(cam, targets, target)
	local alive = {}
	if S.ESP then
		for _, m in ipairs(targets) do
			local pos = m.HumanoidRootPart.Position
			local e = esp[m]
			if not e then
				local box = new("Frame", { BackgroundTransparency = 1, Active = false }, espLayer)
				local st = new("UIStroke", { Thickness = 1.5 }, box)
				local lb = new("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(180, 16),
					BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextStrokeTransparency = 0.5,
				}, box)
				e = { box = box, st = st, lb = lb }
				esp[m] = e
			end
			alive[m] = true
			local top = cam:WorldToViewportPoint(pos + Vector3.new(0, 2.8, 0))
			local bot = cam:WorldToViewportPoint(pos - Vector3.new(0, 3.1, 0))
			if top.Z > 0 and bot.Z > 0 then
				local h = math.abs(bot.Y - top.Y)
				local w = h * 0.55
				local col = (m == target) and GREEN or WHITE
				e.box.Visible = true
				e.box.Position = UDim2.fromOffset((top.X + bot.X) / 2 - w / 2, math.min(top.Y, bot.Y))
				e.box.Size = UDim2.fromOffset(w, h)
				e.st.Color = col
				e.lb.TextColor3 = col
				local p = Players:GetPlayerFromCharacter(m)
				e.lb.Text = (p and p.DisplayName or m.Name) .. " · " .. math.floor((pos - cam.CFrame.Position).Magnitude) .. "st"
			else
				e.box.Visible = false
			end
		end
	end
	for m, e in pairs(esp) do
		if not alive[m] then e.box:Destroy(); esp[m] = nil end
	end
end

-- Loop principal (logo depois da câmera padrão)
local target, lost, weight, aim = nil, 0, 0, nil

local function update(dt)
	local cam = WS.CurrentCamera
	if not cam then return end
	dt = math.min(dt, 0.1)

	local vp = cam.ViewportSize
	local center = vp / 2
	local r = S.Radius / 100 * math.min(vp.X, vp.Y)
	circle.Size = UDim2.fromOffset(r * 2, r * 2)
	circle.Visible = S.Enabled
	circleStroke.Color = target and GREEN or Color3.fromRGB(46, 200, 110)
	hud.TextColor3 = S.Lock and GREEN or MUTED
	hudStroke.Color = S.Lock and GREEN or MUTED

	local targets = S.Enabled and listTargets() or {}
	local function screenDist(m)
		local v = cam:WorldToViewportPoint(m.HumanoidRootPart.Position)
		if v.Z <= 0 then return math.huge end
		return (Vector2.new(v.X, v.Y) - center).Magnitude
	end
	local function worldDist(m)
		return (m.HumanoidRootPart.Position - cam.CFrame.Position).Magnitude
	end

	-- Mantém o alvo enquanto válido e dentro do círculo + tolerância (com 0,2 s de graça)
	if target then
		local ok = table.find(targets, target) ~= nil
		if ok and screenDist(target) <= r + S.Tol and worldDist(target) <= S.MaxDist * 1.05 then
			lost = 0
		else
			lost += dt
		end
		if not ok or lost > 0.2 then target, lost = nil, 0 end
	end

	-- Escolhe o mais próximo do centro (automático ou pelo botão manual)
	if not target and (S.Auto or wantPick) then
		local best, bestD = nil, r
		for _, m in ipairs(targets) do
			local d = screenDist(m)
			if d <= bestD and worldDist(m) <= S.MaxDist then best, bestD = m, d end
		end
		target = best
	end
	wantPick = false

	-- Trava de câmera suave (peso sobe/desce = sem puxão ao entrar ou soltar)
	local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	local can = cam.CameraType == Enum.CameraType.Custom and hum ~= nil and hum.Health > 0
	local want = can and S.Lock and target ~= nil
	if want then weight = math.min(1, weight + dt / 0.35) else weight = math.max(0, weight - dt / 0.25) end
	if want then
		local p = target.HumanoidRootPart.Position
		aim = aim and aim:Lerp(p, 1 - math.exp(-28 * dt)) or p
	end

	if not can then
		weight, aim = 0, nil
	elseif weight <= 0 then
		aim = nil
	elseif aim then
		local e = weight * weight * (3 - 2 * weight)
		local cf = cam.CFrame
		local off = aim - cf.Position
		if off.Magnitude > 1 then
			local d = off.Unit
			d = Vector3.new(d.X, math.clamp(d.Y, -0.94, 0.94), d.Z).Unit -- limita inclinação
			local ang = math.acos(math.clamp(cf.LookVector:Dot(d), -1, 1))
			if ang > 0.002 then
				local rate = 2 + 38 * (1 - S.Smooth / 100) ^ 2
				local a = math.min((1 - math.exp(-rate * dt)) * e, 9.4 * dt / ang) -- limite de velocidade
				cam.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, cf.Position + d), a)
			end
		end
	end

	drawEsp(cam, targets, target)
end

RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value + 1, function(dt)
	local ok, err = pcall(update, dt)
	if not ok then warn("[Obsidian] " .. tostring(err)) end
end)
