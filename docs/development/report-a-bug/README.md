# Report a bug

If you find a bug please create a bug report.

1. Login to the [OpenProject developer platform](https://community.openproject.com/login).
2. Open the [bug form](https://community.openproject.com/projects/openproject/work_packages/new?type=1).
3. Add a precise subject.
3. Add a detailed description.
4. Attach a file (optional).
5. Press Create.


# Information you should add to the bug description

## Preconditions to reproduce the bug

Prior to detailing which steps to take to reproduce the error, the necessary preconditions which have to be met should be stated.
* Which browser did you use when you experienced the error?
* Do you receive any error messages in the browser console when the error occurs? Please include the error message if applicable.
* Please also include the contents of the browser's developer tool's network tab where applicable.
* If you are self-hosting please include logs from `sudo openproject logs` gathered while you are reproducing the error.

Example:

```
* Forum exists
* Forum messages exist with many replies
```

## Steps to reproduce the bug

* The steps that led to the bug should be listed in the description in order to replicate the bug and determine the underlying problem.

Example:

```
1. Go to forum
2. Scroll to bottom of messages
```

## Actual behavior

* The actual, erroneous behavior should be stated briefly and concisely.

Example:

```
* Not possible to switch to next entry in pagination
```

## Expected behavior

* If known, the expected behavior of the application should be described concisely.

Example:

```
* Possible to switch to next pagination page
```

## Screenshots

* If applicable, a screenshot should be added to the bug report in order to explain the bug visually.
  * The unintended behavior should be marked in the screenshot (e.g. by using red color).
* The screenshot can be attached as a file and can be integrated in the description with the following syntax: "!Name_of_screenshot.png!" (without quotation marks)
(Notice: *Name_of_screenshot* should be replaced with the respective name of the file. The file ending (here: *.png*) has to be adjusted to the appropriate file type of the screenshot.)

## Example of bug reporting

![Report a bug: Bug example](https://openproject.org/wp-content/uploads/2014/09/Forum-bug1.png "Report a bug: Bug example")
