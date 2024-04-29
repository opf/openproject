# Accessibility checklist

For every new OpenProject release we need to ensure accessibility for all newly developed features. We strive to comply to the [Web Content Accessibility Guidelines (WCAG) 2.1](https://www.w3.org/TR/WCAG21/).

> Web Content Accessibility Guidelines (WCAG) 2.1 covers a wide range of recommendations for making Web content more accessible. Following these guidelines will make content more accessible to a wider range of people with disabilities, including accommodations for blindness and low vision, deafness and hearing loss, limited movement, speech disabilities, photosensitivity, and combinations of these, and some accommodation for learning disabilities and cognitive limitations; but will not address every user need for people with these disabilities. These guidelines address accessibility of web content on desktops, laptops, tablets, and mobile devices. Following these guidelines will also often make Web content more usable to users in general.

To help development teams prioritize accessibility implementation and remediation efforts we strive for Level AA (indicates overall accessibility and removal of significant barriers to accessing content).

## 1. Perceivable - Using senses for web content (sight, hearing and/or touch)

### 1.1. Graphics

* All images, form image buttons, and image map hot spots have appropriate, equivalent alternative text.
  * Every image must have an alt attribute.
* Images that do not convey content, are decorative, or contain content that is already conveyed in text are given null alt text (alt="") or implemented as CSS backgrounds. All linked images have descriptive alternative text.
* Background images do not contain information (e.g. text displayed in image (without label))
* Form buttons have a descriptive value.
* Form inputs have associated text labels.
* When audio information is used, a text alternative is supplied
* When video information is used, an audio description / alternative text is supplied

### 1.2. Relations / Context

* The reading and navigation order (determined by code order) is logical and intuitive.
* Instructions do not rely upon shape, size, or visual location (e.g., "Click the square icon to continue" or "Instructions are in the right-hand column").
* Color is not used as the sole method of conveying content or distinguishing visual elements.
* The contrast is sufficient
  * Text and images of text have a contrast ratio of at least 7:1.
  * Large text (over 18 point or 14 point bold) has a contrast ratio of at least 4.5:1
* The page is readable and functional when the text size is doubled.
* If the same visual presentation can be made using text alone, an image is not used to present that text.

## 2. Operable - Interface forms, controls, and navigation are operable

### 2.1. Keyboard usability

* All page functionality is available using the keyboard, unless the functionality cannot be accomplished in any known way using a keyboard (e.g., free hand drawing).
* Page-specified shortcut keys and access keys (access key should typically be avoided) do not conflict with existing browser and screen reader shortcuts.
* Keyboard focus is never locked or trapped at one particular page element. The user can navigate to and from all navigable page elements using only a keyboard.
* All page functionality is available using the keyboard.

### 2.2. Enough time

* If a page or application has a time limit, the user is given options to turn off, adjust, or extend that time limit.
* The content and functionality has no time limits or constraints.
* If an authentication session expires, the user can re-authenticate and continue the activity without losing any data from the current page.

### 2.3. Navigation

* The web page has a descriptive and informative page title.
* The navigation order of links, form elements, etc. is logical and intuitive.
* Page headings and labels for form and interactive controls are informative.
* Text fields and labels are connected.
* It is visually apparent which page element has the current keyboard focus (i.e., as you tab through the page, you can see where you are).
* Layout tables do not contain any table markup.
* If a web page is part of a sequence of pages or within a complex site structure, an indication of the current page location is provided, for example, through breadcrumbs or specifying the current step in a sequence (e.g., "Step 2 of 5 - Shipping Address").
* The purpose of each link (or form image button or image map hotspot) can be determined from the link text alone, or from the link text and its context (e.g., surrounding paragraph, list item, table cell, or table headers).

## 3. Understandable - Content and interface are understandable

### 3.1. Texts

* The language of the page is identified using the HTML lang attribute (`<html lang="en">`, for example).
* Words that may be ambiguous, unknown, or used in a very specific way are defined through adjacent text, a definition list, a glossary, or other suitable method.

### 3.2. Predictable

* When a page element receives focus, it does not result in a substantial change to the page, the spawning of a pop-up window, an additional change of keyboard focus, or any other change that could confuse or disorient the user.
* Navigation links that are repeated on web pages do not change order when navigating through the site.

### 3.3. Errors and help

* Required form elements or form elements that require a specific format, value, or length provide this information within the element's label.
* Required fields are clearly marked.
* Help and documents are available.

## 4. Robust - Content can be used reliably by a wide variety of user agents, including assistive technologies

* Markup is used in a way that facilitates accessibility. This includes following the HTML/XHTML specifications and using forms, form labels, frame titles, etc. appropriately.
