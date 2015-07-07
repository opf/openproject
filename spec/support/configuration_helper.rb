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

module OpenProject::Reporting::SpecHelper
  module ConfigurationHelper
    def mock_cache_classes_setting_with(value)
      allow(OpenProject::Configuration).to receive(:[]).and_call_original
      allow(OpenProject::Configuration).to receive(:[])
        .with('cost_reporting_cache_filter_classes')
        .and_return(value)
      allow(OpenProject::Configuration).to receive(:cost_reporting_cache_filter_classes)
        .and_return(value)
    end
  end
end
