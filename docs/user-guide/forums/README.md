---
sidebar_navigation:
  title: Forums
  priority: 820
description: Create and manage a forum in OpenProject
keywords: forum, forums, topic, reply
---

# Forums

In the forums in OpenProject you can discuss topics in a project with the team: ask questions, reply to them and document the answers.

<div class="glossary">

**Forum** is defined as a module used to display forums and their topics. The module has to be [activated in the project settings](../projects/project-settings/modules/) to be displayed in the side navigation.

</div>

| Topic                                                                   | Content                                                                    |
|-------------------------------------------------------------------------|----------------------------------------------------------------------------|
| [Create a new forum](#create-a-new-forum)                               | How to create a new forum.                                                 |
| [Manage forums](#manage-forums)                                         | How to sort, edit or delete a forum.                                       |
| [Open a forum](#open-a-forum)                                           | How to open an existing forum and sort its topics.                         |
| [Create a new topic](#create-a-new-topic-in-a-forum)                    | How to start a new topic in a forum.                                       |
| [Read a topic](#read-a-topic)                                           | How to read a topic and load its older replies.                            |
| [Reply to a topic](#reply-to-a-topic)                                   | How to reply to a topic or quote a post.                                   |
| [Create a work package](#create-a-work-package-from-a-topic-or-a-reply) | How to turn a topic or a reply into a work package.                        |
| [Watch a forum](#watch-a-forum)                                         | How to keep informed about changes in a forum, e.g. new topics or replies. |
| [Edit a topic or a reply](#edit-a-topic-or-a-reply)                     | How to edit a post in a forum.                                             |
| [Delete a topic or a reply](#delete-a-topic-or-a-reply)                 | How to delete a topic or a single reply.                                   |

## Create a new forum

To create a new forum in your project, navigate to the **Forums** module in the project navigation and click the **+ Forum** button.

Enter a name and description for the new forum. Click the **Create** button to save the new forum.

![Create new forum in OpenProject](openproject_user_guide_forums_new_forum_create_form.png)

## Manage forums

To change the order of the forums in your project, edit a forum, or delete a forum, go to the list of forums in your project.

- **Drag and drop** a forum by its handle on the left to change its position in the list.
- Click the **More** (three dots) icon of a forum to **edit** its name or description, to **move** it up or down, or to **delete** it.

![Manage forums in OpenProject](openproject_user_guide_forums_manage.png)

## Open a forum

To work in the forums in OpenProject, select the menu item **Forums** in the project navigation.

![Forums module in OpenProject](openproject_user_guide_forums_module.png)

You will get a list of all forums within the project with their description, the number of topics and messages, as well as the last message posted in each forum.

Click on the name of a forum to open it.

![A forum and its topics in OpenProject](openproject_user_guide_forums_single_forum.png)

Each topic shows its subject, its author, the date it was started and a preview of its opening post, as well as the number of replies and the last reply. A pin marks a sticky topic, which always stays on top of the list. A lock marks a locked topic, which no longer accepts replies.

To change the order of the topics, open the **Sort** menu and choose between **Recent activity**, **Oldest activity**, **Newest**, **Oldest**, **Most replies** and **Fewest replies**.

![Sort the topics of a forum in OpenProject](openproject_user_guide_forums_sort_topics.png)

## Create a new topic in a forum

To **start a new topic** in a forum, click the green **+ Topic** button on the top right of the forum.

Enter the **subject** of the topic.

You can choose whether the topic should be **Sticky**. A sticky topic always appears on top of the forum.

Select whether the topic should be **Locked**. Then nobody can reply to it anymore.

Enter the **message content**. Its beginning is shown as a preview under the subject in the forum. You can attach files if needed.

Click the **Create** button to create the new topic in this forum.

![Create a new forum topic in OpenProject](openproject_user_guide_forums_new_topic.png)

The **new topic has been created**.

![New forum topic in OpenProject](openproject_user_guide_forums_new_topic_created.png)

> [!TIP]
> Changes you make in the editor are saved locally. If you navigated away from the page or could not save your changes due to a technical difficulty, you can restore them with the **Show local modifications** button in the editor toolbar.

![Locally saved draft in an OpenProject forum topic](openproject_user_guide_forums_draft_saved_locally.png)

## Read a topic

Click on the subject of a topic to open it. Underneath the subject you see when the topic was started, how many replies it has and how many people take part in it.

The opening post is followed by its replies, from the oldest to the newest. In a long topic, only the latest 20 replies are shown. To show the older ones, click the button above them, e.g. **Load previous 5 replies**.

![Load the previous replies of a forum topic in OpenProject](openproject_user_guide_forums_load_previous_replies.png)

## Reply to a topic

To **reply to a topic**, open it. Underneath the last reply, enter your message in the editor. You can also **attach files** if needed.

Click the **Reply** button to save your reply.

![Reply to a forum topic in OpenProject](openproject_user_guide_forums_reply_form.png)

Your reply has been added at the end of the topic.

![Reply added to a forum topic in OpenProject](openproject_user_guide_forums_reply_saved.png)

### Quote a post

To quote a post in your reply, click the **More** (three dots) icon of that post and select **Quote message**. The quoted text is added to the editor, where you can complete your reply.

From the same menu, **Copy link to clipboard** copies a link that opens the topic at that post.

![Actions on a forum reply in OpenProject](openproject_user_guide_forums_post_actions.png)

## Create a work package from a topic or a reply

When a discussion leads to something to do, you can **create a work package** from the post that started it. You need the permission to add work packages in the project.

Hover the post and click the **+ Add new work package** button next to its **More** (three dots) icon. You can also select **Add new work package** in the **More** menu.

![Add a work package from a forum reply in OpenProject](openproject_user_guide_forums_add_work_package_button.png)

A dialog opens with the subject of the topic as the subject of the work package and the content of the post as its description. Adjust them, choose the type and the other attributes, and click **Create**.

![Create a work package from a forum post in OpenProject](openproject_user_guide_forums_add_work_package_dialog.png)

The work package appears in the topic, right under the post it was created from, and the header of the topic lists all the work packages created from it. The success message offers a button to view the new work package.

![Work package created from a forum post in OpenProject](openproject_user_guide_forums_work_package_created.png)

In the **Activity** tab of the work package, the first entry links back to the forum post it was created from.

![Activity of a work package created from a forum post in OpenProject](openproject_user_guide_forums_work_package_activity.png)

## Watch a forum

To keep informed about changes in a forum, e.g. new topics or new replies, you can add yourself as a **Watcher** of a forum.

[Open an existing forum](#open-a-forum) from the list and click the **Watch** button in the top right corner of the forum.

You will then be notified via e-mail according to your [e-mail notifications](../../user-guide/notifications/notification-settings) about new topics and replies in this forum.

![Watch a forum in OpenProject](openproject_user_guide_forums_watch.png)

The button will then change to **Unwatch**.

### Watch a topic

If you watch a forum, you automatically watch all of its topics. Alternatively, you can also **watch only certain topics** within a forum. You also automatically watch the topics you start or reply to.

To do so, open the topic and click the **Watch** button in its top right corner.

![Watch a forum topic in OpenProject](openproject_user_guide_forums_watch_topic.png)

## Unwatch a forum

To stop being informed via e-mail about new topics and replies in a forum, click the **Unwatch** button on the top right of the forum.

![Unwatch a forum in OpenProject](openproject_user_guide_forums_unwatch.png)

### Unwatch a topic

The same applies to **unwatch a topic**. Open the topic which you do not want to watch any longer and click the **Unwatch** button.

## Edit a topic or a reply

To **edit a post in a forum**, click the **More** (three dots) icon of the post and select **Edit message**. This works for the opening post of a topic and for each reply.

![Edit a forum topic in OpenProject](openproject_user_guide_forums_edit_topic.png)

Make your changes and click the **Save** button.

## Delete a topic or a reply

To **delete a topic** with all its replies, open it and click the **Delete** button in its top right corner.

![Delete a forum topic in OpenProject](openproject_user_guide_forums_delete_topic.png)

To **delete a single reply**, click the **More** (three dots) icon of the reply and select **Delete**.
