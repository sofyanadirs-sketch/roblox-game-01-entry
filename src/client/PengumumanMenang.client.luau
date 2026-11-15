-- Kopi Hitam Rush — pengumuman menang (StarterPlayerScripts, LocalScript).
-- Tampilkan spanduk saat ada pemain yang sampai ke warung kopi.
-- Juara pertama (yang paling cepat sampai) dapat label "[JUARA 1!]".
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local gui = Instance.new("ScreenGui")
gui.Name = "PengumumanMenangGui"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.8, 0, 0, 80)
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0.1, 0)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BackgroundTransparency = 0.2
label.TextColor3 = Color3.fromRGB(255, 210, 60)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Text = ""
label.Visible = false
label.Parent = gui

-- Token: pengumuman baru tidak boleh ditutup oleh timer pengumuman lama.
local token = 0
local event = ReplicatedStorage:WaitForChild("UmumkanMenang")
event.OnClientEvent:Connect(function(nama, waktu, kopi, juara1)
	token = token + 1
	local myToken = token
	local teks = "🏆 "
	if juara1 then
		teks = teks .. "[JUARA 1!] "
	end
	teks = teks .. nama .. " SAMPAI WARUNG! " .. tostring(waktu) .. " detik • " .. tostring(kopi) .. " biji kopi"
	label.Text = teks
	label.Visible = true
	task.wait(7)
	if token == myToken then
		label.Visible = false
	end
end)
