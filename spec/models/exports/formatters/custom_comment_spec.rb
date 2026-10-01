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

require "spec_helper"

RSpec.describe Exports::Formatters::CustomComment do
  describe ".apply?" do
    it "applies to custom comment attributes" do
      expect(described_class.apply?("cfc_1", :csv)).to be(true)
      expect(described_class.apply?("cfc_1", :foo)).to be(true)
    end

    it "does not apply to non comment attributes" do
      expect(described_class.apply?("cf_1", :csv)).to be(false)
    end
  end

  describe "#format" do
    let(:project) { build(:project) }
    let(:custom_field) { build(:project_custom_field, id: 42) }

    subject(:formatter) { described_class.new("cfc_42") }

    before do
      allow(project).to receive(:available_custom_fields).and_return(available_custom_fields)
    end

    context "with a comment present" do
      let(:available_custom_fields) { [custom_field] }
      let(:comment) { build(:custom_comment, customized: project, custom_field:, text: "Hello, World!") }

      before do
        allow(project).to receive(:custom_comment_for).with(custom_field).and_return(comment)
      end

      it "returns the comment text" do
        expect(formatter.format(project)).to eq("Hello, World!")
      end
    end

    context "with no comment" do
      let(:available_custom_fields) { [custom_field] }

      before do
        allow(project).to receive(:custom_comment_for).with(custom_field).and_return(nil)
      end

      it "returns an empty string" do
        expect(formatter.format(project)).to eq("")
      end
    end

    context "with a missing custom field" do
      let(:available_custom_fields) { [] }

      it "returns an empty string" do
        expect(formatter.format(project)).to eq("")
      end
    end
  end
end
