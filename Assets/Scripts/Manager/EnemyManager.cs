using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyManager : MonoBehaviour
{
    public static EnemyManager Instance;

    [Header("Containers")]
    [SerializeField] Transform activeEnemyContainer;
    [SerializeField] Transform pooledEnemyContainer;

    [Header("Enemy")]
    [SerializeField] int enemiesToSpawn = 0;
    [SerializeField] GameObject enemyPrefab;
    [SerializeField] List<EnemyController> enemiesInUseList = new List<EnemyController>();
    [SerializeField] List<EnemyController> enemiesWaitingList = new List<EnemyController>();
    [SerializeField] GameObject spawnPos;
    [SerializeField] GameObject target;

    [Header("Leader")]
    //[SerializeField] int groupSize = 10;
    public EnemyController currentLeader;
    public Action<EnemyController> OnLeaderChanged;

    public void Awake()
    {
        if (Instance != null && Instance != this)
            Destroy(gameObject);
        else
        {
            Instance = this;
            DontDestroyOnLoad(Instance);
        }
    }

    public void Start()
    {
        PlaceEnemies();

        InvokeRepeating(nameof(UpdateLeader), 0f, 0.5f);
    }

    public void UpdateLeader() 
    {
        float closestDist = float.MaxValue;
        EnemyController closestEnemy = null;

        foreach (EnemyController enemy in enemiesInUseList)
        {
            float dist = (enemy.transform.position - target.transform.position).sqrMagnitude;

            if (dist < closestDist) 
            {
                closestDist = dist;
                closestEnemy = enemy;
            }
        }

        if (closestEnemy != currentLeader) 
        {
            currentLeader = closestEnemy;
            OnLeaderChanged?.Invoke(currentLeader);
        }
    }

    public void PlaceEnemies() 
    {
        for (int i = 0; i < enemiesToSpawn; i++)
        {
            GameObject enemy = Instantiate(enemyPrefab, spawnPos.transform.position, Quaternion.identity, activeEnemyContainer);
            EnemyController enemyController = enemy.GetComponent<EnemyController>();
            enemyController.target = target;
            enemiesInUseList.Add(enemyController);
        }
    }

    public void ReUseEnemy(EnemyController enemyToReUse) 
    {
        enemyToReUse.gameObject.SetActive(false);
        enemyToReUse.transform.parent = pooledEnemyContainer;

        enemiesInUseList.Remove(enemyToReUse);
        enemiesWaitingList.Add(enemyToReUse);
        
        if (enemiesWaitingList.Count >= 10)
        {
            for (int i = 0; i < enemiesWaitingList.Count - 1; i++)
            {
                enemiesWaitingList[i].transform.position = spawnPos.transform.position;
                enemiesWaitingList[i].gameObject.SetActive(true);
                enemiesWaitingList[i].transform.parent = activeEnemyContainer;

                enemiesInUseList.Add(enemiesWaitingList[0]);
                enemiesWaitingList.RemoveAt(0);
            }
        }
    }
}
