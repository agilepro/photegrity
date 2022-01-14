cd d:\GitHub\photegrity
call build.bat
echo "==============================="
cd d:\GitHub\photegrity\kubernetes


copy d:\GitHub\photegrity\photoWar\build\libs\photo.war d:\GitHub\photegrity\kubernetes\build\
copy d:\GitHub\web-util\WebUtilWar\build\libs\WebUtilWar.war d:\GitHub\photegrity\kubernetes\build\

cd d:\GitHub\photegrity\kubernetes
docker build -t first-try .

docker run -p 8088:8080 -v //h/z/.y/:/opt/ImageData first-try
