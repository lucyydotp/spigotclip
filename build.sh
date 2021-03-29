#!/bin/bash

# Copyright © __lucyy 2021. All rights reserved.
#
# This file is part of Spigotclip.
#
# Spigotclip is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spigotclip is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# yes, this is very, _very_ messy, but it works

function title() {
	echo -e "\n---------------------------------------------"
	echo $1
	echo -e "---------------------------------------------\n "
}

title "SpigotClip Build Script by __lucyy"
echo -e "Not affiliated or related to SpigotMC, PaperMC or Mojang!"

title "Downloading BuildTools"
mkdir -p buildtools && cd buildtools
wget -O buildtools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar

title "Building Spigot"

java -jar buildtools.jar --compile-if-changed

stat -t spigot*.jar >/dev/null 2>&1

if [ $? -ne 0 ]; then
	title "BuildTools did not build a jar, either there are no changes or the build failed, exiting"
	exit
fi


SPIGOT_JAR=$(ls spigot*.jar)
cd Spigot
SPIGOT_COMMIT=$(git rev-parse --short HEAD)
cd ..
echo $SPIGOT_JAR 
VERSION=$(echo $SPIGOT_JAR | grep -oP '(([0-9]*\.)+[0-9]+)')

title "Jarfile $SPIGOT_JAR built"
title "Downloading Paperclip"

cd ..
rm -rf paperclip
git clone https://github.com/papermc/paperclip.git
cd paperclip

cp ../buildtools/$SPIGOT_JAR assembly/spigot.jar
cp ../buildtools/work/minecraft_server.$VERSION.jar assembly/vanilla.jar

title "Building paperclipped jar"

cd assembly

# append jar information to the assembly pom
CONTENT=$(echo "<mcver>$VERSION</mcver>\n<vanillajar>vanilla.jar</vanillajar>\n<paperjar>spigot.jar</paperjar>" | sed 's/\//\\\//g')
mv pom.xml pom.xml.old
sed "/<\/properties>/ s/.*/${CONTENT}\n&/" pom.xml.old > pom.xml
rm pom.xml.old

cd ..
mvn clean package

title "Copying jars and tidying up"
cd ..
mkdir -p out
mv paperclip/assembly/target/paperclip-$VERSION.jar out/spigotclip-$VERSION-$SPIGOT_COMMIT.jar && rm buildtools/$SPIGOT_JAR

title "out/spigotclip-$VERSION-$SPIGOT_COMMIT.jar saved"
