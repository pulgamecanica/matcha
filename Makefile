DOCKER_CONTAINER_NAME = web

docs:
	docker compose run \
		-it \
		--remove-orphans \
		${DOCKER_CONTAINER_NAME} \
		rake doc:export

create:
	docker compose run \
		-it \
		--remove-orphans \
		${DOCKER_CONTAINER_NAME} \
		rake db:create

migrate:
	docker compose run \
		-it \
		--remove-orphans \
		${DOCKER_CONTAINER_NAME} \
		rake db:migrate

test:
	docker compose run \
		-it \
		--remove-orphans \
		${DOCKER_CONTAINER_NAME} \
		bundle exec rspec

console:
	docker compose run \
		${DOCKER_CONTAINER_NAME} \
		irb -r ./app

.PHONY: docs test migrate
