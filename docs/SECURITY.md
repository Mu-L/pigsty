# Security Considerations

> If security concerns you, you should be aware of the following options.


## Confidentiality


**Credentials**

* Secure your CA private key and other certs
  - These files are very important, and will be generated under `files/pki` under pigsty source dir by default.
  - You should secure & backup them in a safe place


**Passwords**

* Always change these passwords, DO NOT USE THE DEFAULT VALUES:
  - [`grafana_admin_password`](PARAM#grafana_admin_password)   : `pigsty`
  - [`pg_admin_password`](PARAM#pg_admin_password)             : `DBUser.DBA`
  - [`pg_monitor_password`](PARAM#pg_monitor_password)         : `DBUser.Monitor`
  - [`pg_replication_password`](PARAM#pg_replication_password) : `DBUser.Replicator`
  - [`patroni_password`](PARAM#patroni_password)               : `Patroni.API`
  - [`haproxy_admin_password`](PARAM#haproxy_admin_password)   : `pigsty`

* Use advanced password encryption method for PostgreSQL
  - use [`pg_pwd_enc`](PARAM#pg_pwd_enc) default `scram-sha-256` instead of legacy `md5`

* Enforce a strong pg password with the `passwordcheck` extension.
  - add `$lib/passwordcheck` to [`pg_libs`](PARAM#pg_libs) to enforce password policy.

* Encrypt remote backup with an encryption algorithm
  - check [`pgbackrest_repo`](PARAM#pgbackrest_repo) definition `repo_cipher_type`

* Add an expiration date to biz user passwords.
  - You can set an expiry date for each user for compliance purposes.
  - Don't forget to refresh these passwords periodically.

  ```yaml
  - { name: dbuser_meta , password: Pleas3-ChangeThisPwd ,expire_in: 7300 ,pgbouncer: true ,roles: [ dbrole_admin ]    ,comment: pigsty admin user }
  - { name: dbuser_view , password: Make.3ure-Compl1ance  ,expire_in: 7300 ,pgbouncer: true ,roles: [ dbrole_readonly ] ,comment: read-only viewer for meta database }
  - { name: postgres     ,superuser: true  ,expire_in: 7300                        ,comment: system superuser }
  - { name: replicator ,replication: true  ,expire_in: 7300 ,roles: [pg_monitor, dbrole_readonly]   ,comment: system replicator }
  - { name: dbuser_dba   ,superuser: true  ,expire_in: 7300 ,roles: [dbrole_admin]  ,pgbouncer: true ,pool_mode: session, pool_connlimit: 16 , comment: pgsql admin user }
  - { name: dbuser_monitor ,roles: [pg_monitor] ,expire_in: 7300 ,pgbouncer: true ,parameters: {log_min_duration_statement: 1000 } ,pool_mode: session ,pool_connlimit: 8 ,comment: pgsql monitor user }
  ```

* Do not log changing password statement into postgres log.

  ```bash
  SET log_statement TO 'none';
  ALTER USER "{{ user.name }}" PASSWORD '{{ user.password }}';
  SET log_statement TO DEFAULT;
  ```


**IP Addresses**

* Bind to specific IP addresses rather than all addresses for postgres/pgbouncer/patroni
  - The default [`pg_listen`](PARAM#pg_listen) address is `0.0.0.0`, which is all IPv4 addresses.
  - consider using `pg_listen: '${ip},${vip},${lo}'` to bind to specific addresses for better security.

* Do not expose any port to the Internet; except 80/443, the infra portal.
  - You have to implement it with the security group or firewall rules.

* Limit postgres client access with [HBA](PGSQL-HBA)
  - There's a security enhance config template: [`security.yml`](https://github.com/Vonng/pigsty/blob/master/files/pigsty/security.yml)

* Limit patroni admin access from the infra/admin node.
  - This is restricted by default with [`restapi.allowlist`](https://github.com/Vonng/pigsty/blob/master/roles/pgsql/templates/oltp.yml#L109)



**Net Traffic**

* Access Nginx with SSL and domain names
  - Nginx SSL is controlled by [`nginx_sslmode`](PARAM#nginx_sslmode), which is `enable` by default.
  - Nginx Domain names are specified by [`infra_portal.<value>.domain`](PARAM#infra_portal).

* Secure Patroni REST API with SSL
  - [`patroni_ssl_enabled`](PARAM#patroni_ssl_enabled) is disabled by default
  - Since it affects health checks and API invocation.
  - Note this is a global option, and you have to decide before deployment.

* Secure Pgbouncer Client Traffic with SSL
  - [`pgbouncer_sslmode`](PARAM#pgbouncer_sslmode) is `disable` by default
  - Since it has a significant performance impact.



## Integrity

**Consistency**

* Use consistency-first mode for PostgreSQL.
  - Use `crit.yml` templates for [`pg_conf`](PARAM#pg_conf) will trade some availability for the best consistency.

* Use a critical node tuning template for better consistency.
  - Use `crit` templates for [`node_tune`](PARAM#node_tune) to reduce the dirty page ratio.

* Enable data checksum to detect silent data corruption.
  - [`pg_checksum`](PARAM#pg_checksum) is disabled by default, and enabled for `crit.yml` by default
  - This can be enabled later, which requires a full cluster scan/stop.


**Audit**

* Enable `log_connections` and `log_disconnections` after the pg cluster bootstrap.
  - Audit incoming sessions; this is enabled in `crit.yml` by default.




## Availability

* Do not access the database directly via a fixed IP address; use VIP, DNS, HAProxy, or their combination.
  - Haproxy will handle the traffic control for the clients in case of failover/switchover.

* Use enough nodes for serious production deployment.
  - You need at least three nodes (tolerate one node failure) to achieve production-grade high availability.
  - If you only have two nodes, you can tolerate the failure of the specific standby node.
  - If you have one node, use an external S3/MinIO for cold backup & wal archive storage.

* Trade off between availability and consistency for PostgreSQL.
  - [`pg_rpo`](PARAM#pg_rpo) : **trade-off between Availability and Consistency**
  - [`pg_rto`](PARAM#pg_rto) : **trade-off between failure chance and impact**

* Use multiple infra nodes in serious production deployment (e.g., 1~3)
  - Usually, 2 ~ 3 is enough for a large production deployment.

* Use enough etcd members and use even numbers (1,3,5,7).
  - Check [ETCD Administration](ETCD-ADMIN) for details.


