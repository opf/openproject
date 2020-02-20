#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
#++

require 'support/pages/messages/base'

module Pages::Messages
  class Index < ::Pages::Messages::Base
    attr_accessor :project

    def initialize(project)
      self.project = project
    end

    def path
      project_forums_path(project)
    end

    def click_create_message
      click_on 'Message'

      ::Pages::Messages::Create.new(project.forums.first)
    end

    def expect_listed(subject:, replies: nil, last_message: nil)
      subject = find('table tr td.subject', text: subject)

      row = subject.find(:xpath, '..')

      within(row) do
        expect(page).to have_selector('td.replies', text: replies) if replies
        expect(page).to have_selector('td.last_message', text: last_message) if last_message
      end
    end

    def expect_num_replies(amount)
      expect(page).to have_selector('td.replies', text: amount)
    end
  end
end
