-- KopiHitamRush.server.lua
-- Taruh sebagai SATU Script di ServerScriptService. Tidak perlu script lain.
-- Butuh di dunia (nama HARUS persis): Checkpoint1, Checkpoint2, ... (Part),
-- Coin (Part, boleh banyak), KillPart (Part, boleh banyak), WinPad (Part),
-- dan SpawnLocation (sudah ada di Baseplate).
-- Leaderstats: "Biji Kopi" dan "Waktu" (detik, berhenti saat menang).

local Players = game:GetService("Players")

-- Preload semua suara biar langsung bunyi saat pertama dipakai.
task.spawn(function()
	local sounds = {}
	for _, s in ipairs(game:GetService("SoundService"):GetChildren()) do
		if s:IsA("Sound") then
			table.insert(sounds, s)
		end
	end
	pcall(function()
		game:GetService("ContentProvider"):PreloadAsync(sounds)
	end)
end)

local COIN_RESPAWN_DELAY = 10
local KILL_DEBOUNCE = 1
local firstWinner = nil -- nama pemain pertama yang finis (buat pengumuman mabar).

local function setupPlayer(player)
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

	local checkpoint = Instance.new("IntValue")
	checkpoint.Name = "Checkpoint"
	checkpoint.Value = 0
	checkpoint.Parent = state

	local startTime = Instance.new("NumberValue")
	startTime.Name = "StartTime"
	startTime.Value = 0
	startTime.Parent = state

	local finished = Instance.new("BoolValue")
	finished.Name = "Finished"
	finished.Value = false
	finished.Parent = state

	local lastKill = Instance.new("NumberValue")
	lastKill.Name = "LastKill"
	lastKill.Value = 0
	lastKill.Parent = state

	local function onCharacterAdded(character)
		task.wait(0.2)
		local root = character:WaitForChild("HumanoidRootPart", 5)
		if not root then return end
		-- Bunyi lompat ("Fahhh") tiap karakter lompat — bunyi buat semua pemain.
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Jumping:Connect(function()
				local suara = game:GetService("SoundService"):FindFirstChild("SuaraLompat")
				if suara then
					suara:Play()
				end
			end)
		end
		-- Respawn di checkpoint terakhir, bukan di awal.
		local cp = checkpoint.Value
		if cp > 0 then
			local pad = workspace:FindFirstChild("Checkpoint" .. cp, true)
			if pad then
				root.CFrame = pad.CFrame + Vector3.new(0, 4, 0)
			end
		end
		if startTime.Value == 0 then
			startTime.Value = os.clock()
		end
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end

	-- Timer jalan sampai finis.
	task.spawn(function()
		while player.Parent do
			task.wait(1)
			if startTime.Value > 0 and not finished.Value then
				waktu.Value = math.floor(os.clock() - startTime.Value)
			end
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	setupPlayer(p)
end

-- Checkpoint: sentuh = simpan, ada pesan kecil.
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Name:match("^Checkpoint%d+$") then
		local num = tonumber(obj.Name:match("%d+"))
		local lastBunyi = 0 -- debounce bunyi per checkpoint (biar tidak spam).
		obj.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then return end
			local state = player:FindFirstChild("KopiRushState")
			if not state then return end
			local cp = state:FindFirstChild("Checkpoint")
			-- Bunyi checkpoint ("Hidup Jokowi") TIAP kali disentuh, bukan cuma
			-- saat checkpoint baru — bunyi buat semua pemain (mabar).
			if os.clock() - lastBunyi > 2 then
				lastBunyi = os.clock()
				local suaraCp = game:GetService("SoundService"):FindFirstChild("SuaraCheckpoint")
				if suaraCp then
					suaraCp:Play()
				end
			end
			if cp and num > cp.Value then
				cp.Value = num
			end
		end)
	end
end

-- Koin biji kopi: ambil = +1, hilang 10 detik lalu muncul lagi.
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Name:match("^Coin%d*$") then
		obj.Touched:Connect(function(hit)
			if not obj.Parent then return end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then return end
			local leaderstats = player:FindFirstChild("leaderstats")
			if not leaderstats then return end
			local kopi = leaderstats:FindFirstChild("Biji Kopi")
			if not kopi then return end
			kopi.Value = kopi.Value + 1
			local coin = obj
			local home = coin.Parent
			coin.Parent = nil
			task.wait(COIN_RESPAWN_DELAY)
			coin.Parent = home
		end)
	end
end

-- Kopi tumpah: kena = balik ke checkpoint terakhir.
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Name:match("^KillPart%d*$") then
		obj.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then return end
			local state = player:FindFirstChild("KopiRushState")
			if not state then return end
			local lastKill = state:FindFirstChild("LastKill")
			if not lastKill or os.clock() - lastKill.Value < KILL_DEBOUNCE then return end
			lastKill.Value = os.clock()
			local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Bunyi mati (kentut "Slip Fart") — bunyi buat semua pemain (mabar).
				local suaraMati = game:GetService("SoundService"):FindFirstChild("SuaraMati")
				if suaraMati then
					suaraMati:Play()
				end
				humanoid.Health = 0
			end
		end)
	end
end

-- WinPad: finis, waktu berhenti.
local winPad = workspace:FindFirstChild("WinPad", true)
if winPad then
	winPad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end
		local state = player:FindFirstChild("KopiRushState")
		local leaderstats = player:FindFirstChild("leaderstats")
		if not state or not leaderstats then return end
		local finished = state:FindFirstChild("Finished")
		if not finished or finished.Value then return end
		local startTime = state:FindFirstChild("StartTime")
		if startTime and startTime.Value > 0 then
			local waktuNow = leaderstats:FindFirstChild("Waktu")
			if waktuNow then
				waktuNow.Value = math.floor(os.clock() - startTime.Value)
			end
		end
		finished.Value = true
		-- Umumkan ke semua pemain (mabar): siapa finis + waktunya + biji kopinya.
		local rs = game:GetService("ReplicatedStorage")
		local umumkan = rs:FindFirstChild("UmumkanMenang")
		if umumkan then
			local juara1 = false
			if not firstWinner then
				firstWinner = player.Name
				juara1 = true
			end
			local w = leaderstats:FindFirstChild("Waktu")
			local k = leaderstats:FindFirstChild("Biji Kopi")
			umumkan:FireAllClients(player.Name, w and w.Value or 0, k and k.Value or 0, juara1)
		end
		-- Bunyi finis ("Kids Yay") — bunyi buat semua pemain (mabar).
		local suaraMenang = game:GetService("SoundService"):FindFirstChild("SuaraMenang")
		if suaraMenang then
			suaraMenang:Play()
		end
		local waktu = leaderstats:FindFirstChild("Waktu")
		local kopi = leaderstats:FindFirstChild("Biji Kopi")
		if waktu and kopi then
			-- Skor akhir tercatat di leaderstats (Waktu + Biji Kopi).
			-- Pesan menang: pakai BillboardGui di WinPad kalau mau, ini cukup.
			print(player.Name .. " SAMPAI WARUNG! Waktu: " .. waktu.Value
				.. " detik, Biji Kopi: " .. kopi.Value)
		end
	end)
end
