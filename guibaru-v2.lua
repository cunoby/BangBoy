-- ==========================================
-- CUSTOM PREMIUM UI LIBRARY (LOADER)
-- ==========================================
local Speed_Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/cunoby/BangBoy/refs/heads/main/D.lua"))()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer.PlayerGui
local PetsService       = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetsService")
local ActivePetsService = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)
local PetUtilities      = require(ReplicatedStorage.Modules.PetServices.PetUtilities)

-- ==========================================
-- STATE & VARIABEL MESIN
-- ==========================================
local FavPet = {}
local NonFav = {}
local PetTeamElephant = {}
local PetTeamLeveling = {}
local PetTeamAge100 = {}
local PetBahan = {}
local ElephantMinAge = 50
local ElephantResetAge = 1
local LevelingMinAge = 1
local LevelingMaxAge = 50
local Age100MinAge   = 55
local Age100MaxAge   = 100
local BahanBatchSize = 2

local AutoElephantOn = false
local WaktuTerakhirGerak = 0
local FaseFarming = "TANAM"  
local BahanDiKebun = {} 
local GajahMentokNotif = false
local CycleCount = 0
local WaktuStartBot = tick()
local WaktuStartCycle = tick()
local WebhookURL = ""
local AntiAFKOn = true

-- ==========================================
-- VARIABEL & SISTEM SADAP SERVER (SKILL CANCEL)
-- ==========================================
local PetKebun = {}
local PickPlacePets = {}
local DelayToPick = 0.5
local DelayToPlace = 0.5
local AutoPickPlaceOn = false

local PetCooldownsUpdated = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetCooldownsUpdated")
local CooldownDatabase = {}

-- 1. Menyadap Sinyal Server
PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdData)
    CooldownDatabase[uuid] = cdData
end)

-- 2. Menghitung Mundur di Background (Kebal Tutup UI)
task.spawn(function()
    while task.wait(1) do
        for uuid, slots in pairs(CooldownDatabase) do
            if slots then
                for _, slotData in ipairs(slots) do
                    if slotData and slotData.Time then
                        slotData.Time = math.max(0, slotData.Time - 1)
                    end
                end
            end
        end
    end
end)

local function IsPetSkillReady(uuid)
    local slots = CooldownDatabase[uuid]
    if slots then
        if slots[1] and slots[1].Time <= 0 then return true end
        if slots[2] and slots[2].Time <= 0 then return true end
    end
    return false 
end

-- ==========================================
-- 1. FUNGSI KEBUN & PET
-- ==========================================
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

local function PlacePet(petId)
    WaktuTerakhirGerak = tick()
    local koordinatKebun = GetMyFarmCenter()
    if not koordinatKebun then return false end
    local sukses, _ = pcall(function() PetsService:FireServer("EquipPet", petId, koordinatKebun) end)
    return sukses
end

local function PickupPet(petId)
    WaktuTerakhirGerak = tick()
    local sukses, _ = pcall(function() PetsService:FireServer("UnequipPet", petId) end)
    return sukses
end

local function TarikSemuaPetDiAwal()
    print("[Sistem] Memulai pembersihan kebun otomatis...")
    pcall(function()
        local scrollingFrame = PlayerGui.ActivePetUI.Frame.Main.PetDisplay.ScrollingFrame
        for _, item in ipairs(scrollingFrame:GetChildren()) do
            if string.find(item.Name, "-") then PickupPet(item.Name) task.wait(0.1) end
        end
    end)
end

local function AmbilUmur(item)
    local umur = 1
    pcall(function()
        local uuid = item:GetAttribute("PET_UUID")
        local data = ActivePetsService:GetPetData(LocalPlayer.Name, uuid)
        if data and data.PetData then umur = data.PetData.Level end
    end)
    return umur
end

local function AmbilUmurDiKebun(petId)
    local umur = 0
    pcall(function()
        local data = ActivePetsService:GetPetData(LocalPlayer.Name, petId)
        if data and data.PetData then umur = data.PetData.Level end
    end)
    return umur
end

local function ScanTas()
    table.clear(FavPet) table.clear(NonFav)
    local tas = LocalPlayer:FindFirstChild("Backpack")
    if not tas then return end
    for _, item in ipairs(tas:GetChildren()) do
        if item:GetAttribute("ItemType") == "Pet" then
            local uuid = item:GetAttribute("PET_UUID")
            if uuid and uuid ~= "" then
                local dataPet = {
                    Id = uuid, Nama = item:GetAttribute("f") or item.Name,
                    Umur = AmbilUmur(item), Teks = item.Name .. " [#" .. string.upper(string.sub(string.gsub(uuid, "[^%w]", ""), 1, 4)) .. "]",
                }
                if item:GetAttribute("d") == true then table.insert(FavPet, dataPet) else table.insert(NonFav, dataPet) end
            end
        end
    end
end

local function InfoBahan()
    local daftarNama = {}
    for _, id in ipairs(BahanDiKebun) do
        local namaPet = "Unknown"
        for _, pet in ipairs(PetBahan) do if pet.Id == id then namaPet = pet.Nama break end end
        table.insert(daftarNama, namaPet)
    end
    return #daftarNama == 0 and "Bahan" or table.concat(daftarNama, " & ")
end

local function GetDetailBahan()
    if #BahanDiKebun == 0 then
        return "> **[Bahan Kosong]**\n> **Name :** -\n> **Age :** 0\n> **Kg :** 0"
    end

    local teksDetail = ""
    for i, id in ipairs(BahanDiKebun) do
        local namaPet = "Unknown"
        for _, pet in ipairs(PetBahan) do
            if pet.Id == id then
                namaPet = pet.Nama
                break
            end
        end
        
        local umurPet = 0
        local beratPet = 0
        pcall(function()
            local data = ActivePetsService:GetPetData(LocalPlayer.Name, id)
            if data and data.PetData then
                umurPet = data.PetData.Level
                local baseWeight = data.PetData.BaseWeight
                beratPet = PetUtilities:CalculateWeight(baseWeight, umurPet, data.PetType)
            end
        end)
        
        local beratFormat = string.format("%.2f", beratPet)
        
        teksDetail = teksDetail .. "> **[Bahan " .. i .. "]**\n"
        teksDetail = teksDetail .. "> **Name :** " .. namaPet .. "\n"
        teksDetail = teksDetail .. "> **Age :** " .. umurPet .. "\n"
        teksDetail = teksDetail .. "> **Kg :** " .. beratFormat
        
        if i < #BahanDiKebun then
            teksDetail = teksDetail .. "\n> \n"
        end
    end
    return teksDetail
end

local function GetSisaBahan()
    local sisa = 0
    for _, petBahan in ipairs(PetBahan) do
        local inKebun = false
        for _, id in ipairs(BahanDiKebun) do
            if id == petBahan.Id then
                inKebun = true
                if AmbilUmurDiKebun(id) < Age100MaxAge then
                    sisa = sisa + 1
                end
                break
            end
        end
        if not inKebun then
            for _, p in ipairs(NonFav) do
                if p.Id == petBahan.Id then
                    if p.Umur < Age100MaxAge then
                        sisa = sisa + 1
                    end
                    break
                end
            end
        end
    end
    return sisa
end

-- ==========================================
-- 2. SISTEM WEBHOOK DISCORD
-- ==========================================
local function FormatWaktu(detik)
    local h = math.floor(detik / 3600)
    local m = math.floor((detik % 3600) / 60)
    local s = math.floor(detik % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function GetPing()
    local ping = "N/A"
    pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    return ping .. " ms"
end

local function GetTeamNames(teamTable)
    local names = {}
    for _, pet in ipairs(teamTable) do table.insert(names, pet.Nama) end
    if #names == 0 then return "Kosong" end
    return table.concat(names, ", ")
end

local function KirimWebhook(teksFase, embedData)
    if WebhookURL == "" or string.find(WebhookURL, "MASUKKAN") then return end
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if req then
            req({
                Url = WebhookURL, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = game:GetService("HttpService"):JSONEncode({ ["content"] = "", ["embeds"] = { embedData } })
            })
        end
    end)
end

local function LogPesan(teksFase)
    print(teksFase)
    task.spawn(function()
        local dataEmbed = {
            ["title"] = teksFase,
            ["fields"] = {
                { ["name"] = "Information Pet", ["value"] = GetDetailBahan() .. "\n> ────────────────\n> **Cycle Count :** " .. CycleCount .. "\n> **Duration :** " .. FormatWaktu(tick() - WaktuStartBot) .. "\n> **Cycle Time:** " .. FormatWaktu(tick() - WaktuStartCycle), ["inline"] = false },
                { ["name"] = "Game Info", ["value"] = "> **Game Ping :** " .. GetPing() .. "\n> **Total Pets :** " .. (#FavPet + #NonFav) .. "\n> **Sisa Bahan :** " .. GetSisaBahan() .. " Pet", ["inline"] = false },
                { ["name"] = "Teams Inventory", ["value"] = "> **Team Elephant :** " .. GetTeamNames(PetTeamElephant) .. "\n> **Team Leveling :** " .. GetTeamNames(PetTeamLeveling) .. "\n> **Team Age100 :** " .. GetTeamNames(PetTeamAge100), ["inline"] = false }
            },
            ["footer"] = { ["text"] = "FSM Bot by Gery • " .. os.date("%d/%m/%y, %H:%M") }
        }
        KirimWebhook(teksFase, dataEmbed)
    end)
end

-- ==========================================
-- 3. PEMBUATAN CUSTOM UI
-- ==========================================
local Window = Speed_Library:CreateWindow({
    Title = "FSM Bot Auto-Farming",
    Description = "Ultimate Edition by Gery",
    TabWidth = 140,
    SizeUi = UDim2.fromOffset(580, 340)
})

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

local TabLeveling = Window:CreateTab({Name = "Auto Leveling", Icon = "rbxassetid://7734010488"})
local TabMisc     = Window:CreateTab({Name = "MISC",          Icon = "rbxassetid://7734010488"})
local TabSetting  = Window:CreateTab({Name = "Settings",      Icon = "rbxassetid://7734010488"})

-- SECTION 1: GAJAH
local SecGajah = TabLeveling:AddSection("Team Gajah Settings", false)
local DropGajah = SecGajah:AddDropdown({
    Title = "Pilih Team Gajah", Content = "Pilih 1 atau lebih", Multi = true, Options = {"Kosong"}, Default = {},
    Callback = function(Options) UpdateMultiSelectState(FavPet, Options, PetTeamElephant) end
})
SecGajah:AddInput({
    Title = "Min Age (Blessing)", Content = "Umur minimal gajah ditarik", Default = "50",
    Callback = function(Text) ElephantMinAge = tonumber(Text) or 50 end
})

-- SECTION 2: LEVELING
local SecLeveling = TabLeveling:AddSection("Team Leveling Settings", false)
local DropLeveling = SecLeveling:AddDropdown({
    Title = "Pilih Team Leveling", Content = "Pilih 1 atau lebih", Multi = true, Options = {"Kosong"}, Default = {},
    Callback = function(Options) UpdateMultiSelectState(FavPet, Options, PetTeamLeveling) end
})
SecLeveling:AddInput({
    Title = "Minimum Age", Content = "Batas bawah", Default = "0", Callback = function(Text) LevelingMinAge = tonumber(Text) or 0 end
})
SecLeveling:AddInput({
    Title = "Maximum Age", Content = "Batas atas", Default = "50", Callback = function(Text) LevelingMaxAge = tonumber(Text) or 50 end
})

-- SECTION 3: AGE 100
local SecAge100 = TabLeveling:AddSection("Team Age 100 Settings", false)
local DropAge100 = SecAge100:AddDropdown({
    Title = "Pilih Team Age 100", Content = "Pilih 1 atau lebih", Multi = true, Options = {"Kosong"}, Default = {},
    Callback = function(Options) UpdateMultiSelectState(FavPet, Options, PetTeamAge100) end
})
SecAge100:AddInput({
    Title = "Minimum Age", Content = "Bypass Gajah", Default = "55", Callback = function(Text) Age100MinAge = tonumber(Text) or 55 end
})
SecAge100:AddInput({
    Title = "Maximum Age", Content = "Target panen", Default = "100", Callback = function(Text) Age100MaxAge = tonumber(Text) or 100 end
})

-- SECTION 4: BAHAN
local ToggleMesin
local SecBahan = TabLeveling:AddSection("Konfigurasi Bahan", false)
local DropBahan = SecBahan:AddDropdown({
    Title = "Pilih Pet Bahan", Content = "Pilih dari Non-Fav", Multi = true, Options = {"Kosong"}, Default = {},
    Callback = function(Options) UpdateMultiSelectState(NonFav, Options, PetBahan) end
})
SecBahan:AddInput({
    Title = "Batch Size", Content = "Jumlah tanam per putaran", Default = "2", Callback = function(Text) BahanBatchSize = tonumber(Text) or 2 end
})
ToggleMesin = SecBahan:AddToggle({
    Title = "▶️ MULAI MESIN OTOMATIS", Content = "Pastikan semua setting benar", Default = false,
    Callback = function(Value)
        AutoElephantOn = Value
        if AutoElephantOn then
            FaseFarming = "TANAM" WaktuStartCycle = tick()
            Speed_Library:SetNotification({Title = "Sistem Menyala", Description = "Mesin Berjalan", Content = "Otomasi FSM telah diaktifkan!", Time = 3})
        else
            Speed_Library:SetNotification({Title = "Sistem Mati", Description = "Mesin Dimatikan", Content = "Menarik semua pet dari kebun...", Time = 3})
            task.spawn(TarikSemuaPetDiAwal) 
        end
    end
})

-- SECTION 5: TAB MISC (SADAP SERVER SKILL CANCEL)
local SecPickPlace = TabMisc:AddSection("Skill Cancel (Sadap Mode)", false)
local DropPickPlace 
SecPickPlace:AddButton({
    Title = "🔍 Scan Pet di Kebun", Content = "Tanam pet, lalu buka UI game & klik ini",
    Callback = function()
        ScanKebun()
        if DropPickPlace then DropPickPlace:Refresh(AmbilDaftarNama(PetKebun), DropPickPlace.Value) end
        Speed_Library:SetNotification({Title = "Scan Selesai", Description = "Berhasil", Content = "Daftar pet diperbarui!", Time = 2})
    end
})
DropPickPlace = SecPickPlace:AddDropdown({ Title = "Pilih Pet", Content = "Pilih dari hasil scan kebun", Multi = true, Options = {"Kosong"}, Default = {}, Callback = function(Options) UpdateMultiSelectState(PetKebun, Options, PickPlacePets) end })
SecPickPlace:AddInput({ Title = "Delay To Pick", Content = "Jeda narik (0.5)", Default = "0.5", Callback = function(Text) DelayToPick = tonumber(Text) or 0.5 end })
SecPickPlace:AddInput({ Title = "Delay To Place", Content = "Jeda nanam (0.5)", Default = "0.5", Callback = function(Text) DelayToPlace = tonumber(Text) or 0.5 end })
SecPickPlace:AddToggle({ Title = "▶️ MULAI SADAP SKILL", Content = "Bisa jalan bareng FSM atau mandiri!", Default = false, Callback = function(Value) AutoPickPlaceOn = Value end })

-- SECTION 6: SETTINGS & SECFITUR
local SecFitur = TabSetting:AddSection("Fitur Keamanan", false)
SecFitur:AddToggle({ 
    Title = "🛡️ Anti-AFK (Bypass 20 Menit)", 
    Content = "Mencegah kick otomatis saat ditinggal tidur", 
    Default = true, 
    Callback = function(Value) AntiAFKOn = Value end 
})

local SecSet = TabSetting:AddSection("Webhook & Update", false)
SecSet:AddInput({
    Title = "URL Webhook", Content = "Paste link Discord", Default = "",
    Callback = function(Text) WebhookURL = Text end
})
SecSet:AddButton({
    Title = "Test Webhook", Content = "Kirim pesan test",
    Callback = function()
        if WebhookURL == "" then
            Speed_Library:SetNotification({Title = "Gagal", Description = "Error", Content = "Link Webhook kosong!", Time = 3})
        else
            KirimWebhook("✅ **TEST BERHASIL!** Custom UI Gery sudah terhubung!", {["title"] = "Test", ["description"] = "Aman!"})
        end
    end
})

-- ==========================================
-- 4. SENSOR UI ANTI-LAG & CCTV
-- ==========================================
local function UpdateSemuaDropdown()
    if tick() - WaktuTerakhirGerak < 3 then return end 
    ScanTas()
    DropGajah:Refresh(AmbilDaftarNama(FavPet), DropGajah.Value) 
    DropLeveling:Refresh(AmbilDaftarNama(FavPet), DropLeveling.Value)
    DropAge100:Refresh(AmbilDaftarNama(FavPet), DropAge100.Value) 
    DropBahan:Refresh(AmbilDaftarNama(NonFav), DropBahan.Value)
end

local tas = LocalPlayer:WaitForChild("Backpack")
local function PantauBintangPet(item)
    if item:GetAttribute("ItemType") == "Pet" then
        item:GetAttributeChangedSignal("d"):Connect(function() task.wait(0.1) UpdateSemuaDropdown() end)
    end
end
for _, item in ipairs(tas:GetChildren()) do PantauBintangPet(item) end
tas.ChildAdded:Connect(function(item) if item:GetAttribute("ItemType") == "Pet" then PantauBintangPet(item) task.wait(0.1) UpdateSemuaDropdown() end end)
tas.ChildRemoved:Connect(function(item) if item:GetAttribute("ItemType") == "Pet" then UpdateSemuaDropdown() end end)

local function SetupCCTVNotif()
    local FrameFolder = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Top_Notification"):WaitForChild("Frame")
    local function CekNotifikasi(uiNode)
        if string.find(uiNode.Name, "Notification") then
            local function BacaAtribut()
                local textOG = uiNode:GetAttribute("OG")
                if textOG and textOG ~= "" then
                    local teksKecil = string.lower(textOG)
                    if string.find(teksKecil, "elephant trumpeted") and string.find(teksKecil, "weight cap") then
                        LogPesan("🚨 [Sistem] Alarm CCTV: Gajah mentok terdeteksi!") GajahMentokNotif = true 
                    end
                end
            end
            BacaAtribut() uiNode:GetAttributeChangedSignal("OG"):Connect(BacaAtribut)
        end
    end
    FrameFolder.ChildAdded:Connect(function(node) task.wait(0.1) CekNotifikasi(node) end)
end
task.spawn(SetupCCTVNotif)

-- ==========================================
-- 4.5 MESIN PARALEL: AUTO PICK & PLACE (SADAP SERVER)
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if AutoPickPlaceOn and #PickPlacePets > 0 then
            
            local function IsPetActiveInFSM(petId)
                if not AutoElephantOn then return true end 
                if FaseFarming == "LEVELING" or FaseFarming == "PUSH_LEVELING" then
                    for _, p in ipairs(PetTeamLeveling) do if p.Id == petId then return true end end
                elseif FaseFarming == "BLESSING" then
                    for _, p in ipairs(PetTeamElephant) do if p.Id == petId then return true end end
                elseif FaseFarming == "MENUJU_100" then
                    for _, p in ipairs(PetTeamAge100) do if p.Id == petId then return true end end
                end
                local isFSMTarget = false
                for _, p in ipairs(PetTeamLeveling) do if p.Id == petId then isFSMTarget = true end end
                for _, p in ipairs(PetTeamElephant) do if p.Id == petId then isFSMTarget = true end end
                for _, p in ipairs(PetTeamAge100) do if p.Id == petId then isFSMTarget = true end end
                if not isFSMTarget then return true end 
                return false
            end
            
            local petsReady = {}
            for _, pet in ipairs(PickPlacePets) do
                if not AutoPickPlaceOn then break end
                if IsPetSkillReady(pet.Id) and IsPetActiveInFSM(pet.Id) then table.insert(petsReady, pet.Id) end
            end
            
            if #petsReady > 0 then
                for _, uuid in ipairs(petsReady) do PetsService:FireServer("UnequipPet", uuid) end
                task.wait(DelayToPick) 
                
                local koordinat = GetMyFarmCenter()
                if koordinat then for _, uuid in ipairs(petsReady) do PetsService:FireServer("EquipPet", uuid, koordinat) end end
                task.wait(DelayToPlace) 
                
                for _, uuid in ipairs(petsReady) do CooldownDatabase[uuid] = nil end
                task.wait(0.5)
            end
        end
    end
end)

-- ==========================================
-- 5. MESIN FSM OTOMATISASI UTAMA
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do 
        if AutoElephantOn then
            if FaseFarming == "TANAM" then
                table.clear(BahanDiKebun) ScanTas() 
                local targetDitanam = {}
                for _, petBahan in ipairs(PetBahan) do 
                    local petSegar = nil
                    for _, p in ipairs(NonFav) do if p.Id == petBahan.Id then petSegar = p break end end
                    if petSegar and petSegar.Umur < Age100MaxAge then
                        table.insert(targetDitanam, petSegar)
                        if #targetDitanam >= BahanBatchSize then break end
                    end
                end
                
                local bahanDitanam = 0
                for _, pet in ipairs(targetDitanam) do PlacePet(pet.Id) table.insert(BahanDiKebun, pet.Id) bahanDitanam = bahanDitanam + 1 task.wait(0.5) end
                
                if bahanDitanam == 0 then
                    LogPesan("[Sistem] Selesai!") 
                    AutoElephantOn = false 
                    ToggleMesin:Set(false)
                    continue
                end
                
                for _, petTeam in ipairs(PetTeamLeveling) do PlacePet(petTeam.Id) task.wait(0.5) end
                FaseFarming = "LEVELING" LogPesan("[Fase] Masuk Fase LEVELING...")

            elseif FaseFarming == "LEVELING" then
                local semuaSiapBlessing = true
                for _, id in ipairs(BahanDiKebun) do if AmbilUmurDiKebun(id) < ElephantMinAge then semuaSiapBlessing = false break end end
                
                if semuaSiapBlessing then
                    LogPesan("[Fase] " .. InfoBahan() .. " -> Gajah") GajahMentokNotif = false
                    for _, petTeam in ipairs(PetTeamLeveling) do PickupPet(petTeam.Id) task.wait(0.4) end
                    for _, petTeam in ipairs(PetTeamElephant) do PlacePet(petTeam.Id) task.wait(0.4) end
                    FaseFarming = "BLESSING"
                end

            elseif FaseFarming == "BLESSING" then
                local semuaSuksesReset = true
                for _, id in ipairs(BahanDiKebun) do
                    local umurSekarang = AmbilUmurDiKebun(id)
                    if umurSekarang > 0 then if umurSekarang > (ElephantResetAge + 5) then semuaSuksesReset = false end else semuaSuksesReset = false end
                end

                if GajahMentokNotif then
                    GajahMentokNotif = false 
                    local butuhPush = false
                    for _, id in ipairs(BahanDiKebun) do if AmbilUmurDiKebun(id) < Age100MinAge then butuhPush = true break end end
                    
                    if butuhPush then
                        LogPesan("⚠️ [Fase] Push Leveling " .. InfoBahan())
                        for _, petTeam in ipairs(PetTeamElephant) do PickupPet(petTeam.Id) task.wait(0.4) end
                        for _, petTeam in ipairs(PetTeamLeveling) do PlacePet(petTeam.Id) task.wait(0.4) end
                        FaseFarming = "PUSH_LEVELING"
                    else
                        LogPesan("⏩ [Fase] Langsung Age 100 " .. InfoBahan())
                        for _, petTeam in ipairs(PetTeamElephant) do PickupPet(petTeam.Id) task.wait(0.4) end
                        for _, petTeam in ipairs(PetTeamAge100) do PlacePet(petTeam.Id) task.wait(0.4) end
                        FaseFarming = "MENUJU_100"
                    end

                elseif semuaSuksesReset then
                    LogPesan("✅ [Fase] Reset Sukses " .. InfoBahan())
                    for _, petTeam in ipairs(PetTeamElephant) do PickupPet(petTeam.Id) task.wait(0.4) end
                    for _, petTeam in ipairs(PetTeamLeveling) do PlacePet(petTeam.Id) task.wait(0.4) end
                    FaseFarming = "LEVELING" 
                end

            elseif FaseFarming == "PUSH_LEVELING" then
                local semuaSiapAge100 = true
                for _, id in ipairs(BahanDiKebun) do if AmbilUmurDiKebun(id) < Age100MinAge then semuaSiapAge100 = false break end end
                
                if semuaSiapAge100 then
                    LogPesan("[Fase] Push Selesai, masuk Age 100")
                    for _, petTeam in ipairs(PetTeamLeveling) do PickupPet(petTeam.Id) task.wait(0.4) end
                    for _, petTeam in ipairs(PetTeamAge100) do PlacePet(petTeam.Id) task.wait(0.4) end
                    FaseFarming = "MENUJU_100"
                end

            elseif FaseFarming == "MENUJU_100" then
                local semuaSudahMax = true
                for _, id in ipairs(BahanDiKebun) do if AmbilUmurDiKebun(id) < Age100MaxAge then semuaSudahMax = false break end end
                
                if semuaSudahMax then
                    LogPesan("🎉 [PANEN] " .. InfoBahan() .. " max!") CycleCount = CycleCount + 1 WaktuStartCycle = tick()
                    for _, id in ipairs(BahanDiKebun) do PickupPet(id) task.wait(0.4) end
                    for _, petTeam in ipairs(PetTeamAge100) do PickupPet(petTeam.Id) task.wait(0.4) end
                    FaseFarming = "TANAM" 
                end
            end
        end
    end
end)

-- ==========================================
-- 6. SISTEM ANTI-AFK (MENCEGAH KICK 20 MENIT)
-- ==========================================
LocalPlayer.Idled:Connect(function()
    if AntiAFKOn then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("🛡️ [Sistem] Anti-AFK Berjalan! Mereset timer idle Roblox...")
    end
end)

task.spawn(function()
    TarikSemuaPetDiAwal() ScanTas() 
    UpdateSemuaDropdown()
    Speed_Library:SetNotification({Title = "Berhasil", Description = "Injected", Content = "FSM Bot Ultimate Edition siap digunakan!", Time = 5})
end)
