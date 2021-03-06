--[[
	@20/4/16
	@axel-studios
	@the-vault-blood-money
	@waffloid
--]]

repeat wait(5)  until game.Players.LocalPlayer.Character

local run_service = game:GetService('RunService')

local player = game.Players.LocalPlayer
local _character = player.Character
local _replicated_storage = game.ReplicatedStorage
local _humanoid = _character:WaitForChild("Humanoid")
local _network = _replicated_storage.Network
local _assets = _replicated_storage.Assets
local _interface = player.PlayerGui:WaitForChild('UI')
local _ui = _interface.Gameplay

local heartbeat_funcs = {}
local character_module = {}
local animation = {anims={}}
local named_events = {}
local movement = {}
local movement_data = {}
local event = {}
local named_events = {}
local event = {}
local pseudo_char_interp = {} -- "game.workspace.npc1" = {start=cframe,finish=cframe,start_time=start_time,length=length,angle=angle}
local pseudo_char_output = {} -- "game.workspace.npc1" = cframe=current_cframe
local animation = {}
local running_animations = {} -- {Workspace.Waffloid={wave={start_time=start_time,looped=true},jump=start_time}}
local animation_start = {}
local current_keyframe = {}
local animated_models = {}
local ui_logic = {}
local weld_status = {} 
local delta = {}
local mathf = {}
local weapon = {}
local animations = {}
local skills = {}
local emotions =  {}
local remote_functions

local anim_render_dist = 90
local movement_render_dist = 150
local rot_constraint = 20
local user_input_service = game:GetService('UserInputService')
local has_bag
local interacting

local is_aiming
local reloading
local shooting
local switching

local player_anim

local tutorial_mode = true
local casing_mode = true


function index_table(tab,real_tab)
	real_tab = real_tab or ''	for i,v in pairs(tab) do
		--(real_tab,i,":",v)
		if type(v) == 'table' then
			index_table(v,real_tab..'	')
		end
	end
end

local function get_obj(real_model)
	local model
	for w in string.gmatch(real_model,'%w+') do
		if not model then
			model = workspace
		else
			model = model:FindFirstChild(w)
		end
	end
	return model
end












--mathf module
do
	
	function mathf.round(num) -- for that pesky fpp
		return math.floor(num*12)/12
	end


	function mathf.extract_angle(c)
		return c-c.p--hot
	end

	function mathf.clamp(min,max,val)
		return math.max(min,math.min(max,val))
	end

	function mathf.abs(vec)
		return Vector3.new(math.abs(vec.X),math.abs(vec.Y),math.abs(vec.Z))
	end

	function mathf.len(t)
		local l=0
		for i,v in pairs(t) do
			l=l+1
		end
		return l
	end
end












--delta module
do
	local id = {}
	function delta.set(name)
		id[name]=tick()
	end
	function delta.get(name)
		if id[name] then
			return tick()-id[name]
		else
			delta.set(name)
			return 0
		end
	end
end











--@networking/events
do
	_network.RemoteEvent.OnClientEvent:connect(function(name,...)
		local event = named_events[name]
		if event then
			for i,v in pairs(event.connections) do
				if type(v) == 'function' then
					v(...)
				else
					v:fire(...)
				end
			end
		end
	end)

	_network.RemoteFunction.OnClientInvoke = function(name,...)
		local func = remote_functions[name]
		if func then
			return func(...)
		end
	end

	function event.new(name)
		local event = {connections={}}
		function event:fire(...)
			if name then
				_network.RemoteEvent:FireServer(name,...)
			end
			for  x = 1,#event.connections do
				if type(event.connections[x]) == 'function' then
					event.connections[x](...)
				else
					event.connections[x]:fire(...)
				end
			end
		end
		function event:connect(func)
			event.connections[#event.connections+1] = func
		end
		function event:condition(new_event,condition)
			event:connect(function(...) local output = {condition(...)} if #output ~= 0 then new_event:fire(unpack(output)) end end)
		end
		if name then
			named_events[name] = event
		end
		return event
	end
end
--('networking/event module loaded')












--@animation ski
do
	for _,anim in pairs(script:GetChildren()) do
		animations[anim.Name]=require(anim)
	end
	
	function recoil()
		delta.set('Recoil')
		run_service:UnbindFromRenderStep('Recoil')
		run_service:BindToRenderStep('Recoil',213,function()
			local delta_v = -math.sin(math.pi * delta.get('Recoil') * 6) 
			player_anim.head_offset = CFrame.new(0,delta_v/40,0) * CFrame.Angles(math.rad(delta_v * 3),0,0)
			if (delta.get('Recoil') * 6) > 1 then
				------print(('bbk till they day that i dead')
				run_service:UnbindFromRenderStep('Recoil')
			end
		end)
	end
	
	local function select_keyframe(slide,time)
		local current_keyframe_time
		local next_keyframe_time
		
		local last_slide_time
		local last_slide_keyframe
		
		for keyframe_time,keyframe in pairs(slide) do
			if keyframe_time >= time then
				return keyframe_time,keyframe
			end
		end
	end
	
	
	event.new('run animation'):connect(function(obj,anim,...)
		if not animated_models[obj] then
			animated_models[obj] = render_anim(obj)
		end
		animated_models[obj]:run(anim,...)
	end)
	
	
	
	function render_anim(real_obj,is_player)
		
		local id = real_obj:GetFullName()..math.random()..'Animated'
		
		local last_anim = tick()
		local running_animations = {}
	
		local animation = {
			['Right Arm']={curr=CFrame.new()},
			['Left Arm']={curr=CFrame.new()},
			['Left Leg'] = {curr=CFrame.new(-.5,-2,0)},
			['Right Leg'] = {curr=CFrame.new(.5,-2,0)},
			['Gun']={curr=CFrame.new()}
		}
		for obj,_ in pairs(animation) do
			if real_obj.Torso:FindFirstChild(obj) then
				real_obj.Torso[obj].C1 = CFrame.new()
			end
		end
		
		local animation_object = {head_offset=CFrame.new()}
		
		run_service:BindToRenderStep(id,215,function()
			if not real_obj.Parent then
				run_service:UnbindFromRenderStep(id)
			end
			if is_player then
				real_obj.Torso.Head.C0 = (CFrame.Angles(math.asin(workspace.CurrentCamera.CFrame.lookVector.Y),0,0) + Vector3.new(0,1.5,0))
				real_obj.Torso.Head.C1 = animation_object.head_offset
				for _,part in pairs(real_obj:GetChildren()) do
					if part:IsA("BasePart") then
						part.LocalTransparencyModifier=0
					end
				end
			end
			for anim,anim_data in pairs(running_animations) do
				if not real_obj.Parent then
					game:GetService("RunService"):UnbindFromRenderStep(id)
				end
				local keyframe_time,keyframe = select_keyframe(animations[anim],tick()-anim_data.start)
				----print((animations[anim],keyframe_time,tick()-anim_data.start)
				if animations[anim][keyframe_time] then
					for part,desired in pairs(animations[anim][keyframe_time]) do
						------print(("they're like chippy gon mad innit")
						if not animation[part] then
							animation[part] = {}
						end
						if (animation[part].priority or 0) <= anim_data.priority then
							animation[part].desired = desired
							animation[part].finish_time = anim_data.start+keyframe_time
							animation[part].priority = anim_data.priority
						end
					end
				else
					if not anim_data.looped then
						local last_slide
						for i,_ in pairs(animations[anim]) do
							last_slide = i
						end
						running_animations[anim]=nil
					else
						anim_data.start=tick()
					end
				end
			end
			
			for obj,data in pairs(animation) do
				data.priority = nil
				if data.finish_time and (data.finish_time > tick()) and real_obj.Torso:FindFirstChild(obj) then
					----print((obj,data)
					local delta =  math.max( math.min( (tick()-last_anim) / (data.finish_time-tick()) , 1) , 0 )
					----print((delta)
					data.curr = data.curr:lerp(data.desired,delta)
					real_obj.Torso[obj].C0 = (data.curr)
				end
			end 
			
			last_anim = tick()
		end)
		
		function animation_object:run(anim,looped,priority,speed)
			running_animations[anim] = {start=tick(),priority=priority or 3,looped=looped or false,speed=speed or 1} -- IMPLEMENT SPEED
		end
		
		function animation_object:stop(anim)
			--print('difft day same shit')
			running_animations[anim] = nil
		end
		
		function animation_object:terminate()
			run_service:UnbindFromRenderStep(id)
		end
		
		return animation_object
	end
	player_anim = render_anim(game.Players.LocalPlayer.Character,true)
	
	player_anim:run('Default')
end















--@skills
do
	skills['laughing gas'] = true
end


























--@color module
do
	local positive_not_scared_desired = Color3.new(30/255, 199/255, 143/255)
	local negative_not_scared_desired = Color3.new(255/255, 0, 0)
	local positive_sadness_desired = Color3.new(0, 24/255, 158/255)
	local negative_sadness_desired = Color3.new(215/255, 255/255, 153/255)
	
	local increment = .35
	local delta_increment = 1


	function decide_emotion_color(not_scared,sadness)
		local not_scared_color,sadness_color
		if math.abs(not_scared) == not_scared then
			not_scared_color = Color3.new(.5,.5,.5):lerp(positive_not_scared_desired,(not_scared/10)^increment)
		else
			not_scared_color = Color3.new(.5,.5,.5):lerp(negative_not_scared_desired,(not_scared/-10)^increment)
		end
		
		if math.abs(sadness) == sadness then
			sadness_color = Color3.new(.5,.5,.5):lerp(positive_sadness_desired,(sadness/10)^increment)
		else
			sadness_color = Color3.new(.5,.5,.5):lerp(negative_sadness_desired,(sadness/-10)^increment)
		end
		
		local delta = math.abs(not_scared)/(math.abs(sadness)+math.abs(not_scared))
		return sadness_color:lerp(not_scared_color,delta)
	end
	
	run_service:BindToRenderStep('Detection',199,function()
		for _,object in pairs(workspace.DetectionMeter:GetChildren()) do
			object.block.CFrame = CFrame.new(object.Value.Position + Vector3.new(0,2,0)) * CFrame.Angles(math.rad(45),math.rad(45),0)
			local transparency = (math.abs(object.Not_Scared.Value+object.Sadness.Value)/10)^.3
			if transparency < .05 and transparency > -.05 then
				transparency = 1
			end
			local color = decide_emotion_color(object.Not_Scared.Value,object.Sadness.Value)
			object.block.BrickColor = BrickColor.new(color)
			object.block.Transparency = transparency
			for i,v in pairs(object.block:GetChildren()) do
				v.Frame.Transparency = transparency
				v.Frame.BackgroundColor3 = color
			end
		end
	end)
end



















--@pseudocharacter module
do
end
--('pseudocharacter module loaded')



















--@interacion module
do
	
	local interact = event.new('interact')

	local function get_interactive_data(model)
		local is_interactive,class,name
		if model and model.Parent.Parent then
			if (model.Parent.Parent == workspace.Interactive) then
				return model.Parent.Name,model.Name,model
			elseif model:IsDescendantOf(workspace.Interactive) then
				return get_interactive_data(model.Parent) -- if its inside model ski recursive
			end
		end
	end

	local function is_interactive(obj)
		if obj and obj.Parent then
			local class,name = get_interactive_data(obj)
			if class then
				return _network.RemoteFunction:InvokeServer('interactive',class,obj)
			end
		end
	end
	
	local last_mouse_hit = nil--workspace.Buildings.SkyFog
	local mouse = player:GetMouse()
	local global_class,name,interactive_data
	
	local interact_ui = player.PlayerGui.UI.Interact
	
	run_service:BindToRenderStep('Interaction',160,function()
		if not casing_mode and not sprint and not reloading then
			local target
			if (mouse.Hit.p-workspace.CurrentCamera.CFrame.p).Magnitude < 10 then
				target = mouse.Target
			elseif interact_ui.Parent then
				interact_ui.Enabled = false
				interact_ui.Parent = game.ReplicatedStorage
				global_class = nil
				interact_time = nil
				interactive_data = nil
			end
			if target and not interacting then  
				if last_mouse_hit~= target then
					local class,name,target=get_interactive_data(target)
					local set_parent
					if class then
						global_class = class
						interactive_data = is_interactive(target)
						
						if interactive_data and not has_bag then
							interact_time = tonumber(interactive_data[3])
							
							if not interact_ui.Parent then
								interact_ui = game.ReplicatedStorage.Interact:Clone()
							end
							
							interact_ui.Parent = target
							interact_ui.Enabled = true
							
							interact_ui.Key.Text = 'F'
							
							interact_ui.Text.Text = interactive_data[1]:upper()
						end
						
					elseif interact_ui.Parent then
						interact_ui.Enabled = false
						interact_ui.Parent = game.ReplicatedStorage
						global_class = nil
						interact_time = nil
						interactive_data = nil
					end
					last_mouse_hit = target
				end
			end
		end
	end)
	
	function interact_proxy(time,key)
		if interact_ui.Parent and interactive_data and not has_bag and time and key and not sprint then
			interacting = true
			local obj = last_mouse_hit
			_character.Humanoid.WalkSpeed = 0
			for i = 0,1,(1/60) /time do -- use bind
				interact_ui.Text.Frame.Size = UDim2.new(i,0,1,0)
				run_service.RenderStepped:wait()
				if (not user_input_service:IsKeyDown(Enum.KeyCode[key])) and true then
					interact_ui.Text.Frame.Size = UDim2.new(0,0,1,0)
					_character.Humanoid.WalkSpeed = 16
					interacting = false
					return
				end
			end
			interact_ui.Text.Frame.Size = UDim2.new(0,0,1,0)
			interact_ui.Enabled = false
			interact_ui.Parent = game.ReplicatedStorage
			interact:fire(global_class,last_mouse_hit)
			if global_class == 'Bag' then
				has_bag = last_mouse_hit
			end
			
			_character.Humanoid.WalkSpeed = 16
			interacting = false
			
			if obj and obj.Parent then
				local interactive,class,name = get_interactive_data(name)
				local new_data = is_interactive(obj)
				if new_data and not new_data[2] then
					_ui.OnscreenInteract.Visible = true
					_ui.OnscreenInteract.Text = new_data[1]:upper()
				end
			end
		end
	end
	
	function attempt_drop()
		if has_bag then
			_ui.OnscreenInteract.Visible = false
			interact:fire('Bag',has_bag);
			has_bag = nil
		end
	end
end
















--@gamelogic
do
	local picked_up_thermalbag
	local picked_up_money_bag
	
	local recieve_broken_light = event.new('Client broke light')
	local recieve_broken_glass = event.new('Client broke glass')
	local receive_open_door = event.new('Client open door')
	local receive_close_door = event.new('Client close door')

	recieve_broken_light:connect(function(part)
		part:ClearAllChildren()
		part.Material = 'Plastic'
	end)
	
	local in_system = 0

	--[[game:GetService('RunService'):BindToRenderStep('laughing gas effect',201,function()
		local total_dist = 0
		local total_count = 0
		for i,v in pairs(workspace['Laughing gas']:GetChildren()) do
			total_count = total_count + 1
			total_dist = (total_dist + (1/(v.exit.Position-game.Players.LocalPlayer.Character.Torso.Position).Magnitude^1.5) / (60/v.exit.ParticleEmitter.Rate))
		end
		in_system = math.min(1,(in_system * 0.998) + (total_dist * 0.2)) / total_count
		local v = math.abs(math.sin(tick())^2)
		local d = 1-v 
		game.Lighting.ColorCorrection.TintColor = Color3.new((v * in_system) - (in_system-1) ,(d * in_system) - (in_system-1),1)
		game.Lighting.ColorCorrection.Saturation = math.sin(tick()/3) * in_system
		game.Lighting.ColorCorrection.Contrast = ((math.abs(math.sin(tick()/3))/2) + 0.2) * in_system
		workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * CFrame.Angles(math.sin((tick()))/(120 / in_system),math.cos(tick())/(120 /in_system),0)
	end)]]

	receive_open_door:connect(function(door)
		id = 'Open door '..math.random()
		local val = 90
		if door:FindFirstChild("desired") then
			val = door.desired.Value
		end
		local desired = math.rad(math.random(val-20,val+20))
		delta.set(id)
		run_service:BindToRenderStep(id,201,function()
			local delta = math.min(delta.get(id) * 3,1)
			
			door:SetPrimaryPartCFrame(CFrame.Angles(0,math.sin(delta * desired) * math.pi/2,0) + door.PrimaryPart.Position)

			if delta >= 1 then
				run_service:UnbindFromRenderStep(id)
			end
		end)
	end)

	receive_close_door:connect(function(door)
		id = 'Open door '..math.random()
			local val = 90
		if door:FindFirstChild("desired") then
			val = door.desired.Value
		end
		local desired = math.rad(math.random(val-20,val+20))
		delta.set(id)
		run_service:BindToRenderStep(id,201,function()
			local delta = 1-math.min(delta.get(id) * 3,1)
			
			door:SetPrimaryPartCFrame(CFrame.Angles(0,math.sin(delta * desired) * math.pi/2,0) + door.PrimaryPart.Position)

			if delta <= 0 then
				run_service:UnbindFromRenderStep(id)
			end
		end)
	end)
	
	recieve_broken_glass:connect(function(part)
		------------print(((('rasclart')
		local w1 = Instance.new('WedgePart')
		local w2 = Instance.new('WedgePart')

		w1.CanCollide = false
		w2.CanCollide = false

		w1.Size = part.Size
		w2.Size = part.Size

		w1.Transparency = part.Transparency
		w2.Transparency = part.Transparency

		w1.BrickColor = part.BrickColor
		w2.BrickColor = part.BrickColor

		w1.Velocity = workspace.CurrentCamera.CFrame.lookVector * 20
		w2.Velocity = workspace.CurrentCamera.CFrame.lookVector * 20

		w1.Parent = workspace
		w2.Parent = workspace
	
		w1.CFrame = part.CFrame
		w2.CFrame = part.CFrame * CFrame.Angles(math.rad(180),0,0)
		
		

		part:Destroy()

	end)
	
	function leave_casing()
		local gun = _replicated_storage.Gun
	end
	

	
	workspace.Flashbang.ChildAdded:connect(function(flashbang)
		if (flashbang.Position-_character.Torso.Position).Magnitude < 15 then
			_character.Humanoid.WalkSpeed = 4
			_ui.Visible = false
			for i = 0,1,.1 do
				game.Lighting.ColorCorrection.Brightness = i
				run_service.RenderStepped:wait() -- sorry
			end
			wait(math.random(3,5))
			for i = 1,0,-0.01 do
				game.Lighting.ColorCorrection.Brightness = i
				run_service.RenderStepped:wait() -- sorry
			end
			_character.Humanoid.WalkSpeed = 16
			_ui.Visible = true
		end
	end)
	
	run_service:BindToRenderStep('Game logic',170,function()
		if has_bag and has_bag.Name == 'Interactive_Bag_ThermalBag' then
			if not picked_up_thermalbag then
				picked_up_thermalbag = tick()
			else
				local brightness = math.sin(picked_up_thermalbag-tick())/3 + 0.5
				workspace.Interactive.VaultArea.Transparency = brightness
			end
		elseif (has_bag and has_bag.Name:find('MoneyBag')) or picked_up_money_bag then
			if not picked_up_money_bag then
				picked_up_money_bag = tick()
			end
			local brightness = math.sin(picked_up_money_bag-tick())/3 + 0.5
			workspace.Interactive.BagArea.Transparency = brightness
		elseif picked_up_thermalbag then
			--('dr0pped baggio')
			picked_up_thermalbag = nil
			workspace.Interactive.VaultArea.Transparency = 1
		end
	end)
end















--@weapon module
do

	local dest_env = event.new('player shoot')
	local break_light = event.new('Broke light')
	local shatter_glass = event.new('Broke glass')
	local gun_fire = event.new('Gunshot')
	
	

	local function shoot()
		--if not reloading then
			if weapon.clip > 0 then
				local ray =  Ray.new(_character.Torso.Gun.Part1.Position,_character.Torso.Gun.Part1.CFrame.lookVector*-300)
				local hit,pos,norm = workspace:FindPartOnRayWithIgnoreList(ray,{_character})

				if hit then
					------------print(((('yannoe dem 1s',(hit:IsDescendantOf(workspace.walls) or hit:IsDescendantOf(workspace.Broken)))
					if(hit:IsDescendantOf(workspace.walls) or hit:IsDescendantOf(workspace.Broken)) then
						dest_env:fire(hit,pos,norm)
						------------print(((('tell moi prettoi lois')
					elseif hit:IsDescendantOf(workspace.Lights) then
						break_light:fire(hit)
					elseif math.floor(hit.Transparency)~=hit.Transparency and (math.min(hit.Size.X,hit.Size.Y,hit.Size.Z) <= 1.5) then
						------------print(((('brapalap')
						shatter_glass:fire(hit)
						
					end
				end
				
				gun_fire:fire(hit,pos,norm)
				------------print(((('buss da skeng!')
				weapon.clip = weapon.clip-1
				recoil()
			else
				weapon.reload()
			end
		--end
	end

	local function reload()
		reloading = true
		------------print(((('reloading')
		wait(2)
		weapon.clip = weapon.full_clip
		reloading = false
	end
	
	local function switch(new_weapon) -- im talking about switching weapons not actually using the weapons to switch
		switching = true
		player_anim:run("Switch") --run_animation('Switch',player_animation)
		------------print(((('who dabs the dab')
		wait(.4)
		if type(weapon)=='table' and weapon.gun then
			_character.Torso.Gun.Part1 = nil
			weapon.gun.Parent = game.ReplicatedStorage
		end
		weapon = new_weapon
		weapon.gun.Parent = workspace.Ignore_Folder
		_character.Torso.Gun.Part1 = weapon.gun
		player_anim:run(weapon.hipfire_anim)--run_animation(weapon.hipfire_anim,player_animation)
		switching = false
	end

	local function run(key_up)
		if key_up then
			_humanoid.WalkSpeed = 20
			sprint = true
			player_anim(weapon.run_anim)--run_animation(weapon.run_anim,player_animation)
		else
			_humanoid.WalkSpeed = 16
			sprint = false
			player_anim:run(weapon.hipfire)--run_animation(weapon.hitfire,player_animation)
		end
	end

	local function aim(aim)
		if aim then
			is_aiming = true
			player_anim:run('Aim')--run_animation('Aim',player_animation)
		else
			is_aiming = false
			player_anim:run(weapon.hipfire_anim)--run_animation(weapon.hipfire_anim,player_animation)
		end
	end
	
	local is_shooting

	local function shoot_semi(key_up)
		if key_up then
			shoot()
		end
	end
	--[[grenade = {}
	grenade.gun = game.ReplicatedStorage.Assets.Grenade:Clone()
	grenade.shoot = function()
		local grenade_piece = weapon.gun
		run_animation('Throw',player_animation)
		wait(.15)
		_character.Torso.Gun.Part1 = nil
		grenade_piece.Velocity = (workspace.CurrentCamera.CFrame * CFrame.new(1, 0, -1.5, 1, 0, -0, -0, 0.928476751, -0.3713907, -0, 0.3713907, 0.928476751)).lookVector * 60
		weapon = {switch=switch}
	end
	grenade.switch = switch
	grenade.hipfire_anim = 'Brace']]
	

	primary_weapon = {}
	primary_weapon.gun = game.ReplicatedStorage.Assets.WeaponGun:Clone()
	primary_weapon.full_clip = 13
	primary_weapon.clip = 13

	primary_weapon.hipfire_anim = 'Hipfire'
	primary_weapon.run_anim = 'Run'

	primary_weapon.shoot = shoot_semi
	
	primary_weapon.run = run
	primary_weapon.reload = reload
	primary_weapon.aim = aim
	primary_weapon.switch = switch
	
	
	secondary_weapon = {}
	secondary_weapon.gun = game.ReplicatedStorage.Assets.WeaponGun:Clone()
	secondary_weapon.gun.Size = Vector3.new(0.2, 0.8, 4)
	secondary_weapon.full_clip = 21
	secondary_weapon.clip = 21
	
	secondary_weapon.hipfire_anim = 'Hipfire'
	secondary_weapon.run_anim = 'Run'
	
	secondary_weapon.shoot = shoot_semi
	secondary_weapon.switch = switch
	secondary_weapon.shoot = shoot_semi
	secondary_weapon.run = run
	secondary_weapon.reload = reload
	secondary_weapon.aim = aim
	 

	weapon = {switch=function()
		switch(primary_weapon)
	end,hipfire='Hipfire',run='Run'}
end















--input module
do
	user_input_service.InputBegan:connect(function(input)
		if _character and _character:FindFirstChild("Humanoid") and not interacting then
			if not casing_mode then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.R then
						weapon.reload()
					elseif input.KeyCode == Enum.KeyCode.LeftShift then
						if not has_bag then
							_humanoid.WalkSpeed = 20
							sprinting = true
							player_anim:run(weapon.run_anim)
						end
					--[[elseif input.KeyCode == Enum.KeyCode.T then
						if grenade.gun then
							local orig = weapon
							weapon.switch(grenade)
							wait(0.2)
							weapon.shoot()
							weapon.switch(orig)
						end--]]
					elseif input.KeyCode == Enum.KeyCode.E then
						--weapon_module.change_weapon()
					elseif input.KeyCode == Enum.KeyCode.One then
						weapon.switch(primary_weapon)
					elseif input.KeyCode == Enum.KeyCode.Two then
						weapon.switch(secondary_weapon)
					elseif input.KeyCode == Enum.KeyCode.Q then
						if not sprinting and not reloading then
							weapon.aim(not is_aiming)
							------------print(((('MEH HAFFI AIM')
						end
					elseif input.KeyCode == Enum.KeyCode.F then
						interact_proxy(interact_time,'F')
					elseif input.KeyCode == Enum.KeyCode.G then
						attempt_drop()
					elseif input.KeyCode == Enum.KeyCode.C then
						run_service:UnbindFromRenderStep('Crouch')
					end
				elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
					if not reloading then
						weapon.shoot(true)
					end
				elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
					if not sprinting and not reloading then
						weapon.aim(true)
					end
				end
			elseif input.KeyCode == Enum.KeyCode.G then
				_ui.OnscreenInteract.Visible = false
				casing_mode = false
				weapon.switch()
				--animation.run(_character,'hipfire')
				if workspace.Interactive:FindFirstChild("Interactive_Bag_ThermalBag") then
					ui_logic['Objectives']:fire("Get the thermal drill bag")
				end
			end
		end
	end)
	
	user_input_service.InputEnded:connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.LeftShift then
				sprinting = false
				_humanoid.WalkSpeed = 16
				player_anim:run(weapon.hipfire_anim)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			--('EEEEE I SWEAR TO GOD WHY DOESNT THIS FIRE')
			shooting = false
			run_service:UnbindFromRenderStep('Shoot')
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if is_aiming then
				weapon.aim(false)
			end
		end
	end)
end













--@aesthetic
do
	--kinda gamelogic but not rlly
	local new_emotion = {}
	local angle = math.rad(4) 
	local eye_angle = math.rad(10)
	local odds = 90
	
	local brow1 = CFrame.new(-0.136310577, 0.401372242, -0.559999943, 0.959538877, 0.0177439954, 0.281016499, 0.0295529962, 0.98615402, -0.163177446, -0.280020982, 0.164879993, 0.945728719)
	local brow2 = CFrame.new(0.127689362, 0.401372242, -0.563999653, -0.963426948, -0.0048001986, 0.267928123, 0.0352389961, 0.98888725, 0.144430727, -0.265643984, 0.148589969, -0.952551544)
	
	local mouth = CFrame.new(0, -0.190575123, -0.582895756, 1, 0, 0, 0, 0.999999881, -0.000496729393, 0, 0.000496729393, 0.999999881)
	
	local eye1 = CFrame.new(0.130001068, 0.271208096, -0.579999924, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	local eye2 = CFrame.new(-0.130001068, 0.271208096, -0.579999924, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	
	local function val(num)
		local new = (num / math.abs(num))
		if new ~= 1 or new ~= -1 then
			new = 0
		end
		return new
	end
	
	local function sigmoid(x)
		return 1/(math.exp(-x)+1)
	end
	
	local function generate_face(head)
		local _folder = Instance.new('Folder')
		local _face = game.ReplicatedStorage.Face
		
		_folder.Parent = head
		
		local b1,b2,e1,e2,m = Instance.new('ManualWeld'),Instance.new('ManualWeld'),Instance.new('ManualWeld'),Instance.new('ManualWeld'),Instance.new('ManualWeld')
		b1.Parent,b2.Parent,e1.Parent,e2.Parent,m.Parent= _folder,_folder,_folder,_folder,_folder --lazy
		b1.Part0,b2.Part0,e1.Part0,e2.Part0,m.Part0 = head,head,head,head,head -- would using loops be more efficient?
		b1.C0,b2.C0,e1.C0,e2.C0,m.C0 = brow1,brow2,eye1,eye2,mouth
		
		b1.Name,b2.Name,e1.Name,e2.Name,m.Name = 'b1','b2','e1','e2','m'
		
		local _b1,_b2,_e1,_e2,_m = _face.brow1:Clone(),_face.brow2:Clone(),_face.eye1:Clone(),_face.eye2:Clone(),_face.mouth:Clone()
		
		_b1.Parent,_b2.Parent,_e1.Parent,_e2.Parent,_m.Parent=_folder,_folder,_folder,_folder,_folder
		
		b1.Part1,b2.Part1,e1.Part1,e2.Part1,m.Part1= _b1,_b2,_e1,_e2,_m
		
		return _folder
	end
	
	local function render_face(face,playback,anger,happiness,concience)
		local angle = -(((-((happiness - (anger / 3)) / (math.abs(happiness) + anger))) * math.max(math.abs(happiness),math.abs(anger))/10) - .5) * math.rad(5)
		local eyebrows = (((-((anger - (happiness / 3)) / (math.abs(anger) + happiness))) * math.max(math.abs(happiness),math.abs(anger))/10))  * (1 + (playback/2000))
		m= ((math.max(playback,10) ^(1/2.2))/12) 
		if tostring(eyebrows) ~='nan' and tostring(angle) ~= 'nan' and tostring(m) ~= 'nan' then
			face.b1.C1 = CFrame.Angles(0,0,math.rad(-20) * eyebrows)
			face.b2.C1 = CFrame.Angles(0,0,math.rad(-20) * eyebrows)
			
			face.m.C1 = CFrame.Angles(angle * math.min((2/m),100),0,0)
			face.mouth.Mesh.Offset = Vector3.new(0,0,(angle*((m)/3.5) * val(angle)))-- ------------print((((math.abs(m),-m)
			------------print((((Vector3.new(1, 1.054 * m, 0.2) )
			face.mouth.Mesh.Scale = Vector3.new(1, 1.054 * m, 0.2)
		end
		if math.random(60 * math.sqrt(concience))==1 then
			face.eye1.Mesh.Scale = Vector3.new(0.5, 0.1, 0.2)
			face.eye2.Mesh.Scale = Vector3.new(0.5, 0.1, 0.2)
		else
			face.eye1.Mesh.Scale = Vector3.new(0.5, (0.6 * concience) + .1, 0.2)
			face.eye2.Mesh.Scale = Vector3.new(0.5, (0.6 * concience) + .1, 0.2)
		end
	end
	
	event.new('move'):connect(function(npc,is_animating)
		local animated_model = animated_models[npc]
		if not animated_model then
			animated_models[npc] = render_anim(npc)
			animated_model = animated_models[npc]
		end
		--print('is_-animating',is_animating)
		if is_animating then
			--print('bitch boy wanna start rhyming again')
			--animated_model:run('Walk',true)
		else
			--animated_model:stop('Walk')
			--animated_model:run('Default',nil,5)
		end
	end)
	
	
	event.new('update emotions'):connect(function(npc,emotion,awareness)
		--print('shoot if u have to')
		new_emotion[npc] = true
		emotions[npc]={emotion=emotion,awareness=awareness}
	end)
	
	local faces = {}
	
	for i,v in pairs(workspace.Interactive.Civilian:GetChildren()) do
		local generatred = generate_face(v.Head)
		faces[v]=generatred
	end
	
	run_service:BindToRenderStep('Render faces',201,function()
		for i,v in pairs(faces) do
			if v and v.Parent and v:FindFirstChild('b1') then
				local sound = v.Parent:FindFirstChild("Sound")
				if ((sound and sound.IsPlaying and sound.PlaybackLoudness > 50) or new_emotion[v.Parent.Parent])  then
					------print(('rander!')
					new_emotion[v] = nil
					local loud = 0
					local fear = 0
					local sadness = 0
					local concience = 1
					
					local brain = emotions[v.Parent.Parent]
					if brain then
						fear = brain.emotion.Z + ((brain.emotion.X - 0.5)/2) -- if hes hurt he'll look more scared
						sadness = brain.emotion.Y + ((brain.emotion.X - 0.5)/2)
						concience = brain.awareness
					end
					if sound then
						loud = (sound.PlaybackLoudness) * 1.2
					end
					----------print(((math.abs(sadness)*50,'wallahi')
					render_face(v,loud + (math.abs(sadness) + math.abs(fear))*70,(-(fear - 0.5)) *20,(-(sadness - 0.5))*20,concience)
				end
			else
				faces[i]=nil
			end
		end
	end)
end















--@ui module
do
	local police_assault = event.new('police assault')
	local narration = event.new('narration')
	local downed = event.new('downed')
	
	local ui = {}
	
	function ui.new(name,func)
		local curr_event = event.new()
		event.new(name):connect(curr_event)
		ui_logic[name] = curr_event
		ui_logic[name]:connect(func)
	end
	
	local last_open
	local last_narration
	local blur
	
	ui.new('Objectives',function(objectives)
		if objectives then
			local time = tick()
			last_open = time
			_ui.Objectives.Frame:TweenSize(UDim2.new(0,0,0,60),'Out','Sine',.5)
			wait(2)
			_ui.Objectives.Frame.TextLabel.Text = ' '..objectives:upper()
			if last_open == time then
				_ui.Objectives.Frame:TweenSize(UDim2.new(0,550,0,60),'Out','Sine',.5)
			end
		else
			_ui.Objectives.Frame:TweenSize(UDim2.new(0,0,0,60),'Out','Sine',.5)
			wait(.5)
			_ui.Objectives.Frame.TextLabel.Text = ''
		end
	end)
	
	ui.new('Police Assault',function(val,...)
		
		if val then
			_ui.PoliceAssault.Frame:TweenSize(UDim2.new(0,-550,0,60),'Out','Sine',.5)
		else
			_ui.PoliceAssault.Frame:TweenSize(UDim2.new(0,0,0,60),'Out','Sine',.5)
		end
	end)
	
	ui.new('Downed',function(is_downed)
		--(is_downed)
		if is_downed then
			_humanoid.WalkSpeed = 0
			blur = true
			local amount = game.Lighting.Blur.Size^2
			for i,v in pairs(_ui:GetChildren()) do
				v.Visible = false
			end
			_ui.DownedUI.Visible = true
			run_service:BindToRenderStep('BlurCamera',Enum.RenderPriority.Camera.Value-10,function()
				if (amount >= 10*60) or (not blur) then
					--('stop!!!!!!')
					run_service:UnbindFromRenderStep('BlurCamera')
				end
				game.Lighting.ColorCorrection.Saturation = -math.atan(math.sqrt(amount)/5)/math.pi
				game.Lighting.Blur.Size = math.sqrt(amount)
				amount = amount + 1
			end)
		else
			_humanoid.WalkSpeed = 16
			local finish
			blur = false
			local amount = game.Lighting.Blur.Size^2
			run_service:BindToRenderStep('UnblurCamera',Enum.RenderPriority.Camera.Value-10,function()
				if blur or amount == 0 then
					finish = true
					run_service:UnbindFromRenderStep('UnblurCamera')
				end
				game.Lighting.ColorCorrection.Saturation = -math.atan(math.sqrt(amount)/5)/math.pi
				game.Lighting.Blur.Size = math.sqrt(amount)
				amount = math.max(amount - 6,0)
			end)
			repeat wait() until finish
			wait(.2)
			for i,v in pairs(_ui:GetChildren()) do
				v.Visible = true
			end
			_ui.DownedUI.Visible = false
		end
	end)
	
	ui.new('Time',function()
		local start = tick()
		spawn(function()
			while wait(1) do
				local sec,min = tostring(math.floor((tick()-start)%60)),tostring(math.floor((tick()-start)/60))
				sec = string.rep('0',(2-#sec))..sec
				_ui.Time.Text = min..':'..sec
			end
		end)
	end)
	
	local function load_number(text_label,prefix,number)
		local start = tick()
		run_service:BindToRenderStep('Load number '..text_label.Name,199,function()
			local delta = tick()-start
			if delta <= 1 then
				text_label.Text = prefix..math.floor(number * delta)
			else
				text_label.Text = prefix..math.floor(number)
				run_service:UnbindFromRenderStep('Load number '..text_label.Name)
			end
		end)
		repeat wait() until (tick()-start) >= 1 -- yields once the loop b4 yields
	end
	
	ui.new('End screen',function(total_money,heisters_in_custody,civilians_killed,stealthed)
		if total_money == 0 then
			--_interface.HeistCompleted.Completed.BackgroundColor3 = Color3.fromRGB(185, 0, 19)
			_interface.HeistCompleted.Completed.Text.Text = 'HEIST FAILED'
		end
		local stealth_bonus = 0
		if stealthed then
			stealth_bonus = total_money  * .2
		end
		local result =math.max((total_money + stealth_bonus) - ((heisters_in_custody * 5000) + (civilians_killed * 1000)),0)
		------------print((((result,total_money,((heisters_in_custody * 5000) + (civilians_killed * 1000)))
		
		
		_ui.Visible = false
		wait(1)
		_interface.HeistCompleted.Visible = true
		
		_interface.HeistCompleted.Custody.Text.Text = 'HEISTERS IN CUSTODY x'..heisters_in_custody
		_interface.HeistCompleted.Civilians.Text.Text = 'CIVILIANS KILLED x'..civilians_killed
		
		load_number(_interface.HeistCompleted.Stolen.Value,'$',total_money)
		load_number(_interface.HeistCompleted.Bonus.Value,'$',stealth_bonus)
		
		load_number(_interface.HeistCompleted.Civilians.Value, '-$', (civilians_killed * 1000))
		load_number(_interface.HeistCompleted.Custody.Value, '-$',(heisters_in_custody * 5000))
		load_number(_interface.HeistCompleted.Total.Value,'$',result)
	end)
	
	local function relay(...)
		 return ... 
	end
	
	ui_logic['Time']:fire()
	
	police_assault:condition(ui_logic['Police Assault'],relay)
	downed:condition(ui_logic['Downed'],function(char,is_downed)
		if (char) == _character then -- if its meeee
			return is_downed
		end
	end)
end