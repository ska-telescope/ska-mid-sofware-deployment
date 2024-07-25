PYTHON_PUBLISH_URL := https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/
# include makefile targets from the submodule
include .make/oci.mk

# include k8s support
include .make/k8s.mk

# include Helm Chart support
include .make/helm.mk

# Include Python support
include .make/python.mk

# include raw support
include .make/raw.mk

# include core make support
include .make/base.mk

# include your own private variables for custom deployment configuration
-include PrivateRules.mak

# include xray support
include .make/xray.mk

PROJECT = ska-mid-software-deployment

OCI_IMAGE_BUILD_CONTEXT := $(PWD)

ENV_TYPE ?= ci # the environment in which the k8s installation takes place
K8S_CHART ?= 
# we use this image tag to know which image to use in the chart
IMAGE_TAG ?= $(VERSION)-dev.c$(CI_COMMIT_SHORT_SHA)
OCI_REGISTRY = $(CI_REGISTRY)
PROJECT_NAMESPACE = /$(CI_PROJECT_NAMESPACE)/$(CI_PROJECT_NAME)
ifeq ($(CI_JOB_ID),)
	OCI_REGISTRY = 
	PROJECT_NAMESPACE =
	HELM_RELEASE = dev
	ENV_TYPE = dev
	IMAGE_TAG = $(VERSION)
	KUBE_NAMESPACE = test-parent
	K8S_CHART = test-parent
endif

TANGO_HOST ?= tango-databaseds:10000
CI_RUNNER_TAGS ?= local
#speed up python linting. Setting this --jobs flag to 0,
#makes the pylint to detect the number of processors
#available and use all of them.
#See https://pylint.pycqa.org/en/1.6.0/features.html
PYTHON_SWITCHES_FOR_PYLINT := --jobs 0
PYTHON_LINE_LENGTH := 120
# Not sure why these are required as well
PYTHON_SWITCHES_FOR_BLACK := --line-length $(PYTHON_LINE_LENGTH)
PYTHON_SWITCHES_FOR_FLAKE8 := --max-line-length $(PYTHON_LINE_LENGTH)
PYTHON_SWITCHES_FOR_PYLINT := --max-line-length $(PYTHON_LINE_LENGTH)
example-start-server:
	uvicorn src.ska_cicd_training_pipeline_machinery.main:app --reload

PYTHON_VARS_AFTER_PYTEST = --disable-pytest-warnings

test: python-test

### USEFUL BITS FROM LOW
DOCS_SPHINXOPTS=-n -W --keep-going

# https://github.com/pytest-dev/pytest-bdd/issues/401
PYTHON_VARS_BEFORE_PYTEST = PYTHONDONTWRITEBYTECODE=True

# better be verbose for debugging
PYTHON_VARS_AFTER_PYTEST ?= -v

# execute in true context; add BDD test results to be uploaded to xray
PYTHON_VARS_AFTER_PYTEST += -v --cucumberjson=build/reports/cucumber.json \
	--json-report --json-report-file=build/reports/report.json

# hack out PYTHONPATH - why is it even there?
# hack in test target directory
K8S_TEST_TEST_COMMAND = unset PYTHONPATH; TANGO_HOST=$(TANGO_HOST) \
						pytest \
						$(PYTHON_VARS_AFTER_PYTEST) ./tests/functional \
						 | tee pytest.stdout ## k8s-test test command to run in container

q_test:
	PYTHONDONTWRITEBYTECODE=True  pytest --disable-pytest-warnings \
	--cov=src --cov-report=term-missing --cov-report html:build/reports/code-coverage --cov-report xml:build/reports/code-coverage.xml --junitxml=build/reports/unit-tests.xml \
	./tests/functional 

install-chart: k8s-install-chart

uninstall-chart: k8s-uninstall-chart

reinstall-chart: uninstall-chart oci-build install-chart

lint: python-lint

version:
	@echo $(VERSION)

### VAULT SPECIFIC MAKEFILE TARGETS ###

## TARGET: flux-vault-dish-lmc-unistall
## SYNOPSIS: flux-vault-dish-lmc-unistall
## HOOKS: none
## VARS: none
## make target for uninstalling dish LMC helm charts
flux-vault-dish-lmc-unistall:
	cd helmrelease/mid-itf; \
	for i in vault-secrets.yaml kubeconfig.yaml helm-repo.yaml ska007-dish-lmc.yaml ; do \
	  kubectl delete -f $$i || true; \
	done
.PHONY: flux-vault-dish-lmc-unistall

## TARGET: flux-vault-dish-lmc-kubeconfig
## SYNOPSIS: flux-vault-dish-lmc-kubeconfig
## HOOKS: none
## VARS: none
## make target for installing dish LMC helm charts
flux-vault-dish-lmc-kubeconfig:
	$(eval TEMPDIR := $(shell mktemp -d))
	$(eval TMP_FILE:= $(TEMPDIR)/ska.yaml)
	cp -f charts/vault/kubeconfig.yaml $(TMP_FILE)
	KC=`kubectl config view --raw --flatten --minify | awk '{ print "    " $$0 }'`; \
	echo "$${KC}" >> $(TMP_FILE)
	kubectl apply -f $(TMP_FILE)
	@rm -rf $(TEMPDIR)
.PHONY: flux-vault-dish-lmc-kubeconfig

## TARGET: flux-vault-dish-lmc-secrets
## SYNOPSIS: flux-vault-dish-lmc-secrets
## HOOKS: none
## VARS: none
## make target for installing vault secrets helm chart
flux-vault-dish-lmc-secrets:
	kubectl apply -f charts/vault/vault-secrets.yaml
.PHONY: flux-vault-dish-lmc-secrets

## TARGET: flux-vault-dish-lmc-secrets
## SYNOPSIS: flux-vault-dish-lmc-secrets
## HOOKS: none
## VARS: none
## make target for installing vault secrets helm chart
flux-vault-dish-lmc:
	cd charts/vault; \
	for i in helm-repo.yaml ska007-dish-lmc.yaml ; do \
	  kubectl apply -f $$i; \
	done
.PHONY: flux-vault-dish-lmc

## TARGET: flux-vault-dish-lmc-all
## SYNOPSIS: flux-vault-dish-lmc-all
## HOOKS: none
## VARS: none
## make target for installing all vault helm charts
flux-vault-dish-lmc-all: flux-vault-dish-lmc-kubeconfig flux-vault-dish-lmc flux-vault-dish-lmc-secrets
.PHONY: flux-vault-dish-lmc-all