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

RSpec.describe Queries::Capabilities::CapabilityQuery do
  let(:instance) { described_class.new }

  current_user do
    build_stubbed(:user)
  end

  describe "#valid?" do
    context "without filters" do
      it "is invalid" do
        expect(instance)
          .not_to be_valid
      end
    end

    context "with a principal filter having the `=` operator" do
      before do
        instance.where("principal_id", "=", ["1"])
      end

      it "is valid" do
        expect(instance)
          .to be_valid
      end
    end

    context "with a principal filter having the `!` operator" do
      before do
        instance.where("principal_id", "!", ["1"])
      end

      it "is invalid" do
        expect(instance)
          .not_to be_valid
      end
    end

    context "with a principal filter having the `=` operator but without values" do
      before do
        instance.where("principal_id", "=", [])
      end

      it "is invalid" do
        expect(instance)
          .not_to be_valid
      end
    end

    context "with a context filter having the `=` operator" do
      before do
        instance.where("context", "=", ["p1"])
      end

      it "is valid" do
        expect(instance)
          .to be_valid
      end
    end

    context "with a context filter having the `=` operator but without values" do
      before do
        instance.where("context", "=", [])
      end

      it "is invalid" do
        expect(instance)
          .not_to be_valid
      end
    end

    context "with a context filter having the `!` operator" do
      before do
        instance.where("context", "!", ["g"])
      end

      it "is invalid" do
        expect(instance)
          .not_to be_valid
      end
    end

    context "with a context filter having the `!` operator and also with a principal filter having the `=` operator" do
      before do
        instance.where("context", "!", ["g"])
        instance.where("principal_id", "=", ["1"])
      end

      it "is valid" do
        expect(instance)
          .to be_valid
      end
    end
  end
end
