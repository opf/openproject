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

RSpec.describe CustomValue::FormatStrategy do
  let(:custom_value) do
    double("CustomValue",
           value:)
  end

  describe "#value_present?" do
    subject { described_class.new(custom_value).value_present? }

    context "value is nil" do
      let(:value) { nil }

      it { is_expected.to be(false) }
    end

    context "value is empty string" do
      let(:value) { "" }

      it { is_expected.to be(false) }
    end

    context "value is present string" do
      let(:value) { "foo" }

      it { is_expected.to be(true) }
    end

    context "value is present integer" do
      let(:value) { 42 }

      it { is_expected.to be(true) }
    end
  end
end
