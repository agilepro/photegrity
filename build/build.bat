:### setup
call build_configuration.bat

echo JAVA_HOME is %JAVA_HOME%
echo SERVLET_API_CP is %SERVLET_API_CP%
echo SOURCE_DIR is %SOURCE_DIR%
echo TARGET_DIR is %TARGET_DIR%
echo TARGET_DIR_DRIVE is %TARGET_DIR_DRIVE%

:### delete any build previously created in TARGET_DIR & recreate folder structure
del /s /q %TARGET_DIR%\photo.war
rmdir /s /q %TARGET_DIR%\photo_war
mkdir %TARGET_DIR%\photo_war\WEB-INF\classes
mkdir %TARGET_DIR%\photo_war\WEB-INF\lib

:### copy webapp
XCOPY /sy %SOURCE_DIR%\jsp %TARGET_DIR%\photo_war

COPY %SOURCE_DIR%\thirdparty\js.jar %TARGET_DIR%\photo_war\WEB-INF\lib
COPY %SOURCE_DIR%\thirdparty\purple.jar %TARGET_DIR%\photo_war\WEB-INF\lib
COPY %SOURCE_DIR%\thirdparty\imgscalr-lib-4.2.jar %TARGET_DIR%\photo_war\WEB-INF\lib

:### setup classpath

set PHOTO_CP=%SERVLET_API_LOC%servlet-api.jar;%SERVLET_API_LOC%jsp-api.jar;%TARGET_DIR%\photo_war\WEB-INF\lib\purple.jar;%TARGET_DIR%\photo_war\WEB-INF\lib\imgscalr-lib-4.2.jar

set NETCLASSES=%SOURCE_DIR%\src\org\apache\commons\net\bsd\*.java %SOURCE_DIR%\src\org\apache\commons\net\chargen\*.java %SOURCE_DIR%\src\org\apache\commons\net\daytime\*.java %SOURCE_DIR%\src\org\apache\commons\net\discard\*.java %SOURCE_DIR%\src\org\apache\commons\net\echo\*.java %SOURCE_DIR%\src\org\apache\commons\net\finger\*.java %SOURCE_DIR%\src\org\apache\commons\net\ftp\*.java %SOURCE_DIR%\src\org\apache\commons\net\imap\*.java %SOURCE_DIR%\src\org\apache\commons\net\io\*.java %SOURCE_DIR%\src\org\apache\commons\net\nntp\*.java %SOURCE_DIR%\src\org\apache\commons\net\ntp\*.java %SOURCE_DIR%\src\org\apache\commons\net\pop3\*.java %SOURCE_DIR%\src\org\apache\commons\net\smtp\*.java %SOURCE_DIR%\src\org\apache\commons\net\telnet\*.java %SOURCE_DIR%\src\org\apache\commons\net\tftp\*.java %SOURCE_DIR%\src\org\apache\commons\net\time\*.java %SOURCE_DIR%\src\org\apache\commons\net\util\*.java %SOURCE_DIR%\src\org\apache\commons\net\whois\*.java %SOURCE_DIR%\src\org\apache\commons\net\*.java %SOURCE_DIR%\src\org\apache\commons\net\ftp\parser\*.java

:### compile java classes
"%JAVA_HOME%/bin/javac" -classpath "%PHOTO_CP%" -d "%TARGET_DIR%\photo_war\WEB-INF\classes" -target 1.6 -source 1.6 %SOURCE_DIR%\src\bogus\*.java %SOURCE_DIR%\src\bandaid\*.java %NETCLASSES%



if errorlevel 1 goto END

echo Compile successful

:### build nugen.war
%TARGET_DIR_DRIVE%
pushd %TARGET_DIR%\photo_war
del %TARGET_DIR%\photo.war
"%JAVA_HOME%/bin/jar" -cvfM %TARGET_DIR%\photo.war *
if errorlevel 1 goto END

echo photo.war created successfully at %TARGET_DIR%

:END
:### restore starting directory
popd
pause
