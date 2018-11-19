#-- copyright
# ReportingEngine
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

module Engine
  ##
  # Subclass of Report to be used for constant lookup and such.
  # It is considered public API to override this method i.e. in Tests.
  #
  # @return [Class] subclass
  def engine
    return @engine if @engine
    if is_a? Module
      @engine = Object.const_get(name[/^[^:]+/] || :Report)
    elsif respond_to? :parent and parent.respond_to? :engine
      parent.engine
    else
      self.class.engine
    end
  end
end
