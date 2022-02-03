# install jq
brew install jq

# Create time stamp
TAG=deploy-`date "+%Y-%m-%d-%HT%M-%S"`

# Step 1. Use the Access token in the `astro auth login` command
docker login images.astronomer.cloud -u $ASTRONOMER_KEY_ID -p $ASTRONOMER_KEY_SECRET

# Step 2. Request the Organization Id

# Step 3. Build the image
docker build . -t images.astronomer.cloud/$ORGANIZATION_ID/$DEPLOYMENT_ID:$TAG

# Step 4. Push the image
docker push images.astronomer.cloud/$ORGANIZATION_ID/$DEPLOYMENT_ID:$TAG

# Step 5. Get the access token
echo "get token"
TOKEN=$( curl --location --request POST "https://auth.astronomer.io/oauth/token" \
        --header "content-type: application/json" \
        --data-raw "{
            \"client_id\": \"$ASTRONOMER_KEY_ID\",
            \"client_secret\": \"$ASTRONOMER_KEY_SECRET\",
            \"audience\": \"astronomer-ee\",
            \"grant_type\": \"client_credentials\"}" | jq -r '.access_token' )
# Step 6. Create the Image
echo "get image id"
IMAGE=$( curl --location --request POST "https://api.astronomer.io/hub/v1" \
        --header "Authorization: Bearer $TOKEN" \
        --header "Content-Type: application/json" \
        --data-raw "{
            \"query\" : \"mutation imageCreate(\n    \$input: ImageCreateInput!\n) {\n    imageCreate (\n    input: \$input\n) {\n    id\n    tag\n    repository\n    digest\n    env\n    labels\n    deploymentId\n  }\n}\",
            \"variables\" : {
                \"input\" : {
                    \"deploymentId\" : \"$DEPLOYMENT_ID\",
                    \"tag\" : \"$TAG\"
                    }
                }
            }" | jq -r '.data.imageCreate.id')
# Step 7. Deploy the Image
echo "deploy image"
curl --location --request POST "https://api.astronomer.io/hub/v1" \
        --header "Authorization: Bearer $TOKEN" \
        --header "Content-Type: application/json" \
        --data-raw "{
            \"query\" : \"mutation imageDeploy(\n    \$input: ImageDeployInput!\n  ) {\n    imageDeploy(\n      input: \$input\n    ) {\n      id\n      deploymentId\n      digest\n      env\n      labels\n      name\n      tag\n      repository\n    }\n}\",
            \"variables\" : {
                \"input\" : {
                    \"id\" : \"$IMAGE\",
                    \"tag\" : \"$TAG\",
                    \"repository\" : \"images.astronomer.cloud/$ORGANIZATION_ID/$DEPLOYMENT_ID\"
                    }
                }
            }"