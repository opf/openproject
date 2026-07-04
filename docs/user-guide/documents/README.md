---
sidebar_navigation:
  title: Documents
  priority: 770
description: Create documents and attach files in OpenProject.
keywords: documents
---

# Documents

The Documents module allows you to write or upload documents directly to the project.

> [!NOTE]
> Use the Documents module to create, write, or upload documents directly in your projects. If you need to manage files stored externally, please take a look at the [file storages integrations](../file-management).

> [!IMPORTANT]
>
> With 17.0 release, real-time documents collaboration was introduced. It is automatically available for the following installation types: 
> - Containerized installations
> - Cloud-hosted installations
>
> **Packaged installations (DEB/RPM) require additional manual setup**. Please refer to the [system administration guide for more details](../../system-admin-guide/documents/#real-time-collaboration-in-documents). 

## Document index

To use the Documents module, make sure it is enabled in the Project settings of your project (Project settings → Modules). 

Once it is enabled, you can navigate to the *Documents* module in the sidebar of your project to get to the Documents index that lists all available documents:

![Documents index lists of all available documents in an OpenProject project](openproject_user_guide_real_documents_overview.png)

The Documents index page lets you:

1. View all documents

2. Filter by document type

> [!TIP]
> If no document types were specified by you yet, default document types are seeded. They include: *Note, Idea, Proposal, Specification, Report and Documentation*.

3. Quick-filter the list of documents based on the document title

4. Add a new document

5. View a list of all available documents, including their type and the date they were last edited. Documents created prior to 17.0 release will be marked by *Legacy* label. 

   ![An example of a document marked by a legacy label in OpenProject *Documents* module](openproject-documents-legacy.png)

A document in OpenProject can be:

- a text written directly in the editor of a document
- a file uploaded and attached to a document
- both a file uploaded and attached to a document, with a text note that describes it

## View a document 

To view a document, simply click on the name of a document in the index. You will then see the document:

![Viewing a document with an attachment in OpenProject](openproject_user_guide_documents_module_detailed_view.png)

A document has:

1. A title, a category, number of active editors and last saved date
2. *More* menu with with options to edit, copy link and delete a document
3. The document text itself
4. Attachments

## Add a new document to the project 

To create a new document, click on the *+ Document* button. 

![Create a new document in OpenProject Documents module](openproject_user_guide_documents_create_new.png)

In the form that appears, select the document category, give it a title and an optional description. You can optionally also attach a file to the document.

Please note that that these document categories are created by the administrator of your instance.

The uploaded documents are visible to all project members who have the necessary permissions.

> [!NOTE]
> There is no versioning of documents. An edit of any field or the contents of the document is visible to all members.

## Edit a project document 

You can edit a document anytime. 

To edit a document title, click on the *More (three dots)* menu and select *Edit title*. 

![Edit a document title in OpenProject Documents module](openproject_user_guide_documents_edit_title.png)

To edit the document itself simply click anywhere in the document and you can directly start editing. Simply start entering text or use **/** to add headings, blocks, media elements, emojis and link to work packages. 

![Edit a document in OpenProject Documents module](openproject_user_guide_documents_module_add_heading.png)

### Collaborative editing

Multiple project members can edit a document at the same time. If they do, you will see what changes are made by which user in real time.

Take a look at this example for an illustration. 

![An example of real-time document editing in OpenProject Documents module](openproject_user_guide_real_time_collaboration_example.gif)

### Link work packages to documents

You can link existing work packages to a document in two ways:

1. **Using the slash menu**

Start editing a document, type **/** to open the slash menu, then select **Link to existing work package** from the list of available options.

![Link a document to an existing work package in OpenProject](openproject_user_guide_documents_module_add_work_package.png)

Enter the work package ID or subject and it will automatically be linked, as shown below:

![Document linked to an existing work package in OpenProject](openproject_user_guide_documents_module_add_linked_work_package.png)

> [!NOTE]
> The work package is displayed as a full-width card only when it is linked using a slash command on an empty line.

2. **Using inline work package links**

You can also link work packages directly within a line of text or a paragraph. Type **#**, **##**, or **###**, followed by a work package ID or part of the subject. Matching work packages will be suggested automatically.

![Example of linking a work package inline in OpenProject documents module](openproject_user_guide_documents_link_wp_inline.png)

The amount of work package information shown depends on the display format used:

- **#** displays the work package identifier.
- **##** displays the work package type, identifier, and subject.
- **###** displays the work package status, type, identifier, and subject.

![Work package linked three times inline in OpenProject documents module, showing different amounts of information depending on how many hashtags are used](openproject_user_guide_documents_link_wp_inline_examples.png) 

Inline work package links behave like regular links and can be placed naturally within a paragraph, without adding a line break. Alternatively, work packages can be displayed as separate block-style cards.

Click the work package title to open it in a new browser tab. To change the display style of the linked work package, click the work package ID on the left to open the context menu. You can choose one of the available display options: **Tiny**, **Compact**, **Regular**, or **Compact card**.

![Context menu to change display options for a linked work package in OpenProject Documents module](openproject_user_guide_documents_link_wp_inline_menu.png)


## Delete a project document

You can easily delete a document in OpenProject. 

To delete a document, click on the *More (three dots)* menu and select *Delete*. 

![Delete a document in OpenProject Documents module](openproject_user_guide_documents_delete.png)

## Frequently asked questions (FAQ)

### Why can't I edit documents in real-time?

Real-time document collaboration is available in OpenProject starting with version 17.0, but whether you can use it depends on how your OpenProject instance is set up. In cloud-hosted and containerized setups, real-time editing is enabled by default. For packaged installations (DEB/RPM), additional configuration is necessary. Please contact your OpenProject administrator and/or refer to the [system administration guide for more details](../../system-admin-guide/documents/#real-time-collaboration-in-documents). 

### Is there a size limit for uploading documents to the OpenProject Enterprise cloud edition?

There is no limit in OpenProject in terms of the number of files that you can upload and work with in OpenProject. There is only a restriction in terms of the maximum file size: A file can have a size up to 256 MB.

