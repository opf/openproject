#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
module RandomData
  class BoardSeeder
    def self.seed!(project)
      user = User.admin.first

      puts ''
      print ' ↳ Creating forum board with posts'

      board = Board.create! project: project,
                            name: I18n.t('seeders.demo_data.board.name'),
                            description: I18n.t('seeders.demo_data.board.description')

      rand(30).times do
        print '.'
        message = Message.create board: board,
                                 author: user,
                                 subject: Faker::Lorem.words(5).join(' '),
                                 content: Faker::Lorem.paragraph(5, true, 3)

        rand(5).times do
          print '.'
          Message.create board: board,
                         author: user,
                         subject: message.subject,
                         content: Faker::Lorem.paragraph(5, true, 3),
                         parent: message
        end
      end
    end
  end
end
