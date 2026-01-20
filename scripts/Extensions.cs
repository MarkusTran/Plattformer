using Godot;
using System;

public static partial class Extensions
{
    public static T GetNodeOrThrow<T>(this Node node, NodePath path) where T : Node
    => node.GetNode<T>(path)
       ?? throw new NullReferenceException(
           $"Could not find node of type {typeof(T).Name} at path '{path}'");

}
