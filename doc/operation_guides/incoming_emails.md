# Incoming Emails

OpenProject is able to receive emails and create and update work packages and reply in forums depending on the content of the email.

## Setup

Receiving emails is done via a rake task that fetches emails from an email server, parses them and performs actions depending on the content of the email. This rake task can be executed manually or automatically, e.g. with the help of a Cron job.

### IMAP

The rake task `redmine:email:receive_imap` fetches emails via IMAP and parses them.
Example:

```bash
bundle exec rake redmine:email:receive_imap host='imap.gmail.com' username='test_user' password='password' port=993 ssl=true allow_override=type,project project=test_project
```

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
| `allow_override` | specifies which attributes may be overwritten though specified by previous options. Comma separated list |


### POP3

The rake task `redmine:email:receive_pop3` fetches emails via IMAP and parses them.
Example:
```bash
bundle exec rake redmine:email:receive_pop3 host='pop.gmail.com' username='test_user' password='password' port=995 allow_override=priority
```

Available options that specifiy the email behavior are:

|key | description|
|----|------------|
|`host` | address of the email server (default: 127.0.0.1)|
| username | name of the user that is used to connect to the email server|
| password | password of the user|
| port| POP3 server port (default: 110)|
| apop | use APOP authentication (default: false)|
| delete_unprocessed | delete messages that were ignored (default: leave them on the server)|

Available arguments that change how the work packages are handled:

|key | description|
|----|------------|
| `project` | identifier of the target project|
| `tracker` | name of the target tracker|
| `category` | name of the target category|
| `priority` | name of the target priority|
| `allow_override` | specifies which attributes may be overwritten though specified by previous options. Comma separated list|

If you set a default value it will be used when creating a work package.

But then no other value is possible (even when you update the work package) unless you specify this with the use of `allow_override`. Some attributes (like `type, status, priority`) are only changeable if you specify this via `allow_override`. But notice: Some attributes have to specified in another format here, e.g. Assignee can be allowed to be overriden with `allow_override=assigned_to`.


## Format of the Emails

### Work Packages

#### Attributes

The Attributes you can use in your email are the same whether you create or update a work package. Only the project is a bit special: If you create a work package and do not specify the project via an environment variable you pass along to the rake task you have to put it into the email. If you specify it via an environment variable or you update a work package you do not need to specify it.

The subject of the work package that shall be created is derived from the subject of the email. The body of the email gets parsed and all lines that contain recognized keys are removed. What is left will become the description.

Other available keys for the email are:

|Key|Description|Example|
|---|---|---|
| Project | sets the project. Use the project identifier | Project:test\_project |
| Assigne | sets the assignee. Use the email or login of the user | Assignee:test.nutzer@example.org |
| Type | sets the type | type:Milestone |
| Version | sets the version | version:v4.1.0 |
| Start date | sets the start date | start date:2015-02-28 |
| Due date | sets the due date |  |
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

In the administator's setting you can specify lines after which an email will not be parsed anymore. That is useful if you want to reply to an email automatically sent to you from OpenProject. E.g. you could set it to `--Truncate here--` and insert this line into your email below the updates you want to perform. 
