class_name SynergyCalc
extends RefCounted


static func compute(species_ids: Array) -> Array:
	var counts := {}
	var seen := {}
	for sid in species_ids:
		if seen.has(sid):
			continue
		seen[sid] = true
		for t in GlobalData.get_species(str(sid)).get("types", []):
			counts[t] = int(counts.get(t, 0)) + 1
	var result: Array = []
	for t in counts:
		var info: Dictionary = GlobalData.get_type_info(str(t))
		if info.is_empty():
			continue
		var bps: Array = info.get("breakpoints", [2, 4, 6])
		var tier: int = -1
		for i in range(bps.size()):
			if int(counts[t]) >= int(bps[i]):
				tier = i
		result.append({"type": str(t), "count": int(counts[t]), "tier": tier, "breakpoints": bps, "info": info})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["tier"] != b["tier"]:
			return a["tier"] > b["tier"]
		return a["count"] > b["count"])
	return result


static func mods_for(synergies: Array, unit_types: Array) -> Dictionary:
	var out := {}
	for s in synergies:
		var tier: int = int(s["tier"])
		if tier < 0:
			continue
		var info: Dictionary = s["info"]
		var applies: bool = str(info.get("scope", "members")) == "team" or unit_types.has(s["type"])
		if not applies:
			continue
		var tiers: Array = info.get("tiers", [])
		if tier < tiers.size():
			merge_mods(out, tiers[tier].get("mods", {}))
	return out


static func merge_mods(into: Dictionary, add: Dictionary) -> void:
	for k in add:
		into[k] = float(into.get(k, 0.0)) + float(add[k])


static func to_bbcode(synergies: Array, show_desc: bool = true) -> String:
	var lines: Array[String] = []
	for s in synergies:
		var info: Dictionary = s["info"]
		var tier: int = int(s["tier"])
		var bps: Array = s["breakpoints"]
		var goal: int = int(bps[mini(tier + 1, bps.size() - 1)])
		var col: String = str(info.get("color", "#ffffff")) if tier >= 0 else "#777777"
		var line: String = "[color=%s]●[/color] [b]%s[/b] %d/%d" % [col, str(info.get("name", "?")), int(s["count"]), goal]
		if tier >= 0:
			var tiers: Array = info.get("tiers", [])
			line += "  [color=#9be37a]%s[/color]" % str(info.get("synergy", ""))
			if show_desc and tier < tiers.size():
				line += " [color=#c8c8c8](%s)[/color]" % str(tiers[tier].get("desc", ""))
		else:
			line = "[color=#777777]● %s %d/%d[/color]" % [str(info.get("name", "?")), int(s["count"]), goal]
		lines.append(line)
	return "\n".join(lines)
