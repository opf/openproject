#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
module DemoData
  class VersionBuilder
    include ::DemoData::References

    attr_reader :config
    attr_reader :project

    def initialize(config, project)
      @config = config
      @project = project
    end

    def create!
      create_version if valid?
    end

    private

    def valid?
      true
    end

    def create_version
      version.tap do |version|
        project.versions << version
      end
    end

    def version
      version = Version.create!(
        name:    config[:name],
        status:  config[:status],
        sharing: config[:sharing],
        project: project
      )

      set_wiki! version, config[:wiki] if config[:wiki]

      version
    end

    def set_wiki!(version, config)
      version.wiki_page_title = config[:title]
      page = WikiPage.create! wiki: version.project.wiki, title: version.wiki_page_title

      content = with_references config[:content], project
      Journal::NotificationConfiguration.with false do
        WikiContent.create! page: page, author: User.admin.first, text: content
      end

      version.save!
    end
  end
end
