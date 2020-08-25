# Makefile for all stuff

cwd := $(shell pwd)
jekyll_version := 3.8
html_proofer_version := latest
package_suffix ?= $(shell date --utc +%Y%m%d_%H%M%S)

build:
	docker run --rm --volume="$(cwd):/srv/jekyll" -it jekyll/jekyll:$(jekyll_version) jekyll build --verbose

check: build
	docker run -v "$(cwd)/_site:/mounted-site" 18fgsa/html-proofer:$(html_proofer_version) /mounted-site --disable-external
	# docker run --rm --volume="$(cwd):/srv/jekyll" -it jekyll/jekyll:$(jekyll_version) jekyll doctor

serve: check
	docker run --rm --volume="$(cwd):/srv/jekyll" -p 4000:4000 -it jekyll/jekyll:$(jekyll_version) jekyll serve

package: check
	tar -czvf su0.io_$(package_suffix).tar.gz _site/
