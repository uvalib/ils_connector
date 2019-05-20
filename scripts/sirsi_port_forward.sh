#! /bin/bash
ssh -NL 1521:localhost:8071 libsvr27.lib.virginia.edu &
PID=$!
ssh libsvr27.lib.virginia.edu -t ssh -NL 8071:localhost:1521 ils.lib.virginia.edu
kill $PID
echo "Tunnel closed"
