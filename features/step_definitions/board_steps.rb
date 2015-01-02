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
#++

Given(/^there is a board "(.*?)" for project "(.*?)"$/) do |board_name, project_identifier|
  FactoryGirl.create :board, project: get_project(project_identifier), name: board_name
end

Given(/^the board "(.*?)" has the following messages:$/) do |board_name, table|
  board = Board.find_by_name(board_name)

  create_messages(table.raw.map(&:first), board)
end

Given(/^"(.*?)" has the following replies:$/) do |message_name, table|
  message = Message.find_by_subject(message_name)

  create_messages(table.raw.map(&:first), message.board, message)
end

private

def create_messages(names, board, parent = nil)
  names.each do |name|
    FactoryGirl.create :message,
                       board: board,
                       subject: name,
                       parent: parent
  end
end
