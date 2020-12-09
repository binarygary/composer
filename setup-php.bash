#!/bin/bash
set -e
docker pull -q "php:$ACTION_PHP_VERSION"
dockerfile="FROM php:$ACTION_PHP_VERSION"

base_repo="$1"
echo "DEBUG: base_repo = $base_repo"
echo "DEBUG: GITHUB_ACTOR = ${GITHUB_ACTOR}"
echo "DEBUG: GITHUB_REPOSITORY = ${GITHUB_REPOSITORY}"
echo "DEBUG: GITHUB_SHA = ${GITHUB_SHA}"

echo "${ACTION_TOKEN}" | docker login docker.pkg.github.com -u "${GITHUB_ACTOR}" --password-stdin

if [ -n "$ACTION_PHP_EXTENSIONS" ]
then
	dockerfile="${dockerfile}
ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/"
	dockerfile="${dockerfile}
RUN chmod +x /usr/local/bin/install-php-extensions && sync && install-php-extensions"
fi

dockerfile_unique="${ACTION_PHP_VERSION}"
for ext in $ACTION_PHP_EXTENSIONS
do
	dockerfile="${dockerfile} $ext"
	dockerfile_unique="${dockerfile_unique}-${ext}"
done

# Remove illegal characters and make lowercase:
dockerfile_unique="${dockerfile_unique// /_}"
dockerfile_unique="${dockerfile_unique,,}"

docker_tag="docker.pkg.github.com/${GITHUB_REPOSITORY}/php-${base_repo}:${dockerfile_unique}"
echo "$docker_tag" > ./docker_tag

docker pull "$docker_tag" || echo "Remote tag does not exist"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${DIR}"
echo "$dockerfile" > Dockerfile
docker build --tag "$docker_tag" .
docker push "$docker_tag"