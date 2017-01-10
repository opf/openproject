#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackagesHelper, type: :helper do
  let(:stub_work_package) { FactoryGirl.build_stubbed(:work_package) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project) }
  let(:stub_type) { FactoryGirl.build_stubbed(:type) }
  let(:stub_user) { FactoryGirl.build_stubbed(:user) }

  describe '#link_to_work_package' do
    let(:open_status) { FactoryGirl.build_stubbed(:status, is_closed: false) }
    let(:closed_status) { FactoryGirl.build_stubbed(:status, is_closed: true) }

    before do
      stub_work_package.status = open_status
    end

    describe 'without parameters' do
      it 'should return a link to the work package with the id as the text' do
        link_text = Regexp.new("^##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end

      it 'should return a link to the work package with type and id as the text if type is set' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^#{stub_type.name} ##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end

      it 'should additionally return the subject' do
        text = Regexp.new("#{stub_work_package.subject}$")
        expect(helper.link_to_work_package(stub_work_package)).to have_text(text)
      end

      it 'should prepend an invisible closed information if the work package is closed' do
        stub_work_package.status = closed_status

        expect(helper.link_to_work_package(stub_work_package)).to have_selector('a span.hidden-for-sighted', text: 'closed')
      end
    end

    describe 'with the all_link option provided' do
      it 'should return a link to the work package with the type, id, and subject as the text' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^#{stub_type} ##{stub_work_package.id}: #{stub_work_package.subject}$")
        expect(helper.link_to_work_package(stub_work_package, all_link: true)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end
    end

    describe 'when truncating' do
      it 'should truncate the subject if the subject is longer than the specified amount' do
        stub_work_package.subject = '12345678'

        text = Regexp.new('1234...$')
        expect(helper.link_to_work_package(stub_work_package, truncate: 7)).to have_text(text)
      end

      it 'should not truncate the subject if the subject is shorter than the specified amount' do
        stub_work_package.subject = '1234567'

        text = Regexp.new('1234567$')
        expect(helper.link_to_work_package(stub_work_package, truncate: 7)).to have_text(text)
      end
    end

    describe 'when omitting the subject' do
      it 'should omit the subject' do
        expect(helper.link_to_work_package(stub_work_package, subject: false)).not_to have_text(stub_work_package.subject)
      end
    end

    describe 'when omitting the type' do
      it 'should omit the type' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package, type: false)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end
    end

    describe 'with a project' do
      let(:text) { Regexp.new("^#{stub_project.name} -") }

      before do
        stub_work_package.project = stub_project
      end

      it 'should prepend the project if parameter set to true' do
        expect(helper.link_to_work_package(stub_work_package, project: true)).to have_text(text)
      end

      it 'should not have the project name if the parameter is missing/false' do
        expect(helper.link_to_work_package(stub_work_package)).not_to have_text(text)
      end
    end

    describe 'when only wanting the id' do
      it 'should return a link with the id as text only even if the work package has a type' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package, id_only: true)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end

      it 'should not have the subject as text' do
        expect(helper.link_to_work_package(stub_work_package, id_only: true)).not_to have_text(stub_work_package.subject)
      end
    end

    describe 'when only wanting the subject' do
      it 'should return a link with the subject as text' do
        link_text = Regexp.new("^#{stub_work_package.subject}$")
        expect(helper.link_to_work_package(stub_work_package, subject_only: true)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end
    end

    describe 'with the status displayed' do
      it 'should return a link with the status name contained in the text' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^#{stub_type.name} ##{stub_work_package.id} #{stub_work_package.status}$")
        expect(helper.link_to_work_package(stub_work_package, status: true)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end
    end
  end

  describe '#work_package_css_classes' do
    let(:statuses) { (1..5).map { |_i| FactoryGirl.build_stubbed(:status) } }
    let(:priority) { FactoryGirl.build_stubbed :priority, is_default: true }
    let(:status) { statuses[0] }
    let(:stub_work_package) {
      FactoryGirl.build_stubbed(:work_package,
                                status: status,
                                priority: priority)
    }

    it 'should always have the work_package class' do
      expect(helper.work_package_css_classes(stub_work_package)).to include('work_package')
    end

    it "should return the position of the work_package's status" do
      status = double('status', is_closed?: false)

      allow(stub_work_package).to receive(:status).and_return(status)
      allow(status).to receive(:position).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include('status-5')
    end

    it "should return the position of the work_package's priority" do
      priority = double('priority')

      allow(stub_work_package).to receive(:priority).and_return(priority)
      allow(priority).to receive(:position).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include('priority-5')
    end

    it 'should have a closed class if the work_package is closed' do
      allow(stub_work_package).to receive(:closed?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).to include('closed')
    end

    it 'should not have a closed class if the work_package is not closed' do
      allow(stub_work_package).to receive(:closed?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('closed')
    end

    it 'should have an overdue class if the work_package is overdue' do
      allow(stub_work_package).to receive(:overdue?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).to include('overdue')
    end

    it 'should not have an overdue class if the work_package is not overdue' do
      allow(stub_work_package).to receive(:overdue?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('overdue')
    end

    it 'should have a child class if the work_package is a child' do
      allow(stub_work_package).to receive(:child?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).to include('child')
    end

    it 'should not have a child class if the work_package is not a child' do
      allow(stub_work_package).to receive(:child?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('child')
    end

    it 'should have a parent class if the work_package is a parent' do
      allow(stub_work_package).to receive(:leaf?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).to include('parent')
    end

    it 'should not have a parent class if the work_package is not a parent' do
      allow(stub_work_package).to receive(:leaf?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('parent')
    end

    it 'should have a created-by-me class if the work_package is a created by the current user' do
      stub_user = double('user', logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:author_id).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include('created-by-me')
    end

    it 'should not have a created-by-me class if the work_package is not created by the current user' do
      stub_user = double('user', logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:author_id).and_return(4)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('created-by-me')
    end

    it 'should not have a created-by-me class if the work_package is the current user is not logged in' do
      expect(helper.work_package_css_classes(stub_work_package)).not_to include('created-by-me')
    end

    it 'should have a assigned-to-me class if the work_package is a created by the current user' do
      stub_user = double('user', logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:assigned_to_id).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include('assigned-to-me')
    end

    it 'should not have a assigned-to-me class if the work_package is not created by the current user' do
      stub_user = double('user', logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:assigned_to_id).and_return(4)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('assigned-to-me')
    end

    it 'should not have a assigned-to-me class if the work_package is the current user is not logged in' do
      expect(helper.work_package_css_classes(stub_work_package)).not_to include('assigned-to-me')
    end
  end
end
