include ../make/Makefile

REGISTRY_HOST=registry.sptcloud.com
USERNAME=oracle
NAME=database

DOCKER_BUILD_CONTEXT=dockerfiles/21.3.0
DOCKER_FILE_PATH=$(DOCKER_BUILD_CONTEXT)/Dockerfile
DOCKER_BUILD_ARGS=--build-arg DB_EDITION=ee

pre-build:
	cp -f ../../http-server/files/oracle/LINUX.X64_213000_db_home.zip ./dockerfiles/21.3.0

post-build:
	rm -f ./dockerfiles/21.3.0/LINUX.X64_213000_db_home.zip
