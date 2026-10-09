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

RSpec.shared_examples_for "has a permission_granted? check for rendering details" do
  # The #permission_granted? method is used by the JournalFormatter#render_detail
  # to check whether the user has the permission to see the rendered activity.
  describe "#permission_granted?" do
    subject { instance.permission_granted?(permission, key:) }

    context "with a Proc permission" do
      context "when the proc, receiving the resolved custom field, allows" do
        let(:permission) do
          expected_custom_field = custom_field
          ->(field) { field == expected_custom_field }
        end

        it { is_expected.to be(true) }
      end

      context "when the proc, receiving the resolved custom field, denies" do
        let(:permission) do
          expected_custom_field = custom_field
          ->(field) { field != expected_custom_field }
        end

        it { is_expected.to be(false) }
      end
    end

    context "with a named (Symbol) permission" do
      let(:permission) { :view_project }
      let(:project) { build_stubbed(:project) }
      let(:journal) { instance_double(Journal, project:) }

      before do
        mock_permissions_for(User.current) do |mock|
          mock.allow_in_project(*permissions, project:)
        end
      end

      context "when the current user has the permission in the project" do
        let(:permissions) { [:view_project] }

        it { is_expected.to be(true) }
      end

      context "when the current user lacks the permission in the project" do
        let(:permissions) { [] }

        it { is_expected.to be(false) }
      end
    end
  end
end
