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

# This file can be safely deleted once the feature flag percent_complete_edition
# is removed, which should happen for OpenProject 15.0 release.
RSpec.describe WorkPackages::SetAttributesService, "pre 14.4 without percent complete edition",
               type: :model,
               with_flag: { percent_complete_edition: false } do
  shared_let(:status_0_pct_complete) { create(:status, default_done_ratio: 0, name: "0% complete") }
  shared_let(:status_50_pct_complete) { create(:status, default_done_ratio: 50, name: "50% complete") }
  shared_let(:status_70_pct_complete) { create(:status, default_done_ratio: 70, name: "70% complete") }

  let(:user) { build_stubbed(:user) }
  let(:project) do
    p = build_stubbed(:project)
    allow(p).to receive(:shared_versions).and_return([])

    p
  end
  let(:work_package) do
    build_stubbed(:work_package, project:, status: status_0_pct_complete)
  end
  let(:statuses) { [] }
  let(:contract_class) { WorkPackages::UpdateContract }
  let(:mock_contract) do
    class_double(contract_class,
                 new: mock_contract_instance)
  end
  let(:mock_contract_instance) do
    instance_double(contract_class,
                    assignable_statuses: statuses,
                    errors: contract_errors,
                    validate: contract_valid)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    instance_double(ActiveModel::Errors)
  end
  let(:instance) do
    described_class.new(user:,
                        model: work_package,
                        contract_class: mock_contract)
  end

  shared_examples_for "service call" do |description: nil|
    subject do
      allow(work_package)
        .to receive(:save)

      instance.call(call_attributes)
    end

    it description || "sets the value" do
      all_expected_attributes = {}
      all_expected_attributes.merge!(expected_attributes) if defined?(expected_attributes)
      if defined?(expected_kept_attributes)
        kept = work_package.attributes.slice(*expected_kept_attributes)
        if kept.size != expected_kept_attributes.size
          raise ArgumentError, "expected_kept_attributes contains attributes that are not present in the work_package: " \
                               "#{expected_kept_attributes - kept.keys} not present in #{work_package.attributes}"
        end
        all_expected_attributes.merge!(kept)
      end
      next if all_expected_attributes.blank?

      subject

      aggregate_failures do
        expect(subject).to be_success
        expect(work_package).to have_attributes(all_expected_attributes)
        # work package is not saved and no errors are created by the service
        # (that's contract's responsibility and it is mocked in this test)
        expect(work_package).not_to have_received(:save)
        expect(subject.errors).to be_empty
      end
    end

    context "when the contract does not validate" do
      let(:contract_valid) { false }

      it "is unsuccessful, does not persist the changes and exposes the contract's errors", :aggregate_failures do
        expect(subject).not_to be_success
        expect(work_package).not_to have_received(:save)
        expect(subject.errors).to eql mock_contract_instance.errors
      end
    end
  end

  # Scenarios specified in https://community.openproject.org/wp/40749
  describe "deriving remaining work attribute (remaining_hours)" do
    context "in status-based mode",
            with_settings: { work_package_done_ratio: "status" } do
      context "given a work package with work, remaining work, and status with % complete being set" do
        before do
          work_package.status = status_50_pct_complete
          work_package.done_ratio = work_package.status.default_done_ratio
          work_package.estimated_hours = 10.0
          work_package.remaining_hours = 5.0
          work_package.clear_changes_information
        end

        context "when work is unset" do
          let(:call_attributes) { { estimated_hours: nil } }
          let(:expected_attributes) { { remaining_hours: nil } }

          it_behaves_like "service call", description: "unsets remaining work"
        end

        context "when work is changed" do
          let(:call_attributes) { { estimated_hours: 5.0 } }
          let(:expected_attributes) { { remaining_hours: 2.5 } }

          it_behaves_like "service call", description: "recomputes remaining work accordingly"
        end

        context "when work is changed to a negative value" do
          let(:call_attributes) { { estimated_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[remaining_hours] }

          it_behaves_like "service call",
                          description: "is an error state (to be detected by contract), and remaining work is kept"
        end

        context "when another status is set" do
          let(:call_attributes) { { status: status_70_pct_complete } }
          let(:expected_attributes) { { remaining_hours: 3.0 } }

          it_behaves_like "service call",
                          description: "recomputes remaining work according to the % complete value of the new status"
        end

        context "when floating point operations are inaccurate (2.4000000000000004h)" do
          let(:call_attributes) { { estimated_hours: 8.0, status: status_70_pct_complete } }
          let(:expected_attributes) { { remaining_hours: 2.4 } } # would be 2.4000000000000004 without rounding

          it_behaves_like "service call", description: "remaining work is computed and rounded (2.4)"
        end
      end

      context "given a work package with work and remaining work unset, and a status with 0% complete" do
        before do
          work_package.status = status_0_pct_complete
          work_package.done_ratio = work_package.status.default_done_ratio
          work_package.estimated_hours = nil
          work_package.remaining_hours = nil
          work_package.clear_changes_information
        end

        context "when another status with another % complete value is set" do
          let(:call_attributes) { { status: status_70_pct_complete } }
          let(:expected_attributes) { { remaining_hours: nil } }

          it_behaves_like "service call",
                          description: "remaining work remains unset"
        end

        context "when work is set" do
          let(:call_attributes) { { estimated_hours: 10.0 } }
          let(:expected_attributes) { { remaining_hours: 10.0 } }

          it_behaves_like "service call",
                          description: "remaining work is updated accordingly from work and % complete value of the status"
        end

        context "when work is set to a negative value" do
          let(:call_attributes) { { estimated_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[remaining_hours] }

          it_behaves_like "service call",
                          description: "is an error state (to be detected by contract), and remaining work is kept"
        end

        context "when work is set with 2nd decimal rounding up" do
          let(:call_attributes) { { estimated_hours: 3.567 } }
          let(:expected_attributes) { { estimated_hours: 3.57, remaining_hours: 3.57 } }

          it_behaves_like "service call",
                          description: "values are rounded up to 2 decimals and set to the same value"
        end
      end
    end
  end

  # Scenarios specified in https://community.openproject.org/wp/40749
  describe "deriving % complete attribute (done_ratio)" do
    context "in status-based mode",
            with_settings: { work_package_done_ratio: "status" } do
      context "given a work package with a status with 50% complete" do
        before do
          work_package.status = status_50_pct_complete
          work_package.done_ratio = work_package.status.default_done_ratio
          work_package.clear_changes_information
        end

        context "when another status with another % complete value is set" do
          let(:call_attributes) { { status: status_70_pct_complete } }
          let(:expected_attributes) { { done_ratio: 70 } }

          it_behaves_like "service call", description: "sets the % complete value to the status default % complete value"
        end
      end
    end

    context "in work-based mode",
            with_settings: { work_package_done_ratio: "field" } do
      context "given a work package with work, remaining work, and % complete being set" do
        before do
          work_package.estimated_hours = 10.0
          work_package.remaining_hours = 3.0
          work_package.done_ratio = 70
          work_package.clear_changes_information
        end

        context "when work is unset" do
          let(:call_attributes) { { estimated_hours: nil } }
          let(:expected_attributes) { { remaining_hours: nil, done_ratio: nil } }

          it_behaves_like "service call", description: "unsets remaining work and % complete"
        end

        context "when remaining work is unset" do
          let(:call_attributes) { { remaining_hours: nil } }
          let(:expected_attributes) { { estimated_hours: 10.0, done_ratio: nil } }

          it_behaves_like "service call", description: "keeps work, and unsets % complete"
        end

        context "when both work and remaining work are unset" do
          let(:call_attributes) { { estimated_hours: nil, remaining_hours: nil } }
          let(:expected_attributes) { { done_ratio: nil } }

          it_behaves_like "service call", description: "unsets % complete"
        end

        context "when work is increased" do
          # work changed by +10h
          let(:call_attributes) { { estimated_hours: 10.0 + 10.0 } }
          let(:expected_attributes) do
            { remaining_hours: 3.0 + 10.0, done_ratio: 35 }
          end

          it_behaves_like "service call",
                          description: "remaining work is increased by the same amount, and % complete is updated accordingly"
        end

        context "when work is set to 0h" do
          let(:call_attributes) { { estimated_hours: 0 } }
          let(:expected_attributes) do
            { remaining_hours: 0, done_ratio: nil }
          end

          it_behaves_like "service call",
                          description: "remaining work is set to 0h and % Complete is unset"
        end

        context "when work is decreased" do
          # work changed by -2h
          let(:call_attributes) { { estimated_hours: 10.0 - 2.0 } }
          let(:expected_attributes) do
            { remaining_hours: 3.0 - 2.0, done_ratio: 87 }
          end

          it_behaves_like "service call",
                          description: "remaining work is decreased by the same amount, and % complete is updated accordingly"
        end

        context "when work is decreased below remaining work value" do
          # work changed by -8h
          let(:call_attributes) { { estimated_hours: 10.0 - 8.0 } }
          let(:expected_attributes) do
            { remaining_hours: 0, done_ratio: 100 }
          end

          it_behaves_like "service call",
                          description: "remaining work becomes 0h, and % complete becomes 100%"
        end

        context "when work is changed to a negative value" do
          let(:call_attributes) { { estimated_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[remaining_hours done_ratio] }

          it_behaves_like "service call",
                          description: "is an error state (to be detected by contract), " \
                                       "and % complete and remaining work are kept"
        end

        context "when remaining work is changed" do
          let(:call_attributes) { { remaining_hours: 2 } }
          let(:expected_attributes) { { done_ratio: 80 } }
          let(:expected_kept_attributes) { %w[estimated_hours] }

          it_behaves_like "service call", description: "updates % complete accordingly"
        end

        context "when work and remaining work are both changed to negative values" do
          let(:call_attributes) { { estimated_hours: -10, remaining_hours: -5 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call", description: "is an error state (to be detected by contract), and % Complete is kept"
        end

        context "when work and remaining work are both changed to values with more than 2 decimals" do
          let(:call_attributes) { { estimated_hours: 10.123456, remaining_hours: 5.6789 } }
          let(:expected_attributes) { { estimated_hours: 10.12, remaining_hours: 5.68, done_ratio: 43 } }

          it_behaves_like "service call", description: "rounds work and remaining work to 2 decimals " \
                                                       "and updates % complete accordingly"
        end

        context "when remaining work is changed to a value greater than work" do
          let(:call_attributes) { { remaining_hours: 200.0 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call", description: "is an error state (to be detected by contract), and % Complete is kept"
        end

        context "when remaining work is changed to a negative value" do
          let(:call_attributes) { { remaining_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call", description: "is an error state (to be detected by contract), and % Complete is kept"
        end

        context "when both work and remaining work are changed" do
          let(:call_attributes) { { estimated_hours: 20, remaining_hours: 2 } }
          let(:expected_attributes) { call_attributes.merge(done_ratio: 90) }

          it_behaves_like "service call", description: "updates % complete accordingly"
        end

        context "when work is changed and remaining work is unset" do
          let(:call_attributes) { { estimated_hours: 8.0, remaining_hours: nil } }
          let(:expected_attributes) { call_attributes.dup }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call",
                          description: "% complete is kept and remaining work is kept unset and not recomputed" \
                                       "(error state to be detected by contract)"
        end

        context "when work is increased and remaining work is set to its current value (to prevent it from being increased)" do
          # work changed by +10h
          let(:call_attributes) { { estimated_hours: 10.0 + 10.0, remaining_hours: 3 } }
          let(:expected_attributes) { { remaining_hours: 3.0, done_ratio: 85 } }

          it_behaves_like "service call",
                          description: "remaining work is kept (not increased), and % complete is updated accordingly"
        end
      end

      context "given a work package with work and % complete being set, and remaining work being unset" do
        before do
          work_package.estimated_hours = 10
          work_package.remaining_hours = nil
          work_package.done_ratio = 30
          work_package.clear_changes_information
        end

        context "when work is changed" do
          let(:call_attributes) { { estimated_hours: 20.0 } }
          let(:expected_attributes) { { remaining_hours: 14.0 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call", description: "% complete is kept and remaining work is updated accordingly"
        end

        context "when work is changed to a negative value" do
          let(:call_attributes) { { estimated_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[remaining_hours done_ratio] }

          it_behaves_like "service call",
                          description: "is an error state (to be detected by contract), " \
                                       "and % complete and remaining work are kept"
        end

        context "when remaining work is set" do
          let(:call_attributes) { { remaining_hours: 1.0 } }
          let(:expected_attributes) { call_attributes.merge(done_ratio: 90.0) }
          let(:expected_kept_attributes) { %w[estimated_hours] }

          it_behaves_like "service call", description: "work is kept and % complete is updated accordingly"
        end
      end

      context "given a work package with remaining work and % complete being set, and work being unset" do
        before do
          work_package.estimated_hours = nil
          work_package.remaining_hours = 2.0
          work_package.done_ratio = 50
          work_package.clear_changes_information
        end

        context "when remaining work is changed" do
          let(:call_attributes) { { remaining_hours: 10.0 } }
          let(:expected_attributes) { call_attributes.merge(estimated_hours: 20.0) }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call", description: "% complete is kept and work is updated accordingly"
        end

        context "when % complete is 0% and remaining work is changed to a decimal rounded up" do
          let(:call_attributes) { { remaining_hours: 5.679 } }
          let(:expected_attributes) { { estimated_hours: 5.68, remaining_hours: 5.68 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          before do
            work_package.done_ratio = 0
            work_package.clear_changes_information
          end

          it_behaves_like "service call",
                          description: "% complete is kept, values are rounded, and work is updated accordingly"
        end

        context "when work is set" do
          let(:call_attributes) { { estimated_hours: 10.0 } }
          let(:expected_attributes) { call_attributes.merge(done_ratio: 80.0) }
          let(:expected_kept_attributes) { %w[remaining_hours] }

          it_behaves_like "service call", description: "remaining work is kept and % complete is updated accordingly"
        end
      end

      context "given a work package with work being set, and remaining work and % complete being unset" do
        before do
          work_package.estimated_hours = 10
          work_package.remaining_hours = nil
          work_package.done_ratio = nil
          work_package.clear_changes_information
        end

        context "when work is changed" do
          let(:call_attributes) { { estimated_hours: 20.0 } }
          let(:expected_attributes) { { remaining_hours: 20.0, done_ratio: 0 } }

          it_behaves_like "service call", description: "remaining work is set to the same value and % complete is set to 0%"
        end

        context "when work is changed and remaining work is unset" do
          let(:call_attributes) { { estimated_hours: 10.0, remaining_hours: nil } }
          let(:expected_attributes) { call_attributes.dup }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call",
                          description: "% complete is kept and remaining work is kept unset and not recomputed" \
                                       "(error state to be detected by contract)"
        end

        context "when work is changed to a negative value" do
          let(:call_attributes) { { estimated_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[remaining_hours done_ratio] }

          it_behaves_like "service call",
                          description: "is an error state (to be detected by contract), " \
                                       "and % complete and remaining work are kept"
        end
      end

      context "given a work package with remaining work being set, and work and % complete being unset" do
        before do
          work_package.estimated_hours = nil
          work_package.remaining_hours = 6.0
          work_package.done_ratio = nil
          work_package.clear_changes_information
        end

        context "when work is set" do
          let(:call_attributes) { { estimated_hours: 10.0 } }
          let(:expected_attributes) { { done_ratio: 40 } }
          let(:expected_kept_attributes) { %w[remaining_hours] }

          it_behaves_like "service call",
                          description: "remaining work is kept to the same value and % complete is updated accordingly"
        end

        context "when work is changed to a negative value" do
          let(:call_attributes) { { estimated_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[remaining_hours done_ratio] }

          it_behaves_like "service call",
                          description: "is an error state (to be detected by contract), " \
                                       "and % complete and remaining work are kept"
        end

        context "when remaining work is changed" do
          let(:call_attributes) { { remaining_hours: 12.0 } }
          let(:expected_attributes) { { estimated_hours: 12.0, done_ratio: 0 } }

          it_behaves_like "service call",
                          description: "work is set to the same value and % complete is set to 0%"
        end

        context "when remaining work is changed to a negative value" do
          let(:call_attributes) { { remaining_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[estimated_hours done_ratio] }

          it_behaves_like "service call",
                          description: "is an error state (to be detected by contract), " \
                                       "and % complete and work are kept"
        end
      end

      context "given a work package with work and remaining work unset, and % complete being set" do
        before do
          work_package.estimated_hours = nil
          work_package.remaining_hours = nil
          work_package.done_ratio = 60
          work_package.clear_changes_information
        end

        context "when work is set" do
          let(:call_attributes) { { estimated_hours: 10.0 } }
          let(:expected_attributes) { { remaining_hours: 4.0 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call", description: "% complete is kept and remaining work is updated accordingly"
        end

        context "when work is set to a number with with 4 decimals" do
          let(:call_attributes) { { estimated_hours: 2.5678 } }
          let(:expected_attributes) { { estimated_hours: 2.57, remaining_hours: 1.03 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call",
                          description: "% complete is kept, work is rounded to 2 decimals, " \
                                       "and remaining work is updated and rounded to 2 decimals"
        end

        context "when work is set to a string" do
          let(:call_attributes) { { estimated_hours: "I am a string" } }
          let(:expected_attributes) { { estimated_hours: 0.0, remaining_hours: 0.0 } }

          it "keeps the original string value in the _before_type_cast method " \
             "so that validation can detect it is invalid" do
            allow(work_package).to receive(:save)
            instance.call(call_attributes)

            expect(work_package.estimated_hours_before_type_cast).to eq("I am a string")
          end
        end

        context "when work and remaining work are set" do
          let(:call_attributes) { { estimated_hours: 10.0, remaining_hours: 0 } }
          let(:expected_attributes) { call_attributes.merge(done_ratio: 100) }

          it_behaves_like "service call", description: "% complete is updated accordingly"
        end

        context "when work is set and remaining work is unset" do
          let(:call_attributes) { { estimated_hours: 10.0, remaining_hours: nil } }
          let(:expected_attributes) { call_attributes.dup }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call",
                          description: "% complete is kept and remaining work is kept unset and not recomputed" \
                                       "(error state to be detected by contract)"
        end

        context "when work and remaining work are both set to negative values" do
          let(:call_attributes) { { estimated_hours: -10, remaining_hours: -5 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call", description: "is an error state (to be detected by contract), and % Complete is kept"
        end
      end

      context "given a work package with work, remaining work, and % complete being unset" do
        before do
          work_package.estimated_hours = nil
          work_package.remaining_hours = nil
          work_package.done_ratio = nil
          work_package.clear_changes_information
        end

        context "when work is set" do
          let(:call_attributes) { { estimated_hours: 10.0 } }
          let(:expected_attributes) do
            { remaining_hours: 10.0, done_ratio: 0 }
          end

          it_behaves_like "service call", description: "remaining work is set to the same value and % complete is set to 0%"
        end

        context "when work is set to a negative value" do
          let(:call_attributes) { { estimated_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[remaining_hours done_ratio] }

          it_behaves_like "service call",
                          description: "is an error state (to be detected by contract), " \
                                       "and % complete and remaining work are kept"
        end

        context "when remaining work is set" do
          let(:call_attributes) { { remaining_hours: 10.0 } }
          let(:expected_attributes) { { estimated_hours: 10.0, done_ratio: 0 } }

          it_behaves_like "service call", description: "work is set to the same value and % complete is set to 0%"
        end

        context "when remaining work is set to a negative value" do
          let(:call_attributes) { { remaining_hours: -1.0 } }
          let(:expected_kept_attributes) { %w[estimated_hours done_ratio] }

          it_behaves_like "service call",
                          description: "is an error state (to be detected by contract), " \
                                       "and % complete and work are kept"
        end

        context "when remaining work is set and work is unset" do
          let(:call_attributes) { { estimated_hours: nil, remaining_hours: 6.7 } }
          let(:expected_attributes) { call_attributes.dup }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call",
                          description: "% complete is kept and work is kept unset and not recomputed" \
                                       "(error state to be detected by contract)"
        end
      end
    end
  end
end
