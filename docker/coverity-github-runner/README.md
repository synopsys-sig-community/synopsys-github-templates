# Coverity GitHub Runner

This Docker image is provided as an example of how to construct a GitHub runner that includes the necessary bits
for running a full Coverity workflow within GitHub. For the traditional Coverity workflow, including a local cov-analyze
running on the runner itself, it is recommended to use a self-hosted runner due to the large footprint (3+ GB) of the
analysis software.

Building the image:
1. Copy your coverity analysis kit (e.g. cov-analysis-...) and license file (license.dat) to your working directory.
2. Edit the `Dockerfile` and make sure the Coverity version is set to match your analysis kit
3. Build the image: `docker build -t coverity-github-runner .`

The image is set up to automatically bootstrap the latest GitHub Runner software and connect to your account to start
servicing jobs. You will need to pass the following environment variables to the image:

| Environment Variable Name | Description |
| --- | --- |
| **GITHUB_OWNER** | The GitHub "owner" -- either a username or organization |
| **GITHUB_REPOSITORY** | The GitHub repository to service - Just the name, not the full URL and do not include .git. If left out, will support the entire organization |
| **GITHUB_PAT** | A GitHub personal access token with permission to establish self-hosted runners |

Running the image will vary depending on your platform, but for a simple command line Docker instance it may
look like:

```bash
docker run --name coverity-github-runner \
     -e GITHUB_OWNER=<your GitHub username or organization> \
     -e GITHUB_REPOSITORY=<Optional: repository to service> \
     -e GITHUB_PAT=<your GitHub PAT with permission to establish self-hosted runners> \
     coverity-github-runner
```
