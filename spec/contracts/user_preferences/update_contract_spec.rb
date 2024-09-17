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

RSpec.describe UserPreferences::UpdateContract do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }
  let(:preference_user) { current_user }
  let(:user_preference) do
    build_stubbed(:user_preference,
                  user: preference_user,
                  settings: settings&.with_indifferent_access)
  end
  let(:settings) do
    {
      hide_mail: true,
      auto_hide_popups: true,
      comments_sorting: "desc",
      daily_reminders: {
        enabled: true,
        times: %w[08:00:00+00:00 12:00:00+00:00]
      },
      time_zone: "America/Sao_Paulo",
      warn_on_leaving_unsaved: true,
      workdays: [1, 2, 4, 6]
    }
  end
  let(:contract) { described_class.new(user_preference, current_user) }

  describe "validation" do
    context "when current_user is admin" do
      let(:current_user) { build_stubbed(:admin) }
      let(:preference_user) { build_stubbed(:user) }

      it_behaves_like "contract is valid"
    end

    context "when current_user has manage_user permission" do
      let(:preference_user) { build_stubbed(:user) }

      before do
        mock_permissions_for(current_user) do |mock|
          mock.allow_globally(:manage_user)
        end
      end

      it_behaves_like "contract is valid"
    end

    context "when current_user is the own user" do
      it_behaves_like "contract is valid"
    end

    context "when current_user is the own user but not active" do
      before do
        allow(current_user).to receive(:active?).and_return false
      end

      it_behaves_like "contract user is unauthorized"
    end

    context "when current_user is anonymous" do
      let(:current_user) { User.anonymous }

      it_behaves_like "contract user is unauthorized"
    end

    context "when current_user is a regular user" do
      let(:preference_user) { build_stubbed(:user) }

      it_behaves_like "contract user is unauthorized"
    end

    context "with empty settings" do
      let(:settings) do
        {}
      end

      it_behaves_like "contract is valid"
    end

    context "with a string for hide_mail" do
      let(:settings) do
        {
          hide_mail: "yes please"
        }
      end

      it_behaves_like "contract is invalid", hide_mail: :type_mismatch
    end

    context "with a field within the daily_reminders having the wrong type" do
      let(:settings) do
        {
          daily_reminders: {
            enabled: "sure",
            times: %w[08:00:00+00:00 12:00:00+00:00]
          }
        }
      end

      it_behaves_like "contract is invalid", daily_reminders: :type_mismatch_nested
    end

    context "with a field within the daily_reminders missing" do
      let(:settings) do
        {
          daily_reminders: {
            times: %w[08:00:00+00:00 12:00:00+00:00]
          }
        }
      end

      it_behaves_like "contract is invalid", daily_reminders: :blank_nested
    end

    context "with an extra property" do
      let(:settings) do
        {
          foo: true
        }
      end

      it_behaves_like "contract is invalid", foo: :unknown_property
    end

    context "with an extra property within the daily_reminders" do
      let(:settings) do
        {
          daily_reminders: {
            enabled: true,
            times: %w[08:00:00+00:00 12:00:00+00:00],
            foo: true
          }
        }
      end

      it_behaves_like "contract is invalid", daily_reminders: :unknown_property_nested
    end

    context "with an invalid time for the daily_reminders" do
      let(:settings) do
        {
          daily_reminders: {
            enabled: true,
            times: %w[abc 12:00:00+00:00]
          }
        }
      end

      it_behaves_like "contract is invalid", daily_reminders: %i[format_nested full_hour]
    end

    context "with a sub hour time for the daily_reminders" do
      let(:settings) do
        {
          daily_reminders: {
            enabled: true,
            times: %w[12:30:00+00:00]
          }
        }
      end

      it_behaves_like "contract is invalid", daily_reminders: :full_hour
    end

    context "with an invalid order for comments_sorting" do
      let(:settings) do
        {
          comments_sorting: "up"
        }
      end

      it_behaves_like "contract is invalid", comments_sorting: :inclusion
    end

    context "without a time_zone" do
      let(:settings) do
        {
          hide_mail: true,
          auto_hide_popups: true,
          comments_sorting: "desc",
          daily_reminders: {
            enabled: true,
            times: %w[08:00:00+00:00 12:00:00+00:00]
          },
          warn_on_leaving_unsaved: true
        }
      end

      it_behaves_like "contract is valid"
    end

    context "with a full time_zone" do
      let(:settings) do
        {
          time_zone: "Europe/Paris"
        }
      end

      it_behaves_like "contract is valid"
    end

    context "with a non ActiveSupport::Timezone timezone" do
      let(:settings) do
        {
          time_zone: "America/Adak"
        }
      end

      it_behaves_like "contract is invalid", time_zone: :inclusion
    end

    context "with a malformed time_zone" do
      let(:settings) do
        {
          time_zone: "123Brasilia"
        }
      end

      it_behaves_like "contract is invalid", time_zone: :inclusion
    end

    context "with a non tzinfo time_zone" do
      let(:settings) do
        {
          time_zone: "Brasilia"
        }
      end

      it_behaves_like "contract is invalid", time_zone: :inclusion
    end

    context "with duplicate workday entries" do
      let(:settings) do
        {
          workdays: [1, 1]
        }
      end

      it_behaves_like "contract is invalid", workdays: :no_duplicates
    end

    context "with non-iso workday entries" do
      let(:settings) do
        {
          workdays: [nil, "foo", :bar, 21345, 2.0]
        }
      end

      it_behaves_like "contract is invalid", workdays: %i[invalid type_mismatch_nested
                                                          type_mismatch_nested type_mismatch_nested]
    end
  end

  describe "#assignable_time_zones" do
    subject(:time_zones) { contract.assignable_time_zones }

    it "returns a list of AS::TimeZones" do
      expect(time_zones)
        .to(be_all { |tz| tz.is_a?(ActiveSupport::TimeZone) })
    end

    it "includes only the namesake zone if multiple AS::Timezone map to the same TZInfo" do
      # In this case 'Edinburgh' and 'Bern' are not included
      expect(time_zones.select { |tz| %w[Europe/London Europe/Zurich].include? tz.tzinfo.canonical_zone.name })
        .to contain_exactly(ActiveSupport::TimeZone["London"], ActiveSupport::TimeZone["Zurich"])
    end
  end

  describe "pause_reminders" do
    context "with enabled false" do
      let(:settings) do
        {
          pause_reminders: { enabled: false }
        }
      end

      it_behaves_like "contract is valid"
    end

    context "with enabled true but and valid range" do
      let(:settings) do
        {
          pause_reminders: {
            enabled: true,
            first_day: "2021-10-05",
            last_day: "2021-10-10"
          }
        }
      end

      it_behaves_like "contract is valid"
    end

    context "with empty object" do
      let(:settings) do
        {
          pause_reminders: {}
        }
      end

      it_behaves_like "contract is invalid", pause_reminders: :blank_nested
    end

    context "with enabled true but no days" do
      let(:settings) do
        {
          pause_reminders: { enabled: true }
        }
      end

      it_behaves_like "contract is invalid", pause_reminders: :blank
    end

    context "with enabled true but invalid dates" do
      let(:settings) do
        {
          pause_reminders: {
            enabled: true,
            first_day: "2021-10-05T08:21:35Z",
            last_day: "2021-10-05T08:21:35Z"
          }
        }
      end

      it_behaves_like "contract is invalid", pause_reminders: %i[format_nested format_nested]
    end

    context "with enabled true but only first day" do
      let(:settings) do
        {
          pause_reminders: { enabled: true, first_day: "2021-10-05" }
        }
      end

      it_behaves_like "contract is invalid", pause_reminders: :blank
    end

    context "with enabled true but only last day" do
      let(:settings) do
        {
          pause_reminders: { enabled: true, last_day: "2021-10-05" }
        }
      end

      it_behaves_like "contract is invalid", pause_reminders: :blank
    end
  end

  include_examples "contract reuses the model errors"
end
