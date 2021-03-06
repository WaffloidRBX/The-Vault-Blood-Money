--[[
	@24/4/16
	@axel-studios
	@the-vault-blood-money
	@waffloid
--]]


math.randomseed(math.sin(tick())*tick())

local _replicated_storage = game.ReplicatedStorage
local _assets = _replicated_storage.Assets
local _network = _replicated_storage.Network
local _room = workspace.Rooms.room
local _free = workspace.Rooms.free

local pathfinding_service = game:GetService('PathfindingService')


local called = {}
local remote_functions = {}
local event = {}
local named_events = {}
local vector = {}
local cframe = {}
local action = {}
local downed_players = {}
local behavior_matrix = {}
local brain = {communication={},interaction={}}
local layers = {_assets.layer1,_assets.layer2,_assets.layer3}
local ignore = {workspace.Ignore_Folder,workspace.ActivePoints,workspace.Interactive.Civilian,workspace["Guard spots"],workspace.Guards,workspace["A*"],workspace.AmbushSpot,workspace["Tear gas spots"]}
local spawns = {'41','42','43','44','63','62'}
local faces = {[Vector3.new(0, 1, 0)]='Top',[Vector3.new(0, -1, 0)]='Bottom',
	[Vector3.new(0, 0, -1)]='Front',[Vector3.new(0, 0, 1)]='Back',[Vector3.new(-1, 0, 0)]='Left',[Vector3.new(1, 0, 0)]='Right'}
local interaction_list = {}
local named_events = {}
local pseudo_character = {}
local total = {}
local matrix = {}
local cuffed_npcs = {}
local emotions = {}
local blacked_out_npcs = {}
local nodes = {}
local enemies_firing = {}
local damage_dealt = {}

local dist_threshold = 10^-7
local movement_threshold = 30
local downed_health_threshold = 10
local danger = 1
local civilians = 0
local enemy_count = 0
local bag_money_cap = 10000
local total_money = 0

local sound 
local heisters_noticed
local flashbang

local speed = Vector3.new(14,50,14)
local vision = (Vector3.new(0,0,1)-CFrame.Angles(0,math.rad(40),0).lookVector).Magnitude

local function index_table(tab,real_tab)
	real_tab = real_tab or ''	for i,v in pairs(tab) do
		--(real_tab,i,":",v)
		if type(v) == 'table' then
			index_table(v,real_tab..'	')
		end
	end
end
local function angle(cframe)
	return cframe - cframe.p
end

local function raycast(start,finish,ignorelist)
	local ray = Ray.new(start,finish-start)
	return workspace:FindPartOnRayWithIgnoreList(ray,ignorelist or ignore)
end
local function get_face(v)
	local mag = math.huge
	local return_face
	for pos,face in pairs(faces) do
		if (pos-v).Magnitude < mag then
			mag = (pos-v).Magnitude
			return_face = face
		end
	end
	return return_face
end

local specific = {see={'heister','sgunshot','dead_body','suspicious','scared_civ'},hear={'hgunshot','scream'},smell={'laughing_gas','tear_gas'},feel={'torso_pain','legs_pain','head_pain'},}
--									pain sadness fear
local desired = {heister=Vector3.new(0.5,  0.5,   4),dead_body=Vector3.new(.5,3,3),sgunshot=Vector3.new(0.5,.5,3),suspicious=Vector3.new(0.5,0.5,1),scared_civ=Vector3.new(0.5,0.5,2),
	hgunshot=Vector3.new(0.5,0.5,3),scream=Vector3.new(0.5,0.5,.5),laughing_gas=Vector3.new(0,-10,-2),tear_gas=Vector3.new(1,.6,1),
	torso_pain=Vector3.new(5,.6,1),legs_pain=Vector3.new(3,.6,1),head_pain=Vector3.new(5,.6,2)} -- ouch

local val = Vector3.new(.5,.5,.5)



local function clone(t)
	local new = {}
	for i,v in pairs(t) do
		new[i]=v
	end
	return new
end

local function get_obj(real_model)
	local model
	for w in string.gmatch(real_model,'%w+') do
		if not model then
			model = workspace
		else
			if #model:GetChildren() >= 1 then
				if not model:FindFirstChild(w) then
					local _,last_index = real_model:find(w)
					model = model:FindFirstChild(real_model:sub(last_index+2,#real_model))
				else
					model = model:FindFirstChild(w)
				end
			end
		end
	end
	return model
end

local function visible(start,finish)
	local lookVector = CFrame.new(start.p,finish).lookVector
	local magnitude = (start.lookVector-lookVector).Magnitude
	if magnitude < 1.1471529006958 then
		return true
	end
end

local function cone_vision(start,finish,ignorelist)
	if visible(start,finish) then
		local hit,pos,id=raycast(start.p,finish,ignorelist)
		if hit then
			return hit,pos,id
		end
	end
end

local function add_new_stimulant(name,obj)
	local specific = workspace.Stimulant[name]
	local value
	for i,v in pairs(specific:GetChildren()) do
		if (not v.Value) or (v.Value == obj) then
			value = v
			break
		end
	end
	value = value or Instance.new('ObjectValue')
	value.Parent = specific
	value.Name = obj.Name
	value.Value = obj
end

local function remove_stimulant(name,obj)
	local specific = workspace.Stimulant[name]
	for i,v in pairs(specific:GetChildren()) do
		if v.Value == obj then
			v.Value = nil
		end
	end
end







--@math module
do
	-- vector
	
	function vector.absolute(v) 
		return Vector3.new(math.abs(v.X),math.abs(v.Y),math.abs(v.Z)) 
	end
	
	function vector.lock_on_grid(vector,amnt)
		return Vector3.new(math.floor((vector.X * (1/amnt)) + 0.5) * amnt,math.floor((vector.Y * (1/amnt))+0.5) * amnt,math.floor((vector.Z * (1/amnt)) * amnt)+0.5)
	end 
	
	function vector.random(radius)
		local radius = (radius or 6)*math.sqrt(math.random())
		local angle = math.random()*math.pi
		return Vector3.new(math.sin(angle)*radius,0,math.cos(angle)*radius)
	end
	
	function vector.offset_clamp(offset,base_size,hole_size,num_offset)
		num_offset=num_offset or 0
		if tonumber(hole_size) then
			hole_size = Vector2.new(hole_size,hole_size)
		end
		local bounds_x = base_size.X/2 - hole_size.X/2
		local bounds_y = base_size.Y/2 - hole_size.Y/2
		
		return Vector3.new(math.max(math.min(bounds_x -num_offset,offset.X),-(bounds_x -num_offset)),
			math.max(math.min(bounds_y -num_offset,offset.Y),-(bounds_y -num_offset)),
			offset.Z
		)
	end
		
	-- cframe
	function cframe.spread(r)
		r = math.rad(r)
		return CFrame.Angles((math.random()*r)-(r/2),(math.random()*r)-(r/2),0)
	end
	
	function cframe.extract_angle(cf)
		return cf - cf.p
	end
	
	function cframe.set_norm(part,norm)
		local angle = cframe.extract_angle(part.CFrame):inverse() * CFrame.new(Vector3.new(),norm)
		part.CanCollide = false
		part.Size = vector.absolute((angle * CFrame.new(part.Size)).p) 
		part.CFrame = part.CFrame * angle
		part.CanCollide = true
	end
end


















--@networking/events
do
	_network.RemoteEvent.OnServerEvent:connect(function(plr,name,...)
		local event = named_events[name]
		if event then
			for i,v in pairs(event.connections) do
				if type(v) == 'function' then
					v(plr,...)
				else
					v:fire(plr,...)
				end
			end
		end
	end)

	_network.RemoteFunction.OnServerInvoke = function(player,name,...)
		return remote_functions[name](player,...)
	end

	function event.new(name)
		local event = {connections={}}
		function event:fire(...)
			--'send232')
			if name then
				--'sent')
				_network.RemoteEvent:FireAllClients(name,...)
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
			event:connect(function(...) local output = {condition(...)} 
				if output[1] then new_event:fire(...) end end)
		end
		if name then
			--'ok',name)
			named_events[name] = event
		end
		return event
	end
	
	remote_functions['Ping'] = function(time)
		return time,tick()
	end
end
--'networking crap loaded')

local objectives = event.new('Objectives')
local call_police = event.new()
sound = event.new()





















--@destruction module
do
	function create_hole(wall,real_radius,pos,thick,layers,offset_value,angle)
		--local angle = angle or CFrame.Angles(math.rad(math.random(2)*180),0,math.rad(math.random(2)*180))
		offset_value = offset_value or 0
		local broken_folder = Instance.new('Folder')
		broken_folder.Parent = workspace.Broken
		broken_folder.Name = wall.Parent.Name
		
		local radius = math.min(real_radius,wall.Size.X/2,wall.Size.Y/2) -- ENABLE THIS FOR CLAMPING
		if real_radius ~= radius then
			return
		end
		local offset = vector.offset_clamp(wall.CFrame:toObjectSpace(pos).p,wall.Size,radius*2)
		
		local top_size = Vector3.new(wall.Size.X,(wall.Size.Y/2)-(offset.Y + radius),wall.Size.Z)
		local top_pos = wall.CFrame * CFrame.new(0,(wall.Size.Y/2) - (top_size.Y/2),0)
		
		local bottom_size = Vector3.new(wall.Size.X,(wall.Size.Y/2) + (offset.Y - radius),wall.Size.Z)
		local bottom_pos = wall.CFrame * CFrame.new(0,(-wall.Size.Y/2) + (bottom_size.Y/2),0)
		
		local left_size = Vector3.new((wall.Size.X/2) + (offset.X - radius),radius * 2,wall.Size.Z)
		local left_pos = wall.CFrame * CFrame.new((-wall.Size.X/2 + (left_size.X/2)),offset.Y,0)
		
		local right_size = Vector3.new((wall.Size.X/2) - (offset.X + radius),radius * 2,wall.Size.Z)
		local right_pos = wall.CFrame * CFrame.new((wall.Size.X/2 - (right_size.X/2)),offset.Y,0)
	 
		
		local p = Instance.new('Part')
		p.Parent = broken_folder
		p.Anchored = true
		p.Material = wall.Material
		p.BrickColor = wall.BrickColor
		
		p.Size = top_size
		p.CFrame = top_pos
		
		if 0.01 > (top_size.Y) then
			p:Destroy()
		elseif 0.2 > (top_size.Y) then
			------print((top_size.Y)
			local mesh =Instance.new('BlockMesh')
			mesh.Parent = p
			mesh.Scale = Vector3.new(1,top_size.Y/.2,1)
		end
		
		p = Instance.new('Part')
		p.Parent = broken_folder
		p.Anchored = true
		p.Material = wall.Material
		p.BrickColor = wall.BrickColor
		
		p.Size = bottom_size
		p.CFrame = bottom_pos
		
		if 0.01 > (bottom_size.Y) then
			p:Destroy()
		elseif 0.2 > (bottom_size.Y) then
			------print((bottom_size.Y)
			local mesh =Instance.new('BlockMesh')
			mesh.Parent = p
			mesh.Scale = Vector3.new(1,bottom_size.Y/.2,1)
		end
		
		p = Instance.new('Part')
		p.Parent = broken_folder
		p.Anchored = true
		p.Material = wall.Material
		p.BrickColor = wall.BrickColor
		
		
		p.Size = left_size
		p.CFrame = left_pos
		if 0 > (left_size.Magnitude-p.Size.Magnitude) then
			p:Destroy()
		end
		
		p = Instance.new('Part')
		p.Parent = broken_folder
		p.Anchored = true
		p.Material = wall.Material
		p.BrickColor = wall.BrickColor
		
		p.Size = right_size
		p.CFrame = right_pos
		if 0 > (right_size.Magnitude-p.Size.Magnitude) then
			p:Destroy()
		end
		
		local x_y = CFrame.new(offset.X,offset.Y,0)
		local layers_deep = math.max(math.ceil(wall.Size.Z/thick)+offset_value,1)
		local real_layer_count = math.max(math.ceil(layers_deep / thick),1)
		
		if (wall.Size.Z%thick) < .2 then
			layers_deep = math.max(layers_deep-1,1)
		end
		layers_deep = math.min(layers_deep,#(layers or {1})+1)
		for layer = offset_value+1,layers_deep do
			local depth =  layer - offset_value
			if layer==(#(layers or {1}))+1 then
				local amnt = #(layers or {1})
				local part = Instance.new('Part',broken_folder)
				part.BrickColor = wall.BrickColor
				part.Material = wall.Material
				part.Anchored = true
				part.Parent = broken_folder
				part.Size = Vector3.new(radius*2,radius*2,wall.Size.Z - ((amnt-offset_value)*thick))
				part.CFrame = (wall.CFrame * x_y * CFrame.new(0,0,(wall.Size.Z - part.Size.Z)/2 -  thick*(amnt-offset_value)))
			elseif layers then
				local thickness
				if layers_deep==layer then
					if wall.Size.Z <= thick then
						--thickness = (wall.Size.Z%thick) + thick
					else
						--thickness = (wall.Size.Z%thick)
					end
					thickness = (wall.Size.Z%thick)
				else
					thickness = thick
				end
				local part = (layers[layer] or layers[#layers]):Clone()
				part.BrickColor = wall.BrickColor
				part.Material = wall.Material
				part.Parent = broken_folder
				part.Size = Vector3.new(radius*2,radius*2,thickness)
				part.CFrame = (wall.CFrame * x_y * CFrame.new(0,0,(wall.Size.Z-thickness)/2 - (thick * (layer-offset_value-1)))) * 
					CFrame.Angles(math.rad(math.random(2)*180),0,math.rad(math.random(2)*180)) -- angle
			end
		end
		return angle
	end
	
	function plont_c4(c4)
		local pos = c4.CFrame
		
		local ray = Ray.new(c4.Position,c4.CFrame.lookVector*3)
		local hit,position = workspace:FindPartOnRay(ray,c4)
		local wall
		
		if hit and hit:IsDescendantOf(workspace.walls) then
			if hit.Parent == workspace.walls then
				wall = hit
			else
				wall = hit.Parent
			end
		end
		
		if wall and wall:IsA("Folder") then
			for i,v in pairs(wall:GetChildren()) do
				cframe.set_norm(v,pos.lookVector)
				local size = v.Size--extract_angle(pos):toObjectSpace(CFrame.new(v.Size))
				local offset_vector = pos:toObjectSpace(v.CFrame)
				local offset = math.floor(math.abs(offset_vector.Z * .7) - (math.abs(size.Z)/2 - .35))
				v.Transparency = 1
				if v.Material.Value == Enum.Material.Concrete.Value then
					create_hole(v,6.1,pos,1.1,layers,offset)
				else
					create_hole(v,6,pos,1.1,layers,offset)
				end
			end
			wall:Destroy()
		else
			cframe.set_norm(wall,pos.lookVector)
			local size = wall.Size--extract_angle(pos):toObjectSpace(CFrame.new(v.Size))
			local offset_vector = pos:toObjectSpace(wall.CFrame)
			local offset = math.floor(math.abs(offset_vector.Z * 1.1) - (math.abs(size.Z)/2 - .35))
			if wall.Material.Value == Enum.Material.Concrete.Value then
				create_hole(wall,5.1,pos,1.1,layers,offset)
			else
				create_hole(wall,5,pos,1.1,layers,offset)
			end
			wall:Destroy()
		end
	end

	event.new('player shoot'):connect(function(_,hit,pos,norm)
		------print(('man just bussed a skeng')
		pos = vector.lock_on_grid(pos,1)
		------print((norm)
		if math.floor((norm.Y*10000) + 0.5)== 0 then
			------print(('dun kno')
			if hit and hit:IsA('Part') then
				cframe.set_norm(hit,-norm)
				local min_size = math.min(hit.Size.X,hit.Size.Y)
				if min_size >= .5 then
					hit.Transparency = 1
					create_hole(hit,.5,CFrame.new(pos),.5)
					local p = Instance.new('Part',workspace)
					p.Anchored = true
					p.Size = Vector3.new(.2,.2,.2)
					p.CFrame = CFrame.new(pos)
					game.Debris:AddItem(p,.4)
					hit:Destroy()
				elseif math.max(hit.Size.X,hit.Size.Y,hit.Size.Z) <= .5 then
					------print(('bruck up da ting')
					hit:Destroy()
				end
			--else
				--local p = Instance.new('Part',workspace)
				--p.Anchored = true
				--p.CFrame = CFrame.new(pos)
			end
		end
	end)
end





































 
--@init
do
	game.Players.PlayerAdded:connect(function(plr)
		local char = _assets.PlayerModel:Clone()
		char:SetPrimaryPartCFrame(workspace.Spawn_Point.CFrame+vector.random(5)+Vector3.new(0,2,0))
		char.Name = plr.Name
		plr.Character = char
		char.Parent = workspace.Heisters
		
		local gunshot = Instance.new('Sound')
		gunshot.SoundId = 'rbxassetid://356911785'
		gunshot.Name = 'Shoot'
		gunshot.Parent = char.Torso
		
		add_new_stimulant('heister',char.Head)
		add_new_stimulant('hgunshot',gunshot)
	end)
	
	local function customize_char(char)
	
		local char_model = game.ReplicatedStorage.NPC:Clone()
		char_model.Parent = workspace
		
		local aspects = {}
	
		
		for _,char in pairs(game.ReplicatedStorage.Character[char]:GetChildren()) do
			local children = char:GetChildren()
			if #children==1 then
				print('that shit is priceless')
				aspects[char.Name]=children[1]
			else
				aspects[char.Name]=children[math.random(#children)]
			end
		end
		
		for _,obj in pairs(char_model:GetChildren()) do
			if obj:IsA("BasePart") then
				obj.BrickColor=aspects.Color.Value
			end
		end
		
		local hair_part = aspects.Hair:Clone()
		hair_part.Parent = char_model
		
		hair_part.Motor6D.Part0 = char_model.Head
		hair_part.Name = 'Hair'
		
		char_model.Shirt.ShirtTemplate=aspects.Shirt.ShirtTemplate
		char_model.Pants.PantsTemplate=aspects.Pants.PantsTemplate
		
		return char_model
	end
	
	for i,v in pairs(workspace.CivilianSpawn:GetChildren()) do
		v:Destroy()
		local model =customize_char('Civilian')
		model:SetPrimaryPartCFrame(v.CFrame)
		model.Name = 'Civilian'
		
		model.Parent = workspace.Interactive.Civilian
	end
end


















local Ragdoll = {} -- thx based hexabone for this code im lazy
do
	Ragdoll.new = function(Character,dir)
		local Doll = _assets.Ragdoll:Clone()
		local ToCarry = {}
		for Index, Child in pairs (Character:GetChildren()) do
			if Child:IsA("BasePart") and Doll:FindFirstChild(Child.Name) then
				Doll[Child.Name].BrickColor = Child.BrickColor
			end
			if Doll:FindFirstChild(Child.Name) then
				local Children = Child:GetChildren()
				for Index, UberChild in pairs (Children) do
					UberChild.Parent = Doll[Child.Name]
				end
			end
			if Child:IsA("Shirt") or Child:IsA("Pants") or Child:IsA("Hat") or Child:IsA("BodyColors") or Child:IsA("CharacterMesh") or Child.Name == "Hair" then
				Child.Parent = Doll
				if Child.Name == 'Hair' and Child:FindFirstChild("Motor6D") then
					Child.Motor6D.Part0 = Doll.Head
				end
			end
		end
		Doll:SetPrimaryPartCFrame(Character.Torso.CFrame)
		Character:Destroy()
		Doll.Torso.Velocity = (dir or Doll.Torso.CFrame.lookVector)*-15
		Doll.Humanoid2.Sit = true
		Doll.Humanoid2.PlatformStand = true
		Doll.Parent = workspace
		spawn(function()
			wait(3)
			for i,v in pairs(Doll:GetChildren()) do
				if v:IsA("BasePart") then
					v.Anchored = true
				end
			end
		end)
		
		add_new_stimulant('dead_body',Doll.Torso)
	end
end





















--@AI module
do
	run_anim = event.new('run animation')
	
	local update_emotions = event.new('update emotions')
	update_emotions:connect(function(npc,emotion)
		emotions[npc]=emotion
	end)
	
	local function sigmoid(t)
		return 1/(math.exp(-t)+1)
	end

	function create_ai_model(tolerance,perceptor,brain,npc)

		local terminate

		local concious = 1
		
		local sensory = {}
		local delta = {}
		
		local short_term = {}
		local long_term = {}
		local to_long = {}
		
		local memory = {}
		
		setmetatable(memory,{
				__newindex = function(t,i,v)
					local to_long_val = (delta[i] or -6)
					if to_long_val then
						to_long[i] = (delta[i] or -6)
					end
					short_term[i]={v=v,t=tick()}
					long_term[i] = nil
				end,
				__index = function(t,i)
					if short_term[i] then
						if ((tick()-45) > short_term[i].t) then
							------print(('sok ye mom bled')
							if sigmoid((to_long[i] or -6) * (concious/2 + 0.5))>math.random() then
								------print((i,':',short_term[i].v,'has been inscribed into long term memory')
								long_term[i]=short_term[i]
								short_term[i]=nil
								return long_term[i].v
							else
								------print((i,':',short_term[i].v,'has been destroyed from short term memory')
								short_term[i]=nil
								return nil
							end
						else
							to_long[i] = (to_long[i] or -6) + .5
							return short_term[i].v
						end
					elseif long_term[i] then
						return long_term[i].v
					end
				end
			}
		)
		
		local function get_avg(v)
			local total = Vector3.new()
			for i,v in pairs(specific[v]) do
				local additional = 	(desired[v]- Vector3.new(.5,.5,.5)) * sigmoid(delta[v] * tolerance) + Vector3.new(.5,.5,.5)
				total = total + additional
			end
			return total/#specific[v]
		end
		
		local val = Vector3.new(.5,.5,.5)
		
		for i,v in pairs(desired) do
			delta[i] = -6
		end
		
		local total = Vector3.new()
		for i,v in pairs(specific) do
			sensory[i] = get_avg(i)
			total = total + sensory[i]
		end
		total = total/4

		spawn(function()
			wait(1)			
			run_anim:fire(npc,'Default')
			while not terminate do
				wait(1.2-concious)
				if not npc.Parent then
					return
				end
				perceptor(delta,concious,memory,npc) -- ski
				for i,v in pairs(delta) do
					if sigmoid(v) then
						if v > (memory[i] or -6) then
							memory[i]=v
							to_long[i]=v
						end
					end
				end

				local total = Vector3.new()
				for i,v in pairs(specific) do
					sensory[i] = get_avg(i)
					total = total + sensory[i]
				end
				total = total/4
				
				val = val:lerp(total,sigmoid( ((total-Vector3.new(0.5,0.5,0.5)) .Magnitude -.5) * 6 ) ^ 1.2)
				
				local old_value = emotions[npc] or Vector3.new(0.5,0.5,0.5)
				if (old_value-val).Magnitude > 0.05 then
					update_emotions:fire(npc,val,concious)
				end
				
				
				brain(val,memory,delta,npc)
			end
		end)

		return function()
			terminate = true
		end
	end
	local function civilian(em,mem,percept,npc)
		-- X = pain, Y = sadness, Z = fear. goes from 0-1, 0.5 being default
		spawn(function()
			if em.X > .7 then -- was hurt real badly
			
				--print('UUWAHAWU',em.X)
			elseif ((((em.Z - 0.55) * 4) + sigmoid(mem.scared_civ or -6))) > math.random() then	-- "ok, something feels suspicious"
				if not npc:FindFirstChild("can_call") then
					if ((em.Y+em.Z) / 2)^2 > (math.random() * 40) and not npc.Head.Sound.IsPlaying then
						npc.Head.Sound.SoundId='rbxassetid://540791978'
						npc.Head.Sound.TimePosition = 3.2
						npc.Head.Sound:Resume()
					end
					
					----print(((not mem.running_away) and (not cuffed_npcs[npc]))
					
					if npc.Name == 'Moving' then
						----print(('wow, lad.')
						npc.Humanoid.Sit = false
						npc.Humanoid:MoveTo(cuffed_npcs[npc].Torso.Position + (CFrame.new(cuffed_npcs[npc].Torso.Position,npc.Torso.Position).lookVector*5))
					elseif em.Z > 0.7 and (not cuffed_npcs[npc]) then -- ok fuck this if u move ull die
						mem.running_away = false
						npc.Humanoid:MoveTo(npc.Torso.Position)
						run_anim:fire(npc,'HandsUp') --npc.Humanoid.Sit = true
						mem.running_away = nil
					elseif (not mem.running_away) and (not cuffed_npcs[npc]) then
						mem.running_away = true
						npc.Humanoid.Sit = false
						mem.running_away = npc.Humanoid.WalkToPoint -- so it remembers that mr civ is running away
						add_new_stimulant('scared_civ',npc.Torso)
						----print(('RUUUUUUUUUUN')
						local node = get_nearest_node(npc.Torso)
						if node then
							local path = A_star(node,nodes['2'])
							follow_path(npc,path)
						end
					end
				else
					call_police:fire()
				end
			end
		end)
	end
	
	local function police_officer(em,mem,percept,npc)

		if percept['heister'] then
			for i,v in pairs(workspace.Stimulant.heister:GetChildren()) do
				if v.Value and v.Value.Parent then
					local hit = cone_vision(npc.Head.CFrame,v.Value.Position)
					if hit == v.Value then
						
					end
				end
			end
		end
	end
	
	local function perceptor(delta,concious,memory,npc)
		for i,v in pairs(delta) do
			delta[i] = math.max( ((v + 6) * 0.3) - 6,-6)
		end
		for i,sense in pairs(specific.see) do
			local tab = workspace.Stimulant[sense]
			for i,v in pairs(tab:GetChildren()) do
				if v.Value then
					local hit = cone_vision(npc.Head.CFrame,v.Value.Position)
					if hit == v.Value then
						delta[sense] = delta[sense] + (concious * 8) -- rip doesnt output actual obj, gross of me ik im sorry :(
					end
				end
			end
		end
		for i,sense in pairs(specific.hear) do
			local tab = workspace.Stimulant[sense]
			for i,v in pairs(tab:GetChildren()) do
				if v.Value and v.Value.Parent then
					if v.Value.Playing then
						local d = ((v.Value.Volume * 200) /  math.max(((npc.Head.Position-v.Value.Parent.Position).Magnitude/10)^2,1)) - 6
						if d ~= 'nan' then
							delta[sense] = d
							------print((delta[sense])
						end
					else
						delta[sense] = -6 -- fix dis bled
					end
				end
			end
		end
		for i,sense in pairs(specific.smell) do
			local tab = workspace.Stimulant[sense]
			for i,v in pairs(tab:GetChildren()) do
				if v.Value then
					delta[sense] = -(1/math.max(((npc.Head.Position-v.Value.Position).Magnitude/10)^2,1))/6 + 6
					------print((delta[sense],'control the game whenver he snap')
				end

			end
		end -- ik gross copy and paste :(
		
		--pain ennit
		for i,v in pairs(damage_dealt) do
			--print(i,v.torso_pain,'yea if u say so')
		end
		if damage_dealt[npc] then
			for i,sense in pairs(specific.feel) do
				local feel = damage_dealt[npc][sense] or -10
				delta[sense] = feel
				--print(feel,'these MCs better lay off the rocks')
			end
		end
	end
	------print(('usual standard BLED')
	for i,v in pairs(workspace.Interactive.Civilian:GetChildren()) do
		if v.Name == 'Civilian' then
			add_new_stimulant('scream',v.Head.Sound)
			create_ai_model(1,perceptor,civilian,v) -- REPLACE SKI
		end
	end
	
	--create_ai_model(1,perceptor,police_officer,workspace.NPC.Cop)
	
	
end




















--@action module
do
	local shoot_event = event.new('shoot')

	local downed_event = event.new('downed')
	local ragdoll_event = event.new('ragdoll')
	
	downed_event:connect(function(name,value)
		downed_players[name] = value
	end)
end















--@interaction module
do
	class = {}

	local opened_doors = {}
	
	local picked_up_drill
	local client_open_door = event.new('Client open door')
	local client_close_door = event.new('Client close door')
	
	--[[if door.Name == 'Opened' then
				client_close_door:fire(obj)
				door.Name = 'Closed'
				opened_doors[door] = true
			elseif door.Name == 'Closed' then
				client_open_door:fire(obj)
				door.Name = 'Opened'
				opened_doors[door] = nil]]
	
	--civilian
	do
		class.Civilian = {}
		function class.Civilian:is_interactive(plr,civ)
			print(civ)
			if civ.Name == 'Civilian' then
				return {'cuff civilian',true,2}
			elseif civ.Name == 'Cuffed' then
				cuffed_npcs[civ] = plr
				return {'move civliian',true,0.2}
			elseif civ.Name == 'Moving' then
				return {'stop moving civilian',true,0.2}
			end
		end
		
		function class.Civilian:interact(plr,civ)
			if civ.Name == 'Civilian' then
				cuffed_npcs[civ] = true
				civ.Humanoid:MoveTo(civ.Torso.Position)
				civ.Name = 'Cuffed'
				run_anim:fire(civ,'Cuffed',nil,6)
			elseif civ.Name == 'Cuffed' then
				civ.Name = 'Moving'
			elseif civ.Name == 'Moving' then
				civ.Name = 'Cuffed'
			end
		end
	end
	
	--door
	do

		class.Door = {}
		function class.Door:is_interactive(plr,door)
			local time = 1 + math.random()

			if door.Name == 'Opened' then
				return {'close door',true,0.5}
			elseif door.Name == 'Closed' then
				return {'open door',true,0.5}
			else
				if door.Name == 'Heavy' then
					time = time + 2
				end
				return {'pick lock',true,time}
			end
		end
		
		function class.Door:interact(plr,door)
			--print('ay TAWNI, OPEN DA DAAAAAR')
			if door.Name == 'Opened' then
				client_close_door:fire(door)
				door.Name = 'Closed'
				opened_doors[door] = true
				for i,v in pairs(door:GetChildren()) do
					v.CanCollide = true
				end
				
			elseif door.Name == 'Closed' then
					client_open_door:fire(door)
					door.Name = 'Opened'
					opened_doors[door] = nil
				else
				client_open_door:fire(door)
				opened_doors[door] = true
				door.Name = 'Opened'
				for i,v in pairs(door:GetChildren()) do
					v.CanCollide = false
				end
			end
		end
	end

	-- bag
	do
		local bags_state = {}
		local welds = {}
		
		class.Bag = {}
		function class.Bag:is_interactive(plr,obj)
			if not bags_state[obj.Name] and not welds[plr.Name] then -- if no one has bag
				return {'pick up bag',true,.2} -- message is put on billboard gui, on obj.
			elseif bags_state[obj.Name] == plr then
				return 
		{'press g to drop the bag. you cannot interact with anything, or s-- until you have dropped the bag.',
					false,.2} 
				-- message is not put on billboard gui, put on msg instead
			else
				--(obj.Name,bags_state[obj.Name])
			end
		end

		function class.Bag:interact(plr,obj)
			plr = plr.Character
			if not bags_state[obj.Name] and not welds[plr.Name] then
				if obj.Name == 'ThermalBag' and not picked_up_drill then
					picked_up_drill = true
					objectives:fire('Take your bag to the vault')
				end
				------print((obj,'n15')
				bags_state[obj.Name] = plr
				obj.CanCollide = false
				local weld = Instance.new('ManualWeld',plr)
				welds[plr.Name] = weld
				weld.Part0 = plr.Torso
				weld.Part1 = obj
				weld.C1 = CFrame.new(0,0,-.5 - obj.Size.Z/2) * CFrame.Angles(0,0,math.rad(math.random(60,120)))
			elseif bags_state[obj.Name] == plr then
				if welds[plr.Name] then
					obj.CanCollide = true
					welds[plr.Name]:Destroy()
					welds[plr.Name] = nil
					bags_state[obj.Name] = nil
				end
			end
		end
	end
	
	--drill
	do
		local drill
		
		class.Drill = {}
		function class.Drill:is_interactive(plr,obj)
			if (obj).Name == 'ThermalBag' then
				return {'set up drill',true,1}
			elseif (obj).Name == 'Jammed' then
				return {'fix drill',true,1}
			end
		end
		
		function class.Drill:interact(plr,obj)
			if (obj).Name == 'ThermalBag' then
				if heisters_noticed then
					objectives:fire('Protect the thermal drill')
				else
					objectives:fire('Wait for the vault to open')
				end
				obj:Destroy()
				drill = _assets.ThermalDrill
				drill.Parent = workspace.Interactive.Drill
			elseif (obj).Name == 'Jammed' then
				--print('young strapped and i JUST DONT GIVE A FUCK')
				drill.Name = 'ThermalDrill'
			end
		end
	end
	
	--dead npcs
	do
		class.Dead = {}
		function class.Dead:is_interactive(plr,obj)
			if obj.Name:find('Guard') then
				return {'answer pager',true,3}
			else
				return {'use body bag',true,1}
			end
		end
		
		local existing_bags = 0
		local existing_pagered = 0
		function class.Dead:interact(plr,obj)
			if obj.Name:find('Guard') then
				existing_pagered = existing_pagered + 1
				obj.Name = 'Interactive_Dead_Pagered'..existing_pagered
			else
				existing_bags = existing_bags + 1
				local center = obj:GetModelCFrame()
				local bag = _assets.BodyBag:Clone()
				bag.Parent = workspace.Interactive
				
				obj:Destroy()
				bag.Name = 'Interactive_Bag_Body Bag'..existing_bags
				bag.CFrame = center
			end
		end
	end
	
	--money
	do
		class.Money = {}
		
		function class.Money:is_interactive(plr,obj)
			return {'bag the money',true,1}
		end
		
		local existing_bags = 0
		function class.Money:interact(plr,obj)
			existing_bags = existing_bags + 1
			local center = obj:GetModelCFrame()
			local bag = _assets.MoneyBag:Clone()
			bag.Parent = workspace.Interactive.Bag
			
			obj:Destroy()
			bag.Name = 'MoneyBag'..existing_bags
			bag.CFrame = center
			add_new_stimulant('suspicious',bag) -- AIs will now be aware of this as a suspicious item
		end
	end

	remote_functions['interactive'] = function(plr,spec_class,object)
		if plr.Character.Humanoid.Health > 0  and plr.Character:FindFirstChild('Torso') then
			return class[spec_class]:is_interactive(plr.Character,object)
		end
	end

	event.new('interact'):connect(function(plr,spec_class,object,...) 
		if plr.Character.Humanoid.Health > 0  and plr.Character:FindFirstChild('Torso') then
			if class[spec_class]:is_interactive(plr.Character,object,...) then
				class[spec_class]:interact(plr,object,...)
			end
		end
	end)
end

















--@gamelogic
do
	
	local _interactive = workspace.Interactive
	
	local is_vault_open = false
	
	local vault_opened = event.new('Vault opened')
	local narration = event.new('narration')
	local police_assault = event.new('police assault')
	local spotted = event.new('Spotted')


	local broke_light = event.new('Broke light')
	local client_broke_light = event.new('Client broke light')

	local broke_glass = event.new('Broke glass')
	local client_broke_glass = event.new('Client broke glass')
	
	broke_light:connect(function(_,light)
		client_broke_light:fire(light) -- so that clients can all locally render
	end)
	
	broke_glass:connect(function(_,glass)
		client_broke_glass:fire(glass)
		wait()
		glass:Destroy() -- for vaulting maybe?
	end)
	
	event.new('Gunshot'):connect(function(plr,hit,pos,id)
		if hit and hit:IsDescendantOf(workspace.Interactive.Civilian) then
			if hit.Parent:FindFirstChild("Humanoid") then
				local damage = 10
				if hit.Name == 'Torso' or hit.Name == 'Head' then
					damage = 30
				end
				local ragga_doll
				local name = hit.Name
				local face = get_face(((hit.CFrame-hit.Position):inverse() * CFrame.new(Vector3.new(),id)).lookVector)
				print(hit,hit:FindFirstChildOfClass("SpecialMesh"))
				face = face
				
				local ray = Ray.new(hit.Position,Vector3.new(0,-10,0))
				local floor,pos,norm = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				if floor.Name ~= 'Blood piece' then
					print('SHOWERIN BARS')
					local blood_piece = Instance.new('Part')
					blood_piece.Name = 'Blood piece'
					local splatter = _assets.FloorSplatter:Clone()
					blood_piece.Anchored = true
					blood_piece.Parent = workspace
					blood_piece.Size = Vector3.new(8 * (damage/30),0.2,8 * (damage/30))
					blood_piece.CFrame = (CFrame.new(pos) * CFrame.new(Vector3.new(),norm) * CFrame.Angles(math.rad(-90),0,0)) - Vector3.new(0,.09,0)
					blood_piece.Transparency = 1
					splatter.Parent = blood_piece
				else
					local extent = damage/30
					local cf = floor.CFrame
					floor.Size = floor.Size + Vector3.new(extent,0,extent)
					floor.CFrame = cf
				end
				if hit.Name == 'Torso' or hit.Name == 'HumanoidRootPart' then -- issa torso hit
					 -- do dmg system not just var
					if hit.Parent.Humanoid.Health-damage <= 0 then
						ragga_doll=Ragdoll.new(hit.Parent,-CFrame.new(plr.Character.Torso.Position,pos).lookVector)
					else
						hit.Parent.Humanoid.Health = hit.Parent.Humanoid.Health - damage
					end
					
					damage_dealt[hit.Parent] = damage_dealt[hit.Parent] or {}
					damage_dealt[hit.Parent]['torso_pain'] = 6
					hit.Parent.Humanoid.Sit = true
					hit.Velocity = CFrame.new(plr.Character.Torso.Position,pos).lookVector*15
					hit.RotVelocity = Vector3.new(5,0,0)
					--print(hit.Parent:GetFullName(),'nigg')
					hit.Parent.Head.Sound.SoundId = 'rbxassetid://521472470'
					hit.Parent.Head.Sound:Resume()
					print('why')
					if not cuffed_npcs[hit.Parent] then
						if hit.Parent.Torso.CFrame:toObjectSpace(CFrame.new(pos)).Y - .15 > 0 then
							run_anim:fire(hit.Parent,'ChestHit',nil,4) -- rip :(
						else
							run_anim:fire(hit.Parent,'StomachHit',nil,5)
						end
					end
				elseif hit.Name == 'Head' then
					ragga_doll=Ragdoll.new(hit.Parent,-CFrame.new(plr.Character.Torso.Position,pos).lookVector)
				end
				
				if ragga_doll then
					hit = ragga_doll:FindFirstChild(name)
				end
				
				print(hit,name,face)
				
				if not hit:FindFirstChildOfClass('SpecialMesh') then
					local ui = hit:FindFirstChild(face) or Instance.new('SurfaceGui')
					ui.CanvasSize = Vector2.new(hit.Size.X*100,hit.Size.Y*100)
					ui.Parent = hit
					ui.Name = face
					ui.Face = face
					local splatter = Instance.new('ImageLabel')
					splatter.BackgroundTransparency = 1
					splatter.Image = 'rbxassetid://256293532'
					splatter.Size = UDim2.new(1,0,ui.CanvasSize.X/ui.CanvasSize.Y,0)
					splatter.Position = UDim2.new(0,0,(1-(ui.CanvasSize.X/ui.canvasSize.Y)) * math.random(),0)
					splatter.Parent = ui
				else
					local decal = Instance.new('Decal')
					decal.Parent = hit
					decal.Face = face
					decal.Texture = 'rbxassetid://256293532'
				end
				
				
			end
		end
		add_new_stimulant('sgunshot',plr.Character.Torso)
		plr.Character.Torso.Shoot:Play()
		------print(('puh pew!')
		wait(.3)
		remove_stimulant('sgunshot',plr.Character.Torso)
	end)
	
	local police_assault = event.new()
	
	call_police:condition(police_assault,function()
		if not heisters_noticed then
			heisters_noticed = true
			workspace.Music:Play()
			return true
		end
	end)
	
	police_assault:connect(function()
		print('FEDS TURNIN UP')
	end)
	
	workspace.Interactive.BagArea.Touched:connect(function(hit)
		if hit:FindFirstChild("Money") then
			if hit.Money.Value <= bag_money_cap then
				repeat wait() until hit.CanCollide
				if (hit.Position-workspace.Interactive.BagArea.Position).Magnitude <= 23 then
					total_money = total_money + hit.Money.Value
					hit.Money:Destroy()
					hit.Name = 'Used Moneybag'
					wait(2)
					hit.Anchored = true
					hit.CanCollide = false
				end
			else
				--BANISHED TO OGGYLAND RARARARARAR
			end
		end
	end)
	
	_free.Touched:connect(function(hit)
		if hit:IsDescendantOf(workspace.Interactive.Civilian) then
			hit.Parent:Destroy()
			call_police:fire()
		end
	end)
	
	vault_opened:connect(function(player)
		objectives:fire("Steal the money in the vault")
		if not player then -- if a player opens it it means that they C4/tripmine'd it open
			_interactive.Vault:Destroy()
		end
	end)
	
	spotted:connect(function()
		narration:fire("Police assault should be coming soon. They'll be here in around 30 seconds.")
		wait(math.random(28,32))
		police_assault:fire(true)
		for real_wave = 1,2 + danger do
			wave(real_wave)
			wait((civilians)*5+10)
			police_assault:fire(false)
		end
	end)
	
	_assets.ThermalDrill.Changed:connect(function(v)
		--(v,'44 in the 4 door')
		if _interactive.Drill:FindFirstChild('ThermalDrill') then
			for i = 5,0,-1 do	
				--('onli'..i..'seconds left')
				wait(1)
				if math.random(1,3) == 1 then
					------print(('k')
					_interactive.Drill.ThermalDrill.Name = 'Jammed'
					_interactive.Drill:WaitForChild('ThermalDrill')
				end
			end
			vault_opened:fire()
		end
	end)
	
	local enemys = {'Cop','Cop','SWAT'}
	local limit = 30 + danger * 5
	-- add in specific vehicles spawn too!!!!!!!
	function wave(specific_wave)
		for _ = 1,(math.random(10+(specific_wave*5)))/3.5 do -- rough enemy count
			local enemy = enemys[math.min(math.random(specific_wave),#enemys)]
			local spawn_children = workspace.Spawn:FindFirstChild(enemy):GetChildren()
			local spawn = spawn_children[math.random(#spawn_children)].Position
			for i = 1,math.random(3,5) do
				if enemy_count <= limit then
					enemy_count = enemy_count + 1
					local enemy_body = game.ReplicatedStorage.Assets:FindFirstChild(enemy):Clone()
					enemy_body.Parent = workspace.Enemys:FindFirstChild(enemy)
					enemy_body:SetPrimaryPartCFrame(CFrame.new(spawn + vector.random()) * CFrame.new(0,2,0))
					brain[enemy:lower()](enemy_body)
					enemy_body.Name = enemy..#workspace.Enemys[enemy]:GetChildren()
					wait(.2)
				end
			end
			wait(2 + (2/specific_wave))
		end
	end
	
	
	
	for _,heister in pairs(workspace.Heisters:GetChildren()) do
		local new_sound = Instance.new('Sound',heister['Right Leg'])
		
		local value = Instance.new('ObjectValue',workspace.Sound)
		value.Name = 'heister'
		value.Value = new_sound

		heister['Right Leg'].Touched:connect(function(hit)
			local material
			--hit:GetFullName())
			if hit == workspace.Terrain or hit.Name =='Terrain' then
				local pos = heister['Right Leg'].Position - Vector3.new(0,4,0) 
				local corner1 = pos + Vector3.new(2,2,2)
				local corner2 = pos - Vector3.new(2,2,2)
				local region = Region3.new(corner2,corner1):ExpandToGrid(4)
				
				material =workspace.Terrain:ReadVoxels(region,4)[1][1][1]
				
				--'NOBODY MAYD MEE')
			else
				material =hit.Material
			end
			--new_sound.SoundId = sounds[material.Value] or ''
		end)
	end
	
	

	--A* module
	do
		local color_delay = {
			Black=function() 
				return 4*16 
			end,
			['Dark stone grey'] = function(node,npc)
				local glass = workspace:FindFirstChild('glass'..node.real_node.Name)
				if glass then
					return 0.5 * 16
				else
					return 0
				end
			end,
			['Really red'] = function(node,npc)
				if node:FindFirstChild("Door") and node.Door.Value.Parent.Name ~= 'Opened' then
					return 1 * 16
				end
			end,
			['Navy blue'] = function(node,npc)
				if node:FindFirstChild("Glass") and node.Glass.Value then
					return .3 * 16
				end
			end
		}	
		local passed_node = {
			Black=function() 
				--'FIRE IN THE HOLE') 
				wait(4) 
				if workspace:FindFirstChild('Door') then 
					workspace.Door:Destroy() 
				end 
			end,
			
			['Dark stone grey']=function(node,npc)  
				local glass = workspace:FindFirstChild('glass'..node.real_node.Name) 
				--'SKKKKRRRTT')
				if glass then
					wait(.5)
					glass:Destroy()
				end
				npc.Humanoid.Jump = true
			end,
			['Really red'] = function(node,npc)
				if node.Door.Value.Parent.Name ~= 'Opened' then
					wait(1)
					class.Door:interact(npc,node.Door.Value.Parent)
				end
			end,
			['Navy blue'] = function(node,npc)
				if node:FindFirstChild("Glass") and node.Glass.Value then
					--npc.Humanoid:MoveTo(npc.Torso.Position)
					wait(0.3)
					if node.Glass.Value then
						broke_glass:fire(nil,node.Glass.Value)
						node.Glass.Value = nil
						npc.Humanoid.Jump = true
					end
				end
			end
		}
	
		local function leng(x)
			local len = 0
			for i,v in pairs(x) do
				len = len + 1
			end
			return len
		end
		
		local function reverse(t)
			local new = {}
			local len = leng(t)
			for i = 1,len do
				new[i] = t[len-i+1]
			end
			return new
		end
		
		function A_star(start,finish,...)
			local open_set = {}
			local closed_set = {}
			local came_from = {}
			
			local color_offset = 0
			if color_delay[start.real_node.BrickColor.Name] then
				color_offset = color_delay[start.real_node.BrickColor.Name](start.real_node) or 0
			end
			
			open_set[start] = true
			
			local g_score = {}
			local f_score = {}
			g_score[start] = 0
			f_score[start] = (start.position-finish.position).Magnitude  + color_offset-- + 0
			
			while leng(open_set) > 0 do
				local current
				local current_f_score = math.huge
				for node,_ in pairs(open_set) do
					local f_score = f_score[node]
					if f_score < current_f_score then
						current = node
						current_f_score = f_score
					end
				end
				
				open_set[current] = nil
				closed_set[current] = true
				
				
				if current == finish then
					local path = {finish}
					local last_node = finish
					repeat path[#path+1] = came_from[last_node] last_node = path[#path] until not came_from[came_from[last_node]]
					path[#path+1]=start
					return reverse(path)
				end
				
				for _,neighbor in pairs(current.neighbors) do
					if not (closed_set[neighbor]) then
						local color_offset = 0
						if color_delay[neighbor.real_node.BrickColor.Name] then
							color_offset = color_delay[neighbor.real_node.BrickColor.Name](neighbor.real_node,...) or 0
						end
							open_set[neighbor] = true
						local tentative_g_score = g_score[current] + (neighbor.position-current.position).Magnitude
						if not open_set[neighbor] then
							
							came_from[neighbor] = current
							g_score[neighbor] = tentative_g_score
							f_score[neighbor] = g_score[neighbor] + (neighbor.position-finish.position).Magnitude + color_offset
						elseif tentative_g_score < (g_score[neighbor] or math.huge) then
							came_from[neighbor] = current
							g_score[neighbor] = tentative_g_score
							f_score[neighbor] = g_score[neighbor] + (neighbor.position-finish.position).Magnitude + color_offset
						end
					end
				end
				
			end
		end
		
		function get_nearest_node(part)
			local pos = part.Position
			local nearest_mag
			local nearest_node
			local second_nearest_mag
			local second_nearest_node
			for i,v in pairs(workspace['A*']:GetChildren()) do
				if not nearest_node or nearest_mag > (v.Position-pos).Magnitude then
					nearest_mag = (v.Position-pos).Magnitude
					nearest_node = v
				elseif (not second_nearest_node or second_nearest_mag > (v.Position-pos).Magnitude) then
					second_nearest_mag = (v.Position-pos).Magnitude
					second_nearest_node = v
				end
			end
			local real_node
			local ray = Ray.new(pos,nearest_node.Position-pos)
			local hit,position = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
			if (position - nearest_node.Position).Magnitude <=3 then
				real_node = nearest_node
			else
				local ray = Ray.new(pos,second_nearest_node.Position-pos)
				hit,position = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				if (position - second_nearest_node.Position).Magnitude <=3 then
					real_node = second_nearest_node
				end
			end
			
			return nodes[real_node.Name]
		end
		
		local move = event.new('move')
		
		function follow_path(NPC,path,mem)
			
			move:fire(NPC,true)
			--mem.following_path = true
			
			for _,position in pairs(path) do
				NPC.Humanoid:MoveTo(position.position)
				local color_function = passed_node[position.real_node.BrickColor.Name]
				repeat 
					wait()
					if not NPC.Parent then
						return 
					end
					if position.position ~= NPC.Humanoid.WalkToPoint then
						--print('suttm')
						return 
					end
				until (position.position-NPC.Torso.Position).Magnitude <= 3 and (not color_function or not color_function(position.real_node,NPC))
			end
			
			mem.following_path = false
			move:fire(NPC)
		end
		
		function create_node(node)
			local evaluate = color_delay[node.BrickColor.Name]
			local passed = passed_node[node.BrickColor.Name]
			return {position=node.Position,neighbors={},real_node=node,passed_node=passed,evaluate=evaluate}
		end
		
		for i,v in pairs(workspace['A*']:GetChildren()) do
			nodes[v.Name] = create_node(v)
			
			nodes[v.Name].id = tonumber(v.Name)
		end
		
		for i,node in pairs(nodes) do
			for _,v in pairs(workspace['A*'][node.id]:GetChildren()) do
				if tonumber(v.Name) then
					node.neighbors[#node.neighbors+1] = nodes[v.Name]
				end
			end
		end
		
		wait(6)	
	end
	
	local end_screen = event.new('End screen')
	
	local sent_message_finish
	local first_met_requirement
	
	local heister_last_pos = {}
	
	local last_time = tick()
	
	local gun_fired = event.new('shoot')
	
	
	local amnt=0
	
	while wait(.1) do -- main loop, will handle everythin
		
		
		
		--dampen laughing gas
		for i,v in pairs(workspace["Laughing gas"]:GetChildren()) do
			v.exit.ParticleEmitter.Rate = math.max(v.exit.ParticleEmitter.Rate-0.5,0)
		end
		
		-- weapons loop
		do
			for npc_firing,data in pairs(enemies_firing) do
				if data.is_firing then
					------print(('foyrin')
					------print(((60/data.RPM),((data.last_shot or 0)-tick()))
					if ((60/data.RPM)-((data.last_shot or 0)-tick())) > 0 then
						data.last_shot = tick()
						------print(('SHOOOT')
					end
				end
			end
		end
		
		--sound loop
		do
			-- ADD CHILDADDED AND ALSO MAKE SURE THAT IF A PLAYER RESPAWNS IT IS DEALT WITH PROPERLY
			for _,heister in pairs(workspace.Heisters:GetChildren()) do
				local last_pos = heister_last_pos[heister:GetFullName()] or heister.Torso.Position
				local magnitude = (last_pos-heister.Torso.Position).Magnitude
				if magnitude > .05 then
					heister['Right Leg'].Sound.Volume = magnitude/16
					if not heister['Right Leg'].Sound.IsPlaying then
						heister['Right Leg'].Sound:Play()
					end
				else
					if heister:FindFirstChild('Right Leg') then
						if not heister['Right Leg']:FindFirstChild('Right Leg') then
							Instance.new('Sound',heister['Right Leg'])
						end
						heister['Right Leg'].Sound.Volume = magnitude/16
						heister['Right Leg'].Sound:Stop()
					end
				end
				heister_last_pos[heister:GetFullName()] = heister.Torso.Position
			end
			
			if (tick()- last_time) <= .5 then
				last_time = tick()
				for _,sound_fx in pairs(workspace.Sound:GetChildren()) do
					if sound_fx.Value.IsPlaying then
						sound:fire(sound_fx.Value.Volume,sound_fx.Value.Parent.Position,sound_fx.Name)
					end
				end
			end
		end
		
		-- bag touched loop
		do
			local thermal_bag = _interactive.Bag:FindFirstChild('ThermalBag')
			if thermal_bag then
				if (thermal_bag.Position-_interactive.VaultArea.Position).Magnitude < 8 and thermal_bag.CanCollide == true then
					------print(('DUN KNOOOO')
					objectives:fire("Set up the thermal drill")
					thermal_bag.Parent = workspace.Interactive.Drill
					wait(3)
					if _interactive.Drill:FindFirstChild("ThermalBag") then
						thermal_bag.Anchored = true
						thermal_bag.CanCollide = false
					end
				end
			end
		end
		
		--van stuff
		do
			local good_to_go
			if total_money >= 500 then
				if not sent_message_finish then
					sent_message_finish = true
					objectives:fire("Take more money or stay in van to finish the heist")
				end
				good_to_go = true
				for _,plr in pairs(game.Players:GetPlayers()) do
					local torso = plr.Character:FindFirstChild("Torso")
					if torso then
						local distance = (workspace.Interactive.BagArea.Position-torso.Position).Magnitude
						if distance > 20 then
							good_to_go = false
							first_met_requirement = nil
						end
					end
				end
			end
			if good_to_go and not first_met_requirement then
				first_met_requirement = tick()
			elseif good_to_go and (tick()-first_met_requirement) >= 10 then
				local monies_earned = (total_money + (heisters_in_custody or 0) * -5000 + (civilians_killed or 0) * -1000)
				if stealth then
					monies_earned = monies_earned * 1.2
				end
				end_screen:fire(total_money,heisters_in_custody or 0,
					civilians_killed or 0,stealth)
				--('END')
				break
			end
		end
	end
end