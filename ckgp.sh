#!/bin/bash

Lines=0
Time="date +%s"
Page="http://www.google.com?hl=en-US"
cmd_opt="--connect-timeout 15 -m 45 -x"

exec 3< freeproxylistprovider.txt
while read line <&3
do {
  (( Lines++ ));

  cmd="curl -Is $cmd_opt $line $Page"
  echo
  echo Start Check proxy $Line \"$line\" @ `date +%c`
  echo $cmd
  Start=`eval $Time`
  Head=`eval $cmd`
  res=$?
  End=`eval $Time`
  let Diff=$End-$Start
  echo Spent $Diff seconds for proxy \"$line\"
  if [ $res -ne 0 ]; then
	echo Check header failed, ignored.
	continue
  fi
  echo $Head | grep -q "HTTP/1.[01] \(200\|302\)"
  if [ $? -ne 0 ]; then
	echo Response error while check header, ignored.
  fi
  echo Check Header OK, try to fetch the webpage through proxy \"$line\" @ `date +%c`

  cmd="curl $cmd_opt $line $Page"
  echo $cmd
  Start=`eval $Time`
  Contents=`eval $cmd`
  res=$?
  End=`eval $Time`
  if [ $res -ne 0 ]; then
	echo Fetch webpage failed, ignored.
	#echo $cmd >> contents.txt
	#echo $Contents >> contents.txt
	continue
  fi
  let Diff=$End-$Start
  echo $Contents | grep -qF "google.initHistory"
  if [ $? -eq 0 ]; then
	echo +++++ $line Check OK, Spent $Diff seconds in fetch first page.
	echo $line >> Success.txt
  else
	echo Contents of webpage are wrong, ignored.
  fi
}
done
exec 3>&-
