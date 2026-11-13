PREFIX      ?=${HOME}/local
DESTDIR     ?=
EXEC_PREFIX ?= $(PREFIX)
BINDIR      ?= $(EXEC_PREFIX)/bin
INSTALL_BINDIR := $(DESTDIR)$(BINDIR)

DC          := ldc2
DC_FLAGS    := -O2 -release
DC_LIBS     := 

C3C          := c3c compile-only
#C3_FLAGS     := --x86cpu=native -O2 --emit-stdlib=no -g0
C3_FLAGS     := --x86cpu=native -Oz --function-sections=yes --data-sections=yes --single-module=yes
#C3_FLAGS     := --x86cpu=native -O2 --function-sections=yes --data-sections=yes

LINKER       := $(DC)  # 使用 D 链接器
LINK_FLAGS   :=-O2 -release
LINK_LIBS    := -L--gc-sections -L-lgit2 -L-lrock-soo -L-licuuc # 链接 C3 运行时需要的库

# ============================================================================
# 目录与源文件收集
# ============================================================================
D_SRC_DIR    := read-dir-list-d/src
C3_DIR       := scan-git-c3
C3_SRC_DIR   := ${C3_DIR}/src
BUILD_DIR    := build

D_SOURCES    := $(wildcard $(D_SRC_DIR)/*.d)
#C3_SOURCES   := $(filter-out "main.c3",  $(wildcard $(C3_SRC_DIR)/**/*.c3, $(C3_SRC_DIR)/*.c3))
C3_SOURCES   := $(filter-out $(C3_SRC_DIR)/main.c3,  $(shell find $(C3_SRC_DIR) -name "*.c3"))

D_OBJECTS    := $(patsubst $(D_SRC_DIR)/%.d,$(BUILD_DIR)/%.d.o,$(D_SOURCES))
#C3_OBJECTS   := $(wildcard $(BUILD_DIR)/*.o)
C3_OBJECTS   = $(BUILD_DIR)/proc.o


# ============================================================================
# 主目标
# ============================================================================
TARGET       := $(BUILD_DIR)/scan-gitdir

# 默认目标：确保 build 目录存在并构建目标
.PHONY: all
all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $@
# ============================================================================
# 编译 D 文件
# ============================================================================
$(BUILD_DIR)/%.d.o: $(D_SRC_DIR)/%.d
	$(DC) -c $(DC_FLAGS) $< -of=$@

# ============================================================================
# 编译 C3 文件
# ============================================================================
$(C3_OBJECTS): $(C3_SOURCES)
#$(C3C) compile-only --libdir $(C3_DIR)/lib --lib c3git $(C3_FLAGS) --obj-out $(BUILD_DIR) $<
#$(C3C) compile-only --libdir $(C3_DIR)/lib --lib c3git $(C3_FLAGS) --single-module=yes -o $@ $<
	$(C3C) --libdir $(C3_DIR)/lib --lib c3git $(C3_FLAGS) --obj-out $(BUILD_DIR) $^


# ============================================================================
# 链接：生成可执行文件
# ============================================================================
$(TARGET): $(C3_OBJECTS) $(D_OBJECTS)
	$(LINKER) $(LINK_FLAGS) $^ -of=$@ $(LINK_LIBS)

# ============================================================================
# 安装目标
# ============================================================================
.PHONY: install
install: $(TARGET)
	@echo "安装到 $(INSTALL_BINDIR)"
	@install -d $(INSTALL_BINDIR)
	@install -s -m 755 $(TARGET) $(INSTALL_BINDIR)/
	@echo "安装完成。"
# ============================================================================
# 清理
# ============================================================================
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

.PHONY: help
help:
	@echo "可用目标:"
	@echo "  all     - 构建项目 (默认)"
	@echo "  clean   - 删除所有编译产物"
	@echo "  install - 安装到指定目录(需要 环境变量[PREFIX] 与 [DESTDIR]. ${INSTALL_BINDIR})"
	@echo "  help    - 显示此帮助信息"

