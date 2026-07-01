# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
module DemoData
  # Seeds a handful of user attributes that fit the demo project's mix of
  # conference organisation and software delivery work. Values are intentionally
  # not assigned to users here - that happens once the users PR is merged.
  class UserCustomFieldsSeeder < Seeder
    JOB_TITLES = [
      "Project Manager",
      "Product Owner",
      "Scrum Master",
      "Software Developer",
      "UX/UI Designer",
      "QA Engineer",
      "Marketing Manager",
      "Event Coordinator",
      "Technical Writer"
    ].freeze

    SPOKEN_LANGUAGES = [
      "English",
      "German",
      "French",
      "Spanish",
      "Italian",
      "Dutch",
      "Portuguese",
      "Polish"
    ].freeze

    KEY_SKILLS = [
      "Project Management",
      "Agile & Scrum",
      "Software Development",
      "UX/UI Design",
      "Quality Assurance",
      "DevOps",
      "Public Speaking",
      "Event Planning",
      "Marketing & Communications",
      "Copywriting",
      "Budgeting",
      "Stakeholder Management"
    ].freeze

    def seed_data!
      print_status "    ↳ Creating user custom fields..."

      UserCustomField.transaction do
        field_definitions.each do |attributes|
          create_field!(attributes)
        end
      end
    end

    def applicable?
      UserCustomField.where(name: field_definitions.pluck(:name)).count < field_definitions.size
    end

    def not_applicable_message
      "Skipping user custom fields as they already exist"
    end

    private

    def create_field!(attributes)
      return if UserCustomField.exists?(name: attributes[:name])

      UserCustomField.create!(attributes.merge(custom_field_section: section))
    end

    def field_definitions
      [
        {
          name: "Job title",
          field_format: "list",
          editable: false,
          possible_values: JOB_TITLES,
          # Only claim the semantic key when no other field already owns it.
          semantic_key: UserCustomField.for_semantic_key(:job_title) ? nil : "job_title"
        },
        {
          name: "Spoken languages",
          field_format: "list",
          multi_value: true,
          editable: true,
          possible_values: SPOKEN_LANGUAGES
        },
        {
          name: "Key skills",
          field_format: "list",
          multi_value: true,
          editable: true,
          possible_values: KEY_SKILLS
        },
        {
          name: "Job start date",
          field_format: "date",
          editable: false
        }
      ]
    end

    # The default user custom field section is normally created as basic data, but
    # not every edition seeds it (e.g. BIM), so fall back to creating one. Mirrors
    # BasicData::UserCustomFieldSectionSeeder (blank name, built-in attribute order).
    def section
      @section ||= UserCustomFieldSection.order(:position).first || create_default_section
    end

    def create_default_section
      UserCustomFieldSection.new(
        position: 1,
        attribute_order: UserCustomFieldSection::BUILT_IN_ATTRIBUTES
      ).tap { |section| section.save!(validate: false) }
    end
  end
end
