import requests
import json


bottles_to_build = ('openssl', )
PY_VERSION = '3'
PY_VERSION_ = '3.7'
osx_image = "xcode7.3"


import subprocess

proc = subprocess.run(["travis", "whoami", "--org"],
                      capture_output=True, shell=True)
if proc.returncode:
    if b'not logged in' in proc.stderr:
        loginproc = subprocess.run(["travis", "login", "--org"], shell=True)
        loginproc.check_returncode()
    else:
        raise Exception(proc.stderr)

proc = subprocess.run(["travis", "token", "--org"],
                      capture_output=True, shell=True, text=True)
proc.check_returncode()
token = proc.stdout.strip()

import sys
if sys.version_info.major < 3:
    input = raw_input

body={
  "request": {
    "message": "Build bottles: %s" % (bottles_to_build, ),
    "branch": "travis-upload",
    "config": {
      "merge_mode": "replace",
      "language": "python",
      "cache": {
        "directories": [
          "$HOME/.cache/pip",
          "$HOME/Library/Caches/Homebrew",
          "/Library/Caches/Homebrew"
        ]
      },
      "matrix": {
        "include": [
          {
          "os": "osx",
          "osx_image": osx_image,
          "language": "generic",
          "env": [
            "PY_VERSION=%s" % PY_VERSION,
            "PY_VERSION_=%s" % PY_VERSION_,
            "MAKEFLAGS=-j8",
            "BOTTLES_BUILD='%s'" % ';'.join(bottles_to_build),
            "ROOT_URL=https://github.com/pygame/homebrew-portmidi/releases/download/bottles0",
          ]}
        ]
      },
      "script": [
        "source .travis_osx_upload_bottles.sh"
      ],
      "before_cache": [
        "brew cleanup"
      ]
    }
  }
}

print(body, '\n\n')
print('Building and uploading the following bottles: %s' % (bottles_to_build, ))

confirmation = input('Proceed? [Y/n]')
if confirmation and confirmation[0].lower() != 'y':
    print('Aborting.')


# TODO: use urllib instead (avoid dependency)?
r = requests.post("https://api.travis-ci.org/repo/pygame%2Fpygame/requests",
                  headers={
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                    "Travis-API-Version": "3",
                    "Authorization": "token %s" % token
                  },
                  data=json.dumps(body))
print(r.text)
