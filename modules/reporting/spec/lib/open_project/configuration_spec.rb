#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'

describe 'OpenProject::Configuration' do
  context '.cost_reporting_cache_filter_classes' do
    before do
      # This prevents the values from the actual configuration file to influence
      # the test outcome.
      #
      # TODO: I propose to port this over to the core to always prevent this for specs.
      OpenProject::Configuration.load(file: 'bogus')
    end

    after do
      # resetting for now to avoid braking specs, who by now rely on having the file read.
      OpenProject::Configuration.load
    end

    it 'is a true by default via the method' do
      expect(OpenProject::Configuration.cost_reporting_cache_filter_classes).to be_truthy
    end


    it 'is true by default via the hash' do
      expect(OpenProject::Configuration['cost_reporting_cache_filter_classes']).to be_truthy
    end

  end
end
