site := ${CURDIR}/build/site

all: clean todos html

clean:
	rm -rf site

todos:
	./find-TODOs.sh --verbose modules

html:
	@echo "Building openshift-deployment-guide:"
	antora generate --fetch site.yml
	@echo "Success! Open ${site}/index.html"
	# The site directory must be output as the last line
	# to be compatible with the Tech Hub build process
	@echo "${site}"
