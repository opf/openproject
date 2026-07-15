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

RSpec.describe WorkPackage::Exports::Formatters::Type do
  describe ".apply?" do
    it "applies to the :type attribute for every export format" do
      expect(described_class.apply?(:type, :csv)).to be(true)
      expect(described_class.apply?(:type, :xls)).to be(true)
      expect(described_class.apply?(:type, :pdf)).to be(true)
    end

    it "does not apply to other attributes" do
      expect(described_class.apply?(:status, :csv)).to be(false)
    end
  end

  describe "#format" do
    subject { described_class.new(:type).format(work_package) }

    context "for a sub-type" do
      let(:root_type) { build_stubbed(:type, name: "Task") }
      let(:work_package) { build_stubbed(:work_package, type: build_stubbed(:type, name: "Bug", parent: root_type)) }

      it "exports the root type's name" do
        expect(subject).to eq("Task")
      end
    end

    context "for a root type" do
      let(:work_package) { build_stubbed(:work_package, type: build_stubbed(:type, name: "Task")) }

      it "exports its own name" do
        expect(subject).to eq("Task")
      end
    end
  end
end
