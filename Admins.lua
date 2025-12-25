local AdminList = { 
    8908656348, -- pond
    290863568,  -- dew
    -- ⚠️ อย่าลืมใส่ ID ตัวเองตรงนี้ถ้าจะทดสอบ! เช่น:
    -- 1234567890, 
}

--////////////////////////////////////////////////////////////
-- [SYSTEM] ตัวแปรระบบ
--////////////////////////////////////////////////////////////
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local BanFileName = "3354_ServerBlacklist.json" 

-- 1. ฟังก์ชันเช็คแบน (ทำงานทันทีที่รันสคริปต์)
-- ถ้าเซิร์ฟนี้ติด Blacklist ให้เตะตัวเองออกทันที
if isfile and isfile(BanFileName) then
    local success, bannedList = pcall(function() 
        return HttpService:JSONDecode(readfile(BanFileName)) 
    end)
    
    if success and bannedList then
        for _, bannedJobId in pairs(bannedList) do
            if bannedJobId == game.JobId then
                LocalPlayer:Kick("🚫 This server is Blacklisted by Admin.")
                return -- จบการทำงาน
            end
        end
    end
end

-- 2. ฟังก์ชันเพิ่มการแบน (Server Ban)
local function addServerBan()
    local bannedList = {}
    -- อ่านไฟล์เดิม
    if isfile and isfile(BanFileName) then
        pcall(function() 
            bannedList = HttpService:JSONDecode(readfile(BanFileName)) 
        end)
    end
    
    -- เช็คซ้ำกัน
    local found = false
    for _, id in pairs(bannedList) do
        if id == game.JobId then found = true break end
    end
    
    -- บันทึก
    if not found then
        table.insert(bannedList, game.JobId)
        if writefile then 
            writefile(BanFileName, HttpService:JSONEncode(bannedList)) 
            print("Server Banned Saved!")
        end
    end
end

-- 3. ระบบดักฟังแชท (Core Logic)
task.spawn(function()
    print("Admin System: Loaded") -- เช็คใน F9 ว่าขึ้นไหม

    -- เช็คว่าเป็นแอดมินไหม
    local function isAdmin(userId)
        for _, id in ipairs(AdminList) do
            if userId == id then return true end
        end
        return false
    end

    -- เช็คเป้าหมาย
    local function isTarget(targetName)
        if not targetName then return false end
        local myName = LocalPlayer.Name:lower()
        local myDisplay = LocalPlayer.DisplayName:lower()
        targetName = targetName:lower()

        if targetName == "$" or targetName == "all" then return true end -- เพิ่ม 'all'
        if string.find(myName, targetName) or string.find(myDisplay, targetName) then 
            return true 
        end
        return false
    end

    -- ฟังก์ชันทำงานเมื่อมีคนพิมพ์
    local function onChatted(msg, speaker)
        -- ต้องเป็น Admin เท่านั้นถึงจะสั่งได้
        if isAdmin(speaker.UserId) then
            local args = string.split(msg, " ")
            local cmd = args[1]:lower()
            local target = args[2]

            if not target then return end
            
            -- เช็คว่าตัวเราคือเป้าหมายหรือไม่ (isTarget)
            if isTarget(target) then
                if cmd == ".kick" then
                    LocalPlayer:Kick("You have been kicked by Admin: " .. speaker.Name)
                
                elseif cmd == ".ban" then
                    addServerBan() -- แบนเซิร์ฟ
                    task.wait(0.2)
                    LocalPlayer:Kick("You have been BANNED from this server by Admin: " .. speaker.Name)
                
                elseif cmd == ".bring" then
                    local adminChar = speaker.Character
                    local myChar = LocalPlayer.Character
                    if adminChar and adminChar:FindFirstChild("HumanoidRootPart") and myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        myChar.HumanoidRootPart.CFrame = adminChar.HumanoidRootPart.CFrame
                    end
                end
            end
        end
    end

    -- เริ่มดักฟังทุกคนในเซิร์ฟ
    for _, plr in ipairs(Players:GetPlayers()) do
        plr.Chatted:Connect(function(msg) onChatted(msg, plr) end)
    end
    Players.PlayerAdded:Connect(function(plr)
        plr.Chatted:Connect(function(msg) onChatted(msg, plr) end)
    end)
end)
