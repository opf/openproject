#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"
require_relative "attachment_resource_shared_examples"

RSpec.describe "work package attachments" do
  it_behaves_like "an APIv3 attachment resource" do
    let(:attachment_type) { :work_package }

    let(:create_permission) { :add_work_packages }
    let(:read_permission) { :view_work_packages }
    let(:update_permission) { :edit_work_packages }

    let(:work_package) do
      create(:work_package, author: current_user, project:)
    end
  end

  context "with :add_work_package_attachments as update permission" do
    it_behaves_like "an APIv3 attachment resource" do
      let(:attachment_type) { :work_package }

      let(:create_permission) { :add_work_packages }
      let(:read_permission) { :view_work_packages }
      let(:update_permission) { :add_work_package_attachments }
      let(:delete_permission) { :edit_work_packages }

      let(:work_package) do
        create(:work_package, author: current_user, project:)
      end
    end
  end
end
