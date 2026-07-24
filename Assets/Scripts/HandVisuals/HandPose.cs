using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Data
/// a snapshot of finger rotations
/// </summary>
[CreateAssetMenu]
public class HandPose : ScriptableObject
{
    public FingerPose thumb;
    public FingerPose index;
    public FingerPose middle;
    public FingerPose ring;
    public FingerPose pinky;
}
