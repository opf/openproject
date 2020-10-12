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

describe NoResultsHelper do

  before do
    allow(helper).to receive(:t).with('.no_results_title_text', cascade: true) { "Nothing here!" }
    allow(helper).to receive(:t).with('.no_results_content_text') { "Add some foo" }
  end

  describe '#no_results_box' do

    it "contains the just the title" do
      expect(helper.no_results_box).to have_content 'Nothing here!'
      expect(helper.no_results_box).to_not have_link 'Add some foo'
    end

    it "contains the title and content link" do
      no_results_box = helper.no_results_box(action_url: root_path,
                                             display_action: true)

      expect(no_results_box).to have_content 'Nothing here!'
      expect(no_results_box).to have_link 'Add some foo', href: '/'
    end

    it 'contains title and content_link with custom text' do
      no_results_box = helper.no_results_box(action_url: root_path,
                                             display_action: true,
                                             custom_title: 'This is a different title about foo',
                                             custom_action_text: 'Link to nowhere')

      expect(no_results_box).to have_content 'This is a different title about foo'
      expect(no_results_box).to have_link 'Link to nowhere', href: '/'
    end
  end
end
