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

RSpec.describe "Mail Notifications Settings",
               :skip_csrf,
               type: :rails_request do
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  describe "GET /admin/settings/mail_notifications" do
    context "when email_delivery_method is sendmail" do
      before do
        allow(Setting).to receive(:email_delivery_method).and_return(:sendmail)
        get "/admin/settings/mail_notifications"
      end

      it "shows sendmail_location field as disabled" do
        expect(response).to have_http_status(:success)

        expect(page).to have_field(I18n.t(:setting_sendmail_location), disabled: true, visible: :all)
      end

      it "shows the sendmail fields group and hides the smtp fields group" do
        expect(page).to have_field(I18n.t(:setting_sendmail_location), visible: :visible)
        expect(page).to have_field(I18n.t(:setting_smtp_address), visible: :hidden)
      end
    end

    context "when email_delivery_method is smtp" do
      before do
        allow(Setting).to receive(:email_delivery_method).and_return(:smtp)
        get "/admin/settings/mail_notifications"
      end

      it "shows the smtp fields group and hides the sendmail fields group" do
        expect(response).to have_http_status(:success)

        expect(page).to have_field(I18n.t(:setting_smtp_address), visible: :visible)
        expect(page).to have_field(I18n.t(:setting_sendmail_location), visible: :hidden)
      end
    end
  end

  describe "PATCH /admin/settings/mail_notifications" do
    context "when trying to update sendmail_location" do
      before do
        allow(Setting).to receive(:email_delivery_method).and_return(:sendmail)
      end

      it "returns an error that the setting is not writable" do
        patch "/admin/settings/mail_notifications",
              params: {
                settings: {
                  # have to set setting_mail_from as it's validated on the same page
                  mail_from: "test@example.com",
                  sendmail_location: "/usr/bin/sendmail"
                }
              }

        expected_error = "Setting '#{I18n.t(:setting_sendmail_location)}' could not be updated: " \
                         "The setting is not writable and can only be changed by a sysadmin."
        expect(flash[:error]).to eq(expected_error)
      end
    end

    context "when trying to update sendmail_arguments" do
      before do
        allow(Setting).to receive(:email_delivery_method).and_return(:sendmail)
      end

      it "returns an error that the setting is not writable" do
        patch "/admin/settings/mail_notifications",
              params: {
                settings: {
                  # have to set setting_mail_from as it's validated on the same page
                  mail_from: "test@example.com",
                  sendmail_arguments: "-i -t"
                }
              }

        expected_error = "Setting '#{I18n.t(:setting_sendmail_arguments)}' could not be updated: " \
                         "The setting is not writable and can only be changed by a sysadmin."
        expect(flash[:error]).to eq(expected_error)
      end
    end
  end
end
