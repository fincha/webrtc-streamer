CC = $(CROSS)g++ $(foreach sysroot,$(SYSROOT),--sysroot=$(sysroot))
AR = $(CROSS)ar
CFLAGS = -Wall -pthread -g -std=c++11 -Iinc
LDFLAGS = -pthread 
WEBRTCROOT?=../webrtc
WEBRTCBUILD?=Release

TARGET = webrtc-server_$(GYP_GENERATOR_OUTPUT)_$(WEBRTCBUILD)
all: $(TARGET)

# webrtc
WEBRTCLIBPATH=$(WEBRTCROOT)/src/$(GYP_GENERATOR_OUTPUT)/out/$(WEBRTCBUILD)

CFLAGS += -DWEBRTC_POSIX -fno-rtti -D_GLIBCXX_USE_CXX11_ABI=0
CFLAGS += -I $(WEBRTCROOT)/src -I $(WEBRTCROOT)/src/third_party/jsoncpp/source/include
#detect
TESTDEBUG=$(shell nm $(wildcard $(WEBRTCLIBPATH)/obj/webrtc/media/rtc_media/videocapturer.o $(WEBRTCLIBPATH)/obj/webrtc/media/librtc_media.a) | c++filt | grep std::__debug::vector >/dev/null && echo debug)
ifeq ($(TESTDEBUG),debug)
	CFLAGS +=-DUSE_DEBUG_WEBRTC -D_GLIBCXX_DEBUG=1
endif
LDFLAGS += -lX11 -ldl -lrt

WEBRTC_LIB += $(shell find $(WEBRTCLIBPATH)/obj -name '*.a')
LIBS+=libWebRTC_$(GYP_GENERATOR_OUTPUT)_$(WEBRTCBUILD).a
libWebRTC_$(GYP_GENERATOR_OUTPUT)_$(WEBRTCBUILD).a: $(WEBRTC_LIB)
	$(AR) -rcT $@ $^

# live555helper
ifneq ($(wildcard $(SYSROOT)/usr/include/liveMedia/liveMedia.hh),)
LIBS+=live555helper/live555helper.a
live555helper/Makefile:
	git submodule update --init live555helper

live555helper/live555helper.a: live555helper/Makefile
	git submodule update live555helper
	make -C live555helper

CFLAGS += -DHAVE_LIVE555
CFLAGS += -I live555helper/inc
CFLAGS += -I $(SYSROOT)/usr/include/liveMedia  -I $(SYSROOT)/usr/include/groupsock -I $(SYSROOT)/usr/include/UsageEnvironment -I $(SYSROOT)/usr/include/BasicUsageEnvironment/

LDFLAGS += live555helper/live555helper.a
LDFLAGS += -l:libliveMedia.a -l:libgroupsock.a -l:libUsageEnvironment.a -l:libBasicUsageEnvironment.a 
endif

# civetweb
LIBS+=civetweb/libcivetweb.a
civetweb/Makefile:
	git submodule update --init civetweb

civetweb/libcivetweb.a: civetweb/Makefile
	make lib WITH_CPP=1 COPT="$(CFLAGS)" -C civetweb

CFLAGS += -I civetweb/include
LDFLAGS += -L civetweb -l civetweb


src/%.o: src/%.cpp $(LIBS)
	$(CC) -o $@ -c $< $(CFLAGS) 

FILES = $(wildcard src/*.cpp)
$(TARGET): $(subst .cpp,.o,$(FILES)) $(LIBS) 
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -f src/*.o libWebRTC_$(GYP_GENERATOR_OUTPUT)_$(WEBRTCBUILD).a $(TARGET)
	make -C civetweb clean
	make -C live555helper clean

install:
	install -m 0755 $(TARGET) /usr/local/bin



