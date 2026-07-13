---
sidebar_navigation:
  title: Documents
  priority: 900
description: Documents module settings in OpenProject.
keywords: document category, document categories, documents, collaboration, category, categories, real-time collaboration, edit document
---
# Documents module settings

This page describes the available settings for the **Documents** module in the OpenProject administration.

## Document types

> [!NOTE]
>
> Prior to OpenProject 17.0 document types were called _categories_ and were configured under _Administration → Files → Categories_.

To create or edit document categories in OpenProject, navigate to _Administration → Documents_. Here, you will automatically see all existing document types:

- The column **Type** lists all existing document type names
- The column **Documents** shows the number of documents of this specific type

You can adjust the items within the list by using the options behind the **More (three dots)** menu on the right side. You can also rearrange the order by using the drag-and-drop handle on the left.

![Document types overview in OpenProject administration](openproject_system_guide_documents_types_overview.png)

### Create new document type

To create a new document type, select the **+ Add** button in the top right corner.

You can then name the new type, and activate it. You can optionally set this type to be the **Default** value.
> [!NOTE]
> Making this type default will override the previous default priority.

Press the **Save** button to save your changes.

![Create new document type in OpenProject](openproject_system_guide_documents_types_new_form.png)

### Edit a document type

To **edit** an existing type, either click on the name directly or select the **Edit** option from the **More (three dots)** menu on the right end of the row.

![Edit a document type in OpenProject administration](openproject_system_guide_documents_types_edit.png)

### Delete a document type

To remove a document type, open the **More (three dots)** menu on the right end of the row and click on the **delete** icon.

![Delete a document type in OpenProject administration](openproject_system_guide_documents_types_delete_button.png)

You will see a dialogue informing you of the consequences.

- If a document type is unused, this has no significant consequences.

  ![A warning message when deleting an unused document type in OpenProject](openproject_system_guide_documents_types_delete_message_type_unused.png)

- If a document type is used, you will need to select a different type for reassigning

  ![A warning message when deleting a used document type in OpenProject, asking to reassigning documents to a different type](openproject_system_guide_documents_types_delete_message_type_used.png)

- If a document type is the last existing one, you will not be able to delete it. There must always be at least one document type configured. In this case you can create another document type first.

  ![A warning message that deleting the last existing document type is not permitted in OpenProject](openproject_system_guide_documents_types_delete_message_type_last.png)

## Real-time collaboration in documents

Real-time collaboration for OpenProject’s **Documents** module was introduced with the 17.0 release. When enabled, it allows multiple users to edit the same document at the same time. Changes are synchronized instantly, and users can see each other’s cursors and edits as they occur. This improves collaboration, especially for teams working on shared documentation or meeting notes.

From a technical perspective, real-time collaboration relies on a running [Hocuspocus server](https://github.com/opf/openproject/tree/dev/extensions/op-blocknote-hocuspocus), which handles synchronization between users. OpenProject connects to this service to provide a seamless collaborative editing experience within documents.

![Administration settings for real-time documents collaboration in OpenProject](openproject_system_guide_documents_real_time_collaboration.png)

> [!IMPORTANT]
>
> Real-time collaboration is available for the following installation types. However, it may require proper configuration before it is fully enabled:
>
> - Containerized installations
> - Cloud-hosted installations
>
> Packaged installations (DEB/RPM) require additional manual setup. This includes installing and configuring a [Hocuspocus server](https://github.com/opf/openproject/tree/dev/extensions/op-blocknote-hocuspocus) to enable real-time collaboration.

### Enable real-time collaboration for packaged installations

#### 1. Install hocuspocus

The easiest way to install hocuspocus is by using the Docker container.
You can do so by using the following steps.

Create a hocuspocus directory:

```shell
mkdir hocuspocus
cd hocuspocus
```

Then you can create a `docker-compose.yml` file with the following content inside the `hocuspocus` directory:

```yaml
services:
  hocuspocus:
    image: <hocuspocus_image>
    restart: unless-stopped
    environment:
      SECRET: "secret123"
    ports:
      - "127.0.0.1:1234:1234"
```

Replace the `<hocuspocus_image>` with the image from [here](https://github.com/opf/openproject-docker-compose/blob/stable/17/docker-compose.yml#L122).

Run hocuspocus:

```shell
docker compose up -d
```

#### 2. Configure Apache

> [!NOTE]
> This part of the docs assumes that you are using the generated Apache config by the OpenProject wizard

Create `/etc/openproject/addons/apache2/custom/vhost/hocuspocus.conf` with the following content:

```apache
ProxyPass        /hocuspocus  ws://127.0.0.1:1234/hocuspocus
ProxyPassReverse /hocuspocus  ws://127.0.0.1:1234/hocuspocus
```

**For Debian/Ubuntu-based systems, run the following commands:**

Enable the `proxy_wstunnel` module:

```shell
sudo a2enmod proxy_wstunnel
```

Restart Apache:

```shell
sudo service apache2 restart
```

**For RHEL/CentOS-based systems, run the following command:**

```shell
sudo  service httpd restart
```

#### 3. Enable real-time collaboration

Manually configure the server URL & secret in the _Documents_ administration settings in OpenProject.
Here you need to provide the URL in the following format: `wss://<your_op_hostname>/hocuspocus`.
If you are using HTTP in your instance, the protocol has to be `ws://` instead of `wss://`.

> [!NOTE]
> The secret must be identical in both op-blocknote-hocuspocus and OpenProject.

![Administration settings for real-time documents collaboration in OpenProject](openproject_system_guide_documents_real_time_collaboration_settings.png)

For more background on this feature, see [this blog article](https://www.openproject.org/blog/real-time-collaboration-in-documents/) on the introduction of real-time collaboration in documents.
