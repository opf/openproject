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

RSpec.describe OpenProject::CustomFieldFormatDependent do
  describe ".stimulus_config" do
    it "returns a json with expected structure" do
      expect(JSON.parse(described_class.stimulus_config)).to all match([be_a(String), be_a(String), all(be_a(String))])
    end
  end

  describe "#attributes" do
    let(:instance) { described_class.new(format) }
    let(:format) { "string" }

    subject(:call) { instance.attributes(target_name) }

    context "for targets using operator only" do
      let(:target_name) { :defaultLongText }

      context "for matching format" do
        let(:format) { "text" }

        it { is_expected.to be_html_safe & eq('data-admin--custom-fields-target="defaultLongText"') }
      end

      context "for non matching format" do
        it { is_expected.to be_html_safe & eq('data-admin--custom-fields-target="defaultLongText" hidden="hidden"') }
      end
    end

    context "for targets using operator except" do
      let(:target_name) { :defaultText }

      context "for matching format" do
        let(:format) { "text" }

        it { is_expected.to be_html_safe & eq('data-admin--custom-fields-target="defaultText" hidden="hidden"') }
      end

      context "for non matching format" do
        it { is_expected.to be_html_safe & eq('data-admin--custom-fields-target="defaultText"') }
      end
    end

    context "for unknown target" do
      let(:target_name) { :foo }

      it { expect { call }.to raise_error(ArgumentError) }
    end
  end
end
