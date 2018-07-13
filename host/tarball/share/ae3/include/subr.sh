#
# Not executable as a separate unit.
#

type UserRequireRoot >/dev/null 2>&1 || \
	. "/usr/local/share/myx.common/bin/user/requireRoot"

type ReplaceLine >/dev/null 2>&1 || \
	. "/usr/local/share/myx.common/bin/lib/replaceLine"

UserIsRoot(){
	return $(test `id -u` = 0);
}


#
# Check user
#
UserIsOperator(){
	return $(`id | grep -q '(ae3)'`);
}



#
# Check user
#
UserIsDaemon(){
	return $(test "`id -un`" = 'ae3' );
}



#
# Require operator
#
UserRequireOperator(){
	UserIsRoot || UserIsOperator || { echo "Must be run by ae3 operator but current user is '`id -un`'"; exit 1; }
}



#
# Require daemon ('ae3' user')
#
UserRequireDaemon(){
	UserIsDaemon || { echo "Must be run by ae3 daemon but current user is '`id -un`'"; exit 1; }
}



GetAdminEmail(){
	local FR="^root:"
	grep -q -e "$FR" /etc/mail/aliases || { echo "no admin email specified, use: ae3 config/email your@email.address"; return 1; }
	local TEMP=`grep -e "$FR" /etc/mail/aliases`
	echo "${TEMP#root: }"
	return 0;
}


CheckDaemonSettings(){
	#ae3d_enable="${ae3d_enable:-"NO"}"
	
	ae3d_chdir="${ae3d_chdir:-"/usr/local/ae3"}"
	ae3d_user="${ae3d_user:-"ae3"}"
	ae3d_group="${ae3d_group:-"ae3"}"
	
	ae3d_mode="${ae3d_mode:-"live"}"

	ae3d_daemon="${ae3d_daemon:-"ENABLE"}"
	ae3d_assert="${ae3d_assert:-"NORMAL"}"
	ae3d_logging="${ae3d_logging:-"NORMAL"}"
	ae3d_optimize="${ae3d_optimize:-"DEFAULT"}"
	ae3d_profile="${ae3d_profile:-"OFF"}"
	ae3d_storage="${ae3d_storage:-"s4fs:lcl:bdbje"}"
	ae3d_javaopts="${ae3d_javaopts:-""}"
	ae3d_ram="${ae3d_ram:-"1G"}"
	
	ae3d_ip_listen="0.0.0.0"
	ae3d_ip_external="0.0.0.0"
	ae3d_ip_cluster="0.0.0.0"
	return 0;
}


LoadDaemonSettings(){
	UserRequireOperator
	
	[ -f "$AE3_HOME/ae3d.conf" ] && . "$AE3_HOME/ae3d.conf"

	CheckDaemonSettings	
}


StoreDaemonSettings(){
	UserRequireOperator
	
	cat > "$AE3_HOME/ae3d.conf" <<-EOF
		ae3d_daemon="${ae3d_daemon}"
		ae3d_assert="${ae3d_assert}"
		ae3d_logging="${ae3d_logging}"
		ae3d_optimize="${ae3d_optimize}"
		ae3d_profile="${ae3d_profile}"
		ae3d_storage="${ae3d_storage}"
		ae3d_javaopts="${ae3d_javaopts}"
		ae3d_ram="${ae3d_ram}"
	EOF
}


GetAssertionsMode(){
	[ "$ae3d_assert" ] || LoadDaemonSettings
	echo $ae3d_assert
}


GetDaemonProcessMode(){
	[ "$ae3d_daemon" ] || LoadDaemonSettings
	echo $ae3d_daemon
}

GetLoggingLevel(){
	[ "$ae3d_logging" ] || LoadDaemonSettings
	echo $ae3d_logging
}

GetOptimizationGoal(){
	[ "$ae3d_optimize" ] || LoadDaemonSettings
	echo $ae3d_optimize
}

GetProfilingMode(){
	[ "$ae3d_profile" ] || LoadDaemonSettings
	echo $ae3d_profile
}



GetProfilingOptions(){
	[ "$ae3d_profile" ] || LoadDaemonSettings

	case "$ae3d_profile" in
		OFF)
			;;
		YJP)
			echo " -agentpath:/usr/local/share/ae3/yjp/freebsd-x86-64/libyjpagent.so=listen=127.0.0.1:10001,delay=30000,sessionname=ae3d "
			;;
		JMX)
			echo \
				" -Dcom.sun.management.jmxremote " \
				" -Dcom.sun.management.jmxremote.port=9010 " \
				" -Dcom.sun.management.jmxremote.local.only=true " \
				" -Dcom.sun.management.jmxremote.authenticate=false " \
				" -Dcom.sun.management.jmxremote.ssl=false " 
			;;
		*) 
			;;
	esac
}


GetStorageDescription(){
	[ "$ae3d_storage" ] || LoadDaemonSettings
	echo $ae3d_storage
}

GetJavaOptions(){
	[ "$ae3d_javaopts" ] || LoadDaemonSettings
	echo $ae3d_javaopts
}

GetMemoryAllocation(){
	[ "$ae3d_ram" ] || LoadDaemonSettings
	echo $ae3d_ram
}



GenerateToken(){
	UserRequireOperator
	local FOLDR=${AE3_HOME}/private/auth/tokens
	[ -d $FOLDR ] || { mkdir -p $FOLDR; chown ae3:ae3 $FOLDR; }
	local TOKEN=`dd if=/dev/random bs=32 count=1 2> /dev/null | hexdump -e '4/4 "%04x"'`
	printf "`whoami`\x0a$TOKEN" > $FOLDR/$TOKEN
	chown :ae3 $FOLDR/$TOKEN
	echo $TOKEN
}




AE3="/usr/local/share/ae3"
AE3_BIN="$AE3/bin"
AE3_HOME="/usr/local/ae3"

# public folder, where 'resources' should be
AE3_PUBLIC="$AE3_HOME/public"

# unpacked java classes
AE3_UNPACK="$AE3_HOME/unpack"

AE3_PRIVATE="$AE3_HOME/private"
AE3_CLUSTER="$AE3_HOME/cluster"
AE3_SHARED="$AE3_HOME/shared"

AE3_LOGS=$AE3_PRIVATE/logs

# should be used only for daemon?
AE3_STDIN="$AE3_PRIVATE/run/stdin"
AE3_STDOUT_LOG="$AE3_LOGS/stdout.log"
AE3_STDERR_LOG="$AE3_LOGS/stderr.log"
