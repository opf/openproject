#!/bin/bash
#-- copyright
# OpenProject is a project management system.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

set -e

# script/ci/ai_involvement_check.sh
#
# Verifies that the "AI involvement" section of the pull request template has
# been filled out, i.e. that exactly one of the self-assessment levels is
# present outside of an HTML comment.

# Read from the PR_BODY environment variable, falling back to a positional
# argument so the script can still be run manually for testing.
PR_BODY="${PR_BODY:-$1}"

LEVELS='None|Assisted|Collaborative|Directed|Autonomous'

# The template lists every level inside an HTML comment; contributors pick one
# by removing the comment markers around it. Comments can span multiple lines,
# so they cannot be stripped line by line.
strip_html_comments() {
  awk '
    {
      line = $0
      visible = ""

      while (length(line) > 0) {
        if (in_comment) {
          end = index(line, "-->")
          if (end == 0) {
            line = ""
          } else {
            in_comment = 0
            line = substr(line, end + 3)
          }
        } else {
          start = index(line, "<!--")
          if (start == 0) {
            visible = visible line
            line = ""
          } else {
            visible = visible substr(line, 1, start - 1)
            in_comment = 1
            line = substr(line, start + 4)
          }
        }
      }

      print visible
    }
  '
}

SECTION=$(
  printf '%s\n' "$PR_BODY" |
    tr -d '\r' |
    strip_html_comments |
    sed -n '/^#\{1,6\}[[:space:]]*AI involvement/,/^#\{1,6\}[[:space:]]/p'
)

if [ -z "${SECTION//[[:space:]]/}" ]; then
  echo "::error::The PR description does not contain an 'AI involvement' section."
  echo "status=section_missing" >> "${GITHUB_OUTPUT:-/dev/stdout}"
  exit 0
fi

SELECTED=$(printf '%s\n' "$SECTION" | grep -oE "^[[:space:]]*($LEVELS)\b" | tr -d '[:blank:]' || true)
SELECTED_COUNT=$(printf '%s' "$SELECTED" | grep -c . || true)

if [ "$SELECTED_COUNT" -eq 0 ]; then
  echo "::error::The 'AI involvement' section does not state an AI involvement level."
  echo "status=level_missing" >> "${GITHUB_OUTPUT:-/dev/stdout}"
  exit 0
fi

if [ "$SELECTED_COUNT" -gt 1 ]; then
  LEVEL_LIST="${SELECTED//$'\n'/, }"
  echo "::error::The 'AI involvement' section states more than one level: $LEVEL_LIST"
  {
    echo "status=multiple_levels"
    echo "selected_levels=$LEVEL_LIST"
  } >> "${GITHUB_OUTPUT:-/dev/stdout}"
  exit 0
fi

echo "AI involvement level: $SELECTED"
echo "status=ok" >> "${GITHUB_OUTPUT:-/dev/stdout}"
