
.PHONY: server
server:
	hugo server -D --disableFastRender

.PHONY: build
build:
	hugo

.PHONY: deploy
deploy:
	./deploy.sh
