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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class DeleteOldMeetingContents < ActiveRecord::Migration[8.0]
  def up
    execute("DROP TABLE meeting_contents")
    execute("DROP TABLE meeting_content_journals")
  end

  def down
    # create table with empty content
    # instructions copied from db/structure.sql of a release/16.6
    execute(<<~SQL.squish)
      CREATE TABLE meeting_content_journals (
          id bigint NOT NULL,
          meeting_id bigint,
          author_id bigint,
          text text,
          locked boolean
      );
      CREATE SEQUENCE meeting_content_journals_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;
      ALTER SEQUENCE meeting_content_journals_id_seq OWNED BY meeting_content_journals.id;

      CREATE TABLE meeting_contents (
          id bigint NOT NULL,
          type character varying,
          meeting_id bigint,
          author_id bigint,
          text text,
          lock_version integer,
          created_at timestamp with time zone NOT NULL,
          updated_at timestamp with time zone NOT NULL,
          locked boolean DEFAULT false
      );
      CREATE SEQUENCE meeting_contents_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;
      ALTER SEQUENCE meeting_contents_id_seq OWNED BY meeting_contents.id;

      ALTER TABLE ONLY meeting_content_journals ALTER COLUMN id SET DEFAULT nextval('meeting_content_journals_id_seq'::regclass);
      ALTER TABLE ONLY meeting_contents ALTER COLUMN id SET DEFAULT nextval('meeting_contents_id_seq'::regclass);

      ALTER TABLE ONLY meeting_content_journals
          ADD CONSTRAINT meeting_content_journals_pkey PRIMARY KEY (id);
      ALTER TABLE ONLY meeting_contents
          ADD CONSTRAINT meeting_contents_pkey PRIMARY KEY (id);
    SQL
  end
end
