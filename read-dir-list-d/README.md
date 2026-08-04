# read-dir-list
## NAME
read-dir-list - 接受参数,解析'目录列表文件'
## SYNOPSIS
read-dir-list [参数...]
## DESCRIPTION

```
read-dir-lists -f <目录列表文件> | xargs -I[] scan-git []
```
## 构建方式
需要安装ldc2(D语言编译器). 以dub构建. 在read-dir-list目录中执行
```
dub build
```
然后生成的可执行文件在 项目根目录中

