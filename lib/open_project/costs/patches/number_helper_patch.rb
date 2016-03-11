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

module OpenProject::Costs::Patches::NumberHelperPatch
  def self.included(base) # :nodoc:
    base.class_eval do
      include InstanceMethods

      alias_method_chain :number_to_currency, :l10n
    end
  end

  module InstanceMethods
    def number_to_currency_with_l10n(number, options = {})
      options_with_default = { unit: ERB::Util.h(Setting.plugin_openproject_costs['costs_currency']),
                               format: ERB::Util.h(Setting.plugin_openproject_costs['costs_currency_format']),
                               delimiter: I18n.t(:currency_delimiter),
                               separator: I18n.t(:currency_separator) }.merge(options)

      # FIXME: patch ruby instead of this code
      # this circumvents the broken BigDecimal#to_f on Siemens's ruby
      number = number.to_s if number.is_a? BigDecimal

      number_to_currency_without_l10n(number, options_with_default)
    end
  end
end
