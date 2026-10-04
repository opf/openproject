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

require "rails_helper"

RSpec.describe Project::PhaseDefinition do
  it "can be instantiated" do
    expect { described_class.new }.not_to raise_error
  end

  it "returns its name" do
    expect(subject.to_s).to eq(subject.name)
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "associations" do
    it "has many phases" do
      expect(subject).to have_many(:phases).class_name("Project::Phase")
                                           .with_foreign_key(:definition_id)
                                           .inverse_of(:definition)
                                           .dependent(:destroy)
    end

    it { is_expected.to have_many(:projects).through(:phases) }
    it { is_expected.to belong_to(:color).required }
    it { is_expected.to have_many(:work_packages) }
  end
end
