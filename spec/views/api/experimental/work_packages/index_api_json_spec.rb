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

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'api/experimental/work_packages/index.api.rabl', type: :view do
  def self.stub_can(permissions)
    default_permissions = [:edit, :log_time, :move, :copy, :delete, :duplicate]

    resulting_permissions = default_permissions.reduce({}) do |h, (k, _)|
      h[k] = true if permissions[k]
      h
    end

    let(:can) do
      can = double('Api::Experimental::Concerns::Can')
      allow(can).to receive(:actions) do
        resulting_permissions.keys
      end

      allow(can).to receive(:allowed?) do |_, action|
        resulting_permissions[action]
      end

      can
    end
  end

  before do
    params[:format] = 'json'

    assign(:column_names, column_names)
    assign(:custom_field_column_names, custom_field_column_names)
    assign(:can, can)

    render
  end

  subject { rendered }

  stub_can({})

  context 'with actions, links based on permissions' do
    let(:work_packages) { work_package }
    let(:column_names) { %w(subject project) }
    let(:custom_field_column_names) { [] }


    context 'with all actions' do
      stub_can(
        edit:      true,
        log_time:  true,
        move:      true,
        copy:      true,
        delete:    true,
        duplicate: true
      )

      it { is_expected.to have_json_size(4).at_path('_bulk_links') }

      specify {
        expect(parse_json(subject, '_bulk_links/update')).to match(%r{/work_packages/bulk/edit})
      }

      specify {
        expect(parse_json(subject, '_bulk_links/delete')).to match(%r{/work_packages/bulk.+method\=delete})
      }
    end
  end
end
