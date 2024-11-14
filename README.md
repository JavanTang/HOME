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

## Model batch download

These are some scripts to download models from huggingface/modelscope. Meanwhile, it will to include some useful dockerfiles in which the image will be substituted to chinese mirror.

### Usage

The config file need to include a 'models' tag, where each model contains a 'model_path' tag, then the script will download the model via specified 'model_path' to the local directory.

```bash
models:
  rag:
    model_path: maidalun/bce-embedding-base_v1
    devices: [0]
    batch_size: 128
    model_type: torch
  embedding:
    model_path: xrunda/m3e-base
    devices: [0]
    batch_size: 1
    model_type: torch
  ranker:
    model_path: BAAI/bge-reranker-large
    devices: [0]
    batch_size: 16
    model_type: torch
    model_class: RankerModel
```

The script will download the models via yml config file. 

```bash
bash model_download_by_conf.sh config.yml
```
