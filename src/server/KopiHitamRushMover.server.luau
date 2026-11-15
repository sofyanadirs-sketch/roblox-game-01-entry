-- KopiHitamRushMover.server.lua
-- 1) Menggerakkan platform tertentu bolak-balik (kiri-kanan) pakai TweenService.
--    Platform yang bergerak: Platform25, Platform27, Platform44, Platform61
--    (awal, geser 2 stud) + Platform79, Platform97 (final, geser 3 stud).
--    (Anchored, di-tween CFrame-nya). Semuanya di LEG LURUS (bergerak tegak lurus
--    arah lompat, jadi jarak lompat tidak berubah). Durasi beda-beda biar tidak sinkron.
--    Pemain yang berdiri di atasnya ikut terbawa (perilaku standar Roblox).
-- 2) Memutar bilah kipas pembunuh (KillPart30, KillPart31, KillPart32 di awal,
--    pelan; KillPart33, KillPart34 di final, ngebut) di atas Platform5, Platform46,
--    Platform62, Platform82 dan Platform90. Bilah berputar mengelilingi tiang di
--    tengah platform; kena bilah = mati (ditangani script game utama lewat pola
--    nama ^KillPart%d*$).
-- Kalau di Play ternyata goyang/jitter, hapus Script ini dan platform jadi diam
-- (kipas juga berhenti).

local TweenService = game:GetService("TweenService")

local folder = workspace:WaitForChild("KopiHitamRush")

local function gerakkan(nama, jarak, durasi)
	local part = folder:WaitForChild(nama)
	local awal = part.CFrame
	local tujuan = awal * CFrame.new(jarak, 0, 0)
	local info = TweenInfo.new(durasi, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(part, info, {CFrame = tujuan})
	tween:Play()
end

gerakkan("Platform25", 2, 3)
gerakkan("Platform27", 2, 2.5)
gerakkan("Platform44", 2, 3.5)
gerakkan("Platform61", 2, 2.8)
gerakkan("Platform79", 3, 3)
gerakkan("Platform97", 3, 2.5)

local function putar(nama, derajatPerLangkah)
	local part = folder:WaitForChild(nama)
	while true do
		part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(derajatPerLangkah), 0)
		task.wait(0.03)
	end
end

task.spawn(putar, "KillPart30", 2)
task.spawn(putar, "KillPart31", 2)
task.spawn(putar, "KillPart32", 2)
task.spawn(putar, "KillPart33", 3)
task.spawn(putar, "KillPart34", 3)
