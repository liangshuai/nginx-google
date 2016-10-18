#!/bin/sh
PATH=/bin:/usr/local/nginx/sbin:$PATH
Nginx_Install_Dir=/usr/local/nginx
 
set -e
 
if [ -n "$TIMEZONE" ]; then
        rm -rf /etc/localtime && \
        ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
fi
 
if [ "${1:0:1}" = '-' ]; then
        set -- nginx "$@"
fi
 
if [ -z "$DATA_DIR" ]; then
        DATA_DIR=/home/wwwroot
fi
 
sed -i "s@/home/wwwroot@$DATA_DIR@" $Nginx_Install_Dir/conf/nginx.conf
mkdir -p ${DATA_DIR}
[ ! -f "$DATA_DIR/index.html" ] && echo '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 
 
 
<h1 style="text-align:center;">
                <span style="line-height:1.5;"><span style="color:#337FE5;">Hello world! This Nginx!</span>
</span><span style="line-height:1.5;color:#E53333;">Welcome to use Docker!</span>
        </h1>
 
 
<h1 style="text-align:center;">
                <span style="line-height:1.5;color:#E53333;">^_^┢┦aΡｐy&nbsp;</span>
        </h1>
 
 
 
 
 
         
 
 
' > $DATA_DIR/index.html
chown -R www.www $DATA_DIR
 
CPU_num=$(awk '/processor/{i++}END{print i}' /proc/cpuinfo)
if [ "$CPU_num" == '2' ];then
    sed -i 's@^worker_processes.*@worker_processes 2;\nworker_cpu_affinity 10 01;@' $Nginx_Install_Dir/conf/nginx.conf
elif [ "$CPU_num" == '3' ];then
    sed -i 's@^worker_processes.*@worker_processes 3;\nworker_cpu_affinity 100 010 001;@' $Nginx_Install_Dir/conf/nginx.conf
elif [ "$CPU_num" == '4' ];then
    sed -i 's@^worker_processes.*@worker_processes 4;\nworker_cpu_affinity 1000 0100 0010 0001;@' $Nginx_Install_Dir/conf/nginx.conf
elif [ "$CPU_num" == '6' ];then
    sed -i 's@^worker_processes.*@worker_processes 6;\nworker_cpu_affinity 100000 010000 001000 000100 000010 000001;@' $Nginx_Install_Dir/conf/nginx.conf
elif [ "$CPU_num" == '8' ];then
    sed -i 's@^worker_processes.*@worker_processes 8;\nworker_cpu_affinity 10000000 01000000 00100000 00010000 00001000 00000100 00000010 00000001;@' $Nginx_Install_Dir/conf/nginx.conf
else
    echo Google worker_cpu_affinity
fi
 
if [[ -n "$PROXY_GOOGLE" ]]; then
        [ -f "${Nginx_Install_Dir}/conf/ssl" ] || mkdir -p $Nginx_Install_Dir/conf/ssl
        [ -f "${Nginx_Install_Dir}/conf/vhost" ] || mkdir -p $Nginx_Install_Dir/conf/vhost
 
        if [ -z "$PROXY_DOMAIN" ]; then
                echo >&2 'error:  missing PROXY_DOMAIN'
                echo >&2 '  Did you forget to add -e PROXY_DOMAIN=... ?'
                exit 1
        fi
 
        if [ -n "$PROXY_SSL_CRT_KEY" ]; then
                if [ -z "$PROXY_CRT" ]; then
                        echo >&2 'error:  missing PROXY_CRT'
                        echo >&2 '  Did you forget to add -e PROXY_CRT=... ?'
                        exit 1
                fi
 
                if [ -z "$PROXY_KEY" ]; then
                        echo >&2 'error:  missing PROXY_KEY'
                        echo >&2 '  Did you forget to add -e PROXY_KEY=... ?'
                        exit 1
                fi
 
                if [ ! -f "${Nginx_Install_Dir}/conf/ssl/${PROXY_CRT}" ]; then
                        echo >&2 'error:  missing PROXY_CRT'
                        echo >&2 "  You need to put ${PROXY_CRT} in ssl directory"
                        exit 1
                fi
 
                if [ ! -f "${Nginx_Install_Dir}/conf/ssl/${PROXY_KEY}" ]; then
                        echo >&2 'error:  missing PROXY_CSR'
                        echo >&2 "  You need to put ${PROXY_KEY} in ssl directory"
                        exit 1
                fi
        else
                openssl req -new -newkey rsa:2048 -nodes \
                        -out $Nginx_Install_Dir/conf/ssl/$PROXY_DOMAIN.csr \
                        -keyout $Nginx_Install_Dir/conf/ssl/$PROXY_DOMAIN.key \
                        -subj "/C=CN/ST=Shanghai/L=Pudong/O=Legion/OU=DevOps/CN=$PROXY_DOMAIN/emailAddress=admin@dwhd.org"
                openssl x509 -req -days 365 -in $Nginx_Install_Dir/conf/ssl/$PROXY_DOMAIN.csr \
                        -signkey $Nginx_Install_Dir/conf/ssl/$PROXY_DOMAIN.key \
                        -out $Nginx_Install_Dir/conf/ssl/$PROXY_DOMAIN.crt
 
                rm -rf $Nginx_Install_Dir/conf/ssl/$PROXY_DOMAIN.csr
 
                PROXY_KEY=${PROXY_DOMAIN}.key
                PROXY_CRT=${PROXY_DOMAIN}.crt
        fi
 
        #sed -i '57,87d' $Nginx_Install_Dir/conf/nginx.conf
        cat > ${Nginx_Install_Dir}/conf/vhost/google.conf << EOF
server {
        listen 80;
        server_name $PROXY_DOMAIN;
        return 301 https://$PROXY_DOMAIN\$request_uri;
}
 
server {
        listen 443 ssl;
        server_name $PROXY_DOMAIN;
 
        ssl on;
        ssl_certificate ssl/${PROXY_CRT};
        ssl_certificate_key ssl/${PROXY_KEY};
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ALL:!aNULL:!ADH:!eNULL:!LOW:!EXP:RC4+RSA:+HIGH:+MEDIUM;
        keepalive_timeout 70;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
 
        resolver 8.8.8.8;
        location / {
                google on;
                google_scholar on;
                google_language zh-CN;
                google_robots_allow on;
        }
}
EOF
        #mv ${Nginx_Install_Dir}/vhost/{google.conf.stop,google.conf}
fi
 
exec "$@" -g "daemon off;"
