# sensing-dev-installer

Components:
* ion-kit
* Aravis
* WinUSB installer
* OpenCV

## How to build

```
cd installer
mkdir build
cd build
cmake -G "Visual Studio 16 2019" -A x64 ../
cmake --build . --config=Release
cpack -G "WIX"
```
