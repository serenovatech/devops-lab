// Pipeline for lab 4. Builds and tests the Poultry app, then deploys it to a lab copy on port 3300.
// It never touches your real staging app. Jenkins runs in a container and uses the VM's Docker.
pipeline {
  agent any

  options {
    timeout(time: 40, unit: 'MINUTES')
    disableConcurrentBuilds()
  }

  parameters {
    string(name: 'BRANCH', defaultValue: 'test', description: 'Poultry branch to build')
  }

  environment {
    IMAGE = "poultry-lab:jenkins-${BUILD_NUMBER}"
    CI_IMAGE = "poultry-ci:${BUILD_NUMBER}"
    SMOKE = "poultry-smoke-${BUILD_NUMBER}"
    NET = 'jenkins-lab'
    DB = 'jenkins-mysql'
    DB_PW = 'jenkins-lab-only'
    READY = "fetch('http://127.0.0.1:3000/readyz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
  }

  stages {
    stage('Get the code') {
      steps {
        dir('poultry') {
          git url: 'https://github.com/teenShirt/serenova-poultry-erp.git', branch: params.BRANCH
        }
      }
    }

    stage('Start test database') {
      steps {
        sh '''
          docker network inspect $NET > /dev/null 2>&1 || docker network create $NET
          docker start $DB 2>/dev/null || docker run -d --name $DB --network $NET --memory 768m \
            -e MYSQL_ROOT_PASSWORD=$DB_PW -v jenkins-mysql-data:/var/lib/mysql \
            mysql:8.4 --innodb-buffer-pool-size=128M
          for i in $(seq 1 60); do
            docker exec $DB mysqladmin ping -h 127.0.0.1 -uroot -p$DB_PW --silent && exit 0
            sleep 2
          done
          docker logs $DB
          exit 1
        '''
      }
    }

    stage('Format, types, lint, tests') {
      steps {
        sh '''
          docker build -f jenkins/test.Dockerfile -t $CI_IMAGE poultry
          docker run --rm --network $NET -e TEST_DB_HOST=$DB -e TEST_DB_PORT=3306 \
            -e TEST_DB_USER=root -e TEST_DB_PASSWORD=$DB_PW $CI_IMAGE \
            sh -c 'npm run format:check && npm run typecheck && npm run lint && npm test'
        '''
      }
    }

    stage('Build image') {
      steps {
        sh 'docker build --build-arg RELEASE_SHA=$(git -C poultry rev-parse HEAD) -t $IMAGE poultry'
      }
    }

    stage('Smoke test') {
      steps {
        sh '''
          docker run -d --name $SMOKE --network $NET -e APP_ENV=staging -e DEMO_ENABLED=false \
            -e DB_HOST=$DB -e DB_USER=root -e DB_PASSWORD=$DB_PW -e DB_NAME=smoke_$BUILD_NUMBER $IMAGE
          for i in $(seq 1 60); do
            docker exec $SMOKE node -e "$READY" && exit 0
            sleep 2
          done
          docker logs $SMOKE
          exit 1
        '''
      }
    }

    stage('Deploy to lab staging') {
      steps {
        sh '''
          docker rm -f poultry-jenkins 2>/dev/null || true
          docker run -d --name poultry-jenkins --restart unless-stopped --memory 384m --network $NET -p 3300:3000 \
            -e APP_ENV=staging -e DEMO_ENABLED=false -e DB_HOST=$DB -e DB_USER=root -e DB_PASSWORD=$DB_PW \
            -e DB_NAME=jenkins_staging $IMAGE
          for i in $(seq 1 60); do
            docker exec poultry-jenkins node -e "$READY" && exit 0
            sleep 2
          done
          docker logs poultry-jenkins
          exit 1
        '''
      }
    }
  }

  post {
    always {
      sh '''
        docker rm -f $SMOKE 2>/dev/null || true
        docker rmi $CI_IMAGE 2>/dev/null || true
        docker exec $DB mysql -uroot -p$DB_PW -e "DROP DATABASE IF EXISTS smoke_$BUILD_NUMBER" 2>/dev/null || true
      '''
    }
  }
}
