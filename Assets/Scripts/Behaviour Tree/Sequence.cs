using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class Sequence : Node
{
    public Sequence(string n) 
    {
        name = n;
    }

    public override Status Process()
    {
        Status childStatus = children[currentChild].Process();

        Debug.Log("Processing " + children[currentChild].name + " and it is " + childStatus);

        if(childStatus == Status.RUNNING)
            return Status.RUNNING;
        if(childStatus == Status.FAILURE)
            return childStatus;

        currentChild++;
        if (currentChild >= children.Count)
        {
            currentChild = 0;
            return Status.SUCCESS;
        }

        return Status.RUNNING;
    }
}
