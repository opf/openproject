#-- encoding: UTF-8
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

shared_examples_for 'type service' do
  let(:success) { true }

  describe '#call' do
    before do
      expect(type)
        .to receive(:save)
        .and_return(success)
    end

    it 'returns a success service result' do
      expect(instance.call).to be_success
    end

    it 'set the values provided on the call' do
      permitted_params = { name: 'blubs blubs' }

      instance.call(permitted_params: permitted_params)

      expect(type.name).to eql permitted_params[:name]
    end

    describe 'custom fields' do
      let!(:cf1) { FactoryGirl.create :work_package_custom_field, field_format: 'text' }
      let!(:cf2) { FactoryGirl.create :work_package_custom_field, field_format: 'text' }

      it 'enables the custom fields that are passed via attribute_groups' do
        unsafe_params = {
          attribute_groups: [
            ['group1', ["custom_field_#{cf1.id}", 'custom_field_54']],
            ['group2', ["custom_field_#{cf2.id}"]]
          ].to_json
        }

        expect(type)
          .to receive(:custom_field_ids=)
          .with([cf1.id, cf2.id])

        instance.call(permitted_params: {}, unsafe_params: unsafe_params)
      end
    end

    context 'on failure' do
      let(:success) { false }

      it 'returns a failed service result' do
        expect(instance.call).not_to be_success
      end

      it 'returns the errors of the type' do
        type_errors = 'all the errors'
        allow(type)
          .to receive(:errors)
          .and_return(type_errors)

        expect(instance.call.errors).to eql type_errors
      end
    end
  end
end
