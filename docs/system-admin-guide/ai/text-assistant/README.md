---
sidebar_navigation:
  title: Text assistant
  priority: 900
description: Configure the AI Text Assistant in OpenProject.
keywords: AI, text assistant, writing assistance
---

# Text assistant

[feature: text_assistant ]

The AI Text Assistant offers a variety of actions right where you write tickets or comments. Among other things, these allow you to sort an unstructured block of text into the right work package template, make a message friendlier or summarize a text for you.

## Writing ticket templates

The `structure` action allows you to sort a block of text into the work package's underlying template. These templates should follow a few formatting rules:
* Template sections should best be created using the headings.
* Guidance for a section should be italicized text right under the section heading. During the sorting process, guidance for filled out sections will be removed and those that do not have content yet will stay. These guidance lines are used by both users and the AI assistant

## Writing prompts for ai text actions

When it comes to writing prompts, there is no easy answer. We have optimized our prompts on a set of work packages against a number of goals such as 
* staying faithful to the original content
* using positive declarative statements to describe the finished state
* assuming a medium sized model with reasoning turned off

The easiest approach we can offer is to write a first prompt to specify your intent and then have the most capable model which is available to you improve upon your prompt with these criteria as guidance.




