--[[
    TradeGUI.lua — LocalScript
    Dibuat dari 17 script: TradeBoothListingController, TradeBoothBuyItemController,
    TradeBoothCreateListingController, TradeBoothHistoryController,
    TradeBoothInventoryController, TradeBoothSkinUIController,
    TradeFindSellerController, TradeInputService, TradeInventoryController,
    TradeItemHoverController, TradeRequestController, TradeUIUtils,
    TradeWorldController, TradingController, TradingUserInterfaceController,
    TradeBoothController, TradeBoothRemoveListingController

    Letakkan di: StarterPlayer > StarterPlayerScripts (sebagai LocalScript)
    Pastikan semua RemoteEvent & ReplicatedStorage sudah sesuai dengan game asli.
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- REMOTE EVENTS (sesuai struktur game Grow a Garden)
-- ============================================================
local TradeEvents = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("TradeEvents")
local BoothEvents = TradeEvents:WaitForChild("Booths")

-- ============================================================
-- MODUL GAME (untuk nama, gambar, rarity, format angka)
-- ============================================================
local ItemNameFinder   = require(ReplicatedStorage.Modules.ItemNameFinder)
local ItemImageFinder  = require(ReplicatedStorage.Modules.ItemImageFinder)
local ItemRarityFinder = require(ReplicatedStorage.Modules.ItemRarityFinder)
local NumberUtil       = require(ReplicatedStorage.Modules.NumberUtil)
local GGStaticData     = require(ReplicatedStorage.Modules.GardenGuideModules.DataModules.GGStaticData)
local PetUtilities     = require(ReplicatedStorage.Modules.PetServices.PetUtilities)
local ReplicationReceiver = require(ReplicatedStorage.Modules.ReplicationReciever)
local DataService      = require(ReplicatedStorage.Modules.DataService)
local TradeData        = require(ReplicatedStorage.Data.TradeData)
local TradeBoothsData  = require(ReplicatedStorage.Data.TradeBoothsData)

-- ============================================================
-- STATE GLOBAL
-- ============================================================
local State = {
    -- Booth Listing
    BoothUUID        = nil,
    BoothSortType    = "Rarity",
    BoothSortAsc     = true,
    BoothQuery       = "",
    BoothItems       = {},

    -- My Inventory
    InvCategory      = "Pets",
    InvSortType      = "Rarity",
    InvSortAsc       = true,
    InvQuery         = "",
    InvItems         = {},
    SelectedItem     = nil,    -- item yang akan di-listing
    ListingPrice     = 0,

    -- Trade History
    HistoryFilter    = "All",  -- All / Purchases / Sales
    HistoryAsc       = false,
    HistoryQuery     = "",
    HistoryLogs      = {},

    -- Find Seller
    FindSellerSearching = false,

    -- Live Trade
    CurrentTradeId   = nil,
    CurrentTradeReplicator = nil,

    -- Trade Request
    PendingRequestId = nil,
    PendingRequester = nil,

    -- Remove Listing
    RemoveTarget     = nil,

    -- Buy Item
    BuyTarget        = nil,

    -- Active panel
    CurrentPanel     = "Listing",
}

-- ============================================================
-- WARNA TEMA
-- ============================================================
local C = {
    BG          = Color3.fromRGB(18, 20, 28),
    Panel       = Color3.fromRGB(25, 28, 40),
    Card        = Color3.fromRGB(32, 36, 52),
    CardHover   = Color3.fromRGB(40, 45, 65),
    Border      = Color3.fromRGB(55, 60, 85),
    Primary     = Color3.fromRGB(72, 199, 142),
    PrimaryDark = Color3.fromRGB(40, 140, 100),
    Danger      = Color3.fromRGB(220, 60, 60),
    DangerDark  = Color3.fromRGB(160, 40, 40),
    Accent      = Color3.fromRGB(90, 140, 255),
    Gold        = Color3.fromRGB(255, 200, 60),
    Text        = Color3.fromRGB(230, 235, 255),
    TextMuted   = Color3.fromRGB(120, 130, 160),
    TextDim     = Color3.fromRGB(80, 90, 120),
    White       = Color3.new(1,1,1),
    Black       = Color3.new(0,0,0),
}

local RARITY_COLORS = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(80, 200, 100),
    Rare      = Color3.fromRGB(80, 140, 255),
    Legendary = Color3.fromRGB(180, 80, 255),
    Mythic    = Color3.fromRGB(255, 140, 40),
    Divine    = Color3.fromRGB(255, 220, 40),
}

-- ============================================================
-- HELPER UI
-- ============================================================
local function NewInstance(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function MakeCorner(radius, parent)
    return NewInstance("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function MakePadding(t, b, l, r, parent)
    return NewInstance("UIPadding", {
        PaddingTop    = UDim.new(0, t),
        PaddingBottom = UDim.new(0, b),
        PaddingLeft   = UDim.new(0, l),
        PaddingRight  = UDim.new(0, r),
    }, parent)
end

local function MakeStroke(thickness, color, parent)
    return NewInstance("UIStroke", {
        Thickness = thickness,
        Color     = color,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function MakeLabel(text, size, color, props, parent)
    local lbl = NewInstance("TextLabel", {
        Text            = text,
        TextSize        = size,
        TextColor3      = color,
        BackgroundTransparency = 1,
        Font            = Enum.Font.GothamBold,
        TextXAlignment  = Enum.TextXAlignment.Left,
        TextTruncate    = Enum.TextTruncate.AtEnd,
    }, nil)
    if props then for k, v in pairs(props) do lbl[k] = v end end
    if parent then lbl.Parent = parent end
    return lbl
end

local function MakeButton(text, bgColor, textColor, props, parent)
    local btn = NewInstance("TextButton", {
        Text            = text,
        TextSize        = 14,
        TextColor3      = textColor or C.White,
        BackgroundColor3= bgColor or C.Primary,
        Font            = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, nil)
    if props then for k, v in pairs(props) do btn[k] = v end end
    MakeCorner(8, btn)
    if parent then btn.Parent = parent end
    -- Hover animation
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = bgColor and bgColor:Lerp(C.White, 0.15) or C.PrimaryDark}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = bgColor or C.Primary}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = bgColor and bgColor:Lerp(C.Black, 0.2) or C.PrimaryDark}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = bgColor or C.Primary}):Play()
    end)
    return btn
end

local function MakeTextBox(placeholder, parent)
    local box = NewInstance("TextBox", {
        PlaceholderText      = placeholder,
        PlaceholderColor3    = C.TextMuted,
        Text                 = "",
        TextSize             = 13,
        TextColor3           = C.Text,
        BackgroundColor3     = C.Card,
        Font                 = Enum.Font.Gotham,
        BorderSizePixel      = 0,
        ClearTextOnFocus     = false,
        TextXAlignment       = Enum.TextXAlignment.Left,
    }, nil)
    MakeCorner(8, box)
    MakeStroke(1, C.Border, box)
    MakePadding(0, 0, 10, 10, box)
    if parent then box.Parent = parent end
    return box
end

local function MakeScrollingFrame(props, parent)
    local sf = NewInstance("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 4,
        ScrollBarImageColor3   = C.Border,
        CanvasSize             = UDim2.new(0,0,0,0),
        AutomaticCanvasSize    = Enum.AutomaticCanvasSize.Y,
        ScrollingDirection     = Enum.ScrollingDirection.Y,
    }, nil)
    if props then for k, v in pairs(props) do sf[k] = v end end
    if parent then sf.Parent = parent end
    return sf
end

-- Tween popup open/close
local function TweenOpen(frame)
    frame.Visible = true
    frame.BackgroundTransparency = 1
    TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
end

local function TweenClose(frame, callback)
    TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
    task.delay(0.15, function()
        frame.Visible = false
        if callback then callback() end
    end)
end

-- Format angka
local function Fmt(n)
    if not n then return "???" end
    if n >= 1e9 then return string.format("%.1fB", n/1e9) end
    if n >= 1e6 then return string.format("%.1fM", n/1e6) end
    if n >= 1e3 then return string.format("%.1fK", n/1e3) end
    return tostring(math.floor(n))
end

-- Ambil nama item dari data listing
local function GetItemName(item)
    local key = item.data.Name or item.data.ItemName or item.data.PetType or item.data.SkinID or "Unknown"
    local ok, name = pcall(ItemNameFinder, key, item.type)
    return ok and name or key
end

-- Ambil image item
local function GetItemImage(item)
    local key = item.data.Name or item.data.ItemName or item.data.PetType or item.data.SkinID or ""
    local ok, img = pcall(ItemImageFinder, key, item.type)
    return ok and img or "rbxassetid://0"
end

-- Ambil rarity item
local function GetItemRarity(item)
    local key = item.data.Name or item.data.ItemName or item.data.PetType or item.data.SkinID or ""
    local ok, rar = pcall(ItemRarityFinder, key, item.type)
    return ok and rar or "Common"
end

-- Rarity color
local function RarityColor(rar)
    return RARITY_COLORS[rar] or C.TextMuted
end

-- Hitung berat pet
local function CalcWeight(item)
    if item.data.PetType and item.data.PetData then
        local ok, w = pcall(function()
            return PetUtilities:CalculateWeight(item.data.PetData.BaseWeight, item.data.PetData.Level)
        end)
        if ok and w then return string.format("%.2f kg", w) end
    end
    return "N/A"
end

-- Sort items
local RARITY_ORDER = {Common=1, Uncommon=2, Rare=3, Legendary=4, Mythic=5, Divine=6}
local function SortItems(items, sortType, ascending)
    local sorted = table.clone(items)
    table.sort(sorted, function(a, b)
        local va, vb
        if sortType == "Name" then
            va = GetItemName(a)
            vb = GetItemName(b)
            if ascending then return va < vb else return va > vb end
        elseif sortType == "Rarity" then
            va = RARITY_ORDER[GetItemRarity(a)] or 0
            vb = RARITY_ORDER[GetItemRarity(b)] or 0
        elseif sortType == "Price" then
            va = a.listingPrice or 0
            vb = b.listingPrice or 0
        end
        if va == vb then return GetItemName(a) < GetItemName(b) end
        if ascending then return va < vb else return va > vb end
    end)
    return sorted
end

-- ============================================================
-- BUAT SCREENGUI
-- ============================================================
local ScreenGui = NewInstance("ScreenGui", {
    Name            = "TradeGUI",
    ResetOnSpawn    = false,
    IgnoreGuiInset  = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local MainWindow = NewInstance("Frame", {
    Name             = "MainWindow",
    Size             = UDim2.fromOffset(820, 560),
    Position         = UDim2.fromScale(0.5, 0.5),
    AnchorPoint      = Vector2.new(0.5, 0.5),
    BackgroundColor3 = C.BG,
    BorderSizePixel  = 0,
    Visible          = false,
}, ScreenGui)
MakeCorner(14, MainWindow)
MakeStroke(1.5, C.Border, MainWindow)
MakePadding(0,0,0,0, MainWindow)

-- Drop shadow
local Shadow = NewInstance("ImageLabel", {
    Name = "Shadow",
    Size = UDim2.new(1, 40, 1, 40),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6015897843",
    ImageColor3 = Color3.new(0,0,0),
    ImageTransparency = 0.5,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    ZIndex = 0,
}, MainWindow)

-- Header
local Header = NewInstance("Frame", {
    Name             = "Header",
    Size             = UDim2.new(1, 0, 0, 52),
    BackgroundColor3 = C.Panel,
    BorderSizePixel  = 0,
}, MainWindow)
MakeCorner(14, Header)
-- Patch bawah header
NewInstance("Frame", {
    Size = UDim2.new(1,0,0,14),
    Position = UDim2.new(0,0,1,-14),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, Header)

-- Logo & Title di header
local HeaderTitle = MakeLabel("🌱 Trade Market — Grow a Garden", 16, C.Primary, {
    Size = UDim2.new(1, -180, 1, 0),
    Position = UDim2.fromOffset(16, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

-- Tombol close
local BtnClose = MakeButton("✕", Color3.fromRGB(200,60,60), C.White, {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1, -44, 0.5, -16),
    TextSize = 16,
}, Header)

BtnClose.MouseButton1Click:Connect(function()
    TweenClose(MainWindow)
end)

-- Tab bar
local TabBar = NewInstance("Frame", {
    Name             = "TabBar",
    Size             = UDim2.new(0, 180, 1, -52),
    Position         = UDim2.fromOffset(0, 52),
    BackgroundColor3 = C.Panel,
    BorderSizePixel  = 0,
}, MainWindow)
-- Patch kanan tabbar
NewInstance("Frame", {
    Size = UDim2.new(0,8,1,0),
    Position = UDim2.new(1,-8,0,0),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, TabBar)

-- Content area
local ContentArea = NewInstance("Frame", {
    Name             = "ContentArea",
    Size             = UDim2.new(1, -180, 1, -52),
    Position         = UDim2.new(0, 180, 0, 52),
    BackgroundColor3 = C.BG,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
}, MainWindow)
MakeStroke(1, C.Border:Lerp(C.BG, 0.5), ContentArea)

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local Panels = {}
local TabButtons = {}
local TabList = NewInstance("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, TabBar)
MakePadding(8, 8, 8, 8, TabBar)

local TAB_DEFS = {
    {id="Listing",   icon="🏪", label="Daftar Dagangan", order=1},
    {id="MyBooth",   icon="📦", label="Booth Saya",      order=2},
    {id="Inventory", icon="🎒", label="Inventori Saya",  order=3},
    {id="FindSeller",icon="🔍", label="Find Seller",     order=4},
    {id="History",   icon="📜", label="Riwayat Trade",   order=5},
    {id="LiveTrade", icon="⚡", label="Live Trade",      order=6},
}

local function SetActiveTab(tabId)
    State.CurrentPanel = tabId
    for id, btn in pairs(TabButtons) do
        if id == tabId then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.Primary:Lerp(C.BG, 0.15), TextColor3 = C.White}):Play()
            btn.Font = Enum.Font.GothamBold
        else
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0,0,0,0), TextColor3 = C.TextMuted}):Play()
            btn.Font = Enum.Font.Gotham
        end
    end
    for id, panel in pairs(Panels) do
        panel.Visible = (id == tabId)
    end
end

local function MakeTab(def)
    local btn = NewInstance("TextButton", {
        Name             = "Tab_"..def.id,
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(0,0,0,0),
        BackgroundTransparency = 1,
        TextColor3       = C.TextMuted,
        Text             = def.icon.."  "..def.label,
        TextSize         = 13,
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        LayoutOrder      = def.order,
        BorderSizePixel  = 0,
    }, TabBar)
    MakeCorner(8, btn)
    MakePadding(0, 0, 12, 8, btn)

    btn.MouseEnter:Connect(function()
        if State.CurrentPanel ~= def.id then
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = C.Card}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if State.CurrentPanel ~= def.id then
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0,0,0,0), BackgroundTransparency=1}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function() SetActiveTab(def.id) end)
    TabButtons[def.id] = btn
end

for _, def in ipairs(TAB_DEFS) do MakeTab(def) end

-- ============================================================
-- FUNGSI BUAT PANEL
-- ============================================================
local function MakePanel(id)
    local panel = NewInstance("Frame", {
        Name             = "Panel_"..id,
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Visible          = false,
        ClipsDescendants = true,
    }, ContentArea)
    MakePadding(12, 12, 14, 14, panel)
    Panels[id] = panel
    return panel
end

-- ============================================================
-- ITEM CARD BUILDER (dipakai oleh beberapa panel)
-- ============================================================
local function BuildItemCard(item, parent, options)
    -- options: {showPrice, showBuy, showRemove, showSelect, onAction}
    options = options or {}
    local rarity  = GetItemRarity(item)
    local rarCol  = RarityColor(rarity)
    local name    = GetItemName(item)
    local imgId   = GetItemImage(item)
    local weight  = CalcWeight(item)
    local price   = item.listingPrice

    local card = NewInstance("Frame", {
        Size             = UDim2.new(1, 0, 0, 82),
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
    }, parent)
    MakeCorner(10, card)
    MakeStroke(1.2, rarCol:Lerp(C.Border, 0.55), card)

    -- Top stripe color rarity
    local stripe = NewInstance("Frame", {
        Size             = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = rarCol,
        BorderSizePixel  = 0,
    }, card)
    MakeCorner(10, stripe)

    -- Item image
    local imgFrame = NewInstance("Frame", {
        Size             = UDim2.fromOffset(58, 58),
        Position         = UDim2.fromOffset(10, 12),
        BackgroundColor3 = rarCol:Lerp(C.BG, 0.72),
        BorderSizePixel  = 0,
    }, card)
    MakeCorner(10, imgFrame)

    local img = NewInstance("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = imgId,
        ScaleType = Enum.ScaleType.Fit,
    }, imgFrame)

    -- Info area
    local infoX = 78
    local infoW = options.showPrice and -200 or -90

    local lblName = MakeLabel(name, 14, C.Text, {
        Size = UDim2.new(1, infoW, 0, 18),
        Position = UDim2.fromOffset(infoX, 12),
        Font = Enum.Font.GothamBold,
    }, card)

    -- Rarity badge
    local rarBadge = NewInstance("TextLabel", {
        Text             = rarity,
        TextSize         = 11,
        TextColor3       = rarCol,
        BackgroundColor3 = rarCol:Lerp(C.BG, 0.82),
        Font             = Enum.Font.GothamBold,
        Size             = UDim2.fromOffset(72, 18),
        Position         = UDim2.fromOffset(infoX, 32),
        BorderSizePixel  = 0,
    }, card)
    MakeCorner(6, rarBadge)
    MakePadding(0, 0, 6, 6, rarBadge)

    -- Stats row
    local statsY = 54
    MakeLabel("⚖ "..weight, 11, C.TextMuted, {
        Size     = UDim2.fromOffset(90, 16),
        Position = UDim2.fromOffset(infoX, statsY),
    }, card)

    local sellerText = ""
    if item.listingOwner then
        sellerText = "@"..(item.listingOwner.Name or "???")
    elseif item.seller then
        sellerText = "@"..(item.seller or "???")
    end

    MakeLabel(sellerText, 11, C.TextDim, {
        Size     = UDim2.fromOffset(120, 16),
        Position = UDim2.fromOffset(infoX + 96, statsY),
    }, card)

    -- Mutations
    if item.data and item.data.Mutations then
        local mutX = infoX
        for mutName, _ in pairs(item.data.Mutations) do
            local mb = NewInstance("TextLabel", {
                Text             = mutName,
                TextSize         = 10,
                TextColor3       = C.Gold,
                BackgroundColor3 = C.Gold:Lerp(C.BG, 0.82),
                Font             = Enum.Font.GothamBold,
                Size             = UDim2.fromOffset(60, 16),
                Position         = UDim2.fromOffset(mutX, statsY - 18),
                BorderSizePixel  = 0,
            }, card)
            MakeCorner(5, mb)
            mutX = mutX + 64
        end
    end

    -- Price
    if options.showPrice and price then
        local priceFrame = NewInstance("Frame", {
            Size             = UDim2.fromOffset(90, 44),
            Position         = UDim2.new(1, -175, 0.5, -22),
            BackgroundColor3 = C.Panel,
            BorderSizePixel  = 0,
        }, card)
        MakeCorner(8, priceFrame)
        MakeLabel("Harga", 10, C.TextMuted, {
            Size = UDim2.new(1,0,0,14),
            Position = UDim2.fromOffset(0,5),
            TextXAlignment = Enum.TextXAlignment.Center,
        }, priceFrame)
        MakeLabel(Fmt(price), 18, C.Primary, {
            Size = UDim2.new(1,0,0,22),
            Position = UDim2.fromOffset(0,20),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.GothamBold,
        }, priceFrame)
    end

    -- Action button
    if options.showBuy and options.onAction then
        local btnBuy = MakeButton("Beli", C.Primary, C.White, {
            Size = UDim2.fromOffset(68, 34),
            Position = UDim2.new(1, -80, 0.5, -17),
            TextSize = 13,
        }, card)
        btnBuy.MouseButton1Click:Connect(function() options.onAction(item) end)
    end

    if options.showRemove and options.onAction then
        local btnRem = MakeButton("Hapus", C.Danger, C.White, {
            Size = UDim2.fromOffset(68, 34),
            Position = UDim2.new(1, -80, 0.5, -17),
            TextSize = 12,
        }, card)
        btnRem.MouseButton1Click:Connect(function() options.onAction(item) end)
    end

    if options.showSelect and options.onAction then
        local btnSel = MakeButton("Pilih", C.Accent, C.White, {
            Size = UDim2.fromOffset(68, 34),
            Position = UDim2.new(1, -80, 0.5, -17),
            TextSize = 12,
        }, card)
        btnSel.MouseButton1Click:Connect(function() options.onAction(item) end)
    end

    if options.showAdd and options.onAction then
        local btnAdd = MakeButton("+ Trade", C.Accent, C.White, {
            Size = UDim2.fromOffset(76, 34),
            Position = UDim2.new(1, -88, 0.5, -17),
            TextSize = 11,
        }, card)
        btnAdd.MouseButton1Click:Connect(function() options.onAction(item) end)
    end

    return card
end

-- Bersihkan children ScrollingFrame (kecuali UIListLayout dll)
local function ClearScrollFrame(sf)
    for _, child in sf:GetChildren() do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

-- ============================================================
-- PANEL 1: BOOTH LISTING (Daftar Dagangan Semua Player)
-- ============================================================
local PanelListing = MakePanel("Listing")

-- Top bar
local ListingTopBar = NewInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, PanelListing)

local SearchListingBox = MakeTextBox("🔍  Cari nama pet...", ListingTopBar)
SearchListingBox.Size = UDim2.new(1, -310, 1, -8)
SearchListingBox.Position = UDim2.fromOffset(0, 4)

-- Sort dropdown label
local SortListingLabel = MakeLabel("Sort: "..State.BoothSortType, 12, C.TextMuted, {
    Size = UDim2.fromOffset(100, 36),
    Position = UDim2.new(1, -300, 0, 4),
    TextXAlignment = Enum.TextXAlignment.Center,
}, ListingTopBar)

local BtnSortListing = MakeButton("↕ Sort", C.Card, C.Text, {
    Size = UDim2.fromOffset(100, 36),
    Position = UDim2.new(1, -300, 0, 4),
    TextSize = 13,
}, ListingTopBar)

local BtnRefreshListing = MakeButton("🔄 Refresh", C.Card, C.Text, {
    Size = UDim2.fromOffset(100, 36),
    Position = UDim2.new(1, -192, 0, 4),
    TextSize = 13,
}, ListingTopBar)

local BtnBoothInput = MakeTextBox("Booth UUID...", ListingTopBar)
BtnBoothInput.Size = UDim2.fromOffset(120, 36)
BtnBoothInput.Position = UDim2.new(1, -88, 0, 4)
BtnBoothInput.PlaceholderText = "Nama Booth..."

-- Sort cycle
local SORT_CYCLE = {"Rarity", "Name", "Price"}
BtnSortListing.MouseButton1Click:Connect(function()
    local idx = table.find(SORT_CYCLE, State.BoothSortType) or 1
    if idx >= #SORT_CYCLE then
        idx = 1
        State.BoothSortAsc = not State.BoothSortAsc
    else
        idx = idx + 1
    end
    State.BoothSortType = SORT_CYCLE[idx]
    BtnSortListing.Text = "↕ "..State.BoothSortType..(State.BoothSortAsc and " ↑" or " ↓")
    RefreshListingPanel()
end)

-- Count label
local ListingCountLabel = MakeLabel("0 listing ditemukan", 12, C.TextMuted, {
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.fromOffset(0, 48),
}, PanelListing)

-- Scroll
local ListingScroll = MakeScrollingFrame({
    Size     = UDim2.new(1, 0, 1, -70),
    Position = UDim2.fromOffset(0, 68),
}, PanelListing)
local ListingLayout = NewInstance("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, ListingScroll)

-- Ambil data booth dari ReplicationReceiver
local BoothsReceiver = ReplicationReceiver.new("Booths")

function RefreshListingPanel()
    ClearScrollFrame(ListingScroll)
    local boothUUID = BtnBoothInput.Text ~= "" and BtnBoothInput.Text or State.BoothUUID
    if not boothUUID then
        NewInstance("TextLabel", {
            Text = "Masukkan nama/UUID booth di kolom kanan atas, lalu klik Refresh.",
            TextSize = 13, TextColor3 = C.TextMuted,
            BackgroundTransparency = 1, Size = UDim2.new(1,0,0,40),
            Font = Enum.Font.Gotham, TextWrapped = true,
        }, ListingScroll)
        return
    end

    local data = BoothsReceiver:GetData()
    if not data or not data.Booths or not data.Booths[boothUUID] then
        NewInstance("TextLabel", {
            Text = "Booth tidak ditemukan atau belum ada listing.",
            TextSize = 13, TextColor3 = C.TextMuted,
            BackgroundTransparency = 1, Size = UDim2.new(1,0,0,40),
            Font = Enum.Font.Gotham,
        }, ListingScroll)
        return
    end

    local boothData = data.Booths[boothUUID]
    local ownerID   = boothData.Owner
    local playerData = ownerID and data.Players and data.Players[ownerID]
    if not playerData then return end

    -- Bangun item list
    local items = {}
    for uuid, listing in pairs(playerData.Listings or {}) do
        local itemData = playerData.Items and playerData.Items[listing.ItemId]
        if itemData then
            -- Filter: hanya Pet (exclude buah/tanaman)
            if listing.ItemType == "Pet" then
                local owner = TradeBoothsData.getPlayerById(ownerID)
                table.insert(items, {
                    id           = listing.ItemId,
                    type         = listing.ItemType,
                    data         = itemData,
                    listingOwner = owner,
                    listingUUID  = uuid,
                    listingPrice = listing.Price,
                })
            end
        end
    end

    -- Filter search
    local query = State.BoothQuery
    if query ~= "" then
        items = (function()
            local filtered = {}
            for _, item in ipairs(items) do
                if GetItemName(item):lower():find(query, 1, true) then
                    table.insert(filtered, item)
                end
            end
            return filtered
        end)()
    end

    -- Sort
    items = SortItems(items, State.BoothSortType, State.BoothSortAsc)
    State.BoothItems = items
    ListingCountLabel.Text = #items.." listing ditemukan"

    -- Render
    local isMyBooth = ownerID == TradeBoothsData.getPlayerId(LocalPlayer)
    for i, item in ipairs(items) do
        local card = BuildItemCard(item, ListingScroll, {
            showPrice  = true,
            showBuy    = not isMyBooth,
            showRemove = isMyBooth,
            onAction   = function(it)
                if isMyBooth then
                    OpenRemoveListingPrompt(it)
                else
                    OpenBuyItemPrompt(it)
                end
            end,
        })
        card.LayoutOrder = i
    end
end

SearchListingBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.BoothQuery = SearchListingBox.Text:lower()
    RefreshListingPanel()
end)

BtnBoothInput.FocusLost:Connect(function()
    State.BoothUUID = BtnBoothInput.Text ~= "" and BtnBoothInput.Text or nil
    RefreshListingPanel()
end)

BtnRefreshListing.MouseButton1Click:Connect(function()
    State.BoothUUID = BtnBoothInput.Text ~= "" and BtnBoothInput.Text or State.BoothUUID
    RefreshListingPanel()
end)

-- ============================================================
-- PANEL 2: BOOTH SAYA (My Booth)
-- ============================================================
local PanelMyBooth = MakePanel("MyBooth")

MakeLabel("📦 Booth Saya", 16, C.Text, {
    Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 0),
    Font = Enum.Font.GothamBold,
}, PanelMyBooth)

-- Tombol action booth
local MyBoothActions = NewInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.fromOffset(0, 30),
    BackgroundTransparency = 1,
}, PanelMyBooth)
local MyBoothLayout = NewInstance("UIListLayout", {
    Padding = UDim.new(0, 8),
    FillDirection = Enum.FillDirection.Horizontal,
}, MyBoothActions)

local BtnGoToBooth = MakeButton("🚶 Pergi ke Booth", C.Primary, C.White, {
    Size = UDim2.fromOffset(148, 36), TextSize = 12,
}, MyBoothActions)
local BtnUnclaimBooth = MakeButton("❌ Unclaim Booth", C.Danger, C.White, {
    Size = UDim2.fromOffset(140, 36), TextSize = 12,
}, MyBoothActions)
local BtnAddItem = MakeButton("+ Tambah Item", C.Accent, C.White, {
    Size = UDim2.fromOffset(130, 36), TextSize = 12,
}, MyBoothActions)

local MyBoothSearch = MakeTextBox("🔍 Cari item...", PanelMyBooth)
MyBoothSearch.Size = UDim2.new(1, 0, 0, 34)
MyBoothSearch.Position = UDim2.fromOffset(0, 76)

local MyBoothCountLabel = MakeLabel("0 item di booth", 12, C.TextMuted, {
    Size = UDim2.new(1,0,0,16), Position = UDim2.fromOffset(0, 114),
}, PanelMyBooth)

local MyBoothScroll = MakeScrollingFrame({
    Size = UDim2.new(1, 0, 1, -136),
    Position = UDim2.fromOffset(0, 134),
}, PanelMyBooth)
NewInstance("UIListLayout", {Padding = UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, MyBoothScroll)

function RefreshMyBoothPanel()
    ClearScrollFrame(MyBoothScroll)
    local myId  = TradeBoothsData.getPlayerId(LocalPlayer)
    local data  = BoothsReceiver:GetData()
    if not data then return end

    -- Temukan booth milik pemain ini
    local myBoothUUID = nil
    local myPlayerData = data.Players and data.Players[myId]
    if myPlayerData and myPlayerData.Booth then
        myBoothUUID = myPlayerData.Booth
    end
    if not myBoothUUID then
        NewInstance("TextLabel", {
            Text = "Kamu belum claim booth. Pergi ke Trade World dan claim booth terlebih dahulu.",
            TextSize = 13, TextColor3 = C.TextMuted,
            BackgroundTransparency = 1, Size = UDim2.new(1,0,0,60),
            Font = Enum.Font.Gotham, TextWrapped = true,
        }, MyBoothScroll)
        return
    end

    local items = {}
    if myPlayerData then
        local query = MyBoothSearch.Text:lower()
        for uuid, listing in pairs(myPlayerData.Listings or {}) do
            local itemData = myPlayerData.Items and myPlayerData.Items[listing.ItemId]
            if itemData then
                local item = {
                    id = listing.ItemId, type = listing.ItemType,
                    data = itemData, listingUUID = uuid,
                    listingPrice = listing.Price,
                }
                if query == "" or GetItemName(item):lower():find(query, 1, true) then
                    table.insert(items, item)
                end
            end
        end
    end

    items = SortItems(items, "Rarity", false)
    MyBoothCountLabel.Text = #items.." item di booth kamu"
    for i, item in ipairs(items) do
        local card = BuildItemCard(item, MyBoothScroll, {
            showPrice = true, showRemove = true,
            onAction = function(it) OpenRemoveListingPrompt(it) end,
        })
        card.LayoutOrder = i
    end
end

MyBoothSearch:GetPropertyChangedSignal("Text"):Connect(RefreshMyBoothPanel)

BtnGoToBooth.MouseButton1Click:Connect(function()
    local ok, err = pcall(function()
        local TradeBoothController = require(ReplicatedStorage.Modules.TradeBoothControllers.TradeBoothController)
        TradeBoothController:TeleportToBooth()
    end)
    if not ok then warn("[TradeGUI] TeleportToBooth:", err) end
end)

BtnUnclaimBooth.MouseButton1Click:Connect(function()
    pcall(function()
        TradeEvents.Booths.RemoveBooth:FireServer()
    end)
    task.wait(0.5)
    RefreshMyBoothPanel()
end)

BtnAddItem.MouseButton1Click:Connect(function()
    SetActiveTab("Inventory")
end)

-- ============================================================
-- PANEL 3: INVENTORI SAYA (pilih item untuk di-listing)
-- ============================================================
local PanelInventory = MakePanel("Inventory")

MakeLabel("🎒 Inventori Saya", 16, C.Text, {
    Size=UDim2.new(1,0,0,24), Position=UDim2.fromOffset(0,0), Font=Enum.Font.GothamBold,
}, PanelInventory)

-- Category buttons
local InvCatBar = NewInstance("Frame", {
    Size = UDim2.new(1,0,0,36), Position = UDim2.fromOffset(0,28),
    BackgroundTransparency = 1,
}, PanelInventory)
NewInstance("UIListLayout", {
    Padding=UDim.new(0,6), FillDirection=Enum.FillDirection.Horizontal,
}, InvCatBar)

local INV_CATS = {
    {id="Pets", label="🐾 Pet"},
    {id="Plants", label="🌿 Tanaman"},
    {id="Seeds", label="🌱 Benih"},
}
local InvCatBtns = {}
for _, cat in ipairs(INV_CATS) do
    local btn = MakeButton(cat.label, C.Card, C.TextMuted, {
        Size=UDim2.fromOffset(100,32), TextSize=12,
    }, InvCatBar)
    InvCatBtns[cat.id] = btn
    btn.MouseButton1Click:Connect(function()
        State.InvCategory = cat.id
        for id, b in pairs(InvCatBtns) do
            b.BackgroundColor3 = (id == cat.id) and C.Primary or C.Card
            b.TextColor3 = (id == cat.id) and C.White or C.TextMuted
        end
        RefreshInventoryPanel()
    end)
end
InvCatBtns["Pets"].BackgroundColor3 = C.Primary
InvCatBtns["Pets"].TextColor3 = C.White

local InvSearch = MakeTextBox("🔍 Cari item...", PanelInventory)
InvSearch.Size = UDim2.new(1,0,0,34)
InvSearch.Position = UDim2.fromOffset(0, 70)

-- Price input untuk listing
local InvPriceFrame = NewInstance("Frame", {
    Size = UDim2.new(1,0,0,40), Position = UDim2.fromOffset(0, 110),
    BackgroundColor3 = C.Card, BorderSizePixel=0,
}, PanelInventory)
MakeCorner(8, InvPriceFrame)
MakePadding(4,4,10,10, InvPriceFrame)
MakeLabel("Harga Listing: ", 12, C.TextMuted, {
    Size=UDim2.fromOffset(100,32), Position=UDim2.fromOffset(0,0),
}, InvPriceFrame)
local InvPriceBox = MakeTextBox("contoh: 10000", InvPriceFrame)
InvPriceBox.Size = UDim2.new(1,-200,1,0)
InvPriceBox.Position = UDim2.fromOffset(100,0)
InvPriceBox.Text = ""
local BtnListItem = MakeButton("📋 Listing Item", C.Primary, C.White, {
    Size=UDim2.fromOffset(110,32), Position=UDim2.new(1,-110,0,0), TextSize=12,
}, InvPriceFrame)

local InvCountLabel = MakeLabel("0 item", 12, C.TextMuted, {
    Size=UDim2.new(1,0,0,16), Position=UDim2.fromOffset(0, 156),
}, PanelInventory)

local InvScroll = MakeScrollingFrame({
    Size=UDim2.new(1,0,1,-178), Position=UDim2.fromOffset(0,175),
}, PanelInventory)
NewInstance("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, InvScroll)

local INV_TYPE_MAP = {
    Pets   = {"Pet"},
    Plants = {"Holdable"},
    Seeds  = {"Seed", "SeedPack"},
}

function RefreshInventoryPanel()
    ClearScrollFrame(InvScroll)
    local data = DataService:GetData()
    if not data then
        InvCountLabel.Text = "Data tidak tersedia"
        return
    end

    local allowedTypes = INV_TYPE_MAP[State.InvCategory] or {}
    local items = {}
    local query = InvSearch.Text:lower()

    -- Pet inventory
    if data.PetsData and data.PetsData.PetInventory then
        for id, petData in pairs(data.PetsData.PetInventory.Data or {}) do
            if table.find(allowedTypes, "Pet") then
                local item = {id=id, type="Pet", data=petData}
                if query == "" or GetItemName(item):lower():find(query,1,true) then
                    -- cek trade lock
                    local tl = data.TradeData and data.TradeData.TradeLocks
                    if tl and tl.Pet then item.tradeLock = tl.Pet[id] end
                    table.insert(items, item)
                end
            end
        end
    end

    -- Inventory items (tanaman, benih)
    if data.InventoryData then
        for id, inv in pairs(data.InventoryData) do
            if table.find(allowedTypes, inv.ItemType) then
                local item = {id=id, type=inv.ItemType, data=inv.ItemData or {}}
                if query == "" or GetItemName(item):lower():find(query,1,true) then
                    local tl = data.TradeData and data.TradeData.TradeLocks
                    if tl and tl[inv.ItemType] then item.tradeLock = tl[inv.ItemType][id] end
                    table.insert(items, item)
                end
            end
        end
    end

    items = SortItems(items, State.InvSortType, State.InvSortAsc)
    InvCountLabel.Text = #items.." item di kategori ini"

    for i, item in ipairs(items) do
        local card = BuildItemCard(item, InvScroll, {
            showSelect = true,
            onAction = function(it)
                State.SelectedItem = it
                -- Highlight selected (biru)
                for _, ch in InvScroll:GetChildren() do
                    if ch:IsA("Frame") then
                        TweenService:Create(ch, TweenInfo.new(0.1), {BackgroundColor3 = C.Card}):Play()
                    end
                end
                TweenService:Create(card, TweenInfo.new(0.1), {BackgroundColor3 = C.Accent:Lerp(C.Card, 0.6)}):Play()
            end,
        })
        card.LayoutOrder = i
    end
end

InvSearch:GetPropertyChangedSignal("Text"):Connect(function()
    State.InvQuery = InvSearch.Text:lower()
    RefreshInventoryPanel()
end)

BtnListItem.MouseButton1Click:Connect(function()
    if not State.SelectedItem then
        warn("[TradeGUI] Pilih item terlebih dahulu!")
        return
    end
    local price = tonumber(InvPriceBox.Text)
    if not price or price <= 0 then
        warn("[TradeGUI] Masukkan harga yang valid!")
        return
    end
    State.ListingPrice = price
    local ok, result = pcall(function()
        return TradeEvents.Booths.CreateListing:InvokeServer(
            State.SelectedItem.type,
            State.SelectedItem.id,
            price
        )
    end)
    if ok and result then
        State.SelectedItem = nil
        InvPriceBox.Text = ""
        RefreshInventoryPanel()
        RefreshMyBoothPanel()
    end
end)

-- ============================================================
-- PANEL 4: FIND SELLER
-- ============================================================
local PanelFindSeller = MakePanel("FindSeller")

MakeLabel("🔍 Find Seller", 16, C.Text, {
    Size=UDim2.new(1,0,0,24), Position=UDim2.fromOffset(0,0), Font=Enum.Font.GothamBold,
}, PanelFindSeller)

MakeLabel("Cari seller online berdasarkan tipe item. Gunakan tipe item persis dari game (contoh: Pet, Seed).", 12, C.TextMuted, {
    Size=UDim2.new(1,0,0,32), Position=UDim2.fromOffset(0,28), TextWrapped=true,
}, PanelFindSeller)

local FSTypeBox = MakeTextBox("Tipe item (misal: Pet)", PanelFindSeller)
FSTypeBox.Size = UDim2.new(0.45, 0, 0, 36)
FSTypeBox.Position = UDim2.fromOffset(0, 66)

local FSNameBox = MakeTextBox("Nama item / PetType (misal: Capybara)", PanelFindSeller)
FSNameBox.Size = UDim2.new(0.52, 0, 0, 36)
FSNameBox.Position = UDim2.new(0.47, 0, 0, 66)

local BtnFindSeller = MakeButton("🔍 Cari Seller", C.Primary, C.White, {
    Size=UDim2.new(1,0,0,38), Position=UDim2.fromOffset(0,108), TextSize=14,
}, PanelFindSeller)

local FSStatusLabel = MakeLabel("Masukkan tipe dan nama item, lalu klik Cari Seller.", 13, C.TextMuted, {
    Size=UDim2.new(1,0,0,20), Position=UDim2.fromOffset(0,152),
    TextXAlignment=Enum.TextXAlignment.Center,
}, PanelFindSeller)

local FSResultFrame = NewInstance("Frame", {
    Size=UDim2.new(1,0,0,90), Position=UDim2.fromOffset(0,178),
    BackgroundColor3=C.Card, BorderSizePixel=0,
    Visible=false,
}, PanelFindSeller)
MakeCorner(10, FSResultFrame)
MakeStroke(1, C.Primary:Lerp(C.Border,0.5), FSResultFrame)
MakePadding(10,10,14,14, FSResultFrame)

local FSResultName  = MakeLabel("", 14, C.Text, {Size=UDim2.new(1,0,0,20), Font=Enum.Font.GothamBold}, FSResultFrame)
local FSResultServer= MakeLabel("", 12, C.TextMuted, {Size=UDim2.new(1,0,0,18), Position=UDim2.fromOffset(0,22)}, FSResultFrame)
local FSResultPrice = MakeLabel("", 14, C.Primary, {Size=UDim2.new(1,-120,0,20), Position=UDim2.fromOffset(0,44), Font=Enum.Font.GothamBold}, FSResultFrame)

local BtnHopServer = MakeButton("⚡ Hop Server", C.Primary, C.White, {
    Size=UDim2.fromOffset(110,34), Position=UDim2.new(1,-110,1,-44), TextSize=12,
}, FSResultFrame)

local FSCurrentListing = nil

BtnFindSeller.MouseButton1Click:Connect(function()
    if State.FindSellerSearching then return end
    local itemType = FSTypeBox.Text
    local itemName = FSNameBox.Text
    if itemType == "" or itemName == "" then
        FSStatusLabel.Text = "⚠ Isi tipe dan nama item terlebih dahulu!"
        FSStatusLabel.TextColor3 = C.Danger
        return
    end
    State.FindSellerSearching = true
    FSStatusLabel.TextColor3 = C.TextMuted
    FSStatusLabel.Text = "⏳ Mencari seller online..."
    FSResultFrame.Visible = false
    BtnFindSeller.Text = "⏳ Mencari..."

    task.spawn(function()
        local ok, found, listing = pcall(function()
            local TokenRAPUtil = require(ReplicatedStorage.Modules.TradeTokens.TokenRAPUtil)
            local itemData = TokenRAPUtil.GetDefaultItemData(itemType, itemName)
            assert(itemData, "Item data tidak ditemukan")
            return TradeEvents.TokenRAPs.FindSellers:InvokeServer(itemType, itemData)
        end)

        State.FindSellerSearching = false
        BtnFindSeller.Text = "🔍 Cari Seller"

        if ok and found and listing then
            FSCurrentListing = listing
            FSResultFrame.Visible = true
            FSResultName.Text  = "✅ Seller ditemukan: "..itemName
            FSResultServer.Text = "Server: "..(listing.server or "Server Online")
            FSResultPrice.Text = "Harga: "..Fmt(listing.price or 0).." token"
            FSStatusLabel.Text = "Seller ditemukan! Klik Hop Server untuk pindah."
            FSStatusLabel.TextColor3 = C.Primary
        elseif ok then
            FSResultFrame.Visible = false
            FSStatusLabel.Text = "❌ Tidak ada seller online untuk item ini saat ini."
            FSStatusLabel.TextColor3 = C.Danger
        else
            FSResultFrame.Visible = false
            FSStatusLabel.Text = "❌ Error: Pastikan tipe dan nama item sudah benar."
            FSStatusLabel.TextColor3 = C.Danger
        end
    end)
end)

BtnHopServer.MouseButton1Click:Connect(function()
    if not FSCurrentListing then return end
    BtnHopServer.Text = "⏳ Hopping..."
    pcall(function()
        TradeEvents.TokenRAPs.TeleportToListing:InvokeServer(FSCurrentListing)
    end)
    task.delay(2, function()
        BtnHopServer.Text = "⚡ Hop Server"
        FSCurrentListing = nil
        FSResultFrame.Visible = false
        FSStatusLabel.Text = "Teleport dikirim! Tunggu loading server."
        FSStatusLabel.TextColor3 = C.Primary
    end)
end)

-- ============================================================
-- PANEL 5: RIWAYAT TRADE (Booth History)
-- ============================================================
local PanelHistory = MakePanel("History")

MakeLabel("📜 Riwayat Trade Booth", 16, C.Text, {
    Size=UDim2.new(1,0,0,24), Position=UDim2.fromOffset(0,0), Font=Enum.Font.GothamBold,
}, PanelHistory)

local HistTopBar = NewInstance("Frame", {
    Size=UDim2.new(1,0,0,38), Position=UDim2.fromOffset(0,28),
    BackgroundTransparency=1,
}, PanelHistory)
NewInstance("UIListLayout", {
    Padding=UDim.new(0,8), FillDirection=Enum.FillDirection.Horizontal,
}, HistTopBar)

local HIST_FILTERS = {"All","Purchases","Sales"}
local HistFilterBtns = {}
for _, f in ipairs(HIST_FILTERS) do
    local btn = MakeButton(f, C.Card, C.TextMuted, {Size=UDim2.fromOffset(80,34), TextSize=12}, HistTopBar)
    HistFilterBtns[f] = btn
    btn.MouseButton1Click:Connect(function()
        State.HistoryFilter = f
        for fk, b in pairs(HistFilterBtns) do
            b.BackgroundColor3 = (fk==f) and C.Primary or C.Card
            b.TextColor3 = (fk==f) and C.White or C.TextMuted
        end
        RefreshHistoryPanel()
    end)
end
HistFilterBtns["All"].BackgroundColor3 = C.Primary
HistFilterBtns["All"].TextColor3 = C.White

local BtnSortHist = MakeButton("↕ Terbaru", C.Card, C.Text, {Size=UDim2.fromOffset(96,34), TextSize=12}, HistTopBar)
BtnSortHist.MouseButton1Click:Connect(function()
    State.HistoryAsc = not State.HistoryAsc
    BtnSortHist.Text = State.HistoryAsc and "↑ Terlama" or "↓ Terbaru"
    RefreshHistoryPanel()
end)

local HistSearch = MakeTextBox("🔍 Cari player/item...", PanelHistory)
HistSearch.Size = UDim2.new(1,0,0,34)
HistSearch.Position = UDim2.fromOffset(0, 72)

local HistCountLabel = MakeLabel("0 entri", 12, C.TextMuted, {
    Size=UDim2.new(1,0,0,16), Position=UDim2.fromOffset(0,110),
}, PanelHistory)

local HistScroll = MakeScrollingFrame({
    Size=UDim2.new(1,0,1,-132), Position=UDim2.fromOffset(0,128),
}, PanelHistory)
NewInstance("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, HistScroll)

local function BuildHistoryCard(log)
    local myId = LocalPlayer.UserId
    local isSale   = log.seller and log.seller.userId == myId
    local isFailed = log.status and log.status.result == "Failed"
    local statusTxt = isFailed and "GAGAL" or (isSale and "Dijual" or "Dibeli")
    local statusCol = isFailed and C.Danger or (isSale and Color3.fromRGB(255,100,100) or C.Primary)

    local card = NewInstance("Frame", {
        Size=UDim2.new(1,0,0,68), BackgroundColor3=C.Card, BorderSizePixel=0,
    }, HistScroll)
    MakeCorner(10, card)
    MakeStroke(1, statusCol:Lerp(C.Border, 0.6), card)
    MakePadding(8,8,12,12, card)

    -- Status badge
    local sb = NewInstance("TextLabel", {
        Text=statusTxt, TextSize=11, TextColor3=statusCol,
        BackgroundColor3=statusCol:Lerp(C.BG,0.82),
        Font=Enum.Font.GothamBold, Size=UDim2.fromOffset(56,18),
        BorderSizePixel=0,
    }, card)
    MakeCorner(6, sb)

    -- Partner name
    local partner = isSale and log.buyer or log.seller
    local partnerName = partner and ("@"..partner.username) or "???"
    MakeLabel(partnerName, 14, C.Text, {
        Size=UDim2.new(1,-140,0,18), Position=UDim2.fromOffset(64,0),
        Font=Enum.Font.GothamBold,
    }, card)

    -- Item name
    local itemKey = ""
    if log.item and log.item.data then
        if log.item.data.PetType then itemKey = log.item.data.PetType
        elseif log.item.data.ItemName then itemKey = log.item.data.ItemName
        end
    end
    MakeLabel("Item: "..itemKey, 12, C.TextMuted, {
        Size=UDim2.new(1,-140,0,16), Position=UDim2.fromOffset(64,20),
    }, card)

    -- Time
    local timeStr = log.finishTime and os.date("%d/%m %H:%M", log.finishTime) or "???"
    MakeLabel(timeStr, 11, C.TextDim, {
        Size=UDim2.new(1,-140,0,14), Position=UDim2.fromOffset(64,38),
    }, card)

    -- Price
    MakeLabel(Fmt(log.price or 0), 18, statusCol, {
        Size=UDim2.fromOffset(100,40), Position=UDim2.new(1,-112,0,0),
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Right,
    }, card)

    return card
end

function RefreshHistoryPanel()
    ClearScrollFrame(HistScroll)
    local myId  = LocalPlayer.UserId
    local query = HistSearch.Text:lower()
    local filter = State.HistoryFilter

    local filtered = {}
    for _, log in ipairs(State.HistoryLogs) do
        local isSale = log.seller and log.seller.userId == myId
        if filter == "Sales" and not isSale then goto continue end
        if filter == "Purchases" and isSale then goto continue end
        if log.status and log.status.result == "Failed" then goto continue end

        if query ~= "" then
            local sellerName = log.seller and log.seller.username or ""
            local buyerName  = log.buyer and log.buyer.username or ""
            local itemKey    = ""
            if log.item and log.item.data then
                itemKey = log.item.data.PetType or log.item.data.ItemName or ""
            end
            if not (sellerName:lower():find(query,1,true)
                or buyerName:lower():find(query,1,true)
                or itemKey:lower():find(query,1,true)) then
                goto continue
            end
        end

        table.insert(filtered, log)
        ::continue::
    end

    table.sort(filtered, function(a, b)
        if State.HistoryAsc then return a.finishTime < b.finishTime
        else return a.finishTime > b.finishTime end
    end)

    HistCountLabel.Text = #filtered.." entri"
    for i, log in ipairs(filtered) do
        local card = BuildHistoryCard(log)
        card.LayoutOrder = i
    end
end

HistSearch:GetPropertyChangedSignal("Text"):Connect(RefreshHistoryPanel)

-- Load history saat panel aktif
local HistLoaded = false
local function LoadHistory()
    if HistLoaded then return end
    HistLoaded = true
    task.spawn(function()
        local ok, logs = pcall(function()
            return TradeEvents.Booths.FetchHistory:InvokeServer()
        end)
        if ok and logs then
            State.HistoryLogs = logs
            RefreshHistoryPanel()
        end
    end)
end

-- Realtime history update
TradeEvents.Booths.AddToHistory.OnClientEvent:Connect(function(log)
    table.insert(State.HistoryLogs, 1, log)
    if State.CurrentPanel == "History" then
        RefreshHistoryPanel()
    end
end)

-- ============================================================
-- PANEL 6: LIVE TRADE (Trade aktif dengan player lain)
-- ============================================================
local PanelLiveTrade = MakePanel("LiveTrade")

MakeLabel("⚡ Live Trade", 16, C.Text, {
    Size=UDim2.new(1,0,0,24), Position=UDim2.fromOffset(0,0), Font=Enum.Font.GothamBold,
}, PanelLiveTrade)

local LiveTradeStatus = MakeLabel("Tidak ada trade aktif.", 13, C.TextMuted, {
    Size=UDim2.new(1,0,0,20), Position=UDim2.fromOffset(0,30),
}, PanelLiveTrade)

-- Dua sisi: My Offer & Their Offer
local LiveSides = NewInstance("Frame", {
    Size=UDim2.new(1,0,1,-120), Position=UDim2.fromOffset(0,56),
    BackgroundTransparency=1,
}, PanelLiveTrade)

local function MakeTradeSide(label, posX)
    local side = NewInstance("Frame", {
        Size=UDim2.new(0.48,0,1,0),
        Position=UDim2.fromScale(posX,0),
        BackgroundColor3=C.Panel, BorderSizePixel=0,
    }, LiveSides)
    MakeCorner(10, side)
    MakePadding(8,8,10,10, side)
    MakeLabel(label, 13, C.TextMuted, {
        Size=UDim2.new(1,0,0,20), Font=Enum.Font.GothamBold,
    }, side)
    local sf = MakeScrollingFrame({
        Size=UDim2.new(1,0,1,-28), Position=UDim2.fromOffset(0,26),
    }, side)
    NewInstance("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, sf)
    return side, sf
end

local MySide, MyItemsSF   = MakeTradeSide("🙂 Offer Saya", 0)
local TheirSide, TheirSF  = MakeTradeSide("👤 Offer Mereka", 0.52)

-- Bottom: sheckles, tokens, accept/decline
local LiveTradeBottom = NewInstance("Frame", {
    Size=UDim2.new(1,0,0,58), Position=UDim2.new(0,0,1,-60),
    BackgroundTransparency=1,
}, PanelLiveTrade)
NewInstance("UIListLayout", {
    Padding=UDim.new(0,10), FillDirection=Enum.FillDirection.Horizontal,
    VerticalAlignment=Enum.VerticalAlignment.Center,
}, LiveTradeBottom)

local ShecklesBox = MakeTextBox("Jumlah Sheckles...", LiveTradeBottom)
ShecklesBox.Size = UDim2.fromOffset(150, 42)
local TokensBox   = MakeTextBox("Jumlah Token...", LiveTradeBottom)
TokensBox.Size    = UDim2.fromOffset(140, 42)
local BtnAccept   = MakeButton("✅ Accept", C.Primary, C.White, {Size=UDim2.fromOffset(100,42), TextSize=13}, LiveTradeBottom)
local BtnDecline  = MakeButton("❌ Decline", C.Danger, C.White, {Size=UDim2.fromOffset(100,42), TextSize=13}, LiveTradeBottom)

-- Trade Replicator & render
local CurrentReplicator = nil
local TradeConnections  = {}

local function ClearTradeConnections()
    for _, conn in ipairs(TradeConnections) do conn:Disconnect() end
    TradeConnections = {}
end

local function RenderTradeOffers(data)
    if not data then return end
    ClearScrollFrame(MyItemsSF)
    ClearScrollFrame(TheirSF)
    local myIdx = table.find(data.players, LocalPlayer)
    if not myIdx then return end
    local theirIdx = myIdx == 1 and 2 or 1

    local function RenderOffer(offer, sf)
        for i, item in ipairs(offer.items or {}) do
            local card = BuildItemCard(item, sf, {})
            card.LayoutOrder = i
            card.Size = UDim2.new(1,0,0,60)
        end
    end

    if data.offers[myIdx] then RenderOffer(data.offers[myIdx], MyItemsSF) end
    if data.offers[theirIdx] then RenderOffer(data.offers[theirIdx], TheirSF) end

    local myState = data.states and data.states[myIdx] or "None"
    local theirState = data.states and data.states[theirIdx] or "None"
    LiveTradeStatus.Text = "State kamu: "..myState.." | Mereka: "..theirState
    LiveTradeStatus.TextColor3 = C.Text

    -- Update player names
    if data.players[theirIdx] then
        TheirSide:FindFirstChild("TextLabel").Text = "👤 "..(data.players[theirIdx].Name or "Mereka")
    end
end

local function SetupTradeReplicator(replicator)
    ClearTradeConnections()
    CurrentReplicator = replicator
    if not replicator then
        LiveTradeStatus.Text = "Tidak ada trade aktif."
        LiveTradeStatus.TextColor3 = C.TextMuted
        ClearScrollFrame(MyItemsSF)
        ClearScrollFrame(TheirSF)
        return
    end
    local data = replicator:GetDataAsync()
    RenderTradeOffers(data)
    local conn = replicator:GetPathSignal("offers/@"):Connect(function()
        RenderTradeOffers(replicator:GetData())
    end)
    table.insert(TradeConnections, conn)
    local sconn = replicator:GetPathSignal("states/@"):Connect(function()
        RenderTradeOffers(replicator:GetData())
    end)
    table.insert(TradeConnections, sconn)
end

ShecklesBox.FocusLost:Connect(function()
    local n = tonumber(ShecklesBox.Text)
    if n then pcall(function() TradeEvents.SetSheckles:FireServer(n) end) end
end)
TokensBox.FocusLost:Connect(function()
    local n = tonumber(TokensBox.Text)
    if n then pcall(function() TradeEvents.SetTokens:FireServer(n) end) end
end)
BtnAccept.MouseButton1Click:Connect(function()
    pcall(function()
        local repl = CurrentReplicator
        if not repl then return end
        local data = repl:GetData()
        local myIdx = table.find(data.players, LocalPlayer)
        local myState = data.states and data.states[myIdx]
        if myState == "None" then
            TradeEvents.Accept:FireServer()
        elseif myState == "Accepted" then
            TradeEvents.Confirm:FireServer()
        end
    end)
end)
BtnDecline.MouseButton1Click:Connect(function()
    pcall(function() TradeEvents.Decline:FireServer() end)
end)

-- Dengarkan update trade state dari server
TradeEvents.UpdateTradeState.OnClientEvent:Connect(function(tradeId)
    if tradeId == State.CurrentTradeId then return end
    State.CurrentTradeId = tradeId
    if State.CurrentTradeReplicator then
        pcall(function() State.CurrentTradeReplicator:Destroy() end)
        State.CurrentTradeReplicator = nil
    end
    if tradeId then
        local repl = ReplicationReceiver.new(tradeId)
        State.CurrentTradeReplicator = repl
        SetupTradeReplicator(repl)
        -- Auto-switch ke tab live trade
        SetActiveTab("LiveTrade")
        MainWindow.Visible = true
    else
        SetupTradeReplicator(nil)
    end
end)

-- ============================================================
-- POPUP: BUY ITEM (tanpa konfirmasi — langsung beli!)
-- ============================================================
function OpenBuyItemPrompt(item)
    -- INSTANT BUY: langsung invoke server tanpa popup
    task.spawn(function()
        local ok, result = pcall(function()
            return BoothEvents.BuyListing:InvokeServer(item.listingOwner, item.listingUUID)
        end)
        if ok and result then
            RefreshListingPanel()
            -- Notifikasi kecil
            ShowNotification("✅ Berhasil membeli "..GetItemName(item).."!", C.Primary)
        else
            ShowNotification("❌ Gagal membeli item. Coba lagi!", C.Danger)
        end
    end)
end

-- ============================================================
-- POPUP: REMOVE LISTING
-- ============================================================
local RemovePopup = NewInstance("Frame", {
    Name = "RemovePopup",
    Size = UDim2.fromOffset(340, 180),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 10,
}, ScreenGui)
MakeCorner(12, RemovePopup)
MakeStroke(1.5, C.Danger:Lerp(C.Border,0.5), RemovePopup)
MakePadding(16,16,16,16, RemovePopup)

MakeLabel("🗑 Hapus Listing", 16, C.Text, {
    Size=UDim2.new(1,0,0,24), Font=Enum.Font.GothamBold, ZIndex=11,
}, RemovePopup)
local RemoveItemName = MakeLabel("", 14, C.TextMuted, {
    Size=UDim2.new(1,0,0,20), Position=UDim2.fromOffset(0,30), ZIndex=11,
}, RemovePopup)
MakeLabel("Yakin ingin hapus listing ini dari booth kamu?", 12, C.TextMuted, {
    Size=UDim2.new(1,0,0,32), Position=UDim2.fromOffset(0,54),
    TextWrapped=true, ZIndex=11,
}, RemovePopup)

local RemoveBtnRow = NewInstance("Frame", {
    Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,1,-50),
    BackgroundTransparency=1, ZIndex=11,
}, RemovePopup)
NewInstance("UIListLayout", {
    Padding=UDim.new(0,10), FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Right,
}, RemoveBtnRow)

local BtnRemoveCancel  = MakeButton("Batal", C.Card, C.Text, {Size=UDim2.fromOffset(90,36), ZIndex=12}, RemoveBtnRow)
local BtnRemoveConfirm = MakeButton("Hapus", C.Danger, C.White, {Size=UDim2.fromOffset(90,36), ZIndex=12}, RemoveBtnRow)

function OpenRemoveListingPrompt(item)
    State.RemoveTarget = item
    RemoveItemName.Text = GetItemName(item)
    RemovePopup.Visible = true
    TweenOpen(RemovePopup)
end

BtnRemoveCancel.MouseButton1Click:Connect(function()
    TweenClose(RemovePopup)
    State.RemoveTarget = nil
end)

BtnRemoveConfirm.MouseButton1Click:Connect(function()
    if not State.RemoveTarget then return end
    local target = State.RemoveTarget
    State.RemoveTarget = nil
    TweenClose(RemovePopup)
    task.spawn(function()
        local ok, result = pcall(function()
            return BoothEvents.RemoveListing:InvokeServer(target.listingUUID)
        end)
        if ok and result then
            RefreshMyBoothPanel()
            ShowNotification("✅ Listing "..GetItemName(target).." dihapus!", C.Primary)
        else
            ShowNotification("❌ Gagal hapus listing.", C.Danger)
        end
    end)
end)

-- ============================================================
-- POPUP: TRADE REQUEST (notifikasi terima request trade)
-- ============================================================
local RequestPopup = NewInstance("Frame", {
    Name = "RequestPopup",
    Size = UDim2.fromOffset(320, 160),
    Position = UDim2.new(1, -336, 1, -176),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 20,
}, ScreenGui)
MakeCorner(12, RequestPopup)
MakeStroke(1.5, C.Accent:Lerp(C.Border,0.3), RequestPopup)
MakePadding(14,14,14,14, RequestPopup)

local ReqSenderImg = NewInstance("ImageLabel", {
    Size=UDim2.fromOffset(48,48),
    BackgroundColor3=C.Card,
    BorderSizePixel=0,
    ZIndex=21,
}, RequestPopup)
MakeCorner(24, ReqSenderImg)

local ReqSenderName = MakeLabel("", 14, C.Text, {
    Size=UDim2.new(1,-60,0,22), Position=UDim2.fromOffset(56,0),
    Font=Enum.Font.GothamBold, ZIndex=21,
}, RequestPopup)
MakeLabel("mengajakmu trade!", 12, C.TextMuted, {
    Size=UDim2.new(1,-60,0,18), Position=UDim2.fromOffset(56,22),
    ZIndex=21,
}, RequestPopup)

local ReqTimer = NewInstance("Frame", {
    Size=UDim2.new(1,0,0,4), Position=UDim2.fromOffset(0,58),
    BackgroundColor3=C.Primary, BorderSizePixel=0, ZIndex=21,
}, RequestPopup)
MakeCorner(2, ReqTimer)

local ReqBtnRow = NewInstance("Frame", {
    Size=UDim2.new(1,0,0,42), Position=UDim2.new(0,0,1,-52),
    BackgroundTransparency=1, ZIndex=21,
}, RequestPopup)
NewInstance("UIListLayout", {
    Padding=UDim.new(0,10), FillDirection=Enum.FillDirection.Horizontal,
}, ReqBtnRow)

local BtnReqDecline = MakeButton("❌ Tolak", C.Danger, C.White, {Size=UDim2.fromOffset(120,38), ZIndex=22}, ReqBtnRow)
local BtnReqAccept  = MakeButton("✅ Terima", C.Primary, C.White, {Size=UDim2.fromOffset(140,38), ZIndex=22}, ReqBtnRow)

local ReqTimeoutAnim = nil

BtnReqAccept.MouseButton1Click:Connect(function()
    if not State.PendingRequestId then return end
    pcall(function() TradeEvents.RespondRequest:FireServer(State.PendingRequestId, true) end)
    State.PendingRequestId = nil
    State.PendingRequester = nil
    TweenClose(RequestPopup)
    if ReqTimeoutAnim then ReqTimeoutAnim:Cancel() end
end)
BtnReqDecline.MouseButton1Click:Connect(function()
    if not State.PendingRequestId then return end
    pcall(function() TradeEvents.RespondRequest:FireServer(State.PendingRequestId, false) end)
    State.PendingRequestId = nil
    TweenClose(RequestPopup)
    if ReqTimeoutAnim then ReqTimeoutAnim:Cancel() end
end)

-- Dengar trade request masuk
TradeEvents.SendRequest.OnClientEvent:Connect(function(requestId, sender, expireTime)
    State.PendingRequestId = requestId
    State.PendingRequester = sender
    ReqSenderName.Text = sender.Name
    ReqSenderImg.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=180&h=180"):format(sender.UserId)
    ReqTimer.Size = UDim2.new(1,0,0,4)
    RequestPopup.Visible = true
    TweenOpen(RequestPopup)

    local duration = expireTime and (expireTime - workspace:GetServerTimeNow()) or 30
    if ReqTimeoutAnim then ReqTimeoutAnim:Cancel() end
    ReqTimeoutAnim = TweenService:Create(ReqTimer, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0,0,0,4),
        BackgroundColor3 = C.Danger,
    })
    ReqTimeoutAnim:Play()
    task.delay(duration, function()
        if State.PendingRequestId == requestId then
            State.PendingRequestId = nil
            TweenClose(RequestPopup)
        end
    end)
end)

-- ============================================================
-- NOTIFIKASI KECIL (TOAST)
-- ============================================================
local NotifFrame = NewInstance("Frame", {
    Name="NotifHolder",
    Size=UDim2.fromOffset(300, 50),
    Position=UDim2.new(0.5,-150,0,16),
    BackgroundColor3=C.Panel,
    BorderSizePixel=0,
    Visible=false,
    ZIndex=30,
}, ScreenGui)
MakeCorner(10, NotifFrame)
MakeStroke(1.5, C.Primary:Lerp(C.Border,0.3), NotifFrame)
MakePadding(0,0,14,14, NotifFrame)

local NotifText = MakeLabel("", 13, C.Text, {
    Size=UDim2.new(1,0,1,0), TextXAlignment=Enum.TextXAlignment.Center,
    TextWrapped=true, ZIndex=31,
}, NotifFrame)

local NotifTask = nil
function ShowNotification(msg, color)
    if NotifTask then task.cancel(NotifTask) end
    NotifText.Text = msg
    NotifText.TextColor3 = color or C.Text
    NotifFrame:FindFirstChildWhichIsA("UIStroke").Color = (color or C.Primary):Lerp(C.Border, 0.3)
    NotifFrame.Visible = true
    TweenOpen(NotifFrame)
    NotifTask = task.delay(3, function()
        TweenClose(NotifFrame)
    end)
end

-- ============================================================
-- OPEN/CLOSE MAIN WINDOW VIA TOMBOL HUD
-- ============================================================
-- Buat tombol pembuka di sudut layar
local OpenBtn = NewInstance("TextButton", {
    Text = "🏪 Trade",
    TextSize = 14,
    TextColor3 = C.White,
    BackgroundColor3 = C.Primary,
    Font = Enum.Font.GothamBold,
    Size = UDim2.fromOffset(90, 38),
    Position = UDim2.new(0, 12, 0.5, -19),
    BorderSizePixel = 0,
    ZIndex = 5,
}, ScreenGui)
MakeCorner(10, OpenBtn)
MakeStroke(1, C.PrimaryDark, OpenBtn)

OpenBtn.MouseButton1Click:Connect(function()
    if MainWindow.Visible then
        TweenClose(MainWindow)
    else
        MainWindow.Visible = true
        TweenOpen(MainWindow)
        SetActiveTab(State.CurrentPanel)
        -- Load panel saat pertama dibuka
        if State.CurrentPanel == "Listing" then RefreshListingPanel()
        elseif State.CurrentPanel == "History" then LoadHistory()
        elseif State.CurrentPanel == "Inventory" then RefreshInventoryPanel()
        elseif State.CurrentPanel == "MyBooth" then RefreshMyBoothPanel()
        end
    end
end)

-- ============================================================
-- DRAGGABLE MAIN WINDOW
-- ============================================================
do
    local dragging, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos  = MainWindow.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
-- INISIALISASI AWAL
-- ============================================================
SetActiveTab("Listing")

-- Auto-load booth data saat boothUUID berubah
BoothsReceiver:GetDataAsync()

-- Listen perubahan booth data realtime
pcall(function()
    BoothsReceiver:GetPathSignal("@"):Connect(function()
        if State.CurrentPanel == "Listing" then RefreshListingPanel()
        elseif State.CurrentPanel == "MyBooth" then RefreshMyBoothPanel()
        end
    end)
end)

-- Saat panel History aktif, auto-load
-- (dilakukan via SetActiveTab callback)
local _origSetActiveTab = SetActiveTab
SetActiveTab = function(tabId)
    _origSetActiveTab(tabId)
    if tabId == "History" then LoadHistory() end
    if tabId == "Inventory" then RefreshInventoryPanel() end
    if tabId == "MyBooth" then RefreshMyBoothPanel() end
end

print("[TradeGUI] GUI berhasil dimuat! Klik tombol 🏪 Trade untuk membuka.")
