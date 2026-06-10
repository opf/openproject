# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require_relative "visible_setup"

RSpec.describe WorkPackageCustomFields::Scopes::OnVisibleTypeAndProject do
  include_context "given a visible setup"

  describe ".on_visible_type_and_project" do
    subject { WorkPackageCustomField.on_visible_type_and_project(user) }

    it "returns custom fields for types that are enabled in projects the user can see" do
      expect(subject).to contain_exactly(type_enabled_and_member_cf, type_enabled_for_all_cf)
    end

    context "with project: provided" do
      subject { WorkPackageCustomField.on_visible_type_and_project(user, project: project_with_user_and_feature) }

      it "returns only fields enabled in the given project" do
        expect(subject).to contain_exactly(type_enabled_and_member_cf, type_enabled_for_all_cf)
      end

      context "when the project has a different type than where the CF is active" do
        subject { WorkPackageCustomField.on_visible_type_and_project(user, project: project_with_user_and_bug) }

        it "returns nothing" do
          expect(subject).to be_empty
        end
      end
    end
  end
end
