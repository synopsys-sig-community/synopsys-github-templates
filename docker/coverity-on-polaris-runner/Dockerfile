#FROM openjdk:slim
#COPY --from=python:3.6-slim / /

FROM ubuntu:18.04

ENV GITHUB_PAT ""
ENV GITHUB_TOKEN ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_LABELS "coverity"
ENV POLARIS_ACCESS_TOKEN ""
ENV POLARIS_URL ""

RUN apt-get update \
  && apt-get install -y openjdk-8-jdk python3 python3-pip \
  && apt-get install -y curl unzip git jq sudo \
  && useradd -m runner \
  && usermod -aG sudo runner \
  && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#RUN python3 -m ensurepip
RUN pip3 install --upgrade pip && pip3 install requests==2.26.0 urllib3==1.26.7 jsonapi-requests==0.6.2 tenacity==6.2.0 pygithub

USER runner
WORKDIR /home/runner

RUN GITHUB_RUNNER_VERSION=$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name[1:]') \
    && curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh

COPY --chown=runner:runner entrypoint.sh run.sh ./
RUN sudo chmod u+x ./entrypoint.sh ./run.sh

ENTRYPOINT ["/home/runner/entrypoint.sh"]
