
.PHONY: build

build:
	docker build -t ternau/nginx-webdav:latest .

run:
	docker run --rm -it --name webdav \
		--user 1000:100 \
		-p 8080:7070 \
		-e WEBDAV_USER_NAME=user1 \
		-e WEBDAV_TOKEN=user2 \
		-e WEBDAV_PORT=7070 \
		-v $(CURDIR)/volumes/dav:/home/webdav \
		-v $(CURDIR)/files/nginx-template/nginx.conf:/etc/nginx-template/nginx.conf \
		-v $(CURDIR)/files/nginx-template/http.d:/etc/nginx-template/http.d \
		ternau/nginx-webdav:latest
