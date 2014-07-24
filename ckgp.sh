#!/bin/bash

listfile=freeproxylistprovider.txt
Time="date +%s"
cmd_opt="--connect-timeout 15 -m 45 -x"

function get_site()
{
	local name=$1
	local site
	case $name in
	google )
		site=( 
		'http://www.google.com/?hl=en-US' 
		'google.initHistory' 
		) ;;
	gaovid )
		site=( 
		"http://199.195.197.140/videos" 
		"caoporn#gmail.com" 
		) ;;
	esac
	echo ${site[@]}
}

function check_p ()
{
	local name=$1
	local site=(`get_site $name`)
	local Page=${site[0]}
	local Key=${site[1]}
	local Lines=0

	exec 3< $listfile
	while read line <&3
	do {
		(( Lines++ ));

		echo
		echo Start Check proxy $Lines \"$line\" @ `date +%c`
		
		cmd="curl -Is $cmd_opt $line $Page"
		echo $cmd
		Start=`$Time`
		Head=`$cmd`
		res=$?
		End=`$Time`
		let Diff=$End-$Start
		echo Spent $Diff seconds for proxy \"$line\"

		if [ $res -ne 0 ]; then
			echo Check header failed, ignored.
			continue
		fi

		echo $Head | grep -q "HTTP/1.[01] \(200\|302\)"
		if [ $? -ne 0 ]; then
			echo Response error while check header, ignored.
			continue
		fi
		echo Check Header OK, try to fetch the webpage through proxy \"$line\" @ `date +%c`

		cmd="curl $cmd_opt $line $Page"
		echo $cmd
		Start=`$Time`
		Contents=`$cmd`
		res=$?
		End=`$Time`
		let Diff=$End-$Start

		if [ $res -ne 0 ]; then
			echo Fetch webpage failed, ignored.
			#echo $cmd >> contents.txt
			#echo $Contents >> contents.txt
			continue
		fi

		echo $Contents | grep -qF "$Key"
		if [ $? -eq 0 ]; then
			echo +++++ $line Check OK, Spent $Diff seconds in fetch first page.
			echo $line >> "$name"_Success.txt
		else
			echo Contents of webpage are wrong, ignored.
		fi
	}
	done
	exec 3>&-
}

check_p google
check_p gaovid
