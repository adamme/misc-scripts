#!/bin/sh

[[ $EUID == 0 ]] || { echo "Must be run as root."; exit; }

PKGNAME=AgentUninstaller
LOG=/tmp/$PKGNAME.log
touch $LOG
chmod a+rw $LOG

DAEMON_PLIST="/Library/LaunchDaemons/com.airwatch.airwatchd.plist"
AGENT_PLIST="/Library/LaunchAgents/com.airwatch.mac.agent.plist"
AWCM_PLIST="/Library/LaunchDaemons/com.airwatch.awcmd.plist"
SCHEDULER_PLIST="/Library/LaunchDaemons/com.airwatch.AWSoftwareUpdateScheduler.plist"
REMOTE_PLIST="/Library/LaunchDaemons/com.airwatch.AWRemoteManagementDaemon.plist"
REMOTETUNNEL_PLIST="/Library/LaunchDaemons/com.airwatch.AWRemoteTunnelAgent.plist"

WriteLog ()
{
	# /bin/echo `date`" "$1 >> $LOG
	/bin/echo `date`" "$1
}

val=$(/usr/libexec/PlistBuddy -c "Print ProgramArguments:0" "${AGENT_PLIST}")
if [[ $val == *"VMware AirWatch Agent"* ]]; then
    WriteLog "VMware Agent needs to be Unloaded"
    LOCAL_USER=`ps -ajx | grep "/Applications/VMware AirWatch Agent.app/Contents/MacOS/VMware AirWatch Agent" | grep -v grep | awk '{ print $1 }'`
else
    WriteLog "AirWatch Agent needs to be Unloaded"
    LOCAL_USER=`ps -ajx | grep "/Applications/AirWatch Agent.app/Contents/MacOS/AirWatch Agent" | grep -v grep | awk '{ print $1 }'`
fi

WriteLog "Local user is $LOCAL_USER"

WriteLog "Modifying launchd plists"
/usr/libexec/PlistBuddy -c "Delete :KeepAlive" $DAEMON_PLIST
/usr/libexec/PlistBuddy -c "Delete :KeepAlive" $AGENT_PLIST
/usr/libexec/PlistBuddy -c "Delete :KeepAlive" $AWCM_PLIST
/usr/libexec/PlistBuddy -c "Delete :KeepAlive" $SCHEDULER_PLIST
/usr/libexec/PlistBuddy -c "Delete :KeepAlive" $REMOTE_PLIST
/usr/libexec/PlistBuddy -c "Delete :KeepAlive" $REMOTETUNNEL_PLIST

WriteLog "Unloading the plists"

/bin/launchctl unload $DAEMON_PLIST
/bin/launchctl unload $AWCM_PLIST
/bin/launchctl unload $SCHEDULER_PLIST
/bin/launchctl unload $REMOTE_PLIST
/bin/launchctl unload $REMOTETUNNEL_PLIST

su - ${LOCAL_USER} "/bin/launchctl unload $AGENT_PLIST"

WriteLog "Removing plists"
/bin/rm $DAEMON_PLIST
/bin/rm $AGENT_PLIST
/bin/rm $AWCM_PLIST
/bin/rm $SCHEDULER_PLIST
/bin/rm $REMOTE_PLIST
/bin/rm $REMOTETUNNEL_PLIST

WriteLog "Removing AirWatch folder except recovery key file"
cd "/Library/Application Support/AirWatch"
rm -f airwatchd awcmd AWSoftwareUpdateScheduler AWRemoteManagementDaemon AWRemoteTunnelAgent

rm -rf "/Library/Application Support/AirWatch/FrameWorks"

rm -rf "/Library/Application Support/AirWatch/Installation"

shopt -s extglob
if [ -d "/Library/Application Support/AirWatch/Data" ]; then
    cd "/Library/Application Support/AirWatch/Data"
    rm -rf !(FDE.plist|settings|encKeys)
fi

WriteLog "Removing agent and helper binaries"
rm -rf "/Users/$LOCAL_USER/Applications/AirWatch Agent.app/"
rm -rf "/Applications/AirWatch Agent.app/"
rm -rf "/Applications/VMware AirWatch Agent.app/"

pidAWAgent=`pgrep -x "AirWatch Agent"`
pidVMAgent=`pgrep -x "VMware AirWatch Agent"`
WriteLog "AirWatch Agent PID is $pidAWAgent"
WriteLog "VMWare Agent PID is $pidVMAgent"

kill -9 $pidAWAgent
kill -9 $pidVMAgent

if [ -d "/Users" ]; then
    cd "/Users"
    for USERNAME in `ls`; do
        rm -rf "/Users/$USERNAME/Library/Preferences/com.airwatch.mac.agent.plist" || true
        rm -rf "/Users/$USERNAME/Library/Preferences/com.airwatch.mac.enroller.plist" || true
        rm -rf "/Users/$USERNAME/Library/Preferences/com.aiwatch.mac.enroller.plist" || true
    done
fi

# WriteLog "Script self-destructing now..."
# rm -- "$0"
