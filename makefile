

# uncomment for debug version
!ifdef %DEBUG
DEBUG = 1
!endif

# Machine type see ow docs
MACHINE= -6r

#Optimization Fastest possible -otexan
OPT = -otexan

CC = wcc386
LD = wlink

INCLUDE = .\;$(%watcom)\h;$(%watcom)\h\os2

!ifdef DEBUG
CFLAGS  = -i=$(INCLUDE) -za99 -d3 -wx -od -DDEBUG $(MACHINE) -bm -bt=OS2
LDFLAGS = d all op map,symf
!else
CFLAGS  = -i=$(INCLUDE) -za99 -d0 -wx -zq $(OPT) $(MACHINE) -bm -bt=OS2
LDFLAGS =
!endif

all: mkmsgf.exe

mkmsgf.exe:
  $(CC) $(CFLAGS) mkmsgf.c
  $(LD) NAME mkmsgf SYS os2v2 $(LDFLAGS) FILE mkmsgf.obj
!ifndef DEBUG
  -@lxlite mkmsgf.exe
!endif

mkmsgd.exe:
  $(CC) $(CFLAGS) mkmsgd.c
  $(LD) NAME mkmsgd SYS os2v2 $(LDFLAGS) FILE mkmsgd.obj
!ifndef DEBUG
  -@lxlite mkmsgf.exe
!endif

debug:  .SYMBOLIC
  @set DEBUG=1
  @wmake

clean:  .SYMBOLIC
CLEANEXTS   = obj exe err lst map sym msg
  @for %a in ($(CLEANEXTS))  do -@rm *.%a

