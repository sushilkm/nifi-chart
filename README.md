# Helm charts

This directory has helm charts which are deployable on kubernetes.

One would need helm v3 to deploy the chart. To deploy helm follow instructions at https://helm.sh/docs/intro/install/

# Make targets
There is a [Makefile](./Makefile) in this directory, which has been added with targets to interact with nifi chart.

Following is a list of make targets to interact with the charts in directory.

- `make add-helm-incubator-repository` - Add helm incubator chart repository (we are using zookeeper chart published in incubator repository for nifi chart).
- `make update-nifi-dependency` -  Update the chart dependencies for nifi chart.
- `make deploy-nifi` - Deploy nifi chart on kubernetes to bring up a NiFi cluster.
- `make deploy-secured-nifi` - Deploy nifi chart on kubernetes to bring up a secured NiFi cluster.
- `make deploy-nifi-on-minikube` - Deploy nifi chart on minikube to bring up a NiFi cluster.
- `make deploy-secured-nifi` - Deploy nifi chart on minikube to bring up a secured NiFi cluster.
- `make delete-release` - Delete the deployed release of nifi chart.
- `deploy-secured-nifi-with-openid-authentication-on-minikube` - Deploy nifi chart on minikube to bring up a secured NiFi cluster authenticating via OpenId.
- `deploy-secured-nifi-with-openid-authentication` - Deploy nifi chart on kubernetes to bring up a secured NiFi cluster authenticating via OpenId.
- `deploy-secured-nifi-with-ldap-authentication-on-minikube` - Deploy nifi chart on minikube to bring up a secured NiFi cluster authenticating via LDAP.
- `deploy-secured-nifi-with-ldap-authentication` - Deploy nifi chart on kubernetes to bring up a secured NiFi cluster authenticating via LDAP.

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
- Now, we need to put these values in either [values.yaml](./nifi/values.yaml) file or [openid-values.yaml](./nifi/openid-values.yaml) as follows:
    - `discovery_url`: https://login.microsoftonline.com/<<Directory (tenant) ID>>/v2.0/.well-known/openid-configuration
    - `client_id`: <<Application (client) ID>>
    - `client_secret`: <<Client Secret>>
    - `admin_user`: Email/Username which will be used as admin user for NiFi
- Now run make target `deploy-secured-nifi-with-openid-authentication` to deploy NiFi using these configurations.
- Hostname of the accessible NiFi UI is suggested in the output as the DNS entry you are supposed to add in /etc/hosts file, using that entry we will create the redirect URL for NiFi, as follows.
https://<hostname>:<port>/nifi-api/access/oidc/callback
for eg. https://sample-1599088494-nifi.sample-1599088494.svc:443/nifi-api/access/oidc/callback
- Add the redirect URL created above to the app registration created earlier from "Authentication" option on the "App Registration" page in the "Redirect URI" textbox and click Save.
- Now you are good to go, access your NiFi UI, you would be redirected to Azure signin/app authorization and then redirected to NiFi UI.

# Deploying NiFi with authentication using LDAP Server

- One would need to provide the value of following paramters either in [values.yaml](./nifi/values.yaml) [ldap-values.yaml](./nifi/ldap-values.yaml)
    - `url`: This is ldap server URL, in the format `ldap://ldap_server_ip_or_name:ldap_server_port`
    - `manager_dn`: The DN of the manager that is used to bind to the LDAP server to search for users.
    - `manager_password`: The password of the manager that is used to bind to the LDAP server to search for users.
    - `admin_user_cn`: CN for the user to be used as "Initial Admin Identity"
    - `user_search_base`: Base DN for searching for users (i.e. CN=Users,DC=example,DC=com).
    - `user_search_filter`: Filter for searching for users against the 'User Search Base'. (i.e. sAMAccountName={0}). The user specified name is inserted into '{0}'.
    - `authorizers_provider_user_object_class`: This entry is for authorizers.xml. Object class for identifying users (i.e. person). Required if searching users.
    - `authorizers_provider_user_search_filter`: This entry is for authorizers.xml. Filter for searching for users against the 'User Search Base' (i.e. (memberof=cn=team1,ou=groups,o=nifi) ). Optional.
    - `authorizers_provider_user_group_name_attribute`: This entry is for authorizers.xml. Attribute to use to define group membership (i.e. member). Optional. If not set group membership will not be calculated through the groups. Will rely on group membership being defined through 'User Group Name Attribute' if set. The value of this property is the name of the attribute in the group ldap entry that associates them with a user. The value of that group attribute could be a dn or memberUid for instance. What value is expected is configured in the 'Group Member Attribute - Referenced User Attribute'. (i.e. member: cn=User 1,ou=users,o=nifi vs. memberUid: user1)
    - `authorizers_provider_group_search_base`: This entry is for authorizers.xml. Base DN for searching for groups (i.e. ou=groups,o=nifi). Required to search groups.
    - `authorizers_provider_group_object_class`: This entry is for authorizers.xml. Object class for identifying groups (i.e. groupOfNames). Required if searching groups.
- One can update other parameters too which have default values.
- Now run make target `deploy-secured-nifi-with-ldap-authentication` to deploy NiFi using these configurations.
- Hostname of the accessible NiFi UI is suggested in the output. Add the DNS entry you are supposed to add in /etc/hosts file.
- Now you are good to go, access your NiFi UI, you would be redirected to login page on NiFi UI.

# Deploying NiFi using user-provided certificates and key

If you want to deploy nifi with user provided certificates and keys then proceed as follows:

- We have got a values file [secured-values-with-user-provided-certs.yaml](./nifi/secured-values-with-user-provided-certs.yaml) where one can provide values certiifcate and private-key filenames.
- Copy your root-ca certificate, node-specific certificate and their private-key files to [nifi/certificates](./nifi/certficates) directory. We do not need private key for root-ca.
- Now specify the `node_certs` list with node number, privatekey file-name and certificate file-name as already suggested in the [`secured-values-with-user-provided-certs.yaml`](./nifi/secured-values-with-user-provided-certs.yaml) file.
- You can add/remove the numbers as per your requirement like
    ```
    - node: 4
       private_key: file4.key
       certificate: file4.crt
    ...
    ...
    ```
- If you are using certificate authentication then
    - enable admin user using `admin_user.enabled` to `true` otherwise `false`.
    - provide admin_user DN details as already the example provided.
    - provide admin certificate and private-key file-names under `admin_user` details.
- Once all the required files are copied to `certificates` directory and their names have been specified in `secured-values-with-user-provided-certs.yaml`, then call `deploy-secured-nifi-with-user-certs` make target to deploy NiFi cluster.

    ```
    $ make deploy-secured-nifi-with-user-certs
    ```

## Scaling up NiFi deployed using user-provided certificates and key

Once you have deployed NiFi cluster using the user-provided certificates, and you want to scale up, then proceed as follows.

- Copy your new node-specific certificate and their private-key files to [nifi/certificates](./nifi/certficates) directory. We do not need private key for root-ca.
- Now specify the `node_certs` list with new node number, privatekey file-name and certificate file-name in the [add-more-certs-values.yaml](./nifi/add-more-certs-values.yaml) file.
- You do not need to add pre-existing certificates to this values file, it is optional.
- You can add/remove the numbers as per your requirement like
    ```
    - node: 4
       private_key: file4.key
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
    $ DEPLOYED_NS=ns1 DEPLOYED=rs1 make update-secret-with-more-certs
    ```
    First example woud use release name as namespace itself.
- Last step would generate a file `deployed_secret.yaml` which has details of existing secret
- Copy the new details from the output of previous command, this data could be found under `node_certs` for eg.
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