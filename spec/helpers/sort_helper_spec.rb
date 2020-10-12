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

describe SortHelper, type: :helper do
  describe '#sort_header_tag' do
    let(:output) {
      helper.sort_header_tag('id')
    }
    let(:sort_key) { '' }
    let(:sort_asc) { true }
    let(:sort_criteria) {
      double('sort_criteria', first_key: sort_key,
                              first_asc?: sort_asc,
                              to_param: 'sort_criteria_params').as_null_object
    }

    before do
      # helper relies on this instance var
      @sort_criteria = sort_criteria

      # fake having called '/work_packages'
      allow(helper)
        .to receive(:url_options)
        .and_return(url_options.merge(controller: 'work_packages', action: 'index'))
    end

    it 'renders a th with a sort link' do
      expect(output).to be_html_eql(%{
        <th title="Sort by &quot;Id&quot;">
          <div class="generic-table--sort-header-outer">
            <div class="generic-table--sort-header">
              <span>
                <a href="/work_packages?sort=sort_criteria_params"
                   title="Sort by &quot;Id&quot;">Id</a>
              </span>
            </div>
          </div>
        </th>
      })
    end

    context 'when sorting by the column' do
      let(:sort_key) { 'id' }

      it 'should add the sort class' do
        expect(output).to be_html_eql(%{
          <th title="Ascending sorted by &quot;Id&quot;">
            <div class="generic-table--sort-header-outer">
              <div class="generic-table--sort-header">
                <span class="sort asc">
                  <a href="/work_packages?sort=sort_criteria_params"
                     title="Ascending sorted by &quot;Id&quot;">Id</a>
                </span>
              </div>
            </div>
          </th>
        })
      end
    end

    context 'when sorting desc by the column' do
      let(:sort_key) { 'id' }
      let(:sort_asc) { false }

      it 'should add the sort class' do
        expect(output).to be_html_eql(%{
          <th title="Descending sorted by &quot;Id&quot;">
            <div class="generic-table--sort-header-outer">
              <div class="generic-table--sort-header">
                <span class="sort desc">
                  <a href="/work_packages?sort=sort_criteria_params"
                     title="Descending sorted by &quot;Id&quot;">Id</a>
                </span>
              </div>
            </div>
          </th>
        })
      end
    end
  end
end
