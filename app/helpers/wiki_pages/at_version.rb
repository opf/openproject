# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# ++

# The class represents a wiki page at a specific version.
# It is implemented as somewhat of a mix between a decorator and a view model. It simplifies
# both the controller as well as the view. The controller will only have to provide a single object
# to the view and the view can serve all it's data needs from that one object.
#
# In case more objects like this are generated, a separate folder under e.g. app/view_models or app/decorators
# should be introduced.
class WikiPages::AtVersion < SimpleDelegator
  attr_reader :latest_version,
              :version

  def initialize(wiki_page, version = nil)
    super(wiki_page)
    self.latest_version = wiki_page.version
    self.version = (version || wiki_page.version).to_i.clamp(0, latest_version)
  end

  delegate :text,
           to: :data

  delegate :updated_at,
           to: :last_journal,
           allow_nil: true

  # The form_for helper will call the #to_model method on the object it is passed otherwise
  # which will return the object itself. Any version handling intended by this class will be forfeit.

  # rubocop:disable Style/OptionalBooleanParameter
  # Overwriting a superclass method.
  def respond_to?(method_name, include_all = false)
    if method_name.to_s == 'to_model'
      false
    else
      super
    end
  end
  # rubocop:enable Style/OptionalBooleanParameter

  def author
    last_journal&.user
  end

  def journals
    @journals ||= super.select { |j| j.version <= version.to_i }
  end

  def readonly?
    !current_version?
  end

  def current_version?
    latest_version == version
  end

  def object
    __getobj__
  end

  def to_ary
    object.send(:to_ary)
  end

  private

  attr_writer :latest_version,
              :version

  def data
    last_journal.present? ? last_journal.data : object
  end

  def last_journal
    @last_journal ||= journals.last
  end
end
