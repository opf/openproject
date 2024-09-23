---
sidebar_navigation:
  title: Wiki FAQ
  priority: 001
description: Frequently asked questions regarding wiki
keywords: wiki faq
---

# Frequently asked questions (FAQ) for wiki

## Is it possible to copy a wiki or a wiki page from one project into another project?

Yes, you can do both, you have to export the wiki or the wiki page as a Markdown (or Atom), than copy the Markdown from the text editor. Now you have to create a new wiki in the project you want to copy the old one (or the page). In the section paragraph you have to change into the markdown modus, then paste the text from you have copied. Unfortunately pictures cannot be copied this way. You have to add them manually.

## Which image formats can be used to include them on a wiki page?

Currently supported are PNG and JPEG.

## Can I include wiki pages in the left menu bar? What does "Configure menu item" mean?

The option configure menu item was designed to ease the handling of page structures.
After the initial creation of the page you can select the function. If you select Do not show this wiki page in project navigation the page will be excluded from the menu.
Otherwise the page will appear in the project navigation and you can select, whether it shall be a subitem of an existing wiki page.

## I created a wiki page but cannot find it anywhere in the menu - how can I access it?

After saving a wiki page, you can create a referencing link for the page to easily access it - either by making it a wiki menu item (s.a.) or by referencing it with a link on the main wiki page. If this chance was missed you can reaccess the page at any time, by typing in the page’s URL in the browser:
The example URL would be: `openproject.org/projects/your-projects-name/wiki/your-wiki-page’s-name`
Also, you have the possibility to display the wiki’s Table of Contents, which you also can activate for each wiki page with “configure menu item” (s.a.). Here you see all wiki pages for the project.

## I activated the wiki module in the project settings but cannot see any wiki in the project menu. What happened?

You have probably unchecked the option “show as menu item in project navigation” within the wiki settings “configure menu item” (s.a.). Type in the URL of any wiki page in the browser: `https://www.openproject.org/projects/“project_name”/wiki` to open the wiki. Open “configure menu item” for this page and choose the way you want this wiki to be displayed in the menu bar.

## What is the markup language of the wiki in OpenProject?

The wiki syntax used in OpenProject is Textile.

## I am not used to Textile - is there any documentation where I can get help?

Next to the field to enter the page content, some of the basic formatting commands are included.
Above you see the commands for text styles, headline options and lists, as well as the command to include an image.
On the right, there is also a help link which displays all commands which can be used for formatting.

## How to create a table of content?

The macro to create a table of content is `{{toc}}`.
