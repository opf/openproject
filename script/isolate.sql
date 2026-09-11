---- copyright
-- OpenProject is an open source project management software.
-- Copyright (C) the OpenProject GmbH
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License version 3.
--
-- OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
-- Copyright (C) 2006-2013 Jean-Philippe Lang
-- Copyright (C) 2010-2013 the ChiliProject Team
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
--
-- See COPYRIGHT and LICENSE files for more details.
--++

DELETE FROM deploy_targets;
DELETE FROM deploy_status_checks;

DELETE FROM storages;
DELETE FROM storages_file_links_journals;
DELETE FROM project_storages;
DELETE FROM last_project_folders;
DELETE FROM remote_identities;
DELETE FROM file_links;
DELETE FROM webhooks_events;
DELETE FROM webhooks_logs;
DELETE FROM webhooks_webhooks;
DELETE FROM settings WHERE name = 'mail_from';
DELETE FROM settings WHERE lower(name) like 'smtp_%';

UPDATE users set mail = '';
