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

RSpec.describe Queries::WorkPackages::Selects::ExactMatchSelect do
  describe ".exact_match_condition_sql" do
    subject(:sql) { described_class.exact_match_condition_sql(query_string) }

    def ranked_ids(ids)
      WorkPackage.where(id: ids).order(Arel.sql("#{sql} DESC"), id: :asc).pluck(:id)
    end

    context "when the query string is blank" do
      let(:query_string) { "" }

      it { is_expected.to be_nil }
    end

    context "when the query string is whitespace-only" do
      let(:query_string) { "   " }

      it { is_expected.to be_nil }
    end

    context "when the query string has multiple words" do
      let(:query_string) { "epic gorilla" }

      it { is_expected.to be_nil }
    end

    context "when the query string is a plain numeric id" do
      let!(:exact_work_package)  { create(:work_package) }
      let!(:prefix_work_package) { create(:work_package) }
      let(:query_string) { "5" }

      before do
        WorkPackage.where(id: exact_work_package.id).update_all(id: 5)
        WorkPackage.where(id: prefix_work_package.id).update_all(id: 50)
      end

      it "ranks the exact numeric id above one that merely starts with it" do
        expect(ranked_ids([5, 50]).first).to eq(5)
      end
    end

    context "when the query string is a plain numeric id in semantic mode",
            with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
      let!(:prefix_work_package) { create(:work_package, skip_semantic_id_allocation: true) }
      let!(:exact_work_package)  { create(:work_package, skip_semantic_id_allocation: true) }
      let(:query_string) { "5" }

      before do
        exact_work_package.update_columns(sequence_number: 5)
        prefix_work_package.update_columns(sequence_number: 50)
      end

      it "ranks the work package whose sequence number exactly matches above one that merely starts with it" do
        expect(ranked_ids([exact_work_package.id, prefix_work_package.id]))
          .to eq([exact_work_package.id, prefix_work_package.id])
      end
    end

    context "when the query string has a leading '#'" do
      let!(:work_package) { create(:work_package) }
      let(:query_string) { "##{work_package.id}" }

      it "still matches the numeric id exactly" do
        expect(sql).to include(work_package.id.to_s)
      end

      context "in semantic mode",
              with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
        it "still matches the numeric id exactly, as the prefix asks for it explicitly" do
          expect(sql).to include(work_package.id.to_s)
        end
      end
    end

    context "when the query string is a leading-zero numeric string" do
      let(:query_string) { "007" }

      it { is_expected.to be_nil }
    end

    context "when the query string is an exact semantic identifier" do
      let!(:exact_work_package)  { create(:work_package) }
      let!(:prefix_work_package) { create(:work_package) }
      let!(:exact_alias) do
        create(:work_package_semantic_alias, work_package: exact_work_package, identifier: "COM-5")
      end
      let!(:prefix_alias) do
        create(:work_package_semantic_alias, work_package: prefix_work_package, identifier: "COM-50")
      end
      let(:query_string) { "COM-5" }

      context "and the instance is in semantic identifier mode",
              with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
        it "ranks the exact identifier match above one that only shares the prefix" do
          expect(ranked_ids([exact_work_package.id, prefix_work_package.id]).first)
            .to eq(exact_work_package.id)
        end

        context "when the query is given in lower case" do
          let(:query_string) { "com-5" }

          it "still matches COM-5" do
            expect(ranked_ids([exact_work_package.id, prefix_work_package.id]).first)
              .to eq(exact_work_package.id)
          end
        end

        context "when the query is hash-prefixed" do
          let(:query_string) { "#COM-5" }

          it "still ranks the exact identifier match above one that only shares the prefix" do
            expect(ranked_ids([exact_work_package.id, prefix_work_package.id]).first)
              .to eq(exact_work_package.id)
          end
        end
      end

      context "and the instance is in classic identifier mode" do
        context "when the query is hash-prefixed" do
          let(:query_string) { "#COM-5" }

          it "still ranks the exact identifier match above one that only shares the prefix" do
            expect(ranked_ids([exact_work_package.id, prefix_work_package.id]).first)
              .to eq(exact_work_package.id)
          end
        end

        context "when the query is not hash-prefixed" do
          let(:query_string) { "COM-5" }

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
