# Rocket Pool Holesky Node Complete Guide

## Overview

This comprehensive guide covers the complete setup, monitoring, and maintenance of a Rocket Pool Holesky testnet node. The setup includes execution client (Geth), consensus client (Lighthouse), and monitoring stack (Prometheus + Grafana).

## Prerequisites

- **Hardware Requirements**:
  - 8GB RAM minimum (16GB recommended)
  - 500GB SSD storage minimum
  - Stable internet connection
  - Docker and Docker Compose installed

- **Software Requirements**:
  - Docker Engine 20.10+
  - Docker Compose 2.0+
  - curl for API testing
  - jq for JSON processing (optional but recommended)

## Architecture Overview

### Components

1. **Execution Layer**: Geth client for transaction processing
2. **Consensus Layer**: Lighthouse beacon node for proof-of-stake consensus
3. **Monitoring**: Prometheus metrics collection and Grafana visualization
4. **Rocket Pool**: Node management and staking pool participation

### Network Configuration

- **Network**: Holesky testnet
- **JWT Secret**: Shared authentication between execution and consensus clients
- **Ports**:
  - Geth: 8545 (HTTP RPC), 8546 (WebSocket), 30303 (P2P)
  - Lighthouse: 9000 (P2P), 5052 (HTTP API)
  - Prometheus: 9090
  - Grafana: 3000

## Initial Setup

### 1. Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd rocketpool-eth-node

# Review the docker-compose.yml configuration
cat docker-compose.yml
```

### 2. JWT Secret Generation

The JWT secret is automatically generated when first starting the containers. It's stored in `execution-data/geth/jwtsecret`.

### 3. Start the Node

```bash
# Start all services
docker-compose up -d

# Check container status
docker-compose ps

# View logs
docker-compose logs -f
```

## Monitoring and Status

### Quick Status Check

Use the monitoring scripts in the `scripts/monitoring/` directory:

```bash
# Simple status overview
./scripts/monitoring/monitor-simple.sh

# Complete status with sync information
./scripts/monitoring/monitor-complete-status.sh

# Holesky-specific monitoring
./scripts/monitoring/monitor-holesky.sh
```

### Container Health

```bash
# Check all containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check specific container logs
docker logs rocketpool-eth-node-geth-1
docker logs rocketpool-eth-node-lighthouse-1
```

### Sync Status

#### Execution Client (Geth)

```bash
# Check sync status
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545 | jq

# Check latest block
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 | jq
```

#### Consensus Client (Lighthouse)

```bash
# Check sync status
curl -s http://localhost:5052/eth/v1/node/syncing | jq

# Check node health
curl -s http://localhost:5052/eth/v1/node/health

# Check peer count
curl -s http://localhost:5052/eth/v1/node/peer_count | jq
```

## Grafana Dashboards

### Access Grafana

1. Open browser to `http://localhost:3000`
2. Login with default credentials (admin/admin)
3. Change password when prompted

### Available Dashboards

1. **Ethereum Node Dashboard**: General node metrics
2. **Rocket Pool Node Dashboard**: Rocket Pool specific metrics

### Key Metrics to Monitor

- **Sync Status**: Both execution and consensus clients must be synced
- **Peer Connections**: Healthy peer count (20+ peers recommended)
- **Block Processing**: Regular block reception and processing
- **Finalized Blocks**: Consensus finalization (may be zero during initial sync)
- **Resource Usage**: CPU, memory, disk usage

## Troubleshooting

### Common Issues

#### 1. Consensus Client Not Receiving Updates

**Symptoms**: "Beacon client online, but no consensus updates received in a while"

**Causes**:

- Execution client not fully synced
- Network connectivity issues
- JWT authentication problems

**Solutions**:

```bash
# Check execution client sync
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545

# Check JWT secret exists
ls -la execution-data/geth/jwtsecret

# Restart containers if needed
docker-compose restart
```

#### 2. Finalized Block Count is Zero

**Cause**: Normal during initial sync phase

**Explanation**: Finalization requires:

- Full execution client sync
- Consensus client sync
- Active validator participation
- Network-wide consensus (2/3 validators)

**Monitor Progress**:

```bash
# Check if still syncing
curl -s http://localhost:5052/eth/v1/node/syncing | jq '.data.is_syncing'

# Check sync distance
curl -s http://localhost:5052/eth/v1/node/syncing | jq '.data.sync_distance'
```

#### 3. Container Startup Issues

**Check Docker logs**:

```bash
# View recent logs
docker-compose logs --tail=50 <service-name>

# Follow logs in real-time
docker-compose logs -f <service-name>
```

**Common solutions**:

- Ensure sufficient disk space
- Check port conflicts
- Verify Docker daemon is running
- Restart Docker service if needed

### Log Analysis

#### Geth Logs

```bash
# Monitor Geth sync progress
docker logs rocketpool-eth-node-geth-1 2>&1 | grep -E "(Syncing|Imported|Looking for peers)"

# Check for errors
docker logs rocketpool-eth-node-geth-1 2>&1 | grep -i error
```

#### Lighthouse Logs

```bash
# Monitor beacon sync
docker logs rocketpool-eth-node-lighthouse-1 2>&1 | grep -E "(Syncing|Synced|Downloading)"

# Check consensus updates
docker logs rocketpool-eth-node-lighthouse-1 2>&1 | grep -E "(Consensus|Finalized)"
```

## Maintenance Tasks

### Regular Monitoring

1. **Daily**: Check container status and sync progress
2. **Weekly**: Review Grafana dashboards and metrics
3. **Monthly**: Check disk usage and clean up old logs

### Log Rotation

Docker automatically rotates logs, but you can manually clean them:

```bash
# Clean Docker logs
docker system prune -f

# Clean specific container logs
truncate -s 0 $(docker inspect --format='{{.LogPath}}' <container_name>)
```

### Backup Important Data

```bash
# Backup JWT secret
cp execution-data/geth/jwtsecret backup/

# Backup Grafana dashboards
cp -r grafana/ backup/grafana-$(date +%Y%m%d)/
```

## Performance Optimization

### Resource Monitoring

```bash
# Monitor resource usage
docker stats

# Check disk usage
du -sh execution-data/ consensus-data/

# Monitor network usage
docker exec rocketpool-eth-node-geth-1 geth --exec "net.peerCount" attach
```

### Optimization Tips

1. **SSD Storage**: Use SSD for better I/O performance
2. **RAM**: Increase if sync is slow (16GB recommended)
3. **Network**: Ensure stable, high-bandwidth connection
4. **Firewall**: Open required ports for P2P connections

## Advanced Configuration

### Custom Geth Flags

Edit `docker-compose.yml` to add custom Geth flags:

```yaml
command: |
  --holesky
  --http --http.addr 0.0.0.0 --http.port 8545
  --ws --ws.addr 0.0.0.0 --ws.port 8546
  --authrpc.addr 0.0.0.0 --authrpc.port 8551
  --authrpc.jwtsecret /data/jwtsecret
  --cache 4096
  --maxpeers 50
```

### Custom Lighthouse Configuration

```yaml
command: |
  lighthouse bn
  --network holesky
  --datadir /data
  --http --http-address 0.0.0.0 --http-port 5052
  --execution-endpoint http://geth:8551
  --execution-jwt /data/jwtsecret
  --checkpoint-sync-url https://holesky.beaconstate.info
```

## Security Considerations

### Network Security

1. **Firewall**: Only expose necessary ports
2. **JWT Secret**: Keep the JWT secret secure
3. **API Access**: Limit RPC access to localhost
4. **Updates**: Keep Docker images updated

### Monitoring Security

1. **Grafana**: Change default credentials
2. **Prometheus**: Secure metrics endpoints
3. **Logs**: Regularly review for suspicious activity

## Getting Help

### Resources

- **Rocket Pool Discord**: Community support
- **Ethereum Documentation**: Official Ethereum guides
- **Lighthouse Book**: Comprehensive Lighthouse documentation
- **Geth Documentation**: Execution client documentation

### Log Collection for Support

When seeking help, collect relevant information:

```bash
# System information
docker --version
docker-compose --version
df -h

# Container status
docker-compose ps

# Recent logs
docker-compose logs --tail=100 > logs-$(date +%Y%m%d).txt
```

## Conclusion

This guide provides a comprehensive overview of running a Rocket Pool Holesky node. Regular monitoring, proper maintenance, and understanding of the sync process are key to successful node operation.

For specific issues or advanced configurations, refer to the detailed troubleshooting documentation and monitoring scripts provided in this repository.
