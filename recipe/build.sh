#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Create package archive and install globally
npm pack --ignore-scripts
npm install -ddd \
    --no-bin-links \
    --global \
    --build-from-source \
    ${SRC_DIR}/angular-devkit-${PKG_NAME}-${PKG_VERSION}.tgz

# Patch package.json to remove packageManager key so that
# pnpm can be used to create license report
mv package.json package.json.bak
jq 'del(.packageManager)' package.json.bak > package.json

# Create license report for dependencies
pnpm install
pnpm-licenses generate-disclaimer --prod --output-file=third-party-licenses.txt

mkdir -p ${PREFIX}/bin
tee ${PREFIX}/bin/architect << EOF
#!/bin/sh
exec \${CONDA_PREFIX}/lib/node_modules/@angular-devkit/architect-cli/bin/architect.js "\$@"
EOF
chmod +x ${PREFIX}/bin/architect

tee ${PREFIX}/bin/architect.cmd << EOF
call %CONDA_PREFIX%\bin\node %CONDA_PREFIX%\lib\node_modules\@angular-devkit\architect-cli\bin\architect.js %*
EOF
