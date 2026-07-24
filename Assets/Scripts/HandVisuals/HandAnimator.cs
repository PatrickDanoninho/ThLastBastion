using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// This class decides 
/// what pose to use
/// how much to blend (0 → 1) 
/// when to change pose (context)
/// </summary>
public class HandAnimator : MonoBehaviour
{
    public HandRig rig;

    public HandPose openPose;
    public HandPose closePose;

    [Range(0, 1)]
    public float grip;

    public void Update()
    {
        Testing();
        //rig.ApplyPose(openPose, closePose, grip);
    }

    public void Testing() 
    {
        float value = Input.GetAxisRaw("Horizontal");
        grip = value;
    }
}
