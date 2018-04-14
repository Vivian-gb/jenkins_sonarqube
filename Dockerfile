# Ubuntu 16.04 LTS
# OpenJDK 8
# Maven 3.2.2
# Jenkins latest
# Git
# Nano

# pull base image Ubuntu 16.04 LTS (Xenial)
FROM ubuntu:xenial

LABEL maintainer="vivian.gbarbosa@gmail.com"
#####MAINTAINER Stephen L. Reed (stephenreed@yahoo.com)

# this is a non-interactive automated build - avoid some warning messages
#ENV DEBIAN_FRONTEND noninteractive

# install the OpenJDK 8 java runtime environment and curl
RUN apt update; \
  apt upgrade -y; \
  apt install -y curl wget git nano unzip; \
  apt-get clean; \
  apt-get install -y openjdk-8-jdk
  
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $JAVA_HOME/bin:$PATH

RUN echo $JAVA_HOME \
  ls /usr/lib/jvm/java-8-openjdk-amd64 \
  java -version

# get maven 3.2.2 and verify its checksum
RUN wget --no-verbose -O /tmp/apache-maven-3.2.2.tar.gz http://archive.apache.org/dist/maven/maven-3/3.2.2/binaries/apache-maven-3.2.2-bin.tar.gz; \
  echo "87e5cc81bc4ab9b83986b3e77e6b3095 /tmp/apache-maven-3.2.2.tar.gz" | md5sum -c

# install maven
RUN tar xzf /tmp/apache-maven-3.2.2.tar.gz -C /opt/; \
  ln -s /opt/apache-maven-3.2.2 /opt/maven; \
  ln -s /opt/maven/bin/mvn /usr/local/bin; \
  rm -f /tmp/apache-maven-3.2.2.tar.gz
ENV MAVEN_HOME /opt/maven

RUN mvn --version

# copy jenkins war file to the container
ADD http://mirrors.jenkins.io/war-stable/2.107.1/jenkins.war /opt/jenkins.war
RUN chmod 644 /opt/jenkins.war
ENV JENKINS_HOME /jenkins

#https://www.vultr.com/docs/how-to-install-sonarqube-on-ubuntu-16-04
#SonarQube
ADD https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.4.zip /tmp/sonarqube-6.4.zip

RUN unzip /tmp/sonarqube-6.4.zip -d /opt

RUN mv /opt/sonarqube-6.4 /opt/sonarqube

#configure database connection
#sudo nano /opt/sonarqube/conf/sonar.properties
#Find the following lines.
#sonar.jdbc.username=
#sonar.jdbc.password=
#Uncomment and provide the PostgreSQL username and password of the database that we have created earlier. It should look like:
#sonar.jdbc.username=sonar
#sonar.jdbc.password=StrongPassword
#sonar.jdbc.url=jdbc:postgresql://localhost/sonar

#Step 5: Configure Systemd service
#SonarQube can be started directly using the startup script provided in the installer package. As a matter of convenience, you should setup a #Systemd unit file for SonarQube.

COPY config/sonar.service /etc/systemd/system/sonar.service

RUN chmod a+xr /etc/systemd/system/sonar.service

RUN systemctl enable sonar

RUN apt-get update && apt-get install -y \
    python3 python3-pip libgconf-2-4

RUN pip3 install pytest selenium

ENV CHROMEDRIVER_VERSION 2.36
ENV CHROMEDRIVER_SHA256 2461384f541346bb882c997886f8976edc5a2e7559247c8642f599acd74c21d4

RUN curl -SLO "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip" \
  && echo "$CHROMEDRIVER_SHA256  chromedriver_linux64.zip" | sha256sum -c - \
  && unzip "chromedriver_linux64.zip" -d /usr/local/bin \
  && rm "chromedriver_linux64.zip"

#https://gist.github.com/julionc/7476620
#PhantomJS to use with SeleniumWebDriver
#RUN apt-get install build-essential chrpath libssl-dev libxft-dev; \
#    apt-get install -y phantomjs

#Install these packages needed by PhantomJS to work correctly.
#RUN apt-get install -y libfreetype6 libfreetype6-dev \
#    libfontconfig1 libfontconfig1-dev

#ENV PHANTOM_JS="usr/local/share/phantomjs"
#RUN ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin \
#    phantomjs --version

#ENV PHANTOM_JS="phantomjs-1.9.8-linux-x86_64"
#ADD https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2 /tmp/$PHANTOM_JS.tar.bz2
#RUN tar xvjf $PHANTOM_JS.tar.bz2 \
#    mv $PHANTOM_JS /usr/local/share \
#    ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin \
#    phantomjs --version

VOLUME ["/jenkins", "/opt/sonarqube/data"]
# configure the container to run jenkins, mapping container port 8180 to that host port
EXPOSE 8080 50000 9000

RUN /opt/sonarqube/bin/linux-x86-64/sonar.sh start
ENTRYPOINT ["java", "-jar", "/opt/jenkins.war"]

CMD [""]


