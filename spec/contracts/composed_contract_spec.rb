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

RSpec.describe ComposedContract do
  subject(:composed_contract) do
    # Binding methods to local variables so they are accessible inside the newly defined class
    a = contract_class_a
    b = contract_class_b
    Class.new(described_class) do
      include_contract a
      include_contract b
    end.new(model, user)
  end

  let(:contract_class_a) do
    Class.new(ModelContract) do
      attribute :subject
      validates :subject, format: /B/
    end
  end
  let(:contract_class_b) do
    Class.new(ModelContract) do
      attribute :description
      validates :description, format: /E/
    end
  end

  let(:model) do
    create :work_package
  end
  let(:title) { "ABC" }
  let(:description) { "DEF" }

  let(:user) { build(:user) }

  before do
    model.save!
    model.assign_attributes(subject: title, description:)
  end

  it { is_expected.to be_valid }

  context "when contract A is invalid" do
    let(:title) { "XYZ" }

    it { is_expected.not_to be_valid }
  end

  context "when contract B is invalid" do
    let(:description) { "XYZ" }

    it { is_expected.not_to be_valid }
  end

  context "when changing an attribute not allowed by any subcontract" do
    before do
      model.done_ratio = 50
    end

    it { is_expected.not_to be_valid }

    context "and when the attribute was allowed on the composed contract" do
      before do
        composed_contract.writable_attributes << "done_ratio"
      end

      it { is_expected.to be_valid }
    end
  end
end
