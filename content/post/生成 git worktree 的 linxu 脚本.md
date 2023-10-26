---
title: "生成 git worktree 的 linxu 脚本"
description: "本文是用于生成 git worktree 的 linxu 脚本"
keywords: "linux 脚本,git worktree"

date: 2023-10-17 14:20:00 +08:00
lastmod: 2023-10-17 14:20:00 +08:00

categories:
  - 脚本
tags:
  - linux 脚本
  - git worktree

url: post/F2F81AEC611C498C95787A9FE9768E4F.html
toc: true
---

本文描述如何使用linxu 脚本生成 git worktree。

<!--More-->

## 功能描述

脚本代码主要包括以下功能：

1. 进入原工程目录
2. 切换分支，拉取最新代码
3. 生成 worktree 路径
4. 创建特定名称的 worktree
5. 拷贝 local.properties 文件



## 脚本代码

```shell
#!/bin/bash

# 执行脚本，命令格式为： createWorktree.sh feature/Version_UserName_FunctionName
# 脚本执行完后，会根据原项目的 trunk 分支，在 worktree_dir 创建名为 FunctionName 的 worktree
# 获取传入的分支名参数
branch_name=$1

# echo -e "\n" # 打印空行
# 检查分支名是否为空，为空则提示用户，并提前返回，-z 判断串长度是否为 0
if [ -z "$branch_name" ]; then
    echo -e "\n分支名为空，请输入分支名。提示：脚本运行命令如： createWorktree.sh branchName"
    exit 1 # 0 表示成功，非 0 值表示错误
fi

echo -e "\n分支名称: $branch_name\n"

script_path=f/work/scripts

echo -e "\n脚本路径加入环境变量\n"
# 脚本创建成功后，执行 export PATH=$PATH:/mnt/f/work/scripts 命令，将脚本目录加入环境变量
export PATH=$PATH:"/mnt/$script_path"

echo -e "\n为脚本文件添加执行权限\n"
# 脚本创建成功后，执行 chmod +x createWorktree.sh 命令，给脚本添加执行权限
chmod +x "/$script_path/createWorktree.sh"

# 原项目，进入 D:\Code\develop-2 目录
src_dir="/D/Code/develop-2"
# 打印当前目录
echo -e "\n进入目录：$src_dir\n"

cd "$src_dir"

current_directory=$(pwd)
# 打印当前目录
echo -e "\n当前目录：$current_directory"

echo -e "\n切换到 master 分支\n"
# 切换到 master 分支
git checkout master

echo -e "\n执行 git fetch\n"
echo -e ""
# 执行 git fetch 命令
git fetch

echo -e "\n执行 git pull\n"
# 执行 git pull 命令
git pull

echo -e "\n列举 git worktree\n"
# 列举 worktree 列表
git worktree list

# worktree 的目录
worktree_dir="/D/Code/develop-new"

# 使用字符串操作解析出最后一个 _ 后的内容
worktree_name="${branch_name##*_}"

# worktree 完整路径
worktree_path="${worktree_dir}/${worktree_name}"

# 打印参数
echo -e "\n创建 worktree，路径: $worktree_path\n"

# 创建 worktree
git worktree add "$worktree_path" "$branch_name"

echo -e "\n拷贝 local.properties 文件到路径: $worktree_path\n"
# 拷贝 local.properties 文件
cp local.properties "$worktree_path"

echo -e "\n创建 worktree 成功..."
```