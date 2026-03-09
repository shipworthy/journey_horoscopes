.PHONY: \
	all \
	all-clean \
	build \
	build-test \
	clean \
	db-local-psql \
	db-local-rebuild \
	format \
	format-check \
	run-dev \
	test


POSTGRES_DB_CONTAINER_NAME?=my-postgres


all: build format-check test


all-clean: clean deps-get all


build:
	mix clean
	mix compile --warnings-as-errors --force


build-test:
	MIX_ENV=test mix clean
	MIX_ENV=test mix compile --warnings-as-errors --force


clean:
	MIX_ENV=test mix clean
	mix clean
	mix deps.clean --all


db-local-psql:
	docker exec -it $(POSTGRES_DB_CONTAINER_NAME) psql -U postgres


db-local-rebuild:
	docker rm -fv $(POSTGRES_DB_CONTAINER_NAME)
	docker run --name $(POSTGRES_DB_CONTAINER_NAME) -p 5432:5432 -e POSTGRES_PASSWORD=postgres -d postgres:16.4


format:
	mix format


format-check:
	mix format --check-formatted


lint:
	mix credo --all --strict


run-dev:
	mix compile --warnings-as-errors
	mix assets.build
	mix assets.deploy
	(mix phx.server || true) && mix phx.digest.clean --all


test:
	MIX_ENV=test mix ecto.drop -r Demo.Repo
	MIX_ENV=test mix ecto.create -r Demo.Repo
	MIX_ENV=test mix ecto.drop -r Journey.Repo
	MIX_ENV=test mix ecto.create -r Journey.Repo
	mix test --trace --warnings-as-errors --cover


validate: format-check lint test

