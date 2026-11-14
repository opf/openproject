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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module ApiDocCoverage
    class Reporter
      def initialize(diff)
        @diff = diff
      end

      def to_json_hash
        {
          "summary" => summary_hash,
          "modules" => @diff.by_module.transform_values { |group| module_hash(group) }
        }
      end

      def to_markdown
        lines = ["# APIv3 documentation coverage", ""]
        lines << summary_line << ""
        @diff.by_module.sort.each do |mod, group|
          lines.concat(module_section(mod, group))
        end
        "#{lines.join("\n")}\n"
      end

      private

      def stringify(endpoint) = "#{endpoint.method} #{endpoint.path}"

      def summary_hash
        {
          "undocumented_routes" => @diff.undocumented_routes.size,
          "undocumented_params" => @diff.undocumented_params.size,
          "orphaned_paths" => @diff.orphaned_paths.size
        }
      end

      def module_hash(group)
        {
          "undocumented_routes" => group[:undocumented_routes].map { |e| stringify(e) },
          "undocumented_params" => group[:undocumented_params].map do |h|
            { "endpoint" => stringify(h[:endpoint]), "params" => h[:param_names] }
          end,
          "orphaned_paths" => group[:orphaned_paths].map { |e| stringify(e) }
        }
      end

      def summary_line
        s = summary_hash
        "**#{s['undocumented_routes']}** undocumented routes · " \
          "**#{s['undocumented_params']}** endpoints with undocumented params · " \
          "**#{s['orphaned_paths']}** orphaned doc paths"
      end

      def module_section(mod, group)
        lines = ["## #{mod}", ""]
        lines.concat(subsection("Undocumented routes (hard)", group[:undocumented_routes]) { |e| "`#{stringify(e)}`" })
        lines.concat(subsection("Undocumented params (advisory)", group[:undocumented_params]) { |h| param_line(h) })
        lines.concat(subsection("Orphaned doc paths (info)", group[:orphaned_paths]) { |e| "`#{stringify(e)}`" })
        lines
      end

      def subsection(heading, entries)
        return [] if entries.empty?

        ["### #{heading}", *entries.map { |entry| "- #{yield entry}" }, ""]
      end

      def param_line(entry)
        missing = entry[:param_names].map { |p| "`#{p}`" }.join(", ")
        "`#{stringify(entry[:endpoint])}` — missing: #{missing}"
      end
    end
  end
end
