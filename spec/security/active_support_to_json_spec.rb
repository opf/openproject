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

# This is to ensure that we are unaffected by
# CVE-2015-3226: https://groups.google.com/forum/#!msg/rubyonrails-security/7VlB_pck3hU/3QZrGIaQW6cJ
# The report states that 3.2 is affected by the vulnerability. However,
# the test copied from the rails patch (adapted to rspec) passed without fixes
# in the productive code.
#
# It should be safe to remove this when OP is on rails >= 4.1

require 'spec_helper'

describe ActiveSupport do
  active_support_default = ActiveSupport.escape_html_entities_in_json

  after do
    ActiveSupport.escape_html_entities_in_json = active_support_default
  end

  it 'escapes html entities in json' do
    ActiveSupport.escape_html_entities_in_json = true
    expected_output = "{\"\\u003c\\u003e\":\"\\u003c\\u003e\"}"

    expect(ActiveSupport::JSON.encode('<>' => '<>')).to eql(expected_output)
  end
end
