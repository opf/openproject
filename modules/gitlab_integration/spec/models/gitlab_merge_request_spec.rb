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

RSpec.describe GitlabMergeRequest do
  describe "Associations" do
    it { is_expected.to have_and_belong_to_many(:work_packages) }
    it { is_expected.to have_many(:gitlab_pipelines).dependent(:destroy) }
    it { is_expected.to belong_to(:gitlab_user).optional }
    it { is_expected.to belong_to(:merged_by).class_name("GitlabUser").optional }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of :gitlab_html_url }
    it { is_expected.to validate_presence_of :number }
    it { is_expected.to validate_presence_of :repository }
    it { is_expected.to validate_presence_of :state }
    it { is_expected.to validate_presence_of :title }
    it { is_expected.to validate_presence_of :gitlab_updated_at }

    context "when it is a partial merge request" do
      let(:merge_request) { build(:gitlab_merge_request, :partial) }

      it { expect(merge_request).not_to validate_presence_of :body }
    end

    context "when it is not a partial merge_request" do
      let(:merge_request) { build(:gitlab_merge_request) }

      it { expect(merge_request).to be_valid }
    end

    describe "labels" do
      it { is_expected.to allow_value(nil).for(:labels) }
      it { is_expected.to allow_value([]).for(:labels) }
      it { is_expected.to allow_value([{ "color" => "#666", "title" => "grey" }]).for(:labels) }

      it "requires both color and title" do
        expect(subject).not_to allow_value([{ "title" => "grey" }]).for(:labels)
      end

      it { is_expected.not_to allow_value([{}]).for(:labels) }

      it "returns an error message when invalid" do
        merge_request = build(:gitlab_merge_request, labels: [{ "title" => "grey" }])
        merge_request.valid?
        expect(merge_request.errors[:labels]).to include("must be an array of hashes with keys: color, title")
      end
    end
  end

  describe "Enums" do
    let(:gitlab_merge_request) { build(:gitlab_merge_request) }

    it do
      expect(gitlab_merge_request).to define_enum_for(:state)
        .with_values(opened: "opened", merged: "merged", closed: "closed")
        .backed_by_column_of_type(:string)
    end
  end

  describe ".without_work_package" do
    subject { described_class.without_work_package }

    let(:merge_request) { create(:gitlab_merge_request, work_packages:) }
    let(:work_packages) { [] }

    before { merge_request }

    it { is_expected.to contain_exactly(merge_request) }

    context "when the pr is linked to a work_package" do
      let(:work_packages) { create_list(:work_package, 1) }

      it { is_expected.to be_empty }
    end
  end

  describe ".find_by_gitlab_identifiers" do
    shared_let(:merge_request) { create(:gitlab_merge_request) }

    it "raises an ArgumentError when no id or url is provided" do
      expect { described_class.find_by_gitlab_identifiers }.to raise_error(ArgumentError, "needs an id or an url")
    end

    context "when the gitlab_id attribute matches" do
      it "finds by gitlab_id" do
        expect(described_class.find_by_gitlab_identifiers(id: merge_request.gitlab_id)).to eql(merge_request)
      end
    end

    context "when the gitlab_html_url attribute matches" do
      it "finds by gitlab_html_url" do
        expect(described_class.find_by_gitlab_identifiers(url: merge_request.gitlab_html_url)).to eql(merge_request)
      end
    end

    context "when the provided gitlab_id does not match" do
      it "is nil" do
        expect(described_class.find_by_gitlab_identifiers(id: merge_request.gitlab_id + 1)).to be_nil
      end
    end

    context "when the provided gitlab_html_url does not match" do
      it "is nil" do
        expect(described_class.find_by_gitlab_identifiers(url: "#{merge_request.gitlab_html_url}zzzz"))
          .to be_nil
      end
    end

    context "when neither match" do
      it "is nil" do
        expect(described_class.find_by_gitlab_identifiers(id: merge_request.gitlab_id + 1,
                                                          url: "#{merge_request.gitlab_html_url}zzzz"))
          .to be_nil
      end
    end

    context "when the provided gitlab_html_url does not match but the gitlab_id does" do
      it "is nil" do
        expect(described_class.find_by_gitlab_identifiers(id: merge_request.gitlab_id,
                                                          url: "#{merge_request.gitlab_html_url}zzzz"))
          .to eql merge_request
      end
    end

    context "when the provided gitlab_html_url does match but the gitlab_id does not" do
      it "is nil" do
        expect(described_class.find_by_gitlab_identifiers(id: merge_request.gitlab_id + 1,
                                                          url: merge_request.gitlab_html_url))
          .to eql merge_request
      end
    end

    context "when neither match but initialize is true" do
      subject(:finder) do
        described_class.find_by_gitlab_identifiers(id: merge_request.gitlab_id + 1,
                                                   url: "#{merge_request.gitlab_html_url}zzzz",
                                                   initialize: true)
      end

      it "returns an merge_request" do
        expect(finder).to be_a(described_class)
      end

      it "returns a new record" do
        expect(finder).to be_new_record
      end

      it "has the provided attributes initialized" do
        expect(finder.attributes.compact)
          .to eql("gitlab_id" => merge_request.gitlab_id + 1,
                  "gitlab_html_url" => "#{merge_request.gitlab_html_url}zzzz")
      end
    end
  end

  describe "#latest_pipelines" do
    context "when multiple pipelines for the same merge request exist" do
      shared_association_default(:gitlab_merge_request) { create(:gitlab_merge_request) }

      context "when the piplelines are for multiple projects" do
        let!(:second_pipeline) { create(:gitlab_pipeline, project_id: 112, gitlab_id: 3) }
        let!(:first_pipeline) { create(:gitlab_pipeline, project_id: 111, gitlab_id: 2) }
        let!(:third_pipeline) { create(:gitlab_pipeline, project_id: 113, gitlab_id: 1) }

        it "they are ordered by project_id asc" do
          expect(gitlab_merge_request.reload.latest_pipelines.to_a)
            .to eql([first_pipeline, second_pipeline, third_pipeline])
        end
      end

      context "when the pipelines are for the same project" do
        let!(:second_pipeline) { create(:gitlab_pipeline, project_id: 123, gitlab_id: 10) }
        let!(:first_pipeline) { create(:gitlab_pipeline, project_id: 123, gitlab_id: 11) }
        let!(:third_pipeline) { create(:gitlab_pipeline, project_id: 123, gitlab_id: 9) }

        it "they are ordered by gitlab_id desc (not name, which is a string consisting of the gitlab_id and would lead to a wrong sorting)" do # rubocop:disable Layout/LineLength
          expect(gitlab_merge_request.reload.latest_pipelines.to_a)
            .to eql([first_pipeline, second_pipeline, third_pipeline])
        end
      end

      context "when the pipelines are for the same project and same gitlab_id" do
        let!(:second_pipeline) { create(:gitlab_pipeline, project_id: 123, gitlab_id: 1, started_at: 2.hours.ago) }
        let!(:first_pipeline) { create(:gitlab_pipeline, project_id: 123, gitlab_id: 1, started_at: 3.hours.ago) }
        let!(:third_pipeline) { create(:gitlab_pipeline, project_id: 123, gitlab_id: 1, started_at: 1.hour.ago) }

        it "only returns the most recent pipeline and ignores the others" do
          expect(gitlab_merge_request.reload.latest_pipelines.to_a)
            .to eql([third_pipeline])
        end
      end
    end
  end
end
