#!/usr/bin/env bash
clean()
{
	make fclean -C $MAKEDIR > /dev/null
	rm -rf $PROGRAM
}

info() {
	echo "colors [INFO]" $@ "end colors"
	exit 0
}
fatal() {
	echo "colors [FATAL]" $@ "end colors"
	exit 1
}

test()
{
	while true; do
		x=$(((i+1) * ARG3))
		if ((x > ARG4)); then
			break
		fi
		TEST=$(shuf -i 0-$x -n $x)
		echo -e "\e[33m$x"
		if [[ $ARG2 == verify ]]; then
			RESULT=$(./$PROGRAM --"$ARG1" $TEST | ./checker_linux $TEST)
			[[ $RESULT == "OK" ]] && echo -e -n "\e[32mOK \e[0m" || echo -e -n "\e[31mKO \e[0m"
			
			RESULT=$(valgrind ./$PROGRAM --"$ARG1" $TEST 2>&1 | grep -c 'ERROR SUMMARY: 0 errors from 0 contexts')
			[[ $RESULT == 1 ]] && echo -e "\e[32mMOK\e[0m" || echo -e "\e[31mMKO\e[0m"
		else
			echo -n "$x, " >> $OUTPUT
			./$PROGRAM --"$ARG1" --bench $TEST 2>&1 | grep -a 'total_ops:' | cut -c 20-  >> $OUTPUT
		fi
		((i++))
	done
}

_main() {
	local ARG1="${1:-all}"
	local ARG2="${2:-verify}"
	local ARG3="${3:-50}"
	local ARG4="${4:-500}"
	local SHOULD_REMAKE="${5:-0}"
	local DIR="$(pwd)"
	local PROGRAM="push_swap"
	local CHECKER=$DIR/checker_linux
	local OUTPUT=$ARG1"_results.csv"
	local MAKEDIR=$DIR/..
	local G="\e[32m"
	local CLR="\e[0m"

	if [[ $ARG1 == clean ]]; then
		echo -e "${G}cleaning${CLR}"
		clean
		rm -rf complex_results.csv medium_results.csv simple_results.csv
		exit 0
	fi

	[[ $ARG1 == help ]] && cat <<EOF && return 0
		
ARG1 is for the algorithm flags, simple, medium, complex and adaptivethe all arg will run all flags
ARG1 can also be used to clean with the clean flag

ARG2 is for verification, default verification is active pass anything else to run the benchmark

ARG3 is for the step size and ARG4 is for the total size

SHOULD_REMAKE is for internal use as it bypasses compilation if used in the first call it wont work

EOF

	if [[ $ARG2 == verify && ! -f $CHECKER ]]; then
		echo -e "\e[31mCHECKER MISSING\e[0m"
		exit 1
	fi

	[[ ! -x $CHECKER ]] && chmod +x $CHECKER

	if [[ $SHOULD_REMAKE == 0 ]]; then
		if ! make re -C $MAKEDIR > /dev/null; then
			echo -e "\e[32mBuild failed\e[0m"
			clean
			exit 1
		fi

		ln -sf $MAKEDIR/$PROGRAM $DIR

		if [[ "$ARG1" != "all" ]]; then
			if ! ./"$PROGRAM" --"$ARG1" > /dev/null 2>&1; then
				echo -e "\e[31mBAD ARG1\e[0m"
				clean
				exit 1
			fi
		fi
	fi

	if [[ "$ARG1" == "all" ]]; then
		echo -e "\e[32m$ARG1 Algorithms\e[0m"
		./vis.sh adaptive $ARG2 $ARG3 $ARG4 1
		./vis.sh simple $ARG2 $ARG3 $ARG4 1
		./vis.sh medium $ARG2 $ARG3 $ARG4 1
		./vis.sh complex $ARG2 $ARG3 $ARG4 1
		if [[ $ARG2 == verify ]]; then
			./vis.sh clean
		fi
		clean
	else
		echo -e "\e[32m$ARG1 Algorithm\e[0m"
		> "$OUTPUT"
		test
		if [[ $SHOULD_REMAKE == 0 ]]; then
			clean
		fi
	fi

	echo 
	return 0
}

_main $@