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

describe 'types/edit', type: :view do
  let(:admin) { FactoryGirl.create :admin }
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

  shared_examples 'attribute visibility' do
    let(:attribute) { 'status' }
    let(:visibility) { 'default' }

    it 'is shown correctly' do
      expect(rendered).to have_xpath(
        "//input[@name='type[attribute_visibility][#{attribute}]' and @value='hidden']")

      default_op = visibility == 'default' || visibility == 'visible' ? '=' : '!='
      visible_op = visibility == 'visible' ? '=' : '!='

      sel_prefix = "//input[@id='type_attribute_visibility"
      default_sel = "#{sel_prefix}_default_#{attribute}' and @value='default'"
      visible_sel = "#{sel_prefix}_visible_#{attribute}' and @value='visible'"
      and_checked = " and @checked='checked'"

      if visibility == 'visible'
        # both default and visible should be checked
        expect(rendered).to have_xpath(default_sel + and_checked + ']')
        expect(rendered).to have_xpath(visible_sel + and_checked + ']')
      elsif visibility == 'default'
        # default should be checked, visible should not
        expect(rendered).to have_xpath(default_sel + and_checked + ']')
        expect(rendered).to have_xpath(visible_sel + ']')
        expect(rendered).not_to have_xpath(visible_sel + and_checked + ']')
      elsif visibility == 'hidden'
        # neither default nor visible should be checked
        expect(rendered).not_to have_xpath(default_sel + and_checked + ']')
        expect(rendered).not_to have_xpath(visible_sel + and_checked + ']')
      end
    end
  end

  before do
    allow(User).to receive(:current).and_return admin
    allow(view).to receive(:current_user).and_return admin

    assign(:type, type)
    assign(:projects, [])

    render
  end

  describe 'form' do
    it 'shows the form configuration section' do
      expect(rendered).to include ('Form configuration')
    end

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

    # just checking one examplary attribute out of all the others
    it_behaves_like 'attribute visibility' do
      let(:attribute) { 'assignee' }
      let(:visibility) { 'default' }
    end
  end
end
