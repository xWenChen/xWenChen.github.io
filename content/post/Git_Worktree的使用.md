---
title: "Git Worktree 的使用"
description: "本文讲解了 Git Worktree 的使用"
keywords: "Git,Git Worktree"

date: 2023-03-17 17:36:00 +08:00

categories:
  - Git
  - Git Worktree
tags:
  - Git
  - Git Worktree

url: post/D37D31C2818D4FE2A9008E4B2E79F64E.html
toc: true
---

本文讲解了 Git Worktree 的使用。

<!--More-->

官方介绍地址：[Git Worktree](https://git-scm.com/docs/git-worktree)

## 使用场景

对于 git worktree 的使用场景，我们举个例子说明。

如果我们正在进行重构代码，老板突然要求我们立即修复某些问题。通常我们可能会使用 git-stash 来临时存储相关更改，但是此时工作树会处于这样一种混乱状态(有新增的、被移动的、被删除的文件，以及其他的修改)。一个不注意，我们就会打乱 git-stash 中的文件，此时我们原本的修改或者 Git 管理有可能就会出现问题。

**如果我们希望在不影响现有更改的前提下，修复老板反馈的新的问题，那么我们可以使用 git worktree 功能**。我们可以创建一个临时的链接工作树来进行紧急修复，修复完成后再将链接工作树删除，然后恢复之前的重构代码。

**注意，worktree 对 git 子模块(submodule)的支持不完善。存在子模块时，慎用 worktree 功能**。

## 概念介绍

git worktree 用于管理附加到同一 git 仓库(repository)的多个工作树，这些工作树有主工作树(main worktree)和链接工作树(linked worktree)的区别。一个非 bare 的仓库可以有一个主工作树，以及 n(n >= 0) 个链接工作树。每个工作树可以对应一个分支。这些工作树允许我们在一个 git 仓库中同时切换不同的分支。

git 中的工作树可以理解成一个 git 项目具有多个不同的目录，这些目录有主目录和链接目录的区分。这些目录也可以理解成是一个个项目拷贝，它们属于同一个仓库，但是是不同的分支。我们可以使用不同的分支做不同的事，这些不同的项目拷贝的 git 管理是受主目录管理的。

本文将从 bare repository、worktree 的引用、git 命令、实战注意事项等方面讲解 worktree。

## bare repository

本节内容讲解下 bare repository 这个知识点。

一般我们会使用`git init`命令创建 git 仓库，或者使用`git clone`命令拉取远程仓库到本地，这两种方式创建的 git 仓库支持完整的 git 功能，带有一个 .git 目录。我们可以在该仓库中创建文件和编写代码。

但是，如果我们在服务器上有一个 git 仓库，我们只想管理并允许用户推送和拉取该仓库。而不想使用该仓库进行持续开发(ongoing development)、分支创建(branch creation)或本地提交(local commits)，此时该怎么办呢？

此时**我们可以使用`git init --bare`命令创建一个 git 裸仓库(git bare repository，也叫中心仓库)，或者使用`git clone --bare`命令拉取远程仓库到本地，本地仓库变为 bare repo**。

**bare repo 的名称通常是`git仓库名.git`，即在正常的仓库名后面新增了".git"后缀，以".git"结尾**。这也就是为什么我们从 GitHub clone 仓库的时候，地址都是 xxx.git 这样的形式的原因。

如果我们查看一个 bare repo，我们会看到 .git 文件夹不见了，该文件夹在普通仓库中可以看到。所有 .git 文件夹中的内容都直接出现在仓库的根目录中(.git 文件夹中的内容上挪一级，变成和 .git 文件夹同级)。

bare repo 旨在用作远端中心仓库，其中代码在团队成员之间共享。bare repo 具有 non-bare repo 的所有功能，但不包含工作区。也就是说，bare repo 并**不能用于编写代码，不能执行我们一般使用的 Git 命令；这同时意味着不存在在 bare repo 上直接提交变更的情况，并且我们无需清理 bare repo 的 Git 工作树或工作区**。而正常的 git 仓库包含工作区，我们可以执行 git 命令，以及在工作区中编写代码；同时也要提交变更，清理 Git 工作树或工作区。

在 bare repo 进行上进行开发的通常做法有两种：

1. 从 bare repo clone 出新的 non-bare repo，在 non-bare repo 上进行开发，完成开发后推送内容到 bare repo
2. 使用 git 的 worktree 功能。基于 bare repo 创建新的 worktree，在 worktree 上进行开发，完成开发后推送内容到 bare repo。

## worktree 引用

当 git 仓库中存在多个 worktree 时，一些引用(refs)可以在所有 worktree 之间共享；而一些引用只能在单个 worktree 中使用。比如 HEAD 在每个 worktree 中都不同，不能共享。本节内容介绍引用的共享规则，以及如何在一个 worktree 中访问另一个 worktree 的引用。

- 所有以 refs/ 开头的引用都是共享的。但是也有例外：refs/bisect 和 refs/worktree 中的引用不共享

- 每个伪引用都是单独针对特定的 worktree 的，所有伪引用都不能共享。伪引用就像 HEAD 一样直接在 $GIT_DIR 下，而不是在 $GIT_DIR/refs 目录下。$GIT_DIR 是 git 仓库中的".git"目录，在 bare repo 中 $GIT_DIR 就是 git 仓库的根目录。

虽然每个 worktree 的引用不共享，但是它们仍然可以通过两个特殊路径被另一个 wortree 访问：$GIT_DIR 目录下的 main-worktree 目录和 $GIT_DIR 目录下 worktrees 目录。前者可以访问主工作树的引用，而后者可以访问所有链接工作树的引用。

例如，以下的引用解析结果相同。注意，每个 worktree 实际的位置，可能与其对应的 git 仓库地址不同：

- main-worktree/HEAD 引用与主工作树的 HEAD 的值相同
- main-worktree/refs/bisect/good 引用与主工作树的 refs/bisect/good 的值相同
- worktrees/foo/HEAD 引用与 $GIT_COMMON_DIR/worktrees/foo/HEAD 的值相同
- worktrees/bar/refs/bisect/bad 引用与 $GIT_COMMON_DIR/worktrees/bar/refs/bisect/bad 的值相同。

要查看、修改 worktree 的引用，最好不要直接手动在 $GIT_DIR 目录内部操作。而是使用诸如`git-rev-parse`或`git-update-ref`之类的命令来正确处理引用。此处就不展开了，详细信息可以见 git 官方的讲解。

## 命令讲解

这一节，我们来讲解 git worktree 相关的命令。

git worktree 相关的命令主要有 add、list、lock、move、prune、remove、repair、unlock 8 个命令，这 8 个命令各自具有不同的参数选项。

下面的命令列表中，中括号[]代表可选参数，尖括号<>代表必选参数

```
git worktree add [-f] [--detach] [--checkout] [--lock [--reason <string>]] [-b <new-branch>] <path> [<commit-ish>]
git worktree list [-v | --porcelain [-z]]
git worktree lock [--reason <string>] <worktree>
git worktree move <worktree> <new-path>
git worktree prune [-n] [-v] [--expire <expire>]
git worktree remove [-f] <worktree>
git worktree repair [<path>…​]
git worktree unlock <worktree>
```

### add 命令

`git worktree add`命令的定义如下：

```
git worktree add [-f] [--detach] [--checkout] [--lock [--reason <string>]] [-b <new-branch>] <path> [<commit-ish>]
```

`git worktree add`命令可以创建一个新的与 git 仓库关联的工作树，这个工作树被称为"链接工作树"(linked worktree)，而不是 git init 命令或 git clone 命令创建出的"主工作树"(main worktree)。一个非 bare repository 的存储库可以有一个主工作树，以及 n(n >= 0) 个链接工作树。当使用完链接工作树后，可以使用`git worktree remove`命令将其删除。

git 中的术语 worktree 包括工作树及工作树对应的元数据。

#### `<path> & [<commit-ish>]` 参数

- `git worktree add <path>`命令会在 path 目录下创建一个新的 worktree，并且自动创建一个新分支，其名称是 path 路径的最后一个组成部分；如果该分支已存在，并且没有其他工作树切换到该分支，则新工作树创建时会切换到该分支。例如`git worktree add ../hotfix`命令会在 ../hotfix 目录下创建新的 worktree，并作以下操作。

   - 同时如果 hotfix 不存在，则创建基于 HEAD 的新的 hotfix 分支
   - 如果 hotfix 分支已存在
      - 如果没有其他工作树切换到该分支，则新的工作树会切换到该分支。
      - 如果已有其他工作树切换到该分支，该 git 会拒绝创建工作树(除非使用了 --force 参数)

- `git worktree add <path> <commit-ish>`命令会在 path 目录下创建一个 worktree，并将新工作树切换到 commit-ish。commit-ish 是类似于提交信息的东西，可以是 tag、commit-id、branch 等。当`<commit-ish>`是一个分支名(此时又称为`<branch>`)，并且没有使用 -b、-B 或 --detach 参数时。

   - 如果本地没有对应`<branch>`的分支，而在远端(`<remote>`)存在对应`<branch>`名称的分支，则`git worktree add <path> <commit-ish>`命令等价于`git worktree add --track -b <branch> <path> <remote>/<branch>`命令
   - 如果本地存在对应`<branch>`的分支(即`<branch>`是现有分支的分支名)，则`git worktree add <path> <commit-ish>`命令等价于`git worktree add <path> <branch>`命令。该命令可以在创建新的 worktree 的同时使用现有的分支

#### `[-d]/[--detach]` 参数

如果我们只想进行一些实验性的改动或进行测试，并不想影响现有的开发，则可以创建一个不与任何分支关联的 throwaway worktree(一次性工作树)。使用`git worktree add -d <path>`命令会创建一个新的 worktree。切换分支时，会切换到与当前分支 commit 相同的游离的 HEAD(detach HEAD)。-d 是 --detach 参数的简写。

#### `[--lock [--reason <string>]]` 参数

如果新创建的链接工作树(linked worktree)存储在移动存储或着网上，那么我们可以在创建工作树时使用 --lock 参数，以会保持工作树锁定，防止其管理文件被修改。这相当于`git worktree add`命令之后调用`git worktree lock`命令。同时我们可以使用`--reason`参数来解释工作树被锁定的原因。

#### `[-f]/[--force]` 参数

默认情况下，如果`<commit-ish>`是一个分支名，并且另一个工作树已经切换到该分支；或者`<path>`参数指定的路径已经分配给某个工作树，但相关信息丢失了时(例如`<path >`指定的路径被手动删除了)，则 add 命令会拒绝创建新的工作树。此时如果我们想要继续创建工作树，就可以使用 --force 参数，此强制选项会覆盖 git 的保护措施。注意如果要添加丢失了但被锁定了的工作树路径，需要指定 --force 参数两次。-f 是 --force 参数的简写。


如果在不使用`git worktree remove`命令的情况下删除了工作树，那么位于仓库中的工作树相关的管理文件最终将被自动删除。除了 git 的自动管理外，我们还可以在主工作树或任何链接工作树中主动运行 `git worktree prune`命令，以清理任何无用、多余的管理文件。

#### `[-b <new-branch>]/[-B <new-branch>]` 参数

使用 add 命令时，如果指定了这两个参数，则可以从`<commit-ish>`中创建名为`<new-branch>`的新分支，并在新工作树中切换到`<new-branch>`；如果省略了`<commit-ish>`，则默认会从当前分支的 HEAD 拉取新的分支。

默认情况下，-b 参数会拒绝创建已经存在的新分支。 -B 则相反，会覆盖此保护措施，将`<new-branch>`重置为`<commit-ish>`相关的内容。

#### `[--[no-]checkout]` 参数

`[--[no-]checkout]`参数代表的是`--no-checkout`和`--checkout`两个参数，牵着代表不切换分支，后者代表切换分支。

默认情况下，使用 add 命令会切换到`<commit-ish>`，--no-checkout 参数可用于禁止这种切换，以实现我们自定义的切换，比如我们可以配置 sparse-checko(详细信息可看官方说明)。

#### `[--[no-]guess-remote]` 参数

`[--[no-]guess-remote]` 参数代表的是`--no-guess-remote`和`--guess-remote`两个参数。

使用了该 --guess-remote 参数时，如果`worktree add <path>`命令没有指定`<commit-ish>`参数，当存在与`<path>`的末尾名称匹配的远程分支时，则从该远程分支拉取新分支并关联，而不是从 HEAD 创建新分支。

可以使用 worktree.guessRemote 配置选项设置为 add 命令的默认行为。

#### `[--[no-]track]` 参数

`--[no-]track` 参数代表的是`--no-track`和`--track`两个参数。

使用了该 --track 参数，add 命令在创建新分支时，如果`<commit-ish>`是一个分支，则将该分支设为新分支的"上游"。默认情况下，Git 会关联新分支与远端分支(remote branch)。当`<commit-ish>`是一个远端分支时，这就是默认的行为。

--track 参数的具体含义，可以见 git 官方关于 git-branch 的讲解。

#### `[-q]/[--quiet]` 参数

使用`git worktree add`命令时，抑制 git 打印的日志信息。-q 是 --quiet 参数的缩写。

### list 命令

`git worktree list`命令的定义如下：

```
git worktree list [-v | --porcelain [-z]]
```

`git worktree list`命令用于列出每个工作树的详细信息。首先列出主要工作树，然后是各个链接工作树。输出的详细信息包括：

- 工作树是否是 bare 的
- 当前切换到的 commit
- 当前切换到的分支(如果没有，则用detached HEAD替代)
- "locked"(如果工作树被锁定)
- "prunable"(如果工作树可以使用 prune 命令清除)

#### `[--expire <time>]` 参数

如果缺失的工作树创建时间早于`<time>`，则`git worktree list`命令会其标注为 prunable，表示可以使用 prune 命令清除。

#### 默认格式

`git worktree list`命令有两种输出格式：默认格式和 Porcelain 格式。

默认格式在单行上显示详细信息。例如：

```
$ git worktree list

/path/to/bare-source            (bare)
/path/to/linked-worktree        abcd1234 [master]
/path/to/other-linked-worktree  1234abc  (detached HEAD)
```

list 命令还根据工作树的状态显示每个工作树的标注。这些标注有：

- locked：工作树被锁定了
- prunable：工作树可以被`git worktree prune`命令移除掉.

```
$ git worktree list

/path/to/linked-worktree    abcd1234 [master]
/path/to/locked-worktree    acbd5678 (brancha) locked
/path/to/prunable-worktree  5678abc  (detached HEAD) prunable
```

对于这些标注，可能有一个原因(reason)，这个原因可以使用详细模式(verbose mode)查看。

详细模式下标注将移动到下一行并缩进，后跟附加信息。注意如果附加信息可用，标注才会移至下一行，否则它与工作树本身信息保持在同一行。

```
$ git worktree list --verbose

/path/to/linked-worktree              abcd1234 [master]
/path/to/locked-worktree-no-reason    abcd5678 (detached HEAD) locked
/path/to/locked-worktree-with-reason  1234abcd (brancha)
	locked: worktree path is mounted on a portable device
/path/to/prunable-worktree            5678abc1 (detached HEAD)
	prunable: gitdir file points to non-existent location
```

##### `[-v]/[--verbose]` 参数

list 命令使用`[--verbose]`参数时，会输出 worktree 相关的额外信息。-v 是 --verbose 参数的缩写。

#### Porcelain 格式

porcelain 格式是打印详细信息的一种格式，在该格式下，每个属性都是单独的一行。

- 如果加了 -z 参数，则每行以 NUL 终止，而不是以换行符终止
- 每个属性使用由单个空格分隔的标签和值(即键值对)列举
- 布尔属性(如 bare 和 detached)仅作为标签列出，并且仅当值为 true 时才存在
- 某些属性可以仅作为标签列出，也可以带有值。如 locked 属性如果带有 reason，则可以作为标签和值列举出来；如果没有 reason，则仅作为标签列出
- 工作树的第一个属性始终是 worktree，空行表示记录结束。

porcelain 格式示例如下：

```
$ git worktree list --porcelain

worktree /path/to/bare-source
bare

worktree /path/to/linked-worktree
HEAD abcd1234abcd1234abcd1234abcd1234abcd1234
branch refs/heads/master

worktree /path/to/other-linked-worktree
HEAD 1234abc1234abc1234abc1234abc1234abc1234a
detached

worktree /path/to/linked-worktree-locked-no-reason
HEAD 5678abc5678abc5678abc5678abc5678abc5678c
branch refs/heads/locked-no-reason
locked

worktree /path/to/linked-worktree-locked-with-reason
HEAD 3456def3456def3456def3456def3456def3456b
branch refs/heads/locked-with-reason
locked reason why is locked

worktree /path/to/linked-worktree-prunable
HEAD 1233def1234def1234def1234def1234def1234b
detached
prunable gitdir file points to non-existent location
```

##### `[--porcelain]` 参数

list 命令使用了 --porcelain 参数，则 git 以易于解析的格式输出脚本。这种格式无关 Git 版本和用户配置，将始终保持稳定。建议该参数与 -z 结合使用。

##### `[-z]` 参数

list 命令使用了 -z 参数，则每行以 NUL 终止，而不是以换行符终止。这使得当工作树路径包含换行符时，可以解析输出。

如果不使用 -z 参数，则 lock reason 中的任何特殊字符(例如换行符)都会被转义，并且整个 reason 都会被引用为配置变量 core.quotePath 对应的解释(详细见官方讲解 git-config)。例如：

```
$ git worktree list --porcelain
...
locked "reason\nwhy is locked"
...
```

### lock 命令

`git worktree lock`命令的定义如下：

```
git worktree lock [--reason <string>] <worktree>
```

如果新创建的链接工作树(linked worktree)存储在移动存储或着网上，那么我们可以使用 lock 命令锁定工作树，防止其管理文件被修改。`git worktree add`命令之后调用`git worktree lock`命令，相当于`git worktree add --lock`命令。

#### `<worktree>` 参数

worktree 可以通过相对路径或绝对路径来标识。如果工作树路径中的最后一个路径组件在工作树中是唯一的，则可以用这个路径组件来标识一个工作树。例如，如果只有两个工作树 a 和 b，a 位于 /abc/def/ghi 目录下，b 位于 /abc/def/ggg 目录下，那么 ghi 或 def/ghi 都可以用来代表 a 工作树。

#### `[--reason <string>]` 参数

使用 lock 命令时，我们可以使用`--reason`参数来解释工作树被锁定的原因。

### move 命令

`git worktree move`命令的定义如下：

```
git worktree move <worktree> <new-path>
```

`git worktree move`命令用于将工作树移动到新位置。请注意，不能使用此命令移动主工作树或包含子模块的链接工作树。但是如果我们手动移动了主工作树，可以使用`git worktree repair`命令重新建立与链接工作树的连接

#### `<worktree>` 参数

move 命令的 worktree 参数的含义同 lock 命令中的 worktree 参数含义一致，此处不再重复讲解。

#### `[-f]/[--force]` 参数

默认情况下，如果目标路径已经被分配给了其他工作树，但该路径丢失了(例如`<new-path>`对应的路径被手动删除了)，那么 --force 参数会允许 move 继续进行；另外 move 命令会拒绝移动锁定了的工作树，如果目标同时是被锁定的，则需要指定两次 --force 参数。-f 是 --force 参数的简写。

### remove 命令

`git worktree remove`命令的定义如下：

```
git worktree remove [-f] <worktree>
```

remove 命令用于删除工作树。该命令的限制如下：

- 无法删除主工作树
- 只能删除干净的工作树，干净的工作树内没有未被 git 跟踪的文件，也没有跟踪文件被修改(没有修改未提交)
- 不干净的工作树或带有子模块的工作树可以指定 --force 参数删除

#### `<worktree>` 参数

remove 命令的 worktree 参数的含义同 lock 命令中的 worktree 参数含义一致，此处不再重复讲解。

#### `[-f]/[--force]` 参数

默认情况下，remove 命令会拒绝删除不干净的工作树，除非使用了 --force 参数。要删除锁定的工作树，需要指定 --force 两次。-f 是 --force 参数的简写。

### prune 命令

`git worktree prune`命令的定义如下：

```
git worktree prune [-n] [-v] [--expire <expire>]
```

prune 命令用于修剪 $GIT_DIR/worktrees 目录中的工作树信息。如果我们没有使用 remove 命令而是手动删除了 worktree 对应的目录。那么此时可以调用 prune 命令清除对应工作树的管理文件等信息。

#### `[-n]/[--dry-run]` 参数

prune 命令附带 -n 或 --dry-run 参数时，不会删除任何内容，而是报告它将删除的内容。

#### `[-v]/[--verbose]` 参数

prune 命令附带 -v 或 --verbose 参数时，会打印所有的日志信息。

#### `[--expire <time>]` 参数

prune 命令附带`--expire <time>`参数时，仅使创建时间早于`<time>`时间的未使用的工作树过期。


### repair 命令

`git worktree repair`命令的定义如下：

```
git worktree repair [<path>…​]
```

如果工作树由于外部因素而损坏或过期，则可以用此命令修复 worktree 的管理文件。

- 如果我们移动了主工作树(或 bare repo)的位置，则链接工作树将无法找到主工作树。此时在主工作树中运行 repair 命令将重新建立链接工作树与主工作树的连接。
- 如果我们没有使用 git worktree move 命令，而是手动移动了链接工作树，则主工作树(或 base repo)将无法找到该链接工作树。在移动后的工作树目录中运行 repair 将重新建立链接工作树与主工作树的连接。
- 如果我们移动了多个链接工作树，则可以在任意移动后的工作树目录中运行 repair 命令，并将每棵链接工作树的新 path 作为参数传入，重新建立主工作树与所有指定路径链接工作树的连接。新 path 可以有任意个(可变参数)，数量 <= 移动过的工作树数量保持一致。

- 如果我们手动移动了主工作树和链接工作树，则在主工作树中运行 repair 并指定每个链接工作树的新 path 将重新建立双向的所有连接。

### unlock 命令

`git worktree unlock`命令的定义如下：

```
git worktree unlock <worktree>
```

解锁被锁定的工作树，允许对其进行 pruned, moved 或者 delete。

#### `<worktree>` 参数

unlock 命令的 worktree 参数的含义同 lock 命令中的 worktree 参数含义一致，此处不再重复讲解。

## 注意事项

新增 worktree 拷贝文件时，不会拷贝不受 git 管理的文件。比如 idea 工程中有个被 git 忽略的 local.property 文件，此文件不会被拷贝到链接工作树中，需要我们手动拷贝一下。