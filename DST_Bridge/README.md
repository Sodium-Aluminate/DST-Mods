# DST_Bridge

将多个饥荒服务器、telegram、bilibili 弹幕的消息相互同步...如果你愿意也可以修改客户端，和别的东西同步。
* bilibili 弹幕只接收不发送。

**注意：你需要同时开启游戏本体内 mod 和一个消息服务器，即一个 http server**（后者基于 java，你也可以重新写一个）。

## 饥荒部分 mod 使用方法（游戏服务器）
* 将 mod 塞进服务器
* 使用管理员权限在控制台配置 mod
  * b_SetServerAddr(字符串，服务器地址)
  * b_SetWorldName(字符串，服务器名称)
  * b_SetPasswd(字符串，密码；留空设置为无密码，原版服务端不支持)
  * b_SetPort(数字，端口)
  * b_SetNoHTTPS(布尔，是否禁用 https，当你申请不到证书且不会自签证书、或者不会搭建 nginx 的时候使用。)
  
为了您的聊天信息的安全，我们建议您在以下方案中选择：
* 在同一个服务器中同时部署游戏服务器和 http server，此时可以不设置 https
* **或**在两个不同的服务器中，一个部署游戏服务器，一个部署 http server，使用 https 交流。（可能会因为服务器卡住而影响游戏性能，尽量避免）
* **不建议**在不同的服务器中直接使用 http 明文交换信息。

## 游戏服务器与 http server 之间的接口
消息转发服务端是需要实现俩接口的 http server

发消息接口：
* 请求地址： `/sendMessage`
* 请求方法： `POST`
* 参数：`worldName` 世界名称，`serverPasswd` 密码
* POST 内容：游戏内玩家说的话（以及玩家名字），json 格式，参见 [format.json](src/com/NaAlOH4/dst/format.json)。
* 服务器需要给出的返回值：`200`
* 服务器需要返回的内容：无
* 备注：理论上，应保证 post data 中的世界名称与请求参数中的世界名称相同。

收到消息
* 请求地址： `/getMessage`
* 请求方法： `GET`
* 请求参数：`worldName` 世界名称，`serverPasswd` 密码
* 服务器需要给出的返回值：`200`
* 服务器需要返回的内容：JSON 格式的此名称世界未获取的消息**数组**，从旧到新排列。如果没有新消息，响应内容留空。单个消息格式参见 [format.json](src/com/NaAlOH4/dst/format.json)
* 备注：理论上请求消息动作等同于向服务器注册一个消息监听器，而长时间没有请求（10s）等同于注销该监听器。


## http server 使用方法
### 配置文件
你需要编写一个 json 格式的配置文件，具体格式可以参考[示范文件](example.json)。

### 设置反代
#### 消息服务器与游戏服务器不在同一个设备，（或者不在同一个设备的多个游戏服务器）
推荐的配置是，申请一个 https 证书，比如来自 [let's encrypt](https://letsencrypt.org/) 的，域名类似于 dst-message-server.example.com；

然后搭建你喜欢的前端，将该域名的请求转发到另一个只对内网开放的，[示范文件](example.json)中设置的端口。

#### 消息服务器与游戏服务器在同一个设备
只需要关掉外网对此端口的访问即可。

### 启动消息服务器
程序入口为 `com.NaAlOH4.Main` 你需要下载好依赖后使用 jdk18 编译/运行，或者使用 jre18 运行已经编译好、依赖已经塞进去的 [jar](out/DST-Bridge.jar)。

运行时，需要将配置文件位置作为参数传递给程序。

### 依赖
```
com.google.code.gson:gson
com.squareup.okhttp3:okhttp
```
