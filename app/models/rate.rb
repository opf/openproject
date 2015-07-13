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

class Rate < ActiveRecord::Base
  validates_numericality_of :rate, allow_nil: false
  validate :validate_date_is_a_date

  before_save :convert_valid_from_to_date

  belongs_to :user
  include ::OpenProject::Costs::DeletedUserFallback
  belongs_to :project

  include ActiveModel::ForbiddenAttributesProtection

  def self.clean_currency(value)
    if value && value.is_a?(String)
      value = value.strip
      value.gsub!(l(:currency_delimiter), '') if value.include?(l(:currency_delimiter)) && value.include?(l(:currency_separator))
      value.gsub(',', '.')
    else
      value
    end
  end


  private

  def convert_valid_from_to_date
    self.valid_from &&= valid_from.to_date
  end

  def validate_date_is_a_date
    valid_from.to_date
  rescue Exception
    errors.add :valid_from, :not_a_date
  end
end
