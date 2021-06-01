#-- encoding: UTF-8

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

require 'spec_helper'

describe Statuses::Scopes::NewByWorkflow, type: :model do
  let(:current_status) { FactoryBot.create(:status) }
  let(:other_status) { FactoryBot.create(:status) }
  let(:workflow_old_status) { current_status }
  let(:workflow_new_status) { other_status }
  let(:workflow_type) { type }
  let(:workflow_role) { role }
  let(:workflow_author) { false }
  let(:workflow_assignee) { false }
  let(:workflow) do
    FactoryBot.create(:workflow,
                      old_status: workflow_old_status,
                      new_status: workflow_new_status,
                      type: workflow_type,
                      role: workflow_role,
                      author: workflow_author,
                      assignee: workflow_assignee)
  end
  let(:role) { FactoryBot.create(:role) }
  let(:type) { FactoryBot.create(:type) }
  let(:assignee) { false }
  let(:author) { false }

  shared_examples_for 'includes the current status' do
    it do
      expect(scope)
        .to match_array(current_status)
    end
  end

  shared_examples_for 'includes the current and the new status by workflow' do
    it do
      expect(scope)
        .to match_array([current_status, other_status])
    end
  end

  describe '.new_by_workflow' do
    subject(:scope) do
      Status.new_by_workflow(status: current_status,
                             type: type,
                             role: role,
                             assignee: assignee,
                             author: author)
    end

    before do
      workflow
    end

    context 'without a workflow' do
      let(:workflow) { nil }

      it_behaves_like 'includes the current status'
    end

    context 'with a workflow' do
      it_behaves_like 'includes the current and the new status by workflow'

      context 'with the role mismatching' do
        let(:workflow_role) { FactoryBot.create(:role) }

        it_behaves_like 'includes the current status'
      end

      context 'with the type mismatching' do
        let(:workflow_type) { FactoryBot.create(:type) }

        it_behaves_like 'includes the current status'
      end

      context 'with the old status mismatching' do
        let(:workflow_old_status) { FactoryBot.create(:status) }

        it_behaves_like 'includes the current status'
      end

      context 'with the workflow being author specific and including neither flags' do
        let(:workflow_author) { true }

        it_behaves_like 'includes the current status'
      end

      context 'with the workflow being author specific and including the author flag' do
        let(:workflow_author) { true }
        let(:author) { true }

        it_behaves_like 'includes the current and the new status by workflow'
      end

      context 'with the workflow being author specific and including the assignee flag' do
        let(:workflow_author) { true }
        let(:assignee) { true }

        it_behaves_like 'includes the current status'
      end

      context 'with the workflow being author specific and including both flags' do
        let(:workflow_author) { true }
        let(:assignee) { true }
        let(:author) { true }

        it_behaves_like 'includes the current and the new status by workflow'
      end

      context 'with the workflow being assignee specific and including neither flags' do
        let(:workflow_assignee) { true }

        it_behaves_like 'includes the current status'
      end

      context 'with the workflow being assignee specific and including the author flag' do
        let(:workflow_assignee) { true }
        let(:author) { true }

        it_behaves_like 'includes the current status'
      end

      context 'with the workflow being assignee specific and including the assignee flag' do
        let(:workflow_assignee) { true }
        let(:assignee) { true }

        it_behaves_like 'includes the current and the new status by workflow'
      end

      context 'with the workflow being assignee specific and including both flags' do
        let(:workflow_assignee) { true }
        let(:assignee) { true }
        let(:author) { true }

        it_behaves_like 'includes the current and the new status by workflow'
      end
    end
  end
end
