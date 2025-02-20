# 脚本用法为 webp filepath
param (
    [string]$inputFile
)

# 检查输入文件是否存在
if (-Not (Test-Path $inputFile)) {
    Write-Host "文件不存在: $inputFile"
    exit 1
}

# 定义输出文件名
$outputFile = [System.IO.Path]::ChangeExtension($inputFile, ".webp")

# 使用 cwebp 工具进行转换
# 你需要确保 cwebp 工具已经安装并可以在命令行中使用
cwebp -q 75 $inputFile -o $outputFile

# 检查转换是否成功
if ($LASTEXITCODE -eq 0) {
    Write-Host "转换成功: $outputFile"
} else {
    Write-Host "转换失败"
    exit $LASTEXITCODE
}