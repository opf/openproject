# openproject-gitlab-integration
OpenProject module for integration with Gitlab (latest release tested is 13.9.3)

This plugin is based on the current plugin to integrate Github with OpenProject (https://docs.openproject.org/system-admin-guide/github-integration).

The reference system is the same as for GitHub integration. You can use a link to the work package or just use “OP#87” in the title or description in Gitlab.

## Available events captured in OpenProject

OpenProject will **add comments** to work package for the following events:
* Merge Request (Opened, Closed and Merged)
* Issue (Opened, Closed)
* Push commits in Merge Requests
* Comments (on Issues, Merge Request, Commits and Snippets)

OpenProject will **update WP status** in this events:
* Merge Request (opened) - Status: In progress (currently ID=7)
* Merge Request (merged) - Status: Developed (currently ID=8)

## Example workflow

A typical workflow on Gitlab side would be:
1. **Create Issue.**
> **Issue Opened:** Issue 6 New contact form - OP#18 for Scrum project has been opened by Administrator.

2. **Comment on issue.**
> **Commented in Issue:** Administrator commented this WP in Issue 6 New contact form - OP#18 on Scrum project:
>
> New comment on the issue with attachment.
3. **Create Merge Request.**
> **MR Opened:** Merge request 25 Draft: Resolve "New contact form - OP#18" for Scrum project has been opened by Administrator.
> 
> **Status** changed from _Specified_
> **to** _In progress_
4. **Comment in Merge Request.**
> **Commented in MR:** Administrator commented this WP in Merge request 25 Draft: Resolve "New contact form - OP#18" on Scrum project:
> 
> New comment on MR.
5. **Reference in other Issues (comments).**
> **Referenced in Issue:** Administrator referenced this WP in Issue 2 New backend pipeline on Scrum project:
> 
> OP#18 New comment about...
6. **New commit in Merge Request.**
> **Pushed in MR:** Administrator pushed fca3d6fb to Scrum project at 2021-03-08T08:01:57+00:00:
> 
> Update readme.md OP#18
7. **Comment in a new commit of the Merge Request.**
> **Referenced in Commit:** Administrator referenced this WP in a Commit Note 0bf0e3e9 on Scrum project:
> 
> This change is for OP#18.
8. **Merge Request merged (generates up to 3 events).**
> **Pushed in MR:** Administrator pushed 1da09cb4 to Scrum project at 2021-03-05T14:57:37+00:00:
> 
> Merge branch '5-new-contact-form-op-18' into 'master'
> 
> Resolve "New contact form - OP#18"
> 
> Closes #6
> 
> See merge request root/scrum!9

> **MR Merged:** Merge request 24 Resolve "New contact form - OP#18" for Scrum project has been merged by Administrator.
> 
> **Status** changed from _In progress_
> **to** _Developed_

> **Issue Closed:** Issue 6 New contact form - OP#18 for Scrum project has been closed by Administrator.

## Configuration

You will have to configure both OpenProject and Gitlab for the integration to work. But first you must modify **Gemfile.lock** and **Gemfile.modules** so that OpenProject detects the new module.

Add the following in **Gemfile.lock**:
```
PATH
  remote: modules/gitlab_integration
  specs:
    openproject-gitlab_integration (1.0.0)
      openproject-webhooks
```

Add the following in **Gemfile.modules**:
```
group :opf_plugins do
...
  gem 'openproject-gitlab_integration',        path: 'modules/gitlab_integration'
...
end
```

### OpenProject

First you will need to create a user in OpenProject that will make the comments. The user will have to be added to each project with a role that allows them to comment on work packages and change status.

Once the user is created you need to generate an OpenProject API token for it to use later on the Gitlab side:

* Login as the newly created user.
* Go to My Account (click on Avatar in top right corner).
* Go to Access Token.
* Click on generate in the API row.
* Copy the generated key. You can now configure the necessary webhook in Gitlab.

### Gitlab

In Gitlab you have to set up a webhook in each repository to be integrated with OpenProject.

You need to configure just two things in the webhook:
1. The URL must point to your OpenProject server’s Gitlab webhook endpoint (/webhooks/gitlab). Append it to the URL as a simple GET parameter named key. In the end the URL should look something like this:
```
http://openproject-url.com/webhooks/gitlab?key=ae278268
```
2. Enable the required triggers: Push events, Comments, Issues events, Merge request events

Now the integration is set up on both sides and you can use it.
