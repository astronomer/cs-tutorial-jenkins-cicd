pipeline {
 agent any
   stages {
     stage('Deploy to astronomer') {
       when { branch 'main' }
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