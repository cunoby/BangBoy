local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local Custom = {} do
  Custom.ColorRGB = Color3.fromRGB(250, 7, 7)
  function Custom:Create(Name, Properties, Parent)
    local _instance = Instance.new(Name)
    for i, v in pairs(Properties) do _instance[i] = v end
    if Parent then _instance.Parent = Parent end
    return _instance
  end
  function Custom:EnabledAFK()
    Player.Idled:Connect(function()
      VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
      task.wait(1)
      VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
  end
end

Custom:EnabledAFK()

local function OpenClose()
  local ScreenGui = Custom:Create("ScreenGui", {
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  }, Player:WaitForChild("PlayerGui"))

  local Close_ImageButton = Custom:Create("ImageButton", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BorderColor3 = Color3.fromRGB(255, 0, 0),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.1021, 0, 0.0743, 0),
    Size = UDim2.new(0, 59, 0, 49),
    Image = "rbxassetid://136890595976124",
    Visible = false,
  }, ScreenGui)

  local UICorner = Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9) }, Close_ImageButton)
  local dragging, dragStart, startPos = false, nil, nil

  local function UpdateDraggable(input)
    local delta = input.Position - dragStart
    Close_ImageButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
  end

  Close_ImageButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging = true
      dragStart = input.Position
      startPos = Close_ImageButton.Position
      input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
  end)

  Close_ImageButton.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateDraggable(input) end
  end)
  return Close_ImageButton
end

local Open_Close = OpenClose()

local function MakeDraggable(topbarobject, object)
  local dragging, dragStart, startPos = false, nil, nil
  local function UpdatePos(input)
    local delta = input.Position - dragStart
    object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
  end

  topbarobject.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      dragging = true
      dragStart = input.Position
      startPos = object.Position
      input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
  end)

  topbarobject.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdatePos(input) end
  end)
end

function CircleClick(Button, X, Y)
	task.spawn(function()
		Button.ClipsDescendants = true
		local Circle = Instance.new("ImageLabel")
		Circle.Image = "rbxassetid://106471194043211"
		Circle.ImageColor3 = Color3.fromRGB(80, 80, 80)
		Circle.ImageTransparency = 0.8999999761581421
		Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Circle.BackgroundTransparency = 1
		Circle.ZIndex = 10
		Circle.Name = "Circle"
		Circle.Parent = Button
		
		local NewX = X - Button.AbsolutePosition.X
		local NewY = Y - Button.AbsolutePosition.Y
		Circle.Position = UDim2.new(0, NewX, 0, NewY)
		local Size = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.5
		local Time = 0.5
		local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local Tween = TweenService:Create(Circle, TweenInfo, {
			Size = UDim2.new(0, Size, 0, Size),
			Position = UDim2.new(0.5, -Size/2, 0.5, -Size/2)
		})
		Tween:Play()
		Tween.Completed:Connect(function()
			for i = 1, 10 do Circle.ImageTransparency = Circle.ImageTransparency + 0.01 wait(Time / 10) end
			Circle:Destroy()
		end)
	end)
end

local Speed_Library, Notification = {}, {}
Speed_Library.Unloaded = false

function Speed_Library:SetNotification(Config)
  local Title = Config[1] or Config.Title or ""
  local Description = Config[2] or Config.Description or ""
	local Content = Config[3] or Config.Content or ""
  local Time = Config[5] or Config.Time or 0.5
  local Delay = Config[6] or Config.Delay or 5

  local NotificationGui = Custom:Create("ScreenGui", {
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
  }, Player:WaitForChild("PlayerGui"))

  local NotificationLayout = Custom:Create("Frame", {
    AnchorPoint = Vector2.new(1, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.999,
    BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Position = UDim2.new(1, -30, 1, -30), Size = UDim2.new(0, 320, 1, 0), Name = "NotificationLayout"
  }, NotificationGui)

  local Count = 0
  NotificationLayout.ChildRemoved:Connect(function()
    Count = 0
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    for _, v in ipairs(NotificationLayout:GetChildren()) do
      local NewPOS = UDim2.new(0, 0, 1, -((v.Size.Y.Offset + 12) * Count))
      local tween = TweenService:Create(v, tweenInfo, {Position = NewPOS})
      tween:Play()
      Count = Count + 1
    end
  end)

  local _Count = 0
  for _, v in ipairs(NotificationLayout:GetChildren()) do _Count = -(v.Position.Y.Offset) + v.Size.Y.Offset + 12 end

  local NotificationFrame = Custom:Create("Frame", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 150),
    Name = "NotificationFrame", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -(_Count))
  }, NotificationLayout)

  local NotificationFrameReal = Custom:Create("Frame", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Position = UDim2.new(0, 400, 0, 0), Size = UDim2.new(1, 0, 1, 0), Name = "NotificationFrameReal"
  }, NotificationFrame)

  Custom:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, NotificationFrameReal)

  local DropShadowHolder = Custom:Create("Frame", {
    BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ZIndex = 0, Name = "DropShadowHolder", Parent = NotificationFrameReal
  })

  Custom:Create("ImageLabel", {
    Image = "", ImageColor3 = Color3.fromRGB(0, 0, 0), ImageTransparency = 0.5, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 47, 1, 47), ZIndex = 0, Name = "DropShadow", Parent = DropShadowHolder
  })
 
  local Top = Custom:Create("Frame", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.999, BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 36), Name = "Top", Parent = NotificationFrameReal
  })

  local TextLabel = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold, Text = Title, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.999, BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), Parent = Top
  })

  Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 0.3, Parent = TextLabel })
  Custom:Create("UICorner", { Parent = Top, CornerRadius = UDim.new(0, 5) })

  local TextLabel1 = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold, Text = Description, TextColor3 = Custom.ColorRGB, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.999, BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, TextLabel.TextBounds.X + 15, 0, 0), Parent = Top
  })

  Custom:Create("UIStroke", { Color = Custom.ColorRGB, Thickness = 0.4, Parent = TextLabel1 })

  local Close = Custom:Create("TextButton", {
    Font = Enum.Font.SourceSans, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 18, AnchorPoint = Vector2.new(1, 0.5),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.999, BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.new(0, 25, 0, 25), Name = "Close", Parent = Top
  })

  local TextLabel2 = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, Text = Content, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.999, TextColor3 = Color3.fromRGB(150, 150, 150), BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, 27), Size = UDim2.new(1, -20, 0, 13), Parent = NotificationFrameReal
  })

  TextLabel2.Size = UDim2.new(1, -20, 0, 13 + (13 * (TextLabel2.TextBounds.X // TextLabel2.AbsoluteSize.X)))
  TextLabel2.TextWrapped = true

  if TextLabel2.AbsoluteSize.Y < 27 then NotificationFrame.Size = UDim2.new(1, 0, 0, 65) else NotificationFrame.Size = UDim2.new(1, 0, 0, TextLabel2.AbsoluteSize.Y + 40) end

  local Waitted = false
  function Notification:Close()
    if Waitted then return false end
    Waitted = true
    local tween = TweenService:Create(NotificationFrameReal,TweenInfo.new(tonumber(Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut),{Position = UDim2.new(0, 400, 0, 0)})
    tween:Play()
    task.wait(tonumber(Time) / 1.2)
    NotificationFrame:Destroy()
    Waitted = false
  end

  Close.Activated:Connect(function() Notification:Close() end)
  TweenService:Create(NotificationFrameReal, TweenInfo.new(tonumber(Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {Position = UDim2.new(0, 0, 0, 0)} ):Play()
  task.wait(tonumber(Delay))
  Notification:Close()
  return Notification
end

function Speed_Library:CreateWindow(Config)
  local Title = Config[1] or Config.Title or ""
  local Description = Config[2] or Config.Description or ""
  local TabWidth = Config[3] or Config["Tab Width"] or 120
  local SizeUi = Config[4] or Config.SizeUi or UDim2.fromOffset(550, 315)

  local Funcs = {}
  local SpeedHubXGui = Custom:Create("ScreenGui", { ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, Player:WaitForChild("PlayerGui"))

  local DropShadowHolder = Custom:Create("Frame", {
    BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(0, 455, 0, 350), ZIndex = 0, Name = "DropShadowHolder", Position = UDim2.new(0, (SpeedHubXGui.AbsoluteSize.X // 2 - 455 // 2), 0, (SpeedHubXGui.AbsoluteSize.Y // 2 - 350 // 2))
  }, SpeedHubXGui)

  local DropShadow = Custom:Create("ImageLabel", {
    Image = "", ImageColor3 = Color3.fromRGB(15, 15, 15), ImageTransparency = 0.5, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0.5, 0, 0.5, 0), Size = SizeUi, ZIndex = 0, Name = "DropShadow"
  }, DropShadowHolder)

  local Main = Custom:Create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(15, 15, 15), BackgroundTransparency = 0.1, BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Position = UDim2.new(0.5, 0, 0.5, 0), Size = SizeUi, Name = "Main"
  }, DropShadow)
  Custom:Create("UICorner", {}, Main)
  Custom:Create("UIStroke", { Color = Color3.fromRGB(50, 50, 50), Thickness = 1.6 }, Main)

  local Top = Custom:Create("Frame", { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.999, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38), Name = "Top" }, Main)

  local TextLabel = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold, Text = Title, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundTransparency = 0.999, Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0)
  }, Top)
  Custom:Create("UICorner", {}, Top)

  local TextLabel1 = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold, Text = Description, TextColor3 = Custom.ColorRGB, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundTransparency = 0.999, Size = UDim2.new(1, -(TextLabel.TextBounds.X + 104), 1, 0), Position = UDim2.new(0, TextLabel.TextBounds.X + 15, 0, 0)
  }, Top)
  Custom:Create("UIStroke", { Color = Custom.ColorRGB, Thickness = 0.4 }, TextLabel1)

  local Close = Custom:Create("TextButton", {
    Font = Enum.Font.SourceSans, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 18, AnchorPoint = Vector2.new(1, 0.5), BackgroundTransparency = 0.999, Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 25, 0, 25), Name = "Close"
  }, Top)

  local Min = Custom:Create("TextButton", {
    Font = Enum.Font.SourceSans, Text = "-", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 18, AnchorPoint = Vector2.new(1, 0.5), BackgroundTransparency = 0.999, Position = UDim2.new(1, -42, 0.5, 0), Size = UDim2.new(0, 25, 0, 25), Name = "Min"
  }, Top)

  local LayersTab = Custom:Create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.999, Position = UDim2.new(0, 9, 0, 50), Size = UDim2.new(0, TabWidth, 1, -59), Name = "LayersTab" }, Main)
  Custom:Create("UICorner", { CornerRadius = UDim.new(0, 2) }, LayersTab)

  Custom:Create("Frame", { AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.85, BorderSizePixel = 0, Position = UDim2.new(0.5, 0, 0, 38), Size = UDim2.new(1, 0, 0, 1), Name = "DecideFrame" }, Main)

  local Layers = Custom:Create("Frame", { BackgroundTransparency = 0.999, Position = UDim2.new(0, TabWidth + 18, 0, 50), Size = UDim2.new(1, -(TabWidth + 9 + 18), 1, -59), Name = "Layers" }, Main)
  Custom:Create("UICorner", { CornerRadius = UDim.new(0, 2) }, Layers)

  local NameTab = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold, Text = "", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 24, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 0.999, Size = UDim2.new(1, 0, 0, 30), Name = "NameTab"
  }, Layers)

  local LayersReal = Custom:Create("Frame", { AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 0.999, ClipsDescendants = true, Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 1, -33), Name = "LayersReal" }, Layers)
  local LayersFolder = Custom:Create("Folder", { Name = "LayersFolder" }, LayersReal)
  local LayersPageLayout = Custom:Create("UIPageLayout", { SortOrder = Enum.SortOrder.LayoutOrder, TweenTime = 0.5, EasingDirection = Enum.EasingDirection.InOut, EasingStyle = Enum.EasingStyle.Quad }, LayersFolder)

  local ScrollTab = Custom:Create("ScrollingFrame", {
    CanvasSize = UDim2.new(0, 0, 2.1, 0), ScrollBarThickness = 0, Active = true, BackgroundTransparency = 0.999, Size = UDim2.new(1, 0, 1, -10), Name = "ScrollTab"
  }, LayersTab)
  Custom:Create("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, ScrollTab)

  local function UpdateSize()
    local _Total = 0
		for _, v in pairs(ScrollTab:GetChildren()) do if v.Name ~= "UIListLayout" then _Total = _Total + 3 + v.Size.Y.Offset end end
		ScrollTab.CanvasSize = UDim2.new(0, 0, 0, _Total)
  end
  ScrollTab.ChildAdded:Connect(UpdateSize); ScrollTab.ChildRemoved:Connect(UpdateSize)

  Min.Activated:Connect(function() CircleClick(Min, Player:GetMouse().X, Player:GetMouse().Y); DropShadowHolder.Visible = false; if not Open_Close.Visible then Open_Close.Visible = true end end)
  Open_Close.Activated:Connect(function() DropShadowHolder.Visible = true; if Open_Close.Visible then Open_Close.Visible = false end end)
  Close.Activated:Connect(function() CircleClick(Close, Player:GetMouse().X, Player:GetMouse().Y); if SpeedHubXGui then SpeedHubXGui:Destroy() end; if not Speed_Library.Unloaded then Speed_Library.Unloaded = true end end)

  DropShadowHolder.Size = UDim2.new(0, 115 + TextLabel.TextBounds.X + 1 + TextLabel1.TextBounds.X, 0, 350)
	MakeDraggable(Top, DropShadowHolder)

  local Tabs = {}
  local CountTab = 0
  function Tabs:CreateTab(Config)
    local _Name = Config[1] or Config.Name or "" 
    local Icon = Config[2] or Config.Icon or ""
    
    local ScrolLayers = Custom:Create("ScrollingFrame", { ScrollBarThickness = 0, Active = true, LayoutOrder = CountTab, BackgroundTransparency = 0.999, Size = UDim2.new(1, 0, 1, 0), Name = "ScrolLayers", Parent = LayersFolder })
    Custom:Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ScrolLayers })

    local Tab = Custom:Create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = CountTab == 0 and 0.92 or 0.999, LayoutOrder = CountTab, Size = UDim2.new(1, 0, 0, 30), Name = "Tab", Parent = ScrollTab })
    Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Tab })

    local TabButton = Custom:Create("TextButton", { Font = Enum.Font.GothamBold, Text = "", BackgroundTransparency = 0.999, Size = UDim2.new(1, 0, 1, 0), Name = "TabButton" }, Tab)
    Custom:Create("TextLabel", { Font = Enum.Font.GothamBold, Text = _Name, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 0.999, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 30, 0, 0) }, Tab)
    Custom:Create("ImageLabel", { Image = Icon, BackgroundTransparency = 0.999, Position = UDim2.new(0, 9, 0, 7), Size = UDim2.new(0, 16, 0, 16) }, Tab)

    if CountTab == 0 then
      LayersPageLayout:JumpToIndex(0); NameTab.Text = _Name
      local ChooseFrame = Custom:Create("Frame", { BackgroundColor3 = Custom.ColorRGB, Position = UDim2.new(0, 2, 0, 9), Size = UDim2.new(0, 1, 0, 12), Name = "ChooseFrame" }, Tab)
      Custom:Create("UIStroke", { Color = Custom.ColorRGB, Thickness = 1.6 }, ChooseFrame)
      Custom:Create("UICorner", {}, ChooseFrame)
    end

    TabButton.Activated:Connect(function()
      CircleClick(TabButton, Player:GetMouse().X, Player:GetMouse().Y)
      local FrameChoose = nil
      for _, s in pairs(ScrollTab:GetChildren()) do for _, v in pairs(s:GetChildren()) do if v.Name == "ChooseFrame" then FrameChoose = v; break end end if FrameChoose then break end end
  
      if FrameChoose and Tab.LayoutOrder ~= LayersPageLayout.CurrentPage.LayoutOrder then
        for _, TabFrame in pairs(ScrollTab:GetChildren()) do if TabFrame.Name == "Tab" then TweenService:Create(TabFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.999}):Play() end end
        TweenService:Create(Tab, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.92}):Play()
        TweenService:Create(FrameChoose, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 2, 0, 9 + (33 * Tab.LayoutOrder)) }):Play()
        LayersPageLayout:JumpToIndex(Tab.LayoutOrder)
        task.wait(0.05); NameTab.Text = _Name
        TweenService:Create(FrameChoose, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 1, 0, 20)}):Play()
        task.wait(0.2); TweenService:Create(FrameChoose, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 1, 0, 12)}):Play()
      end
    end)

    local Sections, CountSection = {}, 0
    function Sections:AddSection(Title, OpenSection)
      local Title = Title or ""; local OpenSection = OpenSection or false
      local Section = Custom:Create("Frame", { BackgroundTransparency = 0.999, ClipsDescendants = true, LayoutOrder = CountSection, Size = UDim2.new(1, 0, 0, 30), Name = "Section" }, ScrolLayers)
      local SectionReal = Custom:Create("Frame", { AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.935, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1, 1, 0, 30), Name = "SectionReal" }, Section)
      Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, SectionReal)
      local SectionButton = Custom:Create("TextButton", { Text = "", BackgroundTransparency = 0.999, Size = UDim2.new(1, 0, 1, 0) }, SectionReal)
      local FeatureFrame = Custom:Create("Frame", { AnchorPoint = Vector2.new(1, 0.5), BackgroundTransparency = 0.999, Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.new(0, 20, 0, 20) }, SectionReal)
      Custom:Create("ImageLabel", { Image = "rbxassetid://125609963478878", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 0.999, Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = -90, Size = UDim2.new(1, 6, 1, 6) }, FeatureFrame)
      Custom:Create("TextLabel", { Font = Enum.Font.GothamBold, Text = Title, TextColor3 = Color3.fromRGB(230, 230, 230), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 0.999, Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -50, 0, 13) }, SectionReal)
  
      local SectionDecideFrame = Custom:Create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 33), Size = UDim2.new(0, 0, 0, 2) }, Section)
      Custom:Create("UIGradient", { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)), ColorSequenceKeypoint.new(0.5, Custom.ColorRGB), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))} }, SectionDecideFrame)
      local SectionAdd = Custom:Create("Frame", { AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 0.999, ClipsDescendants = true, Position = UDim2.new(0.5, 0, 0, 38), Size = UDim2.new(1, 0, 0, 100) }, Section)
      Custom:Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, SectionAdd)
  
      local function UpdateSizeScroll()
        local OffsetY = 0
        for _, child in pairs(ScrolLayers:GetChildren()) do if child.Name ~= "UIListLayout" then OffsetY = OffsetY + 3 + child.Size.Y.Offset end end
        ScrolLayers.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
      end
    
      local function UpdateSizeSection()
        if OpenSection then
          local SectionSizeYWitdh = 38
          for _, v in pairs(SectionAdd:GetChildren()) do if v.Name ~= "UIListLayout" and v.Name ~= "UICorner" then SectionSizeYWitdh = SectionSizeYWitdh + v.Size.Y.Offset + 3 end end
          TweenService:Create(FeatureFrame, TweenInfo.new(0.1), {Rotation = 90}):Play(); TweenService:Create(Section, TweenInfo.new(0.1), {Size = UDim2.new(1, 1, 0, SectionSizeYWitdh)}):Play()
          TweenService:Create(SectionAdd, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, SectionSizeYWitdh - 38)}):Play(); TweenService:Create(SectionDecideFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 2)}):Play()
          task.wait(0.5); UpdateSizeScroll()
        end
      end
    
      SectionButton.Activated:Connect(function()
        CircleClick(SectionButton, Player:GetMouse().X, Player:GetMouse().Y)
        if OpenSection then
          TweenService:Create(FeatureFrame, TweenInfo.new(0.1), {Rotation = 0}):Play(); TweenService:Create(Section, TweenInfo.new(0.1), {Size = UDim2.new(1, 1, 0, 30)}):Play()
          TweenService:Create(SectionDecideFrame, TweenInfo.new(0.1), {Size = UDim2.new(0, 0, 0, 2)}):Play()
          OpenSection = false; task.wait(0.1); UpdateSizeScroll()
        else OpenSection = true; UpdateSizeSection() end
      end)
      SectionAdd.ChildAdded:Connect(UpdateSizeSection); SectionAdd.ChildRemoved:Connect(UpdateSizeSection)
      UpdateSizeScroll()

      local Item, ItemCount = {}, 0

      -- ═══════════════════════════════════════════════════════════
      -- BLOK LIVE TABLE + FITUR SEARCH BAR
      -- ═══════════════════════════════════════════════════════════
      function Item:AddLiveTable(Config)
        local Title = Config[1] or Config.Title or "Live Table"
        local Columns = Config[2] or Config.Columns or {"Name", "Value"}
        local Data = Config[3] or Config.Data or {}
        local Actions = Config[5] or Config.Actions or {}
        local RowButtons = Config[6] or Config.RowButtons or false

        local TableFuncs = {}
        local TableData = {}
        local SortColumn = nil
        local SortDirection = "asc"
        local SearchQuery = "" -- Variabel untuk menyimpan teks pencarian

        local TableContainer = Custom:Create("Frame", {
          BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.935,
          LayoutOrder = ItemCount, Size = UDim2.new(1, 0, 0, 300), Name = "LiveTable"
        }, SectionAdd)
        Custom:Create("UICorner", {CornerRadius = UDim.new(0, 4)}, TableContainer)

        -- 1. Table Header (Judul) -> Y: 0
        local TableHeader = Custom:Create("Frame", { BackgroundColor3 = Custom.ColorRGB, BackgroundTransparency = 0.1, Size = UDim2.new(1, 0, 0, 30), Name = "TableHeader" }, TableContainer)
        Custom:Create("UICorner", {CornerRadius = UDim.new(0, 4)}, TableHeader)
        local TableTitle = Custom:Create("TextLabel", { Font = Enum.Font.GothamBold, Text = Title, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 0.999, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0) }, TableHeader)

        -- 2. Search Bar -> Y: 35
        local SearchBar = Custom:Create("TextBox", {
            Font = Enum.Font.GothamBold,
            PlaceholderText = " 🔍 Cari nama pet di sini...",
            PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
            Text = "",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BackgroundTransparency = 0.5,
            BorderColor3 = Custom.ColorRGB,
            BorderSizePixel = 1,
            Position = UDim2.new(0, 10, 0, 35),
            Size = UDim2.new(1, -20, 0, 22),
            Name = "SearchBar"
        }, TableContainer)
        Custom:Create("UICorner", {CornerRadius = UDim.new(0, 4)}, SearchBar)
        
        -- Deteksi saat kita mengetik di kolom pencarian
        SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
            SearchQuery = string.lower(SearchBar.Text)
            TableFuncs:RefreshTable()
        end)

        -- 3. Columns Header -> Y: 62
        local ColumnsFrame = Custom:Create("Frame", { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.92, Position = UDim2.new(0, 0, 0, 62), Size = UDim2.new(1, 0, 0, 25) }, TableContainer)
        local ColumnWidth = 1 / (#Columns + (#Actions > 0 and 1 or 0) + (RowButtons and 1 or 0))

        for i, Column in ipairs(Columns) do
          local ColumnHeader = Custom:Create("TextButton", {
            Font = Enum.Font.GothamBold, Text = Column, TextColor3 = Color3.fromRGB(200, 200, 200), TextSize = 11,
            BackgroundTransparency = 0.999, BorderColor3 = Color3.fromRGB(100, 100, 100), BorderSizePixel = 1,
            Position = UDim2.new(ColumnWidth * (i - 1), 0, 0, 0), Size = UDim2.new(ColumnWidth, 0, 1, 0),
            Name = Column 
          }, ColumnsFrame)

          ColumnHeader.Activated:Connect(function()
            if SortColumn == Column then
              SortDirection = SortDirection == "asc" and "desc" or "asc"
            else SortColumn = Column; SortDirection = "asc" end
            TableFuncs:RefreshTable()
          end)
        end

        if #Actions > 0 then
          Custom:Create("TextLabel", { Font = Enum.Font.GothamBold, Text = "⚙️ Actions", TextColor3 = Color3.fromRGB(200, 200, 200), TextSize = 11, BackgroundTransparency = 0.999, BorderColor3 = Color3.fromRGB(100, 100, 100), BorderSizePixel = 1, Position = UDim2.new(ColumnWidth * #Columns, 0, 0, 0), Size = UDim2.new(ColumnWidth, 0, 1, 0) }, ColumnsFrame)
        end

        -- 4. Rows Container -> Y: 88, Sisanya untuk list (-88)
        local RowsContainer = Custom:Create("ScrollingFrame", {
          CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100), ScrollBarThickness = 6, Active = true,
          BackgroundTransparency = 0.999, Position = UDim2.new(0, 0, 0, 88), Size = UDim2.new(1, 0, 1, -88)
        }, TableContainer)
        Custom:Create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }, RowsContainer)

        function TableFuncs:SetData(NewData)
          TableData = NewData or {}
          self:RefreshTable()
        end

        function TableFuncs:RefreshTable()
          for _, child in pairs(RowsContainer:GetChildren()) do if child.Name == "Row" then child:Destroy() end end

          -- SISTEM FILTER PENCARIAN (SEARCH)
          local DisplayData = {}
          if SearchQuery and SearchQuery ~= "" then
            for _, row in ipairs(TableData) do
                -- Mencari berdasarkan teks pada Kolom ke-1 (yaitu "Pet")
                local searchStr = string.lower(tostring(row[Columns[1]] or ""))
                if string.find(searchStr, SearchQuery, 1, true) then 
                    table.insert(DisplayData, row)
                end
            end
          else
            DisplayData = {unpack(TableData)}
          end
          
          if SortColumn then
            for _, btn in ipairs(ColumnsFrame:GetChildren()) do
              if btn:IsA("TextButton") then
                local colName = btn.Name
                if colName == SortColumn then
                  btn.Text = colName .. (SortDirection == "asc" and " ^" or " v")
                else
                  btn.Text = colName
                end
              end
            end
            
            table.sort(DisplayData, function(a, b)
              local aVal = a[SortColumn] or ""
              local bVal = b[SortColumn] or ""
              local numA = tonumber(aVal)
              local numB = tonumber(bVal)
              
              if numA and numB then
                if SortDirection == "asc" then return numA < numB else return numA > numB end
              else
                local strA = string.lower(tostring(aVal))
                local strB = string.lower(tostring(bVal))
                if SortDirection == "asc" then return strA < strB else return strA > strB end
              end
            end)
          end

          for i = 1, #DisplayData do
            local RowData = DisplayData[i]
            local Row = Custom:Create("Frame", {
              BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.93, BorderColor3 = Color3.fromRGB(100, 100, 100), BorderSizePixel = 1,
              LayoutOrder = i, Size = UDim2.new(1, 0, 0, 24), Name = "Row"
            }, RowsContainer)
            Custom:Create("UICorner", {CornerRadius = UDim.new(0, 2)}, Row)

            for colIndex, Column in ipairs(Columns) do
              Custom:Create("TextLabel", {
                Font = Enum.Font.Gotham, Text = tostring(RowData[Column] or ""), TextColor3 = Color3.fromRGB(200, 200, 200), TextSize = 11,
                BackgroundTransparency = 0.999, Position = UDim2.new(ColumnWidth * (colIndex - 1), 0, 0, 0), Size = UDim2.new(ColumnWidth, 0, 1, 0)
              }, Row)
            end

            if #Actions > 0 then
              local ActionsCell = Custom:Create("Frame", { BackgroundTransparency = 0.999, Position = UDim2.new(ColumnWidth * #Columns, 0, 0, 0), Size = UDim2.new(ColumnWidth, 0, 1, 0) }, Row)
              
              Custom:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
              }, ActionsCell)

              for actionIdx, Action in ipairs(Actions) do
                local ActionBtn = Custom:Create("TextButton", {
                  Font = Enum.Font.GothamBold, Text = Action.Icon or "🛒", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 11,
                  BackgroundColor3 = Custom.ColorRGB, BackgroundTransparency = 0.1, 
                  Size = UDim2.new(0, 26, 0, 18), 
                  LayoutOrder = actionIdx
                }, ActionsCell)
                Custom:Create("UICorner", {CornerRadius = UDim.new(0, 4)}, ActionBtn)
                ActionBtn.Activated:Connect(function() CircleClick(ActionBtn, Player:GetMouse().X, Player:GetMouse().Y); Action.Callback(i, RowData) end)
              end
            end
          end

          RowsContainer.CanvasSize = UDim2.new(0, 0, 0, (#DisplayData * 25))
        end

        if Data and #Data > 0 then TableFuncs:SetData(Data) end
        ItemCount += 1
        return TableFuncs
      end

      ItemCount += 1
      return Item
    end
    CountTab += 1
    return Sections
  end
  return Tabs
end
return Speed_Library
