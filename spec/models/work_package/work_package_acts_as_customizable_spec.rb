#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe WorkPackage, 'acts_as_customizable' do
  let(:type) { create(:type_standard) }
  let(:project) { create(:project, types: [type]) }
  let(:user) { create(:user) }
  let(:status) { create(:status) }
  let(:priority) { create(:priority) }

  let(:work_package) { create(:work_package, project:, type:) }
  let(:new_work_package) do
    described_class.new type:,
                        project:,
                        author: user,
                        status:,
                        priority:,
                        subject: 'some subject'
  end

  def setup_custom_field(cf)
    project.work_package_custom_fields << cf
    type.custom_fields << cf
  end

  describe '#custom_field_values=' do
    context 'with an unpersisted work package and a version custom field' do
      subject(:wp_with_assignee_cf) do
        setup_custom_field(version_cf)
        new_work_package.custom_field_values = { version_cf.id.to_s => version }
        new_work_package
      end

      let(:version) { create(:version, project:) }
      let(:version_cf) { create(:version_wp_custom_field, is_required: true) }

      it 'results in a valid work package' do
        expect(wp_with_assignee_cf)
          .to be_valid
      end

      it 'sets the value' do
        expect(wp_with_assignee_cf.send(version_cf.attribute_getter))
          .to eql version
      end
    end
  end

  describe '#custom_field_:id' do
    let(:included_cf) { build(:work_package_custom_field) }
    let(:other_cf) { build(:work_package_custom_field) }

    before do
      included_cf.save
      other_cf.save

      setup_custom_field(included_cf)
    end

    it 'says to respond to valid custom field accessors' do
      expect(work_package).to respond_to(included_cf.attribute_getter)
    end

    it 'really responds to valid custom field accessors' do
      expect(work_package.send(included_cf.attribute_getter)).to be_nil
    end

    it 'says to not respond to foreign custom field accessors' do
      expect(work_package).not_to respond_to(other_cf.attribute_getter)
    end

    it 'does really not respond to foreign custom field accessors' do
      expect { work_package.send(other_cf.attribute_getter) }.to raise_error(NoMethodError)
    end
  end

  describe '#valid?' do
    let(:cf1) { create(:work_package_custom_field, is_required: true) }
    let(:cf2) { create(:work_package_custom_field, is_required: true) }

    it 'does not duplicate error messages when invalid' do
      # create work_package with one required custom field
      work_package = new_work_package
      # work_package.reload
      setup_custom_field(cf1)

      # set that custom field with a value, should be fine
      work_package.custom_field_values = { cf1.id => 'test' }
      work_package.save!
      work_package.reload

      # now give the work_package another required custom field, but don't assign a value
      setup_custom_field(cf2)
      work_package.custom_field_values # #custom_field_values needs to be touched

      # that should not be valid
      expect(work_package).not_to be_valid

      # assert that there is only one error
      expect(work_package.errors.size).to eq 1
      expect(work_package.errors[cf2.attribute_name].size).to eq 1
    end
  end

  it_behaves_like 'acts_as_customizable included' do
    let(:model_instance) { work_package }
    let(:custom_field) { create(:string_wp_custom_field) }
    before do
      setup_custom_field(custom_field)
    end

    context 'with a default value' do
      before do
        custom_field.update! default_value: 'foobar'
        model_instance.custom_values.destroy_all
      end

      it 'returns no changes' do
        expect(model_instance.custom_field_changes).to be_empty
      end
    end
  end
end
