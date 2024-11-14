#!/bin/bash

# 检查是否提供了YAML文件作为参数
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_yaml_file>"
    exit 1
fi

# 定义模型下载目录
MODEL_DIR="${HOME}/MODELZOOS"
mkdir -p "$MODEL_DIR"

# 检查是否安装modelscope，如未安装则安装
if ! command -v modelscope &> /dev/null; then
    echo "Installing modelscope..."
    pip install modelscope -i https://pypi.tuna.tsinghua.edu.cn/simple
fi

# 检查是否安装yq，如未安装则安装
if ! command -v yq &> /dev/null; then
    echo "Installing yq..."
    pip install yq -i https://pypi.tuna.tsinghua.edu.cn/simple
fi

# 指定的YAML文件
yaml_file="$1"
echo "Processing $yaml_file..."

# 使用yq提取model_path并下载
model_paths=$(yq '.models[].model_path' "$yaml_file")  

# 下载每个model_path
for model_path in $model_paths; do
    # 去除model_path字段的引号
    model_path="${model_path//\"/}"
    local_dir="${MODEL_DIR}/${model_path}"
    
    # 检查目标文件夹是否已存在
    if [ -d "$local_dir" ]; then
        echo "Model ${model_path} already exists in ${local_dir}, skipping download."
        continue
    fi

    # 如果文件夹不存在，则进行下载
    echo "Downloading model ${model_path} to ${local_dir}..."
    echo ${model_path}
    echo ${local_dir}
    modelscope download --model ${model_path} --local_dir ${local_dir}
done

echo "Download completed."