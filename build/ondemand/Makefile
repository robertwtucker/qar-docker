include ../make/Makefile

REGISTRY_HOST=registry.sptcloud.com
USERNAME=qar

DOCKER_BUILD_ARGS=--build-arg INSTALL_FILES_URL=${INSTALL_FILES_URL}

pre-build:
	mkdir -p od
	cp -f ../../http-server/files/od/od-response.file od
	cp -f ../../http-server/files/od/odpdf-response.file od
	cp -f ../../qar-home/qar-home.tar .

post-build:
	rm -rf od
	rm -f qar-home.tar
