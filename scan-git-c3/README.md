# scan-git
## NAME
scan-git - 扫描指定的路径，检查该git目录是否干净.
## SYNOPSIS
scan-git <路径>
## DESCRIPTION
从命令行中接收一个路径，扫描该路径, 确定该目录如果是git管理的目录，则 检查 目录是否干净

*不干净*指: 存在 已经修改、已经删除、已经改名、刚创建 但还没有提交的文件

常和 其它命令结合使用, 如:
```
read-dir-lists -f <目录列表文件> | xargs -I[] scan-git []
```
## 构建方式
需要 `libgit2`库(开发时使用版本为1.9.0). 以c3c构建. 在scan-git-c3目录中执行
```
c3c build
```
然后生成的可执行文件在 `build/`中

*ps*: 引入`string`库只为输出时对齐位置，可以自行实现`string_wide`函数, 就不用引入string库了
