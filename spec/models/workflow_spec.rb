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

describe Workflow, type: :model do
  let(:status_0) { FactoryBot.create(:status) }
  let(:status_1) { FactoryBot.create(:status) }
  let(:role) { FactoryBot.create(:role) }
  let(:type) { FactoryBot.create(:type) }

  describe '#self.copy' do
    let(:role_target) { FactoryBot.create(:role) }
    let(:type_target) { FactoryBot.create(:type) }

    shared_examples_for 'copied workflow' do
      before do Workflow.copy(type, role, type_target, role_target) end

      subject { Workflow.order(Arel.sql('id DESC')).first }

      it { expect(subject.old_status).to eq(workflow_src.old_status) }

      it { expect(subject.new_status).to eq(workflow_src.new_status) }

      it { expect(subject.type_id).to eq(type_target.id) }

      it { expect(subject.role).to eq(role_target) }

      it { expect(subject.author).to eq(workflow_src.author) }

      it { expect(subject.assignee).to eq(workflow_src.assignee) }
    end

    describe 'workflow w/o author or assignee' do
      let!(:workflow_src) {
        FactoryBot.create(:workflow,
                           old_status: status_0,
                           new_status: status_1,
                           type_id: type.id,
                           role: role)
      }
      it_behaves_like 'copied workflow'
    end

    describe 'workflow with author' do
      let!(:workflow_src) {
        FactoryBot.create(:workflow,
                           old_status: status_0,
                           new_status: status_1,
                           type_id: type.id,
                           role: role,
                           author: true)
      }
      it_behaves_like 'copied workflow'
    end

    describe 'workflow with assignee' do
      let!(:workflow_src) {
        FactoryBot.create(:workflow,
                           old_status: status_0,
                           new_status: status_1,
                           type_id: type.id,
                           role: role,
                           assignee: true)
      }
      it_behaves_like 'copied workflow'
    end
  end
end
