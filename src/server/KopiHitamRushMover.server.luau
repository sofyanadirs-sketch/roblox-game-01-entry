-- Kopi Hitam Rush — mover script (ServerScriptService).
-- Platform bergerak (tween X bolak-balik selamanya) + kipas pembunuh
-- berputar (bilah KillPart diputar di tempat). Semua mover ada di jalur
-- lurus searah Z, jadi tween X tegak lurus arah jalan: jarak lompatan
-- tidak berubah, pemain tidak jatuh gara-gara platform bergeser.
local TweenService = game:GetService("TweenService")

local function gerakkan(nama, jarak, durasi)
	local part = workspace:FindFirstChild(nama, true)
	if not part then
		return
	end
	local awal = part.CFrame
	local info = TweenInfo.new(durasi, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
	local tujuan = { CFrame = awal * CFrame.new(jarak, 0, 0) }
	TweenService:Create(part, info, tujuan):Play()
end

local function putar(nama, derajat)
	local part = workspace:FindFirstChild(nama, true)
	if not part then
		return
	end
	task.spawn(function()
		while part.Parent do
			part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(derajat), 0)
			task.wait(0.03)
		end
	end)
end

-- Platform bergerak: awal 2 stud (gampang), final 3 stud (sulit).
gerakkan("Platform25", 2, 3)
gerakkan("Platform27", 2, 2.5)
gerakkan("Platform44", 2, 3.5)
gerakkan("Platform61", 2, 2.8)
gerakkan("Platform79", 3, 3)
gerakkan("Platform97", 3, 2.5)

-- Kipas pembunuh: awal bilah 6 pelan (2 derajat/langkah),
-- final bilah 8 ngebut (3 derajat/langkah).
putar("KillPart30", 2)
putar("KillPart31", 2)
putar("KillPart32", 2)
putar("KillPart33", 3)
putar("KillPart34", 3)
