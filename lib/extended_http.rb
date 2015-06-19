#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

module ExtendedHTTP
  # Use this in response to an HTTP POST (or PUT), telling the client where the
  # new resource is.  Works just like redirect_to, but sends back a 303 (See
  # Other) status code.  Redirects should be used to tell the client to repeat
  # the same request on a different resource, and see_other when we want the
  # client to follow a POST (on this resource) with a GET (to the new resource).
  #
  # This is especially useful for successful create actions.
  def see_other(options = {})
    if options.is_a?(Hash)
      redirect_to options.merge(status: :see_other)
    else
      redirect_to options, status: :see_other
    end
  end

  # Use this in response to an HTTP PUT (or POST), telling the client that
  # everything went well and the desired change was performed successfully.
  #
  # This is especially useful for successful update actions.
  def no_content
    render text: '', status: :no_content
  end
end
