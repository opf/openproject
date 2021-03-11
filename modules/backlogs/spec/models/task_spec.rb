#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Task, type: :model do
  let(:task_type) { FactoryBot.create(:type) }
  let(:default_status) { FactoryBot.create(:default_status) }
  let(:project) { FactoryBot.create(:project) }
  let(:task) do
    FactoryBot.build(:task,
                     project: project,
                     status: default_status,
                     type: task_type)
  end

  before(:each) do
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
      .and_return({ 'task_type' => task_type.id.to_s })
  end

  describe 'copying remaining_hours to estimated_hours and vice versa' do
    context 'providing only remaining_hours' do
      before do
        task.remaining_hours = 3

        task.save!
      end

      it 'copies to estimated_hours' do
        expect(task.estimated_hours)
          .to eql task.remaining_hours
      end
    end

    context 'providing only estimated_hours' do
      before do
        task.estimated_hours = 3

        task.save!
      end

      it 'copies to estimated_hours' do
        expect(task.remaining_hours)
          .to eql task.estimated_hours
      end
    end

    context 'providing estimated_hours and remaining_hours' do
      before do
        task.estimated_hours = 3
        task.remaining_hours = 5

        task.save!
      end

      it 'leaves the values unchanged' do
        expect(task.remaining_hours)
          .to eql 5.0

        expect(task.estimated_hours)
          .to eql 3.0
      end
    end
  end
end
