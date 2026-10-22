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

RSpec.shared_examples_for "progress modal validations" do
  describe "validations" do
    context "when focused_field is not an accepted value (Regression #62075)" do
      it "returns :no_field" do
        work_package = build(:work_package)

        expect(described_class.new(work_package, focused_field: "global-search--input").focused_field).to eq(:no_field)
      end
    end
  end
end

RSpec.shared_examples_for "progress modal submit path" do
  describe "#submit_path" do
    subject(:component) { described_class.new(work_package) }

    before { render_inline(component) }

    context "when the work package is already persisted" do
      let(:work_package) { create(:work_package) }

      it "returns work_package_progress_path with the work package" do
        expect(component.submit_path)
          .to eq(work_package_progress_path(work_package))
      end
    end

    context "when the work package is an unpersisted record" do
      let(:work_package) { WorkPackage.new }

      it "returns work_package_progress_path without a work package id" do
        expect(component.submit_path).to eq("/work_packages/progress")
      end
    end
  end
end

RSpec.shared_examples_for "progress modal help links" do
  describe "#learn_more_href" do
    subject(:component) { render_inline(described_class.new(WorkPackage.new)) }

    it "returns the link to the progress tracking documentation" do
      subject

      expect(page)
        .to have_link("Learn more",
                      href: OpenProject::Static::Links.url_for(:progress_tracking_docs))
    end
  end
end
