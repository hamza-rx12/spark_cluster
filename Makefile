up:
	docker-compose up -d --build

down:
	docker-compose down

destroy:
	docker-compose down --rmi all
	rm -rf data/output && rm -rf warehouse

dev:
	docker exec -it spark-master bash

inspect:
	docker-compose ps


