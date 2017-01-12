#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'api/v2/workflows/index.api.rabl', type: :view do
  before do
    params[:format] = 'xml'
  end

  describe 'with no workflow available' do
    before do
      assign(:workflows, [])
      render
    end

    subject { rendered }

    it 'renders an empty workflows document' do
      is_expected.to have_selector('workflows', count: 1)
      is_expected.to have_selector('workflows[type=array]') do
        without_tag 'workflow'
      end
    end
  end

  describe 'with 2 workflows available' do
    let(:transition_00) { ::Api::V2::WorkflowsController::Transition.new(1, :role) }
    let(:transition_01) { ::Api::V2::WorkflowsController::Transition.new(2, :role) }
    let(:transition_10) { ::Api::V2::WorkflowsController::Transition.new(1, :author) }
    let(:transition_11) { ::Api::V2::WorkflowsController::Transition.new(2, :assignee) }
    let(:workflow_0) { ::Api::V2::WorkflowsController::Workflow.new(0, 0, [transition_00, transition_01]) }
    let(:workflow_1) { ::Api::V2::WorkflowsController::Workflow.new(1, 0, [transition_10, transition_11]) }
    let(:workflows) { [workflow_0, workflow_1] }

    before do
      assign(:workflows, workflows)
      render
    end

    subject { Nokogiri.XML(rendered) }

    it { expect(subject).to have_selector('workflows workflow', count: 2) }

    describe 'transition' do
      it { expect(subject).to have_selector('workflows workflow transition', count: 4) }

      context 'type 0' do
        it 'type 0 has correct number of transitions'  do
          expect(subject).to have_selector('workflows workflow type_id', text: 0) do |tag|
            expect(tag).to have_selector('transitions', count: 2)
          end
        end
      end

      context 'type 1' do
        it 'type 1 has correct number of transitions'  do
          expect(subject).to have_selector('workflows workflow type_id', text: 1) do |tag|
            expect(tag).to have_selector('transitions', count: 2)
          end
        end
      end
    end

    describe 'scope' do
      context 'type 0' do
        it 'type 0 has correct number of transitions' do
          expect(subject).to have_selector('workflows workflow type_id', text: '0') do |tag|
            expect(tag).to have_selector('transitions scope', text: 'role', count: 2)
          end
        end
      end

      context 'type 1' do
        it 'type 1 has correct number of transitions' do
          expect(subject).to have_selector('workflows workflow type_id', text: '0') do |tag|
            expect(tag).to have_selector('transitions scope', text: 'author', count: 1)
            expect(tag).to have_selector('transitions scope', text: 'assignee', count: 1)
          end
        end
      end
    end
  end
end
