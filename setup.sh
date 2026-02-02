#!/bin/bash

RD=${PWD}
git clone https://github.com/AcrylicMadness/SwiftGodot-Integrator
cd SwiftGodot-Integrator
swift build --configuration release
BIN_PATH="$(swift build --configuration release --show-bin-path)"
echo ${PWD}
echo $RD
cp $BIN_PATH/sgint $RD/sgint
cd $RD
rm -rf "SwiftGodot-Integrator"
