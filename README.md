# vault-container

A container used to deploy a Hashicorp Vault on a Docker infrastructure

```bash
docker volume create vault_data
docker volume create vault_config
docker volume create vault_logs

docker run --cap-add=IPC_LOCK -d --env VAULT_X509_SUBJECT="/C=FR/ST=Brittany/L=Brest/O=Article714/OU=Secrets/CN=myvault" --env VAULT_X509_ALTNAMES="DNS:myvault.mydomain.com,DNS:myvault.localhost" -v vault_data:/vault/file -v vault_logs:/var/log -v vault_config:/container/config --name local_vault article714/vault-container
```
