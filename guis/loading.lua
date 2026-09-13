local Players=game:GetService('Players')
local TweenService=game:GetService('TweenService')
local Lighting=game:GetService('Lighting')
local RunService=game:GetService('RunService')
local player=Players.LocalPlayer

do
    local roots = {}
    local playerGui = player and player:FindFirstChildOfClass('PlayerGui')
    if playerGui then roots[#roots + 1] = playerGui end
    local ok, hidden = pcall(function() return gethui and gethui() end)
    if ok and hidden and hidden ~= playerGui then roots[#roots + 1] = hidden end
    for _, root in roots do
        for _, child in root:GetChildren() do
            if child.Name == 'NeonLoading' then pcall(child.Destroy, child) end
        end
    end
    local oldBlur = Lighting:FindFirstChild('NeonStartupBlur')
    if oldBlur then pcall(oldBlur.Destroy, oldBlur) end
end

local function make(class,parent,props)
    local obj=Instance.new(class)
    for key,value in props or{}do pcall(function()obj[key]=value end)end
    obj.Parent=parent
    return obj
end
local function corner(obj,r)return make('UICorner',obj,{CornerRadius=UDim.new(0,r or 8)})end
local function stroke(obj,color,transparency)return make('UIStroke',obj,{Color=color or Color3.fromRGB(255,255,255),Transparency=transparency or .88,Thickness=1})end
local function tween(obj,time,props)
    local t=TweenService:Create(obj,TweenInfo.new(time,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props);t:Play();return t
end

local gui=make('ScreenGui',nil,{Name='NeonLoading',IgnoreGuiInset=true,DisplayOrder=2147483646,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local ok,hui=pcall(function()return gethui and gethui()end)
if ok and hui then gui.Parent=hui else gui.Parent=player:WaitForChild('PlayerGui')end

local overlay=make('Frame',gui,{BackgroundColor3=Color3.fromRGB(5,8,12),BackgroundTransparency=.18,Size=UDim2.fromScale(1,1),BorderSizePixel=0,ZIndex=1})
local veil=make('Frame',overlay,{BackgroundColor3=Color3.fromRGB(4,8,11),BackgroundTransparency=.32,Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromScale(1.1,1.1),BorderSizePixel=0,ZIndex=1})
local wash=make('UIGradient',veil,{Rotation=28,Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(5,14,18)),
    ColorSequenceKeypoint.new(.52,Color3.fromRGB(7,10,17)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(13,9,22)),
})})

local card=make('Frame',overlay,{Name='Card',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(438,188),BackgroundColor3=Color3.fromRGB(12,17,23),BackgroundTransparency=.08,BorderSizePixel=0,ZIndex=4})
corner(card,11);stroke(card,Color3.fromRGB(174,204,220),.84)
local shadow=make('ImageLabel',card,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,52,1,52),BackgroundTransparency=1,Image='rbxassetid://1316045217',ImageColor3=Color3.new(),ImageTransparency=.55,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(10,10,118,118),ZIndex=3})

local mark=make('Frame',card,{Position=UDim2.fromOffset(24,23),Size=UDim2.fromOffset(29,29),BackgroundColor3=Color3.fromRGB(0,226,226),BorderSizePixel=0,ZIndex=6});corner(mark,7)
local markInner=make('Frame',mark,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(13,13),BackgroundColor3=Color3.fromRGB(12,17,23),BorderSizePixel=0,ZIndex=7});corner(markInner,4)
local title=make('TextLabel',card,{BackgroundTransparency=1,Position=UDim2.fromOffset(65,19),Size=UDim2.fromOffset(170,23),Text='NEON',TextColor3=Color3.fromRGB(239,245,248),TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6})
local subtitle=make('TextLabel',card,{BackgroundTransparency=1,Position=UDim2.fromOffset(65,40),Size=UDim2.fromOffset(300,18),Text='CLIENT  /  INITIALIZING',TextColor3=Color3.fromRGB(125,139,151),TextSize=9,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6})

local divider=make('Frame',card,{Position=UDim2.fromOffset(24,72),Size=UDim2.new(1,-48,0,1),BackgroundColor3=Color3.fromRGB(82,97,108),BackgroundTransparency=.72,BorderSizePixel=0,ZIndex=5})
local status=make('TextLabel',card,{BackgroundTransparency=1,Position=UDim2.fromOffset(24,91),Size=UDim2.new(1,-48,0,18),Text='Starting Neon',TextColor3=Color3.fromRGB(190,201,209),TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6})
local percent=make('TextLabel',card,{BackgroundTransparency=1,Position=UDim2.new(1,-75,0,91),Size=UDim2.fromOffset(51,18),Text='0%',TextColor3=Color3.fromRGB(121,139,151),TextSize=10,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=6})
local rail=make('Frame',card,{Position=UDim2.fromOffset(24,124),Size=UDim2.new(1,-48,0,6),BackgroundColor3=Color3.fromRGB(36,45,53),BorderSizePixel=0,ZIndex=6});corner(rail,3)
local fill=make('Frame',rail,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(0,226,226),BorderSizePixel=0,ZIndex=7});corner(fill,3)
local grad=make('UIGradient',fill,{Color=ColorSequence.new(Color3.fromRGB(0,230,226),Color3.fromRGB(82,152,255))})
local footer=make('TextLabel',card,{BackgroundTransparency=1,Position=UDim2.fromOffset(24,145),Size=UDim2.new(1,-48,0,18),Text='clean runtime  •  modular interface  •  neon systems',TextColor3=Color3.fromRGB(78,94,105),TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6})

local blur=make('BlurEffect',Lighting,{Name='NeonStartupBlur',Size=0})
tween(blur,.28,{Size=13})
card.Size=UDim2.fromOffset(410,172);card.BackgroundTransparency=.28
for _,obj in {title,subtitle,status,percent,footer,rail,divider,mark}do if obj:IsA('GuiObject')then obj.Visible=true end end
tween(card,.28,{Size=UDim2.fromOffset(438,188),BackgroundTransparency=.08})

local api={Progress=0,Hidden=false}
function api:SetTheme(pallet,color)
    local accent=Color3.fromRGB(0,226,226)
    if pallet and pallet.Themes and pallet.Themes.Neon then accent=pallet.Themes.Neon[1]or accent end
    mark.BackgroundColor3=accent
    fill.BackgroundColor3=accent
end
function api:SetLoadingProgress(value,text)
    if self.Hidden then return end
    value=math.clamp(tonumber(value)or 0,0,1);self.Progress=value
    if text then status.Text=tostring(text)end
    percent.Text=('%d%%'):format(math.floor(value*100+.5))
    tween(fill,.2,{Size=UDim2.fromScale(value,1)})
end
function api:HideLoadingScreen(immediate)
    if self.Hidden then return end;self.Hidden=true
    local duration=immediate and 0 or .22
    if duration==0 then
        pcall(function()blur:Destroy()end);pcall(function()gui:Destroy()end);return
    end
    tween(card,duration,{Size=UDim2.fromOffset(420,176),BackgroundTransparency=1})
    tween(overlay,duration,{BackgroundTransparency=1});tween(veil,duration,{BackgroundTransparency=1});tween(blur,duration,{Size=0})
    task.delay(duration+.03,function()pcall(function()blur:Destroy()end);pcall(function()gui:Destroy()end)end)
end
shared.NeonLoading=api
return api
