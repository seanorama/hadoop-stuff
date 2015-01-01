## Misc Notes on Apache Ambari


If you need to start over with a cluster:

- On Ambari Server:
```
service ambari-server stop
cd /usr/lib/python2.6/site-packages/ambari_agent/
python HostCleanup.py
service ambari-server reset
service ambari-server start
```

- On Ambari Clients:
```

```:w

