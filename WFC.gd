extends Node2D
const directions = [[1,0],[-1,0],[0,-1],[0,1]]
const dir_keys = ["posX","negX","posY","negY"]
@export var map_width = 10
@export var map_height = 10
# Called when the node enters the scene tree for the first time.
func _ready():
	var success = generate_map(map_width,map_height)
	while(!success):
		success = generate_map(map_width,map_height)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func list_intersect(list1, list2):
	var intersection = []
	
	for val in list1:
		if list2.has(val):
			intersection.append(val)
	
	return intersection

func list_min(list):
	if list.is_empty():
		return 0
		
	var min_val = list[0]
	for x in range(1,list.size()-1):
		min_val = min(min_val, list[x])
	return min_val
	
func parse_json():
	var file = FileAccess.open("res://tileConnectors.json", FileAccess.READ)
	var json = JSON.new()
	var parse_err = json.parse(file.get_as_text())
	var connectors = json.get_data()
	return connectors

func generate_adj(json_data):
	var connectors = json_data
	var num_tiles = connectors.size()
	var adjacencies = {}
	for tile_ind in num_tiles:
		var adjDict = {}
		adjDict["posX"] = {}
		adjDict["negX"] = {}
		adjDict["posY"] = {}
		adjDict["negY"] = {}
		adjacencies[tile_ind] = adjDict
	#print(adjacencies)
	for tile_ind1 in num_tiles:
		for tile_ind2 in num_tiles:
			var key1 = "t"+str(tile_ind1)
			var key2 = "t"+str(tile_ind2)
			var x_val1 = connectors[key1]["posX"]
			var x_val2 = connectors[key2]["negX"]
			if !connectors[key1]["avoid"]["posX"].has(key2) && x_val1 == x_val2:
			#if x_val1 == x_val2:
				adjacencies[tile_ind1]["posX"][tile_ind2] = tile_ind2
				adjacencies[tile_ind2]["negX"][tile_ind1] = tile_ind1
				
			var y_val1 = connectors[key1]["posY"]
			var y_val2 = connectors[key2]["negY"]
			if !connectors[key1]["avoid"]["posY"].has(key2) && y_val1 == y_val2:
			#if y_val1 == y_val2:
				adjacencies[tile_ind1]["posY"][tile_ind2] = tile_ind2
				adjacencies[tile_ind2]["negY"][tile_ind1] = tile_ind1
	return adjacencies
	

func generate_map(width, height):
	var json_data = parse_json()
	
	var adjacencies = generate_adj(json_data)
	var wave = {}
	var entropy = {}
	var num_tiles = adjacencies.size()
	
	for i in width*height:
		wave[i] = range(num_tiles)
		entropy[i] = num_tiles
	
	#Collapse a single cell in the wave at random
	#print(wave)
	var e_min_ind = height*(width-1)
	var ind = 6
	wave[e_min_ind].clear()
	wave[e_min_ind].append(ind)
	entropy.erase(e_min_ind)
	
	#Minimum entropy in wave, used to see if fully collapsed
	var e_min = INF
	
	#Stack of cells to update wave for when changes are made
	var stack = [e_min_ind]
	
	while e_min > 0:
		
		while(!stack.is_empty()):
			
			var curr_ind = stack.pop_back()
			
			for dir_ind in directions.size():
				var x = (curr_ind%width + directions[dir_ind][0])%width
				var y = (curr_ind/width + directions[dir_ind][1])%height
				
				var neighbor_ind = x+y*width
				
				if entropy.has(neighbor_ind):
					var possible = {}
					for pattern in wave[curr_ind]:
						for adjacent_pattern in adjacencies[pattern][dir_keys[dir_ind]]:
							possible[adjacent_pattern] = adjacent_pattern
					
					var intersection = list_intersect(possible.keys(), wave[neighbor_ind])
					if intersection.is_empty():
						print("Contradiction")
						return false
						
					if intersection.size() < wave[neighbor_ind].size():
						wave[neighbor_ind] = intersection
						entropy[neighbor_ind] = intersection.size()
						stack.append(neighbor_ind)
		
		e_min = list_min(entropy.values())
		if e_min != 0:
			e_min_ind = entropy.find_key(e_min)

			var collapse_val = wave[e_min_ind][randi_range(0,wave[e_min_ind].size()-1)]
			wave[e_min_ind].clear()
			wave[e_min_ind].append(collapse_val)
			stack.append(e_min_ind)
			entropy.erase(e_min_ind)
		
	for wave_ind in width*height:
		var x = wave_ind%width
		var y = int(wave_ind/width)
		var tile_ind = wave[wave_ind][0]
		var json_ind = "t"+str(tile_ind)
		var atlas_x = json_data[json_ind]["atlasX"]
		var atlas_y = json_data[json_ind]["atlasY"]
		
		$TileMap.set_cell(0,Vector2i(x,y),0,Vector2i(atlas_x,atlas_y))
	return true
