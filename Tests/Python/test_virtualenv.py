#!/usr/bin/env python3

import subprocess
import shutil
import os
import shlex
import sysconfig
import sys

if sysconfig.get_config_var('TARGET_OS_EMBEDDED'):
    sys.exit(69) # skip test

def run(cmd, **kwargs):
    print("+", ' '.join(map(shlex.quote, cmd)))
    return subprocess.run(cmd, **kwargs)

virtualenv = os.path.join(os.getenv('DT_ASSETS', 'assets'), 'virtualenv-16.0.0-py2.py3-none-any.whl')

run(['python3', '-m', 'pip', 'install', virtualenv], check=True)

env = os.path.join(os.getenv('TMPDIR', '/tmp'), 'env.%d' % os.getpid())

try:
    run(['virtualenv', env], check=True)
    run([env+'/bin/pip', 'install', virtualenv], check=True)
    run([env+'/bin/virtualenv', '-h'])
finally:
    shutil.rmtree(env)

try:
    run(['python3', '-m', 'venv', env], check=True)
    run([env+'/bin/pip', 'install', virtualenv], check=True)
    run([env+'/bin/virtualenv', '-h'])
finally:
    shutil.rmtree(env)
