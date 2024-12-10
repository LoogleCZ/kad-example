#!/bin/bash -x

R_BRANCH="${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
R_COMMIT="${COMMIT:-$(git rev-parse HEAD)}"
R_TAG="${TAG:-docker.io/tomkukral/kad:latest}"

# build container using podman
podman build \
	--format docker \
	--label branch="${R_BRANCH}" \
	--label commit="${R_COMMIT}" \
	--tag "${R_TAG}" .

# parse digest
DIGEST="$(podman inspect ${R_TAG} | jq -r '.[0].Digest')"
echo "Image digest is ${DIGEST}"

podman push "${R_TAG}"

echo "Signing image with cosign"
cosign sign \
    --key <(pass show cosign_kad) \
    -a commit="${R_COMMIT}" \
    -a user="${USER}" \
    -a machine="$(hostname)" \
    "${R_TAG}"

# verify signature
cosign verify --key "https://gitlab.com/6shore.net/kad/-/raw/master/cosign.pub?ref_type=heads" "${R_TAG}"
