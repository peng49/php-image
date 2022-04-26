#! /bin/bash

cat <<EOF | tee /etc/nginx/nginx.conf
user  nginx;
worker_processes  auto;
worker_rlimit_nofile 65535;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  4096;
    use epoll;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    server_tokens   off;
    sendfile        off;
    #tcp_nopush     on;

    keepalive_timeout  65;

    gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
EOF

cat <<EOF | tee /etc/nginx/conf.d/default.conf
server {
    listen       80;
    server_name  localhost;

    #access_log  /var/log/nginx/host.access.log  main;

    if (\$http_x_forwarded_for = "" ) {
        set \$client_ip "\$remote_addr";
    }
    if (\$http_x_forwarded_for != "" ) {
        set \$client_ip "\$http_x_forwarded_for";
    }
    if (\$http_user_agent = "kube-probe/1.11") {
        access_log off;
    }

    root /var/www/html/public/;

    index index.php index.html;

    client_max_body_size    0;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    location ~ \.php$ {
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;

        proxy_read_timeout 1800s;
        proxy_connect_timeout 120;
        proxy_send_timeout 180;
        fastcgi_max_temp_file_size 0;
        fastcgi_buffer_size 4K;
        fastcgi_buffers 32 8k;
        client_body_buffer_size 1024k;
    }

    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|ico)$ {
        expires 7d;
        access_log  off;
    }

    location ~ .*\.(js|css)$ {
        expires 12h;
        access_log  off;
    }

    location ~ /\.ht {
        deny  all;
    }
}
EOF