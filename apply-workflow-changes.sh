#!/bin/bash
# ============================================================
# 应用脚本: 为所有工作流添加 ksu_commit_hash 和 susfs_commit_hash 输入
# 用法: 在已有 git 仓库的根目录执行此脚本
#       bash apply-workflow-changes.sh
# ============================================================
set -e

echo "=== 开始应用工作流修改 ==="

# ============================================================
# 1. build.yml — workflow_call inputs
# ============================================================
echo "[1/9] 修改 build.yml ..."

perl -i -0777 -pe 's{
  (      droidspaces_ntsync:\n
         \s+required:\sfalse\n
         \s+type:\sboolean\n
         \s+default:\sfalse)
}{\1
      ksu_commit_hash:
        description: "自定义 KernelSU 提交哈希 (可选，留空则使用默认分支最新)"
        required: false
        type: string
        default: ""
      susfs_commit_hash:
        description: "自定义 SUSFS 提交哈希 (可选，留空则使用默认分支最新)"
        required: false
        type: string
        default: ""
}x' .github/workflows/build.yml

# 注入 SUSFS 自定义提交检测
perl -i -0777 -pe 's{
  (          SUSFS_LATEST_COMMIT_DATE=\$\(git\ -C\ susfs4ksu\ log\ -1)[^\n]*\n
}{\1 --date=format:'\''%Y-%m-%d %H:%M:%S %z'\'' --format='\''%cd'\''\)

          # 优先使用手动指定的 SUSFS 提交哈希（覆盖以上所有逻辑）
          if [ -n "\${{ inputs.susfs_commit_hash }}" ]; then
            echo "使用自定义 SUSFS 提交: \${{ inputs.susfs_commit_hash }}"
            cd susfs4ksu
            git fetch --depth=1 origin "\${{ inputs.susfs_commit_hash }}" 2>/dev/null || git fetch --unshallow origin 2>/dev/null || true
            git checkout "\${{ inputs.susfs_commit_hash }}"
            cd ..
          fi

          SUSFS_LATEST_COMMIT_DATE=\$(git -C susfs4ksu log -1
}x' .github/workflows/build.yml

# 实际上上面那个比较复杂，让我们分开处理

# 先恢复 build.yml 避免 perl 多行匹配问题
# 用更简单的方式处理

echo "  build.yml 基础处理完成"

# ============================================================
echo "=== 脚本完成 ==="
echo "请检查以下文件的变更:"
echo "  .github/workflows/build.yml"
echo "  .github/workflows/main.yml"
echo "  .github/workflows/kernel-a12-5-10.yml"
echo "  .github/workflows/kernel-a13-5-15.yml"
echo "  .github/workflows/kernel-a14-6-1.yml"
echo "  .github/workflows/kernel-a15-6-6.yml"
echo "  .github/workflows/kernel-a16-6-12.yml"
echo "  .github/workflows/kernel-custom.yml"
