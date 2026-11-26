---
sidebar_navigation:
  title: AI Text assistant
  priority: 900
description: Configure the AI Text Assistant in OpenProject.
keywords: AI, text assistant, writing assistance
---

# AI Text Assistant

[feature: ai_text_assistant ]

The AI Text Assistant offers a variety of actions right where you write tickets or comments. Among other things, these allow you to sort an unstructured block of text into the right work package template, make a message friendlier or summarize a text for you.

## Writing work package templates

The `structure` action allows you to sort a block of text into the work package's underlying template. These templates should follow a few formatting rules:
* Template sections should best be created using the headings.
* Guidance for a section should be italicized text right under the section heading. During the sorting process, guidance for filled out sections will be removed and those that do not have content yet will stay. These guidance lines are used by both users and the AI Text Assistant.

## Writing new actions for the AI Text Assistant

When it comes to writing prompts for new actions, there is no silver bullet. The easiest approach is to write a first prompt to specify your intent. Afterward, have the most capable model which is available to you improve upon your prompt using the following criteria which we used for our own prompt optimization:
* staying faithful to the original content
* using positive statements to describe the finished state
* assuming a medium sized model with reasoning turned off

Staying faithful to the original content being processed is a core requirement of many actions, as we don't want to have hallucinated statements or statements that were removed. The problem becomes more subtle with statements that could be successfully inferred from the existing content. Here you should take a clear stance on what you find acceptable for your new action. Should the action stay strictly limited to the existing facts or should it try to also infer things which can be a great help sometimes but sometimes also get things wrong?

Using positive statements to describe the finished state is a useful prompting technique especially for medium sized models with reasoning turned off. In this scenario, the AI model does not have a lot of time to first create drafts of possible solutions which it then checks against many rules of what to do and what not to do. Instead, it has to generate the result in one go and positive statements define a clear, unambiguous target, giving the model an exact blueprint to follow.

**Examples: Negative vs. Positive Framing**

| Goal | Negative Framing (Weaker) | Positive Framing (Stronger) |
| :--- | :--- | :--- |
| **Formatting** | "Don't use bullet points." | "Write in cohesive, flowing paragraphs." |
| **Tone** | "Don't sound too formal or robotic." | "Use a warm, conversational, and casual tone." |
| **Length** | "Don't write a long essay." | "Summarize the main points in under 100 words." |
