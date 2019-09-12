db_adapter = ActiveRecord::Base.configurations[Rails.env]['adapter']
if db_adapter.start_with? 'mysql'
  warn <<~ERROR
    ======= INCOMPATIBLE DATABASE DETECTED =======
    Your database is set up for use with a MySQL or MySQL-compatible variant.
    This installation of OpenProject 10.0. no longer supports these variants.

    The following guides provide extensive documentation for migrating
    your installation to a PostgreSQL database:

    https://www.openproject.org/migration-guides/

    This process is mostly automated so you can continue using your
    OpenProject installation within a few minutes!

    ==============================================
  ERROR

  Kernel.exit 1
end
