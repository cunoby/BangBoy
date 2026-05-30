-- ==========================================
-- SCRIPT TESTER: AUTO PICK & PLACE (EVENT INTERCEPTOR - SPEED HUB METHOD)
-- ==========================================
local Speed_Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/cunoby/BangBoy/refs/heads/main/D.lua"))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local PetsService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetsService")
local ActivePetsService = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)

-- VARIABEL
local PetKebun = {}
local PickPlacePets = {}
local DelayToPick = 0.5
local DelayToPlace = 0.5
local AutoPickPlaceOn = false
local SedangDiProses = {} -- Pengaman Anti-Spam

-- FUNGSI KEBUN & SCAN
local function GetMyFarmCenter()
    local farmFolder = workspace:FindFirstChild("Farm") or workspace:FindFirstChild("Farms")
    if not farmFolder then return nil end
    for _, kebun in ipairs(farmFolder:GetChildren()) do
        local ownerVal = kebun:FindFirstChild("Important") and kebun.Important:FindFirstChild("Data") and kebun.Important.Data:FindFirstChild("Owner")
        if ownerVal and tostring(ownerVal.Value) == LocalPlayer.Name then
            local center = kebun:FindFirstChild("Spawn_Point") or kebun:FindFirstChild("Center_Point")
            if center then return center:IsA("BasePart") and center.CFrame or CFrame.new(center.Value) end
        end
    end
    return nil
end

local function ScanKebun()
    table.clear(PetKebun)
    pcall(function()
        local scrollingFrame = PlayerGui.ActivePetUI.Frame.Main.PetDisplay.ScrollingFrame
        for _, item in ipairs(scrollingFrame:GetChildren()) do
            if string.find(item.Name, "-") then
                local uuid = item.Name
                local namaPet = "Unknown"
                local data = ActivePetsService:GetPetData(LocalPlayer.Name, uuid)
                if data and data.PetType then namaPet = data.PetType end
                
                local uuidBersih = string.gsub(uuid, "[^%w]", "") 
                local uuidPendek = string.sub(uuidBersih, 1, 4) 
                local teksDropdown = namaPet .. " [#" .. string.upper(uuidPendek) .. "]"
                table.insert(PetKebun, { Id = uuid, Nama = namaPet, Teks = teksDropdown })
            end
        end
    end)
end

local function AmbilDaftarNama(tabelPet)
    local daftar = {}
    for _, pet in ipairs(tabelPet) do table.insert(daftar, pet.Teks) end
    return #daftar > 0 and daftar or {"Kosong"}
end

local function UpdateMultiSelectState(tabelSumber, daftarPilihanUI, tabelStateTarget)
    table.clear(tabelStateTarget)
    for _, namaDipilih in ipairs(daftarPilihanUI) do
        for _, pet in ipairs(tabelSumber) do
            if pet.Teks == namaDipilih then table.insert(tabelStateTarget, pet) end
        end
    end
end

-- PEMBUATAN UI
local Window = Speed_Library:CreateWindow({
    Title = "Tester Pick & Place",
    Description = "Event Interceptor (No UI CCTV)",
    TabWidth = 140,
    SizeUi = UDim2.fromOffset(500, 320)
})

local TabMain = Window:CreateTab({Name = "Tester", Icon = "rbxassetid://7734010488"})
local SecTest = TabMain:AddSection("Sistem Sadap Sinyal Server", false)
local DropPickPlace 

SecTest:AddButton({
    Title = "🔍 Scan Pet di Kebun", 
    Content = "Tanam pet dulu, lalu klik ini",
    Callback = function()
        ScanKebun()
        if DropPickPlace then
            DropPickPlace:Refresh(AmbilDaftarNama(PetKebun), DropPickPlace.Value)
        end
        Speed_Library:SetNotification({Title = "Scan Selesai", Description = "Berhasil", Content = "Daftar pet sudah diperbarui!", Time = 2})
    end
})

DropPickPlace = SecTest:AddDropdown({
    Title = "Pilih Pet", Content = "Pilih dari hasil scan kebun", Multi = true, Options = {"Kosong"}, Default = {},
    Callback = function(Options) UpdateMultiSelectState(PetKebun, Options, PickPlacePets) end 
})

SecTest:AddInput({
    Title = "Delay To Pick", Content = "Jeda saat ditarik (0.1)", Default = "0.1",
    Callback = function(Text) DelayToPick = tonumber(Text) or 0.1 end
})

SecTest:AddInput({
    Title = "Delay To Place", Content = "Jeda saat ditanam (0.1)", Default = "0.1",
    Callback = function(Text) DelayToPlace = tonumber(Text) or 0.1 end
})

SecTest:AddToggle({
    Title = "▶️ MULAI TESTER", Content = "Sadap data cooldown server!", Default = false,
    Callback = function(Value) AutoPickPlaceOn = Value end
})

-- ==========================================
-- MESIN PENYADAP SERVER (100% PASIF, TANPA LOOPING!)
-- ==========================================
local PetCooldownsUpdated = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetCooldownsUpdated")

PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdData)
    -- 1. Matikan jika toggle belum nyala
    if not AutoPickPlaceOn then return end
    
    -- 2. Matikan jika pet ini sedang kita proses agar tidak ditarik berkali-kali
    if SedangDiProses[uuid] then return end
    
    -- 3. Cek apakah UUID ini ada di daftar pet yang kita pilih di Dropdown
    local isTarget = false
    for _, pet in ipairs(PickPlacePets) do
        if pet.Id == uuid then isTarget = true break end
    end
    if not isTarget then return end
    
    -- 4. BEDAH DATA DARI SERVER (Sesuai dengan kode ActivePetsUIController yang kita temukan)
    local baruSajaMukul = false
    if cdData then
        for _, slotData in pairs(cdData) do
            if slotData and type(slotData) == "table" and slotData.Time then
                -- FILTER CERDAS: Jika server memberi cooldown lebih dari 1.5 detik, 
                -- berarti ini MURNI HASIL MUKUL TANAMAN (bukan cooldown pasang pet ke kebun)
                if slotData.Time > 1.5 then
                    baruSajaMukul = true
                    break
                end
            end
        end
    end
    
    -- 5. EKSEKUSI PENCURIAN JIKA TERBUKTI MUKUL!
    if baruSajaMukul then
        SedangDiProses[uuid] = true -- Kunci pet ini
        
        task.spawn(function()
            -- Beri waktu sedikit untuk animasi damage mendarat (Diatur dari UI)
            task.wait(DelayToPick) 
            
            -- TARIK PAKSA!
            PetsService:FireServer("UnequipPet", uuid)
            
            -- JEDA TRANSISI
            task.wait(DelayToPlace) 
            
            -- TANAM KEMBALI
            local koordinat = GetMyFarmCenter()
            if koordinat then
                PetsService:FireServer("EquipPet", uuid, koordinat)
            end
            
            -- Buka kunci setelah selesai
            task.wait(0.2)
            SedangDiProses[uuid] = nil
        end)
    end
end)
