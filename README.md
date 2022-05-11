# finclip-ext
支持Rust开发者开发FinClip SDK Extension，即把以Rust实现的代码，作为自定义API注入到FinClip中，供小程序使用。开发者可以Rust开发和编译出跨硬件跨操作系统的原生功能去增强FinClip安全运行沙箱的标准功能以外的能力，但无需掌握或学习了解任何Rust以外的语言（例如iOS/ObjC或Android/Java等）。

## 项目生成物
libfincliprust.a 为编译产出，是一个静态库。在xcode中构建iOS版本，请作为static library创建项目。

## 如何构建
本项目分成两部分代码，第一部分实现Rust FFI，第二部分为设备端原生部分的wrapper，目前仅提供iOS/ObjC的版本，在Android及其他平台上，可参照ObjC版本实现。

在iOS上，Rust FFI部分的代码，先编译iOS simulator和device的library，产出一对libfinclipext.h/libfinclipext.a中间产物。然后再在iOS wrapper部分构建出libfincliprust.a，注意在xcode中构建libfincliprust.a的项目配置中：
- 配置项目的header和library的search path，指向中间产物libfinclipext.h和libfinclipext.a的所在目录
- 在Build Phase中，在embed and linking环节，把libfinclipext.a连接进来

## 如何集成使用
iOS、Android或其他技术类型的终端上的宿主App（嵌入了FinClip SDK，具备运行小程序能力者），在构建项目时，把libfincliprust.a连接打包。

在该App中初始化FinClip SDK的地方（例如在iOS/ObjC应用中，通常在AppDelegate.m里面），增加两行代码：
```
#import "FinClipExt.h"
#import "myplugin.h"  //此处为任何要引进至App中提供给小程序使用的FinClip SDK Extension项目

...

[[FinClipExt singleton] installFor:[FATClient sharedClient] withExt :myplugin_register_apis()]; // myplugin_register_apis 为某个要安装使用的Rust plugin

```

## 如何注入Rust实现的自定义扩展
这通常由其他人或其他角色（相对于宿主应用开发者，即负责集成FinClip SDK以及libfincliprust.a至App中的人而言）负责基于Rust实现提供，宿主应用开发者用上述'installFor'方法安装即可。

如果要自行试验实现一个基于Rust的FinClip SDK Extension，非常简单 - 没有外部的library或者protocol、interface需要使用，只要Rust代码中包含以下内容：

- 定义一个类型：'type FinClipCall = fn(&String)->String'，即一个出参和入参均为字符串的函数指针
- 提供一个函数，它的作用是以'HashMap<String, FinClipCall>'作为自定义接口的“花名册”，登记准备提供给小程序开发者的自定义API的名录。例如'pub unsafe extern "C" myplugin_register_apis() -> \*mut HashMap<String, FinClipCall>'，注意HashMap必须用Box::into_raw包装成一个opaque pointer
- 把希望提供给宿主的自定义函数，按 'fn(&String) -> String' 的签名去实现，入参和出参都是JSON格式的字符串，建议用serde_json crate进行处理

其他详情参见demo。更详细内容请参考 https://www.finclip.com/blog/finclip-ext-with-rust/


