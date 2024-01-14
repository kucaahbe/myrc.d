docker_image := myconfigs-test

build:
	docker build -t $(docker_image) . && docker run --rm $(docker_image)

run:
	docker build -t $(docker_image) . && docker run --rm -i -t --entrypoint bash $(docker_image)
