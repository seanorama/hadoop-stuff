### Hive Benchmark: https://github.com/cartershanklin/hive-testbench

 - SSH to a HiveClient
 - Prep:

  ```
  sudo yum groupinstall -y "Development tools"
  ```

- Follow instructions: https://github.com/cartershanklin/hive-testbench

- Just to confirm hive is read:
```
sudo su - hive
git clone https://github.com/seanorama/hive-testbench
cd hive-testbench
./tpcds-build.sh
./tpcds-setup.sh 2
cd sample-queries-tpcds
hive
hive > use tpcds_bin_partitioned_orc_2;
hive > source query55.sql;
```
