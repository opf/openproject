#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryGirl.define do
  factory :auth_source do
    name 'Test AuthSource'
  end
  factory :ldap_auth_source, :class => LdapAuthSource do
    name 'Test LDAP AuthSource'
    host '127.0.0.1'
    port 225  # a reserved port, should not be in use
    attr_login 'uid'
  end
end
