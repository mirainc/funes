eval $(docker-machine env)

docker-compose -f docker-compose.test.yml up
