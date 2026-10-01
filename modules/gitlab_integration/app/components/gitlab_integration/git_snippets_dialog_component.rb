# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module GitlabIntegration
  class GitSnippetsDialogComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    alias_method :work_package, :model

    def branch_name
      subject = sanitize_branch_string(work_package.subject).downcase

      "#{branch_prefix}-#{subject}"
    end

    def branch_prefix
      type = sanitize_branch_string(work_package.type.name).downcase
      id = work_package.display_id.to_s.downcase

      "#{type}/#{id}"
    end

    def commit_message_lines
      [
        "OP##{work_package.display_id} #{work_package.subject}",
        url_helpers.work_package_short_url(work_package)
      ]
    end

    def commit_message
      commit_message_lines.join("\n\n")
    end

    def create_branch_command_lines
      command_lines = [
        "git switch -c #{branch_name} &&",
        "git commit --allow-empty"
      ]

      message_lines = commit_message_lines.map { |line| "-m '#{sanitize_shell_command_string(line)}'" }

      command_lines.concat(message_lines)
    end

    def create_branch_command
      create_branch_command_lines.join(" ")
    end

    def create_branch_command_text
      lines = create_branch_command_lines
      lines.map.with_index do |line, idx|
        line = "  #{line}" if idx > 0
        line = "#{line} \\" if idx < lines.count - 1

        line
      end
    end

    private

    def sanitize_branch_string(str)
      str.gsub("&", "and ") # & becomes and
         .gsub(/\W+/, "-") # Replace any consecutive non-word characters with a single dash
         .gsub(/^-/, "") # Dash at the start is removed
         .gsub(/-$/, "") # Dash at the end is removed
    end

    def sanitize_shell_command_string(str)
      str.gsub("'", { "'" => "\\'" })
    end
  end
end
