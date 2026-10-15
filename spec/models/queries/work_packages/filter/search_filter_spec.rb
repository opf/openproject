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

RSpec.describe Queries::WorkPackages::Filter::SearchFilter do
  let(:context) { nil }
  let(:value) { "bogus" }
  let(:operator) { "**" }
  let(:subject) { "Some subject" }
  let(:work_package) { create(:work_package, subject:) }
  let(:journal) { work_package.journals.last }
  let(:instance) do
    described_class.create!(name: :search, context:, operator:, values: [value])
  end

  shared_examples "subject, description, and comment filter" do
    subject { WorkPackage.joins(instance.joins).where(instance.where) }

    context "" do
      let!(:work_package) { create(:work_package, subject: "A bogus subject", description: "And a short description") }

      it "finds in subject" do
        instance.values = ["bogus subject"]
        expect(subject)
          .to contain_exactly(work_package)
      end

      it "finds in description" do
        instance.values = ["short description"]
        expect(subject)
          .to contain_exactly(work_package)
      end

      it "finds in comments" do
        journal.notes = "bogus comment"
        journal.save

        instance.values = [journal.notes]
        expect(subject)
          .to contain_exactly(work_package)
      end
    end
  end

  describe "escaping underscores for the filter (Regression #33574)" do
    subject { WorkPackage.joins(instance.joins).where(instance.where) }

    let!(:work_package) { create(:work_package, description: "Some text c_tree_h more text") }
    let!(:no_match) { create(:work_package, description: "Some cotreeoh text") }

    it "finds in description" do
      instance.values = ["c_tree_h"]
      expect(subject)
        .to contain_exactly(work_package)
    end
  end

  describe "partial (not fuzzy) match of string in subject (#29832)" do
    subject { WorkPackage.joins(instance.joins).where(instance.where) }

    let!(:work_package) { create(:work_package, subject: "big old cat") }

    it "finds in subject" do
      instance.values = ["big cat"]
      expect(subject)
        .to contain_exactly(work_package)
    end
  end

  describe "partial match of string in subject and description (#29832)" do
    subject { WorkPackage.joins(instance.joins).where(instance.where) }

    let!(:work_package) { create(:work_package, subject: "big", description: "cat") }

    it "does not match a partial result currently" do
      instance.values = ["big cat"]
      expect(subject)
        .to be_empty
    end
  end

  if OpenProject::Database.allows_tsv?
    context "DB allows tsv" do
      context "with EE" do
        it_behaves_like "subject, description, and comment filter"

        context "WP with attachment" do
          let(:text) { "lorem ipsum" }
          let(:filename) { "plaintext-file.txt" }
          let(:attachment) { create(:attachment, container: work_package, filename:) }
          let(:plaintext_file_handler) do
            Plaintext::Resolver.file_handlers.find { |h| h.accept? attachment.content_type }.tap do |plaintext_file_handler|
              if plaintext_file_handler.nil?
                fail "Plaintext::FileHandler not found for content type #{attachment.content_type}"
              end
            end
          end

          before do
            allow(plaintext_file_handler).to receive(:text).and_return(text)
          end

          it "finds in attachment content" do
            perform_enqueued_jobs

            instance.values = ["ipsum"]
            expect(WorkPackage.joins(instance.joins).where(instance.where))
              .to contain_exactly(work_package)
          end

          it "finds in attachment file name" do
            perform_enqueued_jobs

            instance.values = [filename]
            expect(WorkPackage.joins(instance.joins).where(instance.where))
              .to contain_exactly(work_package)
          end
        end

        context "with two attachments" do
          let(:text) { "lorem ipsum" }
          let(:filename) { "plaintext-file.txt" }
          let(:attachment) { create(:attachment, container: work_package, filename:) }
          let(:attachment2) { create(:attachment, container: work_package, filename:) }
          let(:plaintext_file_handler) do
            Plaintext::Resolver.file_handlers.find { |h| h.accept? attachment.content_type }.tap do |plaintext_file_handler|
              if plaintext_file_handler.nil?
                fail "Plaintext::FileHandler not found for content type #{attachment.content_type}"
              end
            end
          end

          before do
            allow(plaintext_file_handler).to receive(:text).and_return(text)
          end

          context "with the search string in both attachments" do
            let(:text) { "plaintext lorem ipsum" }

            it "only finds work package once" do
              perform_enqueued_jobs

              instance.values = ["plaintext"]

              expect(WorkPackage.joins(instance.joins).where(instance.where).pluck(:id))
                .to contain_exactly(work_package.id)
            end
          end
        end
      end

      it_behaves_like "basic query filter" do
        let(:type) { :search }
        let(:class_key) { :search }

        describe "#available?" do
          it "is available" do
            expect(instance).to be_available
          end
        end

        describe "#allowed_values" do
          it "is nil" do
            expect(instance.allowed_values).to be_nil
          end
        end

        describe "#valid_values!" do
          it "is a noop" do
            instance.values = ["none", "is", "changed"]

            instance.valid_values!

            expect(instance.values)
              .to contain_exactly("none", "is", "changed")
          end
        end

        describe "#available_operators" do
          it "supports **" do
            expect(instance.available_operators)
              .to eql [Queries::Operators::Everywhere]
          end
        end

        it_behaves_like "non ar filter"
      end
    end
  else
    context "DB does not support TSV" do
      context "WP without attachment" do
        it_behaves_like "subject, description, and comment filter"
      end
    end
  end

  describe "#filter_configurations" do
    shared_let(:type) { create(:type) }
    shared_let(:other_type) { create(:type) }
    shared_let(:here) { create(:project, types: [type]) }
    shared_let(:elsewhere) { create(:project, types: [other_type]) }

    shared_let(:searchable_here) do
      create(:string_wp_custom_field, searchable: true, is_filter: true, types: [type])
    end
    shared_let(:searchable_elsewhere) do
      create(:string_wp_custom_field, searchable: true, is_filter: true, types: [other_type])
    end

    def searched_columns(for_project)
      described_class.create!(name: :search, context: instance_double(Query, project: for_project),
                              operator: "**", values: ["x"])
                     .send(:custom_field_configurations)
                     .map(&:filter_name)
    end

    it "searches only the custom fields the project's form configuration shows" do
      expect(searched_columns(here)).to include(searchable_here.column_name)
      expect(searched_columns(here)).not_to include(searchable_elsewhere.column_name)
    end
  end
end
