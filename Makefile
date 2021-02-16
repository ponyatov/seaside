# \ <section:var>
MODULE       = $(notdir $(CURDIR))
OS           = $(shell uname -s)
MACHINE      = $(shell uname -m)
NOW          = $(shell date +%d%m%y)
REL          = $(shell git rev-parse --short=4 HEAD)
CORES        = $(shell grep processor /proc/cpuinfo| wc -l)
# / <section:var>
# \ <section:dir>
CWD          = $(CURDIR)
DOC          = $(CWD)/doc
BIN          = $(CWD)/bin
TMP          = $(CWD)/tmp
# / <section:dir>
# \ <section:tool>
WGET         = wget -c
CURL         = curl
PHARO        = ./pharo
# / <section:tool>
# \ <section:src>
# / <section:src>
# \ <section:all>
.PHONY: all
all: pharo
	$(PHARO) $(IMAGE)

.PHONY: web
web: $(PY) $(MODULE).py
	$^ $@

.PHONY: test
test: $(PYT) $(T)
	$< test

# / <section:all>
# \ <section:doc>
.PHONY: doxy
doxy:
	rm -rf docs ; doxygen doxy.gen 1>/dev/null
# / <section:doc>
# \ <section:install>
.PHONY: install
install: $(OS)_install
.PHONY: update
update: $(OS)_update
.PHONY: Linux_install Linux_update
Linux_install Linux_update:
	sudo apt update
	sudo apt install -u `cat apt.txt`
# \ <section:install/js>
.PHONY: js
js:	static/js/jquery.min.js static/js/socket.io.min.js \
	static/js/bootstrap/bootstrap.min.css static/js/bootstrap/bootstrap.dark.css \
	static/js/bootstrap/bootstrap.min.js \
	static/js/html5shiv.js static/js/respond.js

JQUERY_VER = 3.5.1
JQUERY_JS  = https://code.jquery.com/jquery-$(JQUERY_VER).js
static/js/jquery.min.js:
	$(WGET) -O $@ $(JQUERY_JS)

SOCKETIO_VER = 3.1.0
SOCKETIO_CDN = https://cdnjs.cloudflare.com/ajax/libs/socket.io
static/js/socket.io.min.js: static/js/socket.io.min.js.map
	$(WGET) -O $@ $(SOCKETIO_CDN)/$(SOCKETIO_VER)/socket.io.min.js
static/js/socket.io.min.js.map:
	$(WGET) -O $@ $(SOCKETIO_CDN)/$(SOCKETIO_VER)/socket.io.min.js.map

BOOTSTRAP_VER  = 4.6.0
BOOTSTRAP_CDN = https://cdn.jsdelivr.net/npm/bootstrap@$(BOOTSTRAP_VER)/dist
static/js/bootstrap/bootstrap.dark.css:
	$(WGET) -O $@ https://bootswatch.com/4/darkly/bootstrap.css
static/js/bootstrap/bootstrap.min.css: static/js/bootstrap/bootstrap.min.css.map
	$(WGET) -O $@ $(BOOTSTRAP_CDN)/css/bootstrap.min.css
static/js/bootstrap/bootstrap.min.css.map:
	$(WGET) -O $@ $(BOOTSTRAP_CDN)/css/bootstrap.min.css.map
static/js/bootstrap/bootstrap.min.js: static/js/bootstrap/bootstrap.bundle.min.js.map
	$(WGET) -O $@ $(BOOTSTRAP_CDN)/js/bootstrap.bundle.min.js
static/js/bootstrap/bootstrap.bundle.min.js.map:
	$(WGET) -O $@ $(BOOTSTRAP_CDN)/js/bootstrap.bundle.min.js.map

HTML5SHIV_VER = 3.7.3
HTML5SHIV_CDN = https://cdnjs.cloudflare.com/ajax/libs/html5shiv
static/js/html5shiv.js:
	$(WGET) -O $@ $(HTML5SHIV_CDN)/$(HTML5SHIV_VER)/html5shiv-printshiv.js

RESPOND_VER = 1.4.2
RESPOND_CDN = https://cdnjs.cloudflare.com/ajax/libs/respond.js
static/js/respond.js:
	$(WGET) -O $@ $(RESPOND_CDN)/$(RESPOND_VER)/respond.js

# / <section:install/js>
# \ <section:install/pharo>

PHARO_VER = 80
.PHONY: pharo
pharo: bin/pharo lib/pharo.version
lib/pharo.version: tmp/pharo64.zip
	unzip -d lib -x $< && touch $@
bin/pharo: tmp/pharo64-linux-stable.zip
	unzip -x $< && touch $@
tmp/pharo64-linux-stable.zip:
	$(WGET) -O $@ https://files.pharo.org/get-files/$(PHARO_VER)/pharo64-linux-stable.zip
tmp/pharo64.zip:	
	$(WGET) -O $@ https://files.pharo.org/get-files/$(PHARO_VER)/pharo64.zip	
# / <section:install/pharo>
# / <section:install>
# \ <section:merge>
MERGE  = Makefile README.md .vscode $(S) apt.txt
.PHONY: main
main:
	git push -v
	git checkout $@
	git pull -v
	git checkout shadow -- $(MERGE)
.PHONY: shadow
shadow:
	git push -v
	git checkout $@
	git pull -v
.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v && git push -v --tags
	$(MAKE) shadow
.PHONY: zip
zip:
	git archive \
		--format zip \
		--output $(TMP)/$(MODULE)_$(NOW)_$(REL).src.zip \
	HEAD
# / <section:merge>
