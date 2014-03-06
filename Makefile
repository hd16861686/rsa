# to build rsa unit tests compile with TESTS=y.
#
# - set u64 type definition by compiling with:
#   U64=UCHAR    for unsigned char (default)
#   U64=USHORT   for unsigned short
#   U64=ULONG    for unsigned long
#   U64=ULLONG   for unsigned long long
# 
# - to enable function timing feature compile with TIME_FUNCTIONS=y.
#
# to build signed rsa encoder and decoders compile with SIG='name'.
# a public key created by the rsa_enc application will contain a field with 
# 'name' signed by the private key and the private key created by the rsa_enc
# application will contain a field with 'name' encrypted by the public key.
# this is used to force rsa_enc and rsa_dec pairs to only use keys generated by
# by rsa-enc

RSA=rsa
ENC=enc
DEC=dec
TEST=test
ALL_TARGETS=$(RSA) $(RSA)_$(ENC) $(RSA)_$(DEC) $(TEST)_$(RSA)

CC=gcc
TARGET_OBJS=rsa_num.o

ENC_LEVEL_VALUES=128 256 512 1024
ifeq ($(ENC_LEVEL),)
ENC_LEVEL=1024
else
ifeq ($(filter $(ENC_LEVEL_VALUES),$(ENC_LEVEL)),)
$(error ENC_LEVEL possible values = {$(ENC_LEVEL_VALUES)}) # error!
endif
endif

CFLAGS=-Wall -Werror -DEL=$(ENC_LEVEL)

ifeq ($(TESTS),y) # create unit tests
TARGET=$(TEST)_$(RSA)
TARGET_OBJS+=rsa_test.o
CFLAGS+=-g -DTESTS

# enable/disable function timing
ifeq ($(TIME_FUNCTIONS),y)
CFLAGS+=-DTIME_FUNCTIONS
endif

# u64 type definition
U64_VALUES=UCHAR USHORT ULONG ULLONG
ifeq ($(U64),)
U64=ULLONG
else
ifeq ($(filter $(U64_VALUES),$(U64)),)
$(error U64 possible values = {$(U64_VALUES)}) # error!
else
ifneq ($(ENC_LEVEL),1024)
ifneq ($(U64),ULLONG)
$(error (for ENC_LEVEL=$(ENC_LEVEL) U64 must be ULLONG)) # error!
endif
endif
endif
endif
CFLAGS+=-D$(U64)
else # creat rsa applications
ifeq ($(SIG),) # create master
TARGET=$(RSA)
else # create separate encoder/decoder
TARGET=$(RSA)_$(ENC) $(RSA)_$(DEC)
TAILOR_OBJS=main.o rsa_key.o rsa_io.o
CFLAGS+=-DULLONG

ifeq ($(SIG),) #master encrypter/decrypter
%.o: %.c rsa.h
	$(CC) -o $@ $(CFLAGS) -c $<

$(RSA): $(TARGET_OBJS) $(TAILOR_OBJS)
	$(CC) -o $@ $^
else #separate encrypter and decrypter
CFLAGS+=-DSIG=\"$(SIG)\" # ENC/DEC

%_$(ENC).o: %.c rsa.h
	$(CC) -o $@ $(CFLAGS) -DRSA_ENC -c $<

%_$(DEC).o: %.c rsa.h
	$(CC) -o $@ $(CFLAGS) -DRSA_DEC -c $<

$(RSA)%: $(TARGET_OBJS) $(TAILOR_OBJS:.o=%.o)
	$(CC) -o $@ $^
endif
endif
endif

.PHONY: all clean cleanapps cleantags cleanall
all: $(TARGET)

$(TARGET): $(TARGET_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ -lm

clean:
	rm -rf *.o

cleanapps:
	rm -rf $(ALL_TARGETS)

cleantags:
	rm -rf tags

cleanall: clean cleanapps cleantags

