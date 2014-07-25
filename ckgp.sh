#!/bin/bash

listfile=freeproxylistprovider.txt

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
	local Page
	local Key=${site[1]}
	local Lines=0
	local Time="date +%s"
	local cmd_opt="--connect-timeout 15 -m 45 -x"
	local resp_file=response.txt
	local rcode
	local speed

	[ -f "$name"_Success.txt ] && rm -f "$name"_Success.txt
	exec 3< $listfile
	while read line <&3
	do {
		Page=${site[0]}
		(( Lines++ ));

		echo
		echo Start Check proxy $Lines \"$line\" @ `date +%c`
		rcode=
		speed=0
		
		while true; do
			cmd="curl -Is $cmd_opt $line $Page"
			echo $cmd

			Start=`$Time`
			$cmd | tee $resp_file
			res=$?
			End=`$Time`
			
			let Diff=$End-$Start
			let speed+=$Diff
			
			echo Spent $Diff seconds for proxy \"$line\"

			if [ $res -ne 0 ]; then
				echo Check header failed, ignored.
				continue 2
			fi

			#grep -q "HTTP/1.[01] \(200\|302\)" $resp_file
			#if [ $? -ne 0 ]; then
			#	echo Response error while check header, ignored.
			#	continue 2
			#fi

			rcode=`head -1 $resp_file`
			rcode=${rcode:9:3}

			if [ "$rcode" == "200" ]; then
				break
			elif [ "$rcode" == "302" ]; then
				Page=`sed -ne "s/^Location: \(http.*\)/\1/p" $resp_file`
				#cmd="curl -Is $cmd_opt $line $loc"
				#echo $cmd
				continue
			fi

			echo Response error while check header, ignored.
			continue 2
		done

		echo Check Header OK, try to fetch the webpage through proxy \"$line\" @ `date +%c`

		cmd="curl $cmd_opt $line $Page"
		echo $cmd
		
		Start=`$Time`
		$cmd > $resp_file
		res=$?
		End=`$Time`
		
		let Diff=$End-$Start
		let speed+=$Diff

		if [ $res -ne 0 ]; then
			echo Fetch webpage failed, ignored.
			continue
		fi

		grep -qF "$Key" $resp_file
		if [ $? -eq 0 ]; then
			echo +++++ $line Check OK, Spent $Diff seconds in fetch first page.
			echo "$line :$speed" >> "$name"_Success.txt
		else
			echo Contents of webpage are wrong, ignored.
		fi
	}
	done
	exec 3>&-
}

check_p google
check_p gaovid
