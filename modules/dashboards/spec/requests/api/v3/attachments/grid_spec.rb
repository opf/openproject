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
require File.join(Rails.root, 'spec', 'requests', 'api', 'v3', 'attachments', 'attachment_resource_shared_examples')

describe "grid attachments" do
  before do
    Grids::Dashboard
  end

  it_behaves_like "an APIv3 attachment resource" do
    let(:attachment_type) { :grid }

    let(:create_permission) { :manage_dashboards }
    let(:read_permission) { :view_dashboards }
    let(:update_permission) { :manage_dashboards }

    let(:grid) { FactoryBot.create(:dashboard, project: project) }

    let(:missing_permissions_user) { FactoryBot.create(:user) }
  end
end
