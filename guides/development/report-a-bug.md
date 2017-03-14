# Report a bug

## How to report a bug?

1. Follow the link below to create a new work package.
2. Set Type to "Bug".
3. Add a detailed Description.
4. Attach a File (optional).
5. Choose Priority (Standard: normal).
6. Set Version to "Bug Backlog".
7. Set Module to the module in OpenProject affected by the bug (e.g. Work packages).
8. Set Bug found in Version to the OpenProject version in which the bug occurs (e.g. 4.0.0).
9. Set Non Functional Aspects to the area which is impacted (e.g. Design).
10. Press Create.
11. Note: Consider the Bug Reporting Guidelines below.

Follow [this link to report a bug](https://community.openproject.com/projects/openproject/work_packages/new).

## Bug Report Guidelines   

### Bug title

* The title of the bug should be as concise and crisp as possible.
* The respective module is specified in brackets in front of the title (optional).

Example:
```
[Forum] Pagination in forums is not working properly
```

### Bug description

* The bug description should be concise and expressive.
* In addition to the description, there should be additional information on the occurence of the error:
  * When did the bug occur? (Example: The bug occured on October, 7th 2013 at 11:34 am)
  * Which browser did you use when you experienced the error?
    * The bug should be tested across multiple browsers in order to determine whether the error is browser-specific.
    * Name the browser version in which the error occurred. (Example: Firefox 24.0)
  * Do you use any plugins? Please provide a list of plugins used (ideally the content of your Gemfile.plugins).
  * Do you receive any error messages in the rails console or browser console when the error occurs? Please include the error message if applicable.

### Preconditions to reproduce the bug

* Prior to detailing which steps to take to reproduce the error, the necessary preconditions which have to be met should be stated.

Example:

```
* Forum exists
* Forum messages exist with many replies
```

### Steps to reproduce the bug

* The steps that led to the bug should be listed in the description in order to replicate the bug and determine the underlying problem.

Example:

```
1. Go to forum
2. Scroll to bottom of messages
```

### Actual behavior

* The actual, erroneous behavior should be stated briefly and concisely.

Example:

```
* Not possible to switch to next entry in pagination
```

### Expected behavior

* If known, the expected behavior of the application should be described concicesly.

Example:

```
* Possible to switch to next pagination page
```

### Screenshots

* If applicable, a screenshot should be added to the bug report in order to explain the bug visually.
  * The unintended behavior should be marked in the screenshot (e.g. by using red color).
* The screenshot can be attached as a file and can be integrated in the description with the following syntax: "!Name_of_screenshot.png!" (without quotation marks)
(Notice: *Name_of_screenshot* should be replaced with the respective name of the file. The file ending (here: *.png*) has to be adjusted to the appropriate file type of the screenshot.)

## Example of bug reporting

![Report a bug: Bug example](http://openproject.org/wp-content/uploads/2014/09/Forum-bug1.png "Report a bug: Bug example")
