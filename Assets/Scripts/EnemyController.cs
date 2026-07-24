using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.Pool;
using UnityEngine.Rendering.Universal;

public class EnemyController : MonoBehaviour
{
    public GameObject target;
    public NavMeshAgent agent;
    public CapsuleCollider agentCapsule;

    [Header("Leader")]
    public bool isLeader = false;
    public EnemyController leader;

    Vector3 formationOffset;
    Vector3 followerTarget;

    Renderer enemyRenderer;

    public float followerSpeed = 20f;
    public float navMeshSwitchDistance = 10f;

    public void Awake()
    {
        enemyRenderer = GetComponent<Renderer>();
    }

    public void OnEnable()
    {
        EnemyManager.Instance.OnLeaderChanged += SetLeader;
        formationOffset = new Vector3(Random.Range(-2f, 2f), 0, Random.Range(-2f, 2f));
        InvokeRepeating(nameof(UpdateLeaderPath), 1f, 0.25f);        
    }
    public void OnDisable()
    {
        EnemyManager.Instance.OnLeaderChanged -= SetLeader;
        CancelInvoke();
    }

    void SetLeader(EnemyController newLeader) 
    {
        leader = newLeader;
        isLeader = (newLeader == this);
    }

    private void Update()
    {
        if (!isLeader && leader != null) 
        {
            transform.position = Vector3.MoveTowards(transform.position, followerTarget, followerSpeed * Time.deltaTime);
        }
    }

    public void UpdateLeaderPath() 
    {
        float dista = GetDistanceFromPlayer();

        if (isLeader)
        {
            enemyRenderer.material.color = Color.yellow;

            agent.enabled = true;
            agentCapsule.enabled = false;
            if (dista <= 2f)
            {
                agent.destination = transform.position;
                EnemyManager.Instance.ReUseEnemy(this);
            }
            else
                agent.destination = target.transform.position;
        }
        else
        {
            if (leader == null)
                return;

            enemyRenderer.material.color = Color.red;

            agentCapsule.enabled = true;
            agent.enabled = false;
            followerTarget = leader.transform.position;
        }
    }

    public float GetDistanceFromPlayer()
    {
        float dist = (transform.position - target.transform.position).sqrMagnitude;
        return dist;
    }
}
