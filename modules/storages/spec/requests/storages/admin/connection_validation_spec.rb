#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe "connection validation", :skip_csrf do
  describe "POST /admin/settings/storages/:id/connection_validation/validate_connection" do
    let(:storage) { create(:one_drive_storage) }
    let(:user) { create(:admin) }
    let(:validator) do
      double = instance_double(Storages::Peripherals::OneDriveConnectionValidator)
      allow(double).to receive_messages(validate: validation_result)
      double
    end

    current_user { user }

    before do
      allow(Storages::Peripherals::OneDriveConnectionValidator).to receive(:new).and_return(validator)
    end

    subject do
      post validate_connection_admin_settings_storage_connection_validation_path(storage.id, format: :turbo_stream)
    end

    shared_examples_for "a validation result template" do |show_timestamp:, label:, description:|
      it "returns a turbo update template" do
        expect(subject.status).to eq(200)

        doc = Nokogiri::HTML(subject.body)
        expect(doc.xpath(xpath_for_subtitle).text).to eq("Connection validation")

        if show_timestamp
          expect(doc.xpath(xpath_for_timestamp)).not_to be_empty
        else
          expect(doc.xpath(xpath_for_timestamp)).to be_empty
        end

        if label.present?
          expect(doc.xpath(xpath_for_label).text).to eq(label)
        else
          expect(doc.xpath(xpath_for_label).text).to be_empty
        end

        if description.present?
          expect(doc.xpath(xpath_for_description).text).to eq(description)
        else
          expect(doc.xpath(xpath_for_description).text).to be_empty
        end
      end
    end

    context "if the a validation result of type :none (no validation executed) is returned" do
      let(:validation_result) do
        Storages::ConnectionValidation.new(type: :none, timestamp: Time.current, description: "not configured")
      end

      it_behaves_like "a validation result template", show_timestamp: false, label: nil, description: "not configured"
    end

    context "if validator returns an error" do
      let(:validation_result) do
        Storages::ConnectionValidation.new(type: :error, timestamp: Time.current, description: "An error occurred")
      end

      it_behaves_like "a validation result template",
                      show_timestamp: true, label: "Error", description: "An error occurred"
    end

    context "if validator returns a warning" do
      let(:validation_result) do
        Storages::ConnectionValidation.new(type: :warning,
                                           timestamp: Time.current,
                                           description: "There is something weird...")
      end

      it_behaves_like "a validation result template",
                      show_timestamp: true, label: "Warning", description: "There is something weird..."
    end

    context "if validator returns a success" do
      let(:validation_result) do
        Storages::ConnectionValidation.new(type: :healthy, timestamp: Time.current, description: nil)
      end

      it_behaves_like "a validation result template",
                      show_timestamp: true, label: "Healthy", description: nil
    end
  end

  private

  # rubocop:disable Layout/LineLength
  def xpath_for_subtitle
    "//turbo-stream[@target='connection_validation_result']/template/div/div/span[@data-test-selector='validation-result--subtitle']"
  end

  def xpath_for_timestamp
    "//turbo-stream[@target='connection_validation_result']/template/div/div/span[@data-test-selector='validation-result--timestamp']"
  end

  def xpath_for_label
    "//turbo-stream[@target='connection_validation_result']/template/div/div/span[contains(@class, 'Label')]"
  end

  def xpath_for_description
    "//turbo-stream[@target='connection_validation_result']/template/div/div/span[@data-test-selector='validation-result--description']"
  end

  # rubocop:enable Layout/LineLength
end
