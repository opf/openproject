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

RSpec.describe "connection validation", :skip_csrf do
  describe "POST /admin/settings/storages/:id/connection_validation/validate_connection" do
    let(:storage) { create(:one_drive_storage) }
    let(:template_body) do
      template = Nokogiri(last_response.body).css("template").first.inner_html
      Capybara.string(template)
    end
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

        expect(template_body).to have_test_selector("validation-result--subtitle", text: "Connection validation")

        if show_timestamp
          expect(template_body).to have_test_selector("validation-result--timestamp")
        else
          expect(template_body).not_to have_test_selector("validation-result--timestamp")
        end

        if label.present?
          expect(template_body).to have_css(".Label", text: label)
        else
          expect(template_body).to have_no_selector(".Label")
        end

        if description.present?
          expect(template_body).to have_test_selector("validation-result--description", text: description)
        else
          expect(template_body).not_to have_test_selector("validation-result--description", text: description)
        end
      end
    end

    context "if the a validation result of type :none (no validation executed) is returned" do
      let(:validation_result) do
        Storages::ConnectionValidation.new(type: :none,
                                           error_code: :none,
                                           timestamp: Time.current,
                                           description: "not configured")
      end

      it_behaves_like "a validation result template", show_timestamp: false, label: nil, description: "not configured"
    end

    context "if validator returns an error" do
      let(:validation_result) do
        Storages::ConnectionValidation.new(type: :error,
                                           error_code: :my_err,
                                           timestamp: Time.current,
                                           description: "An error occurred")
      end

      it_behaves_like "a validation result template",
                      show_timestamp: true, label: "Error", description: "MY_ERR: An error occurred"
    end

    context "if validator returns a warning" do
      let(:validation_result) do
        Storages::ConnectionValidation.new(type: :warning,
                                           error_code: :my_wrn,
                                           timestamp: Time.current,
                                           description: "There is something weird...")
      end

      it_behaves_like "a validation result template",
                      show_timestamp: true, label: "Warning", description: "MY_WRN: There is something weird..."
    end

    context "if validator returns a success" do
      let(:validation_result) do
        Storages::ConnectionValidation.new(type: :healthy, error_code: :none, timestamp: Time.current, description: nil)
      end

      it_behaves_like "a validation result template",
                      show_timestamp: true, label: "Healthy", description: nil
    end
  end
end
