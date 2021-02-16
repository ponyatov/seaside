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
PY           = $(BIN)/python3
PIP          = $(BIN)/pip3
PEP          = $(BIN)/autopep8
PYT          = $(BIN)/pytest
# / <section:tool>
# \ <section:src>
M += $(MODULE).py
M += $(shell find metaL -type f -regex ".+.py$$")
T += $(shell find test  -type f -regex ".+.py$$")
P += config.py
N += nginx.conf
S += $(M) $(T) $(N)
# / <section:src>
# \ <section:all>
.PHONY: all
all: $(PY) $(MODULE).py

.PHONY: web
web: $(PY) $(MODULE).py
	$^ $@

.PHONY: test
test: $(PYT) $(T)
	$< test

.PHONY: pep
pep: $(PEP)
$(PEP): $(M) $(T)
	$(MAKE) test
	$(PEP) --ignore=E26,E302,E401,E402 --in-place $?
	$(MAKE) test
	$(MAKE) doxy
	touch $@

.PHONY: repl
repl: $(PY) $(M) $(T)
	$(MAKE) pep
	$(PY) -i $(MODULE).py $@
	$(MAKE) $@
# / <section:all>
# \ <section:doc>
.PHONY: doxy
doxy:
	rm -rf docs ; doxygen doxy.gen 1>/dev/null
# / <section:doc>
# \ <section:install>
.PHONY: install
install: $(OS)_install
	$(MAKE) $(PIP)
	$(MAKE) update
	$(MAKE) js
.PHONY: update
update: $(OS)_update
	$(PIP)  install -U pip autopep8
	$(PIP)  install -U -r requirements.txt
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
# \ <section:install/py>
$(PY) $(PIP):
	python3 -m venv .
	$(MAKE) update
$(PYT):
	$(PIP) install pytest
# / <section:install/py>
# / <section:install>
# \ <section:merge>
MERGE  = Makefile README.md .vscode $(S)
MERGE += apt.txt apt.dev requirements.txt
MERGE += static templates
MERGE += geo/data
MERGE += doc doxy.gen
.PHONY: main
main:
	git push -v
	git checkout $@
	git pull -v
	git checkout shadow -- $(MERGE)
	$(MAKE) doxy
.PHONY: shadow
shadow:
	git push -v
	git checkout $@
	git pull -v
	$(MAKE) doxy
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
