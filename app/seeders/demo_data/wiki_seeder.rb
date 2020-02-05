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
  class WikiSeeder < Seeder
    attr_reader :project, :key

    def initialize(project, key)
      @project = project
      @key = key
    end

    def seed_data!
      text = project_data_for(key, 'wiki')

      return if text.is_a?(String) && text.start_with?("translation missing")

      user = User.admin.first

      if text.is_a? String
        text = [{title: "Wiki", content: text}]
      end

      print '    ↳ Creating wikis'

      Array(text).each do |data|
        create_wiki_page!(
          data,
          project: project,
          user: user
        )
      end

      puts
    end

    def create_wiki_page!(data, project:, user:, parent: nil)
      wiki_page = WikiPage.create!(
        wiki:  project.wiki,
        title: data[:title],
        parent: parent
      )

      print '.'
      WikiContent.create!(
        page:   wiki_page,
        author: user,
        text:   data[:content]
      )

      if data[:children]
        Array(data[:children]).each do |child_data|
          create_wiki_page!(
            child_data,
            project: project,
            user: user,
            parent: wiki_page
          )
        end
      end
    end
  end
end
