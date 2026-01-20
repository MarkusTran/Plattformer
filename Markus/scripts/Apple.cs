using Godot;
using System;

public partial class Apple : Node2D
{
    public void OnCollision(CharacterBody2D other)
    {
        GD.Print("Apple collided with player");
        QueueFree();
    }
}
