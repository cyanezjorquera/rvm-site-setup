log_format simple '$remote_addr - $http_x_forwarded_for - $http_referer - [$time_local] "$request" $status $body_bytes_sent - $host';

server {
  ssl_certificate     /etc/letsencrypt/live/rvm.io/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/rvm.io/privkey.pem;
  ssl_session_timeout 5m;
  ssl_ciphers "AES256+EECDH:AES256+EDH";
#  ssl_ciphers "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA";
  ssl_dhparam /etc/nginx/ssl/2017_dhparams.pem;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:10m;
  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;
  ssl_stapling on
  ssl_stapling_verify on

  client_max_body_size 20M;
  lingering_close on;
  lingering_time 10;
  tcp_nodelay on;
  sendfile on;
  tcp_nopush off;

  access_log /var/log/nginx/access.log simple;
  error_log  /var/log/nginx/error.log info;

  listen [::]:443 ssl;
  listen [::]:80;
  listen 443 ssl;
  listen 80;

  server_name rvm.io *.rvm.io;
  root /home/rvm/site/current/public;
  location ~ /\.well-known/acme-challenge { root /home/letsencrypt/letsencrypt; }

  if ($request_uri ~ /\.well-known/acme-challenge) { break; }
  if ( -f /home/rvm/github-is-running  ) { set $get_url https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer ; }
  if ( -f /home/rvm/github-not-running ) { set $get_url https://bitbucket.org/mpapis/rvm/raw/master/binscripts/rvm-installer ; }
  if ($host = get.rvm.io) { rewrite ^ $get_url permanent ; break; }

  location ~ /(binaries|vboxes) {
    lingering_time 120;
    autoindex on;
    autoindex_exact_size off;
    try_files $uri $uri/ =404;
  }

  location / {
    rewrite ^/(.*)/index\.html$ /$1 permanent;
    rewrite ^/index\.html$ / permanent;
    rewrite ^/(.*)/$ /$1 permanent;
    try_files $uri $uri/index.html =404;
  }

  location ~ /\.well-known/acme-challenge {
    root /home/letsencrypt/letsencrypt;
  }

  error_page 403 404 500 502 503 504 /error;
}
