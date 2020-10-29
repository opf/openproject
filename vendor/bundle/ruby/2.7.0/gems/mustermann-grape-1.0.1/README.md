# Grape Syntax for Mustermann

This gem implements the `grape` pattern type for Mustermann.

[![Build Status](https://travis-ci.org/ruby-grape/mustermann-grape.svg?branch=master)](https://travis-ci.org/ruby-grape/mustermann-grape)

## Overview

**Supported options:**
`capture`, `except`, `greedy`, `space_matches_plus`, `uri_decode`, `converters` and `ignore_unknown_options`

``` ruby
require 'mustermann/grape'

Mustermann.new('/:id', type: :grape).params('/foo') # => { id: 'foo' }
```

## Syntax

<table>
  <thead>
    <tr>
      <th>Syntax Element</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>:</b><i>name</i> <i><b>or</b></i> <b>&#123;</b><i>name</i><b>&#125;</b></td>
      <td>
        Captures anything but a forward slash in a semi-greedy fashion. Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt> and <tt>greedy</tt> option.
      </td>
    </tr>
    <tr>
      <td><b>*</b><i>name</i> <i><b>or</b></i> <b>&#123;+</b><i>name</i><b>&#125;</b></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named <i>name</i>.
      </td>
    </tr>
    <tr>
      <td><b>*</b> <i><b>or</b></i> <b>&#123;+splat&#125;</b></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named splat.
        It is always an array of captures, as you can use it more than once in a pattern.
      </td>
    </tr>
    <tr>
      <td><b>(</b><i>expression</i><b>)</b></td>
      <td>
        Enclosed <i>expression</i> is optional.
      </td>
    </tr>
    <tr>
      <td><i>expression</i><b>|</b><i>expression</i><b>|</b><i>...</i></td>
      <td>
        Will match anything matching the nested expressions. May contain any other syntax element, including captures.
      </td>
    </tr>
    <tr>
      <td><i>x</i><b>?</b></td>
      <td>Makes <i>x</i> optional. For instance, <tt>(foo)?</tt> matches <tt>foo</tt> or an empty string.</td>
    </tr>
    <tr>
      <td><b>/</b></td>
      <td>
        Matches forward slash. Does not match URI encoded version of forward slash.
      </td>
    </tr>
    <tr>
      <td><b>\</b><i>x</i></td>
      <td>Matches <i>x</i> or URI encoded version of <i>x</i>. For instance <tt>\*</tt> matches <tt>*</tt>.</td>
    </tr>
    <tr>
      <td><i>any other character</i></td>
      <td>Matches exactly that character or a URI encoded version of it.</td>
    </tr>
  </tbody>
</table>
