# Helm charts

This directory has helm charts which are deployable on kubernetes.

One would need helm v3 to deploy the chart. To deploy helm follow instructions at https://helm.sh/docs/intro/install/

# Make targets
There is a [Makefile](./Makefile) in this directory, which has been added with targets to interact with nifi chart.

Following is a list of make targets to interact with the charts in directory.

- `make add-helm-incubator-repository` - Add helm incubator chart repository (we are using zookeeper chart published in incubator repository for nifi chart).
- `make update-nifi-dependency` -  Update the chart dependencies for nifi chart.
- `make deploy-nifi` - Deploy nifi chart on kubernetes to bring up a nifi cluster.
- `make deploy-secured-nifi` - Deploy nifi chart on kubernetes to bring up a secured nifi cluster.
- `make deploy-nifi-on-minikube` - Deploy nifi chart on minikube to bring up a nifi cluster.
- `make deploy-secured-nifi` - Deploy nifi chart on minikube to bring up a secured nifi cluster.
- `make delete-release` - Delete the deployed release of nifi chart.

