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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe SprintGoal do
  let(:project) { create(:project) }
  let(:sprint) { create(:sprint, project:) }

  subject(:sprint_goal) do
    described_class.new(sprint:, project:, text: "Deliver reporting dashboard")
  end

  describe "associations" do
    it { is_expected.to belong_to(:sprint).inverse_of(:goals) }
    it { is_expected.to belong_to(:project) }
  end

  describe "normalization" do
    it { is_expected.to normalize(:text).from(" My awesome sprint\n").to("My awesome sprint") }
    it { is_expected.to normalize(:text).from("  \n").to(nil) }
  end

  describe "validations" do
    it "is valid with a sprint, project, and text" do
      expect(sprint_goal).to be_valid
    end

    it "is invalid without text" do
      sprint_goal.text = nil

      expect(sprint_goal).not_to be_valid
    end

    it "limits text to 500 characters" do
      sprint_goal.text = "a" * 501

      expect(sprint_goal).not_to be_valid
      expect(sprint_goal.errors).to be_added(:text, :too_long, count: 500)
    end

    it "validates uniqueness of project_id scoped to sprint_id" do
      sprint_goal.save!
      expect(sprint_goal).to validate_uniqueness_of(:project_id)
        .scoped_to(:sprint_id)
        .with_message(I18n.t("activerecord.errors.models.sprint_goal.project_already_has_goal"))
    end
  end
end
