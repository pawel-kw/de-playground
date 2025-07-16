# Data Engineering Playground

A Docker-based data engineering playground with PostgreSQL and development tools for learning and experimentation.

## Services

This playground includes the following services:

### PostgreSQL Database
- **Container**: `de-postgres`
- **Port**: `5432` (accessible from host)
- **Database**: `playground`
- **Username**: `deuser`
- **Password**: `depassword`
- **Features**: 
  - Persistent data storage
  - Sample data engineering schema with users and events tables
  - Health checks

### Development Box (Ubuntu)
- **Container**: `de-dev-box`
- **Image**: Ubuntu 22.04
- **Features**:
  - PostgreSQL client pre-installed
  - Python 3 with pip and venv
  - Common development tools (git, vim, curl, etc.)
  - User `deuser` with sudo access
  - Shared workspace volume at `/workspace`

### pgAdmin (Web Interface)
- **Container**: `de-pgadmin`
- **Port**: `8082` (accessible from host)
- **URL**: http://localhost:8082
- **Login**: `admin@de-playground.local` / `admin123`

### File Browser (Web Interface)
- **Port**: `8083` (accessible from host)
- **URL**: http://localhost:8083
- **Authentication**: Passwordless by default (configurable via `FILEBROWSER_NOAUTH`)
- **Features**:
  - Web-based file management
  - Access to workspace and init-scripts volumes
  - Upload, download, and edit files directly from browser

## Configuration

The stack supports environment variables for easy customization. Create a `.env` file or set environment variables:

```env
# PostgreSQL Configuration
POSTGRES_DB=playground
POSTGRES_USER=deuser
POSTGRES_PASSWORD=depassword
POSTGRES_PORT=5432

# Development Box Configuration
DE_USER=deuser
DE_PASSWORD=depassword
SSH_PORT=2222

# pgAdmin Configuration
PGADMIN_EMAIL=admin@de-playground.local
PGADMIN_PASSWORD=admin123
PGADMIN_PORT=8082

# File Browser Configuration
FILEBROWSER_PORT=8083
FILEBROWSER_NOAUTH=true

# Network Configuration
NETWORK_SUBNET=172.20.0.0/16
```

If no environment variables are set, the stack will use the default values shown above.

## Quick Start

### 1. Start the services
```bash
docker-compose up -d
```

### 2. Check service status
```bash
docker-compose ps
```

### 3. Connect to PostgreSQL from your local machine
```bash
psql -h localhost -p 5432 -U deuser -d playground
# Password: depassword
```

Or if you've customized the environment variables:
```bash
psql -h localhost -p ${POSTGRES_PORT:-5432} -U ${POSTGRES_USER:-deuser} -d ${POSTGRES_DB:-playground}
```

### 4. Access the development box
```bash
docker exec -it de-dev-box bash
# Switch to deuser: su - deuser
```

### 5. Connect to PostgreSQL from the dev box
```bash
# From inside the dev-box container
psql -h postgres -U deuser -d playground
```

### 6. Access pgAdmin web interface
Open your browser and go to: http://localhost:8082

### 7. Access File Browser (for file management)
Open your browser and go to: http://localhost:8083
- No login required (passwordless by default)
- Access workspace files at `/workspace`
- Access init scripts at `/init-scripts`

## Directory Structure

```
de-playground/
├── docker-compose.yml          # Main Docker Compose configuration
├── init-scripts/              # PostgreSQL initialization scripts
│   └── 01-create-sample-tables.sql
├── workspace/                 # Shared workspace (mounted in dev-box)
└── README.md                  # This file
```

## Sample Data

The database includes a sample schema `data_eng` with:
- `users` table with sample user data
- `events` table with user activity events (JSON data)
- `user_activity` view for analytics

### Sample Queries

```sql
-- View all users
SELECT * FROM data_eng.users;

-- View user activity summary
SELECT * FROM data_eng.user_activity;

-- Analyze event types
SELECT event_type, COUNT(*) 
FROM data_eng.events 
GROUP BY event_type;

-- Query JSON data
SELECT user_id, event_data->>'browser' as browser
FROM data_eng.events 
WHERE event_type = 'login';
```

## Home Lab Deployment (Arch Linux)

For deployment on your Arch Linux home lab server:

### Prerequisites
```bash
# Install Docker and Docker Compose
sudo pacman -S docker docker-compose

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

### Deployment Options

#### Option 1: Direct Docker Compose
```bash
# Clone the repository
git clone <your-repo-url> de-playground
cd de-playground

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f
```

#### Option 2: Portainer Deployment (Recommended)

For easier management through a web interface:

```bash
# Clone the repository
git clone <your-repo-url> de-playground
cd de-playground

# Initialize volumes for Portainer
./setup-portainer.sh

# Then deploy via Portainer web interface
```

See [PORTAINER.md](PORTAINER.md) for detailed Portainer deployment instructions.

### Network Access
- PostgreSQL: `<server-ip>:5432`
- pgAdmin: `http://<server-ip>:8082`
- File Browser (Portainer): `http://<server-ip>:8083`

## Useful Commands

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v

# View logs
docker-compose logs -f [service-name]

# Restart a specific service
docker-compose restart postgres

# Access dev-box shell
docker exec -it de-dev-box bash

# Backup database
docker exec de-postgres pg_dump -U deuser playground > backup.sql

# Restore database
docker exec -i de-postgres psql -U deuser playground < backup.sql
```

## Extending the Playground

You can easily add more data engineering tools by extending the `docker-compose.yml`:

- **Apache Spark**: For big data processing
- **Apache Kafka**: For streaming data
- **Redis**: For caching and pub/sub
- **Jupyter Notebook**: For data analysis
- **Apache Airflow**: For workflow orchestration
- **Elasticsearch**: For search and analytics
- **Grafana**: For dashboards and monitoring

## Security Notes

⚠️ **Important**: This setup uses default passwords and is intended for development/learning purposes only. For production use:

1. Change all default passwords
2. Use environment files for secrets
3. Configure proper network security
4. Enable SSL/TLS where appropriate
5. Implement proper backup strategies
6. **File Browser Security**: The File Browser is configured for passwordless access by default for convenience. For production:
   - Set `FILEBROWSER_NOAUTH=false` to enable authentication
   - Configure proper user accounts and permissions
   - Restrict network access to the File Browser port
