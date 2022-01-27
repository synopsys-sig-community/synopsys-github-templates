#FROM openjdk:slim
#COPY --from=python:3.6-slim / /

FROM ubuntu:18.04

ENV GITHUB_PAT ""
ENV GITHUB_TOKEN ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_LABELS "coverity"
ENV COVERITY_VERSION=2021.12.1
ENV COVERITY_LICENSE ""

RUN apt-get update \
  && apt-get install -y openjdk-8-jdk python3 python3-pip \
  && apt-get install -y curl unzip git jq sudo \
  && useradd -m runner \
  && usermod -aG sudo runner \
  && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Recent git is required in order to use "git" in checkout action
RUN sudo apt-get install -y software-properties-common     && sudo apt-get update     && sudo add-apt-repository -y ppa:git-core/ppa     && sudo apt-get update     && sudo apt-get install -y git

#RUN python3 -m ensurepip
RUN pip3 install --upgrade pip && pip3 install requests==2.26.0 urllib3==1.26.7 jsonapi-requests==0.6.2 tenacity==6.2.0 pygithub suds

RUN curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - && apt -y install nodejs

USER runner
WORKDIR /home/runner

RUN GITHUB_RUNNER_VERSION=$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name[1:]') \
    && curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh

COPY --chown=runner:runner entrypoint.sh run.sh ./
RUN sudo chmod u+x ./entrypoint.sh ./run.sh

COPY cov-analysis-linux64-${COVERITY_VERSION}.tar.gz ./
RUN tar xzf cov-analysis-linux64-${COVERITY_VERSION}.tar.gz && rm cov-analysis-linux64-${COVERITY_VERSION}.tar.gz && mv cov-analysis-linux64-${COVERITY_VERSION} cov-analysis-linux64

ENTRYPOINT ["/home/runner/entrypoint.sh"]
