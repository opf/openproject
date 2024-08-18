---
sidebar_navigation:
  title: Translate OpenProject
  priority: 985
description: How to translate OpenProject to your language
keywords: translation, translate, crowdin, localization
---

# Help translate OpenProject to your language

## OpenProject translations with CrowdIn

OpenProject is available in more than 30 languages.
Get an overview of the translation process and join us in translating OpenProject to your language.

In order to translate OpenProject, we use [CrowdIn](https://crowdin.com/projects/opf) as a platform where contributors can provide translations for a large number of languages.

We highly appreciate the help of anyone who wants to translate OpenProject to additional languages.
In order to provide translations not only for the OpenProject core but also for the plugins, we created several translation projects on CrowdIn:

* [Translate OpenProject](https://crowdin.com/project/openproject)

To help us translate OpenProject, please follow the links above and follow the instructions below.

## How the translation process works

When a new OpenProject version is developed it typically contains new English text (strings).
CrowdIn facilitates the translation of those strings to different languages.
Here is how the translation process works in detail:

![Translation process via GitHub and CrowdIn in detail](GitHub-CrowdIn-OP.png "Translation process via GitHub and CrowdIn in detail")

1. When a new OpenProject version is developed which contains new English words (strings) (on GitHub) the new strings are copied to the CrowdIn projects for the core and the plugins via a GitHub Action.
2. Once the strings have been copied, they can be translated, voted on and approved via CrowdIn. Afterwards, these translations are copied to GitHub via the OpenProject CI and included in the release branch.
3. When the new OpenProject version is released users can use the translations in their own instances with the next OpenProject version.

## How to translate OpenProject via CrowdIn

You can easily help translate OpenProject by creating a (free) CrowdIn account and by joining the [OpenProject CrowdIn project](https://crowdin.com/projects/opf).
Once you joined the project, you can provide translations by following these steps:

Select the language for which you want to contribute (or vote for) a translation (below the language you can see the progress of the translation).
![Language overview in OpenProject CrowdIn project](crowdin-overview.png "Language overview in OpenProject CrowdIn project")

You will be shown an overview of translatable files in the `dev`  and `release` channel. In the below example, the norwegian project is about 33% translated. Simply click the "Translate All" button to show an editor with all untranslated strings.

![Select OpenProject version to translate in CrowdIn](crowdin-language-overview.png "Language overview of translatable files")

![crowdin-editor](crowdin-editor.png "The crowdin editor view")

On the left hand side (1), strings ordered by translation status will be shown on the left. You can search for specific strings above that list, and also change the filters. The red square next to an English string shows that a string has not been translated yet. To provide a translation, select a string on the left side, provide a translation in the target language (2) in the text box in the right side and press the save button.

Some strings might have pluralization rules, in which case there is a tab that you can enter each value.

![crowdin-multi-translation](crowdin-multi-translation.png "A translation string with pluralization rules")

As soon as a translation has been provided by another user (green square next to string), you can also vote on a translation provided by another user. The translation with the most votes is used unless a different translation has been approved by a proofreader.

Once a translation has been provided, a proof reader can approve the translation and mark it for use in OpenProject.

## Becoming a proof reader

If you are interested in becoming a proof reader, please contact one of the project managers in the OpenProject CrowdIn project or send us an email at support@openproject.org.

If your language is not listed in the list of CrowdIn languages, please contact our project managers or send us an email so we can add your language.

Find out more about our development concepts regarding translations [here](../concepts/translations).
