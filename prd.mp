global项目使用框架
使用语言flutter  适配端 iOS /Android/H5

dio 网络请求
intl 多语言工具
provider 状态管理
flutter_screenutil 屏幕适配
pull_to_refresh_notification 上下拉刷新
internet_connection_checker_plus 网络状态监听
shared_preferences 本地存储
flutter_native_splash 启动图
cached_network_image 图片缓存


在项目中默认使用导入的库

比如：

网络请求要使用
dio 网络请求

状态更新要使用更新页面
provider

网络图片要使用加载缓存
cached_network_image




要求：
1、使用的功能在现有的第三方进行实现、没有在进行添加
2、项目使用的按钮必须统一封装使用防止0.7S 内多次点击
3、项目默认实现必须多语言、使用的颜色值都需要有 白色和暗黑模式两个颜色，在不影响显示前提可以一样
4、项目的功能设置必须支持持续化保存、重启APP、保持登录、主题颜色、语言选择等等
5、网络请求封装在要求最后又请求案例  "access-token"、"_" 必带参数两个，"access-token"没有值就放null
6、对应页面的数据数据请直接请求接口获取 不要进行模拟创造数据
7、先搭建项目的整体框架和页面再根据对应框架UI数据进行开发

每次修改请按照上面的要求和项目整体要求
首页接口：
https://www.global-rlspo.top/api/addons/tf-futures/symbol/cate-list?access-token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJZCI6MSwiS2V5IjoiIn0.lkkgLI7UPS-BcMpvhS3RGLvJKVNlKt2v52joEO8vY4E&_=1744185665000  

长连接：wss://deglobalrlspo.top/ws

Position 页面
都使用GET请求
调用的接口：
1、我的持仓
https://www.global-rlspo.top/api/addons/tf-futures/order/list?state=hold&access-token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJZCI6MSwiS2V5IjoiIn0.lkkgLI7UPS-BcMpvhS3RGLvJKVNlKt2v52joEO8vY4E&_=1744190432000
2、risk ratio余额等：https://www.global-rlspo.top/api/addons/tf-futures/member/my-info?access-token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJZCI6MSwiS2V5IjoiIn0.lkkgLI7UPS-BcMpvhS3RGLvJKVNlKt2v52joEO8vY4E&_=1744190431000
3、History持仓:https://www.global-rlspo.top/api/addons/tf-futures/order/counts?type=1&access-token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJZCI6MSwiS2V5IjoiIn0.lkkgLI7UPS-BcMpvhS3RGLvJKVNlKt2v52joEO8vY4E&_=1744190614000

资讯页面接口：https://www.global-rlspo.top/api/addons/tf-futures/article/news?access-token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJZCI6MSwiS2V5IjoiIn0.lkkgLI7UPS-BcMpvhS3RGLvJKVNlKt2v52joEO8vY4E&page=1&page_size=20&_=1744190630000

我的页面接口：
https://www.global-rlspo.top/api/addons/tf-futures/member/my-info?access-token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJZCI6MSwiS2V5IjoiIn0.lkkgLI7UPS-BcMpvhS3RGLvJKVNlKt2v52joEO8vY4E&_=1744190431000

交易页面接口：
K线数据：https://www.global-rlspo.top/api/kline/history?access-token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJZCI6MSwiS2V5IjoiIn0.lkkgLI7UPS-BcMpvhS3RGLvJKVNlKt2v52joEO8vY4E&code=GOLD&kline_type=8&_=1744190666000

余额接口：https://www.global-rlspo.top/api/addons/tf-futures/member/my-info?access-token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJZCI6MSwiS2V5IjoiIn0.lkkgLI7UPS-BcMpvhS3RGLvJKVNlKt2v52joEO8vY4E&_=1744190676000


登录页面接口：https://www.global-rlspo.top/api/v1/site/login-name?access-token=null&_=1744190960000

请求案例：
    // 准备请求参数
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse(
          'https://www.global-rlspo.top/api/v1/site/login-name?access-token=null&_=$timestamp');

      // 创建 MultipartRequest
      final request = http.MultipartRequest('POST', uri);

      // 添加表单字段，与Postman完全一致
      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['group'] = 'app';

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);



      创建项目后对home要求补充

      home.mp文件有之前接入接口数据和逻辑判断，国际化主要事项，在现有的框架重构

      补充Decode Global.html