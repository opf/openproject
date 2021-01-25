---
sidebar_navigation:
  title: FAQ
  priority: 001
description: Frequently asked questions regarding incoming emails
robots: index, follow
keywords: incoming emails FAQ, inbound emails, send to OpenProject
---

# Frequently asked questions (FAQ) for incoming emails

## What is the correct email address to send inbound emails to for the Enterprise cloud? And what should they look like?

The email address notifications@openproject.com is generally used for the OpenProject Cloud Edition. However, to distinguish between different OpenProject instances, each instance receives a unique token which becomes part of the email address. This email address has the format “notifications+6c1934deae3242...@openproject.com”.
You can find out the correct email address by opening an email which you have received from your OpenProject instance (e.g. an email for a work package update). To test the inbound email function you could answer such an email about a work package update and add a message. This message is processed regularly (every 10 minutes) by a background job and the respective work package will be updated. Your message will be added as a comment to the work package.

If you would like to create a new work package via email you can send the email to the respective email address of your OpenProject instance (which you can take from a work package update email). We recommend to save this email address for future use.
It is important to include all essential information in your email which are necessary to create a work package. On the one hand, this includes the title (set via the subject line of the e-mail), on the other hand, information such as the project in which the work package is to be created, the type, the status and, if applicable, other mandatory fields must be listed in the description. Examples of formatting can be found in the documentation: https://docs.openproject.org/installation-and-operations/configuration/incoming-emails/#format-of-the-emails.
An e-mail could therefore look roughly like this:
Addressee: notifications+6c1c6896e0d63aec8f47c76c390d802dd94b22794dfdd6588c84355a3140167@openproject.com (here you would have to enter the e-mail address of your OpenProject instance)
Subject: Test e-mail
E-mail content: 
Project: test_project (Note: This is the identifier of your project (e.g. found in the project configuration))
type: Milestone 
Status: new.
** This is the description text. **

You can also send files, which will then be attached to the work package.

Find out more about how to format the emails [here](https://docs.openproject.org/installation-and-operations/configuration/incoming-emails/#format-of-the-emails).