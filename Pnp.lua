-- ==========================================
-- SCRIPT TESTER: AUTO PICK & PLACE (CCTV PRE-EMPTIVE STRIKE)
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
local DelayToPick = 1.0
local DelayToPlace = 0.1
local AutoPickPlaceOn = false

-- PENGAMAN & INGATAN
local StatusTerakhirPet = {} 
local SedangDiProses = {}

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

-- FUNGSI CCTV: BACA TEKS UI
local function CekCooldownPet(uuid)
    local isReady = false
    pcall(function()
        local petFrame = PlayerGui.ActivePetUI.Frame.Main.PetDisplay.ScrollingFrame:FindFirstChild(uuid)
        if petFrame then
            local cdText = petFrame.Main.Cooldowns.COOLDOWN_1.COOLDOWN_NAME.Text
            if string.find(string.lower(cdText), "ready") then
                isReady = true
            end
        end
    end)
    return isReady
end

-- PEMBUATAN UI
local Window = Speed_Library:CreateWindow({
    Title = "Tester Pick & Place",
    Description = "CCTV Strike Sebelum Cooldown",
    TabWidth = 140,
    SizeUi = UDim2.fromOffset(500, 320)
})

local TabMain = Window:CreateTab({Name = "Tester", Icon = "rbxassetid://7734010488"})
local SecTest = TabMain:AddSection("Konfigurasi CCTV", false)
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
    Title = "Delay To Pick", Content = "Jeda STELAH tulisan READY (1.0)", Default = "1.0",
    Callback = function(Text) DelayToPick = tonumber(Text) or 1.0 end
})

SecTest:AddInput({
    Title = "Delay To Place", Content = "Jeda masuk tas (0.1)", Default = "0.1",
    Callback = function(Text) DelayToPlace = tonumber(Text) or 0.1 end
})

SecTest:AddToggle({
    Title = "▶️ MULAI CCTV", Content = "Aktifkan eksekusi kilat", Default = false,
    Callback = function(Value) 
        AutoPickPlaceOn = Value 
        if Value then 
            table.clear(StatusTerakhirPet) 
            table.clear(SedangDiProses)
        end 
    end
})

-- MESIN UTAMA CCTV (LOGIKA TRIGGER SAAT READY)
task.spawn(function()
    while task.wait(0.1) do 
        if AutoPickPlaceOn and #PickPlacePets > 0 then
            
            for _, pet in ipairs(PickPlacePets) do
                local uuid = pet.Id
                
                -- Lewati jika script dimatikan atau pet ini sedang dieksekusi timer-nya
                if not AutoPickPlaceOn then break end
                if SedangDiProses[uuid] then continue end 
                
                -- Baca layar saat ini
                local apakahReadySekarang = CekCooldownPet(uuid)
                local apakahReadySebelumnya = StatusTerakhirPet[uuid]
                
                -- Inisialisasi awal agar tidak error
                if apakahReadySebelumnya == nil then
                    StatusTerakhirPet[uuid] = apakahReadySekarang
                    continue
                end
                
                -- LOGIKA EMAS BARU (Sesuai idemu!):
                -- Jika 0.1 detik yang lalu teksnya ANGKA, TAPI SEKARANG BERUBAH JADI "READY"
                if apakahReadySebelumnya == false and apakahReadySekarang == true then
                    
                    -- Kunci pet ini agar tidak tertrigger berkali-kali
                    SedangDiProses[uuid] = true
                    
                    task.spawn(function()
                        -- 1. BERI WAKTU AGAR PET JALAN DAN MUKUL (Sesuai Input UI)
                        task.wait(DelayToPick) 
                        
                        -- 2. TARIK PAKSA! (Dilakukan sebelum cooldown baru muncul)
                        PetsService:FireServer("UnequipPet", uuid)
                        
                        -- 3. JEDA TRANSISI
                        task.wait(DelayToPlace) 
                        
                        -- 4. TANAM KEMBALI
                        local koordinat = GetMyFarmCenter()
                        if koordinat then
                            PetsService:FireServer("EquipPet", uuid, koordinat)
                        end
                        
                        -- 5. BUKA PENGAMAN SETELAH SELESAI
                        task.wait(0.5)
                        SedangDiProses[uuid] = nil
                    end)
                end
                
                -- Simpan status saat ini untuk dicek di putaran berikutnya
                StatusTerakhirPet[uuid] = apakahReadySekarang
            end
            
        end
    end
end)
