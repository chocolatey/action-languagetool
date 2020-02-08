#!/bin/sh
set -e

LANGTOOL_DATA="language=en-US"

java -cp "/LanguageTool-${LANGUAGETOOL_VERSION}/languagetool-server.jar" org.languagetool.server.HTTPServer --port 8010 &
sleep 3 # Wait the server statup.

if [ -n "${GITHUB_WORKSPACE}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

run_langtool() {
  for FILE in $(git ls-files | ghglob '**/*.md' '**/*.txt'); do
    curl --data "language=en-US" \
      --data-urlencode "text=$(cat "${FILE}")" \
      http://localhost:8010/v2/check | \
      FILE="${FILE}" tmpl /langtool.tmpl
  done
}

run_langtool \
  | reviewdog -efm="%A%f:%l:%c: %m" -efm="%C %m" -name="LanguageTool" -reporter="${INPUT_REPORTER:-github-pr-check}" -level="${INPUT_LEVEL}"
