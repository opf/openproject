---
sidebar_navigation:
  title: Configuring inbound emails
  priority: 7
description: Configuring inbound emails in OpenProject.
robots: index, follow
keywords: incoming, e-mail, inbound, mail
---

# Configuring inbound emails

OpenProject is able to receive incoming emails and create and update work packages and reply in forums depending on the content of the email.
If you're using the Enterprise cloud you can skip the Setup section, as the settings are already configured.

## Setup

Receiving emails is done via a rake task that fetches emails from an email server, parses them and performs actions depending on the content of the email. This rake task can be executed manually or automatically, e.g. with the help of a Cron job.

The rake task `redmine:email:receive_imap` fetches emails via IMAP and parses them.

**Packaged installation**

```bash
openproject run bundle exec rake redmine:email:receive_imap host='imap.gmail.com' username='test_user' password='password' port=993 ssl=true allow_override=type,project project=test_project
```

**Docker installation**

The docker installation has a ["cron-like" daemon](https://github.com/opf/openproject/blob/dev/docker/cron) that will imitate the above cron job. You need to specify the following ENV variables (e.g., to your env list file)

- `IMAP_SSL` set to true or false depending on whether the ActionMailer IMAP connection requires implicit TLS/SSL
- `IMAP_PORT` `IMAP_HOST` set to the IMAP host and port of your connection
- `IMAP_USERNAME` and `IMAP_PASSWORD`

Optional ENV variables:

- `IMAP_CHECK_INTERVAL=600` Interval in seconds to check for new mails (defaults to 10minutes)
- `IMAP_ALLOW_OVERRIDE` Attributes writable (true for all), comma-separated list as specified in `allow_override` configuration.

Available arguments for this rake task that specify the email behavior are

|key | description|
|----|------------|
| `host` | address of the email server |
| `username` | the name of the user that is used to connect to the email server|
| `password` | the password of the user|
| `port` | the port that is used to connect to the email server|
| `ssl` | specifies if SSL should be used when connecting to the email server|
| `folder` | the folder to fetch emails from (default: INBOX)|
| `move_on_success` | the folder emails that were successfully parsed are moved to (instead of deleted)|
| `move_on_failure` | the folder emails that were ignored are moved to|

Available arguments that change how the work packages are handled:

| key | description |
|---|---|
| `project` | identifier of the target project |
| `tracker` | name of the target tracker |
| `category` | name of the target category |
| `priority` | name of the target priority |
| `status` | name of the target status |
| `version` | name of the target version |
| `type` | name of the target type |
| `priority` | name of the target priority |
| `unknown_user`| ignore: email is ignored (default), accept: accept as anonymous user, create: create a user account |
| `allow_override` | specifies which attributes may be overwritten though specified by previous options. Comma separated list |

## Format of the emails

Please note: It's important to use the plain text editor of your email client (instead of the HTML editor) to avoid misinterpretations (e.g. for the project name). 

### Work packages

Let's start with two examples right away to get you started.
You can learn more about the details below.

**Work package update**

When you receive a work package notification you can simply reply to that email
and it will be added as a comment to the work package. You can also update attributes.

For instance with the following reply.

```
status: closed

The issue is sorted then. Closing this.
```

This will add the comment and close the work package.

![Work package closed via email](./work-package-update-via-email.png)

**Work package creation**

You can also create new work packages via email. Make sure to send your email to the same address you would
use when replying to a work package notification.

When creating a work package, the project it will be created in will either be pre-defined via configuration (see below) or you will have to define it at the start of the email. You can also define its other attributes
there.

For example if you write an email with the subject "Fixing problems" and the following body:

```
project: demo-project
type: Task
status: In Progress

I'm looking into the problems.
```

It will create a new work package in the Demo Project of type task which is in progress.
`demo-project` is the project's identifier which you can see either in the project settings
or simply by looking at the address bar in your browser when you are in the project.

![Work package created via email](./work-package-creation-via-email.png)

#### Sending user address

The address the mail is sent from must match an existing account in order to map the user action.
If a matching account is found, the mail handler impersonates the user to create the ticket.

If no matching account is found, the mail is rejected. To override this behavior and allow unknown mail address
to create work packages, set the option `no_permission_check=1` and specify with `unknown_user=accept`

**Note**: This feature only provides a mapping of mail to user account, it does not authenticate the user based on the mail. Since you can easily spoof mail addresses, you should not rely on the authenticity of work packages created that way. At the moment in the OpenProject Enterprise Cloud work package generation by emails can only be triggered by registered email addresses.

**Users with mail suffixes**

If you're used to using mail accounts with suffix support such as Google Mail, where you can specify `account+suffix@googlemail.com`, you will receive mails to that account but respond with your regular account `account@googlemail.com` . To mitigate this, OpenProject by default will expand searching for mail addresses `account@domain` to accounts `account+suffix@domain`  through regex searching the mail column. If you do not wish that behavior or want to customize the prefix, alter the setting `mail_suffix_separators` by running `bundle exec rails runner "Setting.mail_suffix_separators = ''"`



#### Attributes

The Attributes you can use in your email are the same whether you create or update a work package.

Only the `project` attribute is a bit special:

You must either add `project` to the set of allowed overridden attributes with `allow_override=project,..` in order to use it in a mail,
OR set it as fixed variable with `project=identifier`.

The subject of the work package that shall be created is derived from the subject of the email. The body of the email gets parsed and all lines that contain recognized keys are removed. What is left will become the description.

Other available keys for the email are:

|Key|Description|Example|
|---|---|---|
| Project | sets the project. Use the project identifier | Project:test\_project |
| Assignee | sets the assignee. Use the email or login of the user | Assignee:test.nutzer@example.org |
| Type | sets the type | type:Milestone |
| Version | sets the version | version:v4.1.0 |
| Start date | sets the start date | start date:2015-02-28 |
| Due date | sets the finish date |  |
| Done ratio | sets the done ratio. Use a number | Done ratio:40 |
| Status | sets the status | Status:closed |
| priority | sets the priority | priority:High |

If you want to set a custom field just use the name as it is displayed in your browser, e.g. `Custom field:new value`

**Notice: The keys are not case-sensitive but the values you want to set are.**

#### Attachments

If you create or update a work package via email the attachments of the email will be attached to the relevant work package.

#### Watchers

If you create a work package via email and sent it to another email (to or bcc) OpenProject will search for a user with this email and add it as watcher.

### Truncate Emails

In the administrator's setting you can specify lines after which an email will not be parsed anymore. That is useful if you want to reply to an email automatically sent to you from OpenProject. E.g. you could set it to `--Truncate here--` and insert this line into your email below the updates you want to perform.
