using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// The Body
/// holds bone references
/// applies rotations to bones
/// </summary>
public class HandRig : MonoBehaviour
{
    public Transform[] thumb;
    public Transform[] index;
    public Transform[] middle;
    public Transform[] ring;
    public Transform[] pinky;

    public void ApplyPose(HandPose open, HandPose closed, float t) 
    {
        ApplyFinger(thumb, open.thumb, closed.thumb, t);
        ApplyFinger(index, open.index, closed.index, t);
        ApplyFinger(middle, open.middle, closed.middle, t);
        ApplyFinger(ring, open.ring, closed.ring, t);
        ApplyFinger(pinky, open.pinky, closed.pinky, t);
    }

    public void ApplyFinger(Transform[] bones, FingerPose open, FingerPose closed, float t) 
    {
        for (int i = 0; i < bones.Length; i++)
        {
            bones[i].localRotation = Quaternion.Slerp(open.rotations[i], closed.rotations[i], t);
        }
    }
}
