_n2k8s_ is an image to build container images from a Nix expression,
inside a container or Kubernetes cluster and push it to a registry.

# Usage

The _n2k8s_ image is available on the Docker Hub:

    docker run -v $PWD/examples:/build lewo/n2k8s /entrypoint --context /build --destination localhost:5000/hello

See also the [`docker-compose` stack](./docker-compose.yaml).

## Amazon ECR authentication

If the option `--aws-region` is set, `skopeo` will log in to AWS to push
the image. Note the `.aws` Amazon credentials directory must be
mounted at `/root/.aws`.

# TODO

- make `useSandbox = false` optionnal
- enable local binary cache
- add options
- reduce image size
- ...

# Related

- https://github.com/GoogleContainerTools/kaniko
