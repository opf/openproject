# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative "attachment_resource_shared_examples"

RSpec.describe "Activity comment attachments" do
  it_behaves_like "an APIv3 attachment resource" do
    let(:work_package) do
      create(:work_package, author: current_user, project:)
    end

    let(:activity) do
      work_package.add_journal(user: current_user, notes: "A comment")
      work_package.save(validate: false)
      work_package.journals.last
    end

    let(:attachment_type) { :activity }

    let(:create_permission) { :add_work_package_comments }
    let(:read_permission) { :view_work_packages }
    let(:update_permission) { :edit_own_work_package_comments }
  end

  context "with a internal journal" do
    it_behaves_like "an APIv3 attachment resource" do
      let(:work_package) do
        create(:work_package, author: current_user, project:)
      end

      let(:activity) do
        work_package.add_journal(user: current_user, notes: "Need to know!", internal: true)
        work_package.save(validate: false)
        work_package.journals.last
      end

      let(:attachment_type) { :activity }

      let(:create_permission) { %i[add_work_package_comments add_internal_comments] }
      let(:read_permission) { %i[view_work_packages view_internal_comments] }
      let(:update_permission) { %i[edit_own_work_package_comments edit_own_internal_comments] }
    end
  end
end
