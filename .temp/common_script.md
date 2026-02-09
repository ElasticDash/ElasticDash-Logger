# Common Script collection

## Get the most recently modified objects from s3

```
aws s3api list-objects-v2 --bucket elasticdash-logger --query 'reverse(sort_by(Contents,&LastModified))[:5].[LastModified,K
ey]' --output table
```

## Get the most recent 50 logs from docker container

```
docker logs --tail 50 elasticdash-logger-langfuse-web-1

docker logs --tail 50 elasticdash-logger-langfuse-worker-1
```

## Rebuild docker with latest changes

```
./scripts/rebuild.sh
```
