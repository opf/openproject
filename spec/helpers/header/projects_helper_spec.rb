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

RSpec.describe Header::ProjectsHelper do
  # Shorthand for the expected highlight span markup.
  let(:hl) { ->(text) { %(<span class="op-search-highlight">#{text}</span>) } }

  describe "#highlight_name" do
    subject(:result) { helper.send(:highlight_name, name, query_terms) }

    context "with no query terms" do
      let(:name) { "My Project" }
      let(:query_terms) { [] }

      it "returns the plain name" do
        expect(result).to eq "My Project"
      end
    end

    context "when no term matches" do
      let(:name) { "My Project" }
      let(:query_terms) { ["foo"] }

      it "returns the plain name" do
        expect(result).to eq "My Project"
      end
    end

    context "with a single matching term" do
      let(:name) { "My Project" }
      let(:query_terms) { ["Project"] }

      it "wraps the match in a highlight span" do
        expect(result).to eq "My #{hl.call('Project')}"
      end
    end

    context "with a match at the beginning of the name" do
      let(:name) { "Alpha Team" }
      let(:query_terms) { ["Alpha"] }

      it { is_expected.to eq "#{hl.call('Alpha')} Team" }
    end

    context "with a match at the end of the name" do
      let(:name) { "Team Alpha" }
      let(:query_terms) { ["Alpha"] }

      it { is_expected.to eq "Team #{hl.call('Alpha')}" }
    end

    context "when the term matches the full name" do
      let(:name) { "Alpha" }
      let(:query_terms) { ["Alpha"] }

      it { is_expected.to eq hl.call("Alpha") }
    end

    context "with case-insensitive matching" do
      let(:name) { "My PROJECT" }
      let(:query_terms) { ["project"] }

      it "highlights the match using the original casing from the name" do
        expect(result).to eq "My #{hl.call('PROJECT')}"
      end
    end

    context "with multiple occurrences of the same term" do
      let(:name) { "Foo and Foo" }
      let(:query_terms) { ["Foo"] }

      it "highlights every occurrence" do
        expect(result).to eq "#{hl.call('Foo')} and #{hl.call('Foo')}"
      end
    end

    context "with multiple non-overlapping terms" do
      let(:name) { "Alpha Beta" }
      let(:query_terms) { ["Alpha", "Beta"] }

      it "highlights each term independently" do
        expect(result).to eq "#{hl.call('Alpha')} #{hl.call('Beta')}"
      end
    end

    context "with overlapping term matches" do
      # "Over" covers indices 0..4, "erlap" covers 1..6 → merged to 0..6 = "Overlap".
      let(:name) { "Overlap" }
      let(:query_terms) { ["Over", "erlap"] }

      it "merges the overlapping ranges into a single span" do
        expect(result).to eq hl.call("Overlap")
      end
    end

    context "with HTML special characters in the name" do
      let(:name) { "A & B <Project>" }
      let(:query_terms) { ["Project"] }

      it "escapes characters outside the match and leaves the span unescaped" do
        expect(result).to eq "A &amp; B &lt;#{hl.call('Project')}&gt;"
      end
    end
  end
end
