#!/bin/bash
## 将 modinfo 的最后加上此代码以便于调试的时候检查 mod 版本
## local timestamp = "debug build 2006.01.02_15:04:05" --[[AUTO GENERATE BY SCRIPT]]
## version = version .. ' (' .. timestamp .. ')' --[[AUTO GENERATE BY SCRIPT]]
## description = timestamp .. "\n" .. description --[[AUTO GENERATE BY SCRIPT]]

sed -i "/.*--\[\[AUTO GENERATE BY SCRIPT\]\]/d" modinfo.lua
timestamp=$(date +%Y.%m.%d_%H:%M:%S)
echo 'local timestamp = "debug build '$timestamp'" --[[AUTO GENERATE BY SCRIPT]]' >> modinfo.lua
echo 'version = version .. " (" .. timestamp .. ")" --[[AUTO GENERATE BY SCRIPT]]' >> modinfo.lua
echo 'description = timestamp .. "\n" .. description --[[AUTO GENERATE BY SCRIPT]]' >> modinfo.lua