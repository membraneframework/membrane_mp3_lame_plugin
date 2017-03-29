ERL_INCLUDE_PATH_DARWIN=/usr/local/Cellar/erlang/19.2/lib/erlang/usr/include/
ERL_INCLUDE_PATH_LINUX=/usr/lib/erlang/erts-8.0.2/include/
OSX_SDK_PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.12.sdk

darwin: darwin_encoder

linux: linux_encoder

darwin_encoder:
	clang -arch x86_64 -O3 -mssse3 -fPIC -I../membrane_common_c/include -I./deps/membrane_common_c/include -isysroot $(OSX_SDK_PATH) -framework Lame -dynamiclib -undefined dynamic_lookup -I$(ERL_INCLUDE_PATH_DARWIN) -o membrane_element_lame_encoder.so c_src/encoder.c

linux_encoder:
	cc -O3 -mssse3 -fPIC -L/usr/local/lib -I../membrane_common_c/include -I./deps/membrane_common_c/include -I$(ERL_INCLUDE_PATH_LINUX) -rdynamic -undefined -shared -o membrane_element_lame_encoder.so c_src/encoder.c -lmp3lame
