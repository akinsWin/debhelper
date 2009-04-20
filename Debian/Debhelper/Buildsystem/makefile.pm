# A buildsystem plugin for handling simple Makefile based projects.
#
# Copyright: © 2008 Joey Hess
#            © 2008-2009 Modestas Vainius
# License: GPL-2+

package Debian::Debhelper::Buildsystem::makefile;

use strict;
use Debian::Debhelper::Dh_Lib;
use base 'Debian::Debhelper::Buildsystem';

sub get_makecmd_C {
	my $this=shift;
	if ($this->get_builddir()) {
		return $this->{makecmd} . " -C " . $this->get_builddir();
	}
	return $this->{makecmd};
}

sub exists_make_target {
	my ($this, $target) = @_;
	my $makecmd=$this->get_makecmd_C();

	# Use make -n to check to see if the target would do
	# anything. There's no good way to test if a target exists.
	my $ret=`$makecmd -s -n $target 2>/dev/null`;
	chomp $ret;
	return length($ret);
}

sub make_first_existing_target {
	my $this=shift;
	my $targets=shift;

	foreach my $target (@$targets) {
		if ($this->exists_make_target($target)) {
			$this->doit_in_builddir($this->{makecmd}, $target, @_);
			return $target;
		}
	}
	return undef;
}

sub DESCRIPTION {
	"support for building Makefile based packages (make && make install)"
}

sub new {
	my $class=shift;
	my $this=$class->SUPER::new(@_);
	$this->{makecmd} = (exists $ENV{MAKE}) ? $ENV{MAKE} : "make";
	return $this;
}

sub check_auto_buildable {
	my $this=shift;
	my ($action) = @_;

	# Handles build, test, install, clean; configure - next class
	if (grep /^\Q$action\E$/, qw{build test install clean}) {
		# This is always called in the source directory, but generally
		# Makefiles are created (or live) in the the build directory.
		return -e $this->get_buildpath("Makefile") ||
		       -e $this->get_buildpath("makefile") ||
		       -e $this->get_buildpath("GNUmakefile");
	}
	return 0;
}

sub build {
	my $this=shift;
	$this->doit_in_builddir($this->{makecmd}, @_);
}

sub test {
	my $this=shift;
	$this->make_first_existing_target(['test', 'check'], @_);
}

sub install {
	my $this=shift;
	my $destdir=shift;
	$this->make_first_existing_target(['install'], "DESTDIR=$destdir", @_);
}

sub clean {
	my $this=shift;
	if (!$this->clean_builddir()) {
		$this->make_first_existing_target(['distclean', 'realclean', 'clean'], @_);
	}
}

1;