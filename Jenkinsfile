pipeline {
 agent any
   stages {
     stage('Deploy to astronomer') {
       when { branch 'main' }
       steps {
         script {
           sh 'docker build . -t images.astronomer.cloud/$ORGANIZATION_ID/$DEPLOYMENT_ID:$BUILD_TAG'
           sh 'docker login images.astronomer.cloud -u $ASTRONOMER_KEY_ID -p $ASTRONOMER_KEY_SECRET'
           sh 'docker push images.astronomer.cloud/$ORGANIZATION_ID/$DEPLOYMENT_ID:$BUILD_TAG'
           sh `TOKEN=$( curl --location --request POST "https://auth.astronomer.io/oauth/token" \
            --header "content-type: application/json" \
            --data-raw "{
                \"client_id\": \"$ASTRONOMER_KEY_ID\",
                \"client_secret\": \"$ASTRONOMER_KEY_SECRET\",
                \"audience\": \"astronomer-ee\",
                \"grant_type\": \"client_credentials\"}" | jq -r '.access_token' )`
           sh `IMAGE=$( curl --location --request POST "https://api.astronomer.io/hub/v1" \
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
                }" | jq -r '.data.imageCreate.id')`
           sh `curl --location --request POST "https://api.astronomer.io/hub/v1" \
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
                }"`
         }
       }
     }
   }
 post {
   always {
     cleanWs()
   }
 }
}

