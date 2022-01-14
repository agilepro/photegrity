FROM  tomcat:9-jdk8-corretto

MAINTAINER Keith

COPY ./build/photo.war /usr/local/tomcat/webapps/
COPY ./build/WebUtilWar.war /usr/local/tomcat/webapps/

CMD ["catalina.sh","run"]