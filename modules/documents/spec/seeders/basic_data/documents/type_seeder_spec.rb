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
require_module_spec_helper

RSpec.describe BasicData::Documents::TypeSeeder do
  include_context "with basic seed data", edition: "standard"

  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

  let(:data_hash) do
    YAML.load <<~SEEDING_DATA_YAML
      document_types:
        - reference: doc_type_note
          name: Note
          is_default: true
        - reference: doc_type_idea
          name: Idea
          is_default: false
        - reference: doc_type_proposal
          name: Proposal
          is_default: false
    SEEDING_DATA_YAML
  end

  before do
    DocumentType.destroy_all
  end

  describe "#seed!" do
    context "when no document types exist" do
      it "seeds all types from seed data" do
        expect { seeder.seed! }
          .to change(DocumentType, :count)
          .from(0).to(3)
      end

      it "sets the correct default type" do
        seeder.seed!

        default_type = DocumentType.find_by(is_default: true)
        expect(default_type.name).to eq("Note")
      end

      it "stores references for all seeded types" do
        seeder.seed!

        expect(seed_data.find_reference("doc_type_note")).to eq(DocumentType.find_by(name: "Note"))
        expect(seed_data.find_reference("doc_type_idea")).to eq(DocumentType.find_by(name: "Idea"))
        expect(seed_data.find_reference("doc_type_proposal")).to eq(DocumentType.find_by(name: "Proposal"))
      end
    end

    context "when document types already exist" do
      before do
        create(:document_type, name: "Note")
        create(:document_type, name: "Custom Type", is_default: true)
      end

      it "does not seed additional types" do
        expect { seeder.seed! }
          .not_to change(DocumentType, :count)
      end

      it "does not modify existing types" do
        seeder.seed!

        expect(DocumentType.find_by(name: "Custom Type", is_default: true)).to be_present
      end

      it "stores references for existing types matching seed data names" do
        seeder.seed!

        expect(seed_data.find_reference("doc_type_note")).to eq(DocumentType.find_by(name: "Note"))
      end
    end
  end
end
