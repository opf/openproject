# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++
require "spec_helper"
require_relative "../shared_modal_examples"

# This file can be safely deleted once the feature flag :percent_complete_edition
# is removed, which should happen for OpenProject 15.0 release.
RSpec.describe WorkPackages::Progress::WorkBased::ModalBodyComponent, "pre 14.4 without percent complete edition",
               type: :component,
               with_flag: { percent_complete_edition: false } do
  include OpenProject::StaticRouting::UrlHelpers

  describe "#should_display_migration_warning?" do
    subject(:component) { described_class.new(work_package) }

    context "when the work package has a percent complete value but no work or remaining work set" do
      let(:work_package) do
        create(:work_package) do |work_package|
          work_package.estimated_hours = nil
          work_package.remaining_hours = nil
          work_package.done_ratio = 10
          work_package.save!(validate: false)
        end
      end

      it "returns true" do
        expect(component.should_display_migration_warning?).to be true
      end
    end

    context "when the work package has a percent complete value and a work value but no remaining work set" do
      let(:work_package) do
        create(:work_package) do |work_package|
          work_package.estimated_hours = 55
          work_package.remaining_hours = nil
          work_package.done_ratio = 10
          work_package.save!(validate: false)
        end
      end

      it "returns false" do
        expect(component.should_display_migration_warning?).to be false
      end
    end
  end
end
