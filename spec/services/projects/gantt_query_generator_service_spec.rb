#-- encoding: UTF-8

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

describe Projects::GanttQueryGeneratorService, type: :model do
  let(:selected) { %w[1 2 3] }
  let(:instance) { described_class.new selected }
  let(:subject) { instance.call }
  let(:json) { JSON.parse(subject) }
  let(:default_json) { JSON.parse(Projects::GanttQueryGeneratorService::DEFAULT_GANTT_QUERY) }

  def build_project_filter(ids)
    { 'n' => 'project', 'o' => '=', 'v' => ids }
  end

  context 'with empty setting' do
    it 'uses the default' do
      Setting.project_gantt_query = ''

      expected = default_json.merge('f' => [build_project_filter(selected)])
      expect(json).to eq(expected)
    end
  end

  context 'with existing filter' do
    it 'overrides the filter' do
      Setting.project_gantt_query = default_json.merge('f' => [build_project_filter(%w[other values])]).to_json

      expected = default_json.merge('f' => [build_project_filter(selected)])
      expect(json).to eq(expected)
    end
  end

  context 'with invalid json' do
    it 'returns the default' do
      Setting.project_gantt_query = 'invalid!1234'

      expected = default_json.merge('f' => [build_project_filter(selected)])
      expect(json).to eq(expected)
    end
  end
end
