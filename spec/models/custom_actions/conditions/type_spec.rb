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
      it "is the list of all types" do
        types = [build_stubbed(:type),
                 build_stubbed(:type)]
        allow(Type)
          .to receive(:select)
          .and_return(types)

        expect(instance.allowed_values)
          .to eql([{ value: types.first.id, label: types.first.name },
                   { value: types.last.id, label: types.last.name }])
      end
    end

    describe "#fulfilled_by?" do
      let(:work_package) { double("work_package", type_id: 1) }
      let(:user) { double("not relevant") }

      it "is true if values are empty" do
        instance.values = []

        expect(instance.fulfilled_by?(work_package, user))
          .to be_truthy
      end

      it "is true if values include work package's type_id" do
        instance.values = [1]

        expect(instance.fulfilled_by?(work_package, user))
          .to be_truthy
      end

      it "is false if values do not include work package's type_id" do
        instance.values = [5]

        expect(instance.fulfilled_by?(work_package, user))
          .to be_falsey
      end
    end
  end
end
