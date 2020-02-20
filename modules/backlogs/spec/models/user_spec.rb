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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User, type: :model do
  describe 'backlogs_preference' do
    describe 'task_color' do
      it 'reads from and writes to a user preference' do
        u = FactoryBot.create(:user)
        u.backlogs_preference(:task_color, '#FFCC33')

        expect(u.backlogs_preference(:task_color)).to eq('#FFCC33')
        u.reload
        expect(u.backlogs_preference(:task_color)).to eq('#FFCC33')
      end

      it 'computes a random color and persists it, when none is set' do
        u = FactoryBot.create(:user)
        u.backlogs_preference(:task_color, nil)
        u.save!

        generated_task_color = u.backlogs_preference(:task_color)
        expect(generated_task_color).to match(/^#[0-9A-F]{6}$/)
        u.save!
        u.reload
        expect(u.backlogs_preference(:task_color)).to eq(generated_task_color)
      end
    end
  end
end
