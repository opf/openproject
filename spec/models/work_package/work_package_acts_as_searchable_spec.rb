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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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

    describe "with a searchable list custom field" do
      let(:list_field) { create(:list_wp_custom_field, searchable: true, possible_values: %w[Aubergine]) }
      let(:text_field) { create(:text_wp_custom_field, searchable: true) }
      let(:aubergine) { list_field.possible_values.first }
      let(:type) { create(:type_task, custom_fields: [list_field, text_field]) }
      let(:project) { create(:project, types: [type], work_package_custom_fields: [list_field, text_field]) }

      before do
        allow(User).to receive(:current).and_return user
        become_member_with_permissions(project, user, :view_work_packages)
      end

      it "finds a work package by the label of its list value" do
        listed = create(:work_package, type:, project:, custom_values: { list_field.id => aubergine.id })

        expect(described_class.search(%w[aubergine]).first).to include(listed)
      end

      it "does not match the label against another field's value that equals the item id" do
        create(:work_package, type:, project:, custom_values: { text_field.id => aubergine.id.to_s })

        expect(described_class.search(%w[aubergine]).first).to be_empty
      end
    end
  end
end
