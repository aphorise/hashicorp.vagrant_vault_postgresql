# HashiCorp `vagrant` demo of **`vault`** with DB PostgreSQL Secrets Engine.
This repo contains a `Vagrantfile` mock of a [Vault](https://www.vaultproject.io/) server setup with [Vault Database Secrets Engine](https://www.vaultproject.io/docs/secrets/databases/) enabled & configured to [PostgreSQL](https://www.vaultproject.io/docs/secrets/databases/postgresql/) via PG_ADMIN user on the application database (PG_DB).

[![demo](https://asciinema.org/a/308019.svg)](https://asciinema.org/a/308019?autoplay=1)


## Makeup & Concept

The PostgreSQL server (postgresql) is generated first with a default DB and a privileged user for Vault.
The second generated host is a vault server (vault1 - in development mode) that's configured with the database secrets engine enabled. The privileged user credentials are rotated by vault; a readonly role is written to allow for credentials generated dynamically on request in a read only capacity with a default TTL of 1hr.


A depiction below shows the intended relations & the actors that may be either users or applications interfacing with Vault.

```
                       Dynamic Credentials to Read
                    🌍           🌍
                💻--||--     💻--||-- 🔑 →→→→→↘ 
           ...     / \  ...     / \             ↘ 
                                                  ↘  
                     🔐🔐🔐🔐🔐🔐                     ↘ 
                .___⇪_⇪_⇪_⇪_⇪_⇪___.252                ↘.…………………………………………….190
                |     vault1      |                    ┊    PostgreSQL   ┊
                |     server      |-------------------►┊     Database    ┊
                |_________________|                    └……………………………………………┘ 
                | Vault DB roles: |
                |┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄|┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄!. 
                |database/static-roles/myapp_admin ┊_╲           
                |database/roles/myapp_readonly       ┊         
                ╰┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄╯
```

The privileged postgresql user (PG_ADMIN) is created for the purposes of dynamic user creation, rotation of self (PG_ADMIN) and other credentials.  
The initial password of PG_ADMIN during install is rotated by Vault. Requests for credential creation, (as `myapp_readonly`) may may via:
```
vault write -f database/rotate-role/myapp ; # // Rotate key
vault read database/static-creds/myapp ; # // Read new key
```

**NOTE**: connectivity to vault1 is not drawn above (for simplicity).
Private IP Address Class D is defined in the **`Vagrantfile`** and can be adjusted to your local network if needed.
A.B.C.190 node is consider as the PostgreSQL host instance.


### Prerequisites
Ensure that you already have the following hardware & software requirements:
 
##### HARDWARE
 - **RAM** **2**+ Gb Free at least (ensure you're not hitting SWAP either or are < 100Mb)
 - **CPU** **2**+ Cores Free at least (2 or more per instance better) 
 - **Network** interface allowing IP assignment and interconnection in VirtualBox bridged mode for all instances.
 - - adjust `sNET='en0: Wi-Fi (Wireless)'` in **`Vagrantfile`** to match your system.

##### SOFTWARE
 - [**Virtualbox**](https://www.virtualbox.org/)
 - [**Virtualbox Guest Additions (VBox GA)**](https://download.virtualbox.org/virtualbox/)
 - > **MacOS** (aka OSX) - VirtualBox 6.x+ is expected to be shipped with the related .iso present under (eg):
 `/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso`
You may however need to download the .iso specific to your version (mount it) and execute the VBoxDarwinAdditions.pkg
 - [**Vagrant**](https://www.vagrantup.com/)
 - **Few** **`shell`** or **`screen`** sessions to allow for multiple SSH sessions.
 

## Usage & Workflow
Refer to the contents of **`Vagrantfile`** for the number of instances, resources, Network, IP and provisioning steps.
The provided **`.sh`** script are installer helpers that download the latest vault binaries (or specific versions) and sets configurations for PostgreSQL integration.

**Inline Environment Variables** can be set for specific versions and other settings that are part of `3.install_vault_postgresql.sh`.

```bash
vagrant up --provider virtualbox ;
# // ... output of provisioning steps.
vagrant global-status ; # should show running nodes
# id       name    provider   state   directory
# -------------------------------------------------------------------------------
# 53192d0  postgresql virtualbox running /home/auser/hashicorp.vagrant_vault_postgresql
# 1fc423c  vault1     virtualbox running /home/auser/hashicorp.vagrant_vault_postgresql

# // SSH to vault1
vagrant ssh vault1 ;
# // ...
vagrant@vault1:~$ \
vault read database/creds/myapp_readonly ; # // Generate credentials.
# ... repeat creating as many as desired.
vagrant@vault1:~$ \
vault list /sys/leases/lookup/database/creds/myapp_readonly/
# ... see how many you've generated;

# // SSH to postgresql host - on another session ;
vagrant ssh postgresql ;
vagrant@postgresql:~$ \
psql -U postgres -c "\du;" ; # // should show all generated users.

# // Continue back on vault1 to revoke / delete creds.

# // ---------------------------------------------------------------------------
# when completely done:
vagrant destroy -f postgresql vault1 ; # ... destroy al
vagrant box remove -f debian/buster64 --provider virtualbox ; # ... delete box images
```


## Notes
This is intended as a mere practise / training exercise.

See also more information at:
 - [PostgreSQL Database Plugin HTTP API](https://www.vaultproject.io/api/secret/databases/postgresql.html)
 - [db-creds-rotation @ learn](https://learn.hashicorp.com/vault/secrets-management/db-creds-rotation)
 - [sm-dynamic-secrets @ learn](https://learn.hashicorp.com/vault/secrets-management/sm-dynamic-secrets)
 - [db-root-rotation @ learn](https://learn.hashicorp.com/vault/secrets-management/db-root-rotation)
 - [sm-app-integration @ learn](https://learn.hashicorp.com/vault/developer/sm-app-integration)

------
