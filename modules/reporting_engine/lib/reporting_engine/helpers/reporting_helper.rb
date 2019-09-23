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

##
# A minimal ReportingHelper module. This is included in Widget and
# Controller and can be used to extend the specific widgets and
# controller functionality.
#
# It is the default hook for translations, and calls to l() in Widgets
# or Controllers will go to this module, first. The default behavior
# is to pass translation work on to I18n.t() or I18n.l(), depending on
# the type of arguments.
module ReportingHelper
end
