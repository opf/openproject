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
require "contracts/shared/model_contract_shared_context"

RSpec.describe UserPreferences::ParamsContract do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }
  let(:preference_user) { current_user }
  let(:user_preference) do
    build_stubbed(:user_preference,
                  user: preference_user)
  end
  let(:notification_settings) do
    [
      { project_id: 1234, news_added: true }
    ]
  end
  let(:params) do
    {
      hide_mail: true,
      auto_hide_popups: true,
      comments_sorting: "desc",
      daily_reminders: {
        enabled: true,
        times: %w[08:00:00+00:00 12:00:00+00:00]
      },
      time_zone: "Brasilia",
      warn_on_leaving_unsaved: true,
      notification_settings:
    }
  end
  let(:contract) { described_class.new(user_preference, current_user, params:) }

  describe "notification settings" do
    context "when multiple global settings" do
      let(:notification_settings) do
        [
          { project_id: nil, mentioned: true },
          { project_id: nil, mentioned: true }
        ]
      end

      it_behaves_like "contract is invalid", notification_settings: :only_one_global_setting
    end

    context "when project settings with an email alert set" do
      let(:notification_settings) do
        [
          { project_id: 1234, news_added: true }
        ]
      end

      it_behaves_like "contract is invalid", notification_settings: :email_alerts_global
    end

    context "when global settings with an email alert set" do
      let(:notification_settings) do
        [
          { project_id: nil, news_added: true }
        ]
      end

      it_behaves_like "contract is valid"
    end

    context "without enterprise" do
      context "when global setting with start_date, due_date and overdue set" do
        let(:notification_settings) do
          [
            { start_date: 1, due_date: 1, overdue: 1 }
          ]
        end

        it_behaves_like "contract is invalid", base: :error_enterprise_only do
          it "displays the error message containing the feature name" do
            contract.validate
            expect(contract.errors.full_messages)
              .to eq(["Date Alerts is only available in the OpenProject Enterprise edition"])
          end
        end
      end

      context "when project setting with start_date, due_date and overdue set" do
        let(:notification_settings) do
          [
            { project_id: 1234, start_date: 1, due_date: 1, overdue: 1 }
          ]
        end

        it_behaves_like "contract is invalid", base: :error_enterprise_only
      end
    end

    context "with enterprise", with_ee: %i[date_alerts] do
      context "when project setting with start_date, due_date and overdue set" do
        let(:notification_settings) do
          [
            { project_id: 1234, start_date: 1, due_date: 1, overdue: 1 }
          ]
        end

        it_behaves_like "contract is valid"
      end

      context "when global setting with start_date, due_date and overdue set" do
        let(:notification_settings) do
          [
            { start_date: 1, due_date: 1, overdue: 1 }
          ]
        end

        it_behaves_like "contract is valid"
      end

      context "when project setting with valid start_date, valid due_date and invalid overdue" do
        let(:notification_settings) do
          [
            { project_id: 1234, start_date: 1, due_date: 1, overdue: 0 }
          ]
        end

        it_behaves_like "contract is invalid", notification_settings: :wrong_date
      end

      context "when global setting with invalid start_date, valid due_date and valid overdue" do
        let(:notification_settings) do
          [
            { start_date: -1, due_date: 1, overdue: 1 }
          ]
        end

        it_behaves_like "contract is invalid", notification_settings: :wrong_date
      end

      context "when project setting with start_date, due_date and overdue missing" do
        let(:notification_settings) do
          [
            { project_id: 1234, start_date: 1, due_date: 1 }
          ]
        end

        it_behaves_like "contract is valid"
      end

      context "when global setting with start_date, due_date and overdue missing" do
        let(:notification_settings) do
          [
            { start_date: 1, due_date: 1 }
          ]
        end

        it_behaves_like "contract is valid"
      end

      context "when project setting with valid start_date, invalid due_date and overdue missing" do
        let(:notification_settings) do
          [
            { project_id: 1234, start_date: 1, due_date: 24 }
          ]
        end

        it_behaves_like "contract is invalid", notification_settings: :wrong_date
      end

      context "when global setting with invalid start_date, valid due_date and overdue missing" do
        let(:notification_settings) do
          [
            { start_date: 24, due_date: 1 }
          ]
        end

        it_behaves_like "contract is invalid", notification_settings: :wrong_date
      end
    end

    context "when notification_settings empty" do
      let(:params) do
        {
          hide_mail: true,
          auto_hide_popups: true,
          comments_sorting: "desc",
          daily_reminders: {
            enabled: true,
            times: %w[08:00:00+00:00 12:00:00+00:00]
          },
          time_zone: "Brasilia",
          warn_on_leaving_unsaved: true
        }
      end

      it_behaves_like "contract is valid"
    end
  end

  include_examples "contract reuses the model errors"
end
