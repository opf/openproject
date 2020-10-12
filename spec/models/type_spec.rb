#-- encoding: UTF-8
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

require 'spec_helper'

describe ::Type, type: :model do
  let(:type) { FactoryBot.build(:type) }
  let(:type2) { FactoryBot.build(:type) }
  let(:project) { FactoryBot.build(:project, no_types: true) }

  describe '.enabled_in(project)' do
    before do
      type.projects << project
      type.save

      type2.save
    end

    it 'returns the types enabled in the provided project' do
      expect(Type.enabled_in(project)).to match_array([type])
    end
  end

  describe '.statuses' do
    let(:subject) { type.statuses }

    context 'when new' do
      let(:type) { FactoryBot.build(:type) }

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'when existing but no statuses' do
      let(:type) { FactoryBot.create(:type) }

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'when existing with workflow' do
      let(:role) { FactoryBot.create(:role) }
      let(:statuses) { (1..2).map { |_i| FactoryBot.create(:status) } }

      let!(:type) { FactoryBot.create(:type) }
      let!(:workflow_a) do
        FactoryBot.create(:workflow, role_id: role.id,
                          type_id: type.id,
                          old_status_id: statuses[0].id,
                          new_status_id: statuses[1].id,
                          author: false,
                          assignee: false)
      end

      it 'returns the statuses relation' do
        expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
      end

      context 'with default status' do
        let!(:default_status) { FactoryBot.create(:default_status) }
        let(:subject) { type.statuses(include_default: true) }

        it 'returns the workflow and the default status' do
          expect(subject.pluck(:id)).to contain_exactly(default_status.id, statuses[0].id, statuses[1].id)
        end
      end
    end
  end
end
