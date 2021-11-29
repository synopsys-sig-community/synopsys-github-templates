docker rm coverity-on-polaris-runner
docker run --name coverity-on-polaris-runner \
     -e GITHUB_OWNER=jcroall \
     -e GITHUB_REPOSITORY=express-cart-polaris-demo \
     -e GITHUB_PAT=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 \
     -e POLARIS_URL=https://sipse.polaris.synopsys.com \
     -e POLARIS_ACCESS_TOKEN=a8l8cp15ol0dfdrg42kd51vcfj82uknprfdtgqr4unrkjaak82gg \
     jcroallsnps/coverity-on-polaris-runner
