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

RSpec.describe WorkPackagesHelper do
  let(:stub_work_package) { build_stubbed(:work_package, type: stub_type) }
  let(:stub_project) { build_stubbed(:project) }
  let(:stub_type) { build_stubbed(:type) }
  let(:stub_user) { build_stubbed(:user) }
  let(:open_status) { build_stubbed(:status, is_closed: false) }
  let(:closed_status) { build_stubbed(:status, is_closed: true) }

  describe "#link_to_work_package" do
    before do
      stub_work_package.status = open_status
    end

    describe "without parameters" do
      it "returns a link to the work package with type and id as the text if type is set" do
        link_text = Regexp.new("^#{stub_type.name} ##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package)).to have_css(
          "a[href='#{work_package_path(stub_work_package)}']", text: link_text
        )
      end

      it "additionally returns the subject" do
        text = Regexp.new("#{stub_work_package.subject}$")
        expect(helper.link_to_work_package(stub_work_package)).to have_text(text)
      end

      it "prepends an invisible closed information if the work package is closed" do
        stub_work_package.status = closed_status

        expect(helper.link_to_work_package(stub_work_package)).to have_css("a span.hidden-for-sighted", text: "closed")
      end

      it "omits the invisible closed information if told so even though the work package is closed" do
        stub_work_package.status = closed_status

        expect(helper.link_to_work_package(stub_work_package, no_hidden: true))
          .to have_no_css("a span.hidden-for-sighted", text: "closed")
      end
    end

    describe "with the all_link option provided" do
      it "returns a link to the work package with the type, id, and subject as the text" do
        link_text = Regexp.new("^#{stub_type} ##{stub_work_package.id}: #{stub_work_package.subject}$")
        expect(helper.link_to_work_package(stub_work_package,
                                           all_link: true)).to have_css(
                                             "a[href='#{work_package_path(stub_work_package)}']", text: link_text
                                           )
      end
    end

    describe "when truncating" do
      it "truncates the subject if the subject is longer than the specified amount" do
        stub_work_package.subject = "12345678"

        text = Regexp.new("1234...$")
        expect(helper.link_to_work_package(stub_work_package, truncate: 7)).to have_text(text)
      end

      it "does not truncate the subject if the subject is shorter than the specified amount" do
        stub_work_package.subject = "1234567"

        text = Regexp.new("1234567$")
        expect(helper.link_to_work_package(stub_work_package, truncate: 7)).to have_text(text)
      end
    end

    describe "when omitting the subject" do
      it "omits the subject" do
        expect(helper.link_to_work_package(stub_work_package, subject: false)).to have_no_text(stub_work_package.subject)
      end
    end

    describe "when omitting the type" do
      it "omits the type" do
        link_text = Regexp.new("^##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package,
                                           type: false)).to have_css("a[href='#{work_package_path(stub_work_package)}']",
                                                                     text: link_text)
      end
    end

    describe "with a project" do
      let(:text) { Regexp.new("^#{stub_project.name} -") }

      before do
        stub_work_package.project = stub_project
      end

      it "prepends the project if parameter set to true" do
        expect(helper.link_to_work_package(stub_work_package, project: true)).to have_text(text)
      end

      it "does not include the project name if the parameter is missing/false" do
        expect(helper.link_to_work_package(stub_work_package)).to have_no_text(text)
      end
    end

    describe "when only wanting the id" do
      it "returns a link with the id as text only" do
        link_text = Regexp.new("^##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package,
                                           id_only: true)).to have_css("a[href='#{work_package_path(stub_work_package)}']",
                                                                       text: link_text)
      end

      it "does not have the subject as text" do
        expect(helper.link_to_work_package(stub_work_package, id_only: true)).to have_no_text(stub_work_package.subject)
      end
    end

    describe "when only wanting the subject" do
      it "returns a link with the subject as text" do
        link_text = Regexp.new("^#{stub_work_package.subject}$")
        expect(helper.link_to_work_package(stub_work_package,
                                           subject_only: true)).to have_css(
                                             "a[href='#{work_package_path(stub_work_package)}']", text: link_text
                                           )
      end
    end

    describe "with the status displayed" do
      it "returns a link with the status name contained in the text" do
        link_text = Regexp.new("^#{stub_type.name} ##{stub_work_package.id} #{stub_work_package.status}$")
        expect(helper.link_to_work_package(stub_work_package,
                                           status: true)).to have_css("a[href='#{work_package_path(stub_work_package)}']",
                                                                      text: link_text)
      end
    end
  end

  describe "#work_package_css_classes" do
    let(:statuses) { (1..5).map { |_i| build_stubbed(:status) } }
    let(:priority) { build_stubbed(:priority, is_default: true) }
    let(:status) { statuses[0] }
    let(:stub_work_package) do
      build_stubbed(:work_package,
                    status:,
                    priority:)
    end

    it "always has the work_package class" do
      expect(helper.work_package_css_classes(stub_work_package)).to include("work_package")
    end

    it "returns the position of the work_package's status" do
      stub_work_package.status = open_status
      allow(open_status).to receive(:position).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include("status-5")
    end

    it "returns the position of the work_package's priority" do
      allow(priority).to receive(:position).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include("priority-5")
    end

    it "has a closed class if the work_package is closed" do
      allow(stub_work_package).to receive(:closed?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).to include("closed")
    end

    it "has no closed class if the work_package is not closed" do
      allow(stub_work_package).to receive(:closed?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include("closed")
    end

    it "has an overdue class if the work_package is overdue" do
      allow(stub_work_package).to receive(:overdue?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).to include("overdue")
    end

    it "has an overdue class if the work_package is not overdue" do
      allow(stub_work_package).to receive(:overdue?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include("overdue")
    end

    it "has a child class if the work_package is a child" do
      allow(stub_work_package).to receive(:child?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).to include("child")
    end

    it "has no child class if the work_package is not a child" do
      allow(stub_work_package).to receive(:child?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include("child")
    end

    it "has a parent class if the work_package is a parent" do
      allow(stub_work_package).to receive(:leaf?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).to include("parent")
    end

    it "has no parent class if the work_package is not a parent" do
      allow(stub_work_package).to receive(:leaf?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include("parent")
    end

    it "has a created-by-me class if the work_package is a created by the current user" do
      stub_user = double("user", logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:author_id).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include("created-by-me")
    end

    it "has no created-by-me class if the work_package is not created by the current user" do
      stub_user = double("user", logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:author_id).and_return(4)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include("created-by-me")
    end

    it "has a created-by-me class if the work_package is the current user is not logged in" do
      expect(helper.work_package_css_classes(stub_work_package)).not_to include("created-by-me")
    end

    it "has a assigned-to-me class if the work_package is a created by the current user" do
      stub_user = double("user", logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:assigned_to_id).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include("assigned-to-me")
    end

    it "has no assigned-to-me class if the work_package is not created by the current user" do
      stub_user = double("user", logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:assigned_to_id).and_return(4)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include("assigned-to-me")
    end

    it "has no assigned-to-me class if the work_package is the current user is not logged in" do
      expect(helper.work_package_css_classes(stub_work_package)).not_to include("assigned-to-me")
    end
  end

  describe "#work_packages_columns_options" do
    it "returns the columns options" do
      expect(helper.work_packages_columns_options)
        .to include(
          { name: "Type", id: "type" },
          { name: "Subject", id: "subject" },
          { name: "Status", id: "status" }
        )
    end
  end

  describe "#selected_project_columns_options",
           with_settings: { work_package_list_default_columns: %w[id subject type status] } do
    it "returns the columns options currently persisted in the setting (in that order)" do
      expect(helper.selected_work_packages_columns_options)
        .to eql([
                  { name: "ID", id: "id" },
                  { name: "Subject", id: "subject" },
                  { name: "Type", id: "type" },
                  { name: "Status", id: "status" }
                ])
    end
  end

  describe "#protected_project_columns_options" do
    it "returns the columns options currently persisted in the setting (in that order)" do
      expect(helper.protected_work_packages_columns_options)
        .to eql([
                  { name: "ID", id: "id" },
                  { name: "Subject", id: "subject" }
                ])
    end
  end
end
