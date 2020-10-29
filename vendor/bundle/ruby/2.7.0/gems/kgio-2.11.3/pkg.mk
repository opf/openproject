RUBY = ruby
RAKE = rake
RSYNC = rsync
OLDDOC = olddoc
RDOC = rdoc

GIT-VERSION-FILE: .FORCE-GIT-VERSION-FILE
	@./GIT-VERSION-GEN
-include GIT-VERSION-FILE
-include local.mk
DLEXT := $(shell $(RUBY) -rrbconfig -e 'puts RbConfig::CONFIG["DLEXT"]')
RUBY_VERSION := $(shell $(RUBY) -e 'puts RUBY_VERSION')
RUBY_ENGINE := $(shell $(RUBY) -e 'puts((RUBY_ENGINE rescue "ruby"))')
lib := lib

ext := $(firstword $(wildcard ext/*))
ifneq ($(ext),)
ext_pfx := tmp/ext/$(RUBY_ENGINE)-$(RUBY_VERSION)
ext_h := $(wildcard $(ext)/*/*.h $(ext)/*.h)
ext_src := $(wildcard $(ext)/*.c $(ext_h))
ext_pfx_src := $(addprefix $(ext_pfx)/,$(ext_src))
ext_d := $(ext_pfx)/$(ext)/.d
$(ext)/extconf.rb: $(wildcard $(ext)/*.h)
	@>> $@
$(ext_d):
	@mkdir -p $(@D)
	@> $@
$(ext_pfx)/$(ext)/%: $(ext)/% $(ext_d)
	install -m 644 $< $@
$(ext_pfx)/$(ext)/Makefile: $(ext)/extconf.rb $(ext_d) $(ext_h)
	$(RM) -f $(@D)/*.o
	cd $(@D) && $(RUBY) $(CURDIR)/$(ext)/extconf.rb $(EXTCONF_ARGS)
ext_sfx := _ext.$(DLEXT)
ext_dl := $(ext_pfx)/$(ext)/$(notdir $(ext)_ext.$(DLEXT))
$(ext_dl): $(ext_src) $(ext_pfx_src) $(ext_pfx)/$(ext)/Makefile
	@echo $^ == $@
	$(MAKE) -C $(@D)
lib := $(lib):$(ext_pfx)/$(ext)
build: $(ext_dl)
else
build:
endif

pkg_extra += GIT-VERSION-FILE NEWS LATEST
NEWS: GIT-VERSION-FILE .olddoc.yml
	$(OLDDOC) prepare
LATEST: NEWS

manifest:
	$(RM) .manifest
	$(MAKE) .manifest

.manifest: $(pkg_extra)
	(git ls-files && for i in $@ $(pkg_extra); do echo $$i; done) | \
		LC_ALL=C sort > $@+
	cmp $@+ $@ || mv $@+ $@
	$(RM) $@+

doc:: .document .olddoc.yml $(pkg_extra) $(PLACEHOLDERS)
	-find lib -type f -name '*.rbc' -exec rm -f '{}' ';'
	-find ext -type f -name '*.rbc' -exec rm -f '{}' ';'
	$(RM) -r doc
	$(RDOC) -f dark216
	$(OLDDOC) merge
	install -m644 COPYING doc/COPYING
	install -m644 NEWS doc/NEWS
	install -m644 NEWS.atom.xml doc/NEWS.atom.xml
	install -m644 $(shell LC_ALL=C grep '^[A-Z]' .document) doc/

ifneq ($(VERSION),)
pkggem := pkg/$(rfpackage)-$(VERSION).gem
pkgtgz := pkg/$(rfpackage)-$(VERSION).tgz

# ensures we're actually on the tagged $(VERSION), only used for release
verify:
	test x"$(shell umask)" = x0022
	git rev-parse --verify refs/tags/v$(VERSION)^{}
	git diff-index --quiet HEAD^0
	test $$(git rev-parse --verify HEAD^0) = \
	     $$(git rev-parse --verify refs/tags/v$(VERSION)^{})

fix-perms:
	-git ls-tree -r HEAD | awk '/^100644 / {print $$NF}' | xargs chmod 644
	-git ls-tree -r HEAD | awk '/^100755 / {print $$NF}' | xargs chmod 755

gem: $(pkggem)

install-gem: $(pkggem)
	gem install --local $(CURDIR)/$<

$(pkggem): manifest fix-perms
	gem build $(rfpackage).gemspec
	mkdir -p pkg
	mv $(@F) $@

$(pkgtgz): distdir = $(basename $@)
$(pkgtgz): HEAD = v$(VERSION)
$(pkgtgz): manifest fix-perms
	@test -n "$(distdir)"
	$(RM) -r $(distdir)
	mkdir -p $(distdir)
	tar cf - $$(cat .manifest) | (cd $(distdir) && tar xf -)
	cd pkg && tar cf - $(basename $(@F)) | gzip -9 > $(@F)+
	mv $@+ $@

package: $(pkgtgz) $(pkggem)

release:: verify package
	# push gem to RubyGems.org
	gem push $(pkggem)
else
gem install-gem: GIT-VERSION-FILE
	$(MAKE) $@ VERSION=$(GIT_VERSION)
endif

all:: check
test_units := $(wildcard test/test_*.rb)
test: check
check: test-unit
test-unit: $(test_units)
$(test_units): build
	$(RUBY) -I $(lib) $@ $(RUBY_TEST_OPTS)

# this requires GNU coreutils variants
ifneq ($(RSYNC_DEST),)
publish_doc:
	-git set-file-times
	$(MAKE) doc
	$(MAKE) doc_gz
	$(RSYNC) -av doc/ $(RSYNC_DEST)/
	git ls-files | xargs touch
endif

# Create gzip variants of the same timestamp as the original so nginx
# "gzip_static on" can serve the gzipped versions directly.
doc_gz: docs = $(shell find doc -type f ! -regex '^.*\.gz$$')
doc_gz:
	for i in $(docs); do \
	  gzip --rsyncable -9 < $$i > $$i.gz; touch -r $$i $$i.gz; done
check-warnings:
	@(for i in $$(git ls-files '*.rb'| grep -v '^setup\.rb$$'); \
	  do $(RUBY) -d -W2 -c $$i; done) | grep -v '^Syntax OK$$' || :

ifneq ($(PLACEHOLDERS),)
$(PLACEHOLDERS):
	echo olddoc_placeholder > $@
endif

.PHONY: all .FORCE-GIT-VERSION-FILE doc check test $(test_units) manifest
.PHONY: check-warnings
