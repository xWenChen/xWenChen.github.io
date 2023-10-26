@echo off

REM windows git 刷新脚本

set msg=%1

REM 检查分支名是否为空，为空则提示用户，并提前返回
if "%msg%" == "" (
    echo.
    echo -e 提交信息为空，请输入提交信息。提示：脚本运行命令如： gitUpdate.sh 更新脚本信息
    echo.

    exit /b 1 REM 0 表示成功，非 0 表示失败
)

echo "执行 git add ."
git add .

echo.
echo "执行 git commit -m %msg%"
git commit -m "%msg%"

echo.
echo "执行 git push"
git push

echo.
echo "数据更新操作完毕..."
echo.