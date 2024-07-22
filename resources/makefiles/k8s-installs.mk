PROJECT_ROOT ?= ../../

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