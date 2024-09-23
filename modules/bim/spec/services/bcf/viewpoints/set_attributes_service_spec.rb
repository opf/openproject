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

RSpec.describe Bim::Bcf::Viewpoints::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = double("contract_class")

    allow(contract)
      .to receive(:new)
      .with(viewpoint, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    double("contract_instance", validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    double("contract_errors")
  end
  let(:viewpoint_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model: viewpoint,
                        contract_class:)
  end
  let(:call_attributes) { {} }
  let(:viewpoint) do
    Bim::Bcf::Viewpoint.new
  end

  before do
    allow(viewpoint)
      .to receive(:attachments_addable?)
      .with(user, any_args)
      .and_return true
  end

  describe "call" do
    # We only expect the service to be called for new records. As viewpoints
    # are immutable.
    context "for a new record" do
      let(:call_attributes) do
        attributes = attributes_for(:bcf_viewpoint)
        attributes[:json_viewpoint].delete("guid")
        attributes[:json_viewpoint]["snapshot"] = {
          "snapshot_type" => "png",
          "snapshot_data" => "data:image/png;base64,SGVsbG8gV29ybGQh"
        }
        attributes
      end

      before do
        allow(viewpoint)
          .to receive(:valid?)
          .and_return(viewpoint_valid)

        expect(contract_instance)
          .to receive(:validate)
          .and_return(contract_valid)
      end

      subject { instance.call(call_attributes) }

      it "is successful" do
        expect(subject.success?).to be_truthy
      end

      it "sets the attributes with the uuid added to the json_viewpoint" do
        subject

        expected_attributes = attributes_for(:bcf_viewpoint)
        expected_attributes[:json_viewpoint]["guid"] = viewpoint.uuid
        expected_attributes[:json_viewpoint]["snapshot"] = {
          "snapshot_type" => "png",
          "snapshot_data" => "data:image/png;base64,SGVsbG8gV29ybGQh"
        }

        expect(viewpoint.attributes.slice(*viewpoint.changed).symbolize_keys)
          .to eql expected_attributes
      end

      it "sets the snapshot attachment based on the data in the json_viewpoint" do
        subject

        expect(viewpoint.attachments.size)
          .to be 1

        expect(viewpoint.attachments.first.file.read)
          .to eql "Hello World!"

        expect(viewpoint.attachments.first.filename)
          .to eql "snapshot.png"
      end

      it "does not persist the viewpoint" do
        expect(viewpoint)
          .not_to receive(:save)

        subject
      end

      context "with an unsupported snapshot type" do
        let(:call_attributes) do
          attributes = attributes_for(:bcf_viewpoint)
          attributes[:json_viewpoint].delete("guid")
          attributes[:json_viewpoint]["snapshot"] = {
            "snapshot_type" => "tif",
            "snapshot_data" => "data:image/png;base64,SGVsbG8gV29ybGQh"
          }
          attributes
        end

        it "sets no snapshot attachment" do
          subject

          expect(viewpoint.attachments.size)
            .to be 0
        end
      end
    end
  end
end
