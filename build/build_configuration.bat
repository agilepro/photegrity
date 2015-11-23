:#####################################################################################################
:#
:# Java home
:#
:#####################################################################################################
set "JAVA_HOME=c:\Program Files\Java\jdk1.6.0_26\"

:#####################################################################################################
:#
:# Path to nugen source directory.
:#
:#####################################################################################################
set SOURCE_DIR=g:\GoogleSvn\PhotoBrowser

:#####################################################################################################
:#
:# Path to build directory. nugen.war will be created here.
:# TARGET_DIR_DRIVE should have the drive letter of TARGET_DIR - a kludge till we have a smarter script
:#
:#####################################################################################################
set TARGET_DIR=g:\GoogleBuild\PhotoBrowser\
set TARGET_DIR_DRIVE=g:

:#####################################################################################################
:#
:# Path to jar file containing javax.servlet.* classes
:#
:# e.g.: 
:# For Tomcat 4.1
:# set SERVLET_API_CP="D:\Program Files\Apache Software Foundation\Tomcat 4.1\common\lib\servlet.jar"
:#
:# For Tomcat 5.5
:# set SERVLET_API_CP="D:\Program Files\Apache_Tomcat_5_5\common\lib\servlet-api.jar"
:#
:#####################################################################################################
set SERVLET_API_LOC=c:\ApacheTomcat6\lib\

