#!/bin/bash

if [ "$RDS_HOSTNAME" ]; then
	PGHOST="$RDS_HOSTNAME"
	PGUSER="$RDS_USERNAME"
	PGPASSWORD="$RDS_PASSWORD"
	PGDATABASE="$RDS_DB_NAME"
	PGPORT="$RDS_PORT"
fi

if [ "$PGHOST" ]; then
	if [ ! "$PGPORT" ]; then
	        PGPORT=5432
	fi
	if [ ! "$PGDATABASE" ]; then
	        PGDATABASE=postgres
	fi
	if [ ! "$PGUSER" ]; then
	        PGUSER=pgadmin
	fi
	if [ ! "$PGPASSWORD" ]; then
	        PGPASSWORD=pgadmin.
	        
	fi
	export PGPASSWORD="$PGPASSWORD"
	echo "Checking PostgreSQL connection ..."

	nc -zv $PGHOST $PGPORT
	
	if [ "$?" -ne "0" ]; then
		echo "PostgreSQL connection failed."
		exit 0
	fi

	CHK_QUARTZ=`echo "$(psql -U $PGUSER  -h $PGHOST -d $PGDATABASE -l | grep quartz | wc -l)"`
	CHK_HIBERNATE=`echo "$(psql -U $PGUSER  -h $PGHOST -d $PGDATABASE -l | grep hibernate | wc -l)"`
	CHK_JCR=`echo "$(psql -U $PGUSER  -h $PGHOST -d $PGDATABASE -l | grep jackrabbit | wc -l)"`

	echo "quartz: $CHK_QUARTZ"
	echo "hibernate: $CHK_HIBERNATE"
	echo "jcr: $CHK_JCR"
	
	if [ "$CHK_JCR" -eq "0" ]; then
	 psql -U $PGUSER  -h $PGHOST -d $PGDATABASE -f $PENTAHO_SERVER/data/postgresql/create_jcr_postgresql.sql
	fi
	if [ "$CHK_HIBERNATE" -eq "0" ]; then
	 psql -U $PGUSER -h $PGHOST -d $PGDATABASE -f $PENTAHO_SERVER/data/postgresql/create_repository_postgresql.sql
	fi
	if [ "$CHK_QUARTZ" -eq "0" ]; then
	 psql -U $PGUSER -h $PGHOST -d $PGDATABASE -f $PENTAHO_SERVER/data/postgresql/create_quartz_postgresql.sql

	 # Insert dummy table to fix "RUNSCRIPT" issue.
	 # http://forums.pentaho.com/showthread.php?153231-Pentaho-ce-5-Initialization-Exception
	 psql -U $PGUSER -h $PGHOST -d quartz -c 'CREATE TABLE "QRTZ" ( NAME VARCHAR(200) NOT NULL, PRIMARY KEY (NAME) );'
	fi

	# Use postgresql for hibernate
	if grep -q postgresql $PENTAHO_SERVER/pentaho-solutions/system/hibernate/hibernate-settings.xml; then
	 sed -i s/hsql/postgresql/g $PENTAHO_SERVER/pentaho-solutions/system/hibernate/hibernate-settings.xml
    
	 sed -i s/localhost:5432/$PGHOST:$PGPORT/g $PENTAHO_SERVER/pentaho-solutions/system/hibernate/postgresql.hibernate.cfg.xml
    
	 cp $PENTAHO_HOME/config/jdbc.properties $PENTAHO_SERVER/pentaho-solutions/system/simple-jndi/jdbc.properties
	 sed -i "s|postgresql://localhost:5432|postgresql://$PGHOST:$PGPORT|g" $PENTAHO_SERVER/pentaho-solutions/system/simple-jndi/jdbc.properties
	fi

	# Use postgreql for jackrabbit
	#if grep -q postgresql://localhost:5432 $PENTAHO_SERVER/pentaho-solutions/system/jackrabbit/repository.xml; then
	# cp $PENTAHO_HOME/config/repository.xml $PENTAHO_SERVER/pentaho-solutions/system/jackrabbit/repository.xml
	# sed -i "s|postgresql://localhost:5432|postgresql://$PGHOST:$PGPORT|g" $PENTAHO_SERVER/pentaho-solutions/system/jackrabbit/repository.xml
	#fi
	
	# Use postgresql for tomcat (quartz / hibernate)
	if grep -q hsqldb $PENTAHO_SERVER/tomcat/webapps/pentaho/META-INF/context.xml; then
	 cp $PENTAHO_HOME/config/context.xml $PENTAHO_SERVER/tomcat/webapps/pentaho/META-INF/context.xml
	 sed -i "s|jdbc:postgresql://localhost:5432/|jdbc:postgresql://$PGHOST:$PGPORT/|g" $PENTAHO_SERVER/tomcat/webapps/pentaho/META-INF/context.xml
	fi
fi
