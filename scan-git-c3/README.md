# scan-git
## NAME
scan-git - 扫描指定的路径，检查该目录是否干净.
## SYNOPSIS
scan-git <路径>
## DESCRIPTION
从命令行中接收一个路径，扫描该路径, 确定该目录如果是git管理的目录，则 检查 目录是否干净

*不干净*指: 存在 已经修改、已经删除、已经改名、刚创建 但还没有提交的文件

常和 其它命令结合使用, 如:
```
read-dir-lists -f <目录列表文件> | xargs -I[] scan-git []
```
