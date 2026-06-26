extends RefCounted
class_name HitContext
## Mutable payload passed to Daemon.on_hit() just before a bullet deals damage.

var bullet: Bullet
var target: LivingEntity
## Mutable — daemons may scale damage before it lands.
var damage: float
## If true, the bullet is NOT freed after the hit (pierce-style behaviors).
var pierce: bool = false
