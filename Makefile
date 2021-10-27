STAGING_STACK_NAME=learning-ci-test
STAGING_PARAMETERS_FILE=template-config.staging.json
STAGING_PARAMETERS=$(shell cat $(STAGING_PARAMETERS_FILE) | jqn 'get("Parameters") | entries | map(x => x[0] + "=" + x[1]) | join(" ")')
STAGING_REGION=us-east-1
STAGING_ARTIFACTS_BUCKET_NAME=learning-ci-artifacts
STAGING_ARTIFACTS_S3_PREFIX=staging/infrastructure

TEMPLATE_FILE=main.yml
CAPABILITIES=CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

# VERSION=$(shell git describe --tags)
VERSION=current

ARTIFACT_NAME=main.zip

.PHONY: deploy-staging

invalidateCloudFront.zip: InvalidateCloudFront/index.js
	( cd InvalidateCloudFront && zip ../invalidateCloudFront.zip index.js )

build-staging: invalidateCloudFront.zip
	sam build

upload-artifact-staging: build-staging
	sam package --output-template-file $(TEMPLATE_FILE) --s3-bucket $(STAGING_ARTIFACTS_BUCKET_NAME) --s3-prefix $(STAGING_ARTIFACTS_S3_PREFIX)/$(VERSION) --region $(STAGING_REGION)
	zip $(ARTIFACT_NAME) $(TEMPLATE_FILE) $(STAGING_PARAMETERS_FILE) Makefile
	aws s3 cp $(ARTIFACT_NAME) s3://$(STAGING_ARTIFACTS_BUCKET_NAME)/$(STAGING_ARTIFACTS_S3_PREFIX)/$(VERSION)/ --region $(STAGING_REGION)

deploy-staging: upload-artifact-staging
	sam deploy --template-file $(TEMPLATE_FILE) --stack-name $(STAGING_STACK_NAME) --capabilities $(CAPABILITIES)  --region $(STAGING_REGION) --parameter-overrides $(STAGING_PARAMETERS)









