using Godot;
using System;

public sealed partial class Orb : Area2D
{
	private static float? _destructionX;
	private bool _isDestroyed = false;

	private AudioStreamPlayer2D _explosionSound;

	[Export]
	private float _speed = 400F;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{

		//Lifetime
		GetTree().CreateTimer(4.0).Timeout += QueueFree;
		_explosionSound.Finished += QueueFree;

		// Offscreen
		// GetNode<VisibleOnScreenNotifier2D>("VisibleOnScreenNotifier2D").ScreenExited += QueueFree;

		// _destructionX ??= CalcDestructionY();



		// float CalcDestructionY()
		// {
		// 	var textureHeight = Texture.GetSize().X * Scale.X;
		// 	return -1 * (textureHeight* 0.5F + 1F);
		// }

		// return;
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{	
		if (_isDestroyed)
		{
			return;
		}
		Translate (Vector2.Right * (float)(delta * _speed));
	}

	public void OnCollision(Node2D other)
	{

		if(other is TileMapLayer)
		{
			GD.Print("Orb hit TileMapLayer");
			this.GetNodeOrThrow<AudioStreamPlayer2D>("ExplosionSound").Play();
			_isDestroyed = true;
			// QueueFree();
			return;
		}if(other is StaticBody2D)
		{
			GD.Print("Orb hit StaticBody2D");
			this.GetNodeOrThrow<AudioStreamPlayer2D>("ExplosionSound").Play();
			_isDestroyed = true;
			// QueueFree();
			return;
		}
		
	}



}
