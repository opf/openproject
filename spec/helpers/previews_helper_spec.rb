#-- encoding: UTF-8
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

describe PreviewsHelper, type: :helper do
  describe '#preview_link' do
    let(:path) { '/' }
    let(:id)   { 'news_preview' }
    subject(:output) { helper.preview_link(path, id) }

    before do
      allow(helper).to receive(:accesskey).and_return('a')
    end

    it 'outputs a styled link' do
      expect(output).to be_html_eql(%{
        <a href="/"
          class="button preview -with-icon icon-issue-watched"
          accesskey="a"
          has-preview=""
          id="news_preview">Preview</a>
      })
    end
  end
end
