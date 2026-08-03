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
require_relative "../shared_expectations"

RSpec.describe CustomActions::Conditions::Type do
  it_behaves_like "associated custom condition" do
    let(:key) { :type }

    describe "#allowed_values" do
      it "is the list of root types, variants being collapsed into them" do
        root = create(:type, name: "Task")
        create(:type, name: "Bug", parent: root)

        expect(instance.allowed_values)
          .to eql([{ value: root.id, label: "Task" }])
      end
    end

    describe "#values=" do
      it "folds a variant configured before into its root" do
        root = create(:type)
        variant = create(:type, parent: root)

        instance.values = [variant.id]

        expect(instance.values).to eql [root.id]
      end
    end

    describe "#fulfilled_by?" do
      shared_let(:root) { create(:type) }
      shared_let(:variant) { create(:type, parent: root) }
      shared_let(:unrelated) { create(:type) }

      let(:user) { double("not relevant") }

      def naming_root_fulfilled_by?(type)
        described_class.new([root.id]).fulfilled_by?(build_stubbed(:work_package, type:), user)
      end

      it "is true if values are empty" do
        instance.values = []

        expect(instance).to be_fulfilled_by(build_stubbed(:work_package, type: unrelated), user)
      end

      it "is true for the type it names" do
        expect(naming_root_fulfilled_by?(root)).to be true
      end

      # The work package's project may run any member of the family, and users picked the
      # family when they picked the type.
      it "is true for a variant of the type it names" do
        expect(naming_root_fulfilled_by?(variant)).to be true
      end

      it "is false for a type of another family" do
        expect(naming_root_fulfilled_by?(unrelated)).to be false
      end
    end
  end
end
