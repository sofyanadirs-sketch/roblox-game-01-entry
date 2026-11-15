-- PengumumanMenang.client.lua
-- LocalScript di StarterPlayerScripts. Menampilkan pengumuman ke SEMUA pemain
-- saat ada yang finis (mabar): siapa juara 1 / finis, waktunya, dan biji kopinya.
-- GUI dibuat di sini (tidak perlu instance GUI di project).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local umumkan = ReplicatedStorage:WaitForChild("UmumkanMenang")

local gui = Instance.new("ScreenGui")
gui.Name = "PengumumanMenang"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.8, 0, 0, 80)
label.Position = UDim2.new(0.1, 0, 0.05, 0)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(255, 220, 60)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = ""
label.Visible = false
label.Parent = gui

local token = 0
umumkan.OnClientEvent:Connect(function(nama, waktu, kopi, juara1)
	token = token + 1
	local t = token
	local gelar = juara1 and "JUARA 1! " or ""
	label.Text = "🏆 " .. gelar .. nama .. " SAMPAI WARUNG! " .. waktu .. " detik • " .. kopi .. " biji kopi"
	label.Visible = true
	task.wait(7)
	if t == token then
		label.Visible = false
	end
end)
