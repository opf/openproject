4.1.8 - 2019-08-16
=================
* Support for Rails 6.0.0

4.1.7 - 2019-06-20
=================
* Fix loading Delayed::PerformableMailer when ActionMailer isn't loaded yet

4.1.6 - 2019-06-19
=================
* Properly initialize ActionMailer outside railties (#1077)
* Fix Psych load_tags support (#1093)
* Replace REMOVED with FAILED in log message (#1048)
* Misc doc updates (#1052, #1074, #1064, #1063)

4.1.5 - 2018-04-13
=================
* Allow Rails 5.2

4.1.4 - 2017-12-29
=================
* Use `yaml_tag` instead of deprecated `yaml_as` (#996)
* Support ruby 2.5.0

4.1.3 - 2017-05-26
=================
* Don't mutate the options hash (#877)
* Log an error message when a deserialization error occurs (#894)
* Adding the queue name to the log output (#917)
* Don't include ClassMethods with MessageSending (#924)
* Fix YAML deserialization error if original object is soft-deleted (#947)
* Add support for Rails 5.1 (#982)

4.1.2 - 2016-05-16
==================
* Added Delayed::Worker.queue_attributes
* Limit what we require in ActiveSupport
* Fix pid file creation when there is no tmp directory
* Rails 5 support

4.1.1 - 2015-09-24
==================
* Fix shared specs for back-ends that reload objects

4.1.0 - 2015-09-22
==================
* Alter `Delayed::Command` to work with or without Rails
* Allow `Delayed::Worker.delay_jobs` configuration to be a proc
* Add ability to set destroy failed jobs on a per job basis
* Make `Delayed::Worker.new` idempotent
* Set quiet from the environment
* Rescue `Exception` instead of `StandardError` in worker
* Fix worker crash on serialization error

4.0.6 - 2014-12-22
==================
* Revert removing test files from the gem

4.0.5 - 2014-12-22
==================
* Support for Rails 4.2
* Allow user to override where DJ writes log output
* First attempt at automatic code reloading
* Clearer error message when ActiveRecord object no longer exists
* Various improvements to the README

4.0.4 - 2014-09-24
==================
* Fix using options passed into delayed_job command
* Add the ability to set a default queue for a custom job
* Add the ability to override the max_run_time on a custom job. MUST be lower than worker setting
* Psych YAML overrides are now exclusively used only when loading a job payload
* SLEEP_DELAY and READ_AHEAD can be set for the rake task
* Some updates for Rails 4.2 support

4.0.3 - 2014-09-04
==================
* Added --pools option to delayed_job command
* Removed a bunch of the Psych hacks
* Improved deserialization error reporting
* Misc bug fixes

4.0.2 - 2014-06-24
==================
* Add support for RSpec 3

4.0.1 - 2014-04-12
==================
* Update gemspec for Rails 4.1
* Make logger calls more universal
* Check that records are persisted? instead of new_record?

4.0.0 - 2013-07-30
==================
* Rails 4 compatibility
* Reverted threaded startup due to daemons incompatibilities
* Attempt to recover from job reservation errors

4.0.0.beta2 - 2013-05-28
========================
* Rails 4 compatibility
* Threaded startup script for faster multi-worker startup
* YAML compatibility changes
* Added jobs:check rake task

4.0.0.beta1 - 2013-03-02
========================
* Rails 4 compatibility

3.0.5 - 2013-01-28
==================
* Better job timeout error logging
* psych support for delayed_job_data_mapper deserialization
* User can configure the worker to raise a SignalException on TERM and/or INT
* Add the ability to run all available jobs and exit when complete

3.0.4 - 2012-11-09
==================
* Allow the app to specify a default queue name
* Capistrano script now allows user to specify the DJ command, allowing the user to add "bundle exec" if necessary
* Persisted record check is now more general

3.0.3 - 2012-05-25
==================
* Fix a bug where the worker would not respect the exit condition
* Properly handle sleep delay command line argument

3.0.2 - 2012-04-02
==================
* Fix deprecation warnings
* Raise ArgumentError if attempting to enqueue a performable method on an object that hasn't been persisted yet
* Allow the number of jobs read at a time to be configured from the command line using --read-ahead
* Allow custom logger to be configured through Delayed::Worker.logger
* Various documentation improvements

3.0.1 - 2012-01-24
==================
* Added RecordNotFound message to deserialization error
* Direct JRuby's yecht parser to syck extensions
* Updated psych extensions for better compatibility with ruby 1.9.2
* Updated syck extension for increased compatibility with class methods
* Test grooming

3.0.0 - 2011-12-30
==================
* New: Named queues
* New: Job/Worker lifecycle callbacks
* Change: daemons is no longer a runtime dependency
* Change: Active Record backend support is provided by a separate gem
* Change: Enqueue hook is called before jobs are saved so that they may be modified
* Fix problem deserializing models that use a custom primary key column
* Fix deserializing AR models when the object isn't in the default scope
* Fix hooks not getting called when delay_jobs is false

2.1.4 - 2011-02-11
==================
* Working around issues when psych is loaded, fixes issues with bundler 1.0.10 and Rails 3.0.4
* Added -p/--prefix option to help differentiate multiple delayed job workers on the same host.

2.1.3 - 2011-01-20
==================
* Revert worker contention fix due to regressions
* Added Delayed::Worker.delay_jobs flag to support running jobs immediately

2.1.2 - 2010-12-01
==================
* Remove contention between multiple workers by performing an update to lock a job before fetching it
* Job payloads may implement #max_attempts to control how many times it should be retried
* Fix for loading ActionMailer extension
* Added 'delayed_job_server_role' Capistrano variable to allow delayed_job to run on its own worker server
    set :delayed_job_server_role, :worker
* Fix `rake jobs:work` so it outputs to the console

2.1.1 - 2010-11-14
==================
* Fix issue with worker name not getting properly set when locking a job
* Fixes for YAML serialization

2.1.0 - 2010-11-14
==================
* Added enqueue, before, after, success, error, and failure. See the README
* Remove Merb support
* Remove all non Active Record backends into separate gems. See https://github.com/collectiveidea/delayed_job/wiki/Backends
* remove rails 2 support. delayed_job 2.1 will only support Rails 3
* New pure-YAML serialization
* Added Rails 3 railtie and generator
* Changed @@sleep_delay to self.class.sleep_delay to be consistent with other class variable usage
* Added --sleep-delay command line option

2.0.8 - Unreleased
==================
* Backport fix for deserialization errors that bring down the daemon

2.0.7 - 2011-02-10
==================
* Fixed missing generators and recipes for Rails 2.x

2.0.6 - 2011-01-20
==================
* Revert worker contention fix due to regressions

2.0.5 - 2010-12-01
==================
* Added #reschedule_at hook on payload to determine when the job should be rescheduled [backported from 2.1]
* Added --sleep-delay command line option [backported from 2.1]
* Added 'delayed_job_server_role' Capistrano variable to allow delayed_job to run on its own worker server
    set :delayed_job_server_role, :worker
* Changed AR backend to reserve jobs using an UPDATE query to reduce worker contention [backported from 2.1]

2.0.4 - 2010-11-14
==================
* Fix issue where dirty tracking prevented job from being properly unlocked
* Add delayed_job_args variable for Capistrano recipe to allow configuration of started workers (e.g. "-n 2 --max-priority 10")
* Added options to handle_asynchronously
* Added Delayed::Worker.default_priority
* Allow private methods to be delayed
* Fixes for Ruby 1.9
* Added -m command line option to start a monitor process
* normalize logging in worker
* Deprecate #send_later and #send_at in favor of new #delay method
* Added @#delay@ to Object that allows you to delay any method and pass options:
    options = {:priority => 19, :run_at => 5.minutes.from_now}
    UserMailer.delay(options).deliver_confirmation(@user)

2.0.3 - 2010-04-16
==================
* Fix initialization for Rails 2.x

2.0.2 - 2010-04-08
==================
* Fixes to Mongo Mapper backend [ "14be7a24":http://github.com/collectiveidea/delayed_job/commit/14be7a24, "dafd5f46":http://github.com/collectiveidea/delayed_job/commit/dafd5f46, "54d40913":http://github.com/collectiveidea/delayed_job/commit/54d40913 ]
* DataMapper backend performance improvements [ "93833cce":http://github.com/collectiveidea/delayed_job/commit/93833cce, "e9b1573e":http://github.com/collectiveidea/delayed_job/commit/e9b1573e, "37a16d11":http://github.com/collectiveidea/delayed_job/commit/37a16d11, "803f2bfa":http://github.com/collectiveidea/delayed_job/commit/803f2bfa ]
* Fixed Delayed::Command to create tmp/pids directory [ "8ec8ca41":http://github.com/collectiveidea/delayed_job/commit/8ec8ca41 ]
* Railtie to perform Rails 3 initialization [ "3e0fc41f":http://github.com/collectiveidea/delayed_job/commit/3e0fc41f ]
* Added on_permanent_failure hook [ "d2f14cd6":http://github.com/collectiveidea/delayed_job/commit/d2f14cd6 ]

2.0.1 - 2010-04-03
==================
* Bug fix for using ActiveRecord backend with daemon [martinbtt]

2.0.0 - 2010-04-03
==================
* Multiple backend support (See README for more details)
* Added MongoMapper backend [zbelzer, moneypools]
* Added DataMapper backend [lpetre]
* Reverse priority so the jobs table can be indexed. Lower numbers have higher priority. The default priority is 0, so increase it for jobs that are not important.
* Move most of the heavy lifting from Job to Worker (#work_off, #reschedule, #run, #min_priority, #max_priority, #max_run_time, #max_attempts, #worker_name) [albus522]
* Remove EvaledJob. Implement your own if you need this functionality.
* Only use Time.zone if it is set. Closes #20
* Fix for last_error recording when destroy_failed_jobs = false, max_attempts = 1
* Implemented worker name_prefix to maintain dynamic nature of pid detection
* Some Rails 3 compatibility fixes [fredwu]

1.8.5 - 2010-03-15
==================
* Set auto_flushing=true on Rails logger to fix logging in production
* Fix error message when trying to send_later on a method that doesn't exist
* Don't use rails_env in capistrano if it's not set. closes #22
* Delayed job should append to delayed_job.log not overwrite
* Version bump to 1.8.5
* fixing Time.now to be Time.zone.now if set to honor the app set local TimeZone
* Replaced @Worker::SLEEP@, @Job::MAX_ATTEMPTS@, and @Job::MAX_RUN_TIME@ with class methods that can be overridden.
