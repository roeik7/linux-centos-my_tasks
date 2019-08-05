#!/bin/bash
#-------------------------------------------------------

# Description : Execute tasks that the user choose.
# Exit code   :  0 valid input, otherwise invalid input.

# -------------------------------------------------------


check_dir_exist() #input:  fisrt arguemnt - source dir name
{
	if [ -z "$1" ]; then 	#check if empty variable
		echo "You need to enter a source dir in -s flag"  
		exit 1
	elif [[ ! -d "$1" ]]; then		#check if exist
		echo "The source directory is not found"
		exit 2

	fi
}


check_file_exist() # args: 1- file name
{

	if [ "$1" = "" ]; then
		echo "you have to enter file name in -p flag"
		exit 1
	elif [[ ! -f "$1" ]]; then
		echo "The conig file is not found"
		exit 2

	fi
}

du_dirs() #input: source dir name
{
	check_dir_exist "$1"
	
	ls $1 -lS | grep "^d" | awk '{print $9, $5/1000 " MB"}' | sort -k 2
}

find_shell_scripts() #input: first arg - source dir name , second arg - execute pemission (true / empty)
{
	source_dir_name=$1
	execution_permission=$2
	check_dir_exist $source_dir_name
	

	if [ ! -z $execution_permission ] ; then
		find $source_dir_name -type f -name "*.sh" -print -exec chmod u+x 2>/dev/null {} \;
	else
		find $source_dir_name -type f -name "*.sh" -print
	fi

	exit 0
}

delete_old_files()  # input: first arg - source dir name , second arg - days
{
	source_dir_name=$1
	check_dir_exist $source_dir_name
		
	#check second argument is a number
	if [[ $2 =~ ^[0-9]+$ ]]; then	
		find $source_dir_name -mtime +$2 -type f -exec rm > /dev/null 2>&1 {} \;	

	else 
		echo "The second argument (days) need to be number."
	fi
}


sync_dir() # input: first arg - source dir name , seecond arg - destination dir
{
	source_dir=$1
	dest_dir=$2

	check_dir_exist "$source_dir"
	check_dir_exist "$dest_dir"
	

	cp -Rn "$source_dir" "$dest_dir"  #copy all files from src to dest. recursive and without overwrite
 
	return 0
}

list_net_cards()
{
	ip -o addr | awk '{print $2 " " $4}'
	return 0
}

list_rpms()
{
	rpm -qa --queryformat '%{name} %{version} %{vendor} %{installtime:date}\n'
	return 0
}

ps_threads()
{	
	processes=`ps -e | awk '{print $1 " " $NF}' | grep -v PID`

	for process_details in $processes ; do
		pid=`echo $process_details | cut -d ' ' -f1`
		process_name=`echo $process_details | cut -d ' ' -f2`
		num_of_threads=`ps hH p $pid | wc -l`
		echo "$pid $process_name $num_of_threads"
	
	done
	
	return 0
}

shellshock()
{
	env x='() { :;}; echo shellshock' bash -c :
	
	return 0

}

send_signals() # first arg - config file name
{

	check_file_exist "$1"

	while IFS= read -r line
	do
		if [ ! -z "$line" ] && [[ ! "$line" =~ ^# ]]; then

			process_name=`echo $line | cut -d":" -f2`
			
			is_running=`ps -A | grep $process_name`

			if [ ! -z "$is_running" ]; then
				signal=`echo $line | cut -d":" -f1`
				pid=`pgrep $process_name`
				
				kill -s $signal $pid
				echo "The signal $signal sent to $process_name successfuly."
			fi
		fi

	done < "$1"		
		
	return 0
}

trap_sigint(){
	echo "SIGINT signal is not availble in this process."
}

trap_sigterm(){
	echo "SIGTERM signal is not availble in this process."
}

##### Main of the script #####

trap trap_sigint SIGINT
trap trap_sigterm SIGTERM

task_name=$1
shift

while getopts 's:p:m:d:x' flag; do

  		case "${flag}" in

  		  s) src_dir="${OPTARG}" ;;
  		  p) config_file="${OPTARG}" ;;
  		  m) days="${OPTARG}" ;;
		  d) dest_dir="${OPTARG}" ;;
		  x) execute_permission="1" ;;
		  *) echo "Flags are not in the correct format."
		     exit 1 ;;

  		esac
	done


case $task_name in
	"du_dirs") 
		$task_name "$src_dir"
		;;
	
	"find_shell_scripts")
		$task_name "$src_dir" "$execute_permission"
		;;
		
	"send_signals")
		$task_name "$config_file"
		;;
		
	"delete_old_files")
		$task_name "$src_dir" "$days"
		;;
		
	"sync_dir")
		$task_name "$src_dir" "$dest_dir"
		;;
		
	"list_net_cards")
		$task_name
		;;
	
	"list_rpms")
		$task_name
		;;
		
	"ps_threads")
		$task_name
		;;
		
	"shellshock")
		$task_name
		;;
		
	*)
		echo "Illegal task, please try again."
		exit 1
		;;

esac
exit 0
		