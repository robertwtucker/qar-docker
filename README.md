# Docker Images for QAR

This repository contains
[Dockerfiles](https://docs.docker.com/engine/reference/builder/) and samples to
build [Docker](https://www.docker.com/resources/what-container/) images for
[Quadient Archive and Retrieval](https://www.quadient.com/en/resources/quadient-archive-and-retrieval-brochure) 
(QAR) and related products.

## Building Docker images with this repository

To minimize the size of the images created, build scripts in this repository
utilize a local HTTP server in order to download the licensed software
installation files at the time they are needed. Installation media should be
placed in the corresponding directories under `http-server/files` in order to
use the sample server.

## Roadmap

See the [open issues](https://github.com/robertwtucker/qar-docker/issues) for
a list of proposed features (and known issues).

## Contributing

Contributions are what make the open source community such an amazing place to
be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/CoolFeature`)
3. Commit your Changes (`git commit -m 'Add some cool feature'`)
4. Push to the Branch (`git push origin feature/CoolFeature`)
5. Open a Pull Request

## License

Copyright (c) 2023 Quadient Group AG and distributed under the MIT License.
See `LICENSE` for more information. Some components are included under the
terms of their respective licenses.

[Generic Docker Makefile](https://github.com/mvanholsteijn/docker-makefile)
[Oracle Docker Images](https://github.com/oracle/docker-images)

## Contact

Robert Tucker - [@robertwtucker](https://twitter.com/robertwtucker)

Project Link: [https://github.com/robertwtucker/qar-docker](https://github.com/robertwtucker/qar-docker)
