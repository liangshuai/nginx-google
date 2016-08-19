自备证书用法
```sh
docker run -d --name=google \
-p 80:80 -p 443:443 \
-v 系统上存放ssl证书的目录:/usr/local/nginx/conf/ssl \
-e PROXY_GOOGLE=On \
-e PROXY_SSL_CRT_KEY=On \
-e PROXY_CRT=你的crt名称 \
-e PROXY_KEY=你的key名称 \
-e PROXY_DOMAIN=你的域名 \
liangshuai/nginx-google
```
 
系统自签证书用法

```sh
docker run -d --name=google \
-p 80:80 -p 443:443 \
-e PROXY_GOOGLE=On \
-e PROXY_DOMAIN=你的域名 \
liangshuai/nginx-google
```
