# Release new version
GIT_BRANCH=dev

GIT_CURRENT_VERSION=$(shell git tag --list | sort -V | tail -n 1)
GIT_NEXT_PATCH=$(shell echo $(GIT_CURRENT_VERSION) | awk -F. '{print $$1"."$$2"."$$3+1}')
GIT_NEXT_MINOR=$(shell echo $(GIT_CURRENT_VERSION) | awk -F. '{print $$1"."$$2+1".0"}')
GIT_NEXT_MAJOR=$(shell echo $(GIT_CURRENT_VERSION) | awk -F. '{print $$1+1".0.0"}')

tag:
	@git tag $(version)

push:
	@git push origin ${GIT_BRANCH} $(version)

# Bug fixes
patch:
	@make tag version=${GIT_NEXT_PATCH}

# Minor changes: Does not break the API
minor:
	@make tag version=${GIT_NEXT_MINOR}

# Major changes: Breaks the API
major:
	@make tag version=${GIT_NEXT_MAJOR}

# Release current version
release: 
	@make push version=${GIT_CURRENT_VERSION}
