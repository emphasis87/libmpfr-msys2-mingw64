#!/bin/bash

vgmp="6.1.2"
vmpfr="3.1.5"

sgmp="gmp-$vgmp"
smpfr="mpfr-$vmpfr"
vlibs="${smpfr}_${sgmp}"

pgmp="$sgmp.tar.lz"
pmpfr="$smpfr.tar.xz"

function make_all {

	make_setup "$@"
	make_build
	make_dist
}

function make_setup {

    set +o xtrace

    arch=${1:-"x32"}
	static_libgcc=${2:-false}
    static_libwinpthread=${3:-false}

	if [ "$static_libgcc" = false ] || [ $static_libwinpthread = false ]; then
		name="runtime";
	else
		name="standalone"
	fi
    if [ "$static_libgcc" = false ]; then name+="_libgcc"; fi
    if [ "$static_libwinpthread" = false ]; then name+="_libwinpthread"; fi

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

mkdir -p /c/libs/src
cd /c/libs/src

if [ ! -f $pgmp ]; then wget "https://gmplib.org/download/gmp/$pgmp"; fi
if [ ! -f $pmpfr ]; then wget "http://www.mpfr.org/mpfr-current/$pmpfr"; fi

set -o xtrace

make_all "x32" false false

set +o xtrace