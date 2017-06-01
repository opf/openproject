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

require 'spec_helper'

describe OpenProject::Scm::Manager do
  let(:vendor) { 'TestScm' }
  let(:scm_class) { Class.new }

  before do
    Repository.const_set(vendor, scm_class)
    OpenProject::Scm::Manager.add :test_scm
  end

  after do
    Repository.send(:remove_const, vendor)
    OpenProject::Scm::Manager.delete :test_scm
  end

  it 'is a valid const' do
    expect(OpenProject::Scm::Manager.registered[:test_scm]).to eq(Repository::TestScm)
  end

  context 'scm is not known' do
    it 'is not included' do
      expect(OpenProject::Scm::Manager.registered).to_not have_key(:some_scm)
    end
  end
end
