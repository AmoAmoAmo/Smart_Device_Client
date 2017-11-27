# Smart_Device_Client
Smart_Device_Client
----
# 演示图
![演示图](https://github.com/AmoAmoAmo/Smart_Device_Client/blob/master/client_3.gif?raw=true)


----
# 下载
- GitHub地址：
- [client端](https://github.com/AmoAmoAmo/Smart_Device_Client)
- [server端](https://github.com/AmoAmoAmo/Smart_Device_Server)
- 另外还写了一份macOS版的server，但是目前还有一些问题，有兴趣可以去看看, [macOS](https://github.com/AmoAmoAmo/Server_Mac)
- 博客地址：[博客地址](http://blog.csdn.net/a997013919/article/details/78081115)



----
# 简介


之前在做类似的网络协议的时候，突发奇想，想写一个网络视频监控，基于局域网的情况下，将MacBook摄像头捕获到的视频，在手机端显示，但是由于对macOS不是很熟悉，最终导致该计划流产。所以后来干脆使用手机捕获视频数据。

为了简化项目工作量，socket协议也只用到了一些必要的功能，其他细节如client端退出监控视频时，server端会crash，各位有需要可以自行去添加一些如设置select()函数，或者设置signal()函数忽略这个断开的信号。等等

项目中没有写录制设备视频的功能，所以没有用到MP4封装

更多其他的细节已经搭建过程，有兴趣的可以去我的GitHub上回退到各个版本看循序渐进的过程。关于音视频我也是初学者，欢迎各位斧正。

----
# 主要功能
client端：

1. udp局域网搜索设备([server](http://note.youdao.com/))，或者手动添加其他设备(并没有功能) 到plist
2. 点击已添加的监控设备，开始TCP音视频数据传输
3. 接收到音视频数据，进行解码，并用OpenGL es渲染显示到界面上 或openAL播放音频
4. 横竖屏功能


server端(摄像头)：

1. 点击“reset”，进入“配对模式”，即开始UDP监听AP
2. 连接成功后，将自己的设备信息发送给client
3. 开始捕获音视频，并进行硬编码，发送给client

----
# 博客

[基于iOS的网络音视频实时传输系统（一）- 前言](http://blog.csdn.net/a997013919/article/details/78081115)

[基于iOS的网络音视频实时传输系统（二）- 捕获音视频数据](http://blog.csdn.net/a997013919/article/details/78089240)

[基于iOS的网络音视频实时传输系统（三）- VideoToolbox编码音视频数据为H264、AAC](http://blog.csdn.net/a997013919/article/details/78215515)

[基于iOS的网络音视频实时传输系统（四）- 自定义socket协议(TCP、UDP)](http://blog.csdn.net/a997013919/article/details/74085489)

[基于iOS的网络音视频实时传输系统（五）- 使用VideoToolbox硬解码H264](http://blog.csdn.net/a997013919/article/details/78215544)

[基于iOS的网络音视频实时传输系统（六）- AudioQueue播放音频，OpenGL渲染显示图像](http://blog.csdn.net/a997013919/article/details/78215581)

