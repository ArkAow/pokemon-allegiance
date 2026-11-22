class_name SpriteLibrary
extends RefCounted

const PMD_DIRS: Array[String] = ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"]
const SCREEN_DIRS: Array[String] = ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"]
const MIRROR_OF := {"right": "left", "down_right": "down_left", "up_right": "up_left"}
const SPRITE_ROOT := "res://assets/pokemons/"
const TICKS_PER_SECOND := 60.0
const LOOPING: Array[String] = ["idle", "walk", "sleep", "eventsleep", "float", "laying", "sit", "deepbreath", "pull"]
const ALIASES := {
	"attack": ["attack", "strike", "swing"],
	"shoot": ["shoot", "charge", "attack"],
	"cast": ["shoot", "charge", "attack"],
	"charge": ["charge", "shoot", "attack"],
	"hurt": ["hurt", "pain", "cringe"],
	"die": ["faint", "hurt", "pain"],
}

static var _cache: Dictionary = {}
static var _portraits: Dictionary = {}


class Entry extends RefCounted:
	var frames: SpriteFrames
	var scale: float = 2.0
	var mirror: bool = false
	var folder: String = ""
	var lengths: Dictionary = {}
	var hit_times: Dictionary = {}
	var sizes: Dictionary = {}
	var files: Dictionary = {}
	var _anchors: Dictionary = {}
	var _heights: Dictionary = {}
	var fallback_height: float = 28.0

	func has_anim(anim: String) -> bool:
		return frames.has_animation(anim + "_down") or frames.has_animation(anim + "_left")


	func resolve(anim: String, dir: String) -> String:
		var d: String = dir
		if mirror and SpriteLibrary.MIRROR_OF.has(dir):
			d = SpriteLibrary.MIRROR_OF[dir]
		var candidates: Array = SpriteLibrary.ALIASES.get(anim, [anim])
		for c in candidates:
			var n: String = str(c) + "_" + d
			if frames.has_animation(n):
				return n
		if frames.has_animation("idle_" + d):
			return "idle_" + d
		return "idle_down"

	func needs_flip(dir: String) -> bool:
		return mirror and SpriteLibrary.MIRROR_OF.has(dir)

	func length(anim: String) -> float:
		return float(lengths.get(SpriteLibrary.base_of(resolve(anim, "down")), 0.0))

	func hit_time(anim: String) -> float:
		return float(hit_times.get(SpriteLibrary.base_of(resolve(anim, "down")), 0.0))

	func anchor_offset(anim_full_name: String) -> Vector2:
		var base: String = SpriteLibrary.base_of(anim_full_name)
		if _anchors.has(base):
			return _anchors[base]
		var off: Vector2 = Vector2(0, -fallback_height * 0.4)
		var size: Vector2i = sizes.get(base, Vector2i.ZERO)
		if folder != "" and size != Vector2i.ZERO:
			var feet: Vector2 = SpriteLibrary.find_feet(self, base)
			if feet.x >= 0.0:
				off = Vector2(size.x * 0.5 - feet.x, size.y * 0.5 - feet.y)
		_anchors[base] = off
		return off

	func body_height(anim: String = "idle") -> float:
		var base: String = SpriteLibrary.base_of(resolve(anim, "down"))
		if _heights.has(base):
			return _heights[base]
		var h: float = fallback_height
		if folder != "" and sizes.has(base):
			var used: Rect2i = SpriteLibrary.used_rect(self, base)
			var feet: Vector2 = SpriteLibrary.find_feet(self, base)
			if used.size.y > 0 and feet.x >= 0.0:
				h = maxf(12.0, feet.y - used.position.y)
		_heights[base] = h
		return h


static func get_entry(species_id: String) -> Entry:
	if _cache.has(species_id):
		return _cache[species_id]
	var e: Entry = _build(species_id)
	_cache[species_id] = e
	return e


static func base_of(full_name: String) -> String:
	return full_name.get_slice("_", 0)


static func dir_from_vector(v: Vector2) -> String:
	if v.length_squared() < 0.0001:
		return "down"
	var ang: float = fposmod(rad_to_deg(v.angle()), 360.0)
	var idx: int = int(roundf(ang / 45.0)) % 8
	return SCREEN_DIRS[idx]


static func get_portrait(species_id: String) -> Texture2D:
	if _portraits.has(species_id):
		return _portraits[species_id]
	var e: Entry = get_entry(species_id)
	var tex: Texture2D = e.frames.get_frame_texture("idle_down", 0)
	if tex == null:
		tex = _placeholder_texture(species_id)
	_portraits[species_id] = tex
	return tex


static func clear_cache() -> void:
	_cache.clear()
	_portraits.clear()


static func used_rect(e: Entry, base: String) -> Rect2i:
	var size: Vector2i = e.sizes.get(base, Vector2i.ZERO)
	var path: String = e.folder.path_join(str(e.files.get(base, base.capitalize())) + "-Anim.png")
	if size == Vector2i.ZERO or not ResourceLoader.exists(path):
		return Rect2i()
	var tex: Texture2D = load(path)
	var img: Image = tex.get_image()
	if img == null:
		return Rect2i()
	return img.get_region(Rect2i(0, 0, size.x, size.y)).get_used_rect()


static func find_feet(e: Entry, base: String) -> Vector2:
	var used: Rect2i = used_rect(e, base)
	if used.size.y <= 0:
		return Vector2(-1, -1)
	return Vector2(used.position.x + used.size.x * 0.5, used.end.y - 2.0)


static func _build(species_id: String) -> Entry:
	var species: Dictionary = GlobalData.get_species(species_id)
	var cfg: Dictionary = species.get("sprite", {})
	var e := Entry.new()
	e.frames = SpriteFrames.new()
	e.scale = float(cfg.get("scale", 2.0))
	var ok: bool = false
	if str(cfg.get("format", "auto")) == "grid":
		e.mirror = bool(cfg.get("mirror", true))
		ok = _build_grid(e, cfg)
	else:
		var dir: String = str(cfg.get("dir", ""))
		if dir == "":
			dir = str(species.get("en", "")).to_lower()
		if dir != "":
			if not dir.begins_with("res://"):
				dir = SPRITE_ROOT + dir
			ok = _build_pmd_folder(e, dir)
	if not ok or not e.frames.has_animation("idle_down"):
		e.mirror = false
		_build_placeholder(e, species_id)
	return e


static func _parse_anim_data(xml_path: String) -> Dictionary:
	var anims: Dictionary = {}
	var p := XMLParser.new()
	if p.open(xml_path) != OK:
		return anims
	var cur: Dictionary = {}
	var in_anim: bool = false
	var elem: String = ""
	while p.read() == OK:
		match p.get_node_type():
			XMLParser.NODE_ELEMENT:
				elem = p.get_node_name()
				if elem == "Anim":
					cur = {"durations": [], "name": "", "copy": "", "w": 0, "h": 0, "hit": -1}
					in_anim = true
			XMLParser.NODE_TEXT:
				if not in_anim:
					continue
				var txt: String = p.get_node_data().strip_edges()
				if txt == "":
					continue
				match elem:
					"Name": cur["name"] = txt
					"CopyOf": cur["copy"] = txt
					"FrameWidth": cur["w"] = int(txt)
					"FrameHeight": cur["h"] = int(txt)
					"HitFrame": cur["hit"] = int(txt)
					"Duration": cur["durations"].append(int(txt))
			XMLParser.NODE_ELEMENT_END:
				if p.get_node_name() == "Anim" and in_anim:
					anims[cur["name"]] = cur
					in_anim = false
	return anims


static func _build_pmd_folder(e: Entry, dir: String) -> bool:
	var xml_path: String = dir.path_join("AnimData.xml")
	if not FileAccess.file_exists(xml_path):
		return false
	e.folder = dir
	var anims: Dictionary = _parse_anim_data(xml_path)
	for aname in anims:
		var a: Dictionary = anims[aname]
		var src: Dictionary = a
		var file_name: String = str(aname)
		if str(a["copy"]) != "" and anims.has(a["copy"]):
			src = anims[a["copy"]]
			file_name = str(a["copy"])
		var png: String = dir.path_join(file_name + "-Anim.png")
		if not ResourceLoader.exists(png) or int(src["w"]) <= 0:
			continue
		var tex: Texture2D = load(png)
		var w: int = int(src["w"])
		var h: int = int(src["h"])
		var durs: Array = src["durations"]
		if tex.get_width() < durs.size() * w or tex.get_height() < 8 * h:
			continue
		var key: String = str(aname).to_lower()
		for di in range(8):
			var full: String = key + "_" + PMD_DIRS[di]
			e.frames.add_animation(full)
			e.frames.set_animation_speed(full, TICKS_PER_SECOND)
			e.frames.set_animation_loop(full, LOOPING.has(key))
			for f in range(durs.size()):
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(f * w, di * h, w, h)
				e.frames.add_frame(full, at, float(durs[f]))
		var total: int = 0
		for d in durs:
			total += int(d)
		e.lengths[key] = float(total) / TICKS_PER_SECOND
		var hit_frame: int = int(src["hit"])
		if hit_frame >= 0:
			var before: int = 0
			for i in range(mini(hit_frame, durs.size())):
				before += int(durs[i])
			e.hit_times[key] = float(before) / TICKS_PER_SECOND
		e.sizes[key] = Vector2i(w, h)
		e.files[key] = file_name
	if e.sizes.has("idle"):
		e.fallback_height = float(e.sizes["idle"].y) * 0.7
	return e.frames.has_animation("idle_down")


static func _build_grid(e: Entry, cfg: Dictionary) -> bool:
	var path: String = str(cfg.get("tex", ""))
	if not ResourceLoader.exists(path):
		return false
	var tex: Texture2D = load(path)
	var w: int = int(cfg.get("w", 32))
	var h: int = int(cfg.get("h", 32))
	var hframes: int = int(cfg.get("hframes", 8))
	var anims: Dictionary = cfg.get("anims", {})
	for anim in anims:
		var a: Dictionary = anims[anim]
		var dirs: Dictionary = a.get("dirs", {})
		for d in dirs:
			var full: String = str(anim) + "_" + str(d)
			e.frames.add_animation(full)
			e.frames.set_animation_speed(full, float(a.get("fps", 8)))
			e.frames.set_animation_loop(full, bool(a.get("loop", true)))
			for idx in dirs[d]:
				var i: int = int(idx)
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2((i % hframes) * w, (i / hframes) * h, w, h)
				e.frames.add_frame(full, at)
	return e.frames.has_animation("idle_down")


static func _build_placeholder(e: Entry, species_id: String) -> void:
	e.frames = SpriteFrames.new()
	e.folder = ""
	e.frames.add_animation("idle_down")
	e.frames.set_animation_loop("idle_down", true)
	e.frames.add_frame("idle_down", _placeholder_texture(species_id))
	e.fallback_height = 28.0


static func _placeholder_texture(species_id: String) -> Texture2D:
	var types: Array = GlobalData.get_species(species_id).get("types", ["normal"])
	var col: Color = GlobalData.get_type_color(str(types[0]))
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(32):
		for x in range(32):
			var d: float = Vector2(x - 15.5, y - 15.5).length()
			if d < 14.0:
				img.set_pixel(x, y, col.darkened(0.35) if d > 11.5 else col)
	for ex in [10, 19]:
		for dy in range(3):
			for dx in range(3):
				img.set_pixel(ex + dx, 12 + dy, Color.WHITE)
		img.set_pixel(ex + 1, 13, Color.BLACK)
	return ImageTexture.create_from_image(img)
