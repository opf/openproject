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
