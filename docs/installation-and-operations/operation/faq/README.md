---
sidebar_navigation:
  title: FAQ
  priority: 4
description: Frequently asked questions regarding operation and upgrading of OpenProject
keywords: operation FAQ, upgrading, database
---

# Frequently asked questions (FAQ) for Operation

## OpenProject says it's the newest version, although I know there's been a major release (e.g. 11.0). What's the problem? Why can't I upgrade?

Please note the steps that have been outlined in the blue box at the top [here](../upgrading). It's important to change the branch for this.
We implemented this to prevent users from upgrading to a major release (which could be not backwards compatible) by mistake.

## Will my data be lost when I upgrade OpenProject?

We strongly recommend a [backup](../backing-up) of your data before updating. Your data won't be lost in the regular update process, though.

## I lost access to my admin account, how do I reset my password?

You can reset your admin account through the Rails console. [Please see this separate page on how to start the console](../control/).

Assuming you have started the rails console, perform these steps:

```ruby
# Find the admin user
user = User.find_by! login: 'admin'

# Ensure the user is set to active
user.activate

# Reset any failed login attempts
user.failed_login_count = 0

# Update the password
user.password = user.password_confirmation = "YOUR NEW SAFE PASSWORD 1234!"

# Save the resource, observe if any errors are returned here
user.save!
```

Afterwards, you can navigate to your OpenProject instance and login with `admin` and your chosen password again.

## Do you provide different release channels?

Yes! We release OpenProject in separate release channels that you can try out. For production environments, **always** use the `stable/MAJOR`  (e.g., stable/9) package source that will receive stable and release updates. Every major upgrade will result in a source switch (from `stable/9` to `stable/10` for example).

A closer look at the available branches:

* [stable/11](https://packager.io/gh/opf/openproject/refs/stable/10): Latest stable releases, starting with 11.0.0 until the last minor and patch releases of 11.X.Y are released, this will receive updates.
* [release/11.0](https://packager.io/gh/opf/openproject/refs/release/10.0): Regular (usually daily) release builds for the current next patch release (or for the first release in this version, such as 11.0.0). This will contain early bugfixes before they are being release into stable. **Do not use in production**. But, for upgrading to the next major version, this can be regarded as a _release candidate channel_ that you can use to test your upgrade on a copy of your production environment.
* [dev](https://packager.io/gh/opf/openproject/refs/dev): Daily builds of the current development build of OpenProject. While we try to keep this operable, this may result in broken code and/or migrations from time to time. Use when you're interested what the next release of OpenProject will look like. **Do not use in production!**

## How can I backup and restore my OpenProject installation?

Please refer to the [backup documentation](../backing-up) for the packaged installation.
