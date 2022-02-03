pipeline {
 agent any
   stages {
     stage('Deploy to astronomer') {
       when {
        expression {
          return env.GIT_BRANCH == "origin/main"
        }
       }
       steps {
         script {
           sh('build.sh')
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