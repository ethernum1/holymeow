local AdminList = { 
    8908656348, --pond
    290863568,   --dew    
}

--////////////////////////////////////////////////////////////
-- [SYSTEM] ตัวแปรระบบ
--////////////////////////////////////////////////////////////
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local BanFileName = "3354_ServerBlacklist.json" -- ชื่อไฟล์สำหรับเก็บประวัติการแบน

-- ฟังก์ชันสำหรับเพิ่มการแบนลงไฟล์ (Server Ban)
local function addServerBan()
    local bannedList = {}
    -- 1. อ่านไฟล์เดิมถ้ามี
    if isfile and isfile(BanFileName) then
        pcall(function() 
            bannedList = HttpService:JSONDecode(readfile(BanFileName)) 
        end)
    end
    
    -- 2. เช็คว่า JobID นี้มีอยู่แล้วหรือยัง
    local currentJob = game.JobId
    local found = false
    for _, id in pairs(bannedList) do
        if id == currentJob then found = true break end
    end
    
    -- 3. ถ้ายังไม่มี ให้บันทึกเพิ่ม
    if not found then
        table.insert(bannedList, currentJob)
        if writefile then 
            writefile(BanFileName, HttpService:JSONEncode(bannedList)) 
        end
    end
end

-- ระบบดักฟังแชท (Core Logic)
task.spawn(function()
    -- เช็คว่าเป็นแอดมินไหม
    local function isAdmin(userId)
        for _, id in ipairs(AdminList) do
            if userId == id then return true end
        end
        return false
    end

    -- เช็คว่าชื่อตรงกับเป้าหมายไหม (รองรับ $ คือทุกคน)
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

    -- ฟังก์ชันทำงานเมื่อมีคนพิมพ์
    local function onChatted(msg, speaker)
        -- ต้องเป็น Admin เท่านั้นถึงจะสั่งได้
        if isAdmin(speaker.UserId) then
            local args = string.split(msg, " ")
            local cmd = args[1]:lower() -- คำสั่ง (เช่น .kick)
            local target = args[2]      -- เป้าหมาย (ชื่อคน หรือ $)

            if not target then return end
            
            -- ข้อความแจ้งเตือนตอนโดนเตะ
            local kickReason = "You have been kicked by " .. speaker.Name

            -- [1] คำสั่ง .kick (เตะเฉยๆ)
            if cmd == ".kick" and isTarget(target) then
                LocalPlayer:Kick(kickReason)

            -- [2] คำสั่ง .ban (เตะ + แบนเซิร์ฟ)
            elseif cmd == ".ban" and isTarget(target) then
                addServerBan() -- บันทึกห้องนี้ลง Blacklist
                task.wait(0.1)
                LocalPlayer:Kick(kickReason)

            -- [3] คำสั่ง .bring (ดึงตัวมาหา)
            elseif cmd == ".bring" and isTarget(target) then
                local adminChar = speaker.Character
                local myChar = LocalPlayer.Character
                
                -- เช็คว่าตัวละครโหลดครบไหมทั้งคู่
                if adminChar and adminChar:FindFirstChild("HumanoidRootPart") and 
                   myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    -- ย้ายตำแหน่งเหยื่อ ไปหาตำแหน่งแอดมิน
                    myChar.HumanoidRootPart.CFrame = adminChar.HumanoidRootPart.CFrame
                end
            end
        end
    end

    -- เริ่มดักฟังผู้เล่นทุกคนในเซิร์ฟ
    for _, plr in ipairs(Players:GetPlayers()) do
        plr.Chatted:Connect(function(msg) onChatted(msg, plr) end)
    end
    -- ดักฟังคนที่เพิ่งเข้าใหม่ด้วย
    Players.PlayerAdded:Connect(function(plr)
        plr.Chatted:Connect(function(msg) onChatted(msg, plr) end)
    end)

end)
