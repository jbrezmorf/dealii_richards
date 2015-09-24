# $Id: Makefile.large 16564 2008-08-15 16:09:42Z bangerth $

# The large projects Makefile looks much like the one for small
# projects. Basically, only the following six parameters need to be
# set by you:

# The first denotes the dimension for which the program is to be
# compiled:
deal_II_dimension = 2

# The second tells us the name of the executable. It is prefixed by
# `lib/' to designate its destination directory. Note that the program
# name depends on the dimension, so you can keep copies for the
# different dimensions around:
target   = lib/richards-$(deal_II_dimension)d

# The `debug-mode' variable works as in the small projects Makefile:
debug-mode = off

# And so does the following variable. You will have to set it to
# something more reasonable, of course.
clean-up-files = *.o *.vtk

# Finally, here is a variable which tells the `run' rule which
# parameters to pass to the executable. Usually, this will be the name
# of an input file.
run-parameters  = 

# Now, this is the last variable you need to set, namely the path to
# the deal.II toplevel directory:
D = ${HOME}/local/deal.ii-7.1.0

BOOST_INCLUDE=${D}/contrib/boost/include/boost
PETSC_DIR=/home/jb/local/petsc-3.0.0-p7
PETSC_ARCH=gcc_serial

LD_LIBRARY_PATH+=${PETSC_DIR}/${PETSC_ARCH}/lib
#
#
# Usually, you will not need to change anything beyond this point.
#
#
# This tells `make' where to find the global settings and rules:
include $D/common/Make.global_options

ACTUAL=$(shell pwd)
INCLUDE += -I${ACTUAL}/include -I${BOOST_INCLUDE} -I${ACTUAL}/lib
flags= -Wno-unused -g

# First get a list of files belonging to the project. Include files
# are expected in `include/', while implementation files are expected
# in `source/'. Object files are placed into `lib/[123]d', using the
# same base name as the `.cc' file.
cc-files    = $(shell echo source/*.cc)
o-files     = $(cc-files:source/%.cc=lib/$(deal_II_dimension)d/%.$(OBJEXT))
go-files    = $(cc-files:source/%.cc=lib/$(deal_II_dimension)d/%.g.$(OBJEXT))
h-files     = $(wildcard include/*.h)
lib-h-files = $( shell echo ${BOOST_INCLUDE}/*.h )

#$(shell echo ${D}/base/include/base/*.h \
#   ${D}/lac/include/lac/*.h \
#   ${D}/deal.II/include/*/*.h \

# As before, define a list of libraries. This, of course depends on
# the dimension in which we are working:
libs.g   := $(lib-deal2.g)
libs.o   := $(lib-deal2.o)

#libs.g   = $(lib-deal2-$(deal_II_dimension)d.g) \
#	   $(lib-lac.g)                         \
#           $(lib-base.g)
#libs.o   = $(lib-deal2-$(deal_II_dimension)d.o) \
#	   $(lib-lac.o)                         \
#           $(lib-base.o)



# Define a nifty string to indicate in the output of the compile
# commands whether the program is compiled in multithread mode or not:
ifneq ($(with-multithreading),no)
  MT = MT
else
  MT = ==
endif




# Now use the information from above to define the set of libraries to
# link with and the flags to be passed to the compiler:
ifeq ($(debug-mode),on)
  libraries = $(go-files) $(libs.g) 
  flags     = $(CXXFLAGS.g) -g3 -rdynamic 
else
  libraries = $(o-files) $(libs.o)
  flags     = $(CXXFLAGS.o) -O3
endif


# Then augment the compiler flags by a specification of the dimension
# for which the program shall be compiled:
flags += -Ddeal_II_dimension=$(deal_II_dimension)


# The following two rules define how to compile C++ files into object
# files:
lib/$(deal_II_dimension)d/%.g.$(OBJEXT) :
	@echo =====waves=======$(deal_II_dimension)d====debug=====$(MT)== $(<F)
	$(CXX)   $(flags) -c $< -o $@
lib/$(deal_II_dimension)d/%.$(OBJEXT) :
	@echo =====waves=======$(deal_II_dimension)d====optimized=$(MT)== $(<F)
	$(CXX)  $(flags)  -c $< -o $@


all: $(target)$(EXEEXT)

# Next define how to link the executable
$(target)$(EXEEXT) : $(libraries) Makefile
	@echo =====waves=======$(deal_II_dimension)d==============$(MT)== Linking $(@F)
	$(CXX) $(flags) -o $@ $(libraries) $(LIBS) $(LDFLAGS)



# Rule how to run the program
run: $(target)$(EXEEXT)
	./$(target)$(EXEEXT) $(run-parameters)


# Rule how to clean up. This is split into several different rules to
# allow for parallel execution of commands:
clean: clean-lib clean-data
	-rm -f *~ */*~ */*/*~ lib/Makefile.dep

clean-lib:
	-rm -f lib/?d/*.$(OBJEXT) lib/?d/*.g.$(OBJEXT) $(target)$(EXEEXT) lib/TAGS

clean-data:
	-rm -f $(clean-up-files)


# Again tell `make' which rules are not meant to produce files:
.PHONY: clean clean-data clean-lib run



# Finally produce the list of dependencies. Note that this time, the
# object files end up in directories of their own, so we have to
# modify the output a bit. The file with the dependencies is put into
# `lib/'.
lib/Makefile.dep: $(cc-files) $(h-files) $(lib-h-files) Makefile
	@echo =====waves=======$(deal_II_dimension)d================== Remaking $@
	$D/common/scripts/make_dependencies $(INCLUDE) -Blib $(cc-files) \
	 | $(PERL) -p -e 's!^lib/(.*):!lib/$(deal_II_dimension)d/$$1:!g;' \
		> $@

include lib/Makefile.dep

