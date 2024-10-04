# Release new version
GIT_BRANCH=dev

GIT_VERSION=$(shell git tag --list | sort -V | tail -n 1)
GIT_NEXT_PATCH=$(shell echo $(GIT_VERSION) | awk -F. '{print $$1"."$$2"."$$3+1}')
GIT_NEXT_MINOR=$(shell echo $(GIT_VERSION) | awk -F. '{print $$1"."$$2+1".0"}')
GIT_NEXT_MAJOR=$(shell echo $(GIT_VERSION) | awk -F. '{print $$1+1".0.0"}')

tag:
	@git tag $(version)

push:
	@git push origin ${GIT_BRANCH} $(version)

release: tag push

# Bug fixes
patch:
	@make release version=${GIT_NEXT_PATCH}

# Minor changes: Does not break the API
minor:
	@make release version=${GIT_NEXT_MINOR}

# Major changes: Breaks the API
major:
	@make release version=${GIT_NEXT_MAJOR}
