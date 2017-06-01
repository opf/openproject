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

describe WorkPackage, type: :model do
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:user)    { FactoryGirl.create(:user) }

  before do
    FactoryGirl.create :priority, is_default: true
    FactoryGirl.create :default_status
  end

  describe '- Relations ' do
    describe '#project' do
      it 'can read the project w/ the help of the belongs_to association' do
        project          = FactoryGirl.create(:project)
        planning_element = FactoryGirl.create(:work_package,
                                              project_id: project.id)

        planning_element.reload

        expect(planning_element.project).to eq(project)
      end

      it 'can read the responsible w/ the help of the belongs_to association' do
        user             = FactoryGirl.create(:user)
        planning_element = FactoryGirl.create(:work_package,
                                              responsible_id: user.id)

        planning_element.reload

        expect(planning_element.responsible).to eq(user)
      end

      it 'can read the type w/ the help of the belongs_to association' do
        type             = project.types.first
        planning_element = FactoryGirl.create(:work_package,
                                              type_id: type.id,
                                              project: project)

        planning_element.reload

        expect(planning_element.type).to eq(type)
      end

      it 'can read the planning_element_status w/ the help of the belongs_to association' do
        status = FactoryGirl.create(:status)
        work_package = FactoryGirl.create(:work_package,
                                          status_id: status.id)

        work_package.reload

        expect(work_package.status).to eq(status)
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      { subject:    'workpackage No. 1',
        start_date: Date.today,
        due_date:   Date.today + 2.weeks,
        project_id: project.id,
        type:       project.types.first,
        author:     user
      }
    }

    it { expect(WorkPackage.new.tap { |pe| pe.send(:assign_attributes, attributes) }).to be_valid }

    describe 'subject' do
      it 'is invalid w/o a subject' do
        attributes[:subject] = nil
        planning_element = WorkPackage.new.tap { |pe| pe.send(:assign_attributes, attributes) }

        expect(planning_element).not_to be_valid

        expect(planning_element.errors[:subject]).to be_present
        expect(planning_element.errors[:subject]).to eq(["can't be blank."])
      end

      it 'is invalid w/ a subject longer than 255 characters' do
        attributes[:subject] = 'A' * 500
        planning_element = WorkPackage.new.tap { |pe| pe.send(:assign_attributes, attributes) }

        expect(planning_element).not_to be_valid

        expect(planning_element.errors[:subject]).to be_present
        expect(planning_element.errors[:subject]).to eq(['is too long (maximum is 255 characters).'])
      end
    end

    describe 'start_date' do
      it 'is valid w/o a start_date' do
        attributes[:start_date] = nil
        planning_element = WorkPackage.new.tap { |pe| pe.send(:assign_attributes, attributes) }

        expect(planning_element).to be_valid

        expect(planning_element.errors[:start_date]).not_to be_present
      end
    end

    describe 'due_date' do
      it 'is valid w/o a due_date' do
        attributes[:due_date] = nil
        planning_element = WorkPackage.new.tap { |pe| pe.send(:assign_attributes, attributes) }

        expect(planning_element).to be_valid

        expect(planning_element.errors[:due_date]).not_to be_present
      end

      it 'is invalid if start_date is after due_date' do
        attributes[:start_date] = Date.today
        attributes[:due_date]   = Date.today - 1.week
        planning_element = WorkPackage.new.tap { |pe| pe.send(:assign_attributes, attributes) }

        expect(planning_element).not_to be_valid

        expect(planning_element.errors[:due_date]).to be_present
        error_message = I18n.t(:greater_than_or_equal_to_start_date, scope: [:activerecord,
                                                                             :errors,
                                                                             :messages])
        expect(planning_element.errors[:due_date]).to eq([error_message])
      end

      it 'is invalid if planning_element is milestone and due_date is not on start_date' do
        attributes[:type] = FactoryGirl.build(:type, is_milestone: true)
        attributes[:start_date]            = Date.today
        attributes[:due_date]              = Date.today + 1.week
        planning_element = WorkPackage.new.tap { |pe| pe.send(:assign_attributes, attributes) }

        expect(planning_element).not_to be_valid

        expect(planning_element.errors[:due_date]).to be_present
        error_message = I18n.t(:not_start_date, scope: [:activerecord,
                                                        :errors,
                                                        :models,
                                                        :work_package,
                                                        :attributes,
                                                        :due_date])
        expect(planning_element.errors[:due_date]).to eq([error_message])
      end
    end

    describe 'project' do
      it 'is invalid w/o a project' do
        attributes[:project_id] = nil
        planning_element = WorkPackage.new.tap { |pe| pe.send(:assign_attributes, attributes) }

        expect(planning_element).not_to be_valid

        expect(planning_element.errors[:project]).to be_present
        expect(planning_element.errors[:project]).to eq(["can't be blank."])
      end
    end

    describe 'parent' do
      let (:message) { 'cannot be a milestone.' }

      it 'is invalid if parent is_milestone' do
        parent = WorkPackage.new.tap do |pe|
          pe.send(:assign_attributes, attributes.merge(type: FactoryGirl.build(:type, is_milestone: true)))
        end

        attributes[:parent] = parent
        planning_element = WorkPackage.new.tap { |pe| pe.send(:assign_attributes, attributes) }

        expect(planning_element).not_to be_valid

        expect(planning_element.errors[:parent_id]).to be_present
        expect(planning_element.errors[:parent_id]).to eq([message])
      end
    end
  end

  describe 'derived attributes' do
    before do
      @pe1  = FactoryGirl.create(:work_package, project_id: project.id)
      @pe11 = FactoryGirl.create(:work_package, project_id: project.id, parent_id: @pe1.id)
      @pe12 = FactoryGirl.create(:work_package, project_id: project.id, parent_id: @pe1.id)
    end

    describe 'start_date' do
      it 'equals the minimum start date of all children' do
        @pe11.reload
        @pe11.update_attributes(start_date: Date.new(2000, 01, 20), due_date: Date.new(2001, 01, 20))
        @pe12.reload
        @pe12.update_attributes(start_date: Date.new(2000, 03, 20), due_date: Date.new(2001, 03, 20))

        @pe1.reload
        expect(@pe1.start_date).to eq(@pe11.start_date)
      end
    end

    describe 'due_date' do
      it 'equals the maximum end date of all children' do
        @pe11.reload
        @pe11.update_attributes(start_date: Date.new(2000, 01, 20), due_date: Date.new(2001, 01, 20))
        @pe12.reload
        @pe12.update_attributes(start_date: Date.new(2000, 03, 20), due_date: Date.new(2001, 03, 20))

        @pe1.reload
        expect(@pe1.due_date).to eq(@pe12.due_date)
      end
    end
  end

  describe 'journal' do
    let(:responsible) { FactoryGirl.create(:user) }
    let(:type)        { project.types.first } # The type-validation, that now lives on work-package is more
    # strict than the previous validation on the planning-element
    # it also checks, that the type is available for the project the pe lives in.
    let(:pe_status)   { FactoryGirl.create(:status) }

    let(:pe) {
      FactoryGirl.create(:work_package,
                         subject:                         'Plan A',
                         author:                          responsible,
                         description:                     "This won't work out",
                         start_date:                      Date.new(2012, 1, 24),
                         due_date:                        Date.new(2012, 1, 31),
                         project_id:                      project.id,
                         responsible_id:                  responsible.id,
                         type_id:                         type.id,
                         status_id:                       pe_status.id
                        )
    }

    it "has an initial journal, so that it's creation shows up in activity" do
      expect(pe.journals.size).to eq(1)

      changes = pe.journals.first.details.to_hash

      expect(changes.size).to eq(11)

      expect(changes).to include(:subject)
      expect(changes).to include(:author_id)
      expect(changes).to include(:description)
      expect(changes).to include(:start_date)
      expect(changes).to include(:due_date)
      expect(changes).to include(:done_ratio)
      expect(changes).to include(:status_id)
      expect(changes).to include(:priority_id)
      expect(changes).to include(:project_id)
      expect(changes).to include(:responsible_id)
      expect(changes).to include(:type_id)
    end

    it 'stores updates in journals' do
      pe.reload
      pe.update_attribute(:due_date, Date.new(2012, 2, 1))

      expect(pe.journals.size).to eq(2)
      changes = pe.journals.last.details

      expect(changes.size).to eq(1)

      expect(changes).to include(:due_date)

      expect(changes[:due_date].first).to eq(Date.new(2012, 1, 31))
      expect(changes[:due_date].last).to eq(Date.new(2012, 2, 1))
    end

    describe 'workpackage hierarchies' do
      let(:child_pe) {
        FactoryGirl.create(:work_package,
                           parent_id:         pe.id,
                           subject:           'Plan B',
                           description:       'This will work out',
                           # interval is the same as parent, so that
                           # dates are not updated
                           start_date:        Date.new(2012, 1, 24),
                           due_date:          Date.new(2012, 1, 31),
                           project_id:        project.id,
                           responsible_id:    responsible.id
                          )
      }

      it 'creates a journal in the parent when end date is changed indirectly' do
        child_pe # trigger creation of child and parent

        # sanity check
        expect(child_pe.journals.size).to eq(1)
        expect(pe.journals.size).to eq(1)

        # update child
        child_pe.reload
        child_pe.update_attribute(:start_date, Date.new(2012, 1, 1))

        # reload parent to avoid stale journal caches
        pe.reload

        expect(pe.journals.size).to eq(2)
        changes = pe.journals.last.details

        expect(changes.size).to eq(1)
        expect(changes).to include(:start_date)
      end
    end
  end

  describe 'acts as paranoid trash' do
    before(:each) do
      @pe1 = FactoryGirl.create(:work_package,
                                project_id: project.id,
                                start_date: Date.new(2011, 1, 1),
                                due_date:   Date.new(2011, 2, 1),
                                subject:    'Numero Uno')
    end

    it 'should delete the object permanently when using destroy' do
      @pe1.destroy

      expect(WorkPackage.find_by(id: @pe1.id)).to be_nil
    end

    it 'destroys all child elements' do
      pe1   = FactoryGirl.create(:work_package, project_id: project.id)
      pe11  = FactoryGirl.create(:work_package, project_id: project.id, parent_id: pe1.id)
      pe12  = FactoryGirl.create(:work_package, project_id: project.id, parent_id: pe1.id)
      pe121 = FactoryGirl.create(:work_package, project_id: project.id, parent_id: pe12.id)
      pe2   = FactoryGirl.create(:work_package, project_id: project.id)

      pe1.destroy

      [pe1, pe11, pe12, pe121].each do |pe|
        expect(WorkPackage.find_by(id: pe.id)).to be_nil
      end
    end
  end
end
