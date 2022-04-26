# php开发镜像
php + nginx

|分支|说明|
|:---:|:---:|
|dev|开发环境|
|pro|生成环境,移除了开发环境的 git 和 composer|

## 使用示例
启动一个laravel项目

```shell
docker run -it -d -p 8080:80 -v F://laravel:/var/www/html peng49/php:dev 
```
