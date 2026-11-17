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

RSpec.describe WorkPackage, "acts_as_searchable" do
  include BecomeMember

  let(:wp_subject) { "the quick brown fox jumps over the lazy dog" }
  let(:project) do
    create(:project,
           public: false)
  end
  let(:work_package) do
    create(:work_package,
           subject: wp_subject,
           project:)
  end
  let(:user) { create(:user) }

  describe "#search" do
    describe "with the user being logged in " \
             "with searching for a matching string " \
             "with being member with the appropriate permission" do
      before do
        work_package
        allow(User).to receive(:current).and_return user

        become_member_with_permissions(project, user, :view_work_packages)
      end

      it "returns the work package" do
        expect(WorkPackage.search(wp_subject.split).first).to include(work_package)
      end
    end

    describe "with the user being logged in " \
             "with being member with the appropriate permission " \
             "with searching for matching string " \
             "with searching with an offset" do
      # this offset recreates the way the time is transformed in the controller
      # This will have to be cleaned up
      let(:offset) { (work_package.created_at - 1.minute).strftime("%Y%m%d%H%M%S").to_time }

      before do
        work_package
        allow(User).to receive(:current).and_return user

        become_member_with_permissions(project, user, :view_work_packages)
      end

      it "returns the work package if the offset is before the work packages created at value" do
        expect(WorkPackage.search(wp_subject.split, nil, offset:).first).to include(work_package)
      end
    end

    describe "with a searchable list custom field with project-specific values" do
      let(:type) { create(:type) }
      let(:project) { create(:project, public: false, types: [type]) }
      let(:custom_field) do
        create(:list_wp_custom_field, :project_specific_allowlist,
               types: [type], searchable: true, possible_values: %w[Acme Oscorp])
      end
      let(:acme) { custom_field.custom_options.find_by!(value: "Acme") }
      let(:oscorp) { custom_field.custom_options.find_by!(value: "Oscorp") }
      let!(:acme_work_package) do
        create(:work_package, project:, type:, custom_values: { custom_field.id => acme.id.to_s })
      end
      let!(:oscorp_work_package) do
        create(:work_package, project:, type:, custom_values: { custom_field.id => oscorp.id.to_s })
      end

      before do
        create(:project_specific_value_restriction, project:, custom_option: acme)
        allow(User).to receive(:current).and_return user

        become_member_with_permissions(project, user, :view_work_packages)
      end

      it "finds the work package by an option usable in its project" do
        expect(described_class.search(["Acme"]).first).to contain_exactly(acme_work_package)
      end

      it "does not find the work package by an option no longer usable in its project" do
        expect(described_class.search(["Oscorp"]).first).to be_empty
      end
    end
  end
end
