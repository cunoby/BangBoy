

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then PlayerGui = LocalPlayer.PlayerGui end

-- ============================================================
-- SAFE REQUIRE (tidak crash kalau modul tidak ada)
-- ============================================================
local function SafeRequire(path)
    local ok, result = pcall(require, path)
    return ok and result or nil
end

local function SafeGet(parent, ...)
    local current = parent
    for _, name in ipairs({...}) do
        if not current then return nil end
        local ok, child = pcall(function() return current:WaitForChild(name, 3) end)
        if not ok or not child then return nil end
        current = child
    end
    return current
end

-- ============================================================
-- LOAD MODUL GAME (semua opsional, tidak crash bila kosong)
-- ============================================================
local Modules = ReplicatedStorage:FindFirstChild("Modules")
local GameEvents = ReplicatedStorage:FindFirstChild("GameEvents")
local TradeEvents = GameEvents and GameEvents:FindFirstChild("TradeEvents")
local BoothEvents = TradeEvents and TradeEvents:FindFirstChild("Booths")

local ItemNameFinder   = Modules and SafeRequire(Modules:FindFirstChild("ItemNameFinder"))
local ItemImageFinder  = Modules and SafeRequire(Modules:FindFirstChild("ItemImageFinder"))
local ItemRarityFinder = Modules and SafeRequire(Modules:FindFirstChild("ItemRarityFinder"))
local PetUtilities     = Modules and (function()
    local ps = Modules:FindFirstChild("PetServices")
    return ps and SafeRequire(ps:FindFirstChild("PetUtilities")) or nil
end)()

-- ============================================================
-- FALLBACK FUNCTIONS (kalau modul tidak ada)
-- ============================================================
local function GetItemName(item)
    if not item or not item.data then return "Unknown" end
    local key = item.data.PetType or item.data.ItemName or item.data.Name or item.data.SkinID or "Unknown"
    if ItemNameFinder then
        local ok, name = pcall(ItemNameFinder, key, item.type or "")
        if ok and name then return tostring(name) end
    end
    return tostring(key)
end

local function GetItemImage(item)
    if not item or not item.data then return "" end
    local key = item.data.PetType or item.data.ItemName or item.data.Name or item.data.SkinID or ""
    if ItemImageFinder then
        local ok, img = pcall(ItemImageFinder, key, item.type or "")
        if ok and img then return tostring(img) end
    end
    return ""
end

local RARITY_ORDER = {Common=1, Uncommon=2, Rare=3, Legendary=4, Mythic=5, Divine=6}
local function GetItemRarity(item)
    if not item or not item.data then return "Common" end
    local key = item.data.PetType or item.data.ItemName or item.data.Name or item.data.SkinID or ""
    if ItemRarityFinder then
        local ok, rar = pcall(ItemRarityFinder, key, item.type or "")
        if ok and rar then return tostring(rar) end
    end
    return "Common"
end

local function CalcWeight(item)
    if item and item.data and item.data.PetData and PetUtilities then
        local ok, w = pcall(function()
            return PetUtilities:CalculateWeight(item.data.PetData.BaseWeight, item.data.PetData.Level)
        end)
        if ok and w then return string.format("%.2f kg", w) end
    end
    if item and item.data and item.data.PetData and item.data.PetData.BaseWeight then
        return string.format("%.2f kg", item.data.PetData.BaseWeight)
    end
    return ""
end

-- ============================================================
-- TEMA WARNA
-- ============================================================
local C = {
    BG       = Color3.fromRGB(14, 16, 24),
    Panel    = Color3.fromRGB(22, 26, 38),
    Card     = Color3.fromRGB(30, 34, 50),
    Border   = Color3.fromRGB(50, 56, 80),
    Primary  = Color3.fromRGB(60, 190, 130),
    PrimDark = Color3.fromRGB(38, 130, 90),
    Danger   = Color3.fromRGB(220, 60, 60),
    Accent   = Color3.fromRGB(90, 140, 255),
    Gold     = Color3.fromRGB(255, 200, 50),
    Text     = Color3.fromRGB(230, 235, 255),
    Muted    = Color3.fromRGB(110, 120, 150),
    Dim      = Color3.fromRGB(60, 70, 100),
    White    = Color3.new(1,1,1),
    Black    = Color3.new(0,0,0),
}

local RARITY_COL = {
    Common    = Color3.fromRGB(170,170,170),
    Uncommon  = Color3.fromRGB(70, 200, 90),
    Rare      = Color3.fromRGB(70, 130, 255),
    Legendary = Color3.fromRGB(180, 70, 255),
    Mythic    = Color3.fromRGB(255, 130, 30),
    Divine    = Color3.fromRGB(255, 215, 30),
}
local function RarColor(r) return RARITY_COL[r] or C.Muted end

-- ============================================================
-- FORMAT ANGKA
-- ============================================================
local function Fmt(n)
    n = tonumber(n) or 0
    if n >= 1e9 then return string.format("%.1fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
    end
    return tostring(math.floor(n))
end

-- ============================================================
-- UI HELPERS
-- ============================================================
local function New(cls, props, parent)
    local i = Instance.new(cls)
    if props then for k,v in pairs(props) do i[k]=v end end
    if parent then i.Parent = parent end
    return i
end

local function Corner(r, p)
    New("UICorner", {CornerRadius=UDim.new(0,r)}, p)
    return p
end

local function Pad(t,b,l,r, p)
    New("UIPadding",{PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r)}, p)
end

local function Stroke(th, col, p)
    New("UIStroke",{Thickness=th, Color=col, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, p)
end

local function Label(txt, sz, col, props, parent)
    local l = New("TextLabel",{
        Text=txt, TextSize=sz, TextColor3=col,
        BackgroundTransparency=1, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Size=UDim2.new(1,0,0,sz+4),
    }, nil)
    if props then for k,v in pairs(props) do l[k]=v end end
    if parent then l.Parent=parent end
    return l
end

local function Btn(txt, bg, tc, props, parent)
    local b = New("TextButton",{
        Text=txt, TextSize=15, TextColor3=tc or C.White,
        BackgroundColor3=bg or C.Primary, Font=Enum.Font.GothamBold,
        AutoButtonColor=false, BorderSizePixel=0,
    }, nil)
    Corner(10, b)
    if props then for k,v in pairs(props) do b[k]=v end end
    local origBg = bg or C.Primary
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=origBg:Lerp(C.White,0.18)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=origBg}):Play()
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.07),{BackgroundColor3=origBg:Lerp(C.Black,0.22)}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=origBg}):Play()
    end)
    if parent then b.Parent=parent end
    return b
end

local function TBox(placeholder, parent)
    local b = New("TextBox",{
        PlaceholderText=placeholder, PlaceholderColor3=C.Muted,
        Text="", TextSize=14, TextColor3=C.Text,
        BackgroundColor3=C.Card, Font=Enum.Font.Gotham,
        BorderSizePixel=0, ClearTextOnFocus=false,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, nil)
    Corner(10, b)
    Stroke(1, C.Border, b)
    Pad(0,0,12,12, b)
    if parent then b.Parent=parent end
    return b
end

local function ScrollFrame(props, parent)
    local sf = New("ScrollingFrame",{
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=C.Border,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticCanvasSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        ElasticBehavior=Enum.ElasticBehavior.Always,
    }, nil)
    if props then for k,v in pairs(props) do sf[k]=v end end
    if parent then sf.Parent=parent end
    return sf
end

local function ClearScroll(sf)
    for _, c in sf:GetChildren() do
        if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then
            c:Destroy()
        end
    end
end

local function SortItems(items, sortType, asc)
    local s = table.clone(items)
    table.sort(s, function(a,b)
        local va, vb
        if sortType == "Name" then
            va = GetItemName(a); vb = GetItemName(b)
            return asc and va<vb or va>vb
        elseif sortType == "Rarity" then
            va = RARITY_ORDER[GetItemRarity(a)] or 0
            vb = RARITY_ORDER[GetItemRarity(b)] or 0
        elseif sortType == "Price" then
            va = a.listingPrice or 0; vb = b.listingPrice or 0
        else
            return false
        end
        if va == vb then return GetItemName(a)<GetItemName(b) end
        return asc and va<vb or va>vb
    end)
    return s
end

-- ============================================================
-- HAPUS GUI LAMA (agar tidak duplikat saat re-execute)
-- ============================================================
local oldGui = PlayerGui:FindFirstChild("GrowTradeGUI")
if oldGui then oldGui:Destroy() end

-- ============================================================
-- SCREENGUI
-- ============================================================
local ScreenGui = New("ScreenGui",{
    Name="GrowTradeGUI", ResetOnSpawn=false,
    IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

-- ============================================================
-- DETEKSI MOBILE (portrait / landscape)
-- ============================================================
local VP = workspace.CurrentCamera.ViewportSize
local IsMobile = UserInputService.TouchEnabled

-- ============================================================
-- TOAST / NOTIFIKASI
-- ============================================================
local ToastHolder = New("Frame",{
    Name="ToastHolder",
    Size=UDim2.new(0,320,0,60),
    Position=UDim2.new(0.5,-160,0,10),
    BackgroundColor3=C.Panel, BorderSizePixel=0,
    Visible=false, ZIndex=100,
}, ScreenGui)
Corner(12, ToastHolder)
Stroke(1.5, C.Primary, ToastHolder)
Pad(0,0,14,14, ToastHolder)
local ToastTxt = Label("",14,C.Text,{
    Size=UDim2.new(1,0,1,0),
    TextXAlignment=Enum.TextXAlignment.Center,
    TextYAlignment=Enum.TextYAlignment.Center,
    TextWrapped=true, ZIndex=101,
}, ToastHolder)

local _toastTask = nil
local function Toast(msg, col, dur)
    if _toastTask then task.cancel(_toastTask) end
    col = col or C.Primary
    ToastTxt.Text = msg
    ToastTxt.TextColor3 = col
    ToastHolder:FindFirstChildWhichIsA("UIStroke").Color = col:Lerp(C.Border,0.4)
    ToastHolder.Visible = true
    ToastHolder.BackgroundTransparency = 0
    TweenService:Create(ToastHolder,TweenInfo.new(0.2),{BackgroundTransparency=0}):Play()
    _toastTask = task.delay(dur or 3, function()
        TweenService:Create(ToastHolder,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play()
        task.wait(0.2)
        ToastHolder.Visible = false
    end)
end

-- ============================================================
-- TOMBOL BUKA (HUD Button)
-- ============================================================
local OpenBtn = Btn("🏪 Trade", C.Primary, C.White, {
    Size=UDim2.fromOffset(110,46),
    Position=UDim2.new(0,10,0.5,-23),
    TextSize=15, ZIndex=50,
}, ScreenGui)

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local WinW = math.min(VP.X - 20, 480)
local WinH = math.min(VP.Y - 20, 680)
-- Untuk HP: hampir fullscreen
if IsMobile then
    WinW = VP.X - 16
    WinH = VP.Y - 16
end

local MainWin = New("Frame",{
    Name="MainWin",
    Size=UDim2.fromOffset(WinW, WinH),
    Position=UDim2.new(0.5,0,0.5,0),
    AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=C.BG,
    BorderSizePixel=0,
    Visible=false, ZIndex=10,
}, ScreenGui)
Corner(16, MainWin)
Stroke(1.5, C.Border, MainWin)

-- ============================================================
-- HEADER
-- ============================================================
local HEADER_H = 52
local Header = New("Frame",{
    Size=UDim2.new(1,0,0,HEADER_H),
    BackgroundColor3=C.Panel, BorderSizePixel=0, ZIndex=11,
}, MainWin)
Corner(16, Header)
-- patch bawah corner
New("Frame",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,1,-16),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=10},Header)

Label("🌱 Grow a Garden — Trade",16,C.Primary,{
    Size=UDim2.new(1,-60,1,0), Position=UDim2.fromOffset(14,0),
    TextYAlignment=Enum.TextYAlignment.Center, ZIndex=12,
}, Header)

local BtnClose = Btn("✕",Color3.fromRGB(200,55,55),C.White,{
    Size=UDim2.fromOffset(38,38),
    Position=UDim2.new(1,-46,0.5,-19),
    TextSize=17, ZIndex=12,
}, Header)

-- ============================================================
-- CONTENT AREA (atas TAB BAR)
-- ============================================================
local TABBAR_H = 58
local ContentArea = New("Frame",{
    Size=UDim2.new(1,0,1,-HEADER_H-TABBAR_H),
    Position=UDim2.fromOffset(0,HEADER_H),
    BackgroundTransparency=1, BorderSizePixel=0,
    ClipsDescendants=true, ZIndex=10,
}, MainWin)

-- ============================================================
-- BOTTOM TAB BAR (mobile style)
-- ============================================================
local TabBar = New("Frame",{
    Size=UDim2.new(1,0,0,TABBAR_H),
    Position=UDim2.new(0,0,1,-TABBAR_H),
    BackgroundColor3=C.Panel, BorderSizePixel=0, ZIndex=11,
}, MainWin)
Corner(16, TabBar)
New("Frame",{Size=UDim2.new(1,0,0,16),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=10},TabBar)
Stroke(0,C.Border,TabBar)

local TabLayout = New("UIListLayout",{
    FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Center,
    VerticalAlignment=Enum.VerticalAlignment.Center,
    Padding=UDim.new(0,0),
}, TabBar)

-- ============================================================
-- STATE
-- ============================================================
local State = {
    Panel        = "Listing",
    BoothUUID    = nil,
    BoothQuery   = "",
    BoothSort    = "Rarity",
    BoothAsc     = false,
    BoothItems   = {},

    InvCategory  = "Pets",
    InvQuery     = "",
    InvSort      = "Rarity",
    InvAsc       = false,
    InvItems     = {},
    SelectedItem = nil,

    HistFilter   = "All",
    HistAsc      = false,
    HistQuery    = "",
    HistLogs     = {},
    HistLoaded   = false,

    FSResult     = nil,
    FSSearching  = false,

    TradeId      = nil,
    PendReqId    = nil,
}

-- ============================================================
-- PANELS
-- ============================================================
local Panels     = {}
local TabButtons = {}

local TAB_DEFS = {
    {id="Listing",    icon="🏪", label="Listing",  order=1},
    {id="MyBooth",    icon="📦", label="Booth",    order=2},
    {id="Inventory",  icon="🎒", label="Inventori",order=3},
    {id="FindSeller", icon="🔍", label="Cari",     order=4},
    {id="History",    icon="📜", label="Riwayat",  order=5},
}

local function SetTab(id)
    State.Panel = id
    for tid, p in pairs(Panels) do p.Visible=(tid==id) end
    for tid, b in pairs(TabButtons) do
        if tid==id then
            b.BackgroundColor3 = C.Primary:Lerp(C.Panel,0.2)
            b.TextColor3       = C.White
        else
            b.BackgroundColor3 = Color3.new(0,0,0)
            b.BackgroundTransparency = 1
            b.TextColor3       = C.Muted
        end
    end
end

local function MakePanel(id)
    local p = New("Frame",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        Visible=false, ClipsDescendants=true,
    }, ContentArea)
    Pad(10,10,12,12, p)
    Panels[id] = p
    return p
end

local tabW = WinW / #TAB_DEFS
for _, def in ipairs(TAB_DEFS) do
    local b = New("TextButton",{
        Size=UDim2.new(1/#TAB_DEFS, 0, 1, 0),
        BackgroundTransparency=1, BorderSizePixel=0,
        Font=Enum.Font.GothamBold,
        Text=def.icon.."\n"..def.label,
        TextSize=11, TextColor3=C.Muted,
        TextWrapped=true, LineHeight=1.2,
        LayoutOrder=def.order, ZIndex=12,
    }, TabBar)
    Corner(0, b)
    TabButtons[def.id] = b
    b.MouseButton1Click:Connect(function()
        SetTab(def.id)
        if def.id=="History" and not State.HistLoaded then
            State.HistLoaded=true
            -- Load history via pcall
            task.spawn(function()
                local ok,logs=pcall(function()
                    return TradeEvents and TradeEvents.Booths and
                        TradeEvents.Booths.FetchHistory and
                        TradeEvents.Booths.FetchHistory:InvokeServer() or {}
                end)
                if ok and logs then State.HistLogs=logs; RefreshHistory() end
            end)
        end
    end)
end

-- ============================================================
-- ITEM CARD (compact, mobile-friendly)
-- ============================================================
local function ItemCard(item, parent, opts)
    opts = opts or {}
    local rar     = GetItemRarity(item)
    local rarCol  = RarColor(rar)
    local name    = GetItemName(item)
    local img     = GetItemImage(item)
    local weight  = CalcWeight(item)
    local price   = item.listingPrice

    local card = New("Frame",{
        Size=UDim2.new(1,0,0,76),
        BackgroundColor3=C.Card, BorderSizePixel=0,
    }, parent)
    Corner(12, card)
    Stroke(1.2, rarCol:Lerp(C.Border,0.5), card)

    -- Rarity stripe kiri
    New("Frame",{
        Size=UDim2.fromOffset(4,56),
        Position=UDim2.fromOffset(0,10),
        BackgroundColor3=rarCol, BorderSizePixel=0,
    }, card)
    New("UICorner",{CornerRadius=UDim.new(0,4)}, card:FindFirstChildWhichIsA("Frame"))

    -- Gambar item
    local imgBox = New("Frame",{
        Size=UDim2.fromOffset(52,52),
        Position=UDim2.fromOffset(10,12),
        BackgroundColor3=rarCol:Lerp(C.BG,0.75), BorderSizePixel=0,
    }, card)
    Corner(10, imgBox)
    if img~="" then
        New("ImageLabel",{
            Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
            Image=img, ScaleType=Enum.ScaleType.Fit,
        }, imgBox)
    else
        Label("?",22,rarCol,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center},imgBox)
    end

    -- Info
    local infoX = 70
    local btnW  = (opts.showBuy or opts.showRemove or opts.showSelect or opts.showAdd) and 76 or 0
    local infoW = -(infoX + btnW + 8 + (price and 70 or 0))

    Label(name,14,C.Text,{
        Size=UDim2.new(1,infoW,0,18),
        Position=UDim2.fromOffset(infoX,10),
        Font=Enum.Font.GothamBold,
    },card)

    -- Rarity badge
    local rb = New("TextLabel",{
        Text=rar, TextSize=10, TextColor3=rarCol,
        BackgroundColor3=rarCol:Lerp(C.BG,0.82),
        Font=Enum.Font.GothamBold, BorderSizePixel=0,
        Size=UDim2.fromOffset(70,16),
        Position=UDim2.fromOffset(infoX,30),
    }, card)
    Corner(5, rb)

    -- Weight
    if weight~="" then
        Label("⚖ "..weight,11,C.Muted,{
            Size=UDim2.fromOffset(100,14),
            Position=UDim2.fromOffset(infoX,50),
        }, card)
    end

    -- Seller
    local sellerTxt = ""
    if item.listingOwner and item.listingOwner.Name then
        sellerTxt = "@"..item.listingOwner.Name
    elseif item.seller then
        sellerTxt = "@"..tostring(item.seller)
    end
    if sellerTxt~="" then
        Label(sellerTxt,11,C.Dim,{
            Size=UDim2.fromOffset(120,14),
            Position=UDim2.fromOffset(infoX+104,50),
        }, card)
    end

    -- Harga (di kanan)
    if opts.showPrice and price then
        local pf = New("Frame",{
            Size=UDim2.fromOffset(68,48),
            Position=UDim2.new(1,-144,0.5,-24),
            BackgroundColor3=C.Panel, BorderSizePixel=0,
        }, card)
        Corner(8, pf)
        Label("Harga",10,C.Muted,{Size=UDim2.new(1,0,0,14),TextXAlignment=Enum.TextXAlignment.Center},pf)
        Label(Fmt(price),16,C.Primary,{
            Size=UDim2.new(1,0,0,22),Position=UDim2.fromOffset(0,16),
            TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,
        },pf)
    end

    -- Action Button
    local actionBg = opts.showBuy and C.Primary or opts.showRemove and C.Danger or opts.showSelect and C.Accent or opts.showAdd and C.Accent or nil
    local actionTxt = opts.showBuy and "Beli" or opts.showRemove and "Hapus" or opts.showSelect and "Pilih" or opts.showAdd and "+Trade" or nil
    if actionBg and opts.onAction then
        local ab = Btn(actionTxt, actionBg, C.White, {
            Size=UDim2.fromOffset(66,36),
            Position=UDim2.new(1,-74,0.5,-18),
            TextSize=13, ZIndex=12,
        }, card)
        ab.MouseButton1Click:Connect(function() opts.onAction(item) end)
    end

    -- Mutations
    if item.data and item.data.Mutations then
        local mx = infoX
        for mName, _ in pairs(item.data.Mutations) do
            local m = New("TextLabel",{
                Text=mName, TextSize=9, TextColor3=C.Gold,
                BackgroundColor3=C.Gold:Lerp(C.BG,0.82),
                Font=Enum.Font.GothamBold, BorderSizePixel=0,
                Size=UDim2.fromOffset(55,14),
                Position=UDim2.fromOffset(mx, 30),
            }, card)
            Corner(4,m)
            mx = mx + 58
        end
    end

    return card
end

-- ============================================================
-- FUNGSI FORWARD DECLARE (agar bisa saling referensi)
-- ============================================================
local RefreshListing, RefreshMyBooth, RefreshInventory, RefreshHistory
local OpenBuyPrompt, OpenRemovePrompt

-- ============================================================
-- PANEL: DAFTAR DAGANGAN (Listing)
-- ============================================================
local P_Listing = MakePanel("Listing")

-- Top controls
local LC_Bar = New("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1},P_Listing)
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center},LC_Bar)

local LC_Search = TBox("🔍 Cari nama pet...", LC_Bar)
LC_Search.Size = UDim2.new(1,-168,1,-6)

local LC_SortBtn = Btn("↕ Rarity",C.Card,C.Text,{Size=UDim2.fromOffset(82,36),TextSize=12},LC_Bar)
local LC_RefBtn  = Btn("🔄",C.Card,C.Text,{Size=UDim2.fromOffset(36,36),TextSize=16},LC_Bar)

-- Booth UUID input (collapsed, buka saat tap)
local LC_BoothRow = New("Frame",{Size=UDim2.new(1,0,0,36),Position=UDim2.fromOffset(0,48),BackgroundTransparency=1},P_Listing)
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center},LC_BoothRow)
Label("Booth:",12,C.Muted,{Size=UDim2.fromOffset(42,36),TextYAlignment=Enum.TextYAlignment.Center,TextXAlignment=Enum.TextXAlignment.Left},LC_BoothRow)
local LC_BoothBox = TBox("UUID atau nama booth...", LC_BoothRow)
LC_BoothBox.Size = UDim2.new(1,-48,1,0)

local LC_Count = Label("0 listing",11,C.Muted,{Size=UDim2.new(1,0,0,16),Position=UDim2.fromOffset(0,90)},P_Listing)

local LC_Scroll = ScrollFrame({Size=UDim2.new(1,0,1,-110),Position=UDim2.fromOffset(0,108)},P_Listing)
New("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},LC_Scroll)

local LC_SortCycle = {"Rarity","Name","Price"}
local LC_SortIdx   = 1

LC_SortBtn.MouseButton1Click:Connect(function()
    LC_SortIdx = LC_SortIdx % #LC_SortCycle + 1
    State.BoothSort = LC_SortCycle[LC_SortIdx]
    State.BoothAsc  = not State.BoothAsc
    LC_SortBtn.Text = "↕ "..State.BoothSort..(State.BoothAsc and "↑" or "↓")
    RefreshListing()
end)
LC_Search:GetPropertyChangedSignal("Text"):Connect(function()
    State.BoothQuery=LC_Search.Text:lower(); RefreshListing()
end)
LC_BoothBox.FocusLost:Connect(function()
    State.BoothUUID = LC_BoothBox.Text~="" and LC_BoothBox.Text or nil
    RefreshListing()
end)
LC_RefBtn.MouseButton1Click:Connect(function()
    State.BoothUUID = LC_BoothBox.Text~="" and LC_BoothBox.Text or State.BoothUUID
    RefreshListing()
end)

RefreshListing = function()
    ClearScroll(LC_Scroll)
    if not BoothEvents then
        New("TextLabel",{Text="⚠ TradeEvents tidak tersedia di server ini.",TextSize=13,TextColor3=C.Danger,BackgroundTransparency=1,Size=UDim2.new(1,0,0,40),Font=Enum.Font.Gotham,TextWrapped=true},LC_Scroll)
        return
    end

    -- Ambil data booth
    local data = nil
    if State.BoothUUID and State.BoothUUID~="" then
        local ok, d = pcall(function()
            return BoothEvents.GetBoothData and BoothEvents.GetBoothData:InvokeServer(State.BoothUUID) or nil
        end)
        if ok then data = d end
    end

    if not data then
        -- Ambil semua listing global (GetAllListings jika ada)
        local ok, d = pcall(function()
            return BoothEvents.GetAllListings and BoothEvents.GetAllListings:InvokeServer() or nil
        end)
        if ok then data = d end
    end

    if not data then
        New("TextLabel",{
            Text="Masukkan UUID Booth di atas lalu tap 🔄, atau booth data tidak tersedia.",
            TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,60),Font=Enum.Font.Gotham,TextWrapped=true,
        },LC_Scroll)
        LC_Count.Text = "0 listing"
        return
    end

    -- Normalize data ke list item
    local items = {}
    -- Format 1: data = {listings={...}}
    -- Format 2: data = array of listing
    local listings = (type(data)=="table" and data.listings) or (type(data)=="table" and data) or {}
    for _, listing in pairs(listings) do
        if type(listing)=="table" then
            local itype = listing.ItemType or listing.type or listing.Type or ""
            -- Hanya show Pet (dan jika query cocok)
            if itype=="Pet" or itype=="" then
                local item = {
                    id           = listing.ItemId or listing.id or "",
                    type         = itype,
                    data         = listing.ItemData or listing.data or listing.PetData or {},
                    listingOwner = listing.Owner or listing.listingOwner,
                    listingUUID  = listing.UUID or listing.listingUUID or listing.id,
                    listingPrice = listing.Price or listing.listingPrice or 0,
                    seller       = listing.sellerName or (listing.Owner and listing.Owner.Name),
                }
                -- Normalize pet data
                if item.data.PetType == nil and listing.PetType then
                    item.data.PetType = listing.PetType
                end
                local q = State.BoothQuery
                if q=="" or GetItemName(item):lower():find(q,1,true) then
                    table.insert(items, item)
                end
            end
        end
    end

    items = SortItems(items, State.BoothSort, State.BoothAsc)
    State.BoothItems = items
    LC_Count.Text = #items.." listing ditemukan"

    local myId = LocalPlayer.UserId
    for i, item in ipairs(items) do
        local isOwn = item.listingOwner and (
            (type(item.listingOwner)=="table" and item.listingOwner.UserId==myId)
            or item.listingOwner==myId
        )
        local card = ItemCard(item, LC_Scroll, {
            showPrice  = true,
            showBuy    = not isOwn,
            showRemove = isOwn,
            onAction   = function(it)
                if isOwn then OpenRemovePrompt(it)
                else          OpenBuyPrompt(it)
                end
            end,
        })
        card.LayoutOrder = i
    end
end

-- ============================================================
-- PANEL: MY BOOTH
-- ============================================================
local P_MyBooth = MakePanel("MyBooth")

Label("📦 Booth Saya",16,C.Text,{Size=UDim2.new(1,0,0,24),Font=Enum.Font.GothamBold},P_MyBooth)

local MB_BtnRow = New("Frame",{Size=UDim2.new(1,0,0,44),Position=UDim2.fromOffset(0,28),BackgroundTransparency=1},P_MyBooth)
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),VerticalAlignment=Enum.VerticalAlignment.Center},MB_BtnRow)
local MB_BtnAdd     = Btn("+ Listing Baru",C.Accent,C.White,{Size=UDim2.fromOffset(130,38),TextSize=12},MB_BtnRow)
local MB_BtnUnclaim = Btn("❌ Unclaim",C.Danger,C.White,{Size=UDim2.fromOffset(100,38),TextSize=12},MB_BtnRow)

local MB_Search = TBox("🔍 Cari di booth...", P_MyBooth)
MB_Search.Size = UDim2.new(1,0,0,38)
MB_Search.Position = UDim2.fromOffset(0, 78)

local MB_Count = Label("0 item",11,C.Muted,{Size=UDim2.new(1,0,0,16),Position=UDim2.fromOffset(0,122)},P_MyBooth)

local MB_Scroll = ScrollFrame({Size=UDim2.new(1,0,1,-142),Position=UDim2.fromOffset(0,140)},P_MyBooth)
New("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},MB_Scroll)

MB_BtnAdd.MouseButton1Click:Connect(function() SetTab("Inventory") end)
MB_BtnUnclaim.MouseButton1Click:Connect(function()
    pcall(function()
        if BoothEvents and BoothEvents.RemoveBooth then
            BoothEvents.RemoveBooth:FireServer()
        end
    end)
    task.wait(0.5); RefreshMyBooth()
end)
MB_Search:GetPropertyChangedSignal("Text"):Connect(function() RefreshMyBooth() end)

RefreshMyBooth = function()
    ClearScroll(MB_Scroll)
    -- Ambil listing milik sendiri
    local ok, data = pcall(function()
        return BoothEvents and BoothEvents.GetMyListings and BoothEvents.GetMyListings:InvokeServer() or nil
    end)
    if not ok or not data then
        New("TextLabel",{Text="Data booth tidak tersedia. Pastikan kamu sudah claim booth di Trade World.",TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,Size=UDim2.new(1,0,0,60),Font=Enum.Font.Gotham,TextWrapped=true},MB_Scroll)
        MB_Count.Text = "0 item"
        return
    end
    local query = MB_Search.Text:lower()
    local items = {}
    for _, listing in pairs(type(data)=="table" and data or {}) do
        if type(listing)=="table" then
            local item = {
                id=listing.ItemId or listing.id or "",
                type=listing.ItemType or "Pet",
                data=listing.ItemData or listing.data or {},
                listingUUID=listing.UUID or listing.id,
                listingPrice=listing.Price or 0,
            }
            if query=="" or GetItemName(item):lower():find(query,1,true) then
                table.insert(items, item)
            end
        end
    end
    items=SortItems(items,"Rarity",false)
    MB_Count.Text=#items.." item di booth kamu"
    for i,item in ipairs(items) do
        local c=ItemCard(item,MB_Scroll,{showPrice=true,showRemove=true,onAction=OpenRemovePrompt})
        c.LayoutOrder=i
    end
end

-- ============================================================
-- PANEL: INVENTORI
-- ============================================================
local P_Inv = MakePanel("Inventory")

-- Category bar
local INV_CatBar = New("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1},P_Inv)
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center},INV_CatBar)
local INV_CATS = {{"Pets","🐾 Pet"},{"Plants","🌿 Plant"},{"Seeds","🌱 Benih"}}
local INV_CatBtns = {}
for _, cat in ipairs(INV_CATS) do
    local b=Btn(cat[2], C.Card, C.Muted,{Size=UDim2.fromOffset(90,34),TextSize=12},INV_CatBar)
    INV_CatBtns[cat[1]]=b
    b.MouseButton1Click:Connect(function()
        State.InvCategory=cat[1]
        for id,btn in pairs(INV_CatBtns) do
            btn.BackgroundColor3=(id==cat[1]) and C.Primary or C.Card
            btn.TextColor3=(id==cat[1]) and C.White or C.Muted
        end
        RefreshInventory()
    end)
end
INV_CatBtns["Pets"].BackgroundColor3=C.Primary
INV_CatBtns["Pets"].TextColor3=C.White

local INV_Search = TBox("🔍 Cari item...",P_Inv)
INV_Search.Size=UDim2.new(1,0,0,38)
INV_Search.Position=UDim2.fromOffset(0,46)

-- Price input + listing button
local INV_PriceRow = New("Frame",{Size=UDim2.new(1,0,0,44),Position=UDim2.fromOffset(0,90),BackgroundColor3=C.Card,BorderSizePixel=0},P_Inv)
Corner(10,INV_PriceRow)
Pad(4,4,10,10,INV_PriceRow)
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),VerticalAlignment=Enum.VerticalAlignment.Center},INV_PriceRow)
Label("Harga:",12,C.Muted,{Size=UDim2.fromOffset(52,36)},INV_PriceRow)
local INV_PriceBox=TBox("contoh: 5000",INV_PriceRow)
INV_PriceBox.Size=UDim2.new(1,-170,1,0)
local INV_ListBtn=Btn("📋 Listing",C.Primary,C.White,{Size=UDim2.fromOffset(90,36),TextSize=13},INV_PriceRow)

local INV_Selected=Label("Pilih item di bawah lalu tap Listing",11,C.Muted,{Size=UDim2.new(1,0,0,16),Position=UDim2.fromOffset(0,138)},P_Inv)
local INV_Count=Label("0 item",11,C.Muted,{Size=UDim2.new(1,0,0,16),Position=UDim2.fromOffset(0,156)},P_Inv)

local INV_Scroll=ScrollFrame({Size=UDim2.new(1,0,1,-176),Position=UDim2.fromOffset(0,174)},P_Inv)
New("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},INV_Scroll)

local INV_TypeMap={Pets={"Pet"},Plants={"Holdable"},Seeds={"Seed","SeedPack"}}

INV_Search:GetPropertyChangedSignal("Text"):Connect(function() State.InvQuery=INV_Search.Text:lower(); RefreshInventory() end)

INV_ListBtn.MouseButton1Click:Connect(function()
    if not State.SelectedItem then Toast("⚠ Pilih item terlebih dahulu!",C.Danger); return end
    local price=tonumber(INV_PriceBox.Text)
    if not price or price<=0 then Toast("⚠ Masukkan harga yang valid!",C.Danger); return end
    local ok,res=pcall(function()
        if BoothEvents and BoothEvents.CreateListing then
            return BoothEvents.CreateListing:InvokeServer(State.SelectedItem.type,State.SelectedItem.id,price)
        end
        return false
    end)
    if ok and res then
        State.SelectedItem=nil
        INV_PriceBox.Text=""
        INV_Selected.Text="Pilih item di bawah lalu tap Listing"
        INV_Selected.TextColor3=C.Muted
        Toast("✅ Item berhasil di-listing!",C.Primary)
        RefreshInventory()
        RefreshMyBooth()
    else
        Toast("❌ Gagal listing item.",C.Danger)
    end
end)

RefreshInventory = function()
    ClearScroll(INV_Scroll)
    local ok, data = pcall(function()
        -- Coba ambil data inventori dari DataService atau langsung dari BoothEvents
        if BoothEvents and BoothEvents.GetInventory then
            return BoothEvents.GetInventory:InvokeServer()
        end
        return nil
    end)
    if not ok or not data then
        New("TextLabel",{Text="Data inventori tidak tersedia.",TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,Size=UDim2.new(1,0,0,40),Font=Enum.Font.Gotham,TextWrapped=true},INV_Scroll)
        INV_Count.Text="0 item"
        return
    end
    local allowed=INV_TypeMap[State.InvCategory] or {}
    local query=State.InvQuery
    local items={}
    for _, item in pairs(type(data)=="table" and data or {}) do
        if type(item)=="table" then
            local itype=item.ItemType or item.type or ""
            if table.find(allowed, itype) or #allowed==0 then
                local it={id=item.ItemId or item.id or "",type=itype,data=item.ItemData or item.data or {}}
                if query=="" or GetItemName(it):lower():find(query,1,true) then
                    table.insert(items,it)
                end
            end
        end
    end
    items=SortItems(items,State.InvSort,State.InvAsc)
    INV_Count.Text=#items.." item"
    for i,item in ipairs(items) do
        local card=ItemCard(item,INV_Scroll,{
            showSelect=true,
            onAction=function(it)
                State.SelectedItem=it
                INV_Selected.Text="✅ Dipilih: "..GetItemName(it)
                INV_Selected.TextColor3=C.Primary
                for _,c in INV_Scroll:GetChildren() do
                    if c:IsA("Frame") then
                        TweenService:Create(c,TweenInfo.new(0.1),{BackgroundColor3=C.Card}):Play()
                    end
                end
                TweenService:Create(card,TweenInfo.new(0.1),{BackgroundColor3=C.Accent:Lerp(C.Card,0.55)}):Play()
            end,
        })
        card.LayoutOrder=i
    end
end

-- ============================================================
-- PANEL: FIND SELLER
-- ============================================================
local P_FS = MakePanel("FindSeller")

Label("🔍 Find Seller",16,C.Text,{Size=UDim2.new(1,0,0,24),Font=Enum.Font.GothamBold},P_FS)
Label("Cari seller online berdasarkan jenis & nama item.",12,C.Muted,{Size=UDim2.new(1,0,0,18),Position=UDim2.fromOffset(0,28),TextWrapped=true},P_FS)

local FS_TypeBox=TBox("Tipe (misal: Pet)",P_FS)
FS_TypeBox.Size=UDim2.new(1,0,0,42)
FS_TypeBox.Position=UDim2.fromOffset(0,52)

local FS_NameBox=TBox("Nama item (misal: Capybara)",P_FS)
FS_NameBox.Size=UDim2.new(1,0,0,42)
FS_NameBox.Position=UDim2.fromOffset(0,100)

local FS_BtnSearch=Btn("🔍 Cari Seller",C.Primary,C.White,{
    Size=UDim2.new(1,0,0,48),Position=UDim2.fromOffset(0,150),TextSize=16,
},P_FS)

local FS_Status=Label("Isi tipe & nama, lalu tap Cari.",13,C.Muted,{
    Size=UDim2.new(1,0,0,20),Position=UDim2.fromOffset(0,206),
    TextXAlignment=Enum.TextXAlignment.Center,
},P_FS)

local FS_ResultBox=New("Frame",{
    Size=UDim2.new(1,0,0,100),Position=UDim2.fromOffset(0,232),
    BackgroundColor3=C.Card,BorderSizePixel=0,Visible=false,
},P_FS)
Corner(12,FS_ResultBox)
Stroke(1.5,C.Primary:Lerp(C.Border,0.4),FS_ResultBox)
Pad(12,12,14,14,FS_ResultBox)

local FS_RName=Label("",15,C.Text,{Size=UDim2.new(1,0,0,22),Font=Enum.Font.GothamBold},FS_ResultBox)
local FS_RServer=Label("",12,C.Muted,{Size=UDim2.new(1,0,0,18),Position=UDim2.fromOffset(0,24)},FS_ResultBox)
local FS_RPrice=Label("",15,C.Primary,{Size=UDim2.new(1,-100,0,22),Position=UDim2.fromOffset(0,46),Font=Enum.Font.GothamBold},FS_ResultBox)
local FS_HopBtn=Btn("⚡ Hop Server",C.Primary,C.White,{
    Size=UDim2.fromOffset(106,36),Position=UDim2.new(1,-106,1,-46),TextSize=12,
},FS_ResultBox)

local FS_CurrentListing=nil

FS_BtnSearch.MouseButton1Click:Connect(function()
    if State.FSSearching then return end
    local itype=FS_TypeBox.Text
    local iname=FS_NameBox.Text
    if itype=="" or iname=="" then
        FS_Status.Text="⚠ Isi tipe dan nama item!"
        FS_Status.TextColor3=C.Danger
        return
    end
    State.FSSearching=true
    FS_Status.Text="⏳ Mencari seller online..."
    FS_Status.TextColor3=C.Muted
    FS_ResultBox.Visible=false
    FS_BtnSearch.Text="⏳ Mencari..."

    task.spawn(function()
        local ok, listing = pcall(function()
            if TradeEvents and TradeEvents.TokenRAPs and TradeEvents.TokenRAPs.FindSellers then
                return TradeEvents.TokenRAPs.FindSellers:InvokeServer(itype, {Name=iname, ItemType=itype})
            end
            return nil
        end)
        State.FSSearching=false
        FS_BtnSearch.Text="🔍 Cari Seller"
        if ok and listing then
            FS_CurrentListing=listing
            FS_ResultBox.Visible=true
            FS_RName.Text="✅ "..iname.." ditemukan!"
            FS_RServer.Text="Server: "..(listing.server or "Server Online")
            FS_RPrice.Text="Harga: "..(listing.price and Fmt(listing.price).." token" or "???")
            FS_Status.Text="Seller ketemu! Tap Hop Server untuk pindah."
            FS_Status.TextColor3=C.Primary
        else
            FS_ResultBox.Visible=false
            FS_Status.Text="❌ Tidak ada seller online untuk item ini."
            FS_Status.TextColor3=C.Danger
        end
    end)
end)

FS_HopBtn.MouseButton1Click:Connect(function()
    if not FS_CurrentListing then return end
    FS_HopBtn.Text="⏳ Hopping..."
    pcall(function()
        if TradeEvents and TradeEvents.TokenRAPs and TradeEvents.TokenRAPs.TeleportToListing then
            TradeEvents.TokenRAPs.TeleportToListing:InvokeServer(FS_CurrentListing)
        end
    end)
    task.delay(2,function()
        FS_HopBtn.Text="⚡ Hop Server"
        FS_ResultBox.Visible=false
        FS_CurrentListing=nil
        FS_Status.Text="Teleport dikirim! Tunggu loading..."
        FS_Status.TextColor3=C.Primary
    end)
end)

-- ============================================================
-- PANEL: RIWAYAT TRADE
-- ============================================================
local P_Hist = MakePanel("History")

Label("📜 Riwayat Trade",16,C.Text,{Size=UDim2.new(1,0,0,24),Font=Enum.Font.GothamBold},P_Hist)

local HIST_TopBar=New("Frame",{Size=UDim2.new(1,0,0,40),Position=UDim2.fromOffset(0,28),BackgroundTransparency=1},P_Hist)
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center},HIST_TopBar)
local HIST_Filters={"All","Dibeli","Dijual"}
local HIST_FBtns={}
for _,f in ipairs(HIST_Filters) do
    local b=Btn(f,C.Card,C.Muted,{Size=UDim2.fromOffset(72,34),TextSize=12},HIST_TopBar)
    HIST_FBtns[f]=b
    b.MouseButton1Click:Connect(function()
        State.HistFilter=f
        for fk,fb in pairs(HIST_FBtns) do
            fb.BackgroundColor3=(fk==f) and C.Primary or C.Card
            fb.TextColor3=(fk==f) and C.White or C.Muted
        end
        RefreshHistory()
    end)
end
HIST_FBtns["All"].BackgroundColor3=C.Primary
HIST_FBtns["All"].TextColor3=C.White
local HIST_SortBtn=Btn("↓ Terbaru",C.Card,C.Text,{Size=UDim2.fromOffset(88,34),TextSize=12},HIST_TopBar)
HIST_SortBtn.MouseButton1Click:Connect(function()
    State.HistAsc=not State.HistAsc
    HIST_SortBtn.Text=State.HistAsc and "↑ Terlama" or "↓ Terbaru"
    RefreshHistory()
end)

local HIST_Search=TBox("🔍 Cari player/item...",P_Hist)
HIST_Search.Size=UDim2.new(1,0,0,38)
HIST_Search.Position=UDim2.fromOffset(0,74)

local HIST_Count=Label("0 entri",11,C.Muted,{Size=UDim2.new(1,0,0,16),Position=UDim2.fromOffset(0,118)},P_Hist)
local HIST_Scroll=ScrollFrame({Size=UDim2.new(1,0,1,-138),Position=UDim2.fromOffset(0,136)},P_Hist)
New("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},HIST_Scroll)

HIST_Search:GetPropertyChangedSignal("Text"):Connect(function() State.HistQuery=HIST_Search.Text:lower(); RefreshHistory() end)

RefreshHistory = function()
    ClearScroll(HIST_Scroll)
    local myId=LocalPlayer.UserId
    local query=State.HistQuery
    local filtered={}
    for _,log in ipairs(State.HistLogs) do
        if type(log)~="table" then goto continue end
        local isSale=(log.seller and log.seller.userId==myId) or (log.type=="Sale")
        if State.HistFilter=="Dijual" and not isSale then goto continue end
        if State.HistFilter=="Dibeli" and isSale then goto continue end
        if query~="" then
            local sn=(log.seller and log.seller.username) or ""
            local bn=(log.buyer and log.buyer.username) or ""
            local ik=""
            if log.item and log.item.data then
                ik=log.item.data.PetType or log.item.data.ItemName or ""
            end
            if not (sn:lower():find(query,1,true) or bn:lower():find(query,1,true) or ik:lower():find(query,1,true)) then goto continue end
        end
        table.insert(filtered,log)
        ::continue::
    end
    table.sort(filtered,function(a,b)
        local ta=a.finishTime or a.time or 0
        local tb=b.finishTime or b.time or 0
        return State.HistAsc and ta<tb or ta>tb
    end)
    HIST_Count.Text=#filtered.." entri"
    if #filtered==0 then
        New("TextLabel",{Text="Belum ada riwayat trade.",TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,Size=UDim2.new(1,0,0,40),Font=Enum.Font.Gotham},HIST_Scroll)
        return
    end
    for i,log in ipairs(filtered) do
        local isSale=(log.seller and log.seller.userId==myId) or (log.type=="Sale")
        local sCol=isSale and Color3.fromRGB(255,100,100) or C.Primary
        local sTxt=isSale and "Dijual" or "Dibeli"
        local partner=isSale and log.buyer or log.seller
        local pName=partner and ("@"..(partner.username or partner.Name or "???")) or "???"
        local itemKey=""
        if log.item and log.item.data then
            itemKey=log.item.data.PetType or log.item.data.ItemName or ""
        end
        local tStr=log.finishTime and os.date("%d/%m %H:%M",log.finishTime) or "???"

        local card=New("Frame",{Size=UDim2.new(1,0,0,64),BackgroundColor3=C.Card,BorderSizePixel=0},HIST_Scroll)
        Corner(10,card); Stroke(1,sCol:Lerp(C.Border,0.6),card); Pad(8,8,12,12,card)
        card.LayoutOrder=i

        local sb=New("TextLabel",{Text=sTxt,TextSize=10,TextColor3=sCol,BackgroundColor3=sCol:Lerp(C.BG,0.82),Font=Enum.Font.GothamBold,Size=UDim2.fromOffset(50,16),BorderSizePixel=0},card)
        Corner(5,sb)
        Label(pName,14,C.Text,{Size=UDim2.new(1,-120,0,18),Position=UDim2.fromOffset(58,0),Font=Enum.Font.GothamBold},card)
        Label("Item: "..itemKey,12,C.Muted,{Size=UDim2.new(1,-120,0,16),Position=UDim2.fromOffset(58,20)},card)
        Label(tStr,11,C.Dim,{Size=UDim2.new(1,-120,0,14),Position=UDim2.fromOffset(58,38)},card)
        Label(Fmt(log.price or 0),17,sCol,{
            Size=UDim2.fromOffset(100,40),Position=UDim2.new(1,-108,0,0),
            TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamBold,
        },card)
    end
end

-- Realtime history update
pcall(function()
    if TradeEvents and TradeEvents.Booths and TradeEvents.Booths.AddToHistory then
        TradeEvents.Booths.AddToHistory.OnClientEvent:Connect(function(log)
            if log then table.insert(State.HistLogs,1,log) end
            if State.Panel=="History" then RefreshHistory() end
        end)
    end
end)

-- ============================================================
-- POPUP: REMOVE LISTING
-- ============================================================
local RemovePopup=New("Frame",{
    Name="RemovePopup",
    Size=UDim2.fromOffset(math.min(WinW-32,340),170),
    Position=UDim2.fromScale(0.5,0.5),
    AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,ZIndex=50,
},ScreenGui)
Corner(14,RemovePopup)
Stroke(1.5,C.Danger:Lerp(C.Border,0.4),RemovePopup)
Pad(16,16,16,16,RemovePopup)

Label("🗑 Hapus Listing",16,C.Text,{Size=UDim2.new(1,0,0,24),Font=Enum.Font.GothamBold,ZIndex=51},RemovePopup)
local RM_Name=Label("",14,C.Muted,{Size=UDim2.new(1,0,0,20),Position=UDim2.fromOffset(0,28),ZIndex=51},RemovePopup)
Label("Yakin hapus listing ini dari booth?",12,C.Muted,{Size=UDim2.new(1,0,0,18),Position=UDim2.fromOffset(0,52),ZIndex=51},RemovePopup)

local RM_BtnRow=New("Frame",{Size=UDim2.new(1,0,0,44),Position=UDim2.new(0,0,1,-52),BackgroundTransparency=1,ZIndex=51},RemovePopup)
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,10),HorizontalAlignment=Enum.HorizontalAlignment.Right},RM_BtnRow)
local RM_Cancel=Btn("Batal",C.Card,C.Text,{Size=UDim2.fromOffset(90,40),ZIndex=52},RM_BtnRow)
local RM_Confirm=Btn("Hapus",C.Danger,C.White,{Size=UDim2.fromOffset(90,40),ZIndex=52},RM_BtnRow)

local _removeTarget=nil
OpenRemovePrompt=function(item)
    _removeTarget=item
    RM_Name.Text=GetItemName(item)
    RemovePopup.Visible=true
end
RM_Cancel.MouseButton1Click:Connect(function() RemovePopup.Visible=false; _removeTarget=nil end)
RM_Confirm.MouseButton1Click:Connect(function()
    if not _removeTarget then return end
    local t=_removeTarget; _removeTarget=nil; RemovePopup.Visible=false
    task.spawn(function()
        local ok,res=pcall(function()
            if BoothEvents and BoothEvents.RemoveListing then
                return BoothEvents.RemoveListing:InvokeServer(t.listingUUID)
            end
            return false
        end)
        if ok and res then
            Toast("✅ Listing "..GetItemName(t).." dihapus!",C.Primary)
            RefreshMyBooth(); RefreshListing()
        else
            Toast("❌ Gagal hapus listing.",C.Danger)
        end
    end)
end)

-- ============================================================
-- BUY ITEM (instant, tanpa popup)
-- ============================================================
OpenBuyPrompt=function(item)
    Toast("⏳ Membeli "..GetItemName(item).."...",C.Muted,1.5)
    task.spawn(function()
        local ok,res=pcall(function()
            if BoothEvents and BoothEvents.BuyListing then
                return BoothEvents.BuyListing:InvokeServer(item.listingOwner, item.listingUUID)
            end
            return false
        end)
        if ok and res then
            Toast("✅ Berhasil membeli "..GetItemName(item).."!",C.Primary)
            RefreshListing()
        else
            Toast("❌ Gagal membeli. Coba lagi!",C.Danger)
        end
    end)
end

-- ============================================================
-- TRADE REQUEST POPUP
-- ============================================================
local ReqPopup=New("Frame",{
    Name="ReqPopup",
    Size=UDim2.fromOffset(math.min(WinW-32,310),155),
    Position=UDim2.new(1,-320,1,-175),
    BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,ZIndex=80,
},ScreenGui)
Corner(14,ReqPopup)
Stroke(1.5,C.Accent:Lerp(C.Border,0.3),ReqPopup)
Pad(14,14,14,14,ReqPopup)

local Req_Avatar=New("ImageLabel",{Size=UDim2.fromOffset(44,44),BackgroundColor3=C.Card,BorderSizePixel=0,ZIndex=81},ReqPopup)
Corner(22,Req_Avatar)
local Req_Name=Label("",14,C.Text,{Size=UDim2.new(1,-56,0,22),Position=UDim2.fromOffset(52,0),Font=Enum.Font.GothamBold,ZIndex=81},ReqPopup)
Label("mengajakmu trade!",12,C.Muted,{Size=UDim2.new(1,-56,0,18),Position=UDim2.fromOffset(52,22),ZIndex=81},ReqPopup)
local Req_Timer=New("Frame",{Size=UDim2.new(1,0,0,4),Position=UDim2.fromOffset(0,52),BackgroundColor3=C.Accent,BorderSizePixel=0,ZIndex=81},ReqPopup)
Corner(2,Req_Timer)

local Req_BtnRow=New("Frame",{Size=UDim2.new(1,0,0,44),Position=UDim2.new(0,0,1,-52),BackgroundTransparency=1,ZIndex=81},ReqPopup)
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,10)},Req_BtnRow)
local Req_Decline=Btn("❌ Tolak",C.Danger,C.White,{Size=UDim2.fromOffset(110,40),ZIndex=82},Req_BtnRow)
local Req_Accept=Btn("✅ Terima",C.Primary,C.White,{Size=UDim2.fromOffset(130,40),ZIndex=82},Req_BtnRow)

local _reqTimer=nil
local function RespondRequest(accepted)
    if not State.PendReqId then return end
    pcall(function()
        if TradeEvents and TradeEvents.RespondRequest then
            TradeEvents.RespondRequest:FireServer(State.PendReqId, accepted)
        end
    end)
    State.PendReqId=nil
    if _reqTimer then task.cancel(_reqTimer) end
    ReqPopup.Visible=false
end
Req_Accept.MouseButton1Click:Connect(function() RespondRequest(true) end)
Req_Decline.MouseButton1Click:Connect(function() RespondRequest(false) end)

pcall(function()
    if TradeEvents and TradeEvents.SendRequest then
        TradeEvents.SendRequest.OnClientEvent:Connect(function(reqId, sender, expireTime)
            State.PendReqId=reqId
            Req_Name.Text=sender and sender.Name or "???"
            Req_Avatar.Image=sender and ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(sender.UserId) or ""
            Req_Timer.Size=UDim2.new(1,0,0,4)
            ReqPopup.Visible=true
            local dur=(expireTime and expireTime-workspace:GetServerTimeNow()) or 30
            if _reqTimer then task.cancel(_reqTimer) end
            TweenService:Create(Req_Timer,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,4),BackgroundColor3=C.Danger}):Play()
            _reqTimer=task.delay(dur,function()
                if State.PendReqId==reqId then
                    State.PendReqId=nil; ReqPopup.Visible=false
                end
            end)
        end)
    end
end)

-- ============================================================
-- OPEN / CLOSE WINDOW
-- ============================================================
BtnClose.MouseButton1Click:Connect(function()
    TweenService:Create(MainWin,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play()
    task.delay(0.15,function() MainWin.Visible=false; MainWin.BackgroundTransparency=0 end)
end)

OpenBtn.MouseButton1Click:Connect(function()
    if MainWin.Visible then
        TweenService:Create(MainWin,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play()
        task.delay(0.15,function() MainWin.Visible=false; MainWin.BackgroundTransparency=0 end)
    else
        MainWin.Visible=true
        MainWin.BackgroundTransparency=1
        TweenService:Create(MainWin,TweenInfo.new(0.2),{BackgroundTransparency=0}):Play()
        SetTab(State.Panel)
    end
end)

-- ============================================================
-- DRAGGABLE (drag dari header)
-- ============================================================
do
    local drag,dragStart,startPos
    Header.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; dragStart=inp.Position; startPos=MainWin.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-dragStart
            MainWin.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=false
        end
    end)
end

-- ============================================================
-- INIT
-- ============================================================
SetTab("Listing")

print("[TradeGUI] ✅ GUI dimuat! Tap tombol 🏪 Trade untuk membuka.")
if not TradeEvents then
    warn("[TradeGUI] ⚠ TradeEvents tidak ditemukan di ReplicatedStorage.GameEvents. Pastikan script dijalankan dalam game Grow a Garden!")
end
