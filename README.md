# xWenChen.github.io

WenChen的个人博客存储地址

Hugo 安装官网为：https://gohugo.io/installation/windows/

Hugo 目录含义：

archetypes：存放执行 hugo new content posts/my-first-post.md 命令新建 md 文件时使用的 front matter 文件模版，Front matter 支持 TOML、YAML、JSON 格式

content：存放内容页面，如 Blog

layouts：存放定义网站的样式，写在layouts文件下的样式会覆盖安装的主题中的 layouts 文件同名的样式

static：存放所有静态文件，如图片

data：存放创建站点时 Hugo 使用的其他数据

public：存放 Hugo 生成的静态网页

themes：存放主题文件

config.toml：网站配置文件

--------------------------------------------------------------------------------------------------------------

Hugo 使用流程：

1、先点击网址下载最新的 Hogo 依赖： https://github.com/gohugoio/hugo/releases/latest

2、在 Windows 上可以下载 hugo_extended_version_windows-amd64.zip，并解压到电脑上的软件目录

3、将 Hugo.exe 所在的目录添加到环境变量中

4、基本安装就完成了，如果需要更强大的功能，可以参考官网安装 Go 等软件

5、创建网站： hugo new site hugo-blog

6、提交 git 命令进行保存，git add . & git commit -m "创建 Hugo 博客" & git push

7、进入网址目录：cd hugo-blog

8、设置主题，并将主题设置为 submodule： git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke

9、启用 ananke 主题，在 hugo.toml 文件末尾新增一行 "theme = 'ananke''"，或者使用命令： echo "theme = 'ananke'" >> hugo.toml

10、启用 Hugo，查看效果： hugo server ，可以在 http://localhost:1313/ 中预览网站

11、新建博文： hugo new content posts/my-first-post.md