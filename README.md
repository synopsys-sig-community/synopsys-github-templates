# Synopsys GitHub Templates

Modern applications are a complex mix of proprietary and open source code, APIs and user interfaces, application behavior, and deployment workflows. Security issues at any point in this software supply chain can leave you and your customers  at risk. Synopsys solutions help you identify and   manage software supply chain risks end-to-end.

The Synopsys GitHub DevOps Templates repository contains GitHub workflow .yml templates that allow you to integrate Synopsys AST soltuions into your GitHub Actions based pipeline. It is recommended that you clone this repo into a copy within your own organiaztion, and then leverage these workflows according to GitHub best practices:

- [Sharing workflows, secrets, and runners with your organization](https://docs.github.com/en/actions/learn-github-actions/sharing-workflows-secrets-and-runners-with-your-organization).
- [Using workflow templates](https://docs.github.com/en/actions/learn-github-actions/using-workflow-templates)

These templates and scripts are provided under an OSS license (specified in the LICENSE file) and have been developed by Synopsys field engineers as a contribution to the Synopsys user community. Please direct questions and comments to the approproate forum in the Synopsys user community.

# Available Templates

## Coverity (cov-buid/cov-capture)

Run a Coverity SAST scan as part of your GitHub CI/CD workflow. These templates are written for the traditional cov-build or cov-capture workflow, with cov-analyze or cov-run-desktop running localy and a central Coverity Connect server. There are two instances of this recipe:

- [coverity-auto-capture-self-hosted.yml](coverity-auto-capture-self-hosted.yml) - Runs Coverity using the "auto capture" process on a self-hosted runner. Since this recipe requires no special knowledge of the project being tested, it can be copied into a repository and used right away. 
- [coverity-build-capture-self-hosted.yml](coverity-build-capture-self-hosted.yml) - Runs Coverity using the classic build capture process on a self-hosted runner. This recipe will require a project-specific build command, but you may choose to keep the template generic by specifying the build command in a project-specific environment variable or secret.

The templates use the [Coverity Report Output V7 JSON Action](https://github.com/synopsys-sig/coverity-report-output-v7-json) to provide feedback to developers. Please see the action's own README for details on how it works.

Each template is commented fully to explain each step of the process.

Both of the above templates use a self-hosted runner. This is recommended when using the traditional Coverity workflow due to the large footprint of the Coverity installation. To mitigate the overhead of setting up the self-hosted runner, [an example Docker configuration is provided that shows how to set up such an environment.](docker/coverity-auto-capture-runner/)

## Black Duck

Run a Black Duck SCA scan as part of your GitHub CI/CD workflow. For best preformance, these templates suggest a hybrid scanning appraoch:

1. Rapid Scans run on pushes to and pull requests opened for main branches. This provides fast turnaround for results, and minimizes overhead on the Black Duck Hub server for ephemeral tests. **Note:** rapid scan only runs package manager scans, and does not include signature, binary, and other scanning. This is usually a reasonable trade-off for CI/CD performance.
2. Full Scans are run on a scheduled basis. This ensures that the Black Duck Hub server is updated when new components are introduiced to your projects and advanced scanning techniques like signature and binary scanning are run.

If scheduling is inconvenient, an good alternative trade-off is running Rapid Scans on pull requests, and Full scans on pushes. While a merge and push will always follow a pull request, there can be many commits to a single pull request, so there could be many Rapid Scans run for each Full scan.

The two templates include:

- [blackduck-rapid.yml](blackduck-rapid.yml) - Runs Black Duck Rapid Scan on a pull request.
- [blackduck-intelligent.yml](blackduck-intelligent.yml) - Runs Black Duck Full (or "Intelligent") Scan on a schedule.

The templates use the [Black Duck Detect Action](https://github.com/synopsys-sig/detect-action) to provide feedback to developers. Please see the action's own README    for details on how it works.

Each template is commented fully to explain each step of the process.

The Black Duck detect process is very lightweight, and these can be used easily on both GitHub-hosted and Self-hosted runners.

# Future Enhancements

Future templates will include:

- Coverity CLI, including the new Thin Client and Scan Service
- Polaris
