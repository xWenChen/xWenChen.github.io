#!/bin/bash

# git 刷新脚本

msg=$1

# echo -e "\n" # 打印空行
# 检查分支名是否为空，为空则提示用户，并提前返回，-z 判断串长度是否为 0
if [ -z "$msg" ]; then
    echo -e "\n提交信息为空，请输入提交信息。提示：脚本运行命令如： gitUpdate.sh 更新脚本信息\n"
    exit 1 # 0 表示成功，非 0 值表示错误
fi

echo -e "\n执行 git add .\n"
git add .
echo -e "\n执行 git commit -m $msg\n"
git commit -m "$msg"
echo -e "\n执行 git push\n"
git push

echo -e "\n数据更新操作完毕...\n"