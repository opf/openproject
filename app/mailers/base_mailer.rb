#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class BaseMailer < ActionMailer::Base

  class << self

    ##
    # Execute the following mailer method immediately, not in a delayed job.
    def deliver_immediately!(method, *args)
      target = immediate(method)

      raise NoMethodError.new("Method #{method} does not exist on mailer.") unless respond_to?(target)

      mailer_obj = public_send(target, *args)
      mailer_obj.deliver_now
    end

    protected

    ##
    # Whether the method is immediate?
    def immediate?(method)
      method.to_s.end_with? '!'
    end

    ##
    # Get the immediate counterpart method
    def immediate(method)
      if immediate?(method)
        method.to_sym
      else
        :"#{method}!"
      end
    end
  end
end
