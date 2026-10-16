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

RSpec.describe Storages::Adapters::Providers::OneDrive::StorageWizard do
  subject(:wizard) { described_class.new(model:, user:) }

  let(:model) { Storages::OneDriveStorage.new }
  let(:user) { create(:admin) }

  before do
    Storages::Storages::SetAttributesService.new(user:, model:, contract_class: EmptyContract).call
  end

  it "has no completed steps" do
    expect(wizard.completed_steps).to be_empty
  end

  it "has all steps pending in correct order" do
    expect(wizard.pending_steps).to eq(%i[general_information
                                          access_management
                                          oauth_client
                                          redirect_uri])
  end

  context "when name was set" do
    before do
      model.name = "Karl"
      model.save!
    end

    it "has general_information step completed" do
      expect(wizard.completed_steps).to eq(%i[general_information])
    end

    it "still didn't specify how to manage folders" do
      expect(model).to be_automatic_management_unspecified
    end

    context "and the next step was prepared" do
      before do
        wizard.prepare_next_step
      end

      it "automatically finished the access_management step" do
        expect(wizard.completed_steps).to eq(%i[general_information
                                                access_management])
      end

      it "enabled automatic storage management, but didn't persist it" do
        expect(model).to be_automatic_management_enabled

        before, after = model.changes["provider_fields"]
        expect(before.keys).not_to include("automatically_managed")
        expect(after.keys).to include("automatically_managed")
      end

      it "has no oauth_client yet" do
        expect(model.oauth_client).to be_nil
      end

      context "and the next step was prepared" do
        before do
          wizard.prepare_next_step
        end

        it "finishes the oauth_client step" do
          expect(wizard.completed_steps).to eq(%i[general_information
                                                  access_management
                                                  oauth_client])
        end

        it "now has an unsaved oauth_client" do
          expect(model.oauth_client).to be_present
          expect(model.oauth_client).not_to be_persisted
        end

        context "when the client was saved" do
          before do
            model.oauth_client.assign_attributes(client_id: "Foo", client_secret: "Bar")
            model.oauth_client.save!
          end

          it "did not finish the final step immediately" do
            expect(wizard.pending_steps).to eq(%i[redirect_uri])
          end

          it "after some time, the final step is completed" do
            Timecop.travel(15.seconds.from_now) do
              expect(wizard.completed_steps).to eq(%i[general_information
                                                      access_management
                                                      oauth_client
                                                      redirect_uri])
            end
          end
        end
      end
    end
  end
end
