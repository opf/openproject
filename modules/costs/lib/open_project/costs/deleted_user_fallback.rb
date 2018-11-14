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

module OpenProject::Costs
  module DeletedUserFallback
    def self.included(base)
      base.prepend InstanceMethods
    end

    module InstanceMethods
      def user(force_reload = true)
        associated_user = super()

        associated_user = reload_user if force_reload && !associated_user.nil?

        if associated_user.nil? && read_attribute(:user_id).present?
          associated_user = DeletedUser.first
        end

        associated_user
      end
    end
  end
end
