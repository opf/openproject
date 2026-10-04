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
require "contracts/shared/model_contract_shared_context"

RSpec.describe ProjectPhases::UpdateContract do
  include_context "ModelContract shared context"

  let(:user) { build_stubbed(:user) }

  subject(:contract) { described_class.new(phase, user) }

  context "with authorized user" do
    let(:phase) { create(:project_phase) }
    let(:project) { phase.project }
    let(:date) { Date.current }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:edit_project_phases, project:)
      end
    end

    describe "contract validations" do
      it_behaves_like "contract is valid"
      it_behaves_like "contract reuses the model errors"

      context "with an invalid start date" do
        let(:phase) do
          build_stubbed(:project_phase, start_date: date + 1, finish_date: date - 1)
        end

        it_behaves_like "contract is invalid", start_date: :must_be_before_finish_date
      end

      context "when trying to change extra attributes" do
        before do
          phase.duration = 42
        end

        it_behaves_like "contract is invalid", duration: :error_readonly
      end

      context "when the phase has preceeding phases" do
        def create_phase(**) = create(:project_phase, project:, **)

        let(:project) { create(:project) }
        let(:phases) { [preceding, phase, following] }
        let(:phase) do
          create_phase(
            start_date: date_range&.begin,
            finish_date: date_range&.end,
            active:
          )
        end

        let(:preceding) do
          create_phase(
            start_date: preceding_date_range&.begin,
            finish_date: preceding_date_range&.end
          )
        end
        let(:following) do
          create_phase(
            start_date: following_date_range.begin,
            finish_date: following_date_range.end
          )
        end
        let(:active) { true }
        let(:date_range) { date - 1..date + 1 }
        let(:preceding_date_range) { date - 6..date - 5 }
        let(:following_date_range) { date + 5..date + 6 }

        before do
          allow(project).to receive(:available_phases).and_return(phases)
        end

        context "with successive non overlapping dates" do
          it_behaves_like "contract is valid"
        end

        context "without dates" do
          let(:date_range) { nil }

          it_behaves_like "contract is valid"
        end

        context "with preceding phase overlapping with start" do
          let(:preceding_date_range) { date - 6..date - 1 }

          it_behaves_like "contract is invalid", start_date: :non_continuous_dates

          context "when inactive" do
            let(:active) { false }

            it_behaves_like "contract is valid"
          end
        end

        context "with preceding phase following this" do
          let(:preceding_date_range) { date + 2..date + 4 }

          it_behaves_like "contract is invalid", start_date: :non_continuous_dates

          context "when inactive" do
            let(:active) { false }

            it_behaves_like "contract is valid"
          end
        end

        context "with preceding phase without dates" do
          let(:preceding_date_range) { nil }

          it_behaves_like "contract is valid"
        end

        context "with following phase overlapping with start" do
          let(:following_date_range) { date - 1..date + 6 }

          it_behaves_like "contract is valid"
        end

        context "with following phase preceding this" do
          let(:following_date_range) { date - 4..date - 2 }

          it_behaves_like "contract is valid"
        end
      end

      context "with non working days present" do
        let(:non_working_day) { Date.current }
        let(:phase) do
          build_stubbed(:project_phase, start_date:, finish_date:)
        end

        before do
          set_non_working_days(non_working_day)
        end

        context "when the start date is a non working day" do
          let(:start_date) { non_working_day }
          let(:finish_date) { non_working_day + 1.day }

          it_behaves_like "contract is invalid", start_date: :cannot_be_a_non_working_day

          context "and the finish date is nil" do
            let(:finish_date) { nil }

            it_behaves_like "contract is invalid", start_date: :cannot_be_a_non_working_day
          end
        end

        context "when the finish date is a non working day" do
          let(:start_date) { non_working_day - 1.day }
          let(:finish_date) { non_working_day }

          it_behaves_like "contract is invalid", finish_date: :cannot_be_a_non_working_day

          context "and the start date is nil" do
            let(:start_date) { nil }

            it_behaves_like "contract is invalid", finish_date: :cannot_be_a_non_working_day
          end
        end

        context "when both dates are on non working day" do
          let(:start_date) { non_working_day }
          let(:finish_date) { non_working_day }

          it_behaves_like "contract is invalid",
                          start_date: :cannot_be_a_non_working_day,
                          finish_date: :cannot_be_a_non_working_day
        end

        context "when both dates are on a working day" do
          let(:start_date) { non_working_day - 1.day }
          let(:finish_date) { non_working_day + 1 }

          it_behaves_like "contract is valid"

          context "and the start date is nil" do
            let(:start_date) { nil }

            it_behaves_like "contract is valid"
          end

          context "and the finish date is nil" do
            let(:finish_date) { nil }

            it_behaves_like "contract is valid"
          end
        end
      end

      describe "date format validation" do
        let(:phase) { build_stubbed(:project_phase) }
        let(:start_date) { nil }
        let(:finish_date) { nil }

        before do
          phase.start_date = start_date
          phase.finish_date = finish_date
        end

        context "with correct YYYY-MM-DD format" do
          let(:start_date) { "2025-06-17" }
          let(:finish_date) { "2025-06-18" }

          it_behaves_like "contract is valid"
        end

        context "with extra characters in date" do
          let(:start_date) { "2025-06-170" }
          let(:finish_date) { "2025-06-18" }

          it_behaves_like "contract is invalid", start_date: :invalid
        end

        context "with non-date string" do
          let(:start_date) { "2025-06-17" }
          let(:finish_date) { "not-a-date" }

          it_behaves_like "contract is invalid", finish_date: :invalid
        end

        context "with wrong format (missing leading zero)" do
          let(:start_date) { "2025-6-17" }
          let(:finish_date) { "2025-06-18" }

          it_behaves_like "contract is invalid", start_date: :invalid
        end

        context "when date is blank" do
          let(:start_date) { "" }
          let(:finish_date) { nil }

          it_behaves_like "contract is valid"
        end
      end
    end
  end

  context "with unauthorized user" do
    let(:phase) { build_stubbed(:project_phase) }

    it_behaves_like "contract user is unauthorized"
  end
end
