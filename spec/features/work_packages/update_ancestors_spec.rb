# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

RSpec.describe 'Update ancestors', :js, :with_cuprite do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:parent) do
    create(:work_package,
           project:,
           subject: 'parent',
           estimated_hours: 2,
           remaining_hours: 1)
  end
  shared_let(:child) do
    create(:work_package,
           project:,
           parent:,
           subject: 'child',
           estimated_hours: 6,
           remaining_hours: 3)
  end
  shared_let(:query) do
    create(:query,
           user:,
           project:,
           show_hierarchies: true,
           column_names: %i[id estimated_hours remaining_hours subject])
  end

  let(:wp_table) { Pages::WorkPackagesTable.new project }

  before do
    # make sure the derived fields are initially displayed right
    WorkPackages::UpdateAncestorsService
      .new(user:, work_package: child)
      .call(%i[estimated_hours remaining_hours])

    login_as(user)
    wp_table.visit_query query
  end

  context 'when changing the child work and remaining work values' do
    it 'updates the parent work and remaining work values' do
      expect do
        wp_table.update_work_package_attributes(child, estimatedTime: child.estimated_hours + 1)
        parent.reload
      end.to change(parent, :derived_estimated_hours).by(1)
      expect do
        wp_table.update_work_package_attributes(child, remainingTime: child.remaining_hours + 2)
        parent.reload
      end.to change(parent, :derived_remaining_hours).by(2)
    end
  end

  context 'when deleting the child' do
    it 'updates the parent work and remaining work values' do
      context_menu = wp_table.open_context_menu_for(child)
      context_menu.choose_delete_and_confirm_deletion

      parent.reload
      expect(parent.derived_estimated_hours).to eq(parent.estimated_hours)
      expect(parent.derived_remaining_hours).to eq(parent.remaining_hours)
    end
  end
end
