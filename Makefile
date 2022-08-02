
THIS_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))
THIS_MAKEFILE := `python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' ${THIS_MAKEFILE}`
SRC_ROOT := $(shell dirname ${THIS_MAKEFILE})


# WARNING: these vars must come before the includes
# FIXME: next line could use default if repo were renamed from https://github.com/605data/lib-605 to https://github.com/605data/lib605
PYPI_PROJECT_NAME:=sceptre

# lib includes
MAKE_INCLUDES_DIR := ${SRC_ROOT}/.makefiles
include ${MAKE_INCLUDES_DIR}/Makefile.605-pypi.mk

pypi-version:
	@printf "`cat setup.cfg|grep current_version | awk '{print $$3}'`-`git rev-parse HEaD`\n"

push:
	mv dist/sceptre-2.3.0.tar.gz dist/sceptre-2.3.0-`git rev-parse HEAD`.tar.gz
	make pypi-push

.PHONY: clean-pyc clean-build docs clean docs
define BROWSER_PYSCRIPT
import os, webbrowser, sys
try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT
BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@echo "clean - remove all build, test, coverage and Python artifacts"
	@echo "clean-build - remove build artifacts"
	@echo "clean-pyc - remove Python file artifacts"
	@echo "clean-test - remove test and coverage artifacts"
	@echo "lint - check style with flake8"
	@echo "test - run tests quickly with the default Python"
	@echo "test-all - run tests on every Python version with tox"
	@echo "test-integration - run integration tests"
	@echo "coverage - check code coverage quickly with the default Python"
	@echo "coverage-ci - check code coverage and generate cobertura report"
	@echo "dist - package"
	@echo "install - install the package to the active Python's site-packages"
	@echo "install-dev - install the test requirements to the active Python's site-packages"
	@echo "docs - generate Sphinx HTML documentation, including API docs"
	@echo ""
	@ $(MAKE) -C docs help


clean: clean-build clean-pyc clean-test docs-clean

clean-build:
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test:
	rm -fr .tox/
	rm -fr .cache/
	rm -f .coverage
	rm -fr htmlcov/
	rm -f test-results.xml

lint:
	flake8 .

test:
	pytest --junitxml=test-results/junit.xml

test-all:
	tox

test-integration: install
	behave integration-tests/

coverage-all:
		coverage erase
		coverage run --source sceptre -m pytest
		coverage xml

coverage: coverage-all
		coverage report --show-missing --fail-under 92

sonar:
	    @sonar-scanner \
            -Dsonar.projectKey=Sceptre_${CIRCLE_PROJECT_REPONAME} \
            -Dsonar.organization=sceptre \
			-Dsonar.projectName=${CIRCLE_PROJECT_REPONAME} \
            -Dsonar.pullrequest.provider=GitHub\
			-Dsonar.branch.name=${CIRCLE_BRANCH}\
            -Dsonar.sources=. \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.login=${SONAR_LOGIN}

docs:
	rm -f docs/sceptre.rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ sceptre
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

docs-latest:
	$(MAKE) -C docs build-latest

docs-build-tag:
	$(MAKE) -C docs build-tag

docs-build-dev:
	$(MAKE) -C docs build-dev

docs-build-commit:
	$(MAKE) -C docs build-commit

docs-serve-latest:
	$(MAKE) -C docs serve-latest

docs-serve-tag:
	$(MAKE) -C docs serve-tag

docs-serve-dev:
	$(MAKE) -C docs serve-dev

docs-serve-commit: docs-commit
	$(MAKE) -C docs serve-commit

docs-install:
	$(MAKE) -C docs install

docs-clean:
	$(MAKE) -C docs clean

dist: clean
	python setup.py sdist
	python setup.py bdist_wheel
	twine check dist/*
	ls -l dist

install: clean
	pip install .

install-dev: clean
	pip install -r requirements/prod.txt
	pip install -r requirements/dev.txt
	pip install -e .
	@echo "To install the documentation dependencies, run:\ncd docs\nmake install"
