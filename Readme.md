# Kubernetes Cilium terraform plan


This is a simple terraform script that creates a Kubernetes cluster that has
enabled by default cilium-CNI plugin.

To execute it, you need to run the following code:

```
terraform init
terraform apply
```

You have the following variables:

    - credentials: json credentials provided by GCP
    - machine_type: instance type for vms, default n1-standard-1
    - nodes: Number of nodes for k8s cluster. Default 1
    - private_key_path: Path for the private ssh keys. Default ~/.ssh/google_compute_engine
    - project: GCP project name, default k8s-cilium
    - region: Region to run the cluster, default europe-west1
    - token: kubernetes auth token.
    - zone: zone to run the cluster, default europe-west-1b
