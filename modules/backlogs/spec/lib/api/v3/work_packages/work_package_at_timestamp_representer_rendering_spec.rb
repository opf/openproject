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

# Only tests the links/properties added by the backlogs plugin. It does not
# retest the properties already covered in the core.
RSpec.describe API::V3::WorkPackages::WorkPackageAtTimestampRepresenter, "rendering" do
  let(:current_user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project, enabled_module_names: %w[backlogs]) }
  let(:type) { create(:type) }
  let(:work_package) do
    build_stubbed(:work_package, project:, type:, story_points: 5)
  end

  let(:model) do
    work_package.tap do |model|
      without_partial_double_verification do
        allow(model)
          .to receive_messages(timestamp: Timestamp.new(1.day.ago),
                               attributes_changed_to_baseline:,
                               exists_at_timestamp?: true,
                               with_query?: true,
                               matches_filters_at_timestamp?: true,
                               exists_at_current_timestamp?: true)
      end
    end
  end

  subject(:generated) { described_class.create(model, current_user:).to_json }

  include_context "eager loaded work package representer"

  describe "storyPoints" do
    context "with story points changed" do
      let(:attributes_changed_to_baseline) { %w[story_points] }

      it "renders the story points" do
        expect(generated).to be_json_eql(5.to_json).at_path("storyPoints")
      end
    end

    context "with story points unchanged" do
      let(:attributes_changed_to_baseline) { %w[subject] }

      it "does not render the story points" do
        expect(generated).not_to have_json_path("storyPoints")
      end
    end
  end
end
