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

RSpec.describe API::V3::Activities::ActivityRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }
  let(:other_user) { build_stubbed(:user) }
  let(:work_package) { journal.journable }
  let(:notes) { "My notes" }
  let(:journal) do
    build_stubbed(:work_package_journal, notes:, user: other_user).tap do |journal|
      allow(journal)
        .to receive(:get_changes)
        .and_return(changes)
    end
  end
  let(:changes) { { subject: ["first subject", "second subject"] } }
  let(:permissions) { %i(edit_work_package_notes) }
  let(:representer) { described_class.new(journal, current_user:) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project *permissions, project: work_package.project
    end

    login_as(current_user)
  end

  subject(:generated) { representer.to_json }

  describe "properties" do
    describe "type" do
      context "with notes" do
        let(:notes) { "Some notes" }

        it_behaves_like "property", :_type do
          let(:value) { "Activity::Comment" }
        end
      end

      context "with empty notes" do
        let(:notes) { "" }

        it_behaves_like "property", :_type do
          let(:value) { "Activity" }
        end
      end

      context "with empty notes and empty changes" do
        let(:notes) { "" }
        let(:changes) { {} }

        it_behaves_like "property", :_type do
          let(:value) { "Activity::Comment" }
        end
      end
    end

    describe "id" do
      it_behaves_like "property", :id do
        let(:value) { journal.id }
      end
    end

    describe "createdAt" do
      it_behaves_like "has UTC ISO 8601 date and time" do
        let(:date) { journal.created_at }
        let(:json_path) { "createdAt" }
      end
    end

    describe "updatedAt" do
      it_behaves_like "has UTC ISO 8601 date and time" do
        let(:date) { journal.updated_at }
        let(:json_path) { "updatedAt" }
      end
    end

    describe "version" do
      it_behaves_like "property", :version do
        let(:value) { journal.version }
      end
    end

    describe "comment" do
      it_behaves_like "API V3 formattable", "comment" do
        let(:format) { "markdown" }
        let(:raw) { journal.notes }
        let(:html) { "<p class=\"op-uc-p\">#{journal.notes}</p>" }
      end

      context "if having no change and notes" do
        let(:notes) { "" }
        let(:changes) { {} }

        it_behaves_like "API V3 formattable", "comment" do
          let(:format) { "markdown" }
          let(:raw) { "_#{I18n.t(:"journals.changes_retracted")}_" }
          let(:html) { "<p class=\"op-uc-p\"><em>#{I18n.t(:"journals.changes_retracted")}</em></p>" }
        end
      end
    end

    describe "details" do
      it { is_expected.to have_json_path("details") }

      it { is_expected.to have_json_size(journal.details.count).at_path("details") }

      it "renders all details as formattable" do
        (0..journal.details.count - 1).each do |x|
          expect(subject).to be_json_eql("custom".to_json).at_path("details/#{x}/format")
          expect(subject).to have_json_path("details/#{x}/raw")
          expect(subject).to have_json_path("details/#{x}/html")
        end
      end
    end
  end

  describe "_links" do
    describe "self" do
      it_behaves_like "has an untitled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.activity journal.id }
      end
    end

    describe "workPackage" do
      it_behaves_like "has a titled link" do
        let(:link) { "workPackage" }
        let(:href) { api_v3_paths.work_package work_package.id }
        let(:title) { work_package.subject }
      end
    end

    describe "user" do
      it_behaves_like "has an untitled link" do
        let(:link) { "user" }
        let(:href) { api_v3_paths.user other_user.id }
      end
    end

    describe "update" do
      let(:link) { "update" }
      let(:href) { api_v3_paths.activity(journal.id) }

      it_behaves_like "has an untitled link"

      context "with a non own journal having edit_work_package_notes permission" do
        it_behaves_like "has an untitled link"
      end

      context "with a non own journal having only edit_own work_package_notes permission" do
        let(:permissions) { %i(edit_own_work_package_notes) }

        it_behaves_like "has no link"
      end
    end
  end
end
