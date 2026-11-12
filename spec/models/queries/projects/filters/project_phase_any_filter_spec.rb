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

RSpec.describe Queries::Projects::Filters::ProjectPhaseAnyFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :project_phase_any }
    let(:type) { :date }
    let(:model) { Project }
    let(:human_name) { I18n.t("project.filters.project_phase_any") }

    describe "default_operator" do
      it "is 'today'" do
        expect(instance.default_operator)
          .to eql Queries::Operators::Today
      end
    end

    describe "#available?" do
      let(:project) { build_stubbed(:project) }
      let(:user) { build_stubbed(:user) }

      current_user { user }

      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(*permissions, project:)
        end
      end

      context "for a user with the necessary permission" do
        let(:permissions) { %i[view_project_phases] }

        it "is true" do
          expect(instance)
            .to be_available
        end
      end

      context "for a user without the necessary permission" do
        let(:permissions) { %i[view_project] }

        it "is false" do
          expect(instance)
            .not_to be_available
        end
      end
    end
  end
end
