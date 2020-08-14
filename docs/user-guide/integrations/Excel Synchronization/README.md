---
sidebar_navigation:
  title: Excel synchronization
  priority: 599
description: Excel synchronization with OpenProject
robots: index, follow
keywords: Excel
---
# Excel synchronization with OpenProject

## Video tutorials

### Download and upload

See how to set up the synchronization between OpenProject work packages and MS Excel.

<iframe width="560" height="315" src="https://www.youtube.com/embed/ZPK-l-e-lKI" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Synchronize custom queries (views)

See how to synchronize custom work package queries from OpenProject in MS Excel.

<iframe width="560" height="315" src="https://www.youtube.com/embed/86X334cg808" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Synchronize hierarchies

See how to synchronize work package hierarchies in OpenProject with MS Excel.

<iframe width="560" height="315" src="https://www.youtube.com/embed/17yqO0uXE5k" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>


## Step-by-step guide

### Setting-up the Excel list

1. In order to upload your tasks from an existing Excel list to OpenProject, you need to go to [OpenProjectExcel on GitHub.](https://github.com/opf/OpenProjectExcel)

2. Click on the green **Clone or download** button.

3. Choose the option **Download ZIP**.

   ![Download-Excel](Download-Excel.png)

4. Then, you need to extract the ZIP file and open the **OpenProjectAPI** Excel document.

![Open-Excel-900x479@2x](Open-Excel-900x479@2x-1594297430589.png)

5. Next, within the Excel document you are asked to **Enable Editing.**

6. Enable **Content** to activate macros within your document.

![Enable-content-and-macros](Enable-content-and-macros-1594297486714.png)



7. Enter settings (URL and API-Token) and choose a project (and  optional a work package query) which you want to synchronize your data  with.

![Choose-project-900x479@2x](Choose-project-900x479@2x.png)



**URL**: the URL of your OpenProject instance.
 **API-Token**: can be generated within your OpenProject installation ->*My Account* -> *Access token*. Generate a new API token and copy & paste it to this form.
 **Project**: this is the project identifier which can be found within the project you want to synchronize -> *Project settings* -> *Information*. It is also shown in the URL if you open a project.
 Query ID (this field is optional): enter the ID of a work package query  within a project with that you want to synchronize your Excel list.

8. Set as default: enable to remember the settings as default.

9. Accept to start the synchronization.

10. You need to select a minimum of columns to start with the  synchronization. For column selection, click in the header and open the  drop down which opens next to the regular drop down icon: Select the  following column headers at a minimum:
     **Updatestatus**
     **Lock Version**
     **ID**
     **Subject**

Additionally, you can select as many other columns that should be  synchronized – always by clicking in the header and selecting the drop  down icon which appears next to the regular icon. You will have all  fields available, incl. custom fields.

**Important**: make sure you have all fields that need to be synchronized from your Excel list also available in OpenProject. **Some might be [created beforehand as custom fields](https://docs.openproject.org/system-admin-guide/custom-fields/) in OpenProject.**
 Attributes that do not exist in the selected project within OpenProject  are NOT available in the headline. They cannot be selected in the header (via the drop-down). Neither can you just create a new column with an  attribute that does not exist in OpenProject. This will generate an  error message.

Copy and paste all data accordingly from your existing Excel list to this sheet.

![Select-columns](Select-columns.png)



11. Important: **Ctrl + B** will open the synchronization module to choose between the following options:

![Ctrl-B](Ctrl-B.png)



**Download workpackages**: intitially downloads all work packages from the selected project (and query).
 **Upload / update work packages**: makes changes to the  work packges, e.g. adding new work packages or changing any information. This option needs to be chosen in order to initially import and  existing Excel list.
 **Show chosen project**: Opens the settings to adapt URL, API key, project or query ID.

Congratulations! You can now synchronize your data between Excel and OpenProject.

![Excel-OpenProject-synch-900x630@2x](Excel-OpenProject-synch-900x630@2x.png)



12. To synchronize hierarchies (Parent and child relations), insert the column **Parent** within the header of the Excel Sheet as described above (screen 10).

To add or edit a new parent-child relation, you have two possibilites:

**A)** You can add a child to a work package when you  enter 4 empty spaces (press 4x Shift) before typing the subject of the  child work package.

![insert-children](https://1t1rycb9er64f1pgy2iuseow-wpengine.netdna-ssl.com/wp-content/uploads/2019/01/Insert-children-1024x605.png)

**Expert tip**: it does not have to be empty spaces  (default 4 empty spaces) to separate the next hierarchy. You can also  take a „-“ and for the next hierarchy „—“. But the disadvantage is that  the hyphen will also be displayed in the work package subject. Therefore we recommend the spaces, because they will not appear in OpenProject.

13. Pressing **Ctrl + B** and selecting **Upload / update work packages** will open a window to define a new character for setting a parent-child-relationship (default is 4 empty spaces).

Click *OK* when the screen for the Search characters (screen 13) appears. The IDs in the *Parent* column will then be automatically updated.

![Search-character-parent](Search-character-parent.png)



Pressing **Cancel** will ignore the Hierarchy – no matter what has been inserted. This is relevant for option B:

**B)** you can edit the IDs in the parent column manually. If you have edited the IDs manually in the parent column, just click *Cancel* when the above Search character option (screen 13) appears. Then, the  hierarchy will be updated according to the IDs in the column *Parent*.

14. The parent-child-relation will be displayed in OpenProject.

![Parent-child-OpenProject](Parent-child-OpenProject.png)



Hopefully, this will save you lots of time to import all your old  Excel To-Do lists and get started with OpenProject for project  management.