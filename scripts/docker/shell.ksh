if [ -z "$DOCKER_HOST" ]; then
   echo "ERROR: no DOCKER_HOST defined"
   exit 1
fi

# set the definitions
INSTANCE=ils-connector
NAMESPACE=uvadave

# environment attributes
#RAILS_MASTER_KEY=
#DBHOST=
#DBNAME=
#DBUSER=
#DBPASSWD=

DBENV="-e DBHOST=$DBHOST -e DBNAME=$DBNAME -e DBUSER=$DBUSER -e DBPASSWD=$DBPASSWD"
RAILSENV="-e RAILS_MASTER_KEY=$RAILS_MASTER_KEY"

docker run -t -i -p 8500:3000 $RAILSENV $DBENV $NAMESPACE/$INSTANCE /bin/bash -l
