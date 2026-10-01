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

RSpec.describe Queries::Projects::Filters::TypeaheadFilter do
  include_context "filter tests"
  let(:values) { ["A name"] }
  let(:model) { Project }

  it_behaves_like "basic query filter" do
    let(:class_key) { :typeahead }
    let(:human_name) { "Search" }
    let(:type) { :search }
    let(:model) { Project }

    describe "#allowed_values" do
      it "is nil" do
        expect(instance.allowed_values).to be_nil
      end
    end
  end

  describe "#apply_to" do
    # The project pickers send the "**" operator, the API's "name_and_identifier"
    # filter sends "~". Both have to find a project by either column.
    shared_examples_for "matching by name and by identifier" do
      let!(:project) { create(:project, name: "Acme Website Redesign", identifier: "libris-nova") }

      def matches(term)
        described_class
          .create!(operator:, values: [term])
          .apply_to(Project.all)
      end

      it "matches on a part of the name" do
        expect(matches("website")).to contain_exactly(project)
      end

      it "matches on a part of the identifier the name does not contain" do
        expect(matches("libris")).to contain_exactly(project)
      end

      it "matches nothing when neither column contains the term" do
        expect(matches("nowhere")).to be_empty
      end
    end

    context "with the ~ operator" do
      let(:operator) { "~" }

      it_behaves_like "matching by name and by identifier"
    end

    context "with the ** operator" do
      let(:operator) { "**" }

      it_behaves_like "matching by name and by identifier"

      # Every typed word is a condition of its own, so the words may appear in
      # any order and need not be adjacent.
      it "matches when the words appear out of order" do
        project = create(:project, name: "Acme Website Redesign", identifier: "libris-nova")

        expect(described_class.create!(operator: "**", values: ["redesign acme"]).apply_to(Project.all))
          .to contain_exactly(project)
      end

      it "matches when one word is in the name and another in the identifier" do
        project = create(:project, name: "Acme Website Redesign", identifier: "libris-nova")

        expect(described_class.create!(operator: "**", values: ["acme nova"]).apply_to(Project.all))
          .to contain_exactly(project)
      end

      it "requires every word to match" do
        create(:project, name: "Acme Website Redesign", identifier: "libris-nova")

        expect(described_class.create!(operator: "**", values: ["acme nowhere"]).apply_to(Project.all))
          .to be_empty
      end
    end
  end
end
