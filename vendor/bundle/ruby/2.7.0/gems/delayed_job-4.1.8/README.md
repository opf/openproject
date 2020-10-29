**If you're viewing this at https://github.com/collectiveidea/delayed_job,
you're reading the documentation for the master branch.
[View documentation for the latest release
(4.1.8).](https://github.com/collectiveidea/delayed_job/tree/v4.1.8)**

Delayed::Job
============
[![Gem Version](https://badge.fury.io/rb/delayed_job.svg)][gem]
[![Build Status](https://travis-ci.org/collectiveidea/delayed_job.svg?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/collectiveidea/delayed_job.svg)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/collectiveidea/delayed_job/badge.svg?branch=master)][coveralls]

[gem]: https://rubygems.org/gems/delayed_job
[travis]: https://travis-ci.org/collectiveidea/delayed_job
[codeclimate]: https://codeclimate.com/github/collectiveidea/delayed_job
[coveralls]: https://coveralls.io/r/collectiveidea/delayed_job

Delayed::Job (or DJ) encapsulates the common pattern of asynchronously executing
longer tasks in the background.

It is a direct extraction from Shopify where the job table is responsible for a
multitude of core tasks. Amongst those tasks are:

* sending massive newsletters
* image resizing
* http downloads
* updating smart collections
* updating solr, our search server, after product changes
* batch imports
* spam checks

[Follow us on Twitter][twitter] to get updates and notices about new releases.

[twitter]: https://twitter.com/delayedjob

Installation
============
delayed_job 3.0.0 only supports Rails 3.0+.

delayed_job supports multiple backends for storing the job queue. [See the wiki
for other backends](https://github.com/collectiveidea/delayed_job/wiki/Backends).

If you plan to use delayed_job with Active Record, add `delayed_job_active_record` to your `Gemfile`.

```ruby
gem 'delayed_job_active_record'
```

If you plan to use delayed_job with Mongoid, add `delayed_job_mongoid` to your `Gemfile`.

```ruby
gem 'delayed_job_mongoid'
```

Run `bundle install` to install the backend and delayed_job gems.

The Active Record backend requires a jobs table. You can create that table by
running the following command:

    rails generate delayed_job:active_record
    rake db:migrate

For Rails 4.2+, see [below](#active-job)

Development
===========
In development mode, if you are using Rails 3.1+, your application code will automatically reload every 100 jobs or when the queue finishes.
You no longer need to restart Delayed Job every time you update your code in development.

Active Job
==========
In Rails 4.2+, set the queue_adapter in config/application.rb

```ruby
config.active_job.queue_adapter = :delayed_job
```

See the [rails guide](http://guides.rubyonrails.org/active_job_basics.html#setting-the-backend) for more details.

Rails 4.x
=========
If you are using the protected_attributes gem, it must appear before delayed_job in your gemfile. If your jobs are failing with:

     ActiveRecord::StatementInvalid: PG::NotNullViolation: ERROR:  null value in column "handler" violates not-null constraint

then this is the fix you're looking for.

Upgrading from 2.x to 3.0.0 on Active Record
============================================
Delayed Job 3.0.0 introduces a new column to the delayed_jobs table.

If you're upgrading from Delayed Job 2.x, run the upgrade generator to create a migration to add the column.

    rails generate delayed_job:upgrade
    rake db:migrate

Queuing Jobs
============
Call `.delay.method(params)` on any object and it will be processed in the background.

```ruby
# without delayed_job
@user.activate!(@device)

# with delayed_job
@user.delay.activate!(@device)
```

If a method should always be run in the background, you can call
`#handle_asynchronously` after the method declaration:

```ruby
class Device
  def deliver
    # long running method
  end
  handle_asynchronously :deliver
end

device = Device.new
device.deliver
```

## Parameters

`#handle_asynchronously` and `#delay` take these parameters:

- `:priority` (number): lower numbers run first; default is 0 but can be reconfigured (see below)
- `:run_at` (Time): run the job after this time (probably in the future)
- `:queue` (string): named queue to put this job in, an alternative to priorities (see below)

These params can be Proc objects, allowing call-time evaluation of the value.

For example:

```ruby
class LongTasks
  def send_mailer
    # Some other code
  end
  handle_asynchronously :send_mailer, :priority => 20

  def in_the_future
    # Some other code
  end
  # 5.minutes.from_now will be evaluated when in_the_future is called
  handle_asynchronously :in_the_future, :run_at => Proc.new { 5.minutes.from_now }

  def self.when_to_run
    2.hours.from_now
  end

  class << self
    def call_a_class_method
      # Some other code
    end
    handle_asynchronously :call_a_class_method, :run_at => Proc.new { when_to_run }
  end

  attr_reader :how_important

  def call_an_instance_method
    # Some other code
  end
  handle_asynchronously :call_an_instance_method, :priority => Proc.new {|i| i.how_important }
end
```

If you ever want to call a `handle_asynchronously`'d method without Delayed Job, for instance while debugging something at the console, just add `_without_delay` to the method name. For instance, if your original method was `foo`, then call `foo_without_delay`.

Rails 3 Mailers
===============
Due to how mailers are implemented in Rails 3, we had to do a little work around to get delayed_job to work.

```ruby
# without delayed_job
Notifier.signup(@user).deliver

# with delayed_job
Notifier.delay.signup(@user)

# with delayed_job running at a specific time
Notifier.delay(run_at: 5.minutes.from_now).signup(@user)
```

Remove the `.deliver` method to make it work. It's not ideal, but it's the best
we could do for now.

Named Queues
============
DJ 3 introduces Resque-style named queues while still retaining DJ-style
priority. The goal is to provide a system for grouping tasks to be worked by
separate pools of workers, which may be scaled and controlled individually.

Jobs can be assigned to a queue by setting the `queue` option:

```ruby
object.delay(:queue => 'tracking').method

Delayed::Job.enqueue job, :queue => 'tracking'

handle_asynchronously :tweet_later, :queue => 'tweets'
```

You can configure default priorities for named queues:

```ruby
Delayed::Worker.queue_attributes = {
  high_priority: { priority: -10 },
  low_priority: { priority: 10 }
}
```

Configured queue priorities can be overriden by passing priority to the delay method

```ruby
object.delay(:queue => 'high_priority', priority: 0).method
```

You can start processes to only work certain queues with the `queue` and `queues`
options defined below. Processes started without specifying a queue will run jobs
from **any** queue. To effectively have a process that runs jobs where a queue is not
specified, set a default queue name with `Delayed::Worker.default_queue_name` and
have the processes run that queue.

Running Jobs
============
`script/delayed_job` can be used to manage a background process which will
start working off jobs.

To do so, add `gem "daemons"` to your `Gemfile` and make sure you've run `rails
generate delayed_job`.

You can then do the following:

    RAILS_ENV=production script/delayed_job start
    RAILS_ENV=production script/delayed_job stop

    # Runs two workers in separate processes.
    RAILS_ENV=production script/delayed_job -n 2 start
    RAILS_ENV=production script/delayed_job stop

    # Set the --queue or --queues option to work from a particular queue.
    RAILS_ENV=production script/delayed_job --queue=tracking start
    RAILS_ENV=production script/delayed_job --queues=mailers,tasks start

    # Use the --pool option to specify a worker pool. You can use this option multiple times to start different numbers of workers for different queues.
    # The following command will start 1 worker for the tracking queue,
    # 2 workers for the mailers and tasks queues, and 2 workers for any jobs:
    RAILS_ENV=production script/delayed_job --pool=tracking --pool=mailers,tasks:2 --pool=*:2 start

    # Runs all available jobs and then exits
    RAILS_ENV=production script/delayed_job start --exit-on-complete
    # or to run in the foreground
    RAILS_ENV=production script/delayed_job run --exit-on-complete

**Rails 4:** *replace script/delayed_job with bin/delayed_job*

Workers can be running on any computer, as long as they have access to the
database and their clock is in sync. Keep in mind that each worker will check
the database at least every 5 seconds.

You can also invoke `rake jobs:work` which will start working off jobs. You can
cancel the rake task with `CTRL-C`.

If you want to just run all available jobs and exit you can use `rake jobs:workoff`

Work off queues by setting the `QUEUE` or `QUEUES` environment variable.

    QUEUE=tracking rake jobs:work
    QUEUES=mailers,tasks rake jobs:work

Restarting delayed_job
======================

The following syntax will restart delayed jobs:

    RAILS_ENV=production script/delayed_job restart

To restart multiple delayed_job workers:

    RAILS_ENV=production script/delayed_job -n2 restart

**Rails 4:** *replace script/delayed_job with bin/delayed_job*



Custom Jobs
===========
Jobs are simple ruby objects with a method called perform. Any object which responds to perform can be stuffed into the jobs table. Job objects are serialized to yaml so that they can later be resurrected by the job runner.

```ruby
NewsletterJob = Struct.new(:text, :emails) do
  def perform
    emails.each { |e| NewsletterMailer.deliver_text_to_email(text, e) }
  end
end

Delayed::Job.enqueue NewsletterJob.new('lorem ipsum...', Customers.pluck(:email))
```

To set a per-job max attempts that overrides the Delayed::Worker.max_attempts you can define a max_attempts method on the job

```ruby
NewsletterJob = Struct.new(:text, :emails) do
  def perform
    emails.each { |e| NewsletterMailer.deliver_text_to_email(text, e) }
  end

  def max_attempts
    3
  end
end
```

To set a per-job max run time that overrides the Delayed::Worker.max_run_time you can define a max_run_time method on the job

NOTE: this can ONLY be used to set a max_run_time that is lower than Delayed::Worker.max_run_time. Otherwise the lock on the job would expire and another worker would start the working on the in progress job.

```ruby
NewsletterJob = Struct.new(:text, :emails) do
  def perform
    emails.each { |e| NewsletterMailer.deliver_text_to_email(text, e) }
  end

  def max_run_time
    120 # seconds
  end
end
```

To set a per-job default for destroying failed jobs that overrides the Delayed::Worker.destroy_failed_jobs you can define a destroy_failed_jobs? method on the job

```ruby
NewsletterJob = Struct.new(:text, :emails) do
  def perform
    emails.each { |e| NewsletterMailer.deliver_text_to_email(text, e) }
  end

  def destroy_failed_jobs?
    false
  end
end
```

To set a default queue name for a custom job that overrides Delayed::Worker.default_queue_name, you can define a queue_name method on the job

```ruby
NewsletterJob = Struct.new(:text, :emails) do
  def perform
    emails.each { |e| NewsletterMailer.deliver_text_to_email(text, e) }
  end

  def queue_name
    'newsletter_queue'
  end
end
```

On error, the job is scheduled again in 5 seconds + N ** 4, where N is the number of attempts. You can define your own `reschedule_at` method to override this default behavior.

```ruby
NewsletterJob = Struct.new(:text, :emails) do
  def perform
    emails.each { |e| NewsletterMailer.deliver_text_to_email(text, e) }
  end

  def reschedule_at(current_time, attempts)
    current_time + 5.seconds
  end
end
```

Hooks
=====
You can define hooks on your job that will be called at different stages in the process:


**NOTE:** If you are using ActiveJob these hooks are **not** available to your jobs. You will need to use ActiveJob's callbacks. You can find details here https://guides.rubyonrails.org/active_job_basics.html#callbacks

```ruby
class ParanoidNewsletterJob < NewsletterJob
  def enqueue(job)
    record_stat 'newsletter_job/enqueue'
  end

  def perform
    emails.each { |e| NewsletterMailer.deliver_text_to_email(text, e) }
  end

  def before(job)
    record_stat 'newsletter_job/start'
  end

  def after(job)
    record_stat 'newsletter_job/after'
  end

  def success(job)
    record_stat 'newsletter_job/success'
  end

  def error(job, exception)
    Airbrake.notify(exception)
  end

  def failure(job)
    page_sysadmin_in_the_middle_of_the_night
  end
end
```

Gory Details
============
The library revolves around a delayed_jobs table which looks as follows:

```ruby
create_table :delayed_jobs, :force => true do |table|
  table.integer  :priority, :default => 0      # Allows some jobs to jump to the front of the queue
  table.integer  :attempts, :default => 0      # Provides for retries, but still fail eventually.
  table.text     :handler                      # YAML-encoded string of the object that will do work
  table.text     :last_error                   # reason for last failure (See Note below)
  table.datetime :run_at                       # When to run. Could be Time.zone.now for immediately, or sometime in the future.
  table.datetime :locked_at                    # Set when a client is working on this object
  table.datetime :failed_at                    # Set when all retries have failed (actually, by default, the record is deleted instead)
  table.string   :locked_by                    # Who is working on this object (if locked)
  table.string   :queue                        # The name of the queue this job is in
  table.timestamps
end
```

On error, the job is scheduled again in 5 seconds + N ** 4, where N is the number of attempts or using the job's defined `reschedule_at` method.

The default `Worker.max_attempts` is 25. After this, the job is either deleted (default), or left in the database with "failed_at" set.
With the default of 25 attempts, the last retry will be 20 days later, with the last interval being almost 100 hours.

The default `Worker.max_run_time` is 4.hours. If your job takes longer than that, another computer could pick it up. It's up to you to
make sure your job doesn't exceed this time. You should set this to the longest time you think the job could take.

By default, it will delete failed jobs (and it always deletes successful jobs). If you want to keep failed jobs, set
`Delayed::Worker.destroy_failed_jobs = false`. The failed jobs will be marked with non-null failed_at.

By default all jobs are scheduled with `priority = 0`, which is top priority. You can change this by setting `Delayed::Worker.default_priority` to something else. Lower numbers have higher priority.

The default behavior is to read 5 jobs from the queue when finding an available job. You can configure this by setting `Delayed::Worker.read_ahead`.

By default all jobs will be queued without a named queue. A default named queue can be specified by using `Delayed::Worker.default_queue_name`.

If no jobs are found, the worker sleeps for the amount of time specified by the sleep delay option. Set `Delayed::Worker.sleep_delay = 60` for a 60 second sleep time.

It is possible to disable delayed jobs for testing purposes. Set `Delayed::Worker.delay_jobs = false` to execute all jobs realtime.

Or `Delayed::Worker.delay_jobs` can be a Proc that decides whether to execute jobs inline on a per-job basis:

```ruby
Delayed::Worker.delay_jobs = ->(job) {
  job.queue != 'inline'
}
```

You may need to raise exceptions on SIGTERM signals, `Delayed::Worker.raise_signal_exceptions = :term` will cause the worker to raise a `SignalException` causing the running job to abort and be unlocked, which makes the job available to other workers. The default for this option is false.

Here is an example of changing job parameters in Rails:

```ruby
# config/initializers/delayed_job_config.rb
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
```

Cleaning up
===========
You can invoke `rake jobs:clear` to delete all jobs in the queue.

Having problems?
================
Good places to get help are:
* [Google Groups](http://groups.google.com/group/delayed_job) where you can join our mailing list.
* [StackOverflow](http://stackoverflow.com/questions/tagged/delayed-job)
