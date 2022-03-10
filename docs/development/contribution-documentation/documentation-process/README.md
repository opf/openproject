---
sidebar_navigation:
  title: Documentation process
  priority: 999
description: The process of how to contribute to the OpenProject documentation
robots: index, follow
keywords: contribution, documentation, documentation process
---

# Documentation process

Proudly open source software, we created our processes in a way that invites anyone to contribute to the OpenProject documentation.

## The documentation process step-by-step

You will find the description for the basic development process in the [GitHub guideline](../../git-workflow/#development-at-github). In the following, you find the detailed information about the process for the documentation.

Please note that you find  the [OpenProject repository on GitHub](https://github.com/opf/openproject).

If you would like to contribute changes to the OpenProject documentation, please follow these steps:

1. [Fork the OpenProject repository](https://www.openproject.org/docs/development/git-workflow/#fork-openproject) and create a local development branch. Include documentation in your branch name.
2. Create your changes in the documentation. It can be found in the folder [docs](https://github.com/opf/openproject/tree/dev/docs). You can work directly in the GitHub markdown files or use e.g. GitHub desktop and a markdown editor like Typora.
   If you are not only changing something in an existing documentation page but are adding a new page, please make sure to add metadata. To provide additional directives and useful information, we add metadata to the beginning of each documentation page. This will give you guidance on what information to provide in the metadata: 
  - Sidebar navigation: You do not have to add anything here. Leave it blank.
  - Title: Site title that will appear in the menu.
  - Priority: You assign a number to your page to indicate in what order it will appear. The higher up you want the section to appear in the menu, the higher the number you assign (any number between 1 and 999). I.e. the section that is appearing first gets the highest number (e.g. 999).
  - Description: description of the content of the page that you are creating. Best is to also include the title name.
  - Robots: always add “index, follow” here.
  - Keywords: use key words to describe the content of the page, minimum two. 
3. [Create a pull request](https://www.openproject.org/docs/development/git-workflow/#create-a-pull-request) on our repository. Make sure you name it accordingly and also include **documentation** in the name.
4. We will evaluate your pull request and changes before we merge it.

If the author or reviewer has any questions, they can use the comments in the pull request.



## Move or rename a page

Moving or renaming a document is the same as changing its location. We want to make sure after renaming or moving a page, the users will still find it. That is why we will need to redirect browsers to the new page. 

Redirects are managed in a repository that is not accessible by the OpenProject community. In case you would like to move or rename a document, please create a ticket so that we can take care of it. Follow these steps to create your ticket:

1. Login to or register at the [OpenProject community platform](https://community.openproject.org/login). It’s fast and free.

2. Check if there is already an existing ticket by using the search bar in the header navigation at the top. If there is one, please leave a comment or add additional information. Otherwise:

3. Open a new [documentation work package]( https://community.openproject.org/projects/openproject/work_packages/new?type=69)

4. Add a precise subject.

5. Add a detailed description which page you want to rename to what or which page you want to move where.

6. Attach a screen-shot (optional).

7. Press **Save**.

