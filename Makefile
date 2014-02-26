# to build rsa tests compile with DEBUG=y.
#
# - set u64 type definition by compiling with:
#   U64=UCHAR    for unsigned char (default)
#   U64=USHORT   for unsigned short
#   U64=ULONG    for unsigned long
#   U64=ULLONG   for unsigned long long
# 
# - to enable function timing feature compile with TIME_FUNCTIONS=y.
#   determine which functions are to be timed by assigning either ENABLED or 
#   DISSABLED in rsa_num.c:func_table[].
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
ALL_TARGETS=$(RSA) $(RSA)_$(ENC) $(RSA)_$(DEC) $(RSA)_$(TEST)

ifeq ($(DEBUG),y)
TARGET=$(RSA)_$(TEST)
else
ifeq ($(SIG),)
TARGET=$(RSA)
else
TARGET=$(RSA)_$(ENC) $(RSA)_$(DEC)
endif
endif

.PHONY: all clean cleanall
all: $(TARGET)

CC=gcc
CFLAGS:=-Wall -g
TARGET_OBJS:=rsa_num.o

ifeq ($(DEBUG),y)
TARGET_OBJS+=rsa_test.o
CFLAGS+=-DDEBUG

ifeq ($(TIME_FUNCTIONS),y)
CFLAGS+=-DTIME_FUNCTIONS
endif

ifeq ($(U64),UCHAR)
CFLAGS+=-DUCHAR
else
ifeq ($(U64),USHORT)
CFLAGS+=-DUSHORT
else
ifeq ($(U64),ULONG)
CFLAGS+=-DULONG
else
ifeq ($(U64),ULLONG)
CFLAGS+=-DULLONG
else
CFLAGS+=-DUCHAR
endif
endif
endif
endif
else #not debug
TARGET_OBJS+=rsa_io.o
TAILOR_OBJS=main.o rsa_key.o
ifneq ("$(SIG)","")
CFLAGS+=-DSIG=\"$(SIG)\"

%_$(ENC).o: %.c
	$(CC) -o $@ $(CFLAGS) -DRSA_ENC -c $<

%_$(DEC).o: %.c
	$(CC) -o $@ $(CFLAGS) -DRSA_DEC -c $<

$(RSA)%: $(TARGET_OBJS) $(TAILOR_OBJS:.o=%.o)
	$(CC) -o $@ $^
endif
%.o: %.c
	$(CC) -o $@ $(CFLAGS) -c $<

$(RSA): $(TARGET_OBJS) $(TAILOR_OBJS:%.o=%.o)
	$(CC) -o $@ $^
endif

clean:
	rm -rf *.o
cleanall: clean
	rm -rf $(ALL_TARGETS) tags

