local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    Enabled = true, 
    FOV = 100, -- Ajustado exactamente a 100 como pediste
}

-- Sincronización con el color verde de tu menú
local COLOR_VERDE_MENU = Color3.fromRGB(15, 115, 45)
local COLOR_NEGRO_OFF = Color3.fromRGB(25, 25, 25)
local COLOR_TEXTO = Color3.fromRGB(255, 255, 255)

local CurrentTargetNPC = nil
local CurrentTargetPart = nil

-- 1. INTERFAZ GRÁFICA (BOTÓN VERDE SUPERIOR IZQUIERDO)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotNPC_UI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local StatusButton = Instance.new("TextButton")
StatusButton.Name = "IndicatorBtn"
StatusButton.Parent = ScreenGui
StatusButton.BackgroundColor3 = COLOR_VERDE_MENU
StatusButton.Position = UDim2.new(0.04, 0, 0.05, 0) 
StatusButton.Size = UDim2.new(0, 110, 0, 28)
StatusButton.Font = Enum.Font.SourceSansBold
StatusButton.Text = "AIMBOT: ON"
StatusButton.TextColor3 = COLOR_TEXTO
StatusButton.TextSize = 13
StatusButton.AutoButtonColor = false

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1
UIStroke.Color = Color3.fromRGB(40, 40, 40)
UIStroke.Parent = StatusButton

-- 2. CÍRCULO DEL FOV TOTALMENTE VERDE Y ELEVADO (TAMAÑO 100)
local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "Aimbot_FOV"
FOVFrame.Parent = ScreenGui
FOVFrame.BackgroundTransparency = 1
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.38, 0) -- Elevado por encima de tu personaje
FOVFrame.Size = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2)
FOVFrame.Visible = true

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVFrame

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = COLOR_VERDE_MENU
FOVStroke.Transparency = 0.25
FOVStroke.Parent = FOVFrame

-- Verificación de línea de visión sin obstrucciones
local function isHeadVisible(headPart)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character, Camera}
    
    local origin = Camera.CFrame.Position
    local direction = headPart.Position - origin
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    
    if not raycastResult or raycastResult.Instance:IsDescendantOf(headPart.Parent) then
        return true
    end
    
    return false
end

-- Buscador de objetivos adaptado al rango de 100
local function updateClosestNPCTarget()
    local fovPosition = Vector2.new(Camera.ViewportSize.X * FOVFrame.Position.X.Scale, Camera.ViewportSize.Y * FOVFrame.Position.Y.Scale)

    -- Fijación imán: Mientras siga vivo y dentro del FOV, la cámara no se despega por nada
    if CurrentTargetNPC and CurrentTargetNPC:FindFirstChild("Humanoid") and CurrentTargetNPC.Humanoid.Health > 0 and CurrentTargetPart and isHeadVisible(CurrentTargetPart) then
        local pos, onScreen = Camera:WorldToViewportPoint(CurrentTargetPart.Position)
        if onScreen then
            local distance = (Vector2.new(pos.X, pos.Y) - fovPosition).Magnitude
            if distance < Settings.FOV then
                return 
            end
        end
    end

    local closestNPC = nil
    local closestPart = nil
    local shortestDistance = Settings.FOV

    for _, humanoid in pairs(workspace:GetDescendants()) do
        if humanoid:IsA("Humanoid") and humanoid.Health > 0 then
            local obj = humanoid.Parent
            if obj and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                -- Apuntado directo a la cabeza
                local head = obj:FindFirstChild("Head")
                if head and head:IsA("BasePart") and isHeadVisible(head) then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local distance = (Vector2.new(pos.X, pos.Y) - fovPosition).Magnitude
                        if distance < shortestDistance then
                            closestNPC = obj
                            closestPart = head
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end

    CurrentTargetNPC = closestNPC
    CurrentTargetPart = closestPart
end

-- Activar / Desactivar con el botón
StatusButton.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        StatusButton.Text = "AIMBOT: ON"
        StatusButton.BackgroundColor3 = COLOR_VERDE_MENU
        FOVFrame.Visible = true
    else
        StatusButton.Text = "AIMBOT: OFF"
        StatusButton.BackgroundColor3 = COLOR_NEGRO_OFF
        FOVFrame.Visible = false
        CurrentTargetNPC = nil
        CurrentTargetPart = nil
    end
end)

-- Ajustar tamaño del círculo si se rota o escala la resolución
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    FOVFrame.Size = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2)
end)

-- Bucle de renderizado para fijación angular inmediata (Máximo pegado)
RunService.RenderStepped:Connect(function()
    if Settings.Enabled then
        updateClosestNPCTarget()
        if CurrentTargetPart then
            -- Fijación 100% directa y rígida hacia la cabeza
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, CurrentTargetPart.Position)
        end
    end
end)
