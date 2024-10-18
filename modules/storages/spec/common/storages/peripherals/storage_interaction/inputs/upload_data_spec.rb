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
require_module_spec_helper

RSpec.describe Storages::Peripherals::StorageInteraction::Inputs::UploadData do
  subject(:input) { described_class }

  it "has .new as a private method" do
    expect { input.new(nil, nil) }.to raise_error NoMethodError
  end

  it "returns a Success(UploadData)" do
    result = input.build(folder_id: "1337", file_name: "i_am_file_with_a_name.txt")

    expect(result).to be_success
    upload_data = result.value!
    expect(upload_data.folder_id).to eq("1337")
    expect(upload_data.file_name).to eq("i_am_file_with_a_name.txt")
  end

  context "when invalid" do
    context "with a nil file name" do
      let(:kwargs) { { folder_id: "42", file_name: nil } }

      it "returns a failure" do
        result = input.build(**kwargs)
        expect(result).to be_failure
      end

      it "contains the specific error" do
        validation_result = input.build(**kwargs).failure
        expect(validation_result.errors[:file_name]).to eq(["must be filled"])
      end
    end

    context "with a empty file name" do
      let(:kwargs) { { folder_id: "42", file_name: "" } }

      it "returns a failure" do
        result = input.build(**kwargs)
        expect(result).to be_failure
      end

      it "contains the specific error" do
        validation_result = input.build(**kwargs).failure
        expect(validation_result.errors[:file_name]).to eq(["must be filled"])
      end
    end

    context "with an empty folder_id" do
      let(:kwargs) { { folder_id: "", file_name: "file_name.txt" } }

      it "returns a failure" do
        result = input.build(**kwargs)
        expect(result).to be_failure
      end

      it "contains the specific error" do
        validation_result = input.build(**kwargs).failure
        expect(validation_result.errors[:folder_id]).to eq(["must be filled"])
      end
    end

    context "with a nil folder id" do
      let(:kwargs) { { folder_id: nil, file_name: "file_name.txt" } }

      it "returns a failure" do
        result = input.build(**kwargs)
        expect(result).to be_failure
        expect(result.failure.errors[:folder_id]).to eq(["must be filled"])
      end
    end
  end
end
