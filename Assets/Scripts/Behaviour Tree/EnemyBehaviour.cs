using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.XR.Interaction.Toolkit.Filtering;

public class EnemyBehaviour : MonoBehaviour
{
    BehaviourTree tree;

    public GameObject target;
    public GameObject secondTarget;
    public GameObject hidingPlace;

    public GameObject frontDoor;
    public GameObject backDoor;

    NavMeshAgent agent;

    [Range(0, 1000)]
    public int money = 800;

    /// <summary>
    /// Track if agent is actually moving or just standing still
    /// </summary>
    public enum ActionState { IDLE, WORKING };
    ActionState state = ActionState.IDLE;

    Node.Status treeStatus = Node.Status.RUNNING;

    // Start is called before the first frame update
    void Start()
    {
        agent = GetComponent<NavMeshAgent>();

        tree = new BehaviourTree();
        Sequence follow = new Sequence("Follow Target");
        Leaf goToTarget = new Leaf("Go To Target", GoToTarget);
        Leaf hasMoney = new Leaf("Has got Money", HasMoney);
        Leaf gotToSecondTarget = new Leaf("Go To Second Target", GoToSecondTarget);
        Leaf goHide = new Leaf("Go Hide", GoHide);
        Leaf goFrontDoor = new Leaf("Go Front Door", GoFrontDoor);
        Leaf goBackDoor = new Leaf("Go Back Door", GoBackDoor);
        Selector openDoor = new Selector("Open Door");

        openDoor.AddChild(goBackDoor);
        openDoor.AddChild(goFrontDoor);

        follow.AddChild(hasMoney);

        follow.AddChild(openDoor);
        follow.AddChild(goToTarget);
        follow.AddChild(goHide);
        follow.AddChild(gotToSecondTarget);
        tree.AddChild(follow);

        tree.PrintTree();
    }

    public Node.Status HasMoney()
    {
        if (money >= 500)
            return Node.Status.FAILURE;

        return Node.Status.SUCCESS;
    }

    public Node.Status GoToTarget()
    {
        Node.Status s = GoToLocation(target.transform.position);
        if (s == Node.Status.SUCCESS) 
        {
            target.transform.parent = transform;
        }
        return s;
    }

    public Node.Status GoToSecondTarget()
    {
        Node.Status s = GoToLocation(secondTarget.transform.position);
        if (s == Node.Status.SUCCESS) 
        {
            money += 300;
            target.SetActive(false);
        }

        return s;
    }

    public Node.Status GoHide()
    {
        return GoToLocation(hidingPlace.transform.position);
    }

    public Node.Status GoToDoor(GameObject door)
    {
        Node.Status s = GoToLocation(door.transform.position);
        if (s == Node.Status.SUCCESS)
        {
            if (!door.GetComponent<Lock>().isLocked)
            {
                door.SetActive(false);
                return Node.Status.SUCCESS;
            }
            return Node.Status.FAILURE;
        }
        else return s;
    }

    public Node.Status GoFrontDoor()
    {
        return GoToDoor(frontDoor);
    }

    public Node.Status GoBackDoor()
    {
        return GoToDoor(backDoor);
    }

    /// <summary>
    /// One single method to move the Agent to the <param name="destination"></param>
    /// while checking if it should be moving or not
    /// </summary>
    /// <returns></returns>
    Node.Status GoToLocation(Vector3 destination)
    {
        float distance = Vector3.Distance(destination, transform.position);
        if (state == ActionState.IDLE)
        {
            agent.SetDestination(destination);
            state = ActionState.WORKING;
        }
        else if (agent.pathStatus == NavMeshPathStatus.PathInvalid) //If cannot reach destination
        {
            state = ActionState.IDLE;
            return Node.Status.FAILURE;
        }
        else if (distance < 2)
        {
            state = ActionState.IDLE;
            return Node.Status.SUCCESS;
        }
        return Node.Status.RUNNING;
    }

    // Update is called once per frame
    void Update()
    {
        if (treeStatus != Node.Status.SUCCESS)
            treeStatus = tree.Process();
    }
}
