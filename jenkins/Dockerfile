# Jenkins plus the Docker command line and its build plugin. The Docker daemon itself stays on the VM.
FROM docker:29-cli AS cli

FROM jenkins/jenkins:lts-jdk21
COPY --from=cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=cli /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins
