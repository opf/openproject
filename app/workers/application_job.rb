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

class ApplicationJob
  def self.inherited(child)
    child.prepend Setup
  end

  module Setup
    def perform
      before_perform!
      super
    end

    def before_perform!
      reset_request_store!
      reload_mailer_configuration!
    end

    # Resets the thread local request store.
    # This should be done, because normal application code expects the RequestStore to be
    # invalidated between multiple requests and does usually not care whether it is executed
    # from a request or from a delayed job.
    # For a delayed job, each job execution is the thing that comes closest to
    # the concept of a new request.
    def reset_request_store!
      RequestStore.clear!
    end

    # Reloads the thread local ActionMailer configuration.
    # Since the email configuration is now done in the web app, we need to
    # make sure that any changes to the configuration is correctly picked up
    # by the background jobs at runtime.
    def reload_mailer_configuration!
      OpenProject::Configuration.reload_mailer_configuration!
    end
  end
end
