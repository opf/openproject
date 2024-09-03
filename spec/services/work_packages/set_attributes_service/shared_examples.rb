# frozen_string_literal: true

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

def to_work_package_field(name)
  {
    work: :estimated_hours,
    remaining_work: :remaining_hours,
    percent_complete: :done_ratio
  }.fetch(name, name)
end

# Sets values on a work package, calls a `DeriveProgressValuesBase` instance and
# check if the work_package as been updated as expected.
#
# * Use `let(:set_attributes)` to define the values to set on the work package:
#
#     let(:set_attributes) { { estimated_hours: 10.0, remaining_hours: 1.0 } }
#
# * Use `let(:expected_derived_attributes)` to define the expected attribute
#   values after derivation:
#
#     let(:expected_derived_attributes) { { done_ratio: 90 } }
#
# * Use `let(:expected_kept_attributes)` to define the attributes which are
#   expected to not change:
#
#     let(:expected_kept_attributes) { %w[estimated_hours] }
RSpec.shared_examples_for "update progress values" do |description:, expected_hints:|
  subject do
    allow(work_package)
      .to receive(:save)

    described_class.new(work_package).call
  end

  it description do
    work_package.attributes = set_attributes
    all_expected_attributes = {}
    all_expected_attributes.merge!(expected_derived_attributes) if defined?(expected_derived_attributes)
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
      expect(work_package).to have_attributes(all_expected_attributes)
      expect(work_package).to have_attributes(set_attributes.except(*all_expected_attributes.keys))
      if expected_hints
        expected_hints = expected_hints.transform_keys { to_work_package_field(_1) }
        expect(work_package.derived_progress_hints).to eq(expected_hints)
      end
      # work package is not saved and no errors are created
      expect(work_package).not_to have_received(:save)
      expect(work_package.errors).to be_empty
    end
  end
end
