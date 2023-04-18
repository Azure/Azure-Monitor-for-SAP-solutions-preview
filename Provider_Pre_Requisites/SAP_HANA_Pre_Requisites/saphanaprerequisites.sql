--Execute queries as a admin/SYSTEM user
--Use the queries as applicable to your system setup

--Create user
create user <ams_user_name> password <password_for_user>;
grant monitoring to <ams_user_name>;
--Login with this user via HANA Studio or Cockpit to change password

--Alternatively create user with no force password change
create user <ams_user_name> password <password_for_user> no force_first_password_change;
grant monitoring to <ams_user_name>;

--change parameter global.ini > public_hostname_resolution > use_default_route to 'ip'
alter system alter configuration ('global.ini', 'SYSTEM') set ('public_hostname_resolution', 'use_default_route') = 'ip';