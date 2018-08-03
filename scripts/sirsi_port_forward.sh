#! /bin/bash
ssh -NL 1521:localhost:8070 libsvr26.lib.virginia.edu &
PID=$!
ssh libsvr26.lib.virginia.edu -t ssh -NL 8070:localhost:1521 ilstest.lib.virginia.edu
kill $PID
echo "Tunnel closed"
