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

require 'spec_helper'

describe 'form configuration', type: :feature, js: true do
  let(:current_user) { FactoryGirl.create :admin }
  let(:type) { FactoryGirl.create :type, attribute_visibility: attribute_visibility }

  let(:attribute_visibility) do
    {
      'version' => 'hidden',
      'status' => 'default',
      'priority' => 'visible'
      # assignee => 'default'
      # not defined attributes shall get default visibility
    }
  end

  def selector(attribute, visibility)
    "input#type_attribute_visibility_#{visibility}_#{attribute}"
  end

  before do
    allow(User).to receive(:current).and_return current_user

    visit edit_type_path(id: type.id)
  end

  shared_examples 'attribute visibility' do
    let(:attribute) { 'status' }
    let(:visibility) { 'default' }

    it 'is displayed correctly' do
      if visibility == 'hidden'
        all(selector(attribute, 'default')).each { |cb| expect(cb).not_to be_checked }
        all(selector(attribute, 'visible')).each { |cb| expect(cb).not_to be_checked }
      elsif visibility == 'default'
        all(selector(attribute, 'default')).each { |cb| expect(cb).to be_checked }
        all(selector(attribute, 'visible')).each { |cb| expect(cb).not_to be_checked }
      elsif visibility == 'visible'
        all(selector(attribute, 'default')).each { |cb| expect(cb).to be_checked }
        all(selector(attribute, 'visible')).each { |cb| expect(cb).to be_checked }
      end
    end
  end

  describe 'before update' do
    it_behaves_like 'attribute visibility' do
      let(:attribute) { 'version' }
      let(:visibility) { 'hidden' }
    end

    it_behaves_like 'attribute visibility' do
      let(:attribute) { 'status' }
      let(:visibility) { 'default' }
    end

    it_behaves_like 'attribute visibility' do
      let(:attribute) { 'priority' }
      let(:visibility) { 'visible' }
    end
  end

  describe 'after update' do
    before do
      # change to visible by checking both checkboxes
      find(:css, selector('version', 'default')).set(true)
      find(:css, selector('version', 'visible')).set(true)

      # change to hidden by unchecking both checkboxes
      find(:css, selector('status', 'default')).set(false)
      find(:css, selector('status', 'visible')).set(false)

      # change to default by unchecking last checkbox
      find(:css, selector('priority', 'visible')).set(false)

      click_on 'Save'
    end

    it 'the type visibilities are set correctly' do
      type.reload

      expect(type.attribute_visibility['version']).to eq 'visible'
      expect(type.attribute_visibility['status']).to eq 'hidden'
      expect(type.attribute_visibility['priority']).to eq 'default'
    end

    it_behaves_like 'attribute visibility' do
      let(:attribute) { 'version' }
      let(:visibility) { 'visible' }
    end

    it_behaves_like 'attribute visibility' do
      let(:attribute) { 'status' }
      let(:visibility) { 'hidden' }
    end

    it_behaves_like 'attribute visibility' do
      let(:attribute) { 'priority' }
      let(:visibility) { 'default' }
    end

    it_behaves_like 'attribute visibility' do
      let(:attribute) { 'assignee' }
      let(:visibility) { 'default' }
    end
  end
end
