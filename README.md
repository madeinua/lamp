# Docker LAMP Stack - XAMPP Replacement

A complete Docker-based LAMP (Linux, Apache, MySQL, PHP) development environment to replace Windows XAMPP.

## Features

- **PHP 8.3** with Apache
- **MySQL 8.0** database
- **Redis 7** - In-memory data store for caching and sessions
- **Multiple Virtual Hosts** - Run multiple projects simultaneously
- **SSL/HTTPS Support** - Self-signed certificates for all domains
- **Email Catching** - Mailpit captures all outgoing emails

## Stack Components

| Service | Port | Description |
|---------|------|-------------|
| Apache/PHP | 80, 443 | Web server with PHP 8.3 |
| MySQL | 3306 | Database server |
| Redis | 6379 | In-memory data store and cache |
| Mailpit Web UI | 8025 | Email testing interface |
| Mailpit SMTP | 1025 | SMTP server for catching emails |

## Prerequisites

- Windows 11 with WSL2 enabled
- Docker Desktop for Windows (with WSL2 backend)
- Administrator access (for editing hosts file)

## Quick Start

### 1. Update Windows Hosts File

You need to add your local domains to the Windows hosts file.

**Option A: Manually**
1. Open Notepad as Administrator
2. Open: `C:\Windows\System32\drivers\etc\hosts`
3. Add entries for your projects (example):

```
127.0.0.1    project1.local
127.0.0.1    project2.local
127.0.0.1    project3.local
```

**Option B: Generate entries automatically**
```bash
./update-hosts.sh
```
This script reads your vhosts configuration and generates the correct entries. Copy the output to your hosts file.

### 2. Start the Stack

```bash
./start.sh
```

Or manually:
```bash
docker-compose up -d --build
```

### 3. Configure Your Virtual Hosts (First Time Only)

On first run, a template configuration file will be auto-generated at `docker/apache/vhosts/dev.conf`.

**To customize for your projects:**

1. Edit `docker/apache/vhosts/dev.conf` and replace example domains with your actual projects:
   ```apache
   # Change this:
   ServerName project1.local
   DocumentRoot "/var/www/htdocs/project1"

   # To your actual project:
   ServerName mysite.local
   DocumentRoot "/var/www/htdocs/mysite"
   ```

2. Add your domains to Windows hosts file (see step 1 above)

3. Restart the container:
   ```bash
   docker-compose restart web
   ```

**Note:** The `dev.conf` file is excluded from git to protect your personal/project data. The template file (`dev.conf.template`) is provided as a starting point with examples.

### 4. Access Your Sites

- Main site: http://localhost or https://localhost
- Your virtual hosts: http://project1.local, https://project1.local, etc.
- Mailpit UI: http://localhost:8025
- phpMyAdmin equivalent: You can access MySQL via any client at localhost:3306

## Database Configuration

**MySQL Root Access:**
- Host: `localhost` or `db` (from within containers)
- Port: `3306`
- Username: `root`
- Password: `root`

**Application Database:**
- Database: `app`
- Username: `app`
- Password: `app`

**Connect from PHP:**
```php
$host = 'db';  // Use 'db' as hostname (Docker service name)
$dbname = 'app';
$user = 'app';
$pass = 'app';

$pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
```

**MySQL Configuration:**
- Custom configuration based on your XAMPP settings
- Location: `docker/mysql/my.cnf`
- UTF-8 MB4 character set (supports emojis and special characters)
- InnoDB buffer pool: 256MB (adjustable based on your needs)
- Buffer sizes and timeouts optimized for development

## Redis Configuration

**Redis Connection:**
- Host: `localhost` or `redis` (from within containers)
- Port: `6379`
- No password required (development environment)
- Persistent storage enabled (AOF)

**Connect from PHP:**
```php
$redis = new Redis();
$redis->connect('redis', 6379);  // Use 'redis' as hostname (Docker service name)

// Example usage
$redis->set('key', 'value');
$value = $redis->get('key');
```

**Connect from external tools:**
- Use `localhost:6379` from Windows
- Use any Redis GUI client (RedisInsight, Redis Commander, etc.)

**Redis CLI access:**
```bash
docker exec -it dev-redis redis-cli
```

## Email Testing

All emails sent via PHP's `mail()` function are caught by Mailpit.

- **View emails:** http://localhost:8025
- **Emails are NOT actually sent** - perfect for development!
- **Download .eml files:** Use the Mailpit UI to download individual emails

**PHP Configuration:**
```php
// No configuration needed! Just use mail() normally:
mail('test@example.com', 'Test Subject', 'Test Body');
```

## SSL Certificates

Self-signed certificates have been generated for all domains.

**To trust certificates in your browser:**

1. Navigate to `docker/apache/ssl/`
2. Double-click any `.crt` file
3. Click "Install Certificate"
4. Choose "Local Machine"
5. Select "Place all certificates in the following store"
6. Click "Browse" and select "Trusted Root Certification Authorities"
7. Click "OK" and finish

**Regenerate certificates:**
```bash
./generate-ssl-certs.sh
```

## Directory Structure

```
lamp/
├── docker/
│   ├── php-apache/
│   │   └── Dockerfile              # PHP 8.3 + Apache configuration
│   ├── apache/
│   │   ├── vhosts/
│   │   │   └── dev.conf            # Virtual hosts configuration
│   │   └── ssl/                    # SSL certificates
│   ├── php/
│   │   └── php.ini                 # PHP configuration (from XAMPP)
│   └── mysql/
│       └── my.cnf                  # MySQL configuration (from XAMPP)
├── htdocs/                         # Your web files (document root)
│   ├── index.php
│   ├── loyalty/
│   ├── laravel/
│   └── ...
├── mail/                           # Mailpit storage
│   └── eml/                        # .eml files
├── docker-compose.yml              # Docker services configuration
├── start.sh                        # Start script
├── stop.sh                         # Stop script
├── test-stack.sh                   # Test suite (50+ checks)
├── mysql-info.sh                   # MySQL connection info
├── update-hosts.sh                 # Generate hosts file entries
├── generate-ssl-certs.sh           # Regenerate SSL certificates
└── README.md                       # This file
```

## Virtual Hosts

All virtual hosts are configured in `docker/apache/vhosts/dev.conf`.

**To add a new virtual host:**

1. Edit `docker/apache/vhosts/dev.conf`
2. Add your VirtualHost configuration:

```apache
<VirtualHost *:80>
    ServerName mynewsite.local
    DocumentRoot "/var/www/htdocs/mynewsite"
    <Directory "/var/www/htdocs/mynewsite">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:443>
    ServerName mynewsite.local
    DocumentRoot "/var/www/htdocs/mynewsite"
    <Directory "/var/www/htdocs/mynewsite">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    SSLEngine on
    SSLCertificateFile "/etc/apache2/ssl/mynewsite.local.crt"
    SSLCertificateKeyFile "/etc/apache2/ssl/mynewsite.local.key"
</VirtualHost>
```

3. Generate SSL certificate:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout docker/apache/ssl/mynewsite.local.key \
    -out docker/apache/ssl/mynewsite.local.crt \
    -subj "/C=DE/ST=Berlin/L=Berlin/O=Development/OU=IT/CN=mynewsite.local"
```

4. Add to Windows hosts file:
```
127.0.0.1    mynewsite.local
```

5. Restart containers:
```bash
./stop.sh && ./start.sh
```

## Testing Your Setup

### Run Complete Test Suite
```bash
./test-stack.sh
```

This comprehensive test script verifies:
- ✓ Docker containers are running
- ✓ PHP is working with all extensions
- ✓ MySQL connection and configuration
- ✓ SSL certificates are valid
- ✓ Mailpit email system works
- ✓ Virtual hosts are configured
- ✓ All configuration files are in place
- ✓ PHP and MySQL settings from your XAMPP config

The test runs **50+ checks** and shows detailed pass/fail results.

## Management Commands

### Start/Stop
```bash
./start.sh          # Start all containers
./stop.sh           # Stop all containers
./test-stack.sh     # Run full test suite
```

### File Permissions

**No permission management needed!** Apache runs as your host user (UID 1000), which means:
- WordPress can write files directly (plugin updates, uploads, etc.)
- You can edit files from your IDE without permission conflicts
- Git operations work seamlessly
- No switching between www-data and host user ownership

This works just like XAMPP on Windows - files are accessible by both the web server and your editor without any special configuration.

### View Logs
```bash
docker-compose logs -f              # All services
docker-compose logs -f web          # Just Apache/PHP
docker-compose logs -f db           # Just MySQL
docker-compose logs -f mailpit      # Just Mailpit
```

### Database Management
```bash
./mysql-info.sh                     # Show MySQL connection info
docker exec -it dev-db mysql -u root -proot  # MySQL CLI
docker exec dev-db mysqldump -u root -proot app > backup.sql  # Backup
docker exec -i dev-db mysql -u root -proot app < backup.sql   # Restore
```

### Redis Management
```bash
docker exec -it dev-redis redis-cli              # Redis CLI
docker exec -it dev-redis redis-cli PING         # Test connection
docker exec -it dev-redis redis-cli KEYS '*'     # List all keys
docker exec -it dev-redis redis-cli FLUSHALL     # Clear all data
docker exec -it dev-redis redis-cli INFO         # Server info
```

### Access Container Shell
```bash
docker exec -it dev-web bash        # Apache/PHP container
docker exec -it dev-db bash         # MySQL container
docker exec -it dev-redis sh        # Redis container (Alpine Linux)
```

### Restart After Changes
```bash
docker-compose restart web          # Restart Apache/PHP
docker-compose restart db           # Restart MySQL
```

### Rebuild After Config Changes
```bash
docker-compose up -d --build
```

## Troubleshooting

### Quick Diagnostics
```bash
# Run the test suite to identify issues
./test-stack.sh

# Check container status
docker ps

# View logs for errors
docker-compose logs -f

# Check MySQL connectivity
./mysql-info.sh
```

### Port Already in Use
If you get "port already in use" errors:
1. **Stop XAMPP first!** (Apache and MySQL services)
2. Check what's using the port:
   ```bash
   # From Windows PowerShell (as Admin)
   netstat -ano | findstr :80
   netstat -ano | findstr :3306
   ```
3. Kill the process or change the port in `docker-compose.yml`

### Can't Access Virtual Hosts
1. **Check Windows hosts file** has the domain (`C:\Windows\System32\drivers\etc\hosts`)
2. Run `./update-hosts.sh` to see what entries you need
3. Clear browser cache and restart browser
4. Check the vhosts config: `docker/apache/vhosts/dev.conf`
5. Restart containers: `./stop.sh && ./start.sh`
6. Check logs: `docker-compose logs -f web`

### Container Won't Start
```bash
# Check logs for specific errors
docker-compose logs web
docker-compose logs db

# Rebuild from scratch
docker-compose down
docker-compose up -d --build

# If still failing, check line endings
file docker/apache/vhosts/dev.conf
# Should show "ASCII text", not "ASCII text, with CRLF"

# Fix line endings if needed
tr -d '\r' < docker/apache/vhosts/dev.conf > temp.conf
mv temp.conf docker/apache/vhosts/dev.conf
```

### SSL Certificate Warnings
This is normal for self-signed certificates. You can:
1. Click "Advanced" and "Proceed anyway" in your browser
2. Or install the certificates as trusted (see SSL Certificates section)

### MySQL Connection Failed
- **From PHP code**: Use hostname `db` (not `localhost`)
  ```php
  new PDO("mysql:host=db;dbname=app", "app", "app");
  ```
- **From Windows**: Use hostname `localhost` or `127.0.0.1`
  ```bash
  mysql -h localhost -u root -proot
  ```
- Check credentials: root/root or app/app
- Run: `./mysql-info.sh` for connection details
- Wait 30 seconds after startup for MySQL to initialize

### Email Not Appearing in Mailpit
1. Check Mailpit is running: `docker ps | grep mailpit`
2. Visit http://localhost:8025
3. Send a test email:
   ```bash
   docker exec dev-web php -r "mail('test@test.com', 'Test', 'Message');"
   ```
4. Refresh Mailpit web interface

### Permission Issues

**This setup runs Apache as your host user (UID 1000)**, eliminating most permission issues.

**If WordPress asks for FTP credentials:**

Add to `wp-config.php`:
```php
define('FS_METHOD', 'direct');  // Force direct filesystem access
```

**If files show as owned by UID 33 after rebuild:**

This can happen if you rebuild the container. Fix with:
```bash
# Change ownership from old UID 33 to new UID 1000
docker exec dev-web find /var/www/htdocs -uid 33 -not -path "*/.git/*" -exec chown 1000:1000 {} +
```

**How it works:**
- Apache runs as `www-data` with UID 1000 (matching your host user)
- Your host user also has UID 1000
- Both identities share the same UID = no permission conflicts
- Files can be edited from host and written by WordPress without switching ownership

### Line Ending Issues (CRLF vs LF)
If Apache fails to start with syntax errors:
```bash
# Fix all config files
find docker/ -type f -exec dos2unix {} \;
# Or
find docker/ -type f -exec sed -i 's/\r$//' {} \;

# Restart
docker-compose restart
```

## PHP Extensions Installed

- mysqli, pdo_mysql
- redis (Redis client)
- gd (image processing)
- zip
- intl (internationalization)
- soap
- mbstring
- curl
- exif
- bcmath
- opcache
- xdebug (debugging)

**To add more extensions:**
1. Edit `docker/php-apache/Dockerfile`
2. Add the extension installation command
3. Rebuild: `docker-compose up -d --build`

## Differences from XAMPP

| Feature | XAMPP | Docker Stack |
|---------|-------|--------------|
| Start/Stop | Control Panel | ./start.sh / ./stop.sh |
| Config Location | C:\xampp\apache\conf | docker/apache/vhosts |
| PHP Config | C:\xampp\php\php.ini | docker/php/php.ini |
| Document Root | C:\xampp\htdocs | ./htdocs |
| MySQL Host (in PHP) | localhost | db |
| Email Testing | Mercury/Sendmail | Mailpit (http://localhost:8025) |
| File Permissions | No issues | No issues (Apache runs as host user) |

## Performance Tips

1. **Use WSL2 file system**: Store project files in WSL2 (`/home/...`) not Windows (`/mnt/c/...`)
2. **Resource limits**: Configure Docker Desktop resources (Settings > Resources)
3. **Disable unneeded services**: Comment out services in `docker-compose.yml`

## Backup

### Database Backup
```bash
docker exec dev-db mysqldump -u root -proot app > backup.sql
```

### Database Restore
```bash
docker exec -i dev-db mysql -u root -proot app < backup.sql
```

## Quick Reference

### Essential Commands
| Command | Description |
|---------|-------------|
| `./start.sh` | Start the entire stack |
| `./stop.sh` | Stop all containers |
| `./test-stack.sh` | Run full test suite (50+ checks) |
| `./mysql-info.sh` | MySQL connection information |
| `./update-hosts.sh` | Generate hosts file entries |
| `docker ps` | Show running containers |
| `docker-compose logs -f` | View all logs |
| `docker-compose restart web` | Restart web server |

### Quick Tests
```bash
# Test web server
curl http://localhost/

# Test MySQL
docker exec dev-db mysql -u root -proot -e "SELECT 1;"

# Test PHP
docker exec dev-web php -v

# View Mailpit
open http://localhost:8025  # or visit in browser
```

## Support

For issues or questions:
1. **Run diagnostics**: `./test-stack.sh`
2. **Check logs**: `docker-compose logs -f`
3. **Verify containers**: `docker ps`
4. **Check configuration files**
5. **Try rebuilding**: `docker-compose down && docker-compose up -d --build`
6. **Review troubleshooting section above**

## License

This configuration is provided as-is for development purposes.
