#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

# Rewrites mentions in user provided text (e.g. work package journals) from one user to another.
# No data is to be removed.
module Users
  class ReplaceMentionsService
    include ActiveRecord::Sanitization

    def self.replacements
      [
        { class: WorkPackage, column: :description },
        { class: Journal::WorkPackageJournal, column: :description },
        { class: Document, column: :description },
        { class: Journal, column: :notes },
        { class: Comment, column: :comments },
        {
          class: CustomValue,
          column: :value,
          condition: <<~SQL.squish
            EXISTS (
              SELECT 1
              FROM #{CustomField.table_name}
              WHERE field_format = 'text'
              AND #{CustomValue.table_name}.custom_field_id = custom_fields.id
            )
          SQL
        },
        {
          class: Journal::CustomizableJournal,
          column: :value,
          condition: <<~SQL.squish
            EXISTS (
              SELECT 1
              FROM #{CustomField.table_name}
              WHERE field_format = 'text'
              AND #{Journal::CustomizableJournal.table_name}.custom_field_id = custom_fields.id
            )
          SQL
        },
        { class: MeetingContent, column: :text },
        { class: Journal::MeetingContentJournal, column: :text },
        { class: Message, column: :content },
        { class: Journal::MessageJournal, column: :content },
        { class: News, column: :description },
        { class: Journal::NewsJournal, column: :description },
        { class: Project, column: :description },
        { class: Project, column: :status_explanation },
        { class: WikiPage, column: :text },
        { class: Journal::WikiPageJournal, column: :text }
      ]
    end

    def initialize(*classes)
      self.replacements = if classes.any?
                            self.class.replacements.select { |r| classes.include?(r[:class]) }
                          else
                            self.class.replacements
                          end
    end

    def call(from:, to:)
      check_input(from, to)

      rewrite(from, to)

      ServiceResult.success
    end

    private

    attr_accessor :replacements

    def check_input(from, to)
      raise ArgumentError unless (from.is_a?(User) || from.is_a?(Group)) && to.is_a?(User)
    end

    def rewrite(from, to)
      replacements.each do |replacement|
        focus_on_replacement(replacement)
        rewrite_column(from, to)
      end
    end

    def focus_on_replacement(replacement)
      self.replacements = [replacement]
    end

    def rewrite_column(from, to)
      sql = <<~SQL.squish
        UPDATE #{table_name} sink
        SET #{column_name} = source.replacement
        FROM
          (SELECT
              #{table_name}.id,
              #{replace_sql(from, to)} replacement
           FROM
             #{table_name}
           WHERE
             #{condition_sql(from)}
          ) source
        WHERE
          source.id = sink.id
      SQL

      klass
        .connection
        .execute sql
    end

    def replace_sql(from, to)
      hash_replace(mention_tag_replace(from,
                                       to),
                   from,
                   to)
    end

    def condition_sql(from)
      mention = '<mention_*data-id="%i"_*</mention>'
      hash = if from.is_a?(User)
               'user#((%i)|("%s")|("%s"))\s'
             else
               'group#%i\s'
             end

      hash_values = if from.is_a?(User)
                      [
                        sanitize_sql_like(from.mail),
                        sanitize_sql_like(from.login)
                      ]
                    else
                      []
                    end

      sql = <<~SQL.squish
        #{table_name}.#{column_name} SIMILAR TO '_*((#{mention})|(#{hash}))_*'
      SQL

      if condition
        sql += "AND #{condition}"
      end

      sanitize_sql_for_conditions [sql,
                                   from.id,
                                   from.id] + hash_values
    end

    def mention_tag_replace(from, to)
      regexp_replace(
        "#{table_name}.#{column_name}",
        '<mention.+data-id="%i".+</mention>',
        '<mention class="mention" data-id="%i" data-type="user" data-text="@%s">@%s</mention>',
        [from.id,
         to.id,
         sanitize_sql_like(to.name),
         sanitize_sql_like(to.name)]
      )
    end

    def hash_replace(source, from, to)
      search = if from.is_a?(User)
                 'user#((%i)|("%s")|("%s"))\s'
               else
                 'group#%i\s'
               end

      values = if from.is_a?(User)
                 [
                   from.id,
                   sanitize_sql_like(from.login),
                   sanitize_sql_like(from.mail),
                   to.id
                 ]
               else
                 [
                   from.id,
                   to.id
                 ]
               end

      regexp_replace(
        source,
        search,
        'user#%i ',
        values
      )
    end

    def regexp_replace(source, search, replacement, values)
      sql = <<~SQL.squish
        REGEXP_REPLACE(
          #{source},
          '#{search}',
          '#{replacement}',
          'g'
        )
      SQL

      sanitize_sql_for_conditions [sql].concat(values)
    end

    def sanitize_sql_like(string)
      klass.sanitize_sql_like(string)
    end

    def sanitize_sql_for_conditions(string)
      klass.sanitize_sql_for_conditions string
    end

    def journal_classes
      [Journal] + Journal::BaseJournal.subclasses
    end

    def klass
      replacements[0][:class]
    end

    def table_name
      replacements[0][:class].table_name
    end

    def column_name
      replacements[0][:column]
    end

    def condition
      replacements[0][:condition]
    end
  end
end
