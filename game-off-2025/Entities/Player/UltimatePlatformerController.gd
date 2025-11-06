extends CharacterBody2D

class_name PlatformerController2D

@export_category("Necesary Child Nodes")
@export var PlayerSprite: AnimatedSprite2D
@export var PlayerCollider: CollisionShape2D
@export var FlapAudioPlayer: AudioStreamPlayer
@export var WalkingAudioPlayer: AudioStreamPlayer

#INFO HORIZONTAL MOVEMENT
@export_category("L/R Movement")
##Walk speed (SMB3 style - slower speed when not running)
@export_range(50, 300) var walkSpeed: float = 150.0
##Run speed (SMB3 style - faster speed when run button held)
@export_range(100, 500) var runSpeed: float = 250.0
##How fast your player will reach max speed from rest (in seconds)
@export_range(0, 4) var timeToReachMaxSpeed: float = 0.3
##How fast your player will reach zero speed from max speed (in seconds)
@export_range(0, 4) var timeToReachZeroSpeed: float = 0.15
##Speed threshold for skidding when changing direction (units/sec)
@export_range(50, 300) var skidThreshold: float = 100.0
##Skid friction multiplier (higher = faster stopping during skid)
@export_range(0.3, 3.0) var skidFriction: float = 0.5
##If true, player will instantly move and switch directions. Overrides the "timeToReach" variables, setting them to 0.
@export var directionalSnap: bool = false
##If enabled, the default movement speed will by 1/2 of the maxSpeed and the player must hold a "run" button to accelerate to max speed. Assign "run" (case sensitive) in the project input settings.
@export var runningModifier: bool = true

#INFO JUMPING
@export_category("Jumping and Gravity")
##The peak height of your player's jump
@export_range(0, 20) var jumpHeight: float = 2.0
##Jump power multiplier when running at max speed (SMB3 style - faster speed = higher jump)
@export_range(1.0, 1.8) var maxSpeedJumpBoost: float = 1.75
##Jump power multiplier when walking or standing still (base jump height)
@export_range(1.0, 1.5) var walkJumpBoost: float = 1.5
##How many jumps your character can do before needing to touch the ground again. Giving more than 1 jump disables jump buffering and coyote time.
@export_range(0, 4) var jumps: int = 1
##Jump gravity (SMB3 style - low gravity while ascending with button held)
@export_range(0, 50) var jumpGravity: float = 5.0
##Fall gravity (SMB3 style - higher gravity when falling for snappy landings)
@export_range(0, 100) var fallGravity: float = 25.0
##The fastest your player can fall
@export_range(0, 1000) var terminalVelocity: float = 500.0
##Enabling this toggle makes it so that when the player releases the jump key while still ascending, their vertical velocity will cut in half, providing variable jump height.
@export var shortHopAkaVariableJumpHeight: bool = true
##How much extra time (in seconds) your player will be given to jump after falling off an edge. This is set to 0.2 seconds by default.
@export_range(0, 0.5) var coyoteTime: float = 0.2
##The window of time (in seconds) that your player can press the jump button before hitting the ground and still have their input registered as a jump. This is set to 0.2 seconds by default.
@export_range(0, 0.5) var jumpBuffering: float = 0.2

#INFO EXTRAS
@export_category("Wall Jumping")
##Allows your player to jump off of walls. Without a Wall Kick Angle, the player will be able to scale the wall.
@export var wallJump: bool = false
##How long the player's movement input will be ignored after wall jumping.
@export_range(0, 0.5) var inputPauseAfterWallJump: float = 0.1
##The angle at which your player will jump away from the wall. 0 is straight away from the wall, 90 is straight up. Does not account for gravity
@export_range(0, 90) var wallKickAngle: float = 60.0
##The player's gravity will be divided by this number when touch a wall and descending. Set to 1 by default meaning no change will be made to the gravity and there is effectively no wall sliding. THIS IS OVERRIDDED BY WALL LATCH.
@export_range(1, 20) var wallSliding: float = 1.0
##If enabled, the player's gravity will be set to 0 when touching a wall and descending. THIS WILL OVERRIDE WALLSLIDING.
@export var wallLatching: bool = false
##wall latching must be enabled for this to work. #If enabled, the player must hold down the "latch" key to wall latch. Assign "latch" in the project input settings. The player's input will be ignored when latching.
@export var wallLatchingModifer: bool = false
@export_category("Dashing")
##The type of dashes the player can do.
@export_enum("None", "Horizontal", "Vertical", "Four Way", "Eight Way") var dashType: int
##How many dashes your player can do before needing to hit the ground.
@export_range(0, 10) var dashes: int = 1
##If enabled, pressing the opposite direction of a dash, during a dash, will zero the player's velocity.
@export var dashCancel: bool = true
##How far the player will dash. One of the dashing toggles must be on for this to be used.
@export_range(1.5, 4) var dashLength: float = 2.5
@export_category("Corner Cutting/Jump Correct")
##If the player's head is blocked by a jump but only by a little, the player will be nudged in the right direction and their jump will execute as intended. NEEDS RAYCASTS TO BE ATTACHED TO THE PLAYER NODE. AND ASSIGNED TO MOUNTING RAYCAST. DISTANCE OF MOUNTING DETERMINED BY PLACEMENT OF RAYCAST.
@export var cornerCutting: bool = false
##How many pixels the player will be pushed (per frame) if corner cutting is needed to correct a jump.
@export_range(1, 5) var correctionAmount: float = 1.5
##Raycast used for corner cutting calculations. Place above and to the left of the players head point up. ALL ARE NEEDED FOR IT TO WORK.
@export var leftRaycast: RayCast2D
##Raycast used for corner cutting calculations. Place above of the players head point up. ALL ARE NEEDED FOR IT TO WORK.
@export var middleRaycast: RayCast2D
##Raycast used for corner cutting calculations. Place above and to the right of the players head point up. ALL ARE NEEDED FOR IT TO WORK.
@export var rightRaycast: RayCast2D
@export_category("Wing Flap/Tail Whip")
##Allows the player to flap wings in midair to slow descent (SMB3 tail whip style). Uses the jump button when airborne.
@export var canFlap: bool = true
##How much upward velocity is added when flapping (negative fall speed)
@export_range(0, 300) var flapLift: float = 100.0
##Cooldown between flaps in seconds (prevents spamming)
@export_range(0.0, 1.0) var flapCooldown: float = 0.25
##If true, flapping resets a small amount of horizontal momentum (like SMB3)
@export var flapAffectsHorizontalSpeed: bool = false

@export_category("Down Input")
##Holding down will crouch the player. Crouching script may need to be changed depending on how your player's size proportions are. It is built for 32x player's sprites.
@export var crouch: bool = false
##Holding down and pressing the input for "roll" will execute a roll if the player is grounded. Assign a "roll" input in project settings input.
@export var canRoll: bool
@export_range(1.25, 2) var rollLength: float = 2
##If enabled, the player will stop all horizontal movement midair, wait (groundPoundPause) seconds, and then slam down into the ground when down is pressed. 
@export var groundPound: bool
##The amount of time the player will hover in the air before completing a ground pound (in seconds)
@export_range(0.05, 0.75) var groundPoundPause: float = 0.25
##If enabled, pressing up will end the ground pound early
@export var upToCancel: bool = false

@export_category("Animations (Check Box if has animation)")
##Animations must be named "run" all lowercase as the check box says
@export var run: bool
##Animations must be named "jump" all lowercase as the check box says
@export var jump: bool
##Animations must be named "idle" all lowercase as the check box says
@export var idle: bool
##Animations must be named "walk" all lowercase as the check box says
@export var walk: bool
##Animations must be named "slide" all lowercase as the check box says
@export var slide: bool
##Animations must be named "skid" all lowercase as the check box says (SMB3 style turning skid)
@export var skid: bool
##Animations must be named "latch" all lowercase as the check box says
@export var latch: bool
##Animations must be named "falling" all lowercase as the check box says
@export var falling: bool
##Animations must be named "crouch_idle" all lowercase as the check box says
@export var crouch_idle: bool
##Animations must be named "crouch_walk" all lowercase as the check box says
@export var crouch_walk: bool
##Animations must be named "roll" all lowercase as the check box says
@export var roll: bool



#Variables determined by the developer set ones.
var appliedGravity: float
var maxSpeed: float
var maxSpeedLock: float
var appliedTerminalVelocity: float

var friction: float
var acceleration: float
var deceleration: float
var instantAccel: bool = false
var instantStop: bool = false

var jumpMagnitude: float = 500.0
var jumpCount: int
var jumpWasPressed: bool = false
var coyoteActive: bool = false
var dashMagnitude: float
var gravityActive: bool = true
var dashing: bool = false
var dashCount: int
var rolling: bool = false

# SMB3 style movement states
var is_skidding: bool = false
var current_move_direction: int = 0  # -1 left, 0 none, 1 right
var previous_move_direction: int = 0

var twoWayDashHorizontal
var twoWayDashVertical
var eightWayDash

var wasMovingR: bool
var wasPressingR: bool
var movementInputMonitoring: Vector2 = Vector2(true, true) #movementInputMonitoring.x addresses right direction while .y addresses left direction

var gdelta: float = 1

var dset = false

var colliderScaleLockY
var colliderPosLockY

var latched
var wasLatched
var crouching
var groundPounding
var canFlapNow: bool = true
var isFlapping: bool = false
var walkingSoundTimer: float = 0.0
var walkingSoundInterval: float = 0.3  # Time between footsteps

# Tile-based friction system
var is_on_slippery_surface: bool = false
var friction_multiplier: float = 1.0
@export_range(0.1, 1.0) var slipperyFrictionMultiplier: float = 0.3  # Adjust this value: lower = more slippery

var anim
var col
var animScaleLock : Vector2

#Input Variables for the whole script
var upHold
var downHold
var leftHold
var leftTap
var leftRelease
var rightHold
var rightTap
var rightRelease
var jumpTap
var jumpRelease
var runHold
var latchHold
var dashTap
var rollTap
var downTap
#var twirlTap

func _ready():
	wasMovingR = true
	anim = PlayerSprite
	col = PlayerCollider
	
	_updateData()
	
func _updateData():
	# SMB3 style: Use run speed as base for calculations
	maxSpeedLock = runSpeed

	# Use runSpeed for acceleration calculation (constant acceleration rate)
	acceleration = runSpeed / timeToReachMaxSpeed
	deceleration = -runSpeed / timeToReachZeroSpeed

	# SMB3 style: Base jump magnitude on jump gravity instead of old gravityScale
	jumpMagnitude = (10.0 * jumpHeight) * jumpGravity
	jumpCount = jumps

	dashMagnitude = runSpeed * dashLength
	dashCount = dashes
	
	animScaleLock = abs(anim.scale)
	colliderScaleLockY = col.scale.y
	colliderPosLockY = col.position.y
	
	if timeToReachMaxSpeed == 0:
		instantAccel = true
		timeToReachMaxSpeed = 1
	elif timeToReachMaxSpeed < 0:
		timeToReachMaxSpeed = abs(timeToReachMaxSpeed)
		instantAccel = false
	else:
		instantAccel = false
		
	if timeToReachZeroSpeed == 0:
		instantStop = true
		timeToReachZeroSpeed = 1
	elif timeToReachMaxSpeed < 0:
		timeToReachMaxSpeed = abs(timeToReachMaxSpeed)
		instantStop = false
	else:
		instantStop = false
		
	if jumps > 1:
		jumpBuffering = 0
		coyoteTime = 0
	
	coyoteTime = abs(coyoteTime)
	jumpBuffering = abs(jumpBuffering)
	
	if directionalSnap:
		instantAccel = true
		instantStop = true
	
	
	twoWayDashHorizontal = false
	twoWayDashVertical = false
	eightWayDash = false
	if dashType == 0:
		pass
	if dashType == 1:
		twoWayDashHorizontal = true
	elif dashType == 2:
		twoWayDashVertical = true
	elif dashType == 3:
		twoWayDashHorizontal = true
		twoWayDashVertical = true
	elif dashType == 4:
		eightWayDash = true
	
	

func _process(_delta):
	#INFO animations
	#Update walking sound timer
	if walkingSoundTimer > 0:
		walkingSoundTimer -= _delta

	#directions
	if is_on_wall() and !is_on_floor() and latch and wallLatching and ((wallLatchingModifer and latchHold) or !wallLatchingModifer):
		latched = true
	else:
		latched = false
		wasLatched = true
		_setLatch(0.2, false)

	if rightHold and !latched:
		anim.scale.x = animScaleLock.x
	if leftHold and !latched:
		anim.scale.x = animScaleLock.x * -1
	
	# Check if player is actually moving (has input)
	var is_moving = (leftHold or rightHold) and is_on_floor() and !is_on_wall()

	# SMB3 style skid animation (takes priority over other ground animations)
	if skid and is_skidding and is_on_floor() and !dashing and !crouching:
		anim.speed_scale = 1
		anim.play("skid")
		_stopWalkingSound()
	#run
	elif run and idle and !dashing and !crouching:
		if abs(velocity.x) > 0.1 and is_on_floor() and !is_on_wall():
			anim.speed_scale = abs(velocity.x / 150)
			anim.play("run")
			if is_moving:
				_playWalkingSound()
			else:
				_stopWalkingSound()
		elif abs(velocity.x) < 0.1 and is_on_floor():
			anim.speed_scale = 1
			anim.play("idle")
			_stopWalkingSound()
	elif run and idle and walk and !dashing and !crouching:
		if abs(velocity.x) > 0.1 and is_on_floor() and !is_on_wall():
			anim.speed_scale = abs(velocity.x / 150)
			# SMB3 style: Use walk speed threshold instead of maxSpeedLock
			if abs(velocity.x) < walkSpeed:
				anim.play("walk")
			else:
				anim.play("run")
			if is_moving:
				_playWalkingSound()
			else:
				_stopWalkingSound()
		elif abs(velocity.x) < 0.1 and is_on_floor():
			anim.speed_scale = 1
			anim.play("idle")
			_stopWalkingSound()
		
	#jump
	if velocity.y < 0 and jump and !dashing:
		if anim.animation != "jump":
			anim.speed_scale = 1
			anim.play("jump")
			_stopWalkingSound()

	if velocity.y > 40 and falling and !dashing and !crouching:
		anim.speed_scale = 1
		anim.play("falling")
		_stopWalkingSound()
		
	if latch and slide:
		#wall slide and latch
		if latched and !wasLatched:
			anim.speed_scale = 1
			anim.play("latch")
		if is_on_wall() and velocity.y > 0 and slide and anim.animation != "slide" and wallSliding != 1:
			anim.speed_scale = 1
			anim.play("slide")
			
		#dash
		if dashing:
			anim.speed_scale = 1
			anim.play("dash")
			
		#crouch
		if crouching and !rolling:
			if abs(velocity.x) > 10:
				anim.speed_scale = 1
				anim.play("crouch_walk")
			else:
				anim.speed_scale = 1
				anim.play("crouch_idle")
		
		if rollTap and canRoll and roll:
			anim.speed_scale = 1
			anim.play("roll")
		
		
		

func _physics_process(delta):
	if !dset:
		gdelta = delta
		dset = true
	leftHold = Input.is_action_pressed("left")
	rightHold = Input.is_action_pressed("right")
	upHold = Input.is_action_pressed("up")
	downHold = Input.is_action_pressed("down")
	leftTap = Input.is_action_just_pressed("left")
	rightTap = Input.is_action_just_pressed("right")
	leftRelease = Input.is_action_just_released("left")
	rightRelease = Input.is_action_just_released("right")
	jumpTap = Input.is_action_just_pressed("jump")
	jumpRelease = Input.is_action_just_released("jump")
	runHold = Input.is_action_pressed("run")
	# Disabled unimplemented features to avoid input errors
	#latchHold = Input.is_action_pressed("latch")
	#dashTap = Input.is_action_just_pressed("dash")
	#rollTap = Input.is_action_just_pressed("roll")
	downTap = Input.is_action_just_pressed("down")
	#twirlTap = Input.is_action_just_pressed("twirl")
	
	
	#INFO Left and Right Movement (SMB3 Style)

	# Track current input direction
	if rightHold and !leftHold:
		current_move_direction = 1
	elif leftHold and !rightHold:
		current_move_direction = -1
	else:
		current_move_direction = 0

	# SMB3 style: Detect skidding when changing direction at high speed
	if is_on_floor() and !dashing and !rolling:
		var velocity_direction = sign(velocity.x)

		# Start skidding when trying to move opposite to current velocity at high speed
		if current_move_direction != 0 and velocity_direction != 0:
			if current_move_direction != velocity_direction and abs(velocity.x) > skidThreshold:
				if !is_skidding:
					print("SKID START! velocity.x: ", velocity.x, " direction: ", current_move_direction)
				is_skidding = true

		# Stop skidding when velocity is low enough (nearly stopped)
		if is_skidding:
			# End skid when you've slowed down to almost stopped
			if abs(velocity.x) < 30.0:
				print("SKID END! velocity.x: ", velocity.x)
				is_skidding = false

		# Stop skidding if no input
		if current_move_direction == 0:
			is_skidding = false
	else:
		is_skidding = false

	# SMB3 style: Walk/Run speed states based on run button
	if runningModifier:
		if runHold and is_on_floor():
			maxSpeed = runSpeed
		else:
			maxSpeed = walkSpeed
	else:
		maxSpeed = runSpeed

	# Detect ground friction from tiles
	_detect_ground_friction()

	# SMB3 style: Apply reduced acceleration and increased friction when skidding
	# Also apply tile-based friction multiplier
	var current_acceleration = acceleration * friction_multiplier
	var current_deceleration = deceleration * friction_multiplier

	if is_skidding:
		# During skid: ONLY decelerate, don't accelerate in new direction yet
		# This preserves momentum in the original direction
		current_acceleration = 0  # No acceleration in new direction while skidding
		current_deceleration = deceleration * skidFriction * friction_multiplier

	if rightHold and leftHold and movementInputMonitoring:
		if !instantStop:
			_decelerate_custom(delta, false, current_deceleration)
		else:
			velocity.x = -0.1
	elif rightHold and movementInputMonitoring.x:
		if velocity.x > maxSpeed or instantAccel:
			velocity.x = maxSpeed
		elif velocity.x < 0:
			# Moving left but want to go right - apply deceleration
			if !instantStop:
				_decelerate_custom(delta, false, current_deceleration)
			else:
				velocity.x = -0.1
		else:
			# Already moving right - apply acceleration
			velocity.x += current_acceleration * delta
	elif leftHold and movementInputMonitoring.y:
		if velocity.x < -maxSpeed or instantAccel:
			velocity.x = -maxSpeed
		elif velocity.x > 0:
			# Moving right but want to go left - apply deceleration
			if !instantStop:
				_decelerate_custom(delta, false, current_deceleration)
			else:
				velocity.x = 0.1
		else:
			# Already moving left - apply acceleration
			velocity.x -= current_acceleration * delta

	if velocity.x > 0:
		wasMovingR = true
	elif velocity.x < 0:
		wasMovingR = false

	if rightTap:
		wasPressingR = true
	if leftTap:
		wasPressingR = false

	if !(leftHold or rightHold):
		if !instantStop:
			_decelerate_custom(delta, false, current_deceleration)
		else:
			velocity.x = 0

	previous_move_direction = current_move_direction
			
	#INFO Crouching
	if crouch:
		if downHold and is_on_floor():
			crouching = true
		elif !downHold and ((runHold and runningModifier) or !runningModifier) and !rolling:
			crouching = false
			
	if !is_on_floor():
		crouching = false

	if crouching:
		maxSpeed = walkSpeed / 2  # SMB3 style: Crouching uses even slower speed
		col.scale.y = colliderScaleLockY / 2
		col.position.y = colliderPosLockY + (8 * colliderScaleLockY)
	else:
		# Speed already set above based on run button
		col.scale.y = colliderScaleLockY
		col.position.y = colliderPosLockY
		
	#INFO Rolling
	if canRoll and is_on_floor() and rollTap and crouching:
		_rollingTime(0.75)
		if wasPressingR and !(upHold):
			velocity.y = 0
			velocity.x = maxSpeedLock * rollLength
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(rollLength * 0.0625)
		elif !(upHold):
			velocity.y = 0
			velocity.x = -maxSpeedLock * rollLength
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(rollLength * 0.0625)
		
	if canRoll and rolling:
		#if you want your player to become immune or do something else while rolling, add that here.
		pass
			
	#INFO Jump and Gravity (SMB3 Style)
	# SMB3 style: Different gravity when falling vs jumping (5:1 ratio)
	if velocity.y > 0:
		appliedGravity = fallGravity
	else:
		# Use reduced gravity while ascending and jump button is held
		if jumpTap or Input.is_action_pressed("jump"):
			appliedGravity = jumpGravity
		else:
			appliedGravity = fallGravity
	
	if is_on_wall() and !groundPounding:
		appliedTerminalVelocity = terminalVelocity / wallSliding
		if wallLatching and ((wallLatchingModifer and latchHold) or !wallLatchingModifer):
			appliedGravity = 0
			
			if velocity.y < 0:
				velocity.y += 50
			if velocity.y > 0:
				velocity.y = 0
				
			if wallLatchingModifer and latchHold and movementInputMonitoring == Vector2(true, true):
				velocity.x = 0
			
		elif wallSliding != 1 and velocity.y > 0:
			appliedGravity = appliedGravity / wallSliding
	elif !is_on_wall() and !groundPounding:
		appliedTerminalVelocity = terminalVelocity
	
	if gravityActive:
		if velocity.y < appliedTerminalVelocity:
			velocity.y += appliedGravity
		elif velocity.y > appliedTerminalVelocity:
				velocity.y = appliedTerminalVelocity
		
	if shortHopAkaVariableJumpHeight and jumpRelease and velocity.y < 0:
		velocity.y = velocity.y / 2
	
	if jumps == 1:
		if !is_on_floor() and !is_on_wall():
			if coyoteTime > 0:
				coyoteActive = true
				_coyoteTime()
				
		if jumpTap and !is_on_wall():
			if coyoteActive:
				coyoteActive = false
				_jump()
			if jumpBuffering > 0:
				jumpWasPressed = true
				_bufferJump()
			elif jumpBuffering == 0 and coyoteTime == 0 and is_on_floor():
				_jump()	
		elif jumpTap and is_on_wall() and !is_on_floor():
			if wallJump and !latched:
				_wallJump()
			elif wallJump and latched:
				_wallJump()
		elif jumpTap and is_on_floor():
			_jump()
		
		
			
		if is_on_floor():
			jumpCount = jumps
			coyoteActive = true
			if jumpWasPressed:
				_jump()

	elif jumps > 1:
		if is_on_floor():
			jumpCount = jumps
		if jumpTap and jumpCount > 0 and !is_on_wall():
			velocity.y = -jumpMagnitude
			jumpCount = jumpCount - 1
			_endGroundPound()
		elif jumpTap and is_on_wall() and wallJump:
			_wallJump()
			
			
	#INFO dashing
	if is_on_floor():
		dashCount = dashes
	if eightWayDash and dashTap and dashCount > 0 and !rolling:
		var input_direction = Input.get_vector("left", "right", "up", "down")
		var dTime = 0.0625 * dashLength
		_dashingTime(dTime)
		_pauseGravity(dTime)
		velocity = dashMagnitude * input_direction
		dashCount += -1
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(dTime)
	
	if twoWayDashVertical and dashTap and dashCount > 0 and !rolling:
		var dTime = 0.0625 * dashLength
		if upHold and downHold:
			_placeHolder()
		elif upHold:
			_dashingTime(dTime)
			_pauseGravity(dTime)
			velocity.x = 0
			velocity.y = -dashMagnitude
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)
		elif downHold and dashCount > 0:
			_dashingTime(dTime)
			_pauseGravity(dTime)
			velocity.x = 0
			velocity.y = dashMagnitude
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)
	
	if twoWayDashHorizontal and dashTap and dashCount > 0 and !rolling:
		var dTime = 0.0625 * dashLength
		if wasPressingR and !(upHold or downHold):
			velocity.y = 0
			velocity.x = dashMagnitude
			_pauseGravity(dTime)
			_dashingTime(dTime)
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)
		elif !(upHold or downHold):
			velocity.y = 0
			velocity.x = -dashMagnitude
			_pauseGravity(dTime)
			_dashingTime(dTime)
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)
			
	if dashing and velocity.x > 0 and leftTap and dashCancel:
		velocity.x = 0
	if dashing and velocity.x < 0 and rightTap and dashCancel:
		velocity.x = 0
	
	#INFO Corner Cutting
	if cornerCutting:
		if velocity.y < 0 and leftRaycast.is_colliding() and !rightRaycast.is_colliding() and !middleRaycast.is_colliding():
			position.x += correctionAmount
		if velocity.y < 0 and !leftRaycast.is_colliding() and rightRaycast.is_colliding() and !middleRaycast.is_colliding():
			position.x -= correctionAmount
			
	#INFO Wing Flap (SMB3 Tail Whip Style)
	# Use jump button for flapping when in the air and falling
	if canFlap and jumpTap and !is_on_floor() and !is_on_wall() and canFlapNow and velocity.y > 0:
		_flap()

	# Reset flap availability when grounded
	if is_on_floor():
		canFlapNow = true
		isFlapping = false

	#INFO Ground Pound
	if groundPound and downTap and !is_on_floor() and !is_on_wall():
		groundPounding = true
		gravityActive = false
		velocity.y = 0
		await get_tree().create_timer(groundPoundPause).timeout
		_groundPound()
	if is_on_floor() and groundPounding:
		_endGroundPound()
	move_and_slide()

	if upToCancel and upHold and groundPound:
		_endGroundPound()
	
func _bufferJump():
	await get_tree().create_timer(jumpBuffering).timeout
	jumpWasPressed = false

func _coyoteTime():
	await get_tree().create_timer(coyoteTime).timeout
	coyoteActive = false
	jumpCount += -1

	
func _jump():
	if jumpCount > 0:
		# Jump power based on whether player is running or not
		var jump_multiplier = walkJumpBoost

		# If moving faster than walk speed, interpolate to running jump boost
		if abs(velocity.x) > walkSpeed:
			var run_speed_ratio = (abs(velocity.x) - walkSpeed) / (runSpeed - walkSpeed)
			run_speed_ratio = clamp(run_speed_ratio, 0.0, 1.0)
			jump_multiplier = walkJumpBoost + (run_speed_ratio * (maxSpeedJumpBoost - walkJumpBoost))

		velocity.y = -jumpMagnitude * jump_multiplier
		jumpCount += -1
		jumpWasPressed = false
		if FlapAudioPlayer:
			FlapAudioPlayer.play()
		
func _wallJump():
	var horizontalWallKick = abs(jumpMagnitude * cos(wallKickAngle * (PI / 180)))
	var verticalWallKick = abs(jumpMagnitude * sin(wallKickAngle * (PI / 180)))
	velocity.y = -verticalWallKick
	var dir = 1
	if wallLatchingModifer and latchHold:
		dir = -1
	if wasMovingR:
		velocity.x = -horizontalWallKick  * dir
	else:
		velocity.x = horizontalWallKick * dir
	if inputPauseAfterWallJump != 0:
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(inputPauseAfterWallJump)
			
func _setLatch(delay, setBool):
	await get_tree().create_timer(delay).timeout
	wasLatched = setBool
			
func _inputPauseReset(time):
	await get_tree().create_timer(time).timeout
	movementInputMonitoring = Vector2(true, true)
	

func _decelerate(delta, vertical):
	if !vertical:
		if velocity.x > 0:
			velocity.x += deceleration * delta
		elif velocity.x < 0:
			velocity.x -= deceleration * delta
	elif vertical and velocity.y > 0:
		velocity.y += deceleration * delta

func _decelerate_custom(delta, vertical, custom_decel):
	# SMB3 style: Custom deceleration for skidding
	if !vertical:
		if velocity.x > 0:
			velocity.x += custom_decel * delta
			if velocity.x < 0:
				velocity.x = 0
		elif velocity.x < 0:
			velocity.x -= custom_decel * delta
			if velocity.x > 0:
				velocity.x = 0
	elif vertical and velocity.y > 0:
		velocity.y += custom_decel * delta


func _pauseGravity(time):
	gravityActive = false
	await get_tree().create_timer(time).timeout
	gravityActive = true

func _dashingTime(time):
	dashing = true
	await get_tree().create_timer(time).timeout
	dashing = false

func _rollingTime(time):
	rolling = true
	await get_tree().create_timer(time).timeout
	rolling = false	

func _groundPound():
	appliedTerminalVelocity = terminalVelocity * 10
	velocity.y = jumpMagnitude * 2
	
func _endGroundPound():
	groundPounding = false
	appliedTerminalVelocity = terminalVelocity
	gravityActive = true

func _placeHolder():
	print("")

func _flap():
	# SMB3 tail whip style: reduces fall speed significantly
	if velocity.y > 0:
		velocity.y = -flapLift

	# Optional: slight horizontal momentum adjustment like SMB3
	if flapAffectsHorizontalSpeed:
		velocity.x *= 0.9

	# Play flap audio if available
	if FlapAudioPlayer:
		FlapAudioPlayer.play()

	# Set flapping state and cooldown
	isFlapping = true
	canFlapNow = false
	_flapCooldownReset()

func _flapCooldownReset():
	await get_tree().create_timer(flapCooldown).timeout
	canFlapNow = true
	isFlapping = false

func _playWalkingSound():
	if WalkingAudioPlayer:
		# Play footstep at regular intervals based on movement speed
		if walkingSoundTimer <= 0:
			WalkingAudioPlayer.play()
			# Adjust interval based on speed - faster movement = faster footsteps
			var speed_ratio = abs(velocity.x) / runSpeed
			walkingSoundInterval = lerp(0.3, 0.2, speed_ratio)  # 0.35s when slow, 0.2s when fast
			walkingSoundTimer = walkingSoundInterval

func _stopWalkingSound():
	# Reset the timer when stopping
	walkingSoundTimer = 0.0
	# Stop any currently playing footstep sound
	if WalkingAudioPlayer and WalkingAudioPlayer.playing:
		WalkingAudioPlayer.stop()

func _detect_ground_friction():
	# Reset to normal friction if not on floor
	if !is_on_floor():
		friction_multiplier = 1.0
		is_on_slippery_surface = false
		return

	# Find the TileMapLayer node - it's nested under TileMap/Ground
	var tilemap = get_tree().current_scene.get_node_or_null("TileMap/Ground")
	if !tilemap:
		# Fallback: try direct parent
		tilemap = get_parent().get_node_or_null("TileMap/Ground")

	if !tilemap:
		print("WARNING: Could not find Ground TileMapLayer!")
		friction_multiplier = 1.0
		is_on_slippery_surface = false
		return

	# Get the tile coordinates beneath the player
	var tile_pos = tilemap.local_to_map(tilemap.to_local(global_position + Vector2(0, 10)))

	# Get the tile data at this position
	var tile_data = tilemap.get_cell_tile_data(tile_pos)

	if tile_data:
		# Check for custom data layer "is_slippery"
		# This will be set up in the TileSet editor
		var has_custom = tile_data.has_custom_data("is_slippery")
		var is_slippery = false

		if has_custom:
			is_slippery = tile_data.get_custom_data("is_slippery")

		# Debug: Print tile info when it changes
		var current_state = is_on_slippery_surface
		if is_slippery != current_state:
			print("Tile at ", tile_pos, " - has_custom_data: ", has_custom, ", is_slippery: ", is_slippery)

		if is_slippery:
			friction_multiplier = slipperyFrictionMultiplier
			is_on_slippery_surface = true
		else:
			friction_multiplier = 1.0
			is_on_slippery_surface = false
	else:
		# No tile found, use normal friction
		friction_multiplier = 1.0
		is_on_slippery_surface = false
