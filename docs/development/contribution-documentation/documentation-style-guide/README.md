---
sidebar_navigation:
  title: Documentation style guide
  priority: 996
description: 
robots: index, follow
keywords: documentation style guide, style guide, 
---

# Documentation Style Guide

This document defines the standards for the OpenProject documentation, including grammar, formatting, wording and more.



## Markdown

All OpenProject documentation is written in Markdown. Feel free to either work directly in the Markdown files or to use [GitHub desktop](https://desktop.github.com) with a markdown editor like [Typora](https://typora.io) or others.



## Structure

The OpenProject documentation is divided into the top level folders:

- Guides: getting started guide, user guide, system admin guide, Enterprise edition guide, installation and operation guide. Thereby each guide is available at top level on its own.
- FAQs
- Release notes
- Development
- API

Within each folder there is a sub-hierarchy of topics. E.g. in the Getting started guide you find amongst others the Introduction to OpenProject and Sign in and registration as sub-topics. Sub-topics are individual documentation pages in GitHub. You will notice the sub-topics in the documentation menu on the left when unfolding each folder's menu.

![OpenProject_documentation_menu](OpenProject_documentation_menu.png)



### Folder structure overview

We aim to have a clear hierarchical structure with meaningful URLs like https://www.openproject.org/docs/getting-started/sign-in-registration/. With this structure you can identify straight away that this part of the documentation is about the sign in and registration process. At the same time, the website path matches our repository, making it easy to update the documentation.

Find an overview of content per folder here:

| **Directory**                                                | **Contents**                                                 |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Getting started guide](https://www.openproject.org/docs/getting-started/) | Here you will learn about the first steps with OpenProject. It is a short introduction on registration,  sign up, inviting members, starting to set up a project and the most important  features work packages, Gantt charts and agile boards. |
| [User guide](https://www.openproject.org/docs/user-guide/)   | This guide covers the details of all features and  functionalities found in OpenProject. |
| [System admin guide](https://www.openproject.org/docs/system-admin-guide/) | Documentation on how to  make changes to settings affecting your entire OpenProject environment. This  is relevant for users with administrator rights for the configuration of all  modules but also overall, e.g. regarding system settings, authentication or user  permissions. |
| [Enterprise guide](https://www.openproject.org/docs/enterprise-guide/) | Here you will find all about the management and  administration of your Enterprise cloud and Enterprise on-premises  subscription. |
| [FAQs](https://www.openproject.org/docs/faq/)                | This is  the central overview of frequently asked questions for OpenProject. |
| [Installation and operations guide](https://www.openproject.org/docs/installation-and-operations/) | This guide summarizes the options for getting  OpenProject, either hosted or on-premises and what to do if you want to  include BIM features in your application. For the on-premises versions you  will find all operation and installation instructions. |
| [Release notes](https://www.openproject.org/docs/release-notes/) | OpenProject is regularly upgraded with new features, security updates  and more. The release notes inform you about the news in each release. |
| [Development](https://www.openproject.org/docs/development/) | This guide details how to contribute to the code of  the OpenProject application. |
| [API](https://www.openproject.org/docs/api/)                 | This part of the documentation deals with the API specification, what endpoints  and functionality are available. |

 

## Work with directories and files

Please respect the following when working with directories and files:

1. When you create a new topic, i.e. a new documentation page, always create a new folder and a new `README.md` file in that folder.
2. Do not use special characters and spaces, or capital letters in file names, directory names, branch names and anything that generates a path.

3. When creating a file or directory and it has more than one word in its name, use underscores (`_`) instead of spaces or dashes. For example use [open_details-view_work_packages.png](https://github.com/opf/openproject/blob/dev/docs/getting-started/work-packages-introduction/open-details-view-work-packages.png). This applies to both image files and Markdown files.

1. For image files, do not exceed 100KB.

If you are unsure where to place a document or a content addition, this should not stop you from authoring and contributing. Use your best judgment, and then add a comment to your pull request.

 

## Avoid duplication

Do not include the same information in multiple places. Instead, link through to the information in the documentation where it is already mentioned so that there is only a single source of truth that needs to be maintained.

 

## References across documents

- When making reference to other OpenProject modules or features, link to their respective documentation, at least on first mention. 
- Please see under links how to use links within the documentation.

- When making reference to third-party products or technologies, link out to their external sites,     documentation and resources.

  

## Structure in documents

- Structure content in tables or lists etc. in alphabetical order unless there is a reason to use an order of importance. 

  

## Language

The OpenProject documentation should be as clear and easy to understand as possible. Avoid unnecessary words.

- Be clear and concise with as little words as possible.

- Write in US English with US grammar.  

  

## Capitalization

### Headings

Use sentences that describe the content and capitalize the first letter in the sentence. For example:

`# Create an OpenProject trial installation

`## Start a new trial installation



### UI text

When referring to specific user interface text, like a button label or menu item, use the name as in the application and start the word with a capital letter. Moreover, please make it make it bold. Example: **Start Free Trial** button.



### Feature names

- Feature names are typically capitalized and in bold. For example:

- - **Gantt chart**

  - **Roadmap**

  - **Project overview**

  - **News**      

  - **Wiki**

    

#### Other terms

Capitalize names of:

- OpenProject products: OpenProject Community edition, OpenProject Enterprise on-premises edition, OpenProject Enterprise cloud edition
- Third-party organizations, software, and products. For example Microsoft, Nextcloud, The Linux Foundation etc.

Follow the capitalization style by the third party which may use non-standard case styles. For example: OpenProject, GitHub.



## Placeholder 

### Fake user information

You may need to include user information in entries. Do not use real user information or email addresses in the OpenProject documentation. For email addresses and names, do use:

- Email address: Use an email address ending in @example.com.

- Names: Use strings like example_username. Alternatively, use diverse or non-gendered names with common surnames, such as Avery Smith.

- Screenshots: When inserting screenshots in the documentation, make sure you are not giving away your identity by using your actual avatar. Rather create a fake user name and avatar.

  

### Fake URLs

When including sample URLs in the documentation, use example.com when the domain name is generic.



### Fake tokens

There may be times where a token is needed to demonstrate an API call. It is strongly advised not to use real tokens in documentation even if the probability of a token being exploited is low.

You can use this fake token as example: 12345678910ABCDE



### Placeholder command

You might want to provide a command or configuration that uses specific values.

In these cases, use `<` customize `>` to call out where a reader must replace text with their own value.

For example:

```
cp <your_source_directory> <your_destination_directory>
```



## Contractions

Please do not use any contractions like don’t or isn’t.



## Copy

### Punctuation

Follow these guidelines for punctuation:

- Avoid semicolons. Use two sentences instead.

- Always add a space before and after dashes when using it in a sentence (for replacing a comma, for example).

- Do not use double spaces.

- When a colon is part of a sentence, always use lowercase after the colon.



### Spaces between words

Use only standard spaces between words so that the search engine can find individual search terms.



## Lists

- Always start list items with a capital letter.

  

### Ordered and unordered lists

Only use ordered lists when their items describe a sequence of steps to follow.

Example for an ordered list:

Follow these steps:

1. Do this

2. Then do that

3. And then finish off with something else.

 

Example for an unordered list: 

- Feature 1

- Feature 2

- Feature 3

  

### Markup

- Use dashes (`-`) for unordered lists.

  

### Punctuation

- Do not add commas (`,`) or semicolons (`;`) to the ends of list items.
- Separate list items from explanatory text with a colon (`:`). For example:
  		- Feature 1: very attractive new feature
  		- Feature 2: description of an additional feature

 

## Tables

Tables should be used to describe complex information in a straightforward manner. Note that in many cases, an unordered list is sufficient to describe a list of items with a single, simple description per item. But, if you have data that’s best described by a matrix, tables are the best choice.

 

### Creation guidelines

To keep tables accessible and scannable, tables should not have any empty cells. If there is no otherwise meaningful value for a cell, consider entering N/A (for ‘not applicable’) or none.

To help tables be easier to maintain, consider adding additional spaces to the column widths to make them consistent. For example:

| Feature  	       | Description                                      										       |

| --------------------- | :-----------------------------------------------------------------------------------  |

| Great feature   | Enhances collaboration between marketing and sales          | 

| Best feature     | Use it to synchronize your example table with OpenProject | 

 

## Headings

- Add only one H1 in each documentation page, by adding # at the beginning of ithe headline (when using Markdown).

- Start with an H2 (##)  and respect the order H2 > H3. Never skip the hierarchy level, such as H3 > H2. Do not go lower in the hierarchy than H3 (###).

- Do not use symbols and special characters in headings. 

- When possible, avoid including words that might change in the future. Changing a heading changes its anchor URL, which affects other pages that link to this headline.

- Leave exactly one blank line before and after a heading.

- Do not use links in headings.

- Make your subheading titles clear, descriptive, and complete to help users find the right example.

- See Capitalization for guidelines on capitalizing headings.

  

### Heading titles

Keep heading titles clear and direct. Make every word count. Where possible, use the imperative. Example: Sign in with an existing account (**not** Signing in with an existing account).



### Anchor links

Headings generate anchor links when rendered. ##This is an example generates the anchor #this-is-an-example.

Keep in mind that there are various links to OpenProject documentation pages and anchor links on the internet to take the users to the right spot. Thus, please avoid changing headings.



## Links

Links are important in the documentation. Use links instead of duplicating content to help preserve a single source of truth in the OpenProject documentation.



### Basic link criteria

- Use inline link Markdown markup `[Description](https://example.com)`. It is easier to read, review, and maintain.

- Use meaningful anchor text descriptions. For example, instead of writing something like `Read more about Gantt charts [here](LINK)`, write `Read more about [Gantt charts](LINK)`.



### Links to internal documentation

Internal links are links within the OpenProject website which includes the OpenProject documentation. In these cases, use relative links. I.e. do not use the full URL of the linked page but instead show the current URL's relation to the linked page's URL. 

To link to internal documentation:

- Use relative links to Markdown files in the same repository.
- Use ../ to navigate to higher-level directories.



### Links to external documentation

When linking to external information, you have to use absolute URLs. Make sure that you are only linking to an authoritative source, i.e. official and credible sources written by the people who created the item or product. These sources are the most likely to be accurate and remain up to date.

 

## Navigation

When documenting navigation through the OpenProject application, use these terms and styles.



### Menus

Use these terms when referring to OpenProject’s main application elements:

- **Header menu**: This is the blue bar at the top that spans the width of the application. It includes the OpenProject logo, the search field, the link to all projects, the short menu, the help icon and the user’s avatar.

- **Project menu**: This is the black menu on the left in the OpenProject application that displays the modules.

  

### How to document the menus

To be consistent, use this format when you write about UI navigation.

1. In the header menu, click on your **Avatar > Administration** to find system settings.

2. In the project menu, select **Work packages** to open your work package list.

   

## Images

Images, including screenshots, can help a reader better understand a guide. However, they can be hard to maintain with software updates being released, and should be used sparingly.

Before including an image in the documentation, ensure it provides value to the reader.



### Capture the image

Use images to help the reader understand where they are in a process, or how they need to interact with the application.

When you take screenshots:

- Capture the most relevant area of the page: Do not include unnecessary white space or areas of the page that don’t help illustrate the point. The project menu on the left of the OpenProject application can change, so don’t include it unless it is necessary.

- Be consistent: Coordinate screenshots with the other screenshots already on a documentation page. For example, if other screenshots include the left sidebar, include the sidebar in all screenshots.

  

### Save the image

- Save the image with a lower case file name that is descriptive of the feature or concept in the image. 

- Place your images in the same directory where the `.md` document that you are working on is located.

- Compress GIFs.

- Max image size: 100KB (GIFs included).

  

### Add the image link to content

The Markdown code for including an image in a document is: `![Image description which will be the alt tag](img/document_image_title_vX_Y.png)`

The image description is the alt text for the rendered image on the documentation page. For accessibility and SEO, use descriptions that are descriptive and precise.



## Videos

At the moment it is not possible for external contributors to upload videos to the documentation. Please open a ticket .



## Alert boxes

Use alert boxes to call attention to information. The alert boxes in the OpenProject documentation have a specific format. Please use the following to be consistent:

<div class="alert alert-info" role="alert">

**Note**: This is where your description goes.

</div>

