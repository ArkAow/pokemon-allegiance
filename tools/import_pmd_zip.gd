@tool
extends EditorScript

const SRC_DIR := "res://sprite_imports"
const DEST_DIR := "res://assets/pokemons"


func _run() -> void:
	var dir := DirAccess.open(SRC_DIR)
	if dir == null:
		printerr("Dossier introuvable : ", SRC_DIR)
		return
	var count: int = 0
	for file_name in dir.get_files():
		if file_name.get_extension().to_lower() != "zip":
			continue
		var poke_name: String = file_name.get_basename().to_lower().replace("_sprite", "").replace("-sprite", "").replace(" ", "_")
		var n: int = _extract(SRC_DIR.path_join(file_name), DEST_DIR.path_join(poke_name))
		print("[PMD] ", file_name, " -> ", DEST_DIR.path_join(poke_name), " (", n, " fichiers)")
		count += 1
	if count == 0:
		print("[PMD] Aucun .zip trouvé dans ", SRC_DIR)
	_remove_shadow_files(DEST_DIR)
	get_editor_interface().get_resource_filesystem().scan()
	print("[PMD] Terminé. Godot va réimporter les images.")


func _extract(zip_path: String, dest: String) -> int:
	var zr := ZIPReader.new()
	if zr.open(zip_path) != OK:
		printerr("Impossible d'ouvrir ", zip_path)
		return 0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dest))
	var n: int = 0
	for entry in zr.get_files():
		var base: String = entry.get_file()
		var keep: bool = base == "AnimData.xml" or (base.ends_with("-Anim.png") and not base.ends_with("-Shadow.png"))
		if not keep:
			continue
		var f := FileAccess.open(dest.path_join(base), FileAccess.WRITE)
		if f == null:
			continue
		f.store_buffer(zr.read_file(entry))
		f.close()
		n += 1
	zr.close()
	return n


func _remove_shadow_files(root: String) -> void:
	var removed: int = 0
	var rd := DirAccess.open(root)
	if rd == null:
		return
	for sub in rd.get_directories():
		var d := DirAccess.open(root.path_join(sub))
		if d == null:
			continue
		for f in d.get_files():
			if f.contains("-Shadow") or f.contains("-Offsets"):
				d.remove(f)
				removed += 1
	if removed > 0:
		print("[PMD] ", removed, " fichier(s) -Shadow/-Offsets suppr")
