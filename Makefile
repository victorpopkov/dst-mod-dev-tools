GIT_LATEST_TAG = $$(git describe --abbrev=0)
MODINFO_VERSION = $$(grep '^version.*=' < modinfo.lua | awk -F'= ' '{ print $$2 }' | tr -d '"')

# Source: https://stackoverflow.com/a/10858332
__check_defined = $(if $(value $1),, $(error Undefined $1$(if $2, ($2))))
check_defined = $(strip $(foreach 1,$1, $(call __check_defined,$1,$(strip $(value 2)))))

help:
	@printf "Please use 'make <target>' where '<target>' is one of:\n\n"
	@echo "   citest          to run Busted tests for CI"
	@echo "   dev             to run reinstall + ldoc + lint + test"
	@echo "   gitrelease      to commit modinfo.lua and CHANGELOG.md + add a new tag"
	@echo "   install         to install the mod"
	@echo "   ldoc            to generate an LDoc documentation"
	@echo "   lint            to run code linting"
	@echo "   modicon         to pack modicon"
	@echo "   reinstall       to uninstall and then install the mod"
	@echo "   release         to update version"
	@echo "   test            to run Busted tests"
	@echo "   testclean       to clean up after tests"
	@echo "   testcoverage    to print the tests coverage report"
	@echo "   testlist        to list all existing tests"
	@echo "   uninstall       to uninstall the mod"
	@echo "   workshop        to prepare the Steam Workshop directory + archive"
	@echo "   workshopclean   to clean up Steam Workshop directory + archive"

citest:
	@busted .; \
		luacov-console .; \
		cp luacov.report.out luacov.report.out.bak \
			&& luacov -r lcov > /dev/null 2>&1 \
			&& cp luacov.report.out lcov.info \
			&& cp luacov.report.out.bak luacov.report.out \
			&& rm luacov.report.out.bak; \
		awk '/^Summary$$/{if (a) print a;if (b) print b}{a=b;b=$$0;} /^Summary$$/,f' luacov.report.out

dev: reinstall ldoc lint test

gitrelease:
	@echo "Latest Git tag: ${GIT_LATEST_TAG}"
	@echo "Modinfo version: ${MODINFO_VERSION}\n"

	@printf '1/5: Resetting (git reset)...'
	@git reset > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@printf '2/5: Adding and commiting modinfo.lua...'
	@git add modinfo.lua > /dev/null 2>&1
	@git commit -m 'Update modinfo: version and description' > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@printf '3/5: Adding and commiting CHANGELOG.md...'
	@git add CHANGELOG.md > /dev/null 2>&1
	@git commit -m "Update CHANGELOG.md: release ${MODINFO_VERSION}" > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@printf "4/5: Creating a signed tag (v${MODINFO_VERSION})..."
	@git tag -s "v${MODINFO_VERSION}" -m "Release v${MODINFO_VERSION}" > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@echo "5/5: Verifying tag (v${MODINFO_VERSION})...\n"
	@git verify-tag "v${MODINFO_VERSION}"

install:
	@:$(call check_defined, DST_MODS)
	@rsync -az \
		--exclude '.*' \
		--exclude 'busted.out' \
		--exclude 'CHANGELOG.md' \
		--exclude 'config.ld' \
		--exclude 'CONTRIBUTING.md' \
		--exclude 'description.txt*' \
		--exclude 'doc/' \
		--exclude 'lcov.info' \
		--exclude 'luacov*' \
		--exclude 'Makefile' \
		--exclude 'modicon.png' \
		--exclude 'preview.*' \
		--exclude 'README.md' \
		--exclude 'readme/' \
		--exclude 'spec/' \
		--exclude 'workshop*' \
		. \
		"${DST_MODS}/dst-mod-dev-tools/"

ldoc:
	@find ./doc/* -type f -not -name Dockerfile -not -name docker-stack.yml -not -wholename ./doc/ldoc/ldoc.css -delete
	@ldoc .

lint:
	@EXIT=0; \
		printf "Luacheck:\n\n"; luacheck . --exclude-files="here/" || EXIT=$$?; \
		printf "\nPrettier:\n\n"; prettier --check \
			'./**/*.md' \
			'./**/*.xml' \
			'./**/*.yml' \
		|| EXIT=$$?; \
		exit $${EXIT}

modicon:
	@:$(call check_defined, DS_KTOOLS_KTECH)
	@${DS_KTOOLS_KTECH} ./modicon.png . --atlas ./modicon.xml --square
	@prettier --xml-whitespace-sensitivity='ignore' --write './modicon.xml'

reinstall: uninstall install

release:
	@:$(call check_defined, MOD_VERSION)
	@echo "Version: ${MOD_VERSION}\n"

	@printf '1/2: Updating modinfo version...'
	@sed -i "s/^version.*$$/version = \"${MOD_VERSION}\"/g" ./modinfo.lua && echo ' Done' || echo ' Error'
	@printf '2/2: Syncing LDoc release code occurrences...'
	@find . -type f -regex '.*\.lua' -exec sed -i "s/@release.*$$/@release ${MOD_VERSION}/g" {} \; && echo ' Done' || echo ' Error'

test:
	@busted .; luacov -r lcov > /dev/null 2>&1 && cp luacov.report.out lcov.info; luacov-console . && luacov-console -s

testclean:
	@rm -f busted.out lcov.info luacov*

testcoverage:
	@luacov -r lcov > /dev/null 2>&1 && cp luacov.report.out lcov.info; luacov-console . && luacov-console -s

testlist:
	@busted --list . | awk '{$$1=""}1' | awk '{gsub(/^[ \t]+|[ \t]+$$/,"");print}'

uninstall:
	@:$(call check_defined, DST_MODS)
	@rm -Rf "${DST_MODS}/dst-mod-dev-tools/"

workshop:
	@rm -Rf ./workshop*
	@mkdir -p ./workshop/
	@cp -R ./LICENSE ./workshop/
	@cp -R ./modicon.tex ./workshop/
	@cp -R ./modicon.xml ./workshop/
	@cp -R ./modinfo.lua ./workshop/
	@cp -R ./modmain.lua ./workshop/
	@cp -R ./scripts/ ./workshop/

workshopclean:
	@rm -Rf ./workshop* ./steam-workshop.zip

.PHONY: ldoc modicon workshop
