#!/usr/bin/env bash

docker run -v $(pwd)/_site:/mounted-site 18fgsa/html-proofer /mounted-site --disable-external
