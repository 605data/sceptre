////
// NB: this is a 605-custom override, not present at all in the upstream (which uses circleci)
//
// this exists just to push versioned stuff to our pypi, so that our sceptre-fork doesn't
// have to be installed from github
//
// FIXME: we ignore most of the normal sceptre build process but should run tests/lint..
//
library identifier: "605-jenkins-libs", changelog: false

pipeline {
  agent any; stages {
    stage("INIT"){ steps{ script{
      // we don't clone here, the job definition handles everything
      this_branch = "${USER_BRANCH?:GIT_BRANCH}".trim()
      currentBuild.displayName = "${this_branch}"
      // shortcuts for long-lived branches.
      // (we might want these branches to trigger push or deploy stages)
      branches = [
        master:"origin/master",
        fork_2_3_0:"origin/2.3.0-fork",
      ]
      // these are the branches that get pushed to pypi (or ECR) on success
      push_branches = [branches.fork_2_3_0]
      github_status_605(status:'PENDING');
      withVenv(
        python:"python3.7",
        script:"make clean && pip install twine==4.0.1")
    }}} //script // steps // stage:init

    // build stage might mean creating packages or containers or both
    stage("BUILD"){ steps {
      ansiColor('xterm') {
        script {
          withVenv(
            script:"make pypi-build")
      } } // ansiColor // script
    } }  // steps // stage:build

    stage("PUSH"){
      steps{
        ansiColor('xterm') {
          script {
            if(push_branches.contains(this_branch)){
              withVenv(script:"make push")
              lib_version = withVenv(script:"make pypi-version", returnStdout: true).trim()
              lib_artifacts = withVenv(script:"make pypi-url", returnStdout: true).trim()
              currentBuild.displayName = "release: ${lib_artifacts}"
              announce_lib_release(
                lib_name:"sceptre",
                lib_repo_name:"sceptre",
                lib_artifacts: lib_artifacts,
                lib_version:lib_version,
                branch:"${this_branch}",
                hash:"${GIT_COMMIT}",
              );
            }
            else {
              echo("NOOP for ECR or pypi-push, this branch is not in ${push_branches}");
            }
          } // script
        } // ansiColor
      } // steps
    } // stage:push
  } // stages
  post {
   always { script {
     node {
       step([$class: 'WsCleanup']);
     } // node
   } } // script // always
   success { script {
      github_status_605(status:'SUCCESS');
   }} // script // success
   failure { script {
      github_status_605(status:'ERROR');
   }} // script // failure
  } // post
} // pipeline
