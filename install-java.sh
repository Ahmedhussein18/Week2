#!/bin/bash

JAVA="17"
JAVA_VERSION="jdk-17.0.12"
JAVA_TAR_NAME="jdk-17.0.12_linux-x64_bin.tar.gz"
URL="https://download.oracle.com/java/${JAVA}/archive/${JAVA_TAR_NAME}"
DIR="${HOME}/java"
TOMCAT_DIR="${HOME}/tomcat"
TOMCAT_VERSION="10.1.41"
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
TOMCAT_TAR_NAME="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
install_java(){
   if [ ! -d "${DIR}" ]; then
      echo "Creating java directory"
      mkdir -p "${DIR}"

   else
      echo "Java directory already exists"
   fi
   cd "${DIR}"
 if [ ! -d ${JAVA_VERSION} ]; then
   if [ ! -f ${JAVA_TAR_NAME} ]; then
      echo "file not found, downloading java"   
      wget ${URL}
      echo "Extracting Java......"
      tar -xzf ${JAVA_TAR_NAME}
   else
      echo "file already exists"
      tar -xzf ${JAVA_TAR_NAME}
   fi

 fi
 
 if ! grep -q "JAVA_HOME" ~/.bashrc; then
	 echo "Configuring env"
	 echo "export JAVA_HOME=$DIR/${JAVA_VERSION}" >> ~/.bashrc
	 echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
 else
	 echo "Environment already configured"
 fi
}

install_tomcat(){

if [ ! -d "${TOMCAT_DIR}" ]; then
      echo "Creating tomcat directory"
      mkdir -p "${TOMCAT_DIR}"

   else
      echo "Tomcat directory already exists"
   fi
   cd "${TOMCAT_DIR}"
 if [ ! -d ${TOMCAT_VERSION} ]; then
   if [ ! -f ${TOMCAT_TAR_NAME} ]; then
      echo "file not found, downloading tomcat"   
      wget ${TOMCAT_URL}
      echo "Extracting tomcat......"
      tar -xzf ${TOMCAT_TAR_NAME}
   else
      echo "file already exists"
      tar -xzf ${TOMCAT_TAR_NAME}
   fi

 fi

 chmod +x ${TOMCAT_DIR}/apache-tomcat-${TOMCAT_VERSION}/bin/*.sh

}

install_java
install_tomcat
