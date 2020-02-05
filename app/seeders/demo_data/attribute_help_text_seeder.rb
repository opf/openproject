#-- encoding: UTF-8

#-- copyright

# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
module DemoData
  class AttributeHelpTextSeeder < Seeder
    def initialize; end

    def seed_data!
      print '    ↳ Creating attribute help texts'

      seed_attribute_help_texts

      puts
    end

    private

    def seed_attribute_help_texts
      help_texts = demo_data_for('attribute_help_texts')
      if help_texts.present?
        help_texts.each do |help_text_attr|
          print '.'
          create_attribute_help_text help_text_attr
        end
      end
    end

    def create_attribute_help_text(help_text_attr)
      help_text_attr[:type] = AttributeHelpText::WorkPackage

      attribute_help_text = AttributeHelpText.new help_text_attr
      attribute_help_text.save
    end
  end
end
