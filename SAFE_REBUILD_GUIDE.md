# Safe Docker Rebuild Guide

## Problem: Docker Build Gets Stuck on EC2

**Symptoms:**
- Build process hangs indefinitely
- EC2 instance becomes unresponsive
- No output for several minutes
- High CPU but nothing progressing

**Root Causes:**
1. ClickHouse consuming all CPU during build
2. Insufficient disk space (Docker layers need space)
3. Out of memory during compilation
4. EC2 instance type too small (t3.micro, t3.small)
5. Orphaned Docker processes from previous builds

---

## ✅ Safe Rebuild Process

### Terminal 1: Run the Rebuild

```bash
./scripts/rebuild.sh
```

**What it does:**
- ✅ Checks 10GB+ disk space available
- ✅ Stops all running containers (frees CPU/memory)
- ✅ Cleans up orphaned Docker images/containers
- ✅ Builds with 30-minute timeout (fails if stuck)
- ✅ Waits for services to be healthy
- ✅ Outputs status summary

**Expected output:**
```
📊 Checking disk space...
✅ Disk space OK: 50GB available
🛑 Stopping containers to free resources...
🧹 Cleaning up unused Docker images/containers...
🏗️  Building Docker images (this may take 5-10 minutes)...
⏳ Waiting for services to be ready...
✅ Build completed successfully!
```

### Terminal 2 (Optional): Monitor Build Progress

While build is running in Terminal 1, open Terminal 2 and monitor:

```bash
./scripts/monitor-build.sh
```

**Shows:**
- System memory/disk usage
- Container CPU/memory consumption
- Docker system statistics
- Build log tail
- Updates every 5 seconds

**What to watch for:**
- 🟢 **Good**: Disk usage increasing gradually, CPU high but I/O progressing
- 🔴 **Bad**: Disk full, memory near 100%, no I/O activity (stuck)

---

## 🆘 If Build Hangs

### Option 1: Kill Build & Try Again

**In Terminal 1:**
```bash
Ctrl+C  # Stop the rebuild script
```

Then clean up and retry:

```bash
./scripts/emergency-recovery.sh
./scripts/rebuild.sh  # Try again
```

### Option 2: Emergency Full Recovery

If everything is jammed:

```bash
./scripts/emergency-recovery.sh
```

**What it does:**
- Forces stop all containers
- Removes dangling containers/images
- Runs `docker system prune -af --volumes`
- Shows available disk/memory
- Lists all running containers

Then try rebuild again:

```bash
./scripts/rebuild.sh
```

---

## 🔍 Troubleshooting Stuck Builds

### Issue: "Only 5GB free. Need at least 10GB"

**Solution:**
```bash
# Clean up Docker
docker system prune -a --volumes

# Or delete old containers/images
docker ps -a -q | xargs docker rm
docker images -q | xargs docker rmi -f

# Check space
df -h
```

---

### Issue: Build times out after 30 minutes

**Likely causes:**
1. EC2 instance too small (t3.micro, t3.small)
   - **Solution:** Upgrade to t3.large or t3.xlarge

2. Disk is slow (network volume, magnetic drive)
   - **Solution:** Ensure EBS volumes are gp3 (not gp2)

3. Compilation taking too long
   - **Solution:** Investigate log file (`rebuild.log`)

---

### Issue: "Out of memory" during build

**Solution:**
```bash
# Increase Docker memory limit
docker update --memory 4g <container_name>

# Or stop other services
docker stop $(docker ps -q)

# Then rebuild
./scripts/rebuild.sh
```

---

## 📋 EC2 Instance Requirements

For stable builds, your EC2 instance should have:

| Requirement   | Minimum  | Recommended   |
|---------------|----------|---------------|
| Instance Type | t3.large | t3.xlarge     |
| vCPU          | 2        | 4+            |
| Memory        | 8 GB     | 16 GB         |
| Disk          | 30 GB    | 50+ GB        |
| Disk Type     | gp3      | gp3 (not gp2) |

**Check your instance:**
```bash
# CPU cores
nproc

# Memory (GB)
free -g | grep Mem

# Disk space
df -h /

# Disk type (check AWS console or run)
lsblk
```

If undersized:
1. Go to AWS EC2 Console
2. Stop the instance
3. Change instance type to t3.large or larger
4. Start the instance
5. Try rebuild again

---

## 🚀 Faster Rebuilds After First Build

After the first successful build, subsequent rebuilds are faster because:
- Docker caches layers
- No need to clean up as much

**But still recommended:**
```bash
# Keep cleanup between rebuilds for safety
./scripts/rebuild.sh
```

---

## 📊 Real-time Monitoring

While rebuild is running, you can also open separate terminal:

```bash
# Watch Docker containers
docker stats

# Watch disk usage
watch df -h

# Watch memory
watch free -h

# Tail build log
tail -f rebuild.log
```

---

## ✅ Verification After Successful Build

After rebuild completes, verify services:

```bash
# Check all containers are running
docker-compose -f docker-compose.build.yml ps

# Test web service
curl http://localhost:3002

# Test health endpoint
curl http://localhost:3002/api/public/health

# Check ClickHouse CPU (should now be lower)
./scripts/check-clickhouse-health.sh

# View logs if needed
docker-compose -f docker-compose.build.yml logs -f langfuse-web
```

---

## 🔧 Advanced: Manual Recovery

If automatic recovery doesn't work:

```bash
# Option 1: Violent cleanup
docker rm -f $(docker ps -a -q)
docker rmi -f $(docker images -q)
docker volume prune -f

# Option 2: Restart Docker daemon
systemctl restart docker

# Option 3: Full system cleanup
docker system prune -af --volumes
```

Then try rebuild again.

---

## 📝 Success Indicators

Build was successful when you see:

```
✅ REBUILD COMPLETE!
═════════════════════════════════════════
Services running:
  langfuse-web ...  Up
  langfuse-worker ... Up
  clickhouse ...  Up
  postgres ...  Up
  redis ...  Up
  minio ...  Up

URLs:
  Web:      http://localhost:3002
  Worker:   http://localhost:3030 
```

All services showing "Up" = ✅ Success!

---

## 🆘 Still Having Issues?

Check logs:
```bash
docker-compose -f docker-compose.build.yml logs --tail 100
```

Or check specific service:
```bash
docker-compose -f docker-compose.build.yml logs -f langfuse-web
docker-compose -f docker-compose.build.yml logs -f langfuse-worker
docker-compose -f docker-compose.build.yml logs -f clickhouse
```
