class_name AttackContext
extends RefCounted
## Tout ce qu'une scène d'effet (AttackFx) doit savoir pour s'animer. Rempli par AbilityRunner.
## Coordonnées : celles du BattleField (les mêmes que `unit.position`).

var caster: BattleUnit
var field: BattleField
var targets: Array = []          ## unités concernées par CETTE animation (BattleUnit)
var main_target: BattleUnit      ## cible principale (celle visée par le lanceur)
var origin: Vector2 = Vector2.ZERO   ## départ visuel (souvent le torse du lanceur)
var dest: Vector2 = Vector2.ZERO     ## arrivée visuelle (torse de la cible / centre de zone / bout du rayon)
var radius: float = 0.0          ## rayon en pixels (zones)
var width: float = 0.0           ## largeur en pixels (rayon, cône)
var duration: float = 0.0        ## durée en secondes (zones)
var color: Color = Color(0, 0, 0, 0)   ## couleur imposée par le step (alpha 0 = non imposée)
var params: Dictionary = {}      ## le step JSON complet : tes fx custom peuvent y lire n'importe quel champ
var vars: Dictionary = {}        ## variables partagées entre effets d'un même step


func direction() -> Vector2:
	var d: Vector2 = dest - origin
	return d.normalized() if d.length() > 0.001 else Vector2.DOWN


func hop_index(unit: BattleUnit) -> int:
	return maxi(0, targets.find(unit))


func param(key: String, default_value: Variant) -> Variant:
	return params.get(key, default_value)
