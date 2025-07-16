# Portainer Deployment Guide

This guide explains how to deploy the Data Engineering Playground using Portainer.

## Prerequisites

- Docker and Docker Compose installed on your server
- Portainer installed and accessible
- Access to this repository (either via Git or file upload)

## Key Features for Portainer

The `docker-compose.yml` file has been optimized for both local and Portainer deployment with the following features:

1. **Environment variable support** - All configuration externalized
2. **Named volumes instead of bind mounts** - Better compatibility with Portainer
3. **Resource limits** - Better resource management
4. **File Browser service** - Easy file management through web interface
5. **Default values** - Works out of the box without environment variables

## Deployment Steps

### 1. Prepare Volumes (Optional)

If you want to pre-populate the volumes with initialization scripts and workspace files:

```bash
./setup-portainer.sh
```

This script will:
- Create and populate Docker volumes
- Show Portainer deployment instructions
- Provide volume management commands

### 2. Deploy via Portainer

#### Option A: Git Repository (Recommended)

1. Log into Portainer
2. Navigate to **Stacks** → **Add stack**
3. Choose **Git Repository**
4. Fill in:
   - **Name**: `de-playground`
   - **Repository URL**: `https://github.com/your-username/de-playground`
   - **Compose path**: `docker-compose.yml`
   - **Branch**: `main`

#### Option B: Upload File

1. Log into Portainer
2. Navigate to **Stacks** → **Add stack**
3. Choose **Upload**
4. Upload the `docker-compose.yml` file
5. Name the stack: `de-playground`

### 3. Configure Environment Variables

Add these environment variables in Portainer:

```env
POSTGRES_DB=playground
POSTGRES_USER=deuser
POSTGRES_PASSWORD=depassword
POSTGRES_PORT=5432
DE_USER=deuser
DE_PASSWORD=depassword
SSH_PORT=2222
PGADMIN_EMAIL=admin@de-playground.local
PGADMIN_PASSWORD=admin123
PGADMIN_PORT=8082
FILEBROWSER_PORT=8083
FILEBROWSER_NOAUTH=true
NETWORK_SUBNET=172.20.0.0/16
```

### 4. Deploy the Stack

Click **Deploy the stack** and wait for all services to start.

## Access URLs

After deployment, the services will be available at:

- **PostgreSQL**: `<server-ip>:5432`
- **pgAdmin**: `http://<server-ip>:8082`
- **File Browser**: `http://<server-ip>:8083`

## File Management

### Using File Browser (Recommended)

The File Browser service provides a web interface for managing files:

1. Access `http://<server-ip>:8083`
2. No login required (passwordless by default)
3. Navigate to:
   - `/workspace` - Development files
   - `/init-scripts` - Database initialization scripts

### Manual Volume Management

To copy files to volumes manually:

```bash
# Copy to workspace volume
docker run --rm -v de-playground_workspace_data:/target -v $(pwd)/workspace:/source alpine cp -r /source/* /target/

# Copy to init-scripts volume
docker run --rm -v de-playground_init_scripts:/target -v $(pwd)/init-scripts:/source alpine cp -r /source/* /target/
```

## Stack Management

### Update Stack

1. In Portainer, go to your stack
2. Click **Edit**
3. Make changes or pull latest from Git
4. Click **Update the stack**

### Backup Data

```bash
# Backup PostgreSQL data
docker run --rm -v de-playground_postgres_data:/source -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz -C /source .

# Backup workspace
docker run --rm -v de-playground_workspace_data:/source -v $(pwd):/backup alpine tar czf /backup/workspace_backup.tar.gz -C /source .
```

### Restore Data

```bash
# Restore PostgreSQL data
docker run --rm -v de-playground_postgres_data:/target -v $(pwd):/backup alpine tar xzf /backup/postgres_backup.tar.gz -C /target

# Restore workspace
docker run --rm -v de-playground_workspace_data:/target -v $(pwd):/backup alpine tar xzf /backup/workspace_backup.tar.gz -C /target
```

## Troubleshooting

### Services Won't Start

1. Check Portainer logs for each service
2. Verify environment variables are set correctly
3. Ensure ports are not already in use
4. Check resource availability

### Volume Issues

1. Use File Browser to inspect volume contents
2. Verify file permissions (should be accessible by container users)
3. Check volume mounts in Portainer's volume section

### Database Connection Issues

1. Verify PostgreSQL service is healthy in Portainer
2. Check if database initialization completed successfully
3. Ensure network connectivity between services

### Port Conflicts

If default ports conflict with existing services, change these environment variables:

- `POSTGRES_PORT` (default: 5432)
- `PGADMIN_PORT` (default: 8082)
- `FILEBROWSER_PORT` (default: 8083)
- `SSH_PORT` (default: 2222)

## Security Considerations

⚠️ **Important for Production Use:**

1. **Change default passwords** before deployment
2. **Use Docker secrets** for sensitive data in production
3. **Configure reverse proxy** with SSL/TLS
4. **Restrict network access** using Portainer's network features
5. **Regular backups** of volumes and configurations
6. **Monitor resource usage** through Portainer dashboards

## Advanced Configuration

### Custom Network Settings

Modify the `NETWORK_SUBNET` environment variable to use a different subnet:

```env
NETWORK_SUBNET=172.30.0.0/16
```

### Resource Limits

The compose file includes resource limits. Adjust them based on your server capacity:

```yaml
deploy:
  resources:
    limits:
      memory: 1G      # Maximum memory
      cpus: '0.5'     # Maximum CPU (50% of one core)
    reservations:
      memory: 512M    # Reserved memory
      cpus: '0.25'    # Reserved CPU (25% of one core)
```

### Adding More Services

To extend the playground with additional services (Kafka, Spark, etc.), edit the compose file and add new service definitions following the same pattern.
