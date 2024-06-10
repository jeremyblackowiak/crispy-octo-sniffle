FROM busybox:latest
ENV PORT=80

ADD index.html /www/index.html

EXPOSE $PORT

HEALTHCHECK CMD nc -z localhost $PORT

# Create a webserver and run it forever
CMD echo "httpd started" && trap "exit 0;" TERM INT; httpd -v -p $PORT -h /www -f & wait