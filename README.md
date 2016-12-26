# MPFR (libmpfr-4.dll)

MPFR library built for Windows using msys2/mingw64

## Prebuilt packages

The current prebuilt packages can be downloaded from [dist/mpfr-3.1.5_gmp-6.1.2](https://github.com/emphasis87/libmpfr-msys2-mingw64/tree/master/dist/mpfr-3.1.5_gmp-6.1.2).

Note that **libgcc** is not shipped together with pacakges where **libgmp-10.dll** and **libmpfr-4.dll** have it as a runtime dependency. This is because I was so far unable to obtain sources from which were mingw32 and mingw64 toolchains built under msys2. For now you can perhaps use those available directly from the mingw64 project.

For x32 Windows there is **libgcc_s_dw2-1.dll** [here](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/6.2.0/threads-win32/dwarf/i686-6.2.0-release-win32-dwarf-rt_v5-rev1.7z/download).
<br>For x64 Windows there is **libgcc_s_seh-1.dll** [here](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/6.2.0/threads-win32/seh/x86_64-6.2.0-release-win32-seh-rt_v5-rev1.7z/download).


## How to build libmpfr-4.dll

0. Example build script

	If you already know what to do, here is an example [build/build.sh](https://github.com/emphasis87/libmpfr-msys2-mingw64/blob/master/build/build.sh) script. You can adapt it if you like.

1. **Install [MSYS2](http://msys2.github.io/)** and [mingw-w64](https://mingw-w64.org/doku.php).

	Follow their instruction manual, once you have setup pacman install required toolchains and other packages:

	```bash
	pacman -S base-devel
	pacman -S mingw-w64-i686-toolchain #for compiling x32 binaries
	pacman -S mingw-w64-x86_64-toolchain #for compiling x64 binaries
	pacman -S lzip #for extracting gmp
	```

2. **Download [GMP](https://gmplib.org/#DOWNLOAD) and [MPFR](http://www.mpfr.org/mpfr-current/#download) source code**

	Extract the source code folders, for example to `c:\libs`.
	<br>For extracting .lz file you can use `tar --lzip -xvf gmp-*.tar.lz`.

3. **Open the correct shell for the compilation**

	This is by default `MSYS2 64bit/MinGW 32-bit` or `MSYS2 64bit/MinGW 64-bit` in the Windows startup menu.
	<br>Check your gcc version by `gcc -v`. Note the compiler and the configuration flags there.

4. **Compile gmp and mpfr**

	The following example code uses /c/libs/x32 directory just as an example.

	```bash
	cd /c/libs/gmp-* #or whichever version
	
	./configure --enable-shared --disable-static --prefix=/c/libs/x32
	make clean #clean up, just to be sure
	make > build.log #you can check out the compilation process
	make check
	make install
	```

	```bash
	cd /c/libs/mpfr-*
	
	./configure --enable-shared --disable-static --enable-thread-safe 
		--with-gmp=/c/libs/x32 --prefix=/c/libs/x32
	make clean
	make > build.log
	make check
	make install
	```

	You can read more on what those configure flags do by `./configure --help` in respective folders.
	<br>For now it is enough to know that:

	* `--enable-shared` produces a shared .dll file

	* `--disable-static` disables compilation of a static library
	<br>This is especially important for gmp, which can not do both static and dynamic compilation at once.

	* `--prefix=<path>` is where the result is installed after the compilation
	<br>This is set by default to `--prefix=/mingw32` or `--prefix=/mingw64` based on the shell running.

	* `--with-gmp=<path>` is how you can specify your custom path to gmp, if you do not use the default one
	<br>I used this option because otherwise configure posted a warning about not matching version of gmp.h.

	Note if you have encountered error: `gmp.h isn't a DLL: use --enable-static --disable-shared`
	<br>during mpfr compilation, as I have, it is because mingw64 is not picking up any installed gmp dll.

  1. **Dynamic linking**

	The compiled libmpfr-4.dll is dependent on these **runtime** libraries:

	* **libgmp-10.dll**
	* **libgcc_s_dw2-1.dll** or **libgcc_s_seh-1.dll** (x32 or x64)
	* **libwinpthread-1.dll**
	
	The compiled libgmp-10.dll depends on **libgcc** only in x32 version.

	These dependencies have to be accessible at runtime, which can be done by either placing them:
	* in your application's directory
	* in the current working directory
	* in the system directories
	* in a directory specified by the PATH environment variable.

	You can and should check all the runtime dependencies by `ldd /c/libs/x32/bin/libmpfr-4.dll`
	<br>or by the [Dependency Walker](http://dependencywalker.com/) Windows tool.

	More information can be found here:
	<br>https://msdn.microsoft.com/en-us/library/7d83bc18.aspx
	<br>https://msdn.microsoft.com/en-us/library/windows/desktop/ms682586(v=vs.85).aspx

  2. **Static linking**

	If you wish to modify libmpfr-4.dll or libgmp-10.dll to link libgcc or libwinpthread statically,
	<br>you can use linking options `-static-libgcc` and `-Wl,Bstatic -lpthread` respectivelly.
	
	However, you can learn from [GMP Known Build Problems](https://gmplib.org/manual/Known-Build-Problems.html#Known-Build-Problems) page that libtool strips those options. To circumvent the problem they suggest appending them directly to the compiler variable. 
	
	```bash
	./configure CC="gcc -static-libgcc"
	```

	For MPFR build you can reuse a linking command from the build.log:

	```bash
	cd /c/libs/mpfr-*
	cmd=$(grep -o 'gcc -shared.*' build.log) #store the linking command
	cmd+=" -static-libgcc"
	cmd+=" -Wl,-Bstatic -lpthread" #for libwinpthread
	(cd src && $cmd) # execute cmd from src directory
	make install
	```

## License information

  * **[GNU Compiler Collection (GCC)](https://gcc.gnu.org/)**, which libgcc is a part of, is distributed under [GNU GPL 3+](https://gcc.gnu.org/onlinedocs/libstdc++/manual/license.html)
	<br>with GCC Runtime Library Exception. The runtime library exception is described in this [rationale](https://www.gnu.org/licenses/gcc-exception-3.1-faq.html).
	<br>As a result libraries linked statically to libgcc do not have any license restrictions,
	<br>provided they are elegible to the exception.

  * **[mingw-w64](http://mingw-w64.org/doku.php/start)** *GCC for Windows 64 & 32 bits* states that it license is disclosed along with its sources and is permissive.
  	<br>This information is well hidden on their webpage in the [support](https://mingw-w64.org/doku.php/support) section.
	<br>This also applies to **winpthread** library or libwinpthread-1.dll (not to confuse with POSIX Threads for Windows or _pthread-win32_).
	<br>In binary distributions of msys2/mingw64 targeting [x86](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/6.2.0/threads-win32/) and [x64](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/6.2.0/threads-win32/seh/) you can find under `mingw32` or `mingw64` a file `licenses/mingw-w64/COPYING` that states:
  
	> With exception of certain parts that are prominently marked as being
	> <br>in the Public Domain, BSD, or LGPL this Software is provided under the
	> <br>Zope Public License (ZPL) Version 2.1.
	
	Also of note should be `COPYING.MinGW-w64.txt` and `COPYING.MinGW-w64-runtime.txt` where the first also states:
	
	> The idea is that if you create binary packages of your software with MinGW-w64, you can simply copy
	> COPYING.MinGW-w64-runtime.txt into your package to fulfill the license requirements of the MinGW runtime.
	
	A separate license notice for **winpthread** is located in `licenses/winpthread/COPYING`.
	<br> It seems fairly permissive, though it requires you to copy the notice and mentions having a part of posix-win32:
	
	> Parts of this library are derived by:
	> <br>Posix Threads library for Microsoft Windows

  * **[The GNU Multiple Precision Arithmetic Library (GMP)](https://gmplib.org/)** uses dual licensing under [GNU LGPL v3](https://www.gnu.org/licenses/lgpl.html) and [GNU GPL v2](https://www.gnu.org/licenses/gpl-2.0.html).

  * **[The GNU MPFR Library](http://www.mpfr.org/)** is licensed under [GNU LGLP v3](https://www.gnu.org/copyleft/lesser.html).

	LGLPv3 and GPLv2 impose requirements on source code distribution alongside binary distributions. The safest option is to simply distribute the source code with the provided binary distribution, because any other option usually results in long-term obligations.
	
	Note that mingw64 distribution also contains `licenses/gmp` and `licenses/mpfr`, because mingw64 ships with some version of GMP and MPFR. This shows what license notices must be provided in such case.

	You can read it all for yourself (though check your sanity first).
