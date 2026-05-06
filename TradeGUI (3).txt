-- TradeGUI.lua | Grow a Garden | Mobile Friendly
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/cunoby/BangBoy/refs/heads/main/TradeGUI.lua"))()

local _ok, _err = pcall(function()

-- Services
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP  = Players.LocalPlayer
local PGui= LP:WaitForChild("PlayerGui", 10) or LP.PlayerGui
local Cam = workspace.CurrentCamera

-- Hapus GUI lama
local old = PGui:FindFirstChild("GrowTradeGUI")
if old then old:Destroy() end

-- Safe require
local function safeReq(inst)
    if not inst then return nil end
    local ok, r = pcall(require, inst)
    return ok and r or nil
end

-- Modul game (opsional)
local Mods = ReplicatedStorage:FindFirstChild("Modules")
local GE   = ReplicatedStorage:FindFirstChild("GameEvents")
local TE   = GE and GE:FindFirstChild("TradeEvents")
local BE   = TE and TE:FindFirstChild("Booths")

local INF  = Mods and safeReq(Mods:FindFirstChild("ItemNameFinder"))
local IIF  = Mods and safeReq(Mods:FindFirstChild("ItemImageFinder"))
local IRF  = Mods and safeReq(Mods:FindFirstChild("ItemRarityFinder"))
local PU   = (function()
    if not Mods then return nil end
    local ps = Mods:FindFirstChild("PetServices")
    return ps and safeReq(ps:FindFirstChild("PetUtilities")) or nil
end)()

-- Helpers item
local function ItemName(item)
    if not (item and item.data) then return "Unknown" end
    local k = item.data.PetType or item.data.ItemName or item.data.Name or item.data.SkinID or "Unknown"
    if INF then
        local ok, v = pcall(INF, k, item.type or "")
        if ok and v then return tostring(v) end
    end
    return tostring(k)
end

local function ItemImg(item)
    if not (item and item.data) then return "" end
    local k = item.data.PetType or item.data.ItemName or item.data.Name or item.data.SkinID or ""
    if IIF then
        local ok, v = pcall(IIF, k, item.type or "")
        if ok and v then return tostring(v) end
    end
    return ""
end

local RORD = {Common=1,Uncommon=2,Rare=3,Legendary=4,Mythic=5,Divine=6}
local function ItemRar(item)
    if not (item and item.data) then return "Common" end
    local k = item.data.PetType or item.data.ItemName or item.data.Name or item.data.SkinID or ""
    if IRF then
        local ok, v = pcall(IRF, k, item.type or "")
        if ok and v then return tostring(v) end
    end
    return "Common"
end

local function ItemWt(item)
    if item and item.data and item.data.PetData and PU then
        local ok, w = pcall(function()
            return PU:CalculateWeight(item.data.PetData.BaseWeight, item.data.PetData.Level)
        end)
        if ok and w then return string.format("%.1f kg", w) end
    end
    if item and item.data and item.data.PetData and item.data.PetData.BaseWeight then
        return string.format("%.1f kg", item.data.PetData.BaseWeight)
    end
    return ""
end

local function Fmt(n)
    n = tonumber(n) or 0
    if n >= 1000000000 then return string.format("%.1fB", n/1000000000)
    elseif n >= 1000000 then return string.format("%.1fM", n/1000000)
    elseif n >= 1000 then return string.format("%.1fK", n/1000)
    end
    return tostring(math.floor(n))
end

local function SortItems(items, stype, asc)
    local s = {}
    for i = 1, #items do s[i] = items[i] end
    table.sort(s, function(a, b)
        if stype == "Name" then
            local va, vb = ItemName(a), ItemName(b)
            if asc then return va < vb else return va > vb end
        elseif stype == "Rarity" then
            local va = RORD[ItemRar(a)] or 0
            local vb = RORD[ItemRar(b)] or 0
            if va == vb then return ItemName(a) < ItemName(b) end
            if asc then return va < vb else return va > vb end
        elseif stype == "Price" then
            local va2 = a and a.listingPrice or 0
            local vb2 = b and b.listingPrice or 0
            if va2 == vb2 then return ItemName(a) < ItemName(b) end
            if asc then return va2 < vb2 else return va2 > vb2 end
        end
        return false
    end)
    return s
end

-- Warna
local C = {
    BG      = Color3.fromRGB(13,15,22),
    Panel   = Color3.fromRGB(21,25,36),
    Card    = Color3.fromRGB(29,33,48),
    Border  = Color3.fromRGB(48,54,78),
    Green   = Color3.fromRGB(55,185,125),
    GreenDk = Color3.fromRGB(35,120,85),
    Red     = Color3.fromRGB(215,55,55),
    Blue    = Color3.fromRGB(85,135,255),
    Gold    = Color3.fromRGB(255,195,45),
    Text    = Color3.fromRGB(228,233,255),
    Muted   = Color3.fromRGB(105,115,148),
    Dim     = Color3.fromRGB(55,65,95),
    White   = Color3.new(1,1,1),
    Black   = Color3.new(0,0,0),
}
local RCOL = {
    Common   = Color3.fromRGB(165,165,165),
    Uncommon = Color3.fromRGB(65,195,85),
    Rare     = Color3.fromRGB(65,125,250),
    Legendary= Color3.fromRGB(175,65,250),
    Mythic   = Color3.fromRGB(250,125,25),
    Divine   = Color3.fromRGB(250,210,25),
}
local function RC(r) return RCOL[r] or C.Muted end

-- UI builders
local function New(cls, props, par)
    local i = Instance.new(cls)
    if props then
        for k,v in pairs(props) do
            i[k] = v
        end
    end
    if par then i.Parent = par end
    return i
end
local function Corner(r, p) New("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function Stroke(th,col,p) New("UIStroke",{Thickness=th,Color=col,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p) end
local function Pad(t,b,l,r,p) New("UIPadding",{PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r)},p) end
local function ListLayout(dir,align,pad,p)
    return New("UIListLayout",{
        FillDirection=dir or Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,pad or 6),
        VerticalAlignment=align or Enum.VerticalAlignment.Top,
    },p)
end
local function HList(pad, p) return New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,pad or 6),VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},p) end

local function Lbl(txt, sz, col, par)
    return New("TextLabel",{
        Text=txt, TextSize=sz, TextColor3=col,
        BackgroundTransparency=1, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Size=UDim2.new(1,0,0,sz+6),
    }, par)
end

local function MakeBtn(txt, bg, tc, sz, par)
    bg = bg or C.Green
    tc = tc or C.White
    local b = New("TextButton",{
        Text=txt, TextSize=sz or 14, TextColor3=tc,
        BackgroundColor3=bg, Font=Enum.Font.GothamBold,
        AutoButtonColor=false, BorderSizePixel=0,
        Size=UDim2.fromOffset(100,40),
    }, nil)
    Corner(10, b)
    local orig = bg
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=orig:Lerp(C.White,0.15)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=orig}):Play()
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.07),{BackgroundColor3=orig:Lerp(C.Black,0.2)}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.09),{BackgroundColor3=orig}):Play()
    end)
    if par then b.Parent = par end
    return b
end

local function MakeTBox(hint, par)
    local b = New("TextBox",{
        PlaceholderText=hint, PlaceholderColor3=C.Muted,
        Text="", TextSize=14, TextColor3=C.Text,
        BackgroundColor3=C.Card, Font=Enum.Font.Gotham,
        BorderSizePixel=0, ClearTextOnFocus=false,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,0,0,42),
    }, nil)
    Corner(10,b) Stroke(1,C.Border,b) Pad(0,0,12,12,b)
    if par then b.Parent=par end
    return b
end

local function MakeSF(par)
    local sf = New("ScrollingFrame",{
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=C.Border,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticCanvasSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        ElasticBehavior=Enum.ElasticBehavior.Always,
    }, nil)
    if par then sf.Parent=par end
    return sf
end

local function ClearSF(sf)
    for _, c in ipairs(sf:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") and not c:IsA("UICorner") then
            c:Destroy()
        end
    end
end

-- ScreenGui
local SG = New("ScreenGui",{Name="GrowTradeGUI",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PGui)

-- Deteksi ukuran layar
local VP     = Cam.ViewportSize
local IS_MOB = UserInputService.TouchEnabled
local WW     = IS_MOB and (VP.X - 12) or math.min(VP.X - 20, 460)
local WH     = IS_MOB and (VP.Y - 12) or math.min(VP.Y - 20, 660)

-- Toast notifikasi
local ToastF = New("Frame",{
    Size=UDim2.fromOffset(300,50), Position=UDim2.new(0.5,-150,0,8),
    BackgroundColor3=C.Panel, BorderSizePixel=0, Visible=false, ZIndex=200,
},SG)
Corner(10,ToastF) Stroke(1.5,C.Green,ToastF) Pad(0,0,12,12,ToastF)
local ToastL = New("TextLabel",{
    Text="", TextSize=13, TextColor3=C.Text,
    BackgroundTransparency=1, Font=Enum.Font.GothamBold,
    Size=UDim2.fromScale(1,1), TextWrapped=true,
    TextXAlignment=Enum.TextXAlignment.Center,
    TextYAlignment=Enum.TextYAlignment.Center, ZIndex=201,
},ToastF)
local _tt = nil
local function Toast(msg, col, dur)
    if _tt then task.cancel(_tt) end
    col = col or C.Green
    ToastL.Text = msg
    ToastL.TextColor3 = col
    local st = ToastF:FindFirstChildWhichIsA("UIStroke")
    if st then st.Color = col:Lerp(C.Border,0.4) end
    ToastF.Visible = true
    ToastF.BackgroundTransparency = 0
    _tt = task.delay(dur or 3, function()
        TweenService:Create(ToastF,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play()
        task.wait(0.22)
        ToastF.Visible = false
    end)
end

-- Open button
local OpenBtn = MakeBtn("Tap untuk Trade", C.Green, C.White, 14, SG)
OpenBtn.Size = UDim2.fromOffset(150,48)
OpenBtn.Position = UDim2.new(0,8,0.5,-24)
OpenBtn.ZIndex = 50
Stroke(1,C.GreenDk,OpenBtn)

-- Main Window
local MW = New("Frame",{
    Name="MainWin",
    Size=UDim2.fromOffset(WW,WH),
    Position=UDim2.new(0.5,0,0.5,0),
    AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=C.BG, BorderSizePixel=0,
    Visible=false, ZIndex=10,
},SG)
Corner(14,MW) Stroke(1.5,C.Border,MW)

-- Header
local HDR_H = 52
local HDR = New("Frame",{Size=UDim2.new(1,0,0,HDR_H),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=11},MW)
Corner(14,HDR)
New("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=10},HDR)
Lbl("🌱 Grow a Garden — Trade",15,C.Green,HDR).Position=UDim2.fromOffset(14,0)
HDR:FindFirstChildWhichIsA("TextLabel").Size=UDim2.new(1,-56,1,0)
HDR:FindFirstChildWhichIsA("TextLabel").TextYAlignment=Enum.TextYAlignment.Center

local CloseBtn = MakeBtn("X",Color3.fromRGB(195,50,50),C.White,18,HDR)
CloseBtn.Size=UDim2.fromOffset(36,36)
CloseBtn.Position=UDim2.new(1,-44,0.5,-18)
CloseBtn.ZIndex=12

-- Tab bar bawah
local TAB_H = 60
local TabBar = New("Frame",{
    Size=UDim2.new(1,0,0,TAB_H), Position=UDim2.new(0,0,1,-TAB_H),
    BackgroundColor3=C.Panel, BorderSizePixel=0, ZIndex=11,
},MW)
Corner(14,TabBar)
New("Frame",{Size=UDim2.new(1,0,0,14),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=10},TabBar)

-- Content area
local CA = New("Frame",{
    Size=UDim2.new(1,0,1,-HDR_H-TAB_H),
    Position=UDim2.fromOffset(0,HDR_H),
    BackgroundTransparency=1, BorderSizePixel=0,
    ClipsDescendants=true, ZIndex=10,
},MW)

-- State
local ST = {
    Panel="Listing",
    BoothUUID=nil, BoothQ="", BoothSort="Rarity", BoothAsc=false,
    InvCat="Pets", InvQ="", InvSort="Rarity", SelItem=nil,
    HistFilter="All", HistAsc=false, HistQ="", HistLogs={}, HistLoaded=false,
    PendReqId=nil,
    FSResult=nil, FSBusy=false,
}

-- Panels & tabs
local Panels = {}
local TabBtns = {}

local TAB_LIST = {
    {id="Listing",    lbl="Listing",   em="[S]"},
    {id="MyBooth",    lbl="Booth",     em="[B]"},
    {id="Inventory",  lbl="Inventori", em="[I]"},
    {id="FindSeller", lbl="Cari",      em="[C]"},
    {id="History",    lbl="Riwayat",   em="[R]"},
}

local function SetTab(id)
    ST.Panel = id
    for tid, p in pairs(Panels) do p.Visible=(tid==id) end
    for tid, b in pairs(TabBtns) do
        if tid==id then
            b.BackgroundColor3=C.Green
            b.TextColor3=C.White
        else
            b.BackgroundColor3=Color3.fromRGB(0,0,0)
            b.BackgroundTransparency=1
            b.TextColor3=C.Muted
        end
    end
end

local function MakePanel(id)
    local p = New("Frame",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        BorderSizePixel=0, Visible=false, ClipsDescendants=true,
    },CA)
    Pad(10,10,12,12,p)
    Panels[id]=p
    return p
end

local tabW = math.floor(WW/#TAB_LIST)
for i, def in ipairs(TAB_LIST) do
    local b = New("TextButton",{
        Size=UDim2.fromOffset(tabW,TAB_H),
        Position=UDim2.fromOffset((i-1)*tabW,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        Font=Enum.Font.GothamBold,
        Text=def.em.."\n"..def.lbl,
        TextSize=11, TextColor3=C.Muted,
        TextWrapped=true, LineHeight=1.2,
        ZIndex=12,
    },TabBar)
    TabBtns[def.id]=b
    local did = def.id
    b.MouseButton1Click:Connect(function()
        SetTab(did)
    end)
end

-- Item card builder
local function ItemCard(item, par, opts)
    opts = opts or {}
    local rar    = ItemRar(item)
    local rcol   = RC(rar)
    local name   = ItemName(item)
    local img    = ItemImg(item)
    local wt     = ItemWt(item)
    local price  = item.listingPrice

    local card = New("Frame",{
        Size=UDim2.new(1,0,0,80),
        BackgroundColor3=C.Card, BorderSizePixel=0,
    },par)
    Corner(12,card) Stroke(1,rcol:Lerp(C.Border,0.5),card)

    -- stripe kiri
    local strp = New("Frame",{
        Size=UDim2.fromOffset(4,58), Position=UDim2.fromOffset(0,11),
        BackgroundColor3=rcol, BorderSizePixel=0,
    },card)
    Corner(3,strp)

    -- gambar
    local imgF = New("Frame",{
        Size=UDim2.fromOffset(54,54), Position=UDim2.fromOffset(10,13),
        BackgroundColor3=rcol:Lerp(C.BG,0.78), BorderSizePixel=0,
    },card)
    Corner(10,imgF)
    if img and img~="" then
        New("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=img,ScaleType=Enum.ScaleType.Fit},imgF)
    else
        New("TextLabel",{Text="?",TextSize=22,TextColor3=rcol,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center},imgF)
    end

    -- info
    local IX = 72
    local btnW = (opts.showBuy or opts.showRemove or opts.showSelect) and 74 or 0
    local priceW = (opts.showPrice and price) and 72 or 0

    New("TextLabel",{
        Text=name, TextSize=14, TextColor3=C.Text,
        BackgroundTransparency=1, Font=Enum.Font.GothamBold,
        Size=UDim2.new(1,-(IX+btnW+priceW+8),0,18),
        Position=UDim2.fromOffset(IX,10),
        TextTruncate=Enum.TextTruncate.AtEnd,
        TextXAlignment=Enum.TextXAlignment.Left,
    },card)

    local rb = New("TextLabel",{
        Text=rar, TextSize=10, TextColor3=rcol,
        BackgroundColor3=rcol:Lerp(C.BG,0.82),
        Font=Enum.Font.GothamBold, BorderSizePixel=0,
        Size=UDim2.fromOffset(70,16), Position=UDim2.fromOffset(IX,30),
        TextXAlignment=Enum.TextXAlignment.Center,
    },card)
    Corner(5,rb)

    if wt~="" then
        New("TextLabel",{
            Text="W: "..wt, TextSize=11, TextColor3=C.Muted,
            BackgroundTransparency=1, Font=Enum.Font.Gotham,
            Size=UDim2.fromOffset(100,14), Position=UDim2.fromOffset(IX,50),
            TextXAlignment=Enum.TextXAlignment.Left,
        },card)
    end

    -- seller
    local sname = ""
    if item.listingOwner then
        if type(item.listingOwner)=="table" then sname=item.listingOwner.Name or ""
        else sname=tostring(item.listingOwner) end
    elseif item.seller then sname=tostring(item.seller) end
    if sname~="" then
        New("TextLabel",{
            Text="@"..sname, TextSize=10, TextColor3=C.Dim,
            BackgroundTransparency=1, Font=Enum.Font.Gotham,
            Size=UDim2.fromOffset(110,14), Position=UDim2.fromOffset(IX+102,50),
            TextXAlignment=Enum.TextXAlignment.Left,
        },card)
    end

    -- harga
    if opts.showPrice and price then
        local pf = New("Frame",{
            Size=UDim2.fromOffset(68,48),
            Position=UDim2.new(1,-(btnW+78),0.5,-24),
            BackgroundColor3=C.Panel, BorderSizePixel=0,
        },card)
        Corner(8,pf)
        New("TextLabel",{Text="Harga",TextSize=10,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Center},pf)
        New("TextLabel",{Text=Fmt(price),TextSize=15,TextColor3=C.Green,BackgroundTransparency=1,Font=Enum.Font.GothamBold,Size=UDim2.new(1,0,0,22),Position=UDim2.fromOffset(0,18),TextXAlignment=Enum.TextXAlignment.Center},pf)
    end

    -- tombol aksi
    if opts.onAction then
        local abg = opts.showBuy and C.Green or opts.showRemove and C.Red or C.Blue
        local atxt = opts.showBuy and "Beli" or opts.showRemove and "Hapus" or "Pilih"
        local ab = MakeBtn(atxt,abg,C.White,13,card)
        ab.Size=UDim2.fromOffset(70,36)
        ab.Position=UDim2.new(1,-76,0.5,-18)
        local citem = item
        ab.MouseButton1Click:Connect(function() opts.onAction(citem) end)
    end

    return card
end

-- Forward declarations
local RefreshListing  = nil
local RefreshMyBooth  = nil
local RefreshInventory= nil
local RefreshHistory  = nil
local OpenRemovePopup = nil
local DoBuyItem       = nil

-- ===== PANEL: LISTING =====
local PL = MakePanel("Listing")
ListLayout(nil,nil,0,PL)

local PL_topRow = New("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1},PL)
HList(6,PL_topRow)
local PL_search = MakeTBox("Cari nama pet...", PL_topRow)
PL_search.Size=UDim2.new(1,-158,1,-6)
local PL_sortBtn = MakeBtn("Sort:Rarity",C.Card,C.Text,12,PL_topRow)
PL_sortBtn.Size=UDim2.fromOffset(96,38)
local PL_refBtn  = MakeBtn("Refresh",C.Card,C.Text,12,PL_topRow)
PL_refBtn.Size=UDim2.fromOffset(56,38)

local PL_boothRow = New("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1},PL)
HList(6,PL_boothRow)
New("TextLabel",{Text="UUID:",TextSize=12,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.fromOffset(46,38),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},PL_boothRow)
local PL_boothBox = MakeTBox("Masukkan UUID atau nama booth...",PL_boothRow)
PL_boothBox.Size=UDim2.new(1,-52,1,0)
PL_boothBox.TextSize=13

local PL_count = New("TextLabel",{Text="0 listing",TextSize=11,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Left},PL)

local PL_sf = MakeSF(PL)
PL_sf.Size=UDim2.new(1,0,0,WH-HDR_H-TAB_H-116)
ListLayout(nil,nil,6,PL_sf)

local PL_sortCycle = {"Rarity","Name","Price"}
local PL_sortIdx = 1
PL_sortBtn.MouseButton1Click:Connect(function()
    PL_sortIdx = PL_sortIdx + 1
    if PL_sortIdx > #PL_sortCycle then PL_sortIdx = 1 end
    ST.BoothSort = PL_sortCycle[PL_sortIdx]
    ST.BoothAsc  = not ST.BoothAsc
    PL_sortBtn.Text = "S:"..ST.BoothSort..(ST.BoothAsc and "+" or "-")
    if RefreshListing then RefreshListing() end
end)
PL_search:GetPropertyChangedSignal("Text"):Connect(function()
    ST.BoothQ = string.lower(PL_search.Text)
    if RefreshListing then RefreshListing() end
end)
PL_boothBox.FocusLost:Connect(function()
    ST.BoothUUID = (PL_boothBox.Text~="" and PL_boothBox.Text) or nil
    if RefreshListing then RefreshListing() end
end)
PL_refBtn.MouseButton1Click:Connect(function()
    ST.BoothUUID = (PL_boothBox.Text~="" and PL_boothBox.Text) or ST.BoothUUID
    if RefreshListing then RefreshListing() end
end)

RefreshListing = function()
    ClearSF(PL_sf)
    if not BE then
        New("TextLabel",{Text="TradeEvents tidak tersedia.",TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,Size=UDim2.new(1,0,0,40),Font=Enum.Font.Gotham,TextWrapped=true},PL_sf)
        return
    end
    local data = nil
    if ST.BoothUUID and ST.BoothUUID~="" then
        local ok, d = pcall(function()
            if BE.GetBoothData then return BE.GetBoothData:InvokeServer(ST.BoothUUID) end
            return nil
        end)
        if ok then data=d end
    end
    if not data then
        local ok, d = pcall(function()
            if BE.GetAllListings then return BE.GetAllListings:InvokeServer() end
            return nil
        end)
        if ok then data=d end
    end
    if not data then
        New("TextLabel",{Text="Masukkan UUID Booth di bawah lalu tap Refresh, atau tidak ada listing saat ini.",TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,Size=UDim2.new(1,0,0,60),Font=Enum.Font.Gotham,TextWrapped=true},PL_sf)
        PL_count.Text="0 listing"
        return
    end
    local raw = type(data)=="table" and (data.listings or data) or {}
    local items = {}
    local q = ST.BoothQ
    local myId = LP.UserId
    for _, v in pairs(raw) do
        if type(v)=="table" then
            local it = {
                id=v.ItemId or v.id or "",
                type=v.ItemType or v.type or "Pet",
                data=v.ItemData or v.data or v.PetData or {},
                listingOwner=v.Owner or v.listingOwner,
                listingUUID=v.UUID or v.listingUUID or v.id or "",
                listingPrice=v.Price or v.listingPrice or 0,
            }
            if it.data.PetType==nil and v.PetType then it.data.PetType=v.PetType end
            if q=="" or string.find(string.lower(ItemName(it)),q,1,true) then
                items[#items+1]=it
            end
        end
    end
    items=SortItems(items,ST.BoothSort,ST.BoothAsc)
    PL_count.Text=#items.." listing"
    for i=1,#items do
        local item=items[i]
        local ownId = type(item.listingOwner)=="table" and item.listingOwner.UserId or 0
        local isOwn = ownId==myId
        local c=ItemCard(item,PL_sf,{
            showPrice=true,
            showBuy=not isOwn,
            showRemove=isOwn,
            onAction=function(it)
                if isOwn then if OpenRemovePopup then OpenRemovePopup(it) end
                else if DoBuyItem then DoBuyItem(it) end end
            end,
        })
        c.LayoutOrder=i
    end
end

-- ===== PANEL: MY BOOTH =====
local PM = MakePanel("MyBooth")

Lbl("Booth Saya",16,C.Text,PM)

local PM_row=New("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1},PM)
HList(8,PM_row)
local PM_addBtn   =MakeBtn("+ Listing Baru",C.Blue,C.White,12,PM_row)
PM_addBtn.Size=UDim2.fromOffset(130,40)
local PM_unBtn    =MakeBtn("Unclaim",C.Red,C.White,12,PM_row)
PM_unBtn.Size=UDim2.fromOffset(90,40)

local PM_search=MakeTBox("Cari item di booth...",PM)
local PM_count=New("TextLabel",{Text="0 item",TextSize=11,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Left},PM)
local PM_sf=MakeSF(PM)
PM_sf.Size=UDim2.new(1,0,0,WH-HDR_H-TAB_H-150)
ListLayout(nil,nil,6,PM_sf)

PM_addBtn.MouseButton1Click:Connect(function() SetTab("Inventory") end)
PM_unBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if BE and BE.RemoveBooth then BE.RemoveBooth:FireServer() end
    end)
    task.wait(0.5)
    if RefreshMyBooth then RefreshMyBooth() end
end)
PM_search:GetPropertyChangedSignal("Text"):Connect(function()
    if RefreshMyBooth then RefreshMyBooth() end
end)

RefreshMyBooth = function()
    ClearSF(PM_sf)
    local ok, data = pcall(function()
        if BE and BE.GetMyListings then return BE.GetMyListings:InvokeServer() end
        return nil
    end)
    if not ok or not data then
        New("TextLabel",{Text="Data booth tidak tersedia. Pastikan sudah claim booth di Trade World.",TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,Size=UDim2.new(1,0,0,60),Font=Enum.Font.Gotham,TextWrapped=true},PM_sf)
        PM_count.Text="0 item"
        return
    end
    local q=string.lower(PM_search.Text)
    local items={}
    for _, v in pairs(type(data)=="table" and data or {}) do
        if type(v)=="table" then
            local it={id=v.ItemId or v.id or "",type=v.ItemType or "Pet",data=v.ItemData or v.data or {},listingUUID=v.UUID or v.id or "",listingPrice=v.Price or 0}
            if q=="" or string.find(string.lower(ItemName(it)),q,1,true) then items[#items+1]=it end
        end
    end
    items=SortItems(items,"Rarity",false)
    PM_count.Text=#items.." item di booth"
    for i=1,#items do
        local it=items[i]
        local c=ItemCard(it,PM_sf,{showPrice=true,showRemove=true,onAction=function(x) if OpenRemovePopup then OpenRemovePopup(x) end end})
        c.LayoutOrder=i
    end
end

-- ===== PANEL: INVENTORI =====
local PI = MakePanel("Inventory")

local PI_catRow=New("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1},PI)
HList(6,PI_catRow)
local PI_CATS={{"Pets","Pet"},{"Plants","Plant"},{"Seeds","Benih"}}
local PI_catBtns={}
for _, cat in ipairs(PI_CATS) do
    local cid,clbl=cat[1],cat[2]
    local b=MakeBtn(clbl,C.Card,C.Muted,12,PI_catRow)
    b.Size=UDim2.fromOffset(86,38)
    PI_catBtns[cid]=b
    b.MouseButton1Click:Connect(function()
        ST.InvCat=cid
        for id2,b2 in pairs(PI_catBtns) do
            b2.BackgroundColor3=(id2==cid) and C.Green or C.Card
            b2.TextColor3=(id2==cid) and C.White or C.Muted
        end
        if RefreshInventory then RefreshInventory() end
    end)
end
PI_catBtns["Pets"].BackgroundColor3=C.Green
PI_catBtns["Pets"].TextColor3=C.White

local PI_search=MakeTBox("Cari item...",PI)
local PI_priceRow=New("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.Card,BorderSizePixel=0},PI)
Corner(10,PI_priceRow) Pad(4,4,10,10,PI_priceRow) HList(8,PI_priceRow)
New("TextLabel",{Text="Harga:",TextSize=12,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.fromOffset(52,36),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},PI_priceRow)
local PI_priceBox=MakeTBox("0",PI_priceRow)
PI_priceBox.Size=UDim2.new(1,-160,1,0)
local PI_listBtn=MakeBtn("Listing",C.Green,C.White,13,PI_priceRow)
PI_listBtn.Size=UDim2.fromOffset(78,36)

local PI_selLbl=New("TextLabel",{Text="Pilih item lalu tap Listing",TextSize=11,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Left},PI)
local PI_count=New("TextLabel",{Text="0 item",TextSize=11,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Left},PI)
local PI_sf=MakeSF(PI)
PI_sf.Size=UDim2.new(1,0,0,WH-HDR_H-TAB_H-186)
ListLayout(nil,nil,6,PI_sf)

local INV_MAP={Pets={"Pet"},Plants={"Holdable"},Seeds={"Seed","SeedPack"}}
PI_search:GetPropertyChangedSignal("Text"):Connect(function()
    ST.InvQ=string.lower(PI_search.Text)
    if RefreshInventory then RefreshInventory() end
end)
PI_listBtn.MouseButton1Click:Connect(function()
    if not ST.SelItem then Toast("Pilih item dulu!",C.Red); return end
    local price=tonumber(PI_priceBox.Text)
    if not price or price<=0 then Toast("Masukkan harga yang valid!",C.Red); return end
    local ok,res=pcall(function()
        if BE and BE.CreateListing then
            return BE.CreateListing:InvokeServer(ST.SelItem.type,ST.SelItem.id,price)
        end
        return false
    end)
    if ok and res then
        ST.SelItem=nil
        PI_priceBox.Text=""
        PI_selLbl.Text="Pilih item lalu tap Listing"
        PI_selLbl.TextColor3=C.Muted
        Toast("Item berhasil di-listing!",C.Green)
        if RefreshInventory then RefreshInventory() end
        if RefreshMyBooth then RefreshMyBooth() end
    else
        Toast("Gagal listing. Coba lagi!",C.Red)
    end
end)

RefreshInventory = function()
    ClearSF(PI_sf)
    local ok, data = pcall(function()
        if BE and BE.GetInventory then return BE.GetInventory:InvokeServer() end
        return nil
    end)
    if not ok or not data then
        New("TextLabel",{Text="Data inventori tidak tersedia.",TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,Size=UDim2.new(1,0,0,40),Font=Enum.Font.Gotham},PI_sf)
        PI_count.Text="0 item"
        return
    end
    local allowed=INV_MAP[ST.InvCat] or {}
    local q=ST.InvQ
    local items={}
    for _, v in pairs(type(data)=="table" and data or {}) do
        if type(v)=="table" then
            local itype=v.ItemType or v.type or ""
            local matches=false
            for _,a in ipairs(allowed) do if a==itype then matches=true break end end
            if matches or #allowed==0 then
                local it={id=v.ItemId or v.id or "",type=itype,data=v.ItemData or v.data or {}}
                if q=="" or string.find(string.lower(ItemName(it)),q,1,true) then
                    items[#items+1]=it
                end
            end
        end
    end
    items=SortItems(items,"Rarity",false)
    PI_count.Text=#items.." item"
    for i=1,#items do
        local it=items[i]
        local c=ItemCard(it,PI_sf,{
            showSelect=true,
            onAction=function(x)
                ST.SelItem=x
                PI_selLbl.Text="Dipilih: "..ItemName(x)
                PI_selLbl.TextColor3=C.Green
                for _,ch in ipairs(PI_sf:GetChildren()) do
                    if ch:IsA("Frame") then
                        TweenService:Create(ch,TweenInfo.new(0.1),{BackgroundColor3=C.Card}):Play()
                    end
                end
                TweenService:Create(c,TweenInfo.new(0.1),{BackgroundColor3=C.Blue:Lerp(C.Card,0.55)}):Play()
            end,
        })
        c.LayoutOrder=i
    end
end

-- ===== PANEL: FIND SELLER =====
local PFS = MakePanel("FindSeller")

Lbl("Find Seller",16,C.Text,PFS)
New("TextLabel",{Text="Cari seller online berdasarkan tipe & nama item.",TextSize=12,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,0,0,18),TextWrapped=true},PFS)
local PFS_type=MakeTBox("Tipe item (contoh: Pet)",PFS)
local PFS_name=MakeTBox("Nama item (contoh: Capybara)",PFS)
local PFS_go  =MakeBtn("Cari Seller",C.Green,C.White,15,PFS)
PFS_go.Size=UDim2.new(1,0,0,50)

local PFS_status=New("TextLabel",{Text="Isi tipe & nama, lalu tap Cari Seller.",TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,0,0,20),TextXAlignment=Enum.TextXAlignment.Center},PFS)

local PFS_res=New("Frame",{Size=UDim2.new(1,0,0,100),BackgroundColor3=C.Card,BorderSizePixel=0,Visible=false},PFS)
Corner(12,PFS_res) Stroke(1.5,C.Green:Lerp(C.Border,0.4),PFS_res) Pad(12,12,14,14,PFS_res)
local PFS_rName  =Lbl("",15,C.Text,PFS_res)
PFS_rName.Font=Enum.Font.GothamBold
local PFS_rSv    =Lbl("",12,C.Muted,PFS_res)
PFS_rSv.Position=UDim2.fromOffset(0,22)
local PFS_rPrice =Lbl("",14,C.Green,PFS_res)
PFS_rPrice.Position=UDim2.fromOffset(0,42)
local PFS_hopBtn =MakeBtn("Hop Server",C.Green,C.White,12,PFS_res)
PFS_hopBtn.Size=UDim2.fromOffset(104,36)
PFS_hopBtn.Position=UDim2.new(1,-108,1,-44)

local PFS_cur=nil
PFS_go.MouseButton1Click:Connect(function()
    if ST.FSBusy then return end
    local itype=PFS_type.Text
    local iname=PFS_name.Text
    if itype=="" or iname=="" then PFS_status.Text="Isi tipe dan nama item!"; PFS_status.TextColor3=C.Red; return end
    ST.FSBusy=true
    PFS_status.Text="Mencari seller..."
    PFS_status.TextColor3=C.Muted
    PFS_res.Visible=false
    PFS_go.Text="Mencari..."
    task.spawn(function()
        local ok, listing = pcall(function()
            if TE and TE.TokenRAPs and TE.TokenRAPs.FindSellers then
                return TE.TokenRAPs.FindSellers:InvokeServer(itype,{Name=iname,ItemType=itype})
            end
            return nil
        end)
        ST.FSBusy=false
        PFS_go.Text="Cari Seller"
        if ok and listing then
            PFS_cur=listing
            PFS_res.Visible=true
            PFS_rName.Text=iname.." ditemukan!"
            PFS_rSv.Text="Server: "..(listing.server or "Online")
            PFS_rPrice.Text="Harga: "..(listing.price and Fmt(listing.price).." token" or "???")
            PFS_status.Text="Seller ketemu! Tap Hop Server."
            PFS_status.TextColor3=C.Green
        else
            PFS_res.Visible=false
            PFS_status.Text="Tidak ada seller online untuk item ini."
            PFS_status.TextColor3=C.Red
        end
    end)
end)
PFS_hopBtn.MouseButton1Click:Connect(function()
    if not PFS_cur then return end
    PFS_hopBtn.Text="Hopping..."
    pcall(function()
        if TE and TE.TokenRAPs and TE.TokenRAPs.TeleportToListing then
            TE.TokenRAPs.TeleportToListing:InvokeServer(PFS_cur)
        end
    end)
    task.delay(2,function()
        PFS_hopBtn.Text="Hop Server"
        PFS_res.Visible=false
        PFS_cur=nil
        PFS_status.Text="Teleport dikirim!"
        PFS_status.TextColor3=C.Green
    end)
end)

-- ===== PANEL: HISTORY =====
local PH = MakePanel("History")

Lbl("Riwayat Trade",16,C.Text,PH)

local PH_filterRow=New("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1},PH)
HList(6,PH_filterRow)
local PH_FILTERS={"All","Dibeli","Dijual"}
local PH_fbtn={}
for _, f in ipairs(PH_FILTERS) do
    local b=MakeBtn(f,C.Card,C.Muted,12,PH_filterRow)
    b.Size=UDim2.fromOffset(74,36)
    PH_fbtn[f]=b
    local cf=f
    b.MouseButton1Click:Connect(function()
        ST.HistFilter=cf
        for fk,fb in pairs(PH_fbtn) do
            fb.BackgroundColor3=(fk==cf) and C.Green or C.Card
            fb.TextColor3=(fk==cf) and C.White or C.Muted
        end
        if RefreshHistory then RefreshHistory() end
    end)
end
PH_fbtn["All"].BackgroundColor3=C.Green
PH_fbtn["All"].TextColor3=C.White
local PH_sortBtn=MakeBtn("Terbaru",C.Card,C.Text,12,PH_filterRow)
PH_sortBtn.Size=UDim2.fromOffset(80,36)
PH_sortBtn.MouseButton1Click:Connect(function()
    ST.HistAsc=not ST.HistAsc
    PH_sortBtn.Text=ST.HistAsc and "Terlama" or "Terbaru"
    if RefreshHistory then RefreshHistory() end
end)

local PH_search=MakeTBox("Cari player atau item...",PH)
local PH_count=New("TextLabel",{Text="0 entri",TextSize=11,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Left},PH)
local PH_sf=MakeSF(PH)
PH_sf.Size=UDim2.new(1,0,0,WH-HDR_H-TAB_H-162)
ListLayout(nil,nil,6,PH_sf)

PH_search:GetPropertyChangedSignal("Text"):Connect(function()
    ST.HistQ=string.lower(PH_search.Text)
    if RefreshHistory then RefreshHistory() end
end)

RefreshHistory = function()
    ClearSF(PH_sf)
    local myId=LP.UserId
    local q=ST.HistQ
    local filt=ST.HistFilter

    local filtered={}
    for i=1,#ST.HistLogs do
        local log=ST.HistLogs[i]
        if type(log)~="table" then
            -- skip
        else
            local isSale=(log.seller and log.seller.userId==myId) or (log.type=="Sale")
            local skip=false
            if filt=="Dijual" and not isSale then skip=true end
            if filt=="Dibeli" and isSale then skip=true end
            if not skip and q~="" then
                local sn=(log.seller and (log.seller.username or log.seller.Name)) or ""
                local bn=(log.buyer and (log.buyer.username or log.buyer.Name)) or ""
                local ik=""
                if log.item and log.item.data then ik=log.item.data.PetType or log.item.data.ItemName or "" end
                if not (string.find(string.lower(sn),q,1,true) or string.find(string.lower(bn),q,1,true) or string.find(string.lower(ik),q,1,true)) then
                    skip=true
                end
            end
            if not skip then filtered[#filtered+1]=log end
        end
    end

    table.sort(filtered,function(a,b)
        local ta=a.finishTime or a.time or 0
        local tb=b.finishTime or b.time or 0
        if ST.HistAsc then return ta<tb else return ta>tb end
    end)

    PH_count.Text=#filtered.." entri"
    if #filtered==0 then
        New("TextLabel",{Text="Belum ada riwayat trade.",TextSize=13,TextColor3=C.Muted,BackgroundTransparency=1,Size=UDim2.new(1,0,0,40),Font=Enum.Font.Gotham},PH_sf)
        return
    end

    for i=1,#filtered do
        local log=filtered[i]
        local isSale=(log.seller and log.seller.userId==myId) or (log.type=="Sale")
        local sc = isSale and Color3.fromRGB(250,90,90) or C.Green
        local stxt = isSale and "Dijual" or "Dibeli"
        local partner=isSale and log.buyer or log.seller
        local pname=partner and ("@"..(partner.username or partner.Name or "???")) or "???"
        local ik=""
        if log.item and log.item.data then ik=log.item.data.PetType or log.item.data.ItemName or "" end
        local tstr=(log.finishTime and os.date("%d/%m %H:%M",log.finishTime)) or "???"

        local card=New("Frame",{Size=UDim2.new(1,0,0,64),BackgroundColor3=C.Card,BorderSizePixel=0},PH_sf)
        Corner(10,card) Stroke(1,sc:Lerp(C.Border,0.6),card) Pad(8,8,12,12,card)
        card.LayoutOrder=i

        local sb=New("TextLabel",{Text=stxt,TextSize=10,TextColor3=sc,BackgroundColor3=sc:Lerp(C.BG,0.82),Font=Enum.Font.GothamBold,Size=UDim2.fromOffset(48,16),BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Center},card)
        Corner(5,sb)
        New("TextLabel",{Text=pname,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Font=Enum.Font.GothamBold,Size=UDim2.new(1,-120,0,18),Position=UDim2.fromOffset(56,0),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},card)
        New("TextLabel",{Text="Item: "..ik,TextSize=11,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,-120,0,16),Position=UDim2.fromOffset(56,20),TextXAlignment=Enum.TextXAlignment.Left},card)
        New("TextLabel",{Text=tstr,TextSize=10,TextColor3=C.Dim,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,-120,0,14),Position=UDim2.fromOffset(56,38),TextXAlignment=Enum.TextXAlignment.Left},card)
        New("TextLabel",{Text=Fmt(log.price or 0),TextSize=16,TextColor3=sc,BackgroundTransparency=1,Font=Enum.Font.GothamBold,Size=UDim2.fromOffset(100,40),Position=UDim2.new(1,-108,0,0),TextXAlignment=Enum.TextXAlignment.Right},card)
    end
end

-- Realtime history
pcall(function()
    if TE and TE.Booths and TE.Booths.AddToHistory then
        TE.Booths.AddToHistory.OnClientEvent:Connect(function(log)
            if log then ST.HistLogs[#ST.HistLogs+1]=log end
            if ST.Panel=="History" and RefreshHistory then RefreshHistory() end
        end)
    end
end)

-- ===== POPUP: REMOVE LISTING =====
local RP = New("Frame",{
    Name="RemovePopup",
    Size=UDim2.fromOffset(math.min(WW-24,320),160),
    Position=UDim2.fromScale(0.5,0.5),
    AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,ZIndex=100,
},SG)
Corner(12,RP) Stroke(1.5,C.Red:Lerp(C.Border,0.4),RP) Pad(14,14,14,14,RP)

Lbl("Hapus Listing",15,C.Text,RP).ZIndex=101
local RP_name=Lbl("",13,C.Muted,RP)
RP_name.ZIndex=101
Lbl("Yakin hapus listing ini dari booth?",12,C.Muted,RP).ZIndex=101

local RP_btnRow=New("Frame",{Size=UDim2.new(1,0,0,44),Position=UDim2.new(0,0,1,-52),BackgroundTransparency=1,ZIndex=101},RP)
HList(10,RP_btnRow)
New("Frame",{Size=UDim2.new(1,-188,1,0),BackgroundTransparency=1},RP_btnRow)-- spacer
local RP_cancel=MakeBtn("Batal",C.Card,C.Text,13,RP_btnRow)
RP_cancel.Size=UDim2.fromOffset(86,40)
RP_cancel.ZIndex=102
local RP_ok=MakeBtn("Hapus",C.Red,C.White,13,RP_btnRow)
RP_ok.Size=UDim2.fromOffset(86,40)
RP_ok.ZIndex=102

local _rt=nil
OpenRemovePopup=function(item)
    _rt=item
    RP_name.Text=ItemName(item)
    RP.Visible=true
end
RP_cancel.MouseButton1Click:Connect(function() RP.Visible=false; _rt=nil end)
RP_ok.MouseButton1Click:Connect(function()
    if not _rt then return end
    local t=_rt; _rt=nil; RP.Visible=false
    task.spawn(function()
        local ok,res=pcall(function()
            if BE and BE.RemoveListing then return BE.RemoveListing:InvokeServer(t.listingUUID) end
            return false
        end)
        if ok and res then
            Toast("Listing "..ItemName(t).." dihapus!",C.Green)
            if RefreshMyBooth then RefreshMyBooth() end
            if RefreshListing then RefreshListing() end
        else
            Toast("Gagal hapus listing.",C.Red)
        end
    end)
end)

-- ===== BUY ITEM =====
DoBuyItem=function(item)
    Toast("Membeli "..ItemName(item).."...",C.Muted,1.5)
    task.spawn(function()
        local ok,res=pcall(function()
            if BE and BE.BuyListing then return BE.BuyListing:InvokeServer(item.listingOwner,item.listingUUID) end
            return false
        end)
        if ok and res then
            Toast("Berhasil membeli "..ItemName(item).."!",C.Green)
            if RefreshListing then RefreshListing() end
        else
            Toast("Gagal membeli. Coba lagi!",C.Red)
        end
    end)
end

-- ===== TRADE REQUEST POPUP =====
local TRP=New("Frame",{
    Name="TradeReqPopup",
    Size=UDim2.fromOffset(math.min(WW-24,300),150),
    Position=UDim2.new(0.5,-150,1,-168),
    BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,ZIndex=100,
},SG)
Corner(14,TRP) Stroke(1.5,C.Blue:Lerp(C.Border,0.3),TRP) Pad(12,12,12,12,TRP)

local TRP_ava=New("ImageLabel",{Size=UDim2.fromOffset(44,44),BackgroundColor3=C.Card,BorderSizePixel=0,ZIndex=101},TRP)
Corner(22,TRP_ava)
local TRP_name=New("TextLabel",{Text="",TextSize=14,TextColor3=C.Text,BackgroundTransparency=1,Font=Enum.Font.GothamBold,Size=UDim2.new(1,-56,0,22),Position=UDim2.fromOffset(52,0),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=101},TRP)
New("TextLabel",{Text="mengajak trade!",TextSize=12,TextColor3=C.Muted,BackgroundTransparency=1,Font=Enum.Font.Gotham,Size=UDim2.new(1,-56,0,18),Position=UDim2.fromOffset(52,22),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=101},TRP)
local TRP_timer=New("Frame",{Size=UDim2.new(1,0,0,4),Position=UDim2.fromOffset(0,52),BackgroundColor3=C.Blue,BorderSizePixel=0,ZIndex=101},TRP)
Corner(2,TRP_timer)

local TRP_btnRow=New("Frame",{Size=UDim2.new(1,0,0,44),Position=UDim2.new(0,0,1,-50),BackgroundTransparency=1,ZIndex=101},TRP)
HList(10,TRP_btnRow)
local TRP_dec=MakeBtn("Tolak",C.Red,C.White,13,TRP_btnRow)
TRP_dec.Size=UDim2.fromOffset(106,40) TRP_dec.ZIndex=102
local TRP_acc=MakeBtn("Terima",C.Green,C.White,13,TRP_btnRow)
TRP_acc.Size=UDim2.fromOffset(126,40) TRP_acc.ZIndex=102

local _rtimer=nil
local function RespondTrade(accepted)
    if not ST.PendReqId then return end
    pcall(function()
        if TE and TE.RespondRequest then
            TE.RespondRequest:FireServer(ST.PendReqId,accepted)
        end
    end)
    ST.PendReqId=nil
    if _rtimer then task.cancel(_rtimer) end
    TRP.Visible=false
end
TRP_acc.MouseButton1Click:Connect(function() RespondTrade(true) end)
TRP_dec.MouseButton1Click:Connect(function() RespondTrade(false) end)

pcall(function()
    if TE and TE.SendRequest then
        TE.SendRequest.OnClientEvent:Connect(function(reqId,sender,expireTime)
            ST.PendReqId=reqId
            TRP_name.Text=sender and sender.Name or "???"
            TRP_ava.Image=sender and string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",sender.UserId) or ""
            TRP_timer.Size=UDim2.new(1,0,0,4)
            TRP.Visible=true
            local dur=(expireTime and (expireTime-workspace:GetServerTimeNow())) or 30
            if _rtimer then task.cancel(_rtimer) end
            TweenService:Create(TRP_timer,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,4),BackgroundColor3=C.Red}):Play()
            _rtimer=task.delay(dur,function()
                if ST.PendReqId==reqId then ST.PendReqId=nil; TRP.Visible=false end
            end)
        end)
    end
end)

-- ===== OPEN / CLOSE =====
OpenBtn.MouseButton1Click:Connect(function()
    if MW.Visible then
        TweenService:Create(MW,TweenInfo.new(0.15),{Size=UDim2.fromOffset(WW*0.9,WH*0.9),BackgroundTransparency=1}):Play()
        task.delay(0.16,function() MW.Visible=false; MW.Size=UDim2.fromOffset(WW,WH); MW.BackgroundTransparency=0 end)
    else
        MW.Size=UDim2.fromOffset(WW*0.9,WH*0.9)
        MW.BackgroundTransparency=1
        MW.Visible=true
        TweenService:Create(MW,TweenInfo.new(0.18),{Size=UDim2.fromOffset(WW,WH),BackgroundTransparency=0}):Play()
        SetTab(ST.Panel)
    end
end)
CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MW,TweenInfo.new(0.15),{Size=UDim2.fromOffset(WW*0.9,WH*0.9),BackgroundTransparency=1}):Play()
    task.delay(0.16,function() MW.Visible=false; MW.Size=UDim2.fromOffset(WW,WH); MW.BackgroundTransparency=0 end)
end)

-- ===== DRAGGABLE =====
do
    local drag,ds,sp
    HDR.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=inp.Position; sp=MW.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            MW.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ===== TAB HISTORY: auto load saat pertama dibuka =====
TabBtns["History"].MouseButton1Click:Connect(function()
    if not ST.HistLoaded then
        ST.HistLoaded=true
        task.spawn(function()
            local ok,logs=pcall(function()
                if TE and TE.Booths and TE.Booths.FetchHistory then
                    return TE.Booths.FetchHistory:InvokeServer()
                end
                return {}
            end)
            if ok and logs then
                ST.HistLogs=logs
                if RefreshHistory then RefreshHistory() end
            end
        end)
    end
end)

-- ===== INIT =====
SetTab("Listing")
print("[TradeGUI] GUI dimuat! Tap tombol Trade untuk membuka.")

end) -- end pcall

if not _ok then
    warn("[TradeGUI] Error saat memuat: ", tostring(_err))
    -- Tampilkan error di layar
    local sg2 = game:GetService("Players").LocalPlayer.PlayerGui
    local old2 = sg2:FindFirstChild("TradeGUIErr")
    if old2 then old2:Destroy() end
    local es = Instance.new("ScreenGui")
    es.Name="TradeGUIErr" es.ResetOnSpawn=false es.Parent=sg2
    local ef = Instance.new("Frame",es)
    ef.Size=UDim2.fromOffset(380,100) ef.Position=UDim2.new(0.5,-190,0.5,-50)
    ef.BackgroundColor3=Color3.fromRGB(40,10,10) ef.BorderSizePixel=0
    local ec = Instance.new("UICorner",ef); ec.CornerRadius=UDim.new(0,10)
    local el = Instance.new("TextLabel",ef)
    el.Text="[TradeGUI Error]\n"..tostring(_err)
    el.TextSize=12 el.TextColor3=Color3.fromRGB(255,100,100)
    el.BackgroundTransparency=1 el.Font=Enum.Font.Gotham
    el.Size=UDim2.fromScale(1,1) el.TextWrapped=true
    el.TextXAlignment=Enum.TextXAlignment.Center el.TextYAlignment=Enum.TextYAlignment.Center
end
