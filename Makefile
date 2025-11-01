PWD=$(shell pwd)
USERID=$(shell id -u)

.PHONY: docs lint all

all: lint docs

docs:
	@echo "Running terraform docs..."
	@docker run --rm --volume "${PWD}:/terraform-docs" -u ${USERID} quay.io/terraform-docs/terraform-docs:0.20.0 markdown --output-file README.md --output-mode inject /terraform-docs
	@docker run --rm --volume "${PWD}/examples/complete:/terraform-docs" -u ${USERID} quay.io/terraform-docs/terraform-docs:0.20.0 markdown --output-file README.md --output-mode inject /terraform-docs
	@docker run --rm --volume "${PWD}/modules/alb-integration:/terraform-docs" -u ${USERID} quay.io/terraform-docs/terraform-docs:0.20.0 markdown --output-file README.md --output-mode inject /terraform-docs
	@docker run --rm --volume "${PWD}/modules/ecs-cluster:/terraform-docs" -u ${USERID} quay.io/terraform-docs/terraform-docs:0.20.0 markdown --output-file README.md --output-mode inject /terraform-docs
	@docker run --rm --volume "${PWD}/modules/ecs-service:/terraform-docs" -u ${USERID} quay.io/terraform-docs/terraform-docs:0.20.0 markdown --output-file README.md --output-mode inject /terraform-docs

lint:
	@echo "Running terraform fmt..."
	@terraform fmt --recursive