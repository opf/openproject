#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Projects::Status, type: :model do
  let(:project) { FactoryBot.create(:project) }

  let(:explanation) { 'some explanation' }
  let(:code) { :on_track }
  let(:instance) { described_class.new explanation: explanation, code: code, project: project }

  describe 'explanation' do
    it 'stores an explanation' do
      instance.save

      instance.reload

      expect(instance.explanation)
        .to eql explanation
    end
  end

  describe 'code' do
    it 'stores a code as an enum' do
      instance.save

      instance.reload

      expect(instance.on_track?)
        .to be_truthy
    end
  end

  describe 'project' do
    it 'stores a project reference' do
      instance.save

      instance.reload

      expect(instance.project)
        .to eql project
    end

    it 'requires one' do
      instance.project = nil

      expect(instance)
        .to be_invalid

      expect(instance.errors.symbols_for(:project))
        .to eql [:blank]
    end

    it 'cannot be one already having a status' do
      described_class.create! explanation: 'some other explanation', code: :off_track, project: project

      expect(instance)
        .to be_invalid

      expect(instance.errors.symbols_for(:project))
        .to eql [:taken]
    end
  end
end
