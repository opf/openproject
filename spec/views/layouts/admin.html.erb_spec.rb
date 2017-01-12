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

describe 'layouts/admin', type: :view do
  include Redmine::MenuManager::MenuHelper
  helper Redmine::MenuManager::MenuHelper

  let(:admin) { FactoryGirl.create :admin }

  before do
    allow(view).to receive(:current_menu_item).and_return('overview')
    allow(view).to receive(:default_breadcrumb)
    allow(controller).to receive(:default_search_scope)

    allow(User).to receive(:current).and_return admin
    allow(view).to receive(:current_user).and_return admin
    allow(view)
      .to receive(:render_to_string)
  end

  # All password-based authentication is to be hidden and disabled if
  # `disable_password_login` is true. This includes LDAP.
  describe 'LDAP authentication menu entry' do
    context 'with password login enabled' do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)
        render
      end

      it 'is shown' do
        expect(rendered).to have_selector('a', text: I18n.t('label_ldap_authentication'))
      end
    end

    context 'with password login disabled' do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        render
      end

      it 'is hidden' do
        expect(rendered).not_to have_selector('a', text: I18n.t('label_ldap_authentication'))
      end
    end
  end
end
