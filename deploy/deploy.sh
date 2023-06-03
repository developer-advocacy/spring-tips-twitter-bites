#!/usr/bin/env bash
set -e
set -o pipefail

echo $APP_NAME
export SECRETS=${APP_NAME}-secrets
export SECRETS_FN=$HOME/${SECRETS}
export IMAGE_NAME=gcr.io/${GCLOUD_PROJECT}/${APP_NAME}
export RESERVED_IP_NAME=${NS_NAME}-${APP_NAME}-ip
docker rmi -f $IMAGE_NAME || echo "could not delete the existing image..."
cd $ROOT_DIR
./mvnw -U -DskipTests=true spring-javaformat:apply clean deploy spring-boot:build-image -Dspring-boot.build-image.imageName=$IMAGE_NAME
docker push $IMAGE_NAME
gcloud compute addresses list --format json | jq '.[].name' -r | grep $RESERVED_IP_NAME || gcloud compute addresses create $RESERVED_IP_NAME --global

echo $IMAGE_NAME

touch $SECRETS_FN
echo writing to "$SECRETS_FN "
cat <<EOF >${SECRETS_FN}
SPRING_RABBITMQ_HOST=${SPRING_RABBITMQ_HOST}
SPRING_RABBITMQ_PASSWORD=${SPRING_RABBITMQ_PASSWORD}
SPRING_RABBITMQ_PORT=${SPRING_RABBITMQ_PORT}
SPRING_RABBITMQ_USERNAME=${SPRING_RABBITMQ_USERNAME}
SPRING_RABBITMQ_VIRTUAL_HOST=${SPRING_RABBITMQ_VIRTUAL_HOST}
SPRING_R2DBC_PASSWORD=${SPRING_R2DBC_PASSWORD}
SPRING_R2DBC_USERNAME=${SPRING_R2DBC_USERNAME}
SPRING_R2DBC_URL=${SPRING_R2DBC_URL}
SPRINGTIPS_GITHUB_REBUILD_KEY=${SPRINGTIPS_GITHUB_REBUILD_KEY}
SPRINGTIPS_FONTS_ENCRYPTION_SALT=${SPRINGTIPS_FONTS_ENCRYPTION_SALT}
SPRINGTIPS_FONTS_ENCRYPTION_PASSWORD=${SPRINGTIPS_FONTS_ENCRYPTION_PASSWORD}
SPRINGTIPS_TWITTER_USERNAME=${SPRINGTIPS_TWITTER_USERNAME}
SPRINGTIPS_TWITTER_CLIENT_ID=${SPRINGTIPS_TWITTER_CLIENT_ID}
SPRINGTIPS_TWITTER_CLIENT_SECRET=${SPRINGTIPS_TWITTER_CLIENT_SECRET}
EOF
kubectl delete secrets $SECRETS || echo "no secrets to delete."
kubectl create secret generic $SECRETS --from-env-file $SECRETS_FN
kubectl delete -f $ROOT_DIR/deploy/k8s/deployment.yaml || echo "couldn't delete the deployment as there was nothing deployed."
kubectl apply -f $ROOT_DIR/deploy/k8s