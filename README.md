# openssl-build-ios

## iOS编译OpenSSL静态库

### 如何使用
1. 从官网上下载需要编译OpenSSL版本的压缩包（(openssl-*.tar.gz)。
链接：https://www.openssl.org/source/old/）

2. 将 openssl-build.sh 移动到 openssl-*.tar.gz 同级目录

3. 编辑 openssl-build.sh
 `OPENSSL_COMPRESSED_FN and -miphoneos-version-min` 
 （设置支持的最小iOS版本）
`export CC=${CLANG} -arch ${ARCH} -miphoneos-version-min=x.0 -fembed-bitcode` 
 （设置支持bitcode）

4. 执行脚本，相应的静态库在 `openssl-version-build/universal/` 目录下。






### 参考
1. https://www.jianshu.com/p/651513cab181
2. https://gist.github.com/vitonzhangtt/797f45ce1f507e20e6d71a781684074d
3. https://github.com/gitusrs/openssl-ios-build-shell-script
4. http://sinofool.net/blog/archives/172


