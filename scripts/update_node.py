#!/usr/bin/env python3
# Copyright 2020 The Emscripten Authors.  All rights reserved.
# Emscripten is available under two separate licenses, the MIT license and the
# University of Illinois/NCSA Open Source License.  Both these licenses can be
# found in the LICENSE file.

"""Updates the node binaries that we cache store at
http://storage.google.com/webassembly.

For the windows version we also alter the directory layout to add the 'bin'
direcotry.
"""

import urllib.request
import subprocess
import os
import shutil

version = '18.18.0'
base = 'https://nodejs.org/dist/v18.18.0/'
upload_base = 'gs://webassembly/emscripten-releases-builds/deps/'

suffixes = [
    '-win-x86.zip',
    '-win-x64.zip',
    '-darwin-x64.tar.gz',
    '-darwin-arm64.tar.gz',
    '-linux-x64.tar.xz',
    '-linux-arm64.tar.xz',
    '-linux-armv7l.tar.xz',
]

for suffix in suffixes:
    filename = 'node-v%s%s' % (version, suffix)
    download_url = base + filename
    print('Downloading: ' + download_url)
    urllib.request.urlretrieve(download_url, filename)

    if '-win-' in suffix:
      subprocess.check_call(['unzip', '-q', filename])
      dirname = os.path.splitext(os.path.basename(filename))[0]
      shutil.move(dirname, 'bin')
      os.mkdir(dirname)
      shutil.move('bin', dirname)
      os.remove(filename)
      subprocess.check_call(['zip', '-rq', filename, dirname])
      shutil.rmtree(dirname)

    upload_url = upload_base + filename
    print('Uploading: ' + upload_url)
    cmd = ['gsutil', 'cp', '-n', filename, upload_url]
    print(' '.join(cmd))
    subprocess.check_call(cmd)
    os.remove(filename)
