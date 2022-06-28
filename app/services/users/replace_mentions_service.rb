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
        { class: Projects::Status, column: :explanation },
        { class: WikiContent, column: :text },
        { class: Journal::WikiContentJournal, column: :text }
      ]
    end

    def call(from:, to:)
      check_input(from, to)

      rewrite(from, to)

      ServiceResult.success
    end

    private

    def check_input(from, to)
      raise ArgumentError unless from.is_a?(User) && to.is_a?(User)
    end

    def rewrite(from, to)
      self.class.replacements.each do |replacement|
        rewrite_column(replacement, from, to)
      end
    end

    def rewrite_column(replacement, from, to)
      sql = <<~SQL.squish
        UPDATE #{replacement[:class].table_name} sink
        SET #{replacement[:column]} = source.replacement
        FROM
          (SELECT
              #{replacement[:class].table_name}.id,
              #{replace_sql(replacement[:class], "#{replacement[:class].table_name}.#{replacement[:column]}", from, to)} replacement
           FROM
             #{replacement[:class].table_name}
           WHERE
             #{condition_sql(replacement, from)}
          ) source
        WHERE
          source.id = sink.id
      SQL

      replacement[:class]
        .connection
        .execute sql
    end

    def replace_sql(klass, source, from, to)
      hash_replace(klass,
                   mention_tag_replace(klass,
                                       source,
                                       from,
                                       to),
                   from,
                   to)
    end

    def condition_sql(replacement, from)
      sql = <<~SQL.squish
        #{replacement[:class].table_name}.#{replacement[:column]} SIMILAR TO '_*((<mention_*data-id="%i"_*</mention>)|(user#((%i)|("%s")|("%s")\s)))_*'
      SQL

      if replacement.has_key?(:condition)
        sql += "AND #{replacement[:condition]}"
      end

      replacement[:class].sanitize_sql_for_conditions [sql,
                                                       from.id,
                                                       from.id,
                                                       replacement[:class].sanitize_sql_like(from.mail),
                                                       replacement[:class].sanitize_sql_like(from.login)]
    end

    def mention_tag_replace(klass, source, from, to)
      regexp_replace(
        klass,
        source,
        '<mention.+data-id="%i".+</mention>',
        '<mention class="mention" data-id="%i" data-type="user" data-text="@%s">@%s</mention>',
        [from.id,
         to.id,
         klass.sanitize_sql_like(to.name),
         klass.sanitize_sql_like(to.name)]
      )
    end

    def hash_replace(klass, source, from, to)
      regexp_replace(
        klass,
        source,
        'user#((%i)|("%s")|("%s")\s)',
        'user#%i ',
        [from.id,
         klass.sanitize_sql_like(from.login),
         klass.sanitize_sql_like(from.mail),
         to.id]
      )
    end

    def regexp_replace(klass, source, search, replacement, values)
      sql = <<~SQL.squish
        REGEXP_REPLACE(
          #{source},
          '#{search}',
          '#{replacement}',
          'g'
        )
      SQL

      klass.sanitize_sql_for_conditions [sql].concat(values)
    end

    def journal_classes
      [Journal] + Journal::BaseJournal.subclasses
    end
  end
end
