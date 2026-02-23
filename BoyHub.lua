-- ==========================================
-- BOYHUB MEGA LIBRARY V20 (FIXED REFRESH BUG)
-- ==========================================

local AbangLibrary = {}
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function AbangLibrary:CreateWindow(Settings)
    local HubName = Settings.Name or "BoyHub"
    local SaveConfig = Settings.SaveConfig or false
    local ConfigFolder = Settings.ConfigFolder or "BoyHubConfig"
    AbangLibrary.Pengaturan = {}
    AbangLibrary.NamaFile = ConfigFolder .. ".json"

    if CoreGui:FindFirstChild(HubName) then CoreGui[HubName]:Destroy() end

    local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = HubName; ScreenGui.Parent = CoreGui; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    function AbangLibrary:Save()
        if SaveConfig and writefile then
            writefile(AbangLibrary.NamaFile, HttpService:JSONEncode(AbangLibrary.Pengaturan))
        end
    end

    function AbangLibrary:Load()
        if SaveConfig and readfile and isfile and isfile(AbangLibrary.NamaFile) then
            local s, res = pcall(function() return HttpService:JSONDecode(readfile(AbangLibrary.NamaFile)) end)
            if s then AbangLibrary.Pengaturan = res end
        end
    end
    AbangLibrary:Load()

    local p = Players.LocalPlayer
    local MiniLogo = Instance.new("ImageButton")
    MiniLogo.Size = UDim2.new(0, 50, 0, 50); MiniLogo.Position = UDim2.new(0, 20, 0, 20)
    MiniLogo.Image = "rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=150&h=150"
    MiniLogo.BackgroundColor3 = Color3.fromRGB(30, 30, 30); MiniLogo.Visible = false; MiniLogo.Parent = ScreenGui
    Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(1, 0); MakeDraggable(MiniLogo)

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 420, 0, 320); Main.Position = UDim2.new(0.5, -210, 0.5, -160)
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15); Main.BorderSizePixel = 0; Main.Parent = ScreenGui; Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12); MakeDraggable(Main)

    MiniLogo.MouseButton1Click:Connect(function() Main.Visible = true; MiniLogo.Visible = false end)

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 65); Header.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Header.BorderSizePixel = 0; Header.Parent = Main
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

    local pImg = Instance.new("ImageLabel")
    pImg.Size = UDim2.new(0, 45, 0, 45); pImg.Position = UDim2.new(0, 10, 0.5, -22)
    pImg.Image = "rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=150&h=150"
    pImg.BackgroundTransparency = 1; pImg.Parent = Header; Instance.new("UICorner", pImg).CornerRadius = UDim.new(1, 0)

    local pName = Instance.new("TextLabel")
    pName.Size = UDim2.new(1, -140, 0, 20); pName.Position = UDim2.new(0, 65, 0, 12); pName.Text = p.DisplayName; pName.TextColor3 = Color3.fromRGB(255, 255, 255); pName.Font = Enum.Font.GothamBold; pName.TextSize = 16; pName.TextXAlignment = Enum.TextXAlignment.Left; pName.BackgroundTransparency = 1; pName.Parent = Header

    local pStatus = Instance.new("TextLabel")
    pStatus.Size = UDim2.new(1, -140, 0, 20); pStatus.Position = UDim2.new(0, 65, 0, 30); pStatus.Text = "Status: " .. (Settings.UserStatus or "User")
    pStatus.TextColor3 = Settings.StatusColor or Color3.fromRGB(80, 255, 80); pStatus.Font = Enum.Font.GothamMedium; pStatus.TextSize = 13; pStatus.TextXAlignment = Enum.TextXAlignment.Left; pStatus.BackgroundTransparency = 1; pStatus.Parent = Header

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0, 15); CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 16; CloseBtn.Parent = Header
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -70, 0, 15); MinBtn.BackgroundTransparency = 1; MinBtn.Text = "—"; MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255); MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 16; MinBtn.Parent = Header
    MinBtn.MouseButton1Click:Connect(function() Main.Visible = false; MiniLogo.Visible = true end)

    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, 0, 1, -115); ContentArea.Position = UDim2.new(0, 0, 0, 65); ContentArea.BackgroundTransparency = 1; ContentArea.Parent = Main

    local BottomBar = Instance.new("ScrollingFrame")
    BottomBar.Size = UDim2.new(1, 0, 0, 50); BottomBar.Position = UDim2.new(0, 0, 1, -50); BottomBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); BottomBar.BorderSizePixel = 0; BottomBar.ScrollBarThickness = 0; BottomBar.Parent = Main
    local NavLayout = Instance.new("UIListLayout"); NavLayout.FillDirection = Enum.FillDirection.Horizontal; NavLayout.VerticalAlignment = Enum.VerticalAlignment.Center; NavLayout.Padding = UDim.new(0, 10); NavLayout.Parent = BottomBar
    Instance.new("UIPadding", BottomBar).PaddingLeft = UDim.new(0, 10)

    NavLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        BottomBar.CanvasSize = UDim2.new(0, NavLayout.AbsoluteContentSize.X + 20, 0, 0)
    end)

    local Window = {}
    Window.TabsCount = 0

    function Window:MakeTab(TabSettings)
        Window.TabsCount = Window.TabsCount + 1
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, -20, 1, -20); Page.Position = UDim2.new(0, 10, 0, 10); Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 2; Page.Parent = ContentArea
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder; PageLayout.Padding = UDim.new(0, 8); PageLayout.Parent = Page
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 15)
        end)

        local NavBtn = Instance.new("TextButton")
        NavBtn.Size = UDim2.new(0, 110, 0, 35); NavBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); NavBtn.Text = TabSettings.Name; NavBtn.TextColor3 = Color3.fromRGB(150, 150, 150); NavBtn.Font = Enum.Font.GothamBold; NavBtn.TextSize = 14; NavBtn.Parent = BottomBar; Instance.new("UICorner", NavBtn)

        NavBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(ContentArea:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _, v in pairs(BottomBar:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(150, 150, 150); v.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end end
            Page.Visible = true; NavBtn.TextColor3 = Color3.fromRGB(255, 255, 255); NavBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
        end)

        if Window.TabsCount == 1 then Page.Visible = true; NavBtn.TextColor3 = Color3.fromRGB(255, 255, 255); NavBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 255) end

        local Tab = {ItemCount = 0}

        function Tab:AddButton(Cfg)
            Tab.ItemCount = Tab.ItemCount + 1
            local f = Instance.new("TextButton"); f.Size = UDim2.new(1, 0, 0, 40); f.BackgroundColor3 = Color3.fromRGB(35, 35, 35); f.Text = Cfg.Name; f.TextColor3 = Color3.fromRGB(255, 255, 255); f.Font = Enum.Font.GothamBold; f.TextSize = 14; f.LayoutOrder = Tab.ItemCount; f.Parent = Page; Instance.new("UICorner", f); f.MouseButton1Click:Connect(Cfg.Callback)
        end

        function Tab:AddToggle(Cfg)
            Tab.ItemCount = Tab.ItemCount + 1
            local state = AbangLibrary.Pengaturan[Cfg.Flag] or Cfg.Default or false
            if Cfg.Flag then AbangLibrary.Pengaturan[Cfg.Flag] = state end
            
            local f = Instance.new("TextButton"); f.Size = UDim2.new(1, 0, 0, 45); f.BackgroundColor3 = Color3.fromRGB(35, 35, 35); f.Text = " "..Cfg.Name; f.TextColor3 = Color3.fromRGB(240,240,240); f.Font = Enum.Font.Gotham; f.TextSize = 14; f.TextXAlignment = Enum.TextXAlignment.Left; f.LayoutOrder = Tab.ItemCount; f.Parent = Page; Instance.new("UICorner", f)
            local s = Instance.new("Frame"); s.Size = UDim2.new(0, 40, 0, 20); s.Position = UDim2.new(1, -55, 0.5, -10); s.BackgroundColor3 = state and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80); s.Parent = f; Instance.new("UICorner", s).CornerRadius = UDim.new(1,0)
            local circle = Instance.new("Frame"); circle.Size = UDim2.new(0, 14, 0, 14); circle.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7); circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); circle.Parent = s; Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

            f.MouseButton1Click:Connect(function()
                state = not state; 
                if Cfg.Flag then AbangLibrary.Pengaturan[Cfg.Flag] = state; AbangLibrary:Save() end
                local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                TweenService:Create(s, tweenInfo, {BackgroundColor3 = state and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)}):Play()
                TweenService:Create(circle, tweenInfo, {Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}):Play()
                Cfg.Callback(state)
            end)
            task.spawn(function() Cfg.Callback(state) end)
        end

        function Tab:AddSlider(Cfg)
            Tab.ItemCount = Tab.ItemCount + 1
            local val = AbangLibrary.Pengaturan[Cfg.Flag] or Cfg.Default or Cfg.Min
            if Cfg.Flag then AbangLibrary.Pengaturan[Cfg.Flag] = val end
            
            local f = Instance.new("Frame"); f.Size = UDim2.new(1, 0, 0, 50); f.BackgroundColor3 = Color3.fromRGB(35, 35, 35); f.LayoutOrder = Tab.ItemCount; f.Parent = Page; Instance.new("UICorner", f)
            local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -20, 0, 25); l.Position = UDim2.new(0, 10, 0, 5); l.BackgroundTransparency = 1; l.Text = Cfg.Name.." : "..val; l.TextColor3 = Color3.fromRGB(255,255,255); l.Font = Enum.Font.Gotham; l.TextSize = 14; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
            local bar = Instance.new("TextButton"); bar.Size = UDim2.new(0.9, 0, 0, 6); bar.Position = UDim2.new(0.05, 0, 0.7, 0); bar.BackgroundColor3 = Color3.fromRGB(20,20,20); bar.Text = ""; bar.Parent = f; Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)
            local fill = Instance.new("Frame"); fill.Size = UDim2.new((val-Cfg.Min)/(Cfg.Max-Cfg.Min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(80, 160, 255); fill.Parent = bar; Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
            local dot = Instance.new("Frame"); dot.Size = UDim2.new(0, 14, 0, 14); dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.new(1, 0, 0.5, 0); dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); dot.Parent = fill; Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

            local function up(i)
                local p = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                val = math.floor(Cfg.Min + (Cfg.Max - Cfg.Min) * p)
                l.Text = Cfg.Name.." : "..val; fill.Size = UDim2.new(p, 0, 1, 0)
                if Cfg.Flag then AbangLibrary.Pengaturan[Cfg.Flag] = val; AbangLibrary:Save() end
                Cfg.Callback(val)
            end

            local drag = false
            bar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; up(i) end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then up(i) end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
            end)
            task.spawn(function() Cfg.Callback(val) end)
        end

        function Tab:AddDropdown(Cfg)
            Tab.ItemCount = Tab.ItemCount + 1
            local isMulti = Cfg.Multi or false
            local Options = Cfg.Options or {}
            local Default = (Cfg.Flag and AbangLibrary.Pengaturan[Cfg.Flag]) or Cfg.Default

            if isMulti then
                if type(Default) ~= "table" then Default = Default and {Default} or {} end
            else
                if type(Default) == "table" then Default = Default[1] or Options[1] else Default = Default or Options[1] end
            end
            
            if Cfg.Flag then AbangLibrary.Pengaturan[Cfg.Flag] = Default end
            local Selected = isMulti and Default or {Default}

            local function GetSelectedText()
                return (isMulti and (#Selected == 0 and "None" or table.concat(Selected, ", "))) or (Selected[1] or "None")
            end

            local f = Instance.new("Frame"); f.Size = UDim2.new(1, 0, 0, 45); f.BackgroundColor3 = Color3.fromRGB(35, 35, 35); f.LayoutOrder = Tab.ItemCount; f.Parent = Page; Instance.new("UICorner", f)
            local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.Gotham; btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.TextTruncate = Enum.TextTruncate.AtEnd; btn.Parent = f; btn.Text = " " .. Cfg.Name .. " : " .. GetSelectedText()

            local Modal = Instance.new("TextButton"); Modal.Size = UDim2.new(1, 0, 1, 0); Modal.BackgroundColor3 = Color3.fromRGB(0,0,0); Modal.BackgroundTransparency = 0.5; Modal.Visible = false; Modal.Text = ""; Modal.AutoButtonColor = false; Modal.ZIndex = 50; Modal.Parent = Main
            local Box = Instance.new("Frame"); Box.Size = UDim2.new(0, 260, 0, 250); Box.Position = UDim2.new(0.5, -130, 0.5, -125); Box.BackgroundColor3 = Color3.fromRGB(25,25,25); Box.ZIndex = 51; Box.Parent = Modal; Instance.new("UICorner", Box)
            local Search = Instance.new("TextBox"); Search.Size = UDim2.new(1, -20, 0, 35); Search.Position = UDim2.new(0, 10, 0, 10); Search.BackgroundColor3 = Color3.fromRGB(35, 35, 35); Search.PlaceholderText = "Cari..."; Search.Text = ""; Search.TextColor3 = Color3.fromRGB(255,255,255); Search.TextSize = 14; Search.ZIndex = 52; Search.Parent = Box; Instance.new("UICorner", Search)
            local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1, -20, 1, -65); scroll.Position = UDim2.new(0, 10, 0, 55); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 2; scroll.ZIndex = 52; scroll.Parent = Box
            local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 5); layout.Parent = scroll

            local function Refresh(filter)
                for _, v in pairs(scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                for _, opt in pairs(Options) do
                    if filter == "" or string.find(string.lower(opt), string.lower(filter)) then
                        local o = Instance.new("TextButton"); o.Size = UDim2.new(1, 0, 0, 35); o.Text = opt; o.TextColor3 = Color3.fromRGB(255, 255, 255); o.TextSize = 14; o.ZIndex = 53; o.Parent = scroll; Instance.new("UICorner", o)
                        local isSel = false;
                        if isMulti then
                            for _, v in pairs(Selected) do if v == opt then isSel = true break end end
                        else
                            isSel = (Selected[1] == opt)
                        end
                        o.BackgroundColor3 = isSel and Color3.fromRGB(80, 160, 255) or Color3.fromRGB(40, 40, 40)
                        
                        o.MouseButton1Click:Connect(function()
                            if isMulti then
                                local found = false;
                                for i, v in ipairs(Selected) do
                                    if v == opt then table.remove(Selected, i); found = true break end
                                end
                                if not found then table.insert(Selected, opt) end
                                o.BackgroundColor3 = (not found) and Color3.fromRGB(80, 160, 255) or Color3.fromRGB(40, 40, 40)
                                if Cfg.Flag then AbangLibrary.Pengaturan[Cfg.Flag] = Selected end
                            else
                                Selected = {opt}; Modal.Visible = false; 
                                if Cfg.Flag then AbangLibrary.Pengaturan[Cfg.Flag] = opt end
                            end
                            btn.Text = " " .. Cfg.Name .. " : " .. GetSelectedText(); AbangLibrary:Save()
                            if isMulti then Cfg.Callback(Selected) else Cfg.Callback(opt); Refresh("") end
                        end)
                    end
                end
            end

            btn.MouseButton1Click:Connect(function() Refresh(""); Modal.Visible = true end)
            Modal.MouseButton1Click:Connect(function() Modal.Visible = false end)
            Search:GetPropertyChangedSignal("Text"):Connect(function() Refresh(Search.Text) end)
            task.spawn(function()
                if isMulti then Cfg.Callback(Selected) else Cfg.Callback(Selected[1]) end
            end)

            -- ==========================================
            -- INI DIA PENYELAMATNYA (RETURN REFRESH FUNC)
            -- ==========================================
            return {
                Refresh = function(self, newOptions, keepSelected)
                    Options = newOptions or {}
                    if not keepSelected then
                        if isMulti then
                            Selected = {}
                        else
                            Selected = {Options[1] or "Kosong"}
                        end
                    end
                    if Cfg.Flag then AbangLibrary.Pengaturan[Cfg.Flag] = isMulti and Selected or Selected[1] end
                    btn.Text = " " .. Cfg.Name .. " : " .. GetSelectedText()
                    Refresh("")
                end
            }
        end

        function Tab:AddTextbox(Cfg)
            Tab.ItemCount = Tab.ItemCount + 1
            local Default = AbangLibrary.Pengaturan[Cfg.Flag] or Cfg.Default or ""
            local f = Instance.new("Frame"); f.Size = UDim2.new(1, 0, 0, 45); f.BackgroundColor3 = Color3.fromRGB(35, 35, 35); f.LayoutOrder = Tab.ItemCount; f.Parent = Page; Instance.new("UICorner", f)
            local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.4, 0, 1, 0); l.Position = UDim2.new(0, 10, 0, 0); l.Text = Cfg.Name; l.TextColor3 = Color3.fromRGB(255, 255, 255); l.BackgroundTransparency = 1; l.TextSize = 14; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
            local tb = Instance.new("TextBox"); tb.Size = UDim2.new(0.5, 0, 0, 30); tb.Position = UDim2.new(0.45, 0, 0.5, -15); tb.BackgroundColor3 = Color3.fromRGB(25, 25, 25); tb.Text = Default; tb.TextColor3 = Color3.fromRGB(80, 160, 255); tb.TextSize = 14; tb.Parent = f; Instance.new("UICorner", tb)
            tb.FocusLost:Connect(function()
                if Cfg.Flag then AbangLibrary.Pengaturan[Cfg.Flag] = tb.Text; AbangLibrary:Save() end
                Cfg.Callback(tb.Text)
            end)
            task.spawn(function() Cfg.Callback(Default) end)
        end

        function Tab:AddLabel(Text)
            Tab.ItemCount = Tab.ItemCount + 1
            local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, 0, 0, 25); l.BackgroundTransparency = 1; l.Text = " " .. Text; l.TextColor3 = Color3.fromRGB(200, 200, 200); l.Font = Enum.Font.Gotham; l.TextSize = 14; l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = Tab.ItemCount; l.Parent = Page
            return {Set = function(_, t) l.Text = " " .. t end}
        end

        function Tab:AddParagraph(Cfg)
            Tab.ItemCount = Tab.ItemCount + 1
            local f = Instance.new("Frame"); f.Size = UDim2.new(1, 0, 0, 65); f.BackgroundColor3 = Color3.fromRGB(30, 30, 30); f.LayoutOrder = Tab.ItemCount; f.Parent = Page; Instance.new("UICorner", f)
            local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -20, 0, 20); t.Position = UDim2.new(0, 10, 0, 5); t.Text = Cfg.Title or "Info"; t.TextColor3 = Color3.fromRGB(80, 160, 255); t.Font = Enum.Font.GothamBold; t.TextSize = 15; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = f
            local c = Instance.new("TextLabel"); c.Size = UDim2.new(1, -20, 1, -30); c.Position = UDim2.new(0, 10, 0, 25); c.Text = Cfg.Content or ""; c.TextColor3 = Color3.fromRGB(255, 255, 255); c.Font = Enum.Font.Gotham; c.TextSize = 13; c.TextWrapped = true; c.BackgroundTransparency = 1; c.TextXAlignment = Enum.TextXAlignment.Left; c.TextYAlignment = Enum.TextYAlignment.Top; c.Parent = f
            c:GetPropertyChangedSignal("TextBounds"):Connect(function() f.Size = UDim2.new(1, 0, 0, c.TextBounds.Y + 35) end)
            return {Set = function(_, baru) t.Text = baru.Title or t.Text; c.Text = baru.Content or c.Text end}
        end
        return Tab
    end

    function Window:BuildSettings()
        local st = self:MakeTab({Name = "⚙️ Settings"})
        st:AddButton({Name = "Save Config Manual", Callback = function() AbangLibrary:Save() end})
        st:AddButton({Name = "Hapus Hub", Callback = function() ScreenGui:Destroy() end})
    end
    return Window
end
return AbangLibrary
