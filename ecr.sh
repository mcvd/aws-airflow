#!/usr/bin/env bash

# Login to ECR
set -e
exec $(aws ecr get-login --no-include-email)
# Retrieve the ECR airflow repo URI

REPO_URI=$(aws ecr describe-repositories --region $AWS_DEFAULT_REGION --repository-names airflow | jq -r '.repositories | .[] | .repositoryUri')
# Retrieve the image from DockerHub

docker pull puckel/docker-airflow:latest
# Tag the local image against it, assumes TAG= latest
docker tag $(docker images puckel/docker-airflow:latest -q) $REPO_URI
# Push the image
docker push $REPO_URI
