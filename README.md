# Helm charts

This directory has helm charts which are deployable on kubernetes.

One would need helm v3 to deploy the chart. To deploy helm follow instructions at https://helm.sh/docs/intro/install/

# Make targets
There is a [Makefile](./Makefile) in this directory, which has been added with targets to interact with nifi chart.

Following is a list of make targets to interact with the charts in directory.

- `make add-helm-incubator-repository` - Add helm incubator chart repository (we are using zookeeper chart published in incubator repository for nifi chart).
- `make update-nifi-dependency` -  Update the chart dependencies for nifi chart.
- `make deploy-nifi` - Deploy nifi chart on kubernetes to bring up a NiFi cluster.
- `make delete-nifi-release` - Delete the deployed release of nifi chart.
- `make deploy-secured-nifi-with-toolkit` - Deploy nifi chart on kubernetes to bring up a secured NiFi cluster using certificates generated via nifi-toolkit.
- `make deploy-secured-nifi-with-openid-authentication-with-toolkit` - Deploy nifi chart on kubernetes to bring up a secured NiFi cluster authenticating via OpenId using certificates generated via nifi-toolkit.
- `make deploy-secured-nifi-with-ldap-authentication-with-toolkit` - Deploy nifi chart on kubernetes to bring up a secured NiFi cluster authenticating via LDAP using certificates generated via nifi-toolkit.
- `make deploy-secured-nifi-with-user-certs` - Deploy nifi chart on kubernetes to bring up a secured NiFi cluster using user provided certificates.
- `make deploy-secured-nifi-with-openid-authentication-with-user-certs` - Deploy nifi chart on kubernetes to bring up a secured NiFi cluster authenticating via OpenId using user provided certificates.
- `make deploy-secured-nifi-with-ldap-authentication-with-user-certs` - Deploy nifi chart on kubernetes to bring up a secured NiFi cluster authenticating via LDAP using user provided certificates.

- `make deploy-secured-nifi-with-toolkit-on-minikube` - Deploy nifi chart on minikube to bring up a secured NiFi cluster using certificates generated via nifi-toolkit.
- `make deploy-secured-nifi-with-openid-authentication-with-toolkit-on-minikube` - Deploy nifi chart on minikube to bring up a secured NiFi cluster authenticating via OpenId using certificates generated via nifi-toolkit.
- `make deploy-secured-nifi-with-ldap-authentication-with-toolkit-on-minikube` - Deploy nifi chart on minikube to bring up a secured NiFi cluster authenticating via LDAP using certificates generated via nifi-toolkit.
- `make deploy-secured-nifi-with-user-certs-on-minikube` - Deploy nifi chart on minikube to bring up a secured NiFi cluster using user provided certificates.
- `make deploy-secured-nifi-with-openid-authentication-with-user-certs-on-minikube` - Deploy nifi chart on minikube to bring up a secured NiFi cluster authenticating via OpenId using user provided certificates.
- `make deploy-secured-nifi-with-ldap-authentication-with-user-certs-on-minikube` - Deploy nifi chart on minikube to bring up a secured NiFi cluster authenticating via LDAP using user provided certificates.

# Deploying NiFi with authentication using OpenID Connect and Azure AD

To deploy secure cluster using OpenId authentication, one would need to register an application allowing access to Azure AD.

- On the Azure Active Directory page, under Manage, select App registrations.
- In the App registrations pane, select New registration.
- Fill in the Name on Create page, and then select Register. We will setup redirect URL later.
- Note the values of
    - Application (client) ID
    - Directory (tenant) ID
- Now click on "Certificates & secrets", and then click on "+ New client secret"
- Fill in the description and select its validity as per your need, and click on Add.
- Copy and keep the value at a safe location, you will not be able to retrieve this value from Azure portal later. This is Client Secret.
- Now, we need to put these values in either [values.yaml](./nifi/values.yaml) file or [openid-values.yaml](./nifi/openid-values.yaml) under `nifi.authentication.openid` as follows:
    - `discoveryUrl`: https://login.microsoftonline.com/<<Directory (tenant) ID>>/v2.0/.well-known/openid-configuration
    - `clientId`: <<Application (client) ID>>
    - `clientSecret`: <<Client Secret>>
- Now run make target `deploy-secured-nifi-with-openid-authentication-with-toolkit` to deploy NiFi using these configurations.
- Hostname of the accessible NiFi UI is suggested in the output as the DNS entry you are supposed to add in /etc/hosts file, using that entry we will create the redirect URL for NiFi, as follows.
https://<hostname>:<port>/nifi-api/access/oidc/callback
for eg. https://sample-1599088494-nifi.sample-1599088494.svc:443/nifi-api/access/oidc/callback
- Add the redirect URL created above to the app registration created earlier from "Authentication" option on the "App Registration" page in the "Redirect URI" textbox and click Save.
- Now you are good to go, access your NiFi UI, you would be redirected to Azure signin/app authorization and then redirected to NiFi UI.

# Deploying NiFi with authentication using LDAP Server

- One would need to provide the value of following parameters either in [values.yaml](./nifi/values.yaml) [ldap-values.yaml](./nifi/ldap-values.yaml).

    - For LDAP authentication, provide values of following parameters under `nifi.authentication.ldap`

        - `url`: This is ldap server URL, in the format `ldap://ldap_server_ip_or_name:ldap_server_port`
        - `managerDn`: The DN of the manager that is used to bind to the LDAP server to search for users.
        - `managerPassword`: The password of the manager that is used to bind to the LDAP server to search for users.
        - `userSearchBase`: Base DN for searching for users (i.e. CN=Users,DC=example,DC=com).
        - `userSearchFilter`: Filter for searching for users against the 'User Search Base'. (i.e. sAMAccountName={0}). The user specified name is inserted into '{0}'.

    - For LDAP authorization, provide values of following parameters under `nifi.authorization.ldap`

        - `userObjectClass`: This entry is for authorizers.xml. Object class for identifying users (i.e. person). Required if searching users.
        - `userSearchFilter`: This entry is for authorizers.xml. Filter for searching for users against the 'User Search Base' (i.e. (memberof=cn=team1,ou=groups,o=nifi) ). Optional.
        - `userGroupNameAttribute`: This entry is for authorizers.xml. Attribute to use to define group membership (i.e. member). Optional. If not set group membership will not be calculated through the groups. Will rely on group membership being defined through 'User Group Name Attribute' if set. The value of this property is the name of the attribute in the group ldap entry that associates them with a user. The value of that group attribute could be a dn or memberUid for instance. What value is expected is configured in the 'Group Member Attribute - Referenced User Attribute'. (i.e. member: cn=User 1,ou=users,o=nifi vs. memberUid: user1)
        - `groupSearchBase`: This entry is for authorizers.xml. Base DN for searching for groups (i.e. ou=groups,o=nifi). Required to search groups.
        - `groupObjectClass`: This entry is for authorizers.xml. Object class for identifying groups (i.e. groupOfNames). Required if searching groups.
- One can update other parameters too which have default values.
- Now run make target `deploy-secured-nifi-with-ldap-authentication-with-toolkit` to deploy NiFi using these configurations.
- Hostname of the accessible NiFi UI is suggested in the output. Add the DNS entry you are supposed to add in /etc/hosts file.
- Now you are good to go, access your NiFi UI, you would be redirected to login page on NiFi UI.

## Deploying NiFi with authentication using secure LDAP Server

The chart can deploy a secure NiFi cluster configured with authentication/authorization via a secure LDAP server using `authenticationStrategy` `LDAPS` or `START_TLS` using relevant ldap URLs.

TLS certificates for an important requirement for NiFi nodes to interact with LDAP service.

For the sake of ease, we have decided to use wildcard certificates for tls communication between NiFi and LDAP servers. The wildcard certificate will mask only the NiFi node, one NiFi release deployment would be one client-entity irrespective of number of nodes it has.

To deploy NiFi with authentication using secure LDAP server, one can set.

- `nifi.authentication.ldap.tls.enable` to `true`
- provide the filenames for
    - `nifi.authentication.ldap.tls.certificate`
    - `nifi.authentication.ldap.tls.privateKey`
    - `nifi.authentication.ldap.tls.caCertificate`
- these files should exist in `nifi.authentication.ldap.tls.dir` directory.

You can also provide values different from default for following paramters, the documentation of these paramters are available in [login-identity-providers.xml](nifi/configs/login-identity-providers.xml).

- `nifi.authentication.ldap.tls.clientAuth`
- `nifi.authentication.ldap.tls.protocol`
- `nifi.authentication.ldap.tls.gracefulShutdown`


Do not forget to update the value of `nifi.authentication.ldap.authenticationStrategy` to either of `LDAPS` or `START_TLS`.

# Deploying NiFi using user-provided certificates and key

If you want to deploy nifi with user provided certificates and keys then proceed as follows:

- We have got a values file [secured-values-with-user-provided-certs.yaml](./nifi/secured-values-with-user-provided-certs.yaml) where one can provide values for certificate and private-key filenames.
- Copy your root-ca certificate, node-specific certificate and their private-key files to [nifi/certificates](./nifi/certificates) directory. We do not need private key for root-ca.
- Now specify the `nodeCerts` list with node number, privatekey file-name and certificate file-name as already suggested in the [`secured-values-with-user-provided-certs.yaml`](./nifi/secured-values-with-user-provided-certs.yaml) file.
- You can add/remove the numbers as per your requirement like
    ```
    - node: 4
       privateKey: file4.key
       certificate: file4.crt
    ...
    ...
    ```
- If you are using certificate authentication then provide admin certificate and private-key file-names under `adminUser` details.
- Once all the required files are copied to `certificates` directory and their names have been specified in `secured-values-with-user-provided-certs.yaml`, then call `deploy-secured-nifi-with-user-certs` make target to deploy NiFi cluster.

    ```
    $ make deploy-secured-nifi-with-user-certs
    ```

## Scaling up NiFi deployed using user-provided certificates and key

Once you have deployed NiFi cluster using the user-provided certificates, and you want to scale up, then proceed as follows.

- Copy your new node-specific certificate and their private-key files to [nifi/certificates](./nifi/certificates) directory. We do not need private key for root-ca.
- Now specify the `nodeCerts` list with new node number, privatekey file-name and certificate file-name in the [add-more-certs-values.yaml](./nifi/add-more-certs-values.yaml) file.
- You do not need to add pre-existing certificates to this values file, it is optional.
- You can add/remove the numbers as per your requirement like
    ```
    - node: 4
       privateKey: file4.key
       certificate: file4.crt
    ...
    ...
    ```
- Run `update-secret-with-more-certs` make target as follows providing the detail for namespace and release name.
    ```
    $ DEPLOYED_NS=suskuma make update-secret-with-more-certs
    ```
    or
    ```
    $ DEPLOYED_NS=ns1 DEPLOYED_RELEASE=rs1 make update-secret-with-more-certs
    ```
    First example woud use release name as namespace itself.
- Last step would generate a file `deployed_secret.yaml` which has details of existing secret
- Copy the new details from the output of previous command, this data could be found under `nodeCerts` for eg.
    ```
    node_4_private_key: "sample_key_data"
    node_4_certificate: "sample_cert_data"
    node_5_private_key: "sample_key_data"
    node_5_certificate: "sample_cert_data"
    ```
- Now one has to put this data in `deployed_secret.yaml` file under `data` section, for eg.
    Following is the original content of file `deployed_secret.yaml`
    ```
    apiVersion: v1
    data:
    admin_certificate: sample_cert_data
    admin_private_key: sample_key_data
    ca_certificate: sample_cert_data
    node_1_certificate: sample_cert_data
    node_1_private_key: sample_key_data
    node_2_certificate: sample_cert_data
    node_2_private_key: sample_key_data
    node_3_certificate: sample_cert_data
    node_3_private_key: sample_key_data

    node_certs: ""
    kind: Secret
    metadata:
    annotations:
        meta.helm.sh/release-name: suskuma
        meta.helm.sh/release-namespace: suskuma
    creationTimestamp: "2020-09-21T01:01:27Z"
    labels:
        app: suskuma-certs
        app.kubernetes.io/managed-by: Helm
        chart: certs-1.0.0
        heritage: Helm
        release: suskuma
    name: suskuma-certs
    namespace: suskuma
    resourceVersion: "3995205"
    selfLink: /api/v1/namespaces/suskuma/secrets/suskuma-certs
    uid: f4ad66a5-e8b2-49af-8ce9-61183a2b1a49
    type: Opaque
    ```

    Following is the content of file `deployed_secret.yaml`, after adding new details
    ```
    apiVersion: v1
    data:
    node_4_certificate: sample_cert_data
    node_4_private_key: sample_key_data
    node_5_certificate: sample_cert_data
    node_5_private_key: sample_key_data
    admin_certificate: sample_cert_data
    admin_private_key: sample_key_data
    ca_certificate: sample_cert_data
    node_1_certificate: sample_cert_data
    node_1_private_key: sample_key_data
    node_2_certificate: sample_cert_data
    node_2_private_key: sample_key_data
    node_3_certificate: sample_cert_data
    node_3_private_key: sample_key_data

    node_certs: ""
    kind: Secret
    metadata:
    annotations:
        meta.helm.sh/release-name: suskuma
        meta.helm.sh/release-namespace: suskuma
    creationTimestamp: "2020-09-21T01:01:27Z"
    labels:
        app: suskuma-certs
        app.kubernetes.io/managed-by: Helm
        chart: certs-1.0.0
        heritage: Helm
        release: suskuma
    name: suskuma-certs
    namespace: suskuma
    resourceVersion: "3995205"
    selfLink: /api/v1/namespaces/suskuma/secrets/suskuma-certs
    uid: f4ad66a5-e8b2-49af-8ce9-61183a2b1a49
    type: Opaque
    ```
- Now run following command to update secret with new certificates and keys

    ```
    $ kubectl apply -f deployed_secret.yaml
    ```
- Once secret is updated now you can proceed for scale-up operation on scaleset.
    ```
    $ kubectl -n ns1 get sts
    NAME                READY   AGE
    ns1-nifi        0/3     110s
    ns1-zookeeper   0/1     110s
    $ kubectl -n ns1 scale sts ns1-nifi --replicas=4
    ```

# Using `Initial Admin Identity` for authorization

The default `Initial Admin Identity` we are using in this chart is a certificate based user whose name is specified as `CN=admin` via `nifi.authorization.adminUser.name`.

This user helps in managing NiFi cluster. Following are the uses of the admin user.
- Used to get nodes status in cluster for the readiness probe.
- Used to run disconnection/offloading logic via the usage of nifi-toolkit.

If one uses the certifcate they are generating themselves or getting them from a ca, they are supposed to get a certificate matching `nifi.authorization.adminUser.name`.

Users can use this `adminUser` to perform the first login and create other user and grant authorization to manage and used NiFi.

If there is a need to completely eliminate this certificate based user from the system, it can be done by updating the value of `nifi.authorization.adminUser.enabled` to `false`.
However, disabling the admin user will mean that the statefulset running the NiFi cluster will not manage the cluster.
- Readiness probe will be based port availability.
- No disconnection/offloading logic would be executed when scaling down the cluster.

If you are disabling the `adminUser`, you should be specifying either an OpenID or an LDAP user to be the `Initial Admin Identity` via `nifi.authorization.adminUser.name`. Failing to this will result in an inaccessible cluster.

`nifi.authorization.adminUser.enabled` and `nifi.authorization.adminUser.name` are available in [values.yaml](./nifi/values.yaml) file.

# Using self-signed certificates

If a user wants to use self-signed certificates and do not have any root-ca certificate, then they can still use the chart.
You can skip providing the value of `caCertificate`.

However, the point to be considered is if there are any changes which requires new certificates, for example
- A new certificate authenticated user is to be added, or
- A new node needs to be added for scaling-up operation.

Both these cases would require a restart of the existing cluster.

The workflow for adding a new user or node would be as follows.

- Get the new certificate, if the change is for user we will need only public certificate, if it is for node then we would need both public certificate and the private key
- Add the certificate/key in `add-more-certs-values.yaml` in the format suggested in the file.
- Run `update-secret-with-more-certs` make target as discussed in [Scaling up NiFi deployed using user-provided certificates and key
](#scaling-up-nifi-deployed-using-user-provided-certificates-and-key) follows providing the detail for namespace and release name.
- Update the secret with new certificate information similar to what is described in [Scaling up NiFi deployed using user-provided certificates and key
](#scaling-up-nifi-deployed-using-user-provided-certificates-and-key)
- Now we need to restart the cluster, simply delete the pods and the cluster nodes would be restarted. This can be done by either using a rollout restart or the scale-down followed by scale-up.
    ```
    # Following is the syntax command to use rollout restart
    $ kubectl -n namespace_name rollout restart sts nifi_stateful_set_name
    
    # Following is the syntax command to use scale-down and scale-up commands to make a restart
    $ kubectl -n namespace_name scale sts nifi_stateful_set_name --replicas=0
    $ kubectl -n namespace_name scale sts nifi_stateful_set_name --replicas=replicas_required
    ```

# Using Azure Managed Identity

We are utilizing [AAD Pod Identity](https://github.com/Azure/aad-pod-identity) for using Azure managed identity with Apache NiFi pods on AKS cluster.

We will setup AAD pod identity to create CRDs etc. and then deploy `AzureIdentity` and `AzureIdentityBinding` followed by deploying NiFi using helm chart providing the values for `managedIdentity.AzureIdentityBinding.selectorLabel` after updating `managedIdentity.enabled` to `true`.

Proceed as following to deploy [Apache NiFi](https://github.com/apache/nifi) with [AAD pod identity](https://github.com/Azure/aad-pod-identity) using [helm chart](./nifi).

- Deploy AAD pod identity: deploy using Helm 3
    ```
    # Add helm repository
    $ helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
    # Install aad pod identity
    $ helm install aad-pod-identity aad-pod-identity/aad-pod-identity --set nmi.allowNetworkPluginKubenet=true
    ```
- Create identity on Azure, here we can use two types of identities user-assigned MSI, or service-principal with client secret.
    - **user-managed MSI**: create the managed identity and grant relevant access to the identity, and create `AzureIdentity`.
        ```
        #
        # Get identity details
        #
        $ export IDENTITY_RESOURCE_GROUP='user-identity-1-rgp'
        $ export IDENTITY_NAME='user-identity-1'
        $ export IDENTITY_CLIENT_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query clientId -otsv)"
        $ export IDENTITY_RESOURCE_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query id -otsv)"
        #
        # Create AzureIdentity
        #
        $ cat <<EOF | kubectl apply -f -
        apiVersion: "aadpodidentity.k8s.io/v1"
        kind: AzureIdentity
        metadata:
            name: aad-azure-identity-1
        spec:
            type: 0
            resourceID: ${IDENTITY_RESOURCE_ID}
            clientID: ${IDENTITY_CLIENT_ID}
        EOF
        ```
    - **Service Principal with client secret**: create the service-principal with client secret either using the registered app with relevant access to applications or simply create a service-principal for rbac.
        ```
        # Create service princiapal for RBAC
        $ az ad sp create-for-rbac --name aad-sp1
        ```
        Above command would provide the tenant-id, client-id and secret. we will use these for creating kubernetes secret and `AzureIdentity`.
        ```
        # Create kubernetes for the client-secret
        $ kubectl create secret generic aad-sp1 --from-literal=clientSecret="client_secret"
        ```

        ```
        # Create AzureIdentity
        $ cat <<EOF | kubectl apply -f -
        apiVersion: "aadpodidentity.k8s.io/v1"
        kind: AzureIdentity
        metadata:
            name: aad-azure-identity-1
        spec:
            type: 1
            tenantID: "TENANT_ID"
            clientID: "CLIENT_ID"
            clientPassword: {"name":"aad-sp1","namespace":"default"}
        EOF
        ```
- Create `AzureIdentityBinding` referencing the `AzureIdentity` which we just created.
    ```
    cat <<EOF | kubectl apply -f -
    apiVersion: "aadpodidentity.k8s.io/v1"
    kind: AzureIdentityBinding
    metadata:
        name: aad-azure-identity-1-binding
    spec:
        azureIdentity: aad-azure-identity-1
        selector: aad-azure-identity-1-selector
    EOF
    ```
- Update following properties in [values.yaml](./nifi/values.yaml) and then deploy using make target
    - `managedIdentity.enabled`: set it to `true`
    - `managedIdentity.AzureIdentityBinding.selectorLabel`: set it to `aad-azure-identity-1-selector` as used above in creating `AzureIdentityBinding`.
    ```
    $ make deploy-nifi
    ```
- Alternatively, you can directly provide values while deploying helm chart
    ```
    $ kubectl create namespace aad-trial-1
    $ helm install aad-trial-1 nifi -n aad-trial-1 --set managedIdentity.enabled=true --set managedIdentity.AzureIdentityBinding.selectorLabel=aad-azure-identity-1-selector
    ```

FYI, you would need to grant relevant access to the user-managed identity or service-principal before using it with Azure resources.

# Using Ingress

The kubernetes cluster should have an ingress controller deployed to use ingress routes.

## Installing Ingress Controller

To create the ingress controller, use Helm to install the chart [ingress-nginx](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx).

The ingress controller needs to be scheduled on a Linux node. Windows Server nodes shouldn't run the ingress controller. A node selector is specified using the --set nodeSelector parameter to tell the Kubernetes scheduler to run the NGINX ingress controller on a Linux-based node.

```
# Create a namespace for your ingress resources
$ kubectl create namespace ingress-basic

# Add the ingress-nginx repository
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Use Helm to deploy an NGINX ingress controller
$ helm install nginx-ingress ingress-nginx/ingress-nginx \
    --namespace ingress-basic \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux
```

Once the controller is up and running, once can check the resources in the namespace `ingress-basic`. A loadbalancer service would be created for nginx ingress controller, a dynamic public IP address is assigned, and can be found as follows:

```
$ kubectl --namespace ingress-basic get services -o wide -w nginx-ingress-ingress-nginx-controller

NAME                                     TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)                      AGE   SELECTOR
nginx-ingress-ingress-nginx-controller   LoadBalancer   10.0.74.133   EXTERNAL_IP     80:32486/TCP,443:30953/TCP   44s   app.kubernetes.io/component=controller,app.kubernetes.io/instance=nginx-ingress,app.kubernetes.io/name=ingress-nginx
```

## Deploying NiFi with Ingress Routes

There is a section in [values.yaml](./nifi/values.yaml) for *ingress* settings.

Following configurations are possible for enabling ingress routes:
- Anonymous access ingress enabled on an anonymous NiFi cluster.

    - Set `ingress.enabled` to `true`
- Certificate authentication ingress enabled on an anonymous NiFi cluster.
    - Set `ingress.enabled` to `true`
    - Set `ingress.tlsOnAnonymousNifi` to `true`
    - Provide values for parameters under `ingress.tlsCerts`
        - `privateKey`: provide the filename of tls private-key located in `tlsCerts.dir`
        - `certificate`: provide the filename of tls certificate located in `tlsCerts.dir`
        - `rootCaCertificate`: provide the filename of tls root-ca certificate located in `tlsCerts.dir`
- Ingress enabled on a secured NiFi cluster.
    - Set `ingress.enabled` to `true`
    - Provide values for parameters under `ingress.tlsCerts`
        - `privateKey`: provide the filename of tls private-key located in `tlsCerts.dir`
        - `certificate`: provide the filename of tls certificate located in `tlsCerts.dir`
        - `rootCaCertificate`: provide the filename of tls root-ca certificate located in `tlsCerts.dir`

## Authentication with secured NiFi cluster

Using ingress will simplify the certificate requirements for setting up secured NiFi cluster.

Users will be required to provide tls certs only for the ingress controller with the option of running NiFi with the certificate source `nifiToolkit`. This would help users to minimize certificate requirements which now would only be required for ingress controller and the NiFi nodes certificates could be generated automatically by system using `nifi-toolkit`.

Users can still follow the other certificate source `userProvided` and provide their certificate for every NiFi node. In this case if they want to run ingress controller they will have to provide another set of certificate for ingress controller for the owner `ingress.user.name` to authenticate ingress controller against NiFi. This certificate and the private key to authenticate can be provided as `ingress.proxyCerts.certificate` and `ingress.proxyCerts.privateKey`, respectively.

If users do not enable any other authentication method then the default method of authentication for users will be certificate and NiFi users can use the certificate issued from the CA whose certifcates are used on ingress controller.

# Creating Initial users for NiFi Cluster

One of the important activity after a secured NiFi cluster is created is to setup users for accessing NiFi.

The helm chart now provides feature to specifiy an initial list of users to be created on the NiFi cluster.

There are two types of users that can be created.

- *admins*: These users will be admin users having access to every policy.
- *uiUsers*: These users will have access only to the NiFi UI via `/flow` policy.

To create initial users one would setup following parameters under `nifi.initUsers` in [values.yaml](./nifi/values.yaml).

- `enabled`: Set it to `true` to enable creation of initial users.
- `admins`: Provide a list of users which are to created as admin users.
- `uiUsers`: Provide a list of users which are to created with access to NiFi UI only.

Following is an example of how to specify initUsers. These can be users authenticated via any mechanism (cert/OpenID/LDAP).

```
  initUsers:
    enabled: true
    admins:
      - "CN=admin1"
      - "admin2"
      - "admin3@def.com"
    uiUsers:
      - "CN=user1"
      - "user2"
      - "user3@def.com"
```

