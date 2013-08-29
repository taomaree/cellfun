The following nginx conf gets nginx playing nicely with Server Side Events (SSE)

```
upstream cellfun { server 127.0.0.1:49153; }
server {
  listen      80;
  server_name cellfun.stumpy.awk.us;
  location    / {
    proxy_pass  http://cellfun;
    proxy_buffering off;
    proxy_cache off;
    proxy_http_version 1.1;
    chunked_transfer_encoding off;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection '';
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Accel-Buffering no;
  }
}
```
