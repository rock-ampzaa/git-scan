# README

## DESCRIPTION
为方便管理本地的多个git开发目录，防止遗漏提交，故而开发这个**简陋**的小工具

目前的工具由两个部分组成
- `read-dir-list-d`负责接收命令行参数，解析'目录列表文件', 并调用`scan-git-c3`提供的`proc__proc`函数处理git部分
- `scan-git-c3` `proc__proc`函数接收一个路径，对该路径中的文件是否 新建/删除/修改/改名、本地分支是否领先跟踪分支、整个仓库是否没有上游 等进行检查。并把检查到的问题显示在标准输出
## 构建方式
需要xmake及安装了c3lang扩展

编译前需要定义`C3LIBRARY_PATH`环境变量. 并且需要在该路径中放置`libgit2.c3l` 这个c3 library

在项目根目录下执行`xmake`, 即可生成`./build/linux/x86_64/release/scan-gitdir`

## 安装
**需要** PREFIX 环境变量. 该变量决定了安装位置

在项目根目录下执行`xmake install`, 即可安装到`$PREFIX/bin`中. 应该确保可执行路径中包括该路径

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
