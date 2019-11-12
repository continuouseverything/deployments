# Deployment Strategies

## Rolling Update
![Rolling Update](https://raw.githubusercontent.com/continuouseverything/deployments/master/rolling.png)
* Scale up the new replication controller based on the surge count.
* Scale down the old replication controller based on the max unavailable count.
* Repeat this scaling until the new replication controller has reached the desired replica count and the old replication controller has been scaled to zero.

```
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
```

```
$ kubectl create -f rolling.yaml

$ kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
timemachine-5f7c5b7fdc-9tnqp   1/1     Running   0          89s
timemachine-5f7c5b7fdc-gxfrl   1/1     Running   0          89s
timemachine-5f7c5b7fdc-jhfb8   1/1     Running   0          89s
timemachine-5f7c5b7fdc-psnkj   1/1     Running   0          89s


$ kubectl get deployment timemachine -o json | jq -r '.spec.template.spec.containers[0].image'
continuouseverything1/timemachine:6a4cd20


$ kubectl set image deployment timemachine timemachine=timemachine:1.1234 
deployment.extensions/timemachine image updated


$ kubectl get pods
NAME                           READY   STATUS             RESTARTS   AGE
timemachine-57b4bb6f76-jscrp   0/1     ImagePullBackOff   0          31s
timemachine-57b4bb6f76-sbtp5   0/1     ErrImagePull       0          32s
timemachine-5f7c5b7fdc-9tnqp   1/1     Running            0          4m2s
timemachine-5f7c5b7fdc-gxfrl   1/1     Running            0          4m2s
timemachine-5f7c5b7fdc-jhfb8   1/1     Running            0          4m2s


$ kubectl set image deployment timemachine timemachine=continuouseverything1/timemachine:ab8a868

$ kubectl get pods
NAME                           READY   STATUS              RESTARTS   AGE
timemachine-57659ff46c-6mwsw   1/1     Running             0          7s
timemachine-57659ff46c-dpmhn   1/1     Running             0          1s
timemachine-57659ff46c-gqm46   1/1     Running             0          7s
timemachine-57659ff46c-rcj8z   0/1     ContainerCreating   0          0s
timemachine-5f7c5b7fdc-9tnqp   1/1     Terminating         0          11m
timemachine-5f7c5b7fdc-gxfrl   0/1     Terminating         0          11m
timemachine-5f7c5b7fdc-jhfb8   1/1     Terminating         0          11m


$ kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
timemachine-57659ff46c-6mwsw   1/1     Running   0          15s
timemachine-57659ff46c-dpmhn   1/1     Running   0          9s
timemachine-57659ff46c-gqm46   1/1     Running   0          15s
timemachine-57659ff46c-rcj8z   1/1     Running   0          8s


$ kubectl get deployment timemachine -o json | jq -r '.spec.template.spec.containers[0].image'
continuouseverything1/timemachine:ab8a868
```


## Blue Green Deployment
![Blue Green Deployment](https://raw.githubusercontent.com/continuouseverything/deployments/master/blue_green.png)
* Blue version currently in production.
* Create deployment for green, with same name, different version.
* Create service with name and version of deployment you would like to point.
* After testing green version, update service with green's version.
* After testing that green version works correctly, delete blue version.

```
$ kubectl create -f blue.yaml
deployment.apps/timemachine-1.11 created
$ kubectl create -f service.yaml
service/timemachine created
$ ./blue_green.sh timemachine 1.11 1.12 green.yaml
Pods:

NAME                                READY   STATUS    RESTARTS   AGE
timemachine-1.11-77db94b986-98wqr   1/1     Running   0          27s
timemachine-1.11-77db94b986-lg8c2   1/1     Running   0          27s
timemachine-1.11-77db94b986-q2t5w   1/1     Running   0          27s
timemachine-1.11-77db94b986-v4rcq   1/1     Running   0          27s

Deploy new version...
deployment.apps/timemachine-1.12 created

Wait until new version is ready...
... new version is ready:
NAME                                READY   STATUS    RESTARTS   AGE
timemachine-1.11-77db94b986-98wqr   1/1     Running   0          37s
timemachine-1.11-77db94b986-lg8c2   1/1     Running   0          37s
timemachine-1.11-77db94b986-q2t5w   1/1     Running   0          37s
timemachine-1.11-77db94b986-v4rcq   1/1     Running   0          37s
timemachine-1.12-9978dd6ff-94srm    1/1     Running   0          10s
timemachine-1.12-9978dd6ff-lrbtk    1/1     Running   0          10s
timemachine-1.12-9978dd6ff-qllfs    1/1     Running   0          10s
timemachine-1.12-9978dd6ff-znd6c    1/1     Running   0          10s

Release...
- Update service with the new version...
service/timemachine patched
- TODO: Check that new version runs stable.
- Delete old version...
deployment.extensions "timemachine-1.11" deleted
... Release finished.

$ kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
timemachine-1.12-9978dd6ff-94srm   1/1     Running   0          18s
timemachine-1.12-9978dd6ff-lrbtk   1/1     Running   0          18s
timemachine-1.12-9978dd6ff-qllfs   1/1     Running   0          18s
timemachine-1.12-9978dd6ff-znd6c   1/1     Running   0          18s
```

## Canary
You can use the ReplicaSet to raise as many pods as necessary to get the right percentage of traffic.
```
kubectl edit deployment timemachine-1.12
```
In practice, using a service mesh may make more sense for those use cases.


# Appendix

If you want to access the app, you can use NodePort as service type and then connect with the node's IP and port:
```
<node's IP>:port
```
However, note that using NodePort shall be only used for debugging and NOT in production!

You can use JSONPath to get the IPs of all your nodes:
```
$ kubectl get nodes -o jsonpath='{.items[*].status. addresses[?(@.type=="ExternalIP")].address}'
```

Get Port number:
```
$ kubectl get svc <name>
```
