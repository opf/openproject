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

> **Note about the status.** If you want to change the ID of the status you can do this in this section of the [code](https://github.com/btey/openproject-gitlab-integration/blob/58279c79035539bdd127d14e2fd148c06d85a15a/lib/open_project/gitlab_integration/notification_handlers.rb#L108-L111).
>
> **Note about the references.** Whether or not to include the reference in certain places depends on the information that Gitlab sends through its webhook. If you include the reference in the title of an issue, the comments on the issue do not need to include the reference. The same will happen when you generate a Merge Request based on an Issue that already includes the reference; comments from that MR need not include the reference.

## Example workflow

A typical workflow on Gitlab side would be:
1. **Create Issue.**

   <img src="doc/op-issue-opened.png" width="500">

> **Issue Opened:** Issue 6 New contact form - OP#18 for Scrum project has been opened by Administrator.

2. **Comment on issue.**

   If the reference is included in the title, the comments will not need a reference. By default, all comments will use the title as a reference.
   
   <img src="doc/op-commented-in-issue.png" width="500">
   
   > **Commented in Issue:** Administrator commented this WP in Issue 6 New contact form - OP#18 on Scrum project:
   >
   > New comment on the issue with attachment.

3. **Create Merge Request.**

   <img src="doc/op-mr-opened.png" width="500">

   > **MR Opened:** Merge request 25 Draft: Resolve "New contact form - OP#18" for Scrum project has been opened by Administrator.
   > 
   > **Status** changed from _Specified_
   > **to** _In progress_

4. **Comment in Merge Request.**

   <img src="doc/op-commented-in-mr.png" width="500">

   > **Commented in MR:** Administrator commented this WP in Merge request 25 Draft: Resolve "New contact form - OP#18" on Scrum project:
   > 
   > New comment on MR.

5. **Reference in other Issues or Merge Request (comments).**

   If the reference is NOT included in the title of the Issue/MR, the comments will need a reference. In OpenProject the comment will be saved as "referenced" in Issue/MR.

   <img src="doc/op-referenced-in-issue.png" width="500">

   > **Referenced in Issue:** Administrator referenced this WP in Issue 2 New backend pipeline on Scrum project:
   > 
   > OP#18 New comment about...

6. **New commit in Merge Request.**

   <img src="doc/op-pushed-in-mr.png" width="500">

   > **Pushed in MR:** Administrator pushed fca3d6fb to Scrum project at 2021-03-08T08:01:57+00:00:
   > 
   > Update readme.md OP#18

7. **Comment in a new commit of the Merge Request.**

   <img src="doc/op-referenced-in-commit.png" width="500">

   > **Referenced in Commit:** Administrator referenced this WP in a Commit Note 0bf0e3e9 on Scrum project:
   > 
   > This change is for OP#18.

8. **Merge Request merged (generates up to 3 events).**

   <img src="doc/op-mr-merged-event-2.png" width="500">

   > **Pushed in MR:** Administrator pushed 1da09cb4 to Scrum project at 2021-03-05T14:57:37+00:00:
   > 
   > Merge branch '5-new-contact-form-op-18' into 'master'
   > 
   > Resolve "New contact form - OP#18"
   > 
   > Closes #6
   > 
   > See merge request root/scrum!9

   <img src="doc/op-mr-merged-event-3.png" width="500">

   > **MR Merged:** Merge request 24 Resolve "New contact form - OP#18" for Scrum project has been merged by Administrator.
   > 
   > **Status** changed from _In progress_
   > **to** _Developed_

   <img src="doc/op-mr-merged-event-4.png" width="500">

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

## How to report bugs or issues

Any error, bug or issue can be reported by creating a new [issue](https://github.com/btey/openproject-gitlab-integration/issues/new).
