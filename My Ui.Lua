-- MyUI.lua v2
-- 改良点:
--  1. 見た目をObsidianに寄せる（角丸・枠線・アクセント・フォント統一）
--  2. ドラッグを確実に効かせる（InputBegan/Changed/Ended + タッチ対応）
--  3. 右下リサイズハンドル＋最小化ボタン
--  4. タブ切り替え・スクロール・ドロップダウンのはみ出し修正

local UIS = game:GetService("UserInputService")
local TS  = game:GetService("TweenService")
local Players = game:GetService("Players")

local Theme = {
    Bg      = Color3.fromRGB(15, 12, 17),
    Panel   = Color3.fromRGB(24, 19, 27),
    Panel2  = Color3.fromRGB(33, 26, 37),
    Accent  = Color3.fromRGB(232, 44, 56),
    Accent2 = Color3.fromRGB(180, 30, 40),
    Outline = Color3.fromRGB(60, 48, 62),
    Text    = Color3.fromRGB(245, 240, 245),
    Muted   = Color3.fromRGB(150, 135, 150),
    Font    = Enum.Font.Gotham,
    FontBold= Enum.Font.GothamBold,
}

local UI = {}
local function corner(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke") s.Color=c or Theme.Outline s.Thickness=t or 1 s.Parent=p return s end
local function pad(p,a) local u=Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,a); u.PaddingBottom=UDim.new(0,a); u.PaddingLeft=UDim.new(0,a); u.PaddingRight=UDim.new(0,a); u.Parent=p end
local function newList(p, gap, order)
    local l=Instance.new("UIListLayout")
    l.Padding=UDim.new(0,gap or 6); l.SortOrder=order or Enum.SortOrder.LayoutOrder; l.Parent=p; return l end
local function tween(obj, props, t)
    TS:Create(obj, TweenInfo.new(t or 0.15), props):Play()
end

-- ============ Window ============
function UI:CreateWindow(o)
    o = o or {}
    local gui = Instance.new("ScreenGui")
    gui.Name = o.Name or "MyUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    -- ルート（リサイズでサイズが変わる）
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 600, 0, 420)
    main.Position = UDim2.new(0.5, -300, 0.5, -210)
    main.BackgroundColor3 = Theme.Bg
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Active = true
    main.Parent = gui
    corner(main, 14); stroke(main, Theme.Outline, 1.5)

    -- タイトルバー
    local bar = Instance.new("Frame")
    bar.Name = "TitleBar"
    bar.Size = UDim2.new(1, 0, 0, 40)
    bar.BackgroundColor3 = Theme.Panel
    bar.BorderSizePixel = 0
    bar.Active = true
    bar.Parent = main
    corner(bar, 14)

    -- タイトルドット
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 16, 0.5, -4)
    dot.BackgroundColor3 = Theme.Accent
    dot.BorderSizePixel = 0
    dot.Parent = bar
    corner(dot, 4)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -160, 1, 0)
    title.Position = UDim2.new(0, 32, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = o.Title or "My UI"
    title.TextColor3 = Theme.Text
    title.Font = Theme.FontBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = bar

    -- 最小化ボタン
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Position = UDim2.new(1, -72, 0.5, -13)
    minBtn.BackgroundColor3 = Theme.Bg
    minBtn.Text = "—"
    minBtn.TextColor3 = Theme.Muted
    minBtn.Font = Theme.Font
    minBtn.TextSize = 16
    minBtn.AutoButtonColor = false
    minBtn.Parent = bar
    corner(minBtn, 6)
    minBtn.MouseEnter:Connect(function() tween(minBtn, {BackgroundColor3 = Theme.Panel2, TextColor3 = Theme.Text}) end)
    minBtn.MouseLeave:Connect(function() tween(minBtn, {BackgroundColor3 = Theme.Bg, TextColor3 = Theme.Muted}) end)

    -- 閉じるボタン
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 26, 0, 26)
    close.Position = UDim2.new(1, -38, 0.5, -13)
    close.BackgroundColor3 = Theme.Bg
    close.Text = "×"
    close.TextColor3 = Theme.Muted
    close.Font = Theme.Font
    close.TextSize = 18
    close.AutoButtonColor = false
    close.Parent = bar
    corner(close, 6)
    close.MouseEnter:Connect(function() tween(close, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text}) end)
    close.MouseLeave:Connect(function() tween(close, {BackgroundColor3 = Theme.Bg, TextColor3 = Theme.Muted}) end)
    close.MouseButton1Click:Connect(function() gui:Destroy() end)

    -- ===== ドラッグ（タッチ・マウス両対応） =====
    local function startDrag(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
           and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local dStart = input.Position
        local sPos = main.Position
        local moveConn, endConn
        moveConn = UIS.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement
               or i.UserInputType == Enum.UserInputType.Touch then
                local d = i.Position - dStart
                main.Position = UDim2.new(
                    sPos.X.Scale, sPos.X.Offset + d.X,
                    sPos.Y.Scale, sPos.Y.Offset + d.Y
                )
            end
        end)
        endConn = UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
               or i.UserInputType == Enum.UserInputType.Touch then
                moveConn:Disconnect(); endConn:Disconnect()
            end
        end)
    end
    bar.InputBegan:Connect(startDrag)

    -- ===== リサイズハンドル =====
    local resize = Instance.new("Frame")
    resize.Name = "ResizeHandle"
    resize.Size = UDim2.new(0, 16, 0, 16)
    resize.Position = UDim2.new(1, -16, 1, -16)
    resize.BackgroundTransparency = 1
    resize.Parent = main

    local grip = Instance.new("TextLabel")
    grip.Size = UDim2.new(1, 0, 1, 0)
    grip.BackgroundTransparency = 1
    grip.Text = "◢"
    grip.TextColor3 = Theme.Outline
    grip.TextSize = 14
    grip.Font = Theme.Font
    grip.Parent = resize

    local resizing = false
    local function startResize(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
           and input.UserInputType ~= Enum.UserInputType.Touch then return end
        resizing = true
        local dStart = input.Position
        local sSize = main.AbsoluteSize
        local sPos = main.AbsolutePosition
        local moveConn, endConn
        moveConn = UIS.InputChanged:Connect(function(i)
            if not resizing then return end
            if i.UserInputType == Enum.UserInputType.MouseMovement
               or i.UserInputType == Enum.UserInputType.Touch then
                local d = i.Position - dStart
                local w = math.clamp(sSize.X + d.X, 420, 1000)
                local h = math.clamp(sSize.Y + d.Y, 260, 700)
                main.Size = UDim2.new(0, w, 0, h)
            end
        end)
        endConn = UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
               or i.UserInputType == Enum.UserInputType.Touch then
                resizing = false
                moveConn:Disconnect(); endConn:Disconnect()
            end
        end)
    end
    resize.InputBegan:Connect(startResize)

    -- ===== 最小化 =====
    local minimized = false
    local bodyHolder = Instance.new("Frame")
    bodyHolder.Name = "Body"
    bodyHolder.Size = UDim2.new(1, 0, 1, -40)
    bodyHolder.Position = UDim2.new(0, 0, 0, 40)
    bodyHolder.BackgroundTransparency = 1
    bodyHolder.ClipsDescendants = true
    bodyHolder.Parent = main

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            main.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, 40)
            bodyHolder.Visible = false
        else
            main.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, 420)
            bodyHolder.Visible = true
        end
    end)

    -- ===== サイドバー =====
    local side = Instance.new("Frame")
    side.Size = UDim2.new(0, 150, 1, 0)
    side.BackgroundColor3 = Theme.Panel
    side.BorderSizePixel = 0
    side.Parent = bodyHolder
    newList(side, 4)
    pad(side, 8)

    -- ===== コンテンツ =====
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -150, 1, 0)
    content.Position = UDim2.new(0, 150, 0, 0)
    content.BackgroundTransparency = 1
    content.Parent = bodyHolder

    local pages, tabs, order, tabButtons = {}, {}, 0, {}
    local function selectTab(name)
        for n,p in pairs(pages) do p.Visible = (n == name) end
        for n,b in pairs(tabButtons) do
            local active = (n == name)
            tween(b, {BackgroundColor3 = active and Theme.Accent or Theme.Bg})
            b.TextColor3 = active and Theme.Text or Theme.Muted
        end
    end

    function tabs:AddTab(name)
        order = order + 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = Theme.Bg
        btn.BorderSizePixel = 0
        btn.Text = name
        btn.TextColor3 = Theme.Muted
        btn.Font = Theme.Font
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.LayoutOrder = order
        btn.Parent = side
        corner(btn, 8)
        local bp = Instance.new("UIPadding"); bp.PaddingLeft = UDim.new(0, 10); bp.Parent = btn
        tabButtons[name] = btn

        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, -20, 1, -20)
        page.Position = UDim2.new(0, 10, 0, 10)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = content
        pages[name] = page

        btn.MouseButton1Click:Connect(function() selectTab(name) end)

        local tabObj = {}
        function tabObj:AddGroup(t, s) return UI:CreateGroup(page, t, s) end
        function tabObj:AddGroupFull(t) return UI:CreateGroup(page, t, "Full") end
        return tabObj
    end

    task.defer(function()
        local first = next(pages)
        if first then selectTab(first) end
    end)

    return {AddTab = function(_, name) return tabs:AddTab(name) end, Gui = gui, Frame = main}
end

-- ============ Group ============
function UI:CreateGroup(page, title, sideName)
    local box = Instance.new("Frame")
    if sideName == "Full" then
        box.Size = UDim2.new(1, 0, 1, 0)
        box.Position = UDim2.new(0, 0, 0, 0)
    elseif sideName == "Right" then
        box.Size = UDim2.new(0.5, -6, 1, 0)
        box.Position = UDim2.new(0.5, 6, 0, 0)
    else
        box.Size = UDim2.new(0.5, -6, 1, 0)
        box.Position = UDim2.new(0, 0, 0, 0)
    end
    box.BackgroundColor3 = Theme.Panel
    box.BorderSizePixel = 0
    box.ClipsDescendants = true
    box.Parent = page
    corner(box, 10); stroke(box, Theme.Outline, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 26)
    lbl.Position = UDim2.new(0, 10, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Theme.Accent
    lbl.Font = Theme.FontBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = box

    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -20, 0, 1)
    sep.Position = UDim2.new(0, 10, 0, 34)
    sep.BackgroundColor3 = Theme.Outline
    sep.BackgroundTransparency = 0.5
    sep.BorderSizePixel = 0
    sep.Parent = box

    local holder = Instance.new("ScrollingFrame")
    holder.Size = UDim2.new(1, -16, 1, -44)
    holder.Position = UDim2.new(0, 8, 0, 42)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.ScrollBarThickness = 3
    holder.ScrollBarImageColor3 = Theme.Accent
    holder.CanvasSize = UDim2.new(0, 0, 0, 0)
    holder.AutomaticCanvasSize = Enum.AutomaticSize.Y
    holder.Parent = box
    newList(holder, 6)
    pad(holder, 4)

    local G, gOrder = {}, 0
    local function nextO() gOrder = gOrder + 1 return gOrder end

    function G:AddToggle(text, default, cb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextO()
        row.Parent = holder

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -50, 1, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Theme.Text
        l.Font = Theme.Font
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = row

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 38, 0, 20)
        knob.Position = UDim2.new(1, -42, 0.5, -10)
        knob.BackgroundColor3 = default and Theme.Accent or Theme.Panel2
        knob.BorderSizePixel = 0
        knob.Parent = row
        corner(knob, 10); stroke(knob, Theme.Outline, 1)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 16, 0, 16)
        dot.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        dot.BackgroundColor3 = Theme.Text
        dot.BorderSizePixel = 0
        dot.Parent = knob
        corner(dot, 8)

        local state = default
        local click = Instance.new("TextButton")
        click.Size = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text = ""
        click.Parent = row
        click.MouseButton1Click:Connect(function()
            state = not state
            tween(knob, {BackgroundColor3 = state and Theme.Accent or Theme.Panel2})
            tween(dot, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
            if cb then cb(state) end
        end)
    end

    function G:AddSlider(text, default, min, max, cb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextO()
        row.Parent = holder

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -60, 0, 18)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Theme.Text
        l.Font = Theme.Font
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = row

        local vl = Instance.new("TextLabel")
        vl.Size = UDim2.new(0, 50, 0, 18)
        vl.Position = UDim2.new(1, -50, 0, 0)
        vl.BackgroundTransparency = 1
        vl.Text = tostring(default)
        vl.TextColor3 = Theme.Accent
        vl.Font = Theme.FontBold
        vl.TextSize = 13
        vl.TextXAlignment = Enum.TextXAlignment.Right
        vl.Parent = row

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 6)
        track.Position = UDim2.new(0, 0, 0, 26)
        track.BackgroundColor3 = Theme.Panel2
        track.BorderSizePixel = 0
        track.Parent = row
        corner(track, 3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        corner(fill, 3)

        local dragging = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + (max - min) * rel + 0.5)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            vl.Text = tostring(v)
            if cb then cb(v) end
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; update(i.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                update(i.Position.X)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    function G:AddButton(text, cb)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = Theme.Panel2
        btn.Text = text
        btn.TextColor3 = Theme.Text
        btn.Font = Theme.Font
        btn.TextSize = 13
        btn.AutoButtonColor = false
        btn.LayoutOrder = nextO()
        btn.Parent = holder
        corner(btn, 8); stroke(btn, Theme.Outline, 1)
        btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.Accent}) end)
        btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Theme.Panel2}) end)
        btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    end

    function G:AddDropdown(text, options, default, cb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextO()
        row.Parent = holder

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = Theme.Panel2
        btn.Text = text .. "  ▾"
        btn.TextColor3 = Theme.Text
        btn.Font = Theme.Font
        btn.TextSize = 13
        btn.AutoButtonColor = false
        btn.Parent = row
        corner(btn, 8); stroke(btn, Theme.Outline, 1)

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, #options * 26 + 8)
        list.Position = UDim2.new(0, 0, 1, 4)
        list.BackgroundColor3 = Theme.Panel
        list.BorderSizePixel = 0
        list.Visible = false
        list.ZIndex = 20
        list.Parent = row
        corner(list, 8); stroke(list, Theme.Outline, 1)
        newList(list, 2)
        pad(list, 4)

        for _, opt in ipairs(options) do
            local o = Instance.new("TextButton")
            o.Size = UDim2.new(1, 0, 0, 22)
            o.BackgroundColor3 = Theme.Bg
            o.Text = opt
            o.TextColor3 = Theme.Text
            o.Font = Theme.Font
            o.TextSize = 12
            o.AutoButtonColor = false
            o.Parent = list
            corner(o, 4)
            o.MouseEnter:Connect(function() tween(o, {BackgroundColor3 = Theme.Accent}) end)
            o.MouseLeave:Connect(function() tween(o, {BackgroundColor3 = Theme.Bg}) end)
            o.MouseButton1Click:Connect(function()
                btn.Text = text .. " : " .. opt .. "  ▾"
                list.Visible = false
                if cb then cb(opt) end
            end)
        end

        btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    end

    function G:AddLabel(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 22)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Theme.Muted
        l.Font = Theme.Font
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = nextO()
        l.Parent = holder
    end

    function G:AddTextbox(text, placeholder, cb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextO()
        row.Parent = holder

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, 0, 1, 0)
        box.BackgroundColor3 = Theme.Panel2
        box.BorderSizePixel = 0
        box.Text = ""
        box.PlaceholderText = text .. (placeholder and (" ("..placeholder..")") or "")
        box.PlaceholderColor3 = Theme.Muted
        box.TextColor3 = Theme.Text
        box.Font = Theme.Font
        box.TextSize = 13
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.Parent = row
        corner(box, 8); stroke(box, Theme.Outline, 1)
        local bp = Instance.new("UIPadding"); bp.PaddingLeft = UDim.new(0, 10); bp.Parent = box
        box.Focused:Connect(function() tween(box, {BackgroundColor3 = Theme.Panel}) end)
        box.FocusLost:Connect(function()
            tween(box, {BackgroundColor3 = Theme.Panel2})
            if cb then cb(box.Text) end
        end)
    end

    return G
end

-- ============ Notify ============
function UI:Notify(title, desc, duration)
    local gui = Instance.new("ScreenGui")
    gui.Name = "MyUINotify"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(0, 280, 0, 0)
    holder.Position = UDim2.new(1, -300, 0, 20)
    holder.BackgroundTransparency = 1
    holder.Parent = gui
    newList(holder, 6, Enum.SortOrder.LayoutOrder)

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Theme.Panel
    card.BorderSizePixel = 0
    card.Parent = holder
    corner(card, 10); stroke(card, Theme.Outline, 1)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.BackgroundColor3 = Theme.Accent
    accent.BorderSizePixel = 0
    accent.Parent = card
    corner(accent, 2)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 0, 24)
    t.Position = UDim2.new(0, 14, 0, 8)
    t.BackgroundTransparency = 1
    t.Text = title or "通知"
    t.TextColor3 = Theme.Text
    t.Font = Theme.FontBold
    t.TextSize = 13
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = card

    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -20, 0, 20)
    d.Position = UDim2.new(0, 14, 0, 30)
    d.BackgroundTransparency = 1
    d.Text = desc or ""
    d.TextColor3 = Theme.Muted
    d.Font = Theme.Font
    d.TextSize = 12
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.Parent = card

    card.Size = UDim2.new(1, 0, 0, 0)
    tween(card, {Size = UDim2.new(1, 0, 0, 60)}, 0.2)
    task.delay(duration or 4, function()
        tween(card, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
        task.wait(0.25)
        gui:Destroy()
    end)
end

return UI
