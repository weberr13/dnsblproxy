#!/bin/sh
#
# Dnsblproxy "install" script.  All this does is correct varrous paramiters
# within the scripts when called with the "build" arg, then when called
# with the "install" arg it puts everything in place.
#
# milter and mc files are configured with the build process, but you will
# need to read the README files on how to use them
#
usage()
{
	echo "usage $0 build|install|clean [--prefix=dir] [--contact=user@host] [--zone=dnsblzone] [--perl=path_to_perl] [--syslogfile=path_to_logfile]"
}

if [ $# -lt 1 ] ; then
	usage
	exit 1
fi

if [ $1 = "build" ] ; then
	build=1
	install=0
	clean=0
	shift
elif [ $1 = "install" ] ; then
	build=0
	install=1
	clean=0
	shift
elif [ $1 = "clean" ] ; then
	build=0
	install=0
	clean=1
	shift
else
	usage
	exit 1
fi

prefix=/usr/local/dnsblproxy
syslogfile=/var/log/syslog
hostname=`hostname`
domain=`grep $hostname /etc/hosts | awk '{print $2}' | sed -e 's/'$hostname'\.//g' | grep "\."`
dnsblzone=bl.$domain
contact=abuse@$domain
contactprime=abuse\\@$domain
perl=/usr/bin/perl
while [ $# -gt 0 ] ; do
	case $1 in 
		--prefix=*)	
		prefix=`echo $1 | sed -e 's/--prefix=//g'`
		shift
		;;
		--contact=*)	
		contact=`echo $1 | sed -e 's/--contact=//g'`
		contactprime=`echo $contact | awk -F@ '{print $1"\@"$2}'`
		shift
		;;
		--zone=*)	
		dnsblzone=`echo $1 | sed -e 's/--zone=//g'`
		shift
		;;
		--domain=*)	
		domain=`echo $1 | sed -e 's/--domain=//g'`
		shift
		;;
		--perl=*)	
		perl=`echo $1 | sed -e 's/--perl=//g'`
		shift
		;;
		--syslogfile=*)	
		syslogfile=`echo $1 | sed -e 's/--syslogfile=//g'`
		shift
		;;
		*)
		usage
		exit 1
		;;
	esac
done
if [ z"$domain" = "z" -a $build -eq 1 ] ; then
	echo "I can't figure out your domain, please specify"
	exit 1
fi	
if [ z"$dnsblzone" = "zbl." -a $build -eq 1 ] ; then
	dnsblzone=bl.$domain	
fi	
if [ z"$contact" = "zabuse@" -a $build -eq 1 ] ; then
	contact=abuse@$domain
	contactprime=abuse\\@$domain
fi	

basedir=`pwd`
if [ $build -eq 1 ] ; then
 for i in bin sendmail milter test ; do 
	cd $basedir/$i
	for j in `/bin/ls *.in` ; do 
		file=`echo $j | sed -e 's/.in$//g'`
		sed -e 's/DNSBL_DOMAIN_NAME/'$dnsblzone'/g' -e 's/CONTACT_ADDRESS_HERE/'$contact'/g' -e 's,PERL_PATH,'$perl',g' -e 's,INSTALL_PREFIX,'$prefix',g' -e 's,SYSLOG_MAILLOG,'$syslogfile',g' $j > $file
	done
 done
 $perl $basedir/test/testperl 
 if [ $? -ne 0 ] ; then
	echo "your perl doesn't have DB_FILE, DB_FILE::Lock or Fcntl installed"
	echo "build failed"
	exit 1
 fi
 cd $basedir
 echo $prefix > installok
fi

if [ $install -eq 1 ] ; then
 if [ ! -f installok ] ; then
	echo you must build first
	exit 1
 fi
 prefix=`cat installok`
 if [ ! -d $prefix ] ; then
	mkdir $prefix
 fi
 for i in bin lib man ; do
  if [ ! -d $prefix/$i ] ; then
	mkdir $prefix/$i
  fi
 done
 for i in bin ; do
  cd $basedir/$i
  for j in `/bin/ls | grep -v '\.in$'` ; do
   cp $j $prefix/bin
  done
 done
fi

if [ $clean -eq 1 ] ; then
 if [ ! -f installok ] ; then
	echo you must build first
	exit 1
 fi
 for i in bin sendmail milter ; do 
	cd $basedir/$i
	for j in `/bin/ls | grep -v '.in$'` ; do 
		rm $j
	done
 done
 rm $basedir/installok
 
fi
