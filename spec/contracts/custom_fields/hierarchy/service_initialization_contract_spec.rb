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

require "rails_helper"

RSpec.describe CustomFields::Hierarchy::ServiceInitializationContract do
  subject { described_class.new }

  # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
  describe "#call" do
    context "when field_format is 'hierarchy'" do
      let(:params) { { field_format: "hierarchy" } }

      it "is valid" do
        result = subject.call(params)
        expect(result).to be_success
      end
    end

    context "when field_format is not 'hierarchy'" do
      let(:params) { { field_format: "text" } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(field_format: ["Custom field must have field format 'hierarchy'"])
      end
    end

    context "when field_format is missing" do
      let(:params) { {} }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(field_format: ["is missing"])
      end
    end

    context "when field_format is nil" do
      let(:params) { { field_format: nil } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(field_format: ["must be filled"])
      end
    end

    context "when inputs are valid" do
      it "creates a success result" do
        [
          { field_format: "hierarchy" }
        ].each { |params| expect(subject.call(params)).to be_success }
      end
    end

    context "when inputs are invalid" do
      it "creates a failure result" do
        [
          {},
          { field_format: "text" },
          { field_format: nil },
          { field_format: 42 }
        ].each { |params| expect(subject.call(params)).to be_failure }
      end
    end
  end
  # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
end
