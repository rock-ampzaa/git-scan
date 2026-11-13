add_addons("c3")

target("library-obj")
        set_kind("object")
        add_rules("@addon/c3/c3single-obj")
        add_files("scan-git-c3/src/proc.c3")
        add_deps("c3git") -- TODO :c3的library该怎么添加
target("scan-gitdir")
        set_kind("executable")
        set_default(true)
        -- set_basename("rock")
        add_deps("library-obj")
        add_files("read-dir-list-d/src/*.d")
