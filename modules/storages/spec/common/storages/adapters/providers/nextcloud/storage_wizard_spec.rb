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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Storages::Adapters::Providers::Nextcloud::StorageWizard do
  subject(:wizard) { described_class.new(model:, user:) }

  let(:model) { Storages::NextcloudStorage.new }
  let(:user) { create(:admin) }

  before do
    Storages::Storages::SetAttributesService.new(user:, model:, contract_class: EmptyContract).call
  end

  it "has no completed steps" do
    expect(wizard.completed_steps).to be_empty
  end

  it "has all steps pending in correct order" do
    expect(wizard.pending_steps).to eq(%i[general_information
                                          oauth_application
                                          oauth_client
                                          automatically_managed_folders])
  end

  context "when name and host were set and authentication method is Two-Way OAuth 2.0" do
    before do
      model.name = "Karl"
      model.host = "https://nextcloud.local/"
      model.authentication_method = "two_way_oauth2"
      model.save!
    end

    it "has general_information step completed" do
      expect(wizard.completed_steps).to eq(%i[general_information])
    end

    it "has no oauth_application yet" do
      expect(model.oauth_application).to be_nil
    end

    context "and the next step was prepared" do
      before do
        wizard.prepare_next_step
      end

      it "automatically finished the oauth_application step" do
        expect(wizard.completed_steps).to eq(%i[general_information
                                                oauth_application])
      end

      it "now has an oauth_application" do
        expect(model.oauth_application).to be_present
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
                                                  oauth_application
                                                  oauth_client])
        end

        it "now has an unsaved oauth_client" do
          expect(model.oauth_client).to be_present
          expect(model.oauth_client).not_to be_persisted
        end

        it "still didn't specify how to manage folders" do
          expect(model).to be_automatic_management_unspecified
        end

        context "and after preparing the next step" do
          before do
            wizard.prepare_next_step
          end

          it "enabled automatic storage management, but didn't persist it" do
            expect(model).to be_automatic_management_enabled

            before, after = model.changes["provider_fields"]
            expect(before.keys).not_to include("automatically_managed")
            expect(after.keys).to include("automatically_managed")
          end

          it "has no pending steps" do
            expect(wizard.pending_steps).to be_empty
          end

          it "has all steps completed" do
            expect(wizard.completed_steps).to eq(%i[general_information
                                                    oauth_application
                                                    oauth_client
                                                    automatically_managed_folders])
          end
        end
      end
    end
  end

  context "when name and host were set and authentication method is OAuth 2.0 SSO" do
    before do
      model.name = "Karl"
      model.host = "https://nextcloud.local/"
      model.authentication_method = "oauth2_sso"
      model.save!
    end

    it "has general_information step completed" do
      expect(wizard.completed_steps).to eq(%i[general_information])
    end

    it "has new steps pending in correct order" do
      expect(wizard.pending_steps).to eq(%i[storage_audience
                                            automatically_managed_folders])
    end

    context "and the storage audience was set" do
      before do
        wizard.prepare_next_step
        model.storage_audience = "nextcloud"
      end

      it "finished the storage_audience step" do
        expect(wizard.completed_steps).to eq(%i[general_information
                                                storage_audience])
      end

      it "still didn't specify how to manage folders" do
        expect(model).to be_automatic_management_unspecified
      end

      context "and after preparing the next step" do
        before do
          wizard.prepare_next_step
        end

        it "enabled automatic storage management, but didn't persist it" do
          expect(model).to be_automatic_management_enabled

          before, after = model.changes["provider_fields"]
          expect(before.keys).not_to include("automatically_managed")
          expect(after.keys).to include("automatically_managed")
        end

        it "has no pending steps" do
          expect(wizard.pending_steps).to be_empty
        end

        it "has all steps completed" do
          expect(wizard.completed_steps).to eq(%i[general_information
                                                  storage_audience
                                                  automatically_managed_folders])
        end
      end
    end
  end

  context "when name and host were set and authentication method is SSO with fallback to Two-Way OAuth 2.0" do
    before do
      model.name = "Karl"
      model.host = "https://nextcloud.local/"
      model.authentication_method = "oauth2_sso_with_two_way_oauth2_fallback"
      model.save!
    end

    it "has general_information step completed" do
      expect(wizard.completed_steps).to eq(%i[general_information])
    end

    it "has new steps pending in correct order" do
      expect(wizard.pending_steps).to eq(%i[storage_audience
                                            oauth_application
                                            oauth_client
                                            automatically_managed_folders])
    end

    context "and the storage audience was set" do
      before do
        wizard.prepare_next_step
        model.storage_audience = "nextcloud"
      end

      it "has storage_audience step completed" do
        expect(wizard.completed_steps).to eq(%i[general_information storage_audience])
      end

      it "has no oauth_application yet" do
        expect(model.oauth_application).to be_nil
      end

      context "and the next step was prepared" do
        before do
          wizard.prepare_next_step
        end

        it "automatically finished the oauth_application step" do
          expect(wizard.completed_steps).to eq(%i[general_information
                                                  storage_audience
                                                  oauth_application])
        end

        it "now has an oauth_application" do
          expect(model.oauth_application).to be_present
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
                                                    storage_audience
                                                    oauth_application
                                                    oauth_client])
          end

          it "now has an unsaved oauth_client" do
            expect(model.oauth_client).to be_present
            expect(model.oauth_client).not_to be_persisted
          end

          it "still didn't specify how to manage folders" do
            expect(model).to be_automatic_management_unspecified
          end

          context "and after preparing the next step" do
            before do
              wizard.prepare_next_step
            end

            it "enabled automatic storage management, but didn't persist it" do
              expect(model).to be_automatic_management_enabled

              before, after = model.changes["provider_fields"]
              expect(before.keys).not_to include("automatically_managed")
              expect(after.keys).to include("automatically_managed")
            end

            it "has no pending steps" do
              expect(wizard.pending_steps).to be_empty
            end

            it "has all steps completed" do
              expect(wizard.completed_steps).to eq(%i[general_information
                                                      storage_audience
                                                      oauth_application
                                                      oauth_client
                                                      automatically_managed_folders])
            end
          end
        end
      end
    end
  end
end
