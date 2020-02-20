---
  title: OpenProject 3.0.3
  sidebar_navigation:
      title: 3.0.3
  release_version: 3.0.3
  release_date: 2014-11-04
---


# OpenProject 3.0.3

The release of OpenProject 3.0.2 was postponed due to a critical
security issue, which was fixed in Ruby on Rails. So we skipped 3.0.2
and bring you [3.0.3](https://github.com/opf/openproject/tree/v3.0.3)
with this issue resolved.

If you want to know more about the vulnerability check out Rafael
França’s [blog
post](http://weblog.rubyonrails.org/2014/5/6/Rails_3_2_18_4_0_5_and_4_1_1_have_been_released/)
about the Rails release.

In addition we fixed a possible cross-site scripting attack that
involved tricking OpenProject with a faked MIME type when uploading
attachments.

In conclusion it is strongly recommended to upgrade your 3.0 based
deployments to version 3.0.3 as soon as possible. The [OpenProject 3.0.3
tag](https://github.com/opf/openproject/tree/v3.0.3) and
the [`dev`](https://github.com/opf/openproject/tree/dev) branches both
include the security fixes.

 

## Bug Fixes:

There was a regression in MRI Ruby 2.1.1 that changed some return values
of Ruby’s internal class `Hash` and led to several failing tests. This
change is intended for Ruby 2.2 but due to their semantic versioning
scheme shouldn’t have been incorporated in 2.1.1. Check out [this blog
post](https://www.ruby-lang.org/en/news/2014/03/10/regression-of-hash-reject-in-ruby-2-1-1/)
if you want to know more about it.

From now on we consider version 1 of our API as deprecated. It will be
completely removed with the next major release of OpenProject. Please
update any client libraries accordingly. As a heads up: we are actively
working on version 3 of our API and will deprecate version 2 rather
sooner than later as well.

We also brought back the ability to use the database to store your
session data. Even though the feature has always been inside Rails’
source code it was difficult to configure it in OpenProject. You can now
use your `configuration.yml` as well as the respective environment
variable to configure the session store. See
[`config/configuration.yml.example`](https://github.com/opf/openproject/blob/dev/config/configuration.yml.example#L149)
if you want to know how to do that exactly.

And here is the full changelog
[3.0.3](https://community.openproject.com/versions/313)


