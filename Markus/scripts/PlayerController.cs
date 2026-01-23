using Godot;
using System;
public partial class PlayerController:CharacterBody2D
{
	// Called when the node enters the scene tree for the first time.
	private static readonly StringName moveRightAction = "move_right";
	private static readonly StringName moveLeftAction = "move_left";
	private static readonly StringName jumpAction = "ui_accept";

	private static readonly StringName shootAction = "shoot";

	[Export]
	private float _startX= 482.0F;
	[Export]
	private float _startY= 531.0F;
	[Export]
	private float _speed = 120F;

	[Export]
	private float _jumpVelocity = 350F;
	private float downAcceleration = 1;

	[Export]
	private PackedScene _laserPrefab;
	private AudioStreamPlayer2D _shootSound;
	private AnimatedSprite2D animatedSprite2D;

	public override void _Ready()
	{
		Position = new Vector2(_startX, _startY);
		_shootSound = GetNode<AudioStreamPlayer2D>("ShootSound");
		animatedSprite2D = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
	}
	// Called every frame. 'delta' is the elapsed time since the previous frame.

	public void Shoot()
	{
		GD.Print("Pew Pew");
		if (!Input.IsActionPressed(shootAction))
		{
			return;
		}
		if(_laserPrefab is null)
		{
			GD.PrintErr("Laser Prefab is null");
			return;
		}

		var orb = _laserPrefab.Instantiate<Orb>();
		orb.Position = Position + (Vector2.Right * 10F);
		GetParent().AddChild(orb);
	}


	public override void _PhysicsProcess(double delta)
	{		
		Vector2 velocity = Velocity;

		// Add the gravity.
		if (!IsOnFloor())
		{
			velocity += GetGravity()  * (float)delta * downAcceleration;
		}

		// Handle Jump.
		if (Input.IsActionJustPressed(jumpAction) && IsOnFloor())
		{
			velocity.Y += (-1) * _jumpVelocity;
		}

		// Move the player
		if(Input.IsActionPressed(moveRightAction))
		{
			animatedSprite2D.FlipH = false;
			animatedSprite2D.Play("run");
			velocity.X = _speed;
	
		}
		if(Input.IsActionPressed(moveLeftAction))
		{
			animatedSprite2D.FlipH = true;
			animatedSprite2D.Play("run");
			velocity.X = -_speed;
		}

		if (Input.IsActionJustPressed(shootAction))
		{
			_shootSound?.Play(); 
			Shoot();
		}
		if(!Input.IsActionPressed(moveLeftAction) && !Input.IsActionPressed(moveRightAction))
		{
			animatedSprite2D.Play("idle");
			velocity.X = Mathf.MoveToward(Velocity.X, 0, _speed);
		}
		Velocity = velocity;
		MoveAndSlide();
	}

	public void interaction()
	{
		GD.Print("Interacting with object");
	}
	public void damageTaken()
	{
		GD.Print("Player took damage");
	}
}


