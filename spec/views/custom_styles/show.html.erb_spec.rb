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

describe 'custom_styles/show', type: :view do
  let(:user) { FactoryBot.build(:admin) }

  before do
    login_as user
  end

  context "no custom logo yet" do
    before do
      assign(:custom_style, CustomStyle.new)
      assign(:current_theme, '')
      allow(view).to receive(:options_for_select).and_return('')
      render
    end

    it 'shows an upload button' do
      expect(rendered).to include "Upload"
    end
  end

  context "with existing custom logo" do
    before do
      assign(:custom_style, FactoryBot.build(:custom_style_with_logo))
      assign(:current_theme, '')
      allow(view).to receive(:options_for_select).and_return('')
      render
    end

    it 'shows a replace button' do
      expect(rendered).to include "Replace"
    end
  end
end
