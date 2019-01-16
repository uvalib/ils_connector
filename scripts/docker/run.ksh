if [ -z "$DOCKER_HOST" ]; then
   echo "ERROR: no DOCKER_HOST defined"
   exit 1
fi

# set the definitions
INSTANCE=ils-conector
NAMESPACE=uvadave

# environment attributes
#API_TOKEN=94DE1D63-72F1-44A1-BC7D-F12FC951
#DEPOSITAUTH_URL=tp://docker1.lib.virginia.edu:8230
#DEPOSITREG_URL=http://docker1.lib.virginia.edu:8220
#USERINFO_URL=http://docker1.lib.virginia.edu:8010

#DOCKER_ENV="-e API_TOKEN=$API_TOKEN -e DEPOSITAUTH_URL=$DEPOSITAUTH_URL -e DEPOSITREG_URL=$DEPOSITREG_URL -e USERINFO_URL=$USERINFO_URL"

# stop the running instance
docker stop $INSTANCE

# remove the instance
docker rm $INSTANCE

# remove the previously tagged version
docker rmi $NAMESPACE/$INSTANCE:current  

# tag the latest as the current
docker tag -f $NAMESPACE/$INSTANCE:latest $NAMESPACE/$INSTANCE:current

docker run -d -p 8500:3000 $DOCKER_ENV --name $INSTANCE $NAMESPACE/$INSTANCE:latest

# return status
exit $?
