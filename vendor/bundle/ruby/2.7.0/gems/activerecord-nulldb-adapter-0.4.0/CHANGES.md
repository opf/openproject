Unreleased
----------

0.4.0 (2019-07-22)
-----------

- *Breaking* Drop support to Ruby 1.9
- Add support for ActiveRecord 6.0 #90
- Prevent ActiveRecord::Tasks::DatabaseNotSupported #88

0.3.9 (2018-07-07)
-----------
- Fix broken count
- Avoid monkey patching Schema.define
- Support ruby 2.4 (drop support for ruby 2.1 and rails 3.0/3.1)
- Support custom TableDefinition (useful for postgres)

0.3.8 (2018-02-06)
-----------
- Adds support for ActiveRecord Edge (6.0)

0.3.7 (2017-06-04)
-----------
- Adds support for ActiveRecord 5.1/5.2.
- Support limit and null


0.3.6 (2016-11-23)
-----------
- Adds support for ActiveRecord 5.0.


0.3.5 (2016-09-26)
-----------
- Adds support for #cast_values on EmptyResult instance.


0.3.4 (2016-08-10)
-----------
- Adds support for Postgres-specific 'enable_extension'


0.3.3 (2016-08-01)
-----------
- Adds support for ActiveRecord 4.2.
- Deprecates support for MRI 2.0.0.


0.3.2 (2016-01-25)
-----------
- Deprecates support for MRI 1.9.3 and adds support for 2.3.x.
- Fixes :string column type fetching for AR 4.1.


0.3.1 (2014-02-17)
-----------
- Removes accidental dependency on iconv. Fixing JRuby support.


0.3.0 (2014-01-31)
-----------
- Drops 1.8.7 support.
- Adds support for Ruby 2.0, 2.1 and ActiveRecord 4.
- Fixes ActiveRecord 2.3 support on Ruby 2 and up.
- Misc small fixes


0.2.1 (2010-09-01)
-----------
- Updated Rails 3 support so that nulldb works against AR 3.0.0.
- Add support for RSpec 2.


0.2.0 (2010-03-20)
-----------
- Rails 3 support.  All specs pass against ActiveRecord 3.0.0.beta.


0.1.1 (2010-03-15)
-----------
- Released as activerecord-nulldb-adapter gem.


0.1.0 (2010-03-02)
-----------
- Released as nulldb gem, with some bug fixes.


0.0.2 (2007-05-31)
-----------
- Moved to Rubyforge


0.0.1 (2007-02-18)
-----------
- Initial Release
