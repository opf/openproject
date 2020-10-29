# with_advisory_lock

Adds advisory locking (mutexes) to ActiveRecord 4.2, 5.x and 6.0, with ruby
2.4, 2.5 and 2.6, when used with
[MySQL](https://dev.mysql.com/doc/refman/8.0/en/miscellaneous-functions.html#function_get-lock)
or
[PostgreSQL](https://www.postgresql.org/docs/current/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS).
SQLite resorts to file locking.

[![Build Status](https://api.travis-ci.org/ClosureTree/with_advisory_lock.svg?branch=master)](https://travis-ci.org/ClosureTree/with_advisory_lock)
[![Gem Version](https://badge.fury.io/rb/with_advisory_lock.svg)](https://badge.fury.io/rb/with_advisory_lock)

## What's an "Advisory Lock"?

An advisory lock is a [mutex](https://en.wikipedia.org/wiki/Mutual_exclusion)
used to ensure no two processes run some process at the same time. When the
advisory lock is powered by your database server, as long as it isn't SQLite,
your mutex spans hosts.

## Usage

This gem automatically includes the `WithAdvisoryLock` module in all of your
ActiveRecord models. Here's an example of how to use it where `User` is an
ActiveRecord model, and `lock_name` is some string:

```ruby
User.with_advisory_lock(lock_name) do
  do_something_that_needs_locking
end
```

### What happens

1. The thread will wait indefinitely until the lock is acquired.
2. While inside the block, you will exclusively own the advisory lock.
3. The lock will be released after your block ends, even if an exception is raised in the block.

### Lock wait timeouts

`with_advisory_lock` takes an options hash as the second parameter. The
`timeout_seconds` option defaults to `nil`, which means wait indefinitely for
the lock.

A value of zero will try the lock only once. If the lock is acquired, the block
will be yielded to. If the lock is currently being held, the block will not be
called.

Note that if a non-nil value is provided for `timeout_seconds`, the block will
not be invoked if the lock cannot be acquired within that time-frame.

For backwards compatability, the timeout value can be specified directly as the
second parameter.

### Shared locks

The `shared` option defaults to `false` which means an exclusive lock will be
obtained. Setting `shared` to `true` will allow locks to be obtained by multiple
actors as long as they are all shared locks.

Note: MySQL does not support shared locks.

### Transaction-level locks

PostgreSQL supports transaction-level locks which remain held until the
transaction completes. You can enable this by setting the `transaction` option
to `true`.

Note: transaction-level locks will not be reflected by `.current_advisory_lock`
when the block has returned.

### Return values

The return value of `with_advisory_lock_result` is a `WithAdvisoryLock::Result`
instance, which has a `lock_was_acquired?` method and a `result` accessor
method, which is the returned value of the given block. If your block may
validly return false, you should use this method.

The return value of `with_advisory_lock` will be the result of the yielded
block, if the lock was able to be acquired and the block yielded, or `false`, if
you provided a timeout_seconds value and the lock was not able to be acquired in
time.

### Testing for the current lock status

If you needed to check if the advisory lock is currently being held, you can
call `Tag.advisory_lock_exists?("foo")`, but realize the lock can be acquired
between the time you test for the lock, and the time you try to acquire the
lock.

If you want to see if the current Thread is holding a lock, you can call
`Tag.current_advisory_lock` which will return the name of the current lock. If
no lock is currently held, `.current_advisory_lock` returns `nil`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'with_advisory_lock'
```

And then execute:

    $ bundle

## Lock Types

First off, know that there are **lots** of different kinds of locks available to
you. **Pick the finest-grain lock that ensures correctness.** If you choose a
lock that is too coarse, you are unnecessarily blocking other processes.

### Advisory locks

These are named mutexes that are inherently "application level"—it is up to the
application to acquire, run a critical code section, and release the advisory
lock.

### Row-level locks

Whether [optimistic](http://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html)
or [pessimistic](http://api.rubyonrails.org/classes/ActiveRecord/Locking/Pessimistic.html),
row-level locks prevent concurrent modification to a given model.

**If you're building a
[CRUD](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
application, this will be your most commonly used lock.**

### Table-level locks

Provided through something like the
[monogamy](https://github.com/ClosureTree/monogamy) gem, these prevent
concurrent access to **any instance of a model**. Their coarseness means they
aren't going to be commonly applicable, and they can be a source of
[deadlocks](http://en.wikipedia.org/wiki/Deadlock).

## FAQ

### Transactions and Advisory Locks

Advisory locks with MySQL and PostgreSQL ignore database transaction boundaries.

You will want to wrap your block within a transaction to ensure consistency.

### MySQL < 5.7.5 doesn't support nesting

With MySQL < 5.7.5, if you ask for a _different_ advisory lock within
a `with_advisory_lock` block, you will be releasing the parent lock (!!!). A
`NestedAdvisoryLockError`will be raised in this case. If you ask for the same
lock name, `with_advisory_lock` won't ask for the lock again, and the block
given will be yielded to.

This is not an issue in MySQL >= 5.7.5, and no error will be raised for nested
lock usage. You can override this by passing `force_nested_lock_support: true`
or `force_nested_lock_support: false` to the `with_advisory_lock` options.

### Is clustered MySQL supported?

[No.](https://github.com/ClosureTree/with_advisory_lock/issues/16)

### There are many `lock-*` files in my project directory after test runs

This is expected if you aren't using MySQL or Postgresql for your tests.
See [issue 3](https://github.com/ClosureTree/with_advisory_lock/issues/3).

SQLite doesn't have advisory locks, so we resort to file locking, which will
only work if the `FLOCK_DIR` is set consistently for all ruby processes.

In your `spec_helper.rb` or `minitest_helper.rb`, add a `before` and `after` block:

```ruby
before do
  ENV['FLOCK_DIR'] = Dir.mktmpdir
end

after do
  FileUtils.remove_entry_secure ENV['FLOCK_DIR']
end
```
