# 来点控制台指令！

控制台实在是太难用了！

干脆整点简化指令节约时间吧？

# 怎么增加我自己的简化指令？

在 `commands/scripts` 内阅读 example.lua 来访写！

在写完之后不要忘记 执行 `updateList.sh` （win 用户请手动增加到 `moduleList.lua`，或者写一个 ps 脚本顺便 push 一下？）

# 现有的简化指令

## fast server announce

使用 `: ` 开头的指令被视为服务器宣告。

对于饥荒不支持输入法的用户来说可能有点帮助？

## MC command

以 `/` 开头的内容被视为类似 Minecraft 的命令。

mod 未完成，目前只完成了：
 * tp
 * summon
 * time
 * seed
 * kill