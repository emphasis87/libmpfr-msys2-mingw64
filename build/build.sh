#!/bin/bash

vgmp="6.1.2"
vmpfr="3.1.5"

sgmp="gmp-$vgmp"
smpfr="mpfr-$vmpfr"
vlibs="${smpfr}_${sgmp}"

pgmp="$sgmp.tar.lz"
pmpfr="$smpfr.tar.xz"

cc=$(gcc -v 2>&1 | grep -o -E "i686|x86" -m 1)

if [ "$cc" == "i686" ]; then 
	arch="x32"
elif [ "$cc" == "x86_64" ]; then 
	arch="x64"
fi

function make_all {

	set -o xtrace
	
	make_setup "$@"
	make_build
	make_dist
	
	set +o xtrace
}

function make_setup {

	mkdir -p /c/libs/src
	cd /c/libs/src

	if [ ! -f $pgmp ]; then wget "https://gmplib.org/download/gmp/$pgmp"; fi
	if [ ! -f $pmpfr ]; then wget "http://www.mpfr.org/mpfr-current/$pmpfr"; fi

	set +o xtrace

	arch=${1:-"x32"}
	static_libgcc=${2:-false}
	static_libwinpthread=${3:-false}

	name="runtime"
	if [ "$static_libgcc" = false ]; then name+="_libgcc"; fi
	if [ "$static_libwinpthread" = false ] && [ "$arch" == "x64" ]; then name+="_libwinpthread"; fi
	if [ "$name" == "runtime" ]; then name="standalone"; fi
		
	fi

	src="/c/libs/src/${arch}_$name"
	out="/c/libs/out/${arch}_$name"
	dist="/c/libs/dist/$vlibs/${arch}_${vlibs}_$name"
	log="/c/logs/${arch}_${vlibs}_$name"

	rm -rf "$src"
	mkdir -p "$src" "$log"

	cd /c/libs/src

	tar --lzip -xf $pgmp -C $src
	tar -xJf $pmpfr -C $src

	set -o xtrace
}

function make_build {

	rm -rf "$out/"

	make_build_gmp
	make_build_mpfr
}

function make_build_gmp {

	set +o xtrace

	cc="gcc"
	if [ "$static_libgcc" = true ]; then cc+=" -static-libgcc"; fi

	set -o xtrace

  cd "$src/$sgmp"
  ./configure CC="$cc" --enable-shared --disable-static --prefix="$out" > "$log/$configure.log" \
		&& make clean > /dev/null \
		&& make > "$log/build.log" \
		&& : make check > "$log/check.log" \
		&& make install > "$log/install.log"

  set +o xtrace
}

function make_build_mpfr {

  set -o xtrace

  cd "$src/$smpfr"
	./configure --enable-shared --disable-static --enable-thread-safe --prefix="$out" --with-gmp="$out" > "$log/configure.log" \
		&& make clean > /dev/null \
		&& make > "$log/build.log" \
		&& {
			set +o xtrace

			if [ "$static_libgcc" = true ] || [ "$static_libwinpthread" = true ]; then
				cmd=$(grep -o 'gcc -shared.*' build.log)
				if [ "$static_libgcc" = true ]; then cmd+=" -static-libgcc"; fi
				if [ "$static_libwinpthread" = true ]; then cmd+=" -Wl,-Bstatic -lpthread"; fi
	
				set -o xtrace
	
				(cd src && $cmd)
	
				set +o xtrace
			fi

			set -o xtrace
		} \
		&& : make check > "$log/check.log" \
		&& make install > "$log/install.log"

  set +o xtrace
}

function make_dist {

	rm -rf "$dist"
	mkdir -p "$dist" "$dist/src/$sgmp" "$dist/src/$smpfr" "$dist/bin" "$dist/licenses"

	cd /c/libs/src

	tar --lzip -xf $pgmp -C "$dist/src"
	tar -xJf $pmpfr -C "$dist/src"

	#shopt -s globstar
	cp -r $out/bin/* "$dist/bin"
}

if [ "$arch" == "x32" ]; then 
	make_all $arch false false
	make_all $arch true false
	# make_all $arch true true # on x32 there is no dependency from libmpfr to libwinpthread
elif [ "$arch" == "x64" ]; then 
	make_all $arch false false
	make_all $arch true false
	make_all $arch true true
fi