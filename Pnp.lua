-- ==========================================
-- SCRIPT AUTO FARM: GERY'S PIPELINE (TARGET TIME ENGINE)
-- ==========================================
local Speed_Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/cunoby/BangBoy/refs/heads/main/D.lua"))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local PetsService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetsService")
local ActivePetsService = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)

-- VARIABEL MESIN
local PetKebun = {}
local PickPlacePets = {}
local DelayToPick = 0.6 
local DelayToPlace = 0.1
local AutoPickPlaceOn = false

-- MEMORI WAKTU TARGET (os.clock) KHUSUS SLOT 1
local TargetSelesaiPet = {} 
local SedangDiProses = {}

-- FUNGSI KEBUN (CARI KOORDINAT)
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

-- FUNGSI SCAN UI
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

-- ==========================================
-- PEMBUATAN UI
-- ==========================================
local Window = Speed_Library:CreateWindow({
    Title = "Tester Pick & Place",
    Description = "Jam Dunia / Target Time Engine",
    TabWidth = 140,
    SizeUi = UDim2.fromOffset(500, 320)
})

local TabMain = Window:CreateTab({Name = "Tester", Icon = "rbxassetid://7734010488"})
local SecTest = TabMain:AddSection("Konfigurasi Alur", false)
local DropPickPlace 

SecTest:AddButton({
    Title = "🔍 Scan Pet dari Layar", 
    Content = "Tanam pet, lalu klik ini",
    Callback = function()
        ScanKebun()
        if DropPickPlace then
            DropPickPlace:Refresh(AmbilDaftarNama(PetKebun), DropPickPlace.Value)
        end
        Speed_Library:SetNotification({Title = "Scan Selesai", Description = "Berhasil", Content = "Pilih pet di bawah!", Time = 2})
    end
})

DropPickPlace = SecTest:AddDropdown({
    Title = "Pilih Pet", Content = "Pilih target eksekusi", Multi = true, Options = {"Kosong"}, Default = {},
    Callback = function(Options) UpdateMultiSelectState(PetKebun, Options, PickPlacePets) end 
})

SecTest:AddInput({
    Title = "Delay Tambahan", Content = "Jeda STELAH Jeda Wajib 1s", Default = "0.5",
    Callback = function(Text) DelayToPick = tonumber(Text) or 0.5 end
})

SecTest:AddInput({
    Title = "Delay Tas", Content = "Jeda saat di dalam tas", Default = "0.1",
    Callback = function(Text) DelayToPlace = tonumber(Text) or 0.1 end
})

SecTest:AddToggle({
    Title = "▶️ MULAI MESIN", Content = "Jalankan Auto Pick & Place", Default = false,
    Callback = function(Value) 
        AutoPickPlaceOn = Value 
        if Value then 
            table.clear(TargetSelesaiPet) 
            table.clear(SedangDiProses)
            print("🚀 [Sistem] Mesin Jam Dunia Dinyalakan!")
        end 
    end
})

-- ==========================================
-- 1. RADAR SERVER (TENTUKAN TARGET JAM SELESAI)
-- ==========================================
local PetCooldownsUpdated = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetCooldownsUpdated")

PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdData)
    if not AutoPickPlaceOn then return end
    
    if cdData then
        -- Kunci target hanya ke Slot 1
        local slotUtama = cdData[1] or cdData["1"]
        
        if slotUtama and type(slotUtama) == "table" and slotUtama.Time then
            -- MENGGUNAKAN JAM DUNIA: Waktu sekarang + Cooldown dari server
            local sisaWaktu = slotUtama.Time
            TargetSelesaiPet[uuid] = os.clock() + sisaWaktu
        end
    end
end)

-- ==========================================
-- 2. PIPELINE ALUR EKSEKUSI (BISA BERPUTAR SANGAT CEPAT)
-- ==========================================
task.spawn(function()
    -- Sekarang kita bisa pakai 0.1 untuk respon kilat tanpa merusak hitungan detik!
    while task.wait(0.01) do
        if not AutoPickPlaceOn then continue end
        
        local jamSekarang = os.clock()
        local kumpulanPetReady = {}
        
        -- Cek target jam selesai semua pet terpilih
        for _, pet in ipairs(PickPlacePets) do
            local uuid = pet.Id
            
            if SedangDiProses[uuid] then continue end 
            
            local targetJam = TargetSelesaiPet[uuid]
            
            -- Jika jam dunia sekarang sudah melebihi atau sama dengan jam target
            if targetJam and jamSekarang >= targetJam then
                SedangDiProses[uuid] = true 
                table.insert(kumpulanPetReady, uuid)
            end
        end
        
        -- PROSES ALUR BERUNTUN
        if #kumpulanPetReady > 0 then
            for urutan, uuid in ipairs(kumpulanPetReady) do
                
                task.spawn(function()
                    task.wait((urutan - 1) * 0.1) 
                    
                    print("⚡ [Alur] Pet #" .. string.sub(uuid, 1, 4) .. " Ready! Eksekusi...")
                    
                    -- TAHAP 1 & 2: Tunggu 1s + Custom Delay
                    task.wait(1 + DelayToPick)
                    
                    -- TAHAP 3: Tarik Paksa
                    PetsService:FireServer("UnequipPet", uuid)
                    
                    -- TAHAP 4: Jeda Tas
                    task.wait(DelayToPlace)
                    
                    -- TAHAP 5: Tanam Kembali
                    local koordinat = GetMyFarmCenter()
                    if koordinat then
                        PetsService:FireServer("EquipPet", uuid, koordinat)
                    end
                    
                    -- TAHAP 6: Buka Gembok (Target jam dinonaktifkan sampai ada sinyal baru)
                    task.wait(0.01) 
                    TargetSelesaiPet[uuid] = nil
                    SedangDiProses[uuid] = nil
                end)
                
            end
        end
        
    end
end)
