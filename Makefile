# Makefile for all stuff

cwd := $(shell pwd)
jekyll_version := 3.8
html_proofer_version := latest

build:
	docker run --rm --volume="$(cwd):/srv/jekyll" -it jekyll/jekyll:$(jekyll_version) jekyll build

check: build
	docker run -v "$(cwd)/_site:/mounted-site" 18fgsa/html-proofer:$(html_proofer_version) /mounted-site --disable-external
	# docker run --rm --volume="$(cwd):/srv/jekyll" -it jekyll/jekyll:$(jekyll_version) jekyll doctor

serve: check
	docker run --rm --volume="$(cwd):/srv/jekyll" -p 4000:4000 -it jekyll/jekyll:$(jekyll_version) jekyll serve

package: check
	tar -czvf su0.io.tar.gz _site/
