#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe UserMailer do
  describe 'journal details' do
    let(:type_standard) { FactoryGirl.build_stubbed(:type_standard) }
    let(:user) { FactoryGirl.build_stubbed(:user) }
    let(:journal) { FactoryGirl.build_stubbed(:work_package_journal) }
    let(:work_package) { FactoryGirl.build_stubbed(:work_package,
                                                   type: type_standard) }

    subject { UserMailer.issue_updated(user, journal).body.encoded }

    before do
      work_package.stub(:reload).and_return(work_package)

      journal.stub(:journable).and_return(work_package)
      journal.stub(:user).and_return(user)

      Setting.stub(:mail_from).and_return('john@doe.com')
      Setting.stub(:host_name).and_return('mydomain.foo')
      Setting.stub(:protocol).and_return('http')
      Setting.stub(:default_language).and_return('en')
    end

    describe 'plain text mail' do
      before do
        Setting.stub(:plain_text_mail).and_return('1')
      end

      describe 'done ration modifications' do
        context 'changed done ratio' do
          before do
            journal.stub(:details).and_return({"done_ratio" => [40, 100]})
          end

          it 'displays changed done ratio' do
            should match("% done changed from 40 to 100")
          end
        end

        context 'new done ratio' do
          before do
            journal.stub(:details).and_return({"done_ratio" => [nil, 100]})
          end

          it 'displays new done ratio' do
            should match("% done changed from 0 to 100")
          end
        end

        context 'deleted done ratio' do
          before do
            journal.stub(:details).and_return({"done_ratio" => [50, nil]})
          end

          it 'displays deleted done ratio' do
            should match("% done changed from 50 to 0")
          end
        end
      end

      describe 'start_date attribute' do
        context 'format the start date' do
          before do
            journal.stub(:details).and_return({"start_date" => ['2010-01-01', '2010-01-31']})
          end

          it 'old date should be formatted' do
            should match("01/01/2010")
          end

          it 'new date should be formatted' do
            should match("01/31/2010")
          end
        end
      end

      describe 'due_date attribute' do
        context 'format the end date' do
          before do
            journal.stub(:details).and_return({"due_date" => ['2010-01-01', '2010-01-31']})
          end

          it 'old date should be formatted' do
            should match("01/01/2010")
          end

          it 'new date should be formatted' do
            should match("01/31/2010")
          end
        end
      end

      describe 'project attribute' do
        let(:project_1) { FactoryGirl.create(:project) }
        let(:project_2) { FactoryGirl.create(:project) }

        before do
          journal.stub(:details).and_return({"project_id" => [project_1.id, project_2.id]})
        end

        it "shows the old project's name" do
          should match(project_1.name)
        end

        it "shows the new project's name" do
          should match(project_2.name)
        end
      end

      describe 'attribute issue status' do
        let(:status_1) { FactoryGirl.create(:status) }
        let(:status_2) { FactoryGirl.create(:status) }

        before do
          journal.stub(:details).and_return({"status_id" => [status_1.id, status_2.id]})
        end

        it "shows the old status' name" do
          should match(status_1.name)
        end

        it "shows the new status' name" do
          should match(status_2.name)
        end
      end

      describe 'attribute type' do
        let(:type_1) { FactoryGirl.create(:type_standard) }
        let(:type_2) { FactoryGirl.create(:type_bug) }

        before do
          journal.stub(:details).and_return({"type_id" => [type_1.id, type_2.id]})
        end

        it "shows the old type's name" do
          should match(type_1.name)
        end

        it "shows the new type's name" do
          should match(type_2.name)
        end
      end

      describe 'attribute assigned to' do
        let(:assignee_1) { FactoryGirl.create(:user) }
        let(:assignee_2) { FactoryGirl.create(:user) }

        before do
          journal.stub(:details).and_return({"assigned_to_id" => [assignee_1.id, assignee_2.id]})
        end

        it "shows the old assignee's name" do
          should match(assignee_1.name)
        end

        it "shows the new assignee's name" do
          should match(assignee_2.name)
        end
      end

      describe 'attribute priority' do
        let(:priority_1) { FactoryGirl.create(:priority) }
        let(:priority_2) { FactoryGirl.create(:priority) }

        before do
          journal.stub(:details).and_return({"priority_id" => [priority_1.id, priority_2.id]})
        end

        it "shows the old priority's name" do
          should match(priority_1.name)
        end

        it "shows the new priority's name" do
          should match(priority_2.name)
        end
      end

      describe 'attribute category' do
        let(:category_1) { FactoryGirl.create(:category) }
        let(:category_2) { FactoryGirl.create(:category) }

        before do
          journal.stub(:details).and_return({"category_id" => [category_1.id, category_2.id]})
        end

        it "shows the old category's name" do
          should match(category_1.name)
        end

        it "shows the new category's name" do
          should match(category_2.name)
        end
      end

      describe 'attribute fixed version' do
        let(:version_1) { FactoryGirl.create(:version) }
        let(:version_2) { FactoryGirl.create(:version) }

        before do
          journal.stub(:details).and_return({"fixed_version_id" => [version_1.id, version_2.id]})
        end

        it "shows the old version's name" do
          should match(version_1.name)
        end

        it "shows the new version's name" do
          should match(version_2.name)
        end
      end

      describe 'attribute estimated hours' do
        let(:estimated_hours_1) { 30.5678 }
        let(:estimated_hours_2) { 35.912834 }

        before do
          journal.stub(:details).and_return({"estimated_hours" => [estimated_hours_1, estimated_hours_2]})
        end

        it "shows the old estimated hours" do
          should match('%.2f' % estimated_hours_1)
        end

        it "shows the new estimated hours" do
          should match('%.2f' % estimated_hours_2)
        end
      end

      describe 'custom field' do
        let(:expected_text_1) { "original, unchanged text" }
        let(:expected_text_2) { "modified, new text" }
        let(:custom_field) { FactoryGirl.create :work_package_custom_field,
                                                field_format: "text" }

        before do
          journal.stub(:details).and_return({"custom_fields_#{custom_field.id}" => [expected_text_1, expected_text_2]})
        end

        it "shows the old custom field value" do
          should match(expected_text_1)
        end

        it "shows the new custom field value" do
          should match(expected_text_2)
        end
      end

      describe 'attachments' do
        let(:attachment) { FactoryGirl.create :attachment }

        context 'added' do
          before do
            journal.stub(:details).and_return({"attachments_#{attachment.id}" => [nil, attachment.filename]})
          end

          it "shows the attachment's filename" do
            should match(attachment.filename)
          end

          it "shows status 'added'" do
            should match('added')
          end

          it "shows no status 'deleted'" do
            should_not match('deleted')
          end
        end

        context 'removed' do
          before do
            journal.stub(:details).and_return({"attachments_#{attachment.id}" => [attachment.filename, nil]})
          end

          it "shows the attachment's filename" do
            should match(attachment.filename)
          end

          it "shows no status 'added'" do
            should_not match('added')
          end

          it "shows status 'deleted'" do
            should match('deleted')
          end
        end
      end
    end

    describe 'html mail' do
      let(:expected_translation) { I18n.t(:done_ratio, :scope => [:activerecord,
                                                                  :attributes,
                                                                  :work_package]) }
      let(:expected_prefix) { "<li><strong>#{expected_translation}</strong>" }

      before do
        Setting.stub(:plain_text_mail).and_return('0')
      end

      context 'changed done ratio' do
        let(:expected) { "#{expected_prefix} changed from <i>40</i> to <i>100</i>" }

        before do
          journal.stub(:details).and_return({"done_ratio" => [40, 100]})
        end

        it 'displays changed done ratio' do
          should match(expected)
        end
      end

      context 'new done ratio' do
        let(:expected) { "#{expected_prefix} changed from <i>0</i> to <i>100</i>" }

        before do
          journal.stub(:details).and_return({"done_ratio" => [nil, 100]})
        end

        it 'displays new done ratio' do
          should match(expected)
        end
      end

      context 'deleted done ratio' do
        let(:expected) { "#{expected_prefix} changed from <i>50</i> to <i>0</i>" }

        before do
          journal.stub(:details).and_return({"done_ratio" => [50, nil]})
        end

        it 'displays deleted done ratio' do
          should match(expected)
        end
      end
    end
  end
end
