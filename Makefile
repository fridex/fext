# Makefile for fext and its test suite.
# 2020; Fridolin Pokorny <fridolin@redhat.com>

.PHONY: clean
clean:
	rm -rf build/ dist/ fext/*.so fext.egg-info/ wheelhouse/
	pipenv --rm || true

.PHONY: deps
deps:
	yum install -y python3 python3-devel python3-debug \
		valgrind valgrind-devel gcc gcc-c++ which git
	which pipenv || pip3 install pipenv
	which twine || pip3 install twine
	pip3 install --upgrade setuptools wheel

.PHONY: check-refcount
check-refcount:
	pipenv install --dev --python /usr/bin/python3-debug
	pipenv run python3-debug setup.py test -a "-R :"
	pipenv --rm

.PHONY: check-leaks
check-leaks:
	pipenv install --dev
	CFLAGS='-Wall -O0 -ggdb' \
	       PYTHONMALLOC=malloc \
	       pipenv run valgrind --show-leak-kinds=definite --log-file=valgrind-output \
	       python3 setup.py test -a '-vv --valgrind --valgrind-log=valgrind-output'
	pipenv --rm

test:
	pipenv install --dev
	pipenv run python3 setup.py test
	pipenv --rm

.PHONY: check
check: test check-refcount check-leaks

.PHONY: build
build:
	python3 setup.py sdist bdist_wheel

.PHONY: release
release:
	auditwheel repair dist/*.whl
	twine upload wheelhouse/*.whl dist/*.tar.gz

.PHONY: all
all: deps check clean build release
