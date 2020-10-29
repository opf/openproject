# use GNU Make to run tests in parallel, and without depending on RubyGems
all:: test

RLFLAGS = -G2

MRI = ruby
RUBY = ruby
RAKE = rake
RAGEL = ragel
RSYNC = rsync
OLDDOC = olddoc
RDOC = rdoc
INSTALL = install

GIT-VERSION-FILE: .FORCE-GIT-VERSION-FILE
	@./GIT-VERSION-GEN
-include GIT-VERSION-FILE
-include local.mk
ruby_bin := $(shell which $(RUBY))
ifeq ($(DLEXT),) # "so" for Linux
  DLEXT := $(shell $(RUBY) -rrbconfig -e 'puts RbConfig::CONFIG["DLEXT"]')
endif
ifeq ($(RUBY_VERSION),)
  RUBY_VERSION := $(shell $(RUBY) -e 'puts RUBY_VERSION')
endif

RUBY_ENGINE := $(shell $(RUBY) -e 'puts((RUBY_ENGINE rescue "ruby"))')

# we should never package more than one ext to avoid DSO proliferation:
# https://udrepper.livejournal.com/8790.html
ext := $(firstword $(wildcard ext/*))

ragel: $(ext)/unicorn_http.c

rl_files := $(wildcard $(ext)/*.rl)
ragel: $(ext)/unicorn_http.c
$(ext)/unicorn_http.c: $(rl_files)
	cd $(@D) && $(RAGEL) unicorn_http.rl -C $(RLFLAGS) -o $(@F)
ext_pfx := test/$(RUBY_ENGINE)-$(RUBY_VERSION)
tmp_bin := $(ext_pfx)/bin
ext_h := $(wildcard $(ext)/*/*.h $(ext)/*.h)
ext_src := $(sort $(wildcard $(ext)/*.c) $(ext_h) $(ext)/unicorn_http.c)
ext_pfx_src := $(addprefix $(ext_pfx)/,$(ext_src))
ext_dir := $(ext_pfx)/$(ext)
$(ext)/extconf.rb: $(wildcard $(ext)/*.h)
	@>>$@
$(ext_dir) $(tmp_bin) man/man1 doc/man1 pkg t/trash:
	@mkdir -p $@
$(ext_pfx)/$(ext)/%: $(ext)/% | $(ext_dir)
	$(INSTALL) -m 644 $< $@
$(ext_pfx)/$(ext)/Makefile: $(ext)/extconf.rb $(ext_h) | $(ext_dir)
	$(RM) -f $(@D)/*.o
	cd $(@D) && $(RUBY) $(CURDIR)/$(ext)/extconf.rb $(EXTCONF_ARGS)
ext_sfx := _ext.$(DLEXT)
ext_dl := $(ext_pfx)/$(ext)/$(notdir $(ext)_ext.$(DLEXT))
$(ext_dl): $(ext_src) $(ext_pfx_src) $(ext_pfx)/$(ext)/Makefile
	$(MAKE) -C $(@D)
lib := $(CURDIR)/lib:$(CURDIR)/$(ext_pfx)/$(ext)
http build: $(ext_dl)
$(ext_pfx)/$(ext)/unicorn_http.c: ext/unicorn_http/unicorn_http.c

# dunno how to implement this as concisely in Ruby, and hell, I love awk
awk_slow := awk '/def test_/{print FILENAME"--"$$2".n"}' 2>/dev/null

slow_tests := test/unit/test_server.rb test/exec/test_exec.rb \
  test/unit/test_signals.rb test/unit/test_upload.rb
log_suffix = .$(RUBY_ENGINE).$(RUBY_VERSION).log
T := $(filter-out $(slow_tests), $(wildcard test/*/test*.rb))
T_n := $(shell $(awk_slow) $(slow_tests))
T_log := $(subst .rb,$(log_suffix),$(T))
T_n_log := $(subst .n,$(log_suffix),$(T_n))

base_bins := unicorn unicorn_rails
bins := $(addprefix bin/, $(base_bins))
man1_rdoc := $(addsuffix _1, $(base_bins))
man1_bins := $(addsuffix .1, $(base_bins))
man1_paths := $(addprefix man/man1/, $(man1_bins))
tmp_bins = $(addprefix $(tmp_bin)/, unicorn unicorn_rails)
pid := $(shell echo $$PPID)

$(tmp_bin)/%: bin/% | $(tmp_bin)
	$(INSTALL) -m 755 $< $@.$(pid)
	$(MRI) -i -p -e '$$_.gsub!(%r{^#!.*$$},"#!$(ruby_bin)")' $@.$(pid)
	mv $@.$(pid) $@

bins: $(tmp_bins)

t_log := $(T_log) $(T_n_log)
test: $(T) $(T_n)
	@cat $(t_log) | $(MRI) test/aggregate.rb
	@$(RM) $(t_log)

test-exec: $(wildcard test/exec/test_*.rb)
test-unit: $(wildcard test/unit/test_*.rb)
$(slow_tests): $(ext_dl)
	@$(MAKE) $(shell $(awk_slow) $@)

# ensure we can require just the HTTP parser without the rest of unicorn
test-require: $(ext_dl)
	$(RUBY) --disable-gems -I$(ext_pfx)/$(ext) -runicorn_http -e Unicorn

test_prereq := $(tmp_bins) $(ext_dl)

SH_TEST_OPTS =
ifdef V
  ifeq ($(V),2)
    SH_TEST_OPTS += --trace
  else
    SH_TEST_OPTS += --verbose
  endif
endif

# do we trust Ruby behavior to be stable? some tests are
# (mostly) POSIX sh (not bash or ksh93, so no "set -o pipefail"
# TRACER = strace -f -o $(t_pfx).strace -s 100000
# TRACER = /usr/bin/time -o $(t_pfx).time
t_pfx = trash/$@-$(RUBY_ENGINE)-$(RUBY_VERSION)
T_sh = $(wildcard t/t[0-9][0-9][0-9][0-9]-*.sh)
$(T_sh): export RUBY := $(RUBY)
$(T_sh): export PATH := $(CURDIR)/$(tmp_bin):$(PATH)
$(T_sh): export RUBYLIB := $(lib):$(RUBYLIB)
$(T_sh): dep $(test_prereq) t/random_blob t/trash/.gitignore
	cd t && $(TRACER) $(SHELL) $(SH_TEST_OPTS) $(@F) $(TEST_OPTS)

t/trash/.gitignore : | t/trash
	echo '*' >$@

dependencies := socat curl
deps := $(addprefix t/.dep+,$(dependencies))
$(deps): dep_bin = $(lastword $(subst +, ,$@))
$(deps):
	@which $(dep_bin) > $@.$(pid) 2>/dev/null || :
	@test -s $@.$(pid) || \
	  { echo >&2 "E '$(dep_bin)' not found in PATH=$(PATH)"; exit 1; }
	@mv $@.$(pid) $@
dep: $(deps)

t/random_blob:
	dd if=/dev/urandom bs=1M count=30 of=$@.$(pid)
	mv $@.$(pid) $@

test-integration: $(T_sh)

check: test-require test test-integration
test-all: check

TEST_OPTS = -v
check_test = grep '0 failures, 0 errors' $(t) >/dev/null
ifndef V
       quiet_pre = @echo '* $(arg)$(extra)';
       quiet_post = >$(t) 2>&1 && $(check_test)
else
       # we can't rely on -o pipefail outside of bash 3+,
       # so we use a stamp file to indicate success and
       # have rm fail if the stamp didn't get created
       stamp = $@$(log_suffix).ok
       quiet_pre = @echo $(RUBY) $(arg) $(TEST_OPTS); ! test -f $(stamp) && (
       quiet_post = && > $(stamp) )2>&1 | tee $(t); \
         rm $(stamp) 2>/dev/null && $(check_test)
endif

# not all systems have setsid(8), we need it because we spam signals
# stupidly in some tests...
rb_setsid := $(RUBY) -e 'Process.setsid' -e 'exec *ARGV'

# TRACER='strace -f -o $(t).strace -s 100000'
run_test = $(quiet_pre) \
  $(rb_setsid) $(TRACER) $(RUBY) -w $(arg) $(TEST_OPTS) $(quiet_post) || \
  (sed "s,^,$(extra): ," >&2 < $(t); exit 1)

%.n: arg = $(subst .n,,$(subst --, -n ,$@))
%.n: t = $(subst .n,$(log_suffix),$@)
%.n: export PATH := $(CURDIR)/$(tmp_bin):$(PATH)
%.n: export RUBYLIB := $(lib):$(RUBYLIB)
%.n: $(test_prereq)
	$(run_test)

$(T): arg = $@
$(T): t = $(subst .rb,$(log_suffix),$@)
$(T): export PATH := $(CURDIR)/$(tmp_bin):$(PATH)
$(T): export RUBYLIB := $(lib):$(RUBYLIB)
$(T): $(test_prereq)
	$(run_test)

install: $(bins) $(ext)/unicorn_http.c
	$(prep_setup_rb)
	$(RM) -r .install-tmp
	mkdir .install-tmp
	cp -p bin/* .install-tmp
	$(RUBY) setup.rb all
	$(RM) $^
	mv .install-tmp/* bin/
	$(RM) -r .install-tmp
	$(prep_setup_rb)

setup_rb_files := .config InstalledFiles
prep_setup_rb := @-$(RM) $(setup_rb_files);$(MAKE) -C $(ext) clean

clean:
	-$(MAKE) -C $(ext) clean
	$(RM) $(ext)/Makefile
	$(RM) $(setup_rb_files) $(t_log)
	$(RM) -r $(ext_pfx) man t/trash
	$(RM) $(html1)

man1 := $(addprefix Documentation/, unicorn.1 unicorn_rails.1)
html1 := $(addsuffix .html, $(man1))
man : $(man1) | man/man1
	$(INSTALL) -m 644 $(man1) man/man1

html : $(html1) | doc/man1
	$(INSTALL) -m 644 $(html1) doc/man1

%.1.html: %.1
	$(OLDDOC) man2html -o $@ ./$<

pkg_extra := GIT-VERSION-FILE lib/unicorn/version.rb LATEST NEWS \
             $(ext)/unicorn_http.c $(man1_paths)

NEWS:
	$(OLDDOC) prepare

.manifest: $(ext)/unicorn_http.c man NEWS
	(git ls-files && for i in $@ $(pkg_extra); do echo $$i; done) | \
	  LC_ALL=C sort > $@+
	cmp $@+ $@ || mv $@+ $@
	$(RM) $@+

PLACEHOLDERS = $(man1_rdoc)
doc: .document $(ext)/unicorn_http.c man html .olddoc.yml $(PLACEHOLDERS)
	find bin lib -type f -name '*.rbc' -exec rm -f '{}' ';'
	$(RM) -r doc
	$(OLDDOC) prepare
	$(RDOC) -f dark216
	$(OLDDOC) merge
	$(INSTALL) -m 644 COPYING doc/COPYING
	$(INSTALL) -m 644 NEWS.atom.xml doc/NEWS.atom.xml
	$(INSTALL) -m 644 $(shell LC_ALL=C grep '^[A-Z]' .document) doc/
	$(INSTALL) -m 644 $(man1_paths) doc/
	tar cf - $$(git ls-files examples/) | (cd doc && tar xf -)

# publishes docs to https://yhbt.net/unicorn/
publish_doc:
	-git set-file-times
	$(MAKE) doc
	$(MAKE) doc_gz
	chmod 644 $$(find doc -type f)
	$(RSYNC) -av doc/ yhbt.net:/srv/yhbt/unicorn/
	git ls-files | xargs touch

# Create gzip variants of the same timestamp as the original so nginx
# "gzip_static on" can serve the gzipped versions directly.
doc_gz: docs = $(shell find doc -type f ! -regex '^.*\.gz$$')
doc_gz:
	for i in $(docs); do \
	  gzip --rsyncable -9 < $$i > $$i.gz; touch -r $$i $$i.gz; done

ifneq ($(VERSION),)
rfpackage := unicorn
pkggem := pkg/$(rfpackage)-$(VERSION).gem
pkgtgz := pkg/$(rfpackage)-$(VERSION).tgz

# ensures we're actually on the tagged $(VERSION), only used for release
verify:
	test x"$(shell umask)" = x0022
	git rev-parse --verify refs/tags/v$(VERSION)^{}
	git diff-index --quiet HEAD^0
	test `git rev-parse --verify HEAD^0` = \
	     `git rev-parse --verify refs/tags/v$(VERSION)^{}`

fix-perms:
	git ls-tree -r HEAD | awk '/^100644 / {print $$NF}' | xargs chmod 644
	git ls-tree -r HEAD | awk '/^100755 / {print $$NF}' | xargs chmod 755

gem: $(pkggem)

install-gem: $(pkggem)
	gem install --local $(CURDIR)/$<

$(pkggem): .manifest fix-perms | pkg
	gem build $(rfpackage).gemspec
	mv $(@F) $@

$(pkgtgz): distdir = $(basename $@)
$(pkgtgz): HEAD = v$(VERSION)
$(pkgtgz): .manifest fix-perms
	@test -n "$(distdir)"
	$(RM) -r $(distdir)
	mkdir -p $(distdir)
	tar cf - $$(cat .manifest) | (cd $(distdir) && tar xf -)
	cd pkg && tar cf - $(basename $(@F)) | gzip -9 > $(@F)+
	mv $@+ $@

package: $(pkgtgz) $(pkggem)

release: verify package
	# push gem to Gemcutter
	gem push $(pkggem)
else
gem install-gem: GIT-VERSION-FILE
	$(MAKE) $@ VERSION=$(GIT_VERSION)
endif

$(PLACEHOLDERS):
	echo olddoc_placeholder > $@

check-warnings:
	@(for i in $$(git ls-files '*.rb' bin | grep -v '^setup\.rb$$'); \
	  do $(RUBY) --disable-gems -d -W2 -c \
	  $$i; done) | grep -v '^Syntax OK$$' || :

.PHONY: .FORCE-GIT-VERSION-FILE doc $(T) $(slow_tests) man $(T_sh) clean
