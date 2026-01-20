using Godot;
using System;
using System.Reflection.Metadata;

public partial class Coin : Node2D
{
	// Called when the node enters the scene tree for the first time.

	private AnimatedSprite2D? _mainSprite;
	private AnimatedSprite2D? _pickupSprite;
	private bool _isPickedUp = false;
	public override void _Ready()
	{
		_mainSprite = GetNode<AnimatedSprite2D>("Collider/CoinAnim") ?? throw new NullReferenceException("Could not find AnimatedSprite2D node 'Collider/CoinAnim'");
		_pickupSprite = GetNode<AnimatedSprite2D>("CoinPickUpAnim") ?? throw new NullReferenceException("Could not find AnimatedSprite2D node 'PickupAnim'");
		_isPickedUp = false;
		_pickupSprite.Hide();
		_pickupSprite.AnimationFinished += HandlePickupAnimationFinished;
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

	public void OnCollision(CharacterBody2D other)
	{
		GD.Print("Coin collided with player");
		// QueueFree();
		_mainSprite?.Hide();
		_pickupSprite?.Show();
		_pickupSprite?.Play();
	}

	private void HandlePickupAnimationFinished()
	{
		
		QueueFree();
	}
}
