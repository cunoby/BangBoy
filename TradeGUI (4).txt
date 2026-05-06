-- TradeGUI.lua | Grow a Garden | Listing + Buy Only | Mobile Friendly
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/cunoby/BangBoy/refs/heads/main/TradeGUI.lua"))()

local ok, err = pcall(function()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui", 10) or LP.PlayerGui
local Cam  = workspace.CurrentCamera

-- Bersihkan GUI lama
local old = PGui:FindFirstChild("GrowTradeGUI")
if old then old:Destroy() end

-- ============================================================
-- SAFE REQUIRE
-- ============================================================
local function safeReq(inst)
    if not inst then return nil end
    local ok2, r = pcall(require, inst)
    return ok2 and r or nil
end

local Mods = ReplicatedStorage:FindFirstChild("Modules")
local GE   = ReplicatedStorage:FindFirstChild("GameEvents")
local TE   = GE and GE:FindFirstChild("TradeEvents")
local BE   = TE and TE:FindFirstChild("Booths")

local INF = Mods and safeReq(Mods:FindFirstChild("ItemNameFinder"))
local IIF = Mods and safeReq(Mods:FindFirstChild("ItemImageFinder"))
local IRF = Mods and safeReq(Mods:FindFirstChild("ItemRarityFinder"))
local PU  = (function()
    if not Mods then return nil end
    local ps = Mods:FindFirstChild("PetServices")
    return ps and safeReq(ps:FindFirstChild("PetUtilities")) or nil
end)()

-- ============================================================
-- ITEM HELPERS
-- ============================================================
local function ItemName(item)
    if not (item and item.data) then return "Unknown" end
    local k = item.data.PetType or item.data.ItemName or item.data.Name or "Unknown"
    if INF then
        local ok2, v = pcall(INF, k, item.type or "")
        if ok2 and v then return tostring(v) end
    end
    return tostring(k)
end

local function ItemImg(item)
    if not (item and item.data) then return "" end
    local k = item.data.PetType or item.data.ItemName or item.data.Name or ""
    if IIF then
        local ok2, v = pcall(IIF, k, item.type or "")
        if ok2 and v then return tostring(v) end
    end
    return ""
end

local RORD = {Common=1, Uncommon=2, Rare=3, Legendary=4, Mythic=5, Divine=6}
local function ItemRar(item)
    if not (item and item.data) then return "Common" end
    local k = item.data.PetType or item.data.ItemName or item.data.Name or ""
    if IRF then
        local ok2, v = pcall(IRF, k, item.type or "")
        if ok2 and v then return tostring(v) end
    end
    return "Common"
end

local function ItemWt(item)
    if item and item.data and item.data.PetData then
        local bd = item.data.PetData.BaseWeight
        local lv = item.data.PetData.Level
        if PU and bd and lv then
            local ok2, w = pcall(function() return PU:CalculateWeight(bd, lv) end)
            if ok2 and w then return string.format("%.1f kg", w) end
        end
        if bd then return string.format("%.1f kg", bd) end
    end
    return ""
end

local RCOL = {
    Common    = Color3.fromRGB(160,160,160),
    Uncommon  = Color3.fromRGB(60,190,80),
    Rare      = Color3.fromRGB(60,120,245),
    Legendary = Color3.fromRGB(170,60,245),
    Mythic    = Color3.fromRGB(245,120,20),
    Divine    = Color3.fromRGB(245,205,20),
}
local function RC(r) return RCOL[r] or Color3.fromRGB(100,110,140) end

local function Fmt(n)
    n = tonumber(n) or 0
    if n >= 1000000000 then return string.format("%.1fB", n/1000000000)
    elseif n >= 1000000 then return string.format("%.1fM", n/1000000)
    elseif n >= 1000 then return string.format("%.1fK", n/1000)
    end
    return tostring(math.floor(n))
end

-- ============================================================
-- WARNA
-- ============================================================
local BG     = Color3.fromRGB(13,15,22)
local PANEL  = Color3.fromRGB(21,25,36)
local CARD   = Color3.fromRGB(29,33,48)
local BORDER = Color3.fromRGB(48,54,78)
local GREEN  = Color3.fromRGB(55,185,125)
local RED    = Color3.fromRGB(210,50,50)
local TEXT   = Color3.fromRGB(228,233,255)
local MUTED  = Color3.fromRGB(105,115,148)
local WHITE  = Color3.new(1,1,1)
local BLACK  = Color3.new(0,0,0)

-- ============================================================
-- UI HELPERS (sederhana, tanpa Enum.AutomaticCanvasSize)
-- ============================================================
local function New(cls, props, par)
    local i = Instance.new(cls)
    if props then
        for k, v in pairs(props) do
            i[k] = v
        end
    end
    if par then i.Parent = par end
    return i
end

local function Corner(r, p)
    New("UICorner", {CornerRadius = UDim.new(0, r)}, p)
end

local function Stroke(th, col, p)
    New("UIStroke", {Thickness=th, Color=col, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, p)
end

-- Buat tombol dengan hover effect
local function Btn(txt, bg, sz, par)
    bg = bg or GREEN
    local b = New("TextButton", {
        Text=txt, TextSize=sz or 14, TextColor3=WHITE,
        BackgroundColor3=bg, Font=Enum.Font.GothamBold,
        AutoButtonColor=false, BorderSizePixel=0,
        Size=UDim2.fromOffset(80, 38),
    }, nil)
    Corner(10, b)
    local orig = bg
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=orig:Lerp(WHITE,0.15)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=orig}):Play()
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.07), {BackgroundColor3=orig:Lerp(BLACK,0.2)}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.09), {BackgroundColor3=orig}):Play()
    end)
    if par then b.Parent = par end
    return b
end

-- Buat ScrollingFrame TANPA AutomaticCanvasSize (kompatibel semua executor)
local function MakeSF(size, pos, par)
    local sf = New("ScrollingFrame", {
        Size=size,
        Position=pos or UDim2.new(0,0,0,0),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ScrollBarThickness=4,
        ScrollBarImageColor3=BORDER,
        CanvasSize=UDim2.new(0,0,0,0),
        ScrollingDirection=Enum.ScrollingDirection.Y,
    }, par)
    return sf
end

-- Update canvas size berdasarkan konten UIListLayout
local function UpdateCanvas(sf, layout)
    sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
end

-- ============================================================
-- DETEKSI LAYAR
-- ============================================================
local VP   = Cam.ViewportSize
local IS_M = UserInputService.TouchEnabled
local WW   = IS_M and (VP.X - 12) or math.min(VP.X - 20, 460)
local WH   = IS_M and (VP.Y - 12) or math.min(VP.Y - 20, 640)

-- ============================================================
-- SCREENGUI
-- ============================================================
local SG = New("ScreenGui", {
    Name="GrowTradeGUI",
    ResetOnSpawn=false,
    IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
}, PGui)

-- ============================================================
-- TOAST
-- ============================================================
local ToastF = New("Frame", {
    Size=UDim2.fromOffset(320,52),
    Position=UDim2.new(0.5,-160,0,10),
    BackgroundColor3=PANEL,
    BorderSizePixel=0,
    Visible=false,
    ZIndex=200,
}, SG)
Corner(10, ToastF)
Stroke(1.5, GREEN, ToastF)
local ToastL = New("TextLabel", {
    Text="", TextSize=13, TextColor3=TEXT,
    BackgroundTransparency=1,
    Font=Enum.Font.GothamBold,
    Size=UDim2.fromScale(1,1),
    TextWrapped=true,
    TextXAlignment=Enum.TextXAlignment.Center,
    TextYAlignment=Enum.TextYAlignment.Center,
    ZIndex=201,
}, ToastF)

local _toastTask = nil
local function Toast(msg, col, dur)
    if _toastTask then task.cancel(_toastTask) end
    col = col or GREEN
    ToastL.Text = msg
    ToastL.TextColor3 = col
    local st = ToastF:FindFirstChildWhichIsA("UIStroke")
    if st then st.Color = col:Lerp(BORDER, 0.4) end
    ToastF.Visible = true
    ToastF.BackgroundTransparency = 0
    _toastTask = task.delay(dur or 3, function()
        TweenService:Create(ToastF, TweenInfo.new(0.2), {BackgroundTransparency=1}):Play()
        task.wait(0.22)
        ToastF.Visible = false
    end)
end

-- ============================================================
-- TOMBOL BUKA
-- ============================================================
local OpenBtn = Btn("Trade Market", GREEN, 14, SG)
OpenBtn.Size = UDim2.fromOffset(140, 48)
OpenBtn.Position = UDim2.new(0, 8, 0.5, -24)
OpenBtn.ZIndex = 50
Stroke(1, GREEN:Lerp(BLACK,0.3), OpenBtn)

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local MW = New("Frame", {
    Name="MainWin",
    Size=UDim2.fromOffset(WW, WH),
    Position=UDim2.new(0.5,0,0.5,0),
    AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=BG,
    BorderSizePixel=0,
    Visible=false,
    ZIndex=10,
}, SG)
Corner(14, MW)
Stroke(1.5, BORDER, MW)

-- ============================================================
-- HEADER
-- ============================================================
local HDR = New("Frame", {
    Size=UDim2.new(1,0,0,50),
    BackgroundColor3=PANEL,
    BorderSizePixel=0,
    ZIndex=11,
}, MW)
Corner(14, HDR)
-- patch sudut bawah header
New("Frame", {
    Size=UDim2.new(1,0,0,14),
    Position=UDim2.new(0,0,1,-14),
    BackgroundColor3=PANEL,
    BorderSizePixel=0,
    ZIndex=10,
}, HDR)

New("TextLabel", {
    Text="Trade Market — Grow a Garden",
    TextSize=15, TextColor3=GREEN,
    BackgroundTransparency=1,
    Font=Enum.Font.GothamBold,
    Size=UDim2.new(1,-56,1,0),
    Position=UDim2.fromOffset(14,0),
    TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Center,
    ZIndex=12,
}, HDR)

local CloseBtn = Btn("X", Color3.fromRGB(190,45,45), 17, HDR)
CloseBtn.Size = UDim2.fromOffset(36,36)
CloseBtn.Position = UDim2.new(1,-44,0.5,-18)
CloseBtn.ZIndex = 12

-- ============================================================
-- AREA KONTEN
-- ============================================================
local CA = New("Frame", {
    Size=UDim2.new(1,0,1,-50),
    Position=UDim2.fromOffset(0,50),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ClipsDescendants=true,
    ZIndex=10,
}, MW)
New("UIPadding", {
    PaddingTop=UDim.new(0,10),
    PaddingBottom=UDim.new(0,10),
    PaddingLeft=UDim.new(0,12),
    PaddingRight=UDim.new(0,12),
}, CA)

-- ============================================================
-- BARIS KONTROL (Search + Sort + Refresh)
-- ============================================================
local CTRL_H = 44
local CtrlRow = New("Frame", {
    Size=UDim2.new(1,0,0,CTRL_H),
    BackgroundTransparency=1,
}, CA)
New("UIListLayout", {
    FillDirection=Enum.FillDirection.Horizontal,
    Padding=UDim.new(0,6),
    VerticalAlignment=Enum.VerticalAlignment.Center,
    SortOrder=Enum.SortOrder.LayoutOrder,
}, CtrlRow)

local SearchBox = New("TextBox", {
    PlaceholderText="Cari nama pet...",
    PlaceholderColor3=MUTED,
    Text="", TextSize=14, TextColor3=TEXT,
    BackgroundColor3=CARD,
    Font=Enum.Font.Gotham,
    BorderSizePixel=0,
    ClearTextOnFocus=false,
    TextXAlignment=Enum.TextXAlignment.Left,
    Size=UDim2.new(1,-150,1,-6),
    LayoutOrder=1,
}, CtrlRow)
Corner(10, SearchBox)
Stroke(1, BORDER, SearchBox)
New("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)}, SearchBox)

local SortBtn = Btn("Sort", CARD:Lerp(BORDER,0.3), 12, CtrlRow)
SortBtn.Size=UDim2.fromOffset(68,38)
SortBtn.TextColor3=TEXT
SortBtn.LayoutOrder=2

local RefBtn = Btn("Refresh", CARD:Lerp(BORDER,0.3), 12, CtrlRow)
RefBtn.Size=UDim2.fromOffset(70,38)
RefBtn.TextColor3=TEXT
RefBtn.LayoutOrder=3

-- ============================================================
-- BARIS UUID BOOTH
-- ============================================================
local BOOTH_H = 40
local BoothRow = New("Frame", {
    Size=UDim2.new(1,0,0,BOOTH_H),
    Position=UDim2.fromOffset(0, CTRL_H+6),
    BackgroundTransparency=1,
}, CA)
New("UIListLayout", {
    FillDirection=Enum.FillDirection.Horizontal,
    Padding=UDim.new(0,6),
    VerticalAlignment=Enum.VerticalAlignment.Center,
    SortOrder=Enum.SortOrder.LayoutOrder,
}, BoothRow)

New("TextLabel", {
    Text="Booth:",
    TextSize=12, TextColor3=MUTED,
    BackgroundTransparency=1,
    Font=Enum.Font.Gotham,
    Size=UDim2.fromOffset(46,38),
    TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Center,
    LayoutOrder=1,
}, BoothRow)

local BoothBox = New("TextBox", {
    PlaceholderText="UUID atau nama booth...",
    PlaceholderColor3=MUTED,
    Text="", TextSize=13, TextColor3=TEXT,
    BackgroundColor3=CARD,
    Font=Enum.Font.Gotham,
    BorderSizePixel=0,
    ClearTextOnFocus=false,
    TextXAlignment=Enum.TextXAlignment.Left,
    Size=UDim2.new(1,-52,1,0),
    LayoutOrder=2,
}, BoothRow)
Corner(10, BoothBox)
Stroke(1, BORDER, BoothBox)
New("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)}, BoothBox)

-- ============================================================
-- LABEL COUNT + STATUS
-- ============================================================
local STATUS_Y = CTRL_H + BOOTH_H + 14
local StatusLbl = New("TextLabel", {
    Text="Masukkan UUID Booth di atas lalu tap Refresh.",
    TextSize=12, TextColor3=MUTED,
    BackgroundTransparency=1,
    Font=Enum.Font.Gotham,
    Size=UDim2.new(1,0,0,18),
    Position=UDim2.fromOffset(0, STATUS_Y),
    TextXAlignment=Enum.TextXAlignment.Left,
    TextWrapped=true,
}, CA)

-- ============================================================
-- SCROLLING LIST (tanpa AutomaticCanvasSize)
-- ============================================================
local LIST_Y  = STATUS_Y + 22
local LIST_H  = WH - 50 - LIST_Y - 20  -- tinggi area list
local ListSF  = MakeSF(UDim2.new(1,0,0,LIST_H), UDim2.fromOffset(0,LIST_Y), CA)
local ListLL  = New("UIListLayout", {
    Padding=UDim.new(0,8),
    SortOrder=Enum.SortOrder.LayoutOrder,
}, ListSF)

-- Update canvas saat layout berubah
ListLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ListSF.CanvasSize = UDim2.new(0,0,0,ListLL.AbsoluteContentSize.Y + 16)
end)

-- ============================================================
-- STATE
-- ============================================================
local State = {
    BoothUUID  = nil,
    Query      = "",
    SortMode   = "Rarity",  -- "Rarity" | "Name" | "Price"
    SortAsc    = false,
    Items      = {},
}
local SORT_CYCLE = {"Rarity", "Name", "Price"}
local sortIdx    = 1

-- ============================================================
-- BUILD ITEM CARD
-- ============================================================
local function BuildCard(item, idx)
    local rar   = ItemRar(item)
    local rcol  = RC(rar)
    local name  = ItemName(item)
    local img   = ItemImg(item)
    local wt    = ItemWt(item)
    local price = item.listingPrice or 0

    local CARD_H = 80
    local card = New("Frame", {
        Size=UDim2.new(1,0,0,CARD_H),
        BackgroundColor3=CARD,
        BorderSizePixel=0,
        LayoutOrder=idx,
    }, ListSF)
    Corner(12, card)
    Stroke(1.2, rcol:Lerp(BORDER,0.5), card)

    -- stripe kiri warna rarity
    local stripe = New("Frame", {
        Size=UDim2.fromOffset(4,60),
        Position=UDim2.fromOffset(0,10),
        BackgroundColor3=rcol,
        BorderSizePixel=0,
    }, card)
    Corner(3, stripe)

    -- gambar item
    local imgBox = New("Frame", {
        Size=UDim2.fromOffset(56,56),
        Position=UDim2.fromOffset(10,12),
        BackgroundColor3=rcol:Lerp(BG,0.76),
        BorderSizePixel=0,
    }, card)
    Corner(10, imgBox)
    if img ~= "" then
        New("ImageLabel", {
            Size=UDim2.fromScale(1,1),
            BackgroundTransparency=1,
            Image=img,
            ScaleType=Enum.ScaleType.Fit,
        }, imgBox)
    else
        New("TextLabel", {
            Text="?", TextSize=22, TextColor3=rcol,
            BackgroundTransparency=1, Font=Enum.Font.GothamBold,
            Size=UDim2.fromScale(1,1),
            TextXAlignment=Enum.TextXAlignment.Center,
            TextYAlignment=Enum.TextYAlignment.Center,
        }, imgBox)
    end

    -- info area
    local IX = 74
    New("TextLabel", {
        Text=name, TextSize=14, TextColor3=TEXT,
        BackgroundTransparency=1, Font=Enum.Font.GothamBold,
        Size=UDim2.new(1,-(IX+90),0,18),
        Position=UDim2.fromOffset(IX,10),
        TextTruncate=Enum.TextTruncate.AtEnd,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, card)

    -- rarity badge
    local rb = New("TextLabel", {
        Text=rar, TextSize=10, TextColor3=rcol,
        BackgroundColor3=rcol:Lerp(BG,0.82),
        Font=Enum.Font.GothamBold, BorderSizePixel=0,
        Size=UDim2.fromOffset(72,16),
        Position=UDim2.fromOffset(IX,30),
        TextXAlignment=Enum.TextXAlignment.Center,
    }, card)
    Corner(5, rb)

    -- weight
    if wt ~= "" then
        New("TextLabel", {
            Text=wt, TextSize=11, TextColor3=MUTED,
            BackgroundTransparency=1, Font=Enum.Font.Gotham,
            Size=UDim2.fromOffset(100,14),
            Position=UDim2.fromOffset(IX,50),
            TextXAlignment=Enum.TextXAlignment.Left,
        }, card)
    end

    -- seller
    local sname = ""
    if item.listingOwner then
        if type(item.listingOwner)=="table" then
            sname = item.listingOwner.Name or ""
        else
            sname = tostring(item.listingOwner)
        end
    end
    if sname ~= "" then
        New("TextLabel", {
            Text="@"..sname, TextSize=10, TextColor3=MUTED:Lerp(BG,0.3),
            BackgroundTransparency=1, Font=Enum.Font.Gotham,
            Size=UDim2.fromOffset(110,14),
            Position=UDim2.fromOffset(IX+104,50),
            TextXAlignment=Enum.TextXAlignment.Left,
        }, card)
    end

    -- harga
    New("TextLabel", {
        Text=Fmt(price), TextSize=17, TextColor3=GREEN,
        BackgroundTransparency=1, Font=Enum.Font.GothamBold,
        Size=UDim2.fromOffset(84,28),
        Position=UDim2.new(1,-160,0,10),
        TextXAlignment=Enum.TextXAlignment.Right,
    }, card)

    -- tombol BELI
    local myId = LP.UserId
    local ownId = type(item.listingOwner)=="table" and (item.listingOwner.UserId or 0) or 0
    local isOwn = ownId == myId

    if not isOwn then
        local buyBtn = Btn("Beli", GREEN, 14, card)
        buyBtn.Size = UDim2.fromOffset(68,38)
        buyBtn.Position = UDim2.new(1,-76,0.5,-19)
        local citem = item
        buyBtn.MouseButton1Click:Connect(function()
            buyBtn.Text = "..."
            buyBtn.Active = false
            Toast("Membeli "..ItemName(citem).."...", MUTED, 2)
            task.spawn(function()
                local ok2, res = pcall(function()
                    if BE and BE.BuyListing then
                        return BE.BuyListing:InvokeServer(citem.listingOwner, citem.listingUUID)
                    end
                    return false
                end)
                if ok2 and res then
                    Toast("Berhasil membeli "..ItemName(citem).."!", GREEN)
                    card:Destroy()
                else
                    Toast("Gagal membeli. Coba lagi!", RED)
                    buyBtn.Text = "Beli"
                    buyBtn.Active = true
                end
            end)
        end)
    else
        -- Milik sendiri — tampilkan badge
        New("TextLabel", {
            Text="Milikmu", TextSize=11, TextColor3=MUTED,
            BackgroundColor3=MUTED:Lerp(BG,0.8),
            Font=Enum.Font.GothamBold, BorderSizePixel=0,
            Size=UDim2.fromOffset(60,22),
            Position=UDim2.new(1,-72,0.5,-11),
            TextXAlignment=Enum.TextXAlignment.Center,
        }, card)
    end

    return card
end

-- ============================================================
-- REFRESH LISTING
-- ============================================================
local function ClearList()
    for _, c in ipairs(ListSF:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end
    ListSF.CanvasSize = UDim2.new(0,0,0,0)
end

local function DoRefresh()
    ClearList()

    if not BE then
        StatusLbl.Text = "TradeEvents tidak tersedia di game ini."
        StatusLbl.TextColor3 = RED
        return
    end

    local uuid = (BoothBox.Text ~= "" and BoothBox.Text) or State.BoothUUID

    StatusLbl.Text = "Memuat listing..."
    StatusLbl.TextColor3 = MUTED

    task.spawn(function()
        local data = nil

        -- Coba GetBoothData dulu (jika ada UUID)
        if uuid and uuid ~= "" then
            local ok2, d = pcall(function()
                if BE.GetBoothData then
                    return BE.GetBoothData:InvokeServer(uuid)
                end
                return nil
            end)
            if ok2 and d then data = d end
        end

        -- Fallback: GetAllListings
        if not data then
            local ok2, d = pcall(function()
                if BE.GetAllListings then
                    return BE.GetAllListings:InvokeServer()
                end
                return nil
            end)
            if ok2 and d then data = d end
        end

        if not data then
            StatusLbl.Text = "Tidak ada data. Masukkan UUID Booth yang valid."
            StatusLbl.TextColor3 = RED
            return
        end

        -- Normalisasi data ke array item
        local raw = {}
        if type(data) == "table" then
            raw = data.listings or data
        end

        local items = {}
        local q = string.lower(State.Query)
        for _, v in pairs(raw) do
            if type(v) == "table" then
                local it = {
                    id           = v.ItemId or v.id or "",
                    type         = v.ItemType or v.type or "Pet",
                    data         = v.ItemData or v.data or v.PetData or {},
                    listingOwner = v.Owner or v.listingOwner,
                    listingUUID  = v.UUID or v.listingUUID or v.id or "",
                    listingPrice = v.Price or v.listingPrice or 0,
                }
                if it.data.PetType == nil and v.PetType then
                    it.data.PetType = v.PetType
                end
                local nm = string.lower(ItemName(it))
                if q == "" or string.find(nm, q, 1, true) then
                    items[#items + 1] = it
                end
            end
        end

        -- Sort
        local smode = State.SortMode
        local sasc  = State.SortAsc
        table.sort(items, function(a, b)
            if smode == "Name" then
                local va, vb = ItemName(a), ItemName(b)
                if sasc then return va < vb else return va > vb end
            elseif smode == "Price" then
                local va = a.listingPrice or 0
                local vb2 = b.listingPrice or 0
                if va == vb2 then return ItemName(a) < ItemName(b) end
                if sasc then return va < vb2 else return va > vb2 end
            else -- Rarity
                local va = RORD[ItemRar(a)] or 0
                local vb2 = RORD[ItemRar(b)] or 0
                if va == vb2 then return ItemName(a) < ItemName(b) end
                if sasc then return va < vb2 else return va > vb2 end
            end
        end)

        State.Items = items

        if #items == 0 then
            StatusLbl.Text = "0 listing ditemukan."
            StatusLbl.TextColor3 = MUTED
            return
        end

        StatusLbl.Text = #items .. " listing ditemukan"
        StatusLbl.TextColor3 = GREEN

        for i = 1, #items do
            BuildCard(items[i], i)
        end
    end)
end

-- ============================================================
-- EVENT HANDLERS
-- ============================================================
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.Query = string.lower(SearchBox.Text)
    DoRefresh()
end)

BoothBox.FocusLost:Connect(function()
    State.BoothUUID = (BoothBox.Text ~= "" and BoothBox.Text) or nil
    DoRefresh()
end)

RefBtn.MouseButton1Click:Connect(function()
    State.BoothUUID = (BoothBox.Text ~= "" and BoothBox.Text) or State.BoothUUID
    DoRefresh()
end)

SortBtn.MouseButton1Click:Connect(function()
    sortIdx = sortIdx + 1
    if sortIdx > #SORT_CYCLE then
        sortIdx = 1
        State.SortAsc = not State.SortAsc
    end
    State.SortMode = SORT_CYCLE[sortIdx]
    local arrow = State.SortAsc and "+" or "-"
    SortBtn.Text = State.SortMode .. arrow
    DoRefresh()
end)

-- ============================================================
-- OPEN / CLOSE
-- ============================================================
local function OpenWindow()
    MW.Size = UDim2.fromOffset(WW * 0.9, WH * 0.9)
    MW.BackgroundTransparency = 1
    MW.Visible = true
    TweenService:Create(MW, TweenInfo.new(0.18), {
        Size=UDim2.fromOffset(WW,WH),
        BackgroundTransparency=0,
    }):Play()
end

local function CloseWindow()
    TweenService:Create(MW, TweenInfo.new(0.14), {
        Size=UDim2.fromOffset(WW * 0.9, WH * 0.9),
        BackgroundTransparency=1,
    }):Play()
    task.delay(0.15, function()
        MW.Visible = false
        MW.Size = UDim2.fromOffset(WW, WH)
        MW.BackgroundTransparency = 0
    end)
end

OpenBtn.MouseButton1Click:Connect(function()
    if MW.Visible then CloseWindow() else OpenWindow() end
end)
CloseBtn.MouseButton1Click:Connect(CloseWindow)

-- ============================================================
-- DRAGGABLE HEADER
-- ============================================================
do
    local drag, ds, sp
    HDR.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            ds = inp.Position
            sp = MW.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - ds
            MW.Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
end

-- ============================================================
-- SELESAI
-- ============================================================
print("[TradeGUI] Loaded! Tap 'Trade Market' untuk membuka.")
if not BE then
    warn("[TradeGUI] Booths events tidak ditemukan — pastikan script dijalankan di game Grow a Garden!")
end

end) -- end pcall

if not ok then
    warn("[TradeGUI] Fatal error:", tostring(err))
    -- Tampilkan error di layar
    local pgu = game:GetService("Players").LocalPlayer.PlayerGui
    local olde = pgu:FindFirstChild("TradeGUIErr")
    if olde then olde:Destroy() end
    local esg = Instance.new("ScreenGui")
    esg.Name = "TradeGUIErr"
    esg.ResetOnSpawn = false
    esg.Parent = pgu
    local ef = Instance.new("Frame", esg)
    ef.Size = UDim2.fromOffset(400,110)
    ef.Position = UDim2.new(0.5,-200,0.5,-55)
    ef.BackgroundColor3 = Color3.fromRGB(35,8,8)
    ef.BorderSizePixel = 0
    local ec = Instance.new("UICorner", ef)
    ec.CornerRadius = UDim.new(0,10)
    local el = Instance.new("TextLabel", ef)
    el.Text = "[TradeGUI Error]\n" .. tostring(err)
    el.TextSize = 12
    el.TextColor3 = Color3.fromRGB(255,100,100)
    el.BackgroundTransparency = 1
    el.Font = Enum.Font.Gotham
    el.Size = UDim2.fromScale(1,1)
    el.TextWrapped = true
    el.TextXAlignment = Enum.TextXAlignment.Center
    el.TextYAlignment = Enum.TextYAlignment.Center
end
