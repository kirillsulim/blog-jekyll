---
layout: default
title: How my blog works
---

So here is a detailed explanation of how my blog works.


## Nostalgia moment

I've tried to create my own blog dozen of times.
My first blog was just a wordpress page on free hosting.
Then I started to learn Django and decided to write my blog using it.
Then Django lost its popularity and shine and I decided to write my blog on Node.js.
Then TypeScript became almost mainstream for any serious project.
But the problem was: I am not a blog person. 
My [github](https://github.com/kirillsulim) can tell a lot about me, but I am too lazy or too shy to write every day a short post about some
hack I used in .sh script or tricky SQL request.

But then I decided to consider my blog not as interesting programming task but as a product.
And with product came the planning. 
[The first plan](/2019/12/14/planning.html) and [the corrected version](/2019/12/17/second-planning.html).
And after all those years I created my blog.


## Jekyll

I decided to start from static site because all my attempts to wrige blog engine was stopped due to lack of interests at some time.
There was 3 options I considered:

1. [Jekyll](https://jekyllrb.com/). Well documented old Ruby-based static site generator. 
2. [Hugo](https://gohugo.io/). Shiney new pragmatic static generator written on Go lang.
3. [Gatsby](https://www.gatsbyjs.org/). Static site with React. 

I've started with Jekyll. It was an easy and working solution althoug the most boring choice.
I was very concerned about ruby due to its loss of popularity in last decade. 
But I decided that if I would choose Jekyll I will use Docker to avoid dependency loading. 
It was almost 2020 and if I use technologies of previouse decade I should add some contemporary flavour.

Then I tried Gatsby. I discovered that my lack of expirience with React significantly slow me down and decided to drop that option.

I've tried Hugo but honestly I do not remember why I decided not to use it. 

And so I choose tecnology but then I had to choode design.
I was very frustrated with default Jekyll design and decided to create my own template based on some beautifull responsive template.
I quickly looked at [Bootstrap](https://getbootstrap.com/) and [Zurb Foundation framework](https://get.foundation/). 
But then I found [HTML5 UP](https://html5up.net/) and I've understand. 
That is it. 
Simple. 
I dont have to know a lot about CSS. 
And distributed with CC license.

I've downloaded template and adapted it to use as Jekyll layout. 
And the hardest part for me was done.


## Makefile

I am a backend engineer from backend clan. And althogh I've painted and created art in my life I've almost never worked on frondtend in my career.
So here begins the fun.

I decided to use makefile because it has a better structure than a .sh script.
Personally I dislike makefiles. Today I would use `make_mode()` of [dogebuild](https://github.com/dogebuild). I found syntax of makefile unfriendly and hard to remember.
I think the reason is I use slightly sophisticated makefiles once a year and that is why its syntax drives me crazy.

Anyway. Here is my makefile:

```Makefile
# Makefile for all stuff

cwd := $(shell pwd)
jekyll_version := 3.8
html_proofer_version := latest
package_suffix ?= $(shell date --utc +%Y%m%d_%H%M%S)

build:
	docker run --rm --volume="$(cwd):/srv/jekyll" -it jekyll/jekyll:$(jekyll_version) jekyll build

check: build
	docker run -v "$(cwd)/_site:/mounted-site" 18fgsa/html-proofer:$(html_proofer_version) /mounted-site --disable-external
	# docker run --rm --volume="$(cwd):/srv/jekyll" -it jekyll/jekyll:$(jekyll_version) jekyll doctor

serve: check
	docker run --rm --volume="$(cwd):/srv/jekyll" -p 4000:4000 -it jekyll/jekyll:$(jekyll_version) jekyll serve

package: check
	tar -czvf su0.io_$(package_suffix).tar.gz _site/
```

1. Build: Just run Jekyll from docker container and pass current directory as volume. Very easy in 2020.
2. Check: I found out that there is some static analisys for static sites (pun intended). And as a backend developer with great baackground I couldn't pass by.
3. Serve: Run my static site locally to see what I've done.
4. Package: Just pack all generated content into .tar.gz archive. See Artifact section below for more details

## Git

I am a fan of CI and CD and I like to set up deploment process based on branches.
For example all code in testing branch is deployed to test environment. 
All code in master branch will be deployed on production. 
And for my blog I use the same approach.


## Travis

I use travis CI for all of my open-source project.
I cannot say it is perfect but travis CI is great.
It is free, easy to configure and well documented.
I use folowing config:

```yaml
language: minimal

before_script:
    - export PACKAGE_SUFFIX=$(date --utc +'%Y%m%d_%H%M%S')

script:
    - mkdir _site && make package package_suffix=${PACKAGE_SUFFIX}

before_deploy:
    - git config --local user.name "Kirill Sulim"
    - git config --local user.email "kirillsulim@gmail.com"
    - git tag ${PACKAGE_SUFFIX}

deploy:
    provider: releases
    api_key: ${GITHUB_OAUTH_TOKEN}
    file_glob: true
    file: "*.tar.gz"
    skip_cleanup: true
```

I only need make, docker and tar archiver so I use minimal configuration.

Before section sets up tag for my arifact. It is just current date and time.

Script section run makefile to perfom build and package.

Before deploy section sets up git configuration to properly tag release.

Deploy section deploy my artifact to github.


## Artifact

And so my site is builded and only static pages are packed into tar.gz and published to github.


## Python polling daemon

My first idea to keep my blog synchronized with resource was to create web-hook.
But then I realize that it will require to set up web server.
Too much for simple static blog and I decided to use simple python script runned as systemd serice with timer.

Python script:

```python
import requests
import json
import logging
import tarfile
import os
import shutil
from pathlib import Path


KEEP_SNAPSHOT_COUNT = 5

ARCHIVE_FILE = Path('su0.io_current.tar.gz')
LATEST_FILE = Path('latest_version')


rsp = requests.get('https://api.github.com/repos/kirillsulim/blog-jekyll/releases/latest')
data = rsp.json()

archive = list(filter(lambda el: el['name'].startswith('su0.io'), data['assets']))
if len(archive) != 1:
    logging.error('Cannot extravt archive link from:\n{}'.format(data))
    exit(1)

archive_url = archive[0]['browser_download_url']
tag = data['tag_name']

if LATEST_FILE.exists() and LATEST_FILE.read_text() == tag:
    logging.info('Latest version already installed')
    exit(0)


gzip = requests.get(archive_url)

ARCHIVE_FILE.write_bytes(gzip.content)

snapshots_path = Path('snapshots').resolve()
site_path = snapshots_path / tag 

tarfile.open(ARCHIVE_FILE).extractall(path=site_path)

os.symlink(site_path / '_site', '/var/www/blog.tmp', target_is_directory=True)
os.rename('/var/www/blog.tmp', '/var/www/blog')

LATEST_FILE.write_text(tag)
ARCHIVE_FILE.unlink() # Remove file

snapshots = sorted(
    list(snapshots_path.glob('*')), 
    key=lambda folder: folder.stat().st_mtime, 
    reverse=True
)
for snapshot in snapshots[KEEP_SNAPSHOT_COUNT:]:
    shutil.rmtree(snapshot)
```

.service file:

```ini
[Unit]
Description=Runs blog updater
Wants=blog-upfater.timer

[Service]
ExecStart=/usr/bin/python3 /srv/blog/updater.py
WorkingDirectory=/srv/blog

[Install]
WantedBy=multi-user.target
```

.timer file:

```ini
[Unit]
Description=Run blog-updater.service periodically
Requires=blog-updater.service

[Timer]
Unit=blog-updater.service
OnUnitInactiveSec=15m

[Install]
WantedBy=timers.target
```

And ansible playbook to install all gears:

```yaml
- hosts: blog
  gather_facts: True
  
  tasks:
  - name: Create a directory for blog
    file:
      path: /srv/blog
      state: directory

  - name: Install updater.py
    copy: 
      src: updater.py
      dest: /srv/blog/updater.py

  - name: Install blog-updater.service
    copy: 
      src: blog-updater.service
      dest: /etc/systemd/system/blog-updater.service

  - name: Install blog-updater.timer
    copy: 
      src: blog-updater.timer
      dest: /etc/systemd/system/blog-updater.timer

  - name: Start blog-updater.timer
    systemd: 
      state: started 
      enabled: yes
      name: blog-updater.timer 
      daemon_reload: yes

  - name: Copy config file
    copy: 
      src: blog.conf
      dest: /etc/nginx/sites-available/blog.conf
  
  - name: Activate config file
    file: 
      src: /etc/nginx/sites-available/blog.conf
      dest: /etc/nginx/sites-enabled/blog.conf
      state: link

  - name: Restart nginx
    service:
      name: nginx
      state: restarted
```

Every 15 minutes systemd runs script.
This script checks latest published releases on github and install latest release if it is not installed yet.

And this is how my blog works.
