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

RSpec.describe Bim::IfcModels::SetAttributesService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[bim]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[bim]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[manage_ifc_models] }) }

  let(:other_user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = double("contract_class") # rubocop:disable RSpec/VerifiedDoubles

    allow(contract)
      .to receive(:new)
      .with(model, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) { double("contract_instance", validate: contract_valid, errors: contract_errors) } # rubocop:disable RSpec/VerifiedDoubles
  let(:contract_valid) { true }
  let(:contract_errors) { double("contract_errors") } # rubocop:disable RSpec/VerifiedDoubles
  let(:model_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model:,
                        contract_class:)
  end
  let(:call_attributes) { {} }
  let(:ifc_file) { FileHelpers.mock_uploaded_file(name: "model_2.ifc", content_type: "application/binary", binary: true) }
  let(:model) do
    create(:ifc_model, project:, uploader: other_user)
  end

  before do
    # required for the attachments
    login_as(user)
  end

  describe "call" do
    let(:call_attributes) do
      {
        project_id: other_project.id
      }
    end

    before do
      allow(model)
        .to receive(:valid?)
        .and_return(model_valid)

      allow(contract_instance)
        .to receive(:validate)
        .and_return(contract_valid)
    end

    subject { instance.call(call_attributes) }

    it "is successful" do
      expect(subject).to be_a_success
      expect(contract_instance).to have_received(:validate)
    end

    it "sets the attributes" do
      subject

      expect(model.attributes.slice(*model.changed).symbolize_keys)
        .to eql call_attributes.merge(uploader_id: user.id)
    end

    it "does not persist the model" do
      allow(model).to receive(:save)
      subject
      expect(model).not_to have_received(:save)
    end

    context "for a new record" do
      let(:model) do
        Bim::IfcModels::IfcModel.new project:
      end

      context "with an ifc_attachment" do
        let(:call_attributes) do
          {
            ifc_attachment: ifc_file
          }
        end

        it "is successful" do
          expect(subject).to be_a_success
        end

        it "sets the title to the attachment`s filename" do
          subject

          expect(model.title)
            .to eql "model_2"
        end

        it "sets the uploader to the attachment`s author (which is the current user)" do
          subject

          expect(model.uploader)
            .to eql user
        end
      end
    end

    context "when the attachment is too large", with_settings: { attachment_max_size: 1 } do
      let(:model) { Bim::IfcModels::IfcModel.new(project:) }
      let(:model_valid) { false }

      let(:call_attributes) do
        {
          ifc_attachment: ifc_file
        }
      end

      before do
        allow(ifc_file).to receive(:size).and_return(2.kilobytes)
      end

      it "returns a service result failure with the file size error message" do
        expect(subject).to be_a_failure
        expect(subject.errors[:attachments]).to eq(["is too large (maximum size is 1024 Bytes)."])

        aggregate_failures "skips the ifc model contract" do
          expect(contract_instance).not_to have_received(:validate)
        end
      end
    end

    context "for an existing model" do
      context "with an ifc_attachment" do
        let(:call_attributes) do
          {
            ifc_attachment: ifc_file
          }
        end

        it "is successful" do
          expect(subject).to be_a_success
        end

        it "does not alter the title" do
          title_before = model.title

          subject

          expect(model.title)
            .to eql title_before
        end

        it "sets the uploader to the attachment`s author (which is the current user)" do
          subject

          expect(model.uploader)
            .to eql user
        end

        it "marks existing attachments for destruction" do
          ifc_attachment = model.ifc_attachment

          subject

          expect(ifc_attachment)
            .to be_marked_for_destruction
        end
      end
    end
  end
end
