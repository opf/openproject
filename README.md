===OpenProject Distro for OpenShift===

==== Installation ====
Unforunately, the OpenProject installation is too long to run as a quickstart, so you must manually push the code to the repository.

1) Create an app for OpenProject
$rhc app create <APP_NAME> ruby-1.9 mysql-5.5

2) CD into the repository created by RHC.

3) Add this repository (openproject_openshift) as a remote, and clone it into your repo.  Then merge the current branch (origin, the OpenShift Repo) and the github/openshift branch you pulled from here.

4) Git Push to OpenShift

