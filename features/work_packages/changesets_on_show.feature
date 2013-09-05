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

Feature: A work packages changesets are displayed on the work package show page

  Background:
      Given there is 1 user with:
          | login | manager |

      And there is a role "manager"

      And there is a project named "ecookbook"
      And the project "ecookbook" has a repository
      And I am working in project "ecookbook"

      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"

      And there are the following work packages in project "ecookbook":
        | subject | start_date | due_date   |
        | pe1     | 2013-01-01 | 2013-12-31 |

      And the work package "pe1" has the following changesets:
        | revision | committer | committed_on | comments | commit_date |
        | 1        | manager   | 2013-02-01   | blubs    | 2013-02-01  |

      And I am already logged in as "manager"

  Scenario: Going to the work package show page and seeing the changesets because the user is allowed to see them
    Given the role "manager" may have the following rights:
        | view_work_packages |
        | view_changesets    |
    When I go to the page of the work package "pe1"
    Then I should see the following changesets:
        | revision | comments |
        | 1        | blubs    |

  Scenario: Going to the work package show page and not seeing the changesets because the user is not allowed to see them
    Given the role "manager" may have the following rights:
        | view_work_packages |
    When I go to the page of the work package "pe1"
    Then I should not be presented changesets
