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

RSpec.describe "Enterprise trial management",
               driver: :chrome_billy do
  let(:admin) { create(:admin) }

  let(:trial_id) { "1b6486b4-5a30-4042-8714-99d7c8e6b637" }
  let(:created_body) do
    {
      _type: "enterprise-trial",
      id: trial_id,
      _links:
        {
          self:
            {
              href: "https://start.openproject-edge.com/public/v1/trials/#{trial_id}"
            },
          details:
            {
              href: "https://start.openproject-edge.com/public/v1/trials/#{trial_id}/details"
            }
        }
    }
  end

  let(:waiting_body) do
    {
      _type: "error",
      code: 422,
      identifier: "waiting_for_email_verification",
      description: "User has to confirm their email address",
      _links: {
        resend: {
          href: "https://start.openproject-edge.com/public/v1/trials/#{trial_id}/resend",
          method: "POST"
        },
        details: {
          href: "https://start.openproject-edge.com/public/v1/trials/#{trial_id}/details"
        }
      }
    }
  end

  let(:expired_token) do
    <<~EOS
      -----BEGIN OPENPROJECT-EE TOKEN-----
      eyJkYXRhIjoiTE02OG5UWjJ1cTY4dnlKNWo4NEk0ZnZGdHlFcUtEU1ZxVGd5
      WnBicTUzTlA5VFFOa3NSc3haOGl1KzZpXG5VTEhuQmhnWjc5c3pYRzhTV2lt
      Tlg3QnpLdkh2MlFLeXFqOCtkQ2dzNHNhQUEvV21aRWZ3YmtPVExTSTBcblVY
      eTYxMmFnKzY0OXVOT2dOdTZmTm5mQndoTnNZdnFGRmxDZjJZd1VQU0ROZUhQ
      dWF2bDJEa3hlTTlLdlxuaWRNbC8wU3BxdWpzMVk4VjlLazhEejRJNUViQU1E
      K1NOMzE1eHplOWc2MDduN2p4c3FKS3k3RVVrUTI5XG5RRG5DSTVZSTJ6bTJv
      dkpaXG4iLCJrZXkiOiJSaXlnRTE0RWswdi9qVFZkOW9HRWJOcldudStQQlN2
      K0xDTEVpUWZadEczY2g2djN1TERWdWVZeG8xV2NcbjRXdUFGUkdKOFEvejhn
      OG01NWpyMkRKdGh6UUdoVjRYa2t4ZlN2ZUdaaUVzRWJFMmh5NzQ2cDRHNjl1
      b1xuaFFOQmtqZ1FqWUZwTW9yUVBSRmhXRTNjbkp1dGFKOGU1dUVTbkZPYUFD
      RDdsdkNvMUhMY2J4NWduMm96XG5NcXllbC96NytBdSt5QUNtT2poSlRaUW9L
      M25ZenVuZ1FXbXJiZm93ZGUzVVN6c1lraEdyRHlBNXJSWmlcbk9TaXpqSnNE
      MXBIRmZ4aVhEMnYzVlNuMWJMNXpJWFZNMDBUSFJGUHZLODVYY3IzTEVFNTZy
      TVBCMytnRlxuYUptcVFUYVJOWFowamJKZ3cwNFdqUEtTbGxxaDVIVWZ5Umk2
      ZjErRGxxYWlsMmcvOUZpTUpPc29QOFhhXG5IYm9oUURBY1drOHBGVE9Fci8z
      NTNSdU4rejE3SklJdVdsM0Z2ZmhiQVFGZVdHQ0paR0JzTnJ4WUV3QzBcbmN1
      WC80NFZKem9kcVkrRHlSUWFYNFlkcytCOUJVRnB2MHRaSnUrZmNza1MyVnc5
      MGtCM3hQZTBmYTFjV1xuZTVSdHFucklFNXRQMzlEQ25YZWxwSmxGRXh5YzhX
      ekZiL3BlVEVqUWtCWnM0ZUNKMzhQT1djQXh1R2s2XG5iRFppYWlEQitJSFV4
      QTBuYXhSa2R5OWJvbHBNa1RBNjk1a3Q3TnhSTDJ2WU1PZFFEY3pIekFNQmpV
      TE5cbnFQd3FuQWlreDgrazJqTStHWDFmTXgrUzcyb3FQTjd6M0ZqaU85S1BV
      VVAveTlNMG1RV1hCZEY0bVJUR1xuM2RuUDNoOXErSHNnTkFHTUNxSHBTRzNv
      L05ONTRQSCs1NCsyWk5MVDFzZ1ZubjBsQ1hVdlh0Vkt6b1hhXG5TdXlZNzBV
      R3NJTUdDYmZhdnlYREVpQzU2SWtJVzNTSU1CVHVQdisxQ1J4TCtIcEEzRE5x
      R09BVjVMbFFcbkUrdGNqZlNpUlVzRXcxeWkxWUZPODVEM2ZVTXdLZzFKclZB
      WEV1YVdvbjUxMzNVRnZNZjBNbFhkSUQ1L1xuNEtXczNGeEdmWVJJRUQ5VlhR
      eFNYdEQ3cWYzSlFFbHdHSGVMdUtVYkRmMWEzTEVKMUFKb2FOV0phcG9xXG4v
      QlU3ZHJoM28zSDFXYVBpeUhpUlQrVExTa2cxUXhxY2p0eUVuK1JiNnBKVmwr
      eVJXWHMrR1pkcGFDY09cbnh2ZWRIam12NzNsUjc5WFpVNVh6UlhwY3E1d1pm
      T2FVaHZ1NHllQysyR0FpYlIrcGowbTA0UzRXbjI0elxucjUvZGtnSG5Xek9B
      V2lZb0MxOEZpckhTSnVGM1FHWHJUK1JyT2c4QVdwTDlHMGZQQlpveTJvNFZj
      V004XG51UXJvSDUwT3Rtcm00cW53QUU3TEFyc3g3bWxOblBGMmpyejZMeWkz
      UlhDN1ZrSE9FVXhiUHNjZHJiRlhcbkd3cTlvNU5LNi9sb2RVTTAzeklyaTBs
      TVdKSlpUU3BNMnVzU0VxWUpoS05uSGI1a3lYcy9MRkhOWW05c1xuN2hBOVdS
      RUxWQi9Tc2x5RjJQczNzSHJQaGtZM1BGZElSeU9Kb2JxdnZoaUpPTVA5dDVu
      MUxUeTFjbkhGXG5DbTBDM0U1bWFjTi9hOE5OSXk2dGhia3JJVE5XK2I4K2Jw
      VDN3OGkxSDVYNCtodlJ5T1g0Y0JEVWhNN2pcbnN3Wkw0citmWlRmaGlNQkZi
      K2NmSUZ0U2lyMVBpdz09XG4iLCJpdiI6IjFxbEZqRWM4QzcrMjg4QWR6cXdL
      OEE9PVxuIn0=
      -----END OPENPROJECT-EE TOKEN-----
    EOS
  end
  let (:confirmed_body) do
    {
      _type: "enterprise-trial",
      id: trial_id,
      token: expired_token,
      token_retrieved: false,
      _links: {
        self: {
          href: "https://start.openproject-edge.com/public/v1/trials/#{trial_id}"
        }
      }
    }
  end

  let(:mail_in_use_body) do
    {
      _type: "error",
      code: 422,
      identifier: "user_already_created_trial",
      description: "Each user can only create one trial."
    }
  end

  let(:domain_in_use_body) do
    {
      _type: "error",
      code: 422,
      identifier: "domain_taken",
      description: "There can only be one active trial per domain."
    }
  end

  let(:other_error_body) do
    {
      _type: "error",
      code: 409,
      description: "Token version is invalid",
      identifier: "token_version_too_old",
      errors: {
        token_version: [
          "does not have a valid value"
        ]
      }
    }
  end

  before do
    login_as(admin)
    visit enterprise_path
  end

  def fill_out_modal(mail: "foo@foocorp.example")
    fill_in "Company", with: "Foo Corp."
    fill_in "First name", with: "Foo"
    fill_in "Last name", with: "Bar"
    fill_in "Email", with: mail

    find_by_id("trial-general-consent").check
  end

  it "blocks the request assuming the mail was used" do
    proxy.stub("https://start.openproject-edge.com:443/public/v1/trials", method: "post")
      .and_return(headers: { "Access-Control-Allow-Origin" => "*" }, code: 422, body: mail_in_use_body.to_json)

    find(".button", text: "Start free trial").click
    fill_out_modal
    find(".button:not(:disabled)", text: "Submit").click

    expect(page).to have_css(".-required-highlighting #trial-email")
    expect(page).to have_text("Each user can only create one trial.")
    expect(page).to have_no_text "email sent - waiting for confirmation"
  end

  it "blocks the request assuming the domain was used" do
    proxy.stub("https://start.openproject-edge.com:443/public/v1/trials", method: "post")
      .and_return(headers: { "Access-Control-Allow-Origin" => "*" }, code: 422, body: domain_in_use_body.to_json)

    find(".button", text: "Start free trial").click
    fill_out_modal
    find(".button:not(:disabled)", text: "Submit").click

    expect(page).to have_css(".-required-highlighting #trial-domain-name")
    expect(page).to have_text("There can only be one active trial per domain.")
    expect(page).to have_no_text "email sent - waiting for confirmation"
  end

  it "shows an error in case of other errors" do
    proxy.stub("https://start.openproject-edge.com:443/public/v1/trials", method: "post")
      .and_return(headers: { "Access-Control-Allow-Origin" => "*" }, code: 409, body: other_error_body.to_json)

    find(".button", text: "Start free trial").click
    fill_out_modal
    find(".button:not(:disabled)", text: "Submit").click

    expect(page).to have_text("Token version is invalid")
    expect(page).to have_no_text "email sent - waiting for confirmation"
  end

  context "with a waiting request pending" do
    before do
      proxy.stub("https://start.openproject-edge.com:443/public/v1/trials", method: "post")
        .and_return(headers: { "Access-Control-Allow-Origin" => "*" }, code: 200, body: created_body.to_json)

      proxy.stub("https://start.openproject-edge.com:443/public/v1/trials/#{trial_id}")
        .and_return(headers: { "Access-Control-Allow-Origin" => "*" }, code: 422, body: waiting_body.to_json)

      proxy.stub("https://start.openproject-edge.com:443/public/v1/trials/#{trial_id}/resend", method: "post")
        .and_return(headers: { "Access-Control-Allow-Origin" => "*" }, code: 200, body: waiting_body.to_json)

      find(".button", text: "Start free trial").click
      fill_out_modal
      find(".button:not(:disabled)", text: "Submit").click

      expect(page).to have_text "foo@foocorp.example"
      expect(page).to have_text "email sent - waiting for confirmation"
    end

    it "can get the trial if reloading the page" do
      # We need to go to another page to stop the request cycle
      visit info_admin_index_path

      # Stub with successful body
      # Stub the proxy to a successful return
      # which marks the user has confirmed the mail link
      proxy.stub("https://start.openproject-edge.com:443/public/v1/trials/#{trial_id}")
        .and_return(headers: { "Access-Control-Allow-Origin" => "*" }, code: 200, body: confirmed_body.to_json)

      # Stub the details URL to still return 403
      proxy.stub("https://start.openproject-edge.com:443/public/v1/trials/#{trial_id}/details")
        .and_return(headers: { "Access-Control-Allow-Origin" => "*" }, code: 403)

      visit enterprise_path

      expect(page).to have_css(".attributes-key-value--value-container", text: "OpenProject Test", wait: 20)
      expect(page).to have_css(".attributes-key-value--value-container", text: "01/01/2020")
      expect(page).to have_css(".attributes-key-value--value-container", text: "01/02/2020")
      expect(page).to have_css(".attributes-key-value--value-container", text: "5")
      # Generated expired token has different mail
      expect(page).to have_css(".attributes-key-value--value-container", text: "info@openproject.com")
    end

    it "can confirm that trial regularly" do
      find_test_selector("op-ee-trial-waiting-resend-link", text: "Resend").click
      expect(page).to have_css(".op-toast.-success", text: "Email has been resent.", wait: 20)

      expect(page).to have_text "foo@foocorp.example"
      expect(page).to have_text "email sent - waiting for confirmation"

      # Stub the proxy to a successful return
      # which marks the user has confirmed the mail link
      proxy.stub("https://start.openproject-edge.com:443/public/v1/trials/#{trial_id}")
        .and_return(headers: { "Access-Control-Allow-Origin" => "*" }, code: 200, body: confirmed_body.to_json)

      # Wait until the next request
      expect(page).to have_test_selector "op-ee-trial-waiting-status--confirmed", text: "confirmed", wait: 20

      # advance to video
      click_on "Continue"

      # advance to close
      click_on "Continue"

      expect(page).to have_css(".op-toast.-success", text: "Successful update.", wait: 10)
      expect(page).to have_css(".attributes-key-value--value-container", text: "OpenProject Test")
      expect(page).to have_css(".attributes-key-value--value-container", text: "01/01/2020")
      expect(page).to have_css(".attributes-key-value--value-container", text: "01/02/2020")
      expect(page).to have_css(".attributes-key-value--value-container", text: "5")
      # Generated expired token has different mail
      expect(page).to have_css(".attributes-key-value--value-container", text: "info@openproject.com")
    end
  end
end
