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

describe ApplicationJob do
  class JobMock < ApplicationJob
    def initialize(callback)
      @callback = callback
    end

    def perform
      @callback.call
    end
  end

  describe 'resets request store' do
    it 'resets request store on each perform' do
      job = JobMock.new(->() do
        expect(RequestStore[:test_value]).to be_nil
        RequestStore[:test_value] = 42
      end)

      RequestStore[:test_value] = 'my value'
      expect { job.perform_now }.not_to change { RequestStore[:test_value] }

      RequestStore[:test_value] = 'my value2'
      expect { job.perform_now }.not_to change { RequestStore[:test_value] }

      expect(RequestStore[:test_value]).to eq 'my value2'
    end
  end
end
