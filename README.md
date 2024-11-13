# Home

## Init Scripts

These are some init scripts, which are used to fast setup development environment.Currently, these have :

1. User Management: Create new user and configure sudo permissions
2. SSH Configuration: Set SSH key and permissions for fast login
3. Basic Environment: Install necessary packages (wget, git, curl, fish, etc.)
4. Python Environment: Install Miniconda
5. Shell Environment: Install fish and plugins
6. Proxy Configuration: Install and configure shadowsocksr-cli

### Usage

```bash
bash init_env.sh
```

## Model batch download(TODO)

These are some scripts to download models from huggingface/modelscope. Meanwhile, it will to include some useful dockerfiles in which the image will be substituted to chinese mirror.