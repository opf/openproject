#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
require 'roar/decorator'

describe OpenProject::Plugins::ActsAsOpEngine do

  subject(:engine) do
    Class.new(Rails::Engine) do
      include OpenProject::Plugins::ActsAsOpEngine
    end
  end

  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:patches) }
  it { is_expected.to respond_to(:assets) }
  it { is_expected.to respond_to(:additional_permitted_attributes) }
  it { is_expected.to respond_to(:register) }

  describe '#name' do
    before do
      Object.const_set('SuperCaliFragilisticExpialidocious', engine)
    end

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq 'SuperCaliFragilisticExpialidocious' }
    end
  end

  describe '#extend_api_response' do
    xit 'should lookup and extend an existing Decorator' do
      # This test does not work as intended...
      # The actual work done by :extend_api_response is not performed unless the engine is started
      # However, it would be green because all attributes of the represented are magically added
      # to the representer...
      module API
        module VTest
          module WorkPackages
            class WorkPackageRepresenter < ::Roar::Decorator
              property :bar
            end
          end
        end
      end

      represented_clazz = Struct.new(:foo, :bar)
      representer = API::VTest::WorkPackages::WorkPackageRepresenter.new(represented_clazz.new)

      engine.class_eval do
        extend_api_response(:v_test, :work_packages, :work_package) do
          property :foo
        end
      end

      expect(representer.to_json).to have_json_path('represented/foo')
      expect(representer.to_json).to have_json_path('represented/bar')
    end
  end
end
