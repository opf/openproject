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

describe 'api/v2/planning_element_priorities/index.api.rabl', type: :view do
  before { params[:format] = 'xml' }

  describe 'with no work package priorities available' do
    before do
      assign(:priorities, [])
      render
    end

    subject { rendered }

    it 'renders an empty planning_element_priorities document' do
      expect(subject).to have_selector('planning_element_priorities', count: 1)
      expect(subject).to have_selector('planning_element_priorities[type=array]') do |tag|
        expect(tag).to have_selector('planning_element_priority', count: 0)
      end
    end
  end

  describe 'with 3 work package priorities available' do
    let!(:priority_0) { FactoryGirl.create(:priority) }
    let!(:priority_1) {
      FactoryGirl.create(:priority,
                         position: 1)
    }
    let!(:priority_2) {
      FactoryGirl.create(:priority,
                         position: 2,
                         is_default: true)
    }

    before do
      assign(:priorities, [priority_0, priority_1, priority_2])
      render
    end

    subject { Nokogiri.XML(rendered) }

    it { expect(subject).to have_selector('planning_element_priorities planning_element_priority', count: 3) }

    context 'priority 0' do
      it 'has empty position' do
        expect(subject).to have_selector('planning_element_priorities planning_element_priority id', text: priority_0.id) do |tag|
          expect(tag.parent).to have_selector('position', text: nil)
        end
      end

      it 'has empty default setting' do
        expect(subject).to have_selector('planning_element_priorities planning_element_priority id', text: priority_0.id) do |tag|
          expect(tag.parent).to have_selector('is_default', text: nil)
        end
      end
    end

    context 'priority 1' do
      it 'has position' do
        expect(subject).to have_selector('planning_element_priorities planning_element_priority id', text: priority_1.id) do |tag|
          expect(tag.parent).to have_selector('position', text: priority_1.position)
        end
      end
    end

    context 'priority 2' do
      it 'has default value set' do
        expect(subject).to have_selector('planning_element_priorities planning_element_priority id', text: priority_2.id) do |tag|
          expect(tag.parent).to have_selector('position', text: priority_2.is_default)
        end
      end
    end
  end
end
