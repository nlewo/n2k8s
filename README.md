_n2k8s_ is an image to build container images from a Nix expression,
inside a container or Kubernetes cluster and push it to a registry.

**The contents of this repo are currently a WIP**

# Usage

The _n2k8s_ image is available on the Docker Hub:

    docker run -v $PWD/examples:/build lewo/n2k8s /entrypoint --context /build --destination localhost:5000/hello

See also the [`docker-compose` stack](./docker-compose.yaml).

## Authentication

`n2k8s` gets registry credentials from the Docker's cli config file
(located at `$HOME/.docker/docker.json` in the container).

### Amazon ECR authentication

To interact with the AWS ECR
- the `docker.json` file must contains a `credHelper` section:
```
{
  "credHelpers": {
    "aws_account_id.dkr.ecr.region.amazonaws.com": "ecr-login"
  }
}
```
- your `~/.aws/credentials` must be mounted to
  `/root/.aws/credentials` (usually provided by Kubernetes secret)


# TODO

- make `useSandbox = false` optionnal
- enable local binary cache
- reduce image size
- do not use root user
- switch to static Nix (to be able to mount `/nix/store`)

# Related

- https://github.com/GoogleContainerTools/kaniko
