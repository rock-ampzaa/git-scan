# README

## DESCRIPTION
为方便管理本地的多个git开发目录，防止遗漏提交，故而开发这个**简陋**的小工具

目前的工具由两个部分组成
- `read-dir-list-d`负责接收命令行参数，解析'目录列表文件', 并调用`scan-git-c3`提供的`proc__proc`函数处理git部分
- `scan-git-c3` `proc__proc`函数接收一个路径，对该路径中的文件是否 新建/删除/修改/改名、本地分支是否领先跟踪分支、整个仓库是否没有上游 等进行检查。并把检查到的问题显示在标准输出
## 构建方式
在项目根目录下执行`make`, 即可生成`build/app`

安装到指定目录:  
**需要指定** DESTDIR 变量. 比如 `DESTDIR=~ make install`. 这样会将程序安装到用户主目录的`bin`中

如果要安装到`/usr/local/bin`中, 则执行 `DESTDIR=/usr/local make install`. 确保执行时有写入`/usr/local/bin`的权限

**不可在不指定`DESTDIR`的情况下`make install`**
## USAGE
```
scan-git -f <目录列表文件>
```
- `scan-gitdir -h`  可以查看更多
## 目录列表文件的格式
```
# '#'开头的是注释
# 末尾是'/*': 表示指定目录下的所有子目录
# 可以使用'~'表示用户主目录
~/project/*
# 指定特定目录
~/document/xx_document

# 排除条目 在最开始放一个'!'
!~/document/exclude
!~/document/exclude/*
```
## 与 v1.0.x 的区别
将 原两个程序的形式变更为一个可执行程序

- [x] 将c3写的git部分以 object文件 形式提供给d程序使用
