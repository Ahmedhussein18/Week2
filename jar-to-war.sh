#!/bin/bash

set -e
POM_FILE="/var/lib/jenkins/workspace/Pet-clinic-cid-cd/pom.xml"
APP_FILE="/var/lib/jenkins/workspace/Pet-clinic-cid-cd/src/main/java/org/springframework/samples/petclinic/PetClinicApplication.java"

if ! grep -q "<packaging>war</packaging>" "$POM_FILE"; then
    sed -i '/<modelVersion>/a \  <packaging>war</packaging>' "$POM_FILE"
    echo "[INFO] <packaging>war</packaging> inserted."
else
    echo "[INFO] pom.xml already has <packaging>war</packaging>."
fi


echo "[INFO] Adding required Spring Boot WAR dependencies..."
if ! grep -q "spring-boot-starter-tomcat" "$POM_FILE"; then
    awk '
    /<!-- Spring and Spring Boot dependencies -->/ {
        print;
        print "        <dependency>";
        print "            <groupId>org.springframework.boot</groupId>";
        print "            <artifactId>spring-boot-starter-web</artifactId>";
        print "        </dependency>";
        print "";
        print "        <dependency>";
        print "            <groupId>org.springframework.boot</groupId>";
        print "            <artifactId>spring-boot-starter-tomcat</artifactId>";
        print "            <scope>provided</scope>";
        print "        </dependency>";
        next
    }
    { print }
    ' "$POM_FILE" > "${POM_FILE}.tmp" && mv "${POM_FILE}.tmp" "$POM_FILE"
    echo "[INFO] Dependencies added to pom.xml."
else
    echo "[INFO] Dependencies already present in pom.xml."
fi

echo "[3/3] Updating main application class..."
APP_FILE="src/main/java/org/springframework/samples/petclinic/PetClinicApplication.java"

if ! grep -q "SpringBootServletInitializer" "$APP_FILE"; then
  sed -i '/import org.springframework.boot.SpringApplication;/a\
import org.springframework.boot.builder.SpringApplicationBuilder;\
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;' "$APP_FILE"

  sed -i 's/public class PetClinicApplication {/public class PetClinicApplication extends SpringBootServletInitializer {\
\
    @Override\
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {\
        return builder.sources(PetClinicApplication.class);\
    }/' "$APP_FILE"
fi

echo "✅ Conversion complete. You can now run './mvnw clean package' to generate the WAR."

./mvnw spring-javaformat:apply
./mvnw clean package
