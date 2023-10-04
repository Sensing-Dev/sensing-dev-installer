import os

from conan import ConanFile
from conan.tools.build import check_min_cppstd
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.files import copy, get

required_conan_version = ">=2.0.0"


class SensingDevInstallerConan(ConanFile): 
    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
    }
    default_options = {
        "shared": False,
        "fPIC": True,
    }
    dependencies_folder = "dependencies"

    generators = "PkgConfigDeps","VirtualBuildEnv", "VirtualRunEnv","AutotoolsDeps"

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC

    def configure(self):
        if self.options.shared:
            self.options.rm_safe("fPIC")
        self.options["glib*"].shared=True
        self.settings.rm_safe("compiler.libcxx")
        self.settings.rm_safe("compiler.cppstd")

    def layout(self):
        cmake_layout(self, src_folder="src")

    def validate(self):
        if self.settings.compiler.get_safe("cppstd"):
            check_min_cppstd(self, 17)

    def source(self):
        # get(self, **self.conan_data["sources"][self.version], strip_root=True)
        pass

    def build_requirements(self):
        self.tool_requires("meson/1.0.0")  
        self.tool_requires("winflexbison/2.5.24")  
        self.tool_requires("m4/1.4.19")  
        self.tool_requires("pkgconf/1.9.3")

    def requirements(self):
        self.requires("aravis/0.8.25")
        # self.requires("glib/2.76.3")
        # self.requires("libxml2/2.11.4")
        # self.requires("gstreamer/1.22.3")
        # self.requires("zlib/1.2.13")
        # self.requires("libusb/1.0.26")
        # self.requires("libffi/3.4.4")  
        # self.requires("libiconv/1.17")  
        #self.requires("libgettext/0.21")  

    def generate(self):
        self.import_dependencies()

    def build(self):
        self.import_dependencies()

    def package(self):
        copy(self, "LICENSE.md",
             dst=os.path.join(self.package_folder, "licenses"), src=self.source_folder)
        copy(self, "*.h",
             dst=os.path.join(self.package_folder, "include"),
             src=os.path.join(self.source_folder, "include"))
        for pattern in ["*.a", "*.so*", "*.dylib", "*.lib"]:
            copy(self, pattern,
                 dst=os.path.join(self.package_folder, "lib"),
                 src=self.build_folder,
                 keep_path=False)
        for pattern in ["*.exe", "*.dll"]:
            copy(self, pattern,
             dst=os.path.join(self.package_folder, "bin"),
             src=self.build_folder,
             keep_path=False)

    def import_dependencies(self):
        dependency_folder = os.path.join(self.build_folder, self.dependencies_folder )       
        self.output.warning(f"dependency_folder: {dependency_folder}")

        self.buildenv.append_path(name="PKG_CONFIG_PATH", value=dependency_folder)
        self.runenv.append_path(name="PKG_CONFIG_PATH", value=dependency_folder)

        # dependency_folder = self.sensing_dev_install_dir
        # self.output.info(f"Value of SENSING_DEV_INSTALL: {self.sensing_dev_install_dir}")
        try:
            if dependency_folder is not None:
                self.output.info(f"Value of dependency_folder: {dependency_folder}")
                if not os.path.exists(dependency_folder):
                    os.makedirs(dependency_folder)
            else:
                self.output.error("dependency_folder is not set.")    

            include_install_dir = os.path.join(dependency_folder,"include")
            lib_install_dir = os.path.join(dependency_folder,"lib")
            bin_install_dir = os.path.join(dependency_folder,"bin")       

            for d in self.dependencies.values():
                self.output.info(f"Copying Dependency : {d}")
                info = d.cpp_info

                # Copy dependency bin
                # bin, *.dll -> ./dependencies/bin
                # bin, *.exe -> ./dependencies/bin
                for lib in info.bindirs:
                    copy(self, pattern="*.dll",src=lib, dst=bin_install_dir) 
                    copy(self, pattern="*.exe",src=lib, dst=bin_install_dir) 

                # Copy dependency libs
                # lib, *.lib -> ./dependencies/lib
                # lib, *.h -> ./dependencies/include 
                for lib in info.libdirs:
                    copy(self, pattern="*.lib",src=lib, dst=lib_install_dir)
                    copy(self, pattern="*.h",src=lib, dst=include_install_dir)

                # Copy dependency include
                # include, *.h -> ./dependencies/include               
                for dir in info.includedirs:
                    self.output.warning(f"includedirs ; {info.includedirs}")
                    copy(self, pattern="*.h",src=dir, dst=include_install_dir)                
        except Exception as e:
                self.output.error(f"An error occurred: {e}")
                
