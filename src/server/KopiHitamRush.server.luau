-- Kopi Hitam Rush — game script (ServerScriptService).
-- Obby sprint ke warung kopi: kumpulin Biji Kopi, hindari genangan kopi
-- tumpah + lantai lava, sampai ke WinPad di ujung. Checkpoint emas jadi
-- tempat respawn, timer jalan sampai finis, juara pertama diumumkan ke
-- semua pemain (mabar). 100% gratis, tanpa Game Pass.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Preload semua suara biar langsung bunyi saat pertama dipakai.
task.spawn(function()
	local sounds = {}
	for _, s in ipairs(SoundService:GetChildren()) do
		if s:IsA("Sound") then
			table.insert(sounds, s)
		end
	end
	pcall(function()
		game:GetService("ContentProvider"):PreloadAsync(sounds)
	end)
end)

local function playSound(name)
	local s = SoundService:FindFirstChild(name)
	if s then
		s:Play()
	end
end

-- Cari pemain dari bagian tubuh yang menyentuh. Aksesori (topi, dll.)
-- parent-nya bukan karakter langsung, jadi cek satu tingkat di atasnya.
local function playerFromHit(hit)
	local model = hit.Parent
	if not model then
		return nil
	end
	local player = Players:GetPlayerFromCharacter(model)
	if player then
		return player
	end
	if model.Parent then
		return Players:GetPlayerFromCharacter(model.Parent)
	end
	return nil
end

local KILL_DEBOUNCE = 1 -- detik, biar tidak mati beruntun
local sudahAdaJuara1 = false

local function setupPlayer(player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local kopi = Instance.new("IntValue")
	kopi.Name = "Biji Kopi"
	kopi.Value = 0
	kopi.Parent = leaderstats
	local waktu = Instance.new("IntValue")
	waktu.Name = "Waktu"
	waktu.Value = 0
	waktu.Parent = leaderstats
	local state = Instance.new("Folder")
	state.Name = "KopiRushState"
	state.Parent = player
	local cp = Instance.new("IntValue")
	cp.Name = "Checkpoint"
	cp.Value = 0
	cp.Parent = state
	local startTime = Instance.new("NumberValue")
	startTime.Name = "StartTime"
	startTime.Value = os.clock()
	startTime.Parent = state
	local lastKill = Instance.new("NumberValue")
	lastKill.Name = "LastKill"
	lastKill.Value = 0
	lastKill.Parent = state
	local finished = Instance.new("BoolValue")
	finished.Name = "Finished"
	finished.Value = false
	finished.Parent = state
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local state = player:FindFirstChild("KopiRushState")
	if not state then
		return
	end
	local cp = state:FindFirstChild("Checkpoint")
	local startTime = state:FindFirstChild("StartTime")
	local finished = state:FindFirstChild("Finished")
	if startTime then
		startTime.Value = os.clock()
	end
	if finished then
		finished.Value = false
	end
	-- Respawn di checkpoint terakhir (bukan balik ke awal).
	if cp and cp.Value > 0 then
		local pad = workspace:FindFirstChild("Checkpoint" .. cp.Value, true)
		if pad then
			root.CFrame = pad.CFrame + Vector3.new(0, 4, 0)
		end
	end
	-- Timer: hitung detik sejak start, berhenti pas finis.
	task.spawn(function()
		while humanoid.Health > 0 do
			task.wait(1)
			if finished and finished.Value then
				break
			end
			local leaderstats = player:FindFirstChild("leaderstats")
			local waktu = leaderstats and leaderstats:FindFirstChild("Waktu")
			if waktu and startTime then
				waktu.Value = math.floor(os.clock() - startTime.Value)
			end
		end
	end)
	-- Bunyi lompat ("fahhh").
	humanoid.Jumping:Connect(function()
		playSound("SuaraLompat")
	end)
end

local function hookPlayer(player)
	setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

Players.PlayerAdded:Connect(hookPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	hookPlayer(player)
end

-- Checkpoint: bunyi "Hidup Jokowi" TIAP sentuhan (debounce 2 detik per
-- checkpoint), simpan checkpoint tertinggi sebagai respawn.
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Name:match("^Checkpoint%d+$") then
		local num = tonumber(obj.Name:match("%d+"))
		local lastBunyi = 0
		obj.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if not player then
				return
			end
			local state = player:FindFirstChild("KopiRushState")
			if not state then
				return
			end
			if os.clock() - lastBunyi > 2 then
				lastBunyi = os.clock()
				playSound("SuaraCheckpoint")
			end
			local cp = state:FindFirstChild("Checkpoint")
			if cp and num > cp.Value then
				cp.Value = num
			end
		end)
	end
end

-- Koin: +1 Biji Kopi, hilang lalu muncul lagi 10 detik kemudian di parent aslinya.
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Name:match("^Coin%d*$") then
		local taken = false
		obj.Touched:Connect(function(hit)
			if taken then
				return
			end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			local leaderstats = player:FindFirstChild("leaderstats")
			local kopi = leaderstats and leaderstats:FindFirstChild("Biji Kopi")
			if not kopi then
				return
			end
			taken = true
			local parent = obj.Parent
			local pos = obj.CFrame
			kopi.Value = kopi.Value + 1
			obj.Parent = nil
			task.wait(10)
			obj.CFrame = pos
			obj.Parent = parent
			taken = false
		end)
	end
end

-- KillPart (lava + genangan + kipas): mati, respawn di checkpoint terakhir.
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Name:match("^KillPart%d*$") then
		obj.Touched:Connect(function(hit)
			local humanoid = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			local state = player:FindFirstChild("KopiRushState")
			local lastKill = state and state:FindFirstChild("LastKill")
			if lastKill and os.clock() - lastKill.Value < KILL_DEBOUNCE then
				return
			end
			if lastKill then
				lastKill.Value = os.clock()
			end
			playSound("SuaraMati")
			humanoid.Health = 0
		end)
	end
end

-- WinPad: stop timer, hitung ulang Waktu, umumkan juara ke semua pemain.
local winPad = workspace:FindFirstChild("WinPad", true)
if winPad then
	winPad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local state = player:FindFirstChild("KopiRushState")
		if not state then
			return
		end
		local finished = state:FindFirstChild("Finished")
		if finished and finished.Value then
			return
		end
		if finished then
			finished.Value = true
		end
		local startTime = state:FindFirstChild("StartTime")
		local leaderstats = player:FindFirstChild("leaderstats")
		local kopi = leaderstats and leaderstats:FindFirstChild("Biji Kopi")
		local waktu = leaderstats and leaderstats:FindFirstChild("Waktu")
		local finalTime = 0
		if startTime and waktu then
			finalTime = math.floor(os.clock() - startTime.Value)
			waktu.Value = finalTime
		end
		playSound("SuaraMenang")
		local jadiJuara1 = not sudahAdaJuara1
		sudahAdaJuara1 = true
		local event = ReplicatedStorage:FindFirstChild("UmumkanMenang")
		if event then
			event:FireAllClients(player.Name, finalTime, kopi and kopi.Value or 0, jadiJuara1)
		end
	end)
end
