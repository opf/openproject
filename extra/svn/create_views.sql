-- -- copyright
--  OpenProject is a project management system.
--  Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License version 3.
--
--  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
--  Copyright (C) 2006-2013 Jean-Philippe Lang
--  Copyright (C) 2010-2013 the ChiliProject Team
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2
--  of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
--
--  See doc/COPYRIGHT.rdoc for more details.
-- ++

/* ssh views */

CREATE OR REPLACE VIEW ssh_users as
select login as username, hashed_password as password
from users
where status = 1;


/* nss views */

CREATE OR REPLACE VIEW nss_groups AS
select identifier AS name, (id + 5000) AS gid, 'x' AS password
from projects;

CREATE OR REPLACE VIEW nss_users AS
select login AS username, CONCAT_WS(' ', firstname, lastname) as realname, (id + 5000) AS uid, 'x' AS password
from users
where status = 1;

CREATE OR REPLACE VIEW nss_grouplist AS
select (members.project_id + 5000) AS gid, users.login AS username 
from users, members
where users.id = members.user_id
and users.status = 1;
