GIT_BRANCH=dev

# Release new version
GIT_VERSION=$(shell git describe --tags)
GIT_NEXT_PATCH=$(shell echo $(GIT_VERSION) | awk -F. '{print $$1"."$$2"."$$3+1}')
GIT_NEXT_MINOR=$(shell echo $(GIT_VERSION) | awk -F. '{print $$1"."$$2+1".0"}')
GIT_NEXT_MAJOR=$(shell echo $(GIT_VERSION) | awk -F. '{print $$1+1".0.0"}')

# Tag a new version
tag:
	@git tag $(version)

# Push a new tag
push:
	@git push origin ${GIT_BRANCH} $(version)

# Publish a new version
publish: tag push

# Bug fixes
patch:
	@make publish version=${GIT_NEXT_PATCH}

# Minor changes: Does not break the API
minor:
	@make publish version=${GIT_NEXT_MINOR}

# Major changes: Breaks the API
major:
	@make publish version=${GIT_NEXT_MAJOR}

# Release a new version
release: 
	@make publish version=${GIT_VERSION}-release
