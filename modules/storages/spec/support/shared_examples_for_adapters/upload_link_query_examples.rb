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

RSpec.shared_examples_for "upload_link_query: basic query setup" do
  it "is registered as queries.upload_link" do
    expect(Storages::Peripherals::Registry
             .resolve("#{storage.short_provider_type}.queries.upload_link")).to eq(described_class)
  end

  it "responds to #call with correct parameters" do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage],
                                                 %i[keyreq auth_strategy],
                                                 %i[keyreq upload_data])
  end
end

RSpec.shared_examples_for "upload_link_query: successful upload link response" do
  it "returns an upload link" do
    result = described_class.call(storage:, auth_strategy:, upload_data:)

    expect(result).to be_success

    response = result.result
    expect(response).to be_a(Storages::UploadLink)
    expect(response.destination).to be_a(URI)
    expect(response.destination.to_s).to eq(upload_url)
    expect(response.method).to eq(upload_method)
  end
end

RSpec.shared_examples_for "upload_link_query: not found" do
  it "returns a failure" do
    result = described_class.call(storage:, auth_strategy:, upload_data:)

    expect(result).to be_failure

    error = result.errors
    expect(error.code).to eq(:not_found)
    expect(error.data.source).to eq(error_source)
  end
end

RSpec.shared_examples_for "upload_link_query: error" do
  it "returns a failure" do
    result = described_class.call(storage:, auth_strategy:, upload_data:)

    expect(result).to be_failure

    error = result.errors
    expect(error.code).to eq(:error)
    expect(error.data.source).to eq(error_source)
  end
end

RSpec.shared_examples_for "upload_link_query: validating input data" do
  let(:upload_data) { Storages::UploadData.new(folder_id:, file_name:) }
  let(:error_source) { described_class }

  context "if folder id being empty" do
    let(:folder_id) { "" }
    let(:file_name) { "DeathStart_blueprints.tiff" }

    it_behaves_like "upload_link_query: error"
  end

  context "if folder id being nil" do
    let(:folder_id) { nil }
    let(:file_name) { "DeathStart_blueprints.tiff" }

    it_behaves_like "upload_link_query: error"
  end

  context "if file name being empty" do
    let(:folder_id) { "42" }
    let(:file_name) { "" }

    it_behaves_like "upload_link_query: error"
  end

  context "if file name being nil" do
    let(:folder_id) { "42" }
    let(:file_name) { nil }

    it_behaves_like "upload_link_query: error"
  end
end
