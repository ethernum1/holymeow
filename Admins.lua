local AdminList = { 
    8908656348, 
    290863568,
    -- ⚠️ อย่าลืมเอาเลข ID ของคุณมาใส่ตรงนี้ด้วย!!
    -- ตัวอย่าง: 12345678, 
}

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Http = game:GetService("HttpService")
local BanFile = "3354_ServerBlacklist.json" 

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
        if writefile then writefile(BanFileName, HttpService:JSONEncode(l)) end
    end
end

task.spawn(function()
    print("💎 Admin Script Loaded! Waiting for commands...") -- เช็ค F9 ว่าขึ้นคำนี้ไหม

    local function isAdmin(userId)
        for _, id in ipairs(AdminList) do if userId == id then return true end end
        return false
    end

    local function onChat(msg, speaker)
        if isAdmin(speaker.UserId) then
            local args = string.split(msg, " ")
            local cmd, target = args[1]:lower(), args[2]
            if not target then return end
            
            local function isMyName(t)
                if t == "$" or t == "all" then return true end
                return string.find(LP.Name:lower(), t:lower()) or string.find(LP.DisplayName:lower(), t:lower())
            end

            if isMyName(target) then
                print("🎯 Command Received: " .. cmd .. " from " .. speaker.Name) -- เช็ค F9 ว่าคำสั่งเข้าไหม

                -- [⚠️ ปิดบรรทัดนี้ชั่วคราว เพื่อเทสกับตัวเอง]
                -- if isAdmin(LP.UserId) and speaker ~= LP then return end 

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
