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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Help
  class DocumentationArticle
    DIRECTORIES = {
      "project-life-cycle" => "user-guide/projects/project-home/project-life-cycle",
      "life-cycle-settings" => "user-guide/projects/project-settings/project-life-cycle",
      "life-cycle-administration" => "system-admin-guide/projects/project-life-cycle",
      "pmflex-mapping" => "use-cases/project-management-pm2-pmflex",
      "pm2-methodology" => "project-management-guide/3-overview-pm2",
      "initiation-request" => "user-guide/projects/project-initiation-request",
      "initiation-settings" => "user-guide/projects/project-initiation-request/project-initiation-request-settings",
      "initiating-phase" => "project-management-guide/5-initiating-phase"
    }.freeze

    CONTEXTS = {
      "life_cycle" => %w[
        project-life-cycle life-cycle-settings life-cycle-administration pmflex-mapping pm2-methodology
        initiation-request initiating-phase initiation-settings
      ],
      "initiation" => %w[
        initiation-request initiating-phase initiation-settings pmflex-mapping
        project-life-cycle pm2-methodology life-cycle-settings life-cycle-administration
      ]
    }.freeze

    attr_reader :id, :directory

    def self.for_context(context)
      CONTEXTS.fetch(context).map { |id| new(id) }
    end

    def initialize(id)
      @id = id
      @directory = DIRECTORIES.fetch(id)
    end

    def title
      markdown[/^# (.+)$/, 1].to_s.strip
    end

    def markdown
      @markdown ||= path.read
        .sub(/\A---\r?\n.*?\r?\n---\r?\n/m, "")
        .gsub(/^\[feature:.*\]\s*$/, "")
        .gsub(/^> \[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]/) { "> **#{Regexp.last_match(1).capitalize}**" }
    end

    def enterprise_feature?
      path.read.match?(/^\[feature:/)
    end

    def html
      Commonmarker.to_html(markdown, options: { render: { unsafe: false } }, plugins: { syntax_highlighter: nil })
    end

    def url
      "https://www.openproject.org/docs/#{directory}/"
    end

    def path
      Rails.root.join("docs", directory, "README.md")
    end

    def linked_article(href)
      target = linked_path(href)
      return unless target

      DIRECTORIES.each_key.map { |id| self.class.new(id) }.find { |article| article.path == target }
    end

    def asset_path(filename)
      raise KeyError unless filename.match?(/\A[\w.-]+\.(?:png|jpe?g|gif|webp)\z/i)
      raise KeyError unless markdown.scan(/!\[[^\]]*\]\(([^)\s]+)\)/).flatten.include?(filename)

      asset = path.dirname.join(filename)
      raise KeyError unless asset.file?

      asset
    end

    private

    def linked_path(href)
      link = URI.parse(href)
      return if link.absolute? || link.path.blank?

      target = path.dirname.join(link.path).cleanpath
      target.extname.empty? ? target.join("README.md") : target
    rescue URI::InvalidURIError
      nil
    end
  end
end
