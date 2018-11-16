#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
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

module OpenProject::Costs::Patches::NumberToCurrencyConverterPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def i18n_opts
      super.merge(unit: ERB::Util.h(Setting.plugin_openproject_costs['costs_currency']),
                  format: ERB::Util.h(Setting.plugin_openproject_costs['costs_currency_format']),
                  delimiter: I18n.t(:currency_delimiter),
                  separator: I18n.t(:currency_separator))
    end
  end
end