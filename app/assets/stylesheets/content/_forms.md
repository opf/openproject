# Forms

## Forms: Standard style

```
<form class="form">
  <div class="form--field -required">
    <label class="form--label">Text:</label>
    <div class="form--field-container">
      <div class="form--text-field-container">
        <input type="text" class="form--text-field">
      </div>
    </div>
  </div>

  <hr class="form--separator">
  <button class="button -highlight">Save</button>
  <button class="button">Cancel</button>
</form>
```

## Forms: Bordered style

```
<form class="form -bordered">
  <div class="form--field -required">
    <label class="form--label">Text:</label>
    <div class="form--field-container">
      <div class="form--text-field-container">
        <input type="text" class="form--text-field">
      </div>
    </div>
  </div>

  <hr class="form--separator">
  <button class="button -highlight">Save</button>
  <button class="button">Cancel</button>
</form>
```

## Forms: Standard layout

```
@full-width

<form class="form">
  <section class="form--section">
    <div class="form--field -required">
      <label class="form--label">Text:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="text" class="form--text-field">
        </div>
      </div>
      <div class="form--field-instructions">
        Write anything you like.
      </div>
    </div>
    <div class="form--field">
      <label class="form--label">Email:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="email" class="form--text-field" placeholder="a valid email">
        </div>
      </div>
      <div class="form--field-extra-actions">
        <a href="#">Request new email</a>
      </div>
    </div>
    <div class="form--field -required">
      <label class="form--label">Number:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="number" class="form--text-field">
        </div>
      </div>
      <div class="form--field-instructions">
        Any number from 1 to 10!
      </div>
    </div>
    <div class="form--field -required">
      <label class="form--label">Long text:</label>
      <div class="form--field-container">
        <div class="form--text-area-container">
          <textarea class="form--text-area">El resto della concluían sayo de velarte, calzas de velludo para las fiestas, con sus pantuflos de lo mesmo, y los días de entresemana se honraba con su vellorí de lo más fino.</textarea>
        </div>
      </div>
      <div class="form--field-instructions">
        Write more about anything.
      </div>
    </div>
    <div class="form--field -required -no-label">
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="text" class="form--text-field">
        </div>
      </div>
      <div class="form--field-instructions">
        This field has no label, which means you really can write what you like.
      </div>
    </div>
    <div class="form--field -required -full-width">
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="text" class="form--text-field">
        </div>
      </div>
      <div class="form--field-instructions">
        This field also has no label, but takes up the full width.
      </div>
    </div>
  </section>
</form>
```

## Forms: Standard layout, wide labels

```
@full-width

<form class="form -wide-labels">
  <section class="form--section">
    <div class="form--field -required">
      <label class="form--label">Text:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="text" class="form--text-field">
        </div>
      </div>
    </div>
    <div class="form--field">
      <label class="form--label">Email:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="email" class="form--text-field" placeholder="a valid email">
        </div>
      </div>
      <div class="form--field-instructions">
        Your personal email address.
      </div>
    </div>
    <div class="form--field -required">
      <label class="form--label">Number:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="number" class="form--text-field">
        </div>
      </div>
      <div class="form--field-instructions">
        Any number from 1 to 10!
      </div>
    </div>
    <div class="form--field -required">
      <label class="form--label">Long text:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <textarea class="form--text-area">El resto della concluían sayo de velarte, calzas de velludo para las fiestas, con sus pantuflos de lo mesmo, y los días de entresemana se honraba con su vellorí de lo más fino.</textarea>
        </div>
      </div>
      <div class="form--field-instructions">
        Write more about anything.
      </div>
    </div>
    <div class="form--field -required -no-label">
      <div class="form--field-container">
        <label class="form--label-with-check-box">
          <div class="form--check-box-container">
            <input type="checkbox" class="form--check-box">
          </div>
          Option 1
        </label>
        <label class="form--label-with-check-box">
          <div class="form--check-box-container">
            <input type="checkbox" class="form--check-box">
          </div>
          Option 2
        </label>
      </div>
      <div class="form--field-instructions">
        Selecting these option might be considered a dangerous operation.
      </div>
    </div>
  </section>
</form>
```

## Forms: Multiple fields per row

```
@full-width

<form class="form">
  <fieldset class="form--fieldset">
    <legend class="form--fieldset-legend">Wichtige Daten</legend>
    <div class="form--field -required">
      <label class="form--label">Lieblingsstädte:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="text" class="form--text-field" value="Leipzig">
        </div>
        <div class="form--text-field-container">
          <input type="text" class="form--text-field" placeholder="Berlin">
        </div>
        <div class="form--text-field-container">
          <input type="text" class="form--text-field" placeholder="Zürich">
        </div>
        <div class="form--text-field-container">
          <input type="text" class="form--text-field" placeholder="Paris">
        </div>
        <div class="form--text-field-container">
          <input type="text" class="form--text-field" placeholder="Rom">
        </div>
      </div>
    </div>
    <div class="form--field -required">
      <label class="form--label">Geburtsdatum:</label>
      <div class="form--field-container">
        <div class="form--select-container">
          <select class="form--select">
            <option>01</option><option>02</option><option>03</option>
          </select>
        </div>
        <div class="form--select-container">
          <select class="form--select">
            <option>Januar</option>
            <option selected>Februar</option>
            <option>März</option>
            <option>April</option>
            <option>Mai</option>
            <option>Juni</option>
            <option>Juli</option>
            <option>August</option>
            <option>September</option>
            <option>Oktober</option>
            <option>November</option>
            <option>Dezember</option>
          </select>
        </div>
        <div class="form--text-field-container">
          <input type="number" class="form--text-field" placeholder="1984">
        </div>
      </div>
      <div class="form--field-instructions">
        One never lies about one's age.
      </div>
    </div>
    <div class="form--grouping" role="group" aria-labelledby="form-grouping-label">
      <div id="form-grouping-label" class="form--grouping-label">Colors:</div>
      <div class="form--grouping-row">
        <div class="form--field">
          <label class="form--label">Most favorite first:</label>
          <div class="form--field-container">
            <div class="form--text-field-container">
              <input type="text" class="form--text-field" placeholder="Green">
            </div>
          </div>
        </div>
        <div class="form--field">
          <label class="form--label">Most favorite second:</label>
          <div class="form--field-container">
            <div class="form--text-field-container">
              <input type="text" class="form--text-field" placeholder="Blue">
            </div>
          </div>
        </div>
      </div>
      <div class="form--grouping-row">
        <div class="form--field">
          <label class="form--label">Least favorite first:</label>
          <div class="form--field-container">
            <div class="form--text-field-container">
              <input type="text" class="form--text-field" placeholder="Magenta">
            </div>
          </div>
        </div>
        <div class="form--field">
          <label class="form--label">Least favorite second:</label>
          <div class="form--field-container">
            <div class="form--text-field-container">
              <input type="text" class="form--text-field" placeholder="Orange">
            </div>
          </div>
        </div>
      </div>
    </div>
  </fieldset>
</form>
```

## Forms: Vertical layout

```
@full-width

<form class="form -vertical">
  <section class="form--section">
    <div class="grid-block">
      <div class="form--field -required">
        <label class="form--label">Text:</label>
        <div class="form--field-container">
          <div class="form--text-field-container">
            <input type="text" class="form--text-field">
          </div>
        </div>
        <div class="form--field-instructions">
          Write anything you like.
        </div>
      </div>
      <div class="form--field">
        <label class="form--label">Email:</label>
        <div class="form--field-container">
          <div class="form--text-field-container">
            <input type="email" class="form--text-field" placeholder="a valid email">
          </div>
        </div>
        <div class="form--field-extra-actions">
          <a href="#">Request new email</a>
        </div>
      </div>
      <div class="form--field -required">
        <label class="form--label">Number:</label>
        <div class="form--field-container">
          <div class="form--text-field-container">
            <input type="number" class="form--text-field">
          </div>
        </div>
        <div class="form--field-instructions">
          Any number from 1 to 10!
        </div>
      </div>
    </div>
    <div class="grid-block">
      <div class="form--field -required">
        <label class="form--label">Long text:</label>
        <div class="form--field-container">
          <div class="form--text-area-container">
            <textarea class="form--text-area">El resto della concluían sayo de velarte, calzas de velludo para las fiestas, con sus pantuflos de lo mesmo, y los días de entresemana se honraba con su vellorí de lo más fino.</textarea>
          </div>
        </div>
        <div class="form--field-instructions">
          Write more about anything.
        </div>
      </div>
    </div>
  </section>
</form>
```

## Forms: Sections and fieldsets

```
<form class="form -bordered">
  <section class="form--section">
    <div class="form--field -required">
      <label class="form--label">Text:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="text" class="form--text-field">
        </div>
      </div>
    </div>
  </section>
  <section class="form--section">
    <h3 class="form--section-title">Advanced information</h3>
    <div class="form--field -required">
      <label class="form--label">More text:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="text" class="form--text-field">
        </div>
      </div>
    </div>
  </section>
  <fieldset class="form--fieldset">
    <legend class="form--fieldset-legend">
      Even more advanced information
    </legend>
    <div class="form--field -required">
      <label class="form--label">Even more text:</label>
      <div class="form--field-container">
        <div class="form--text-field-container">
          <input type="text" class="form--text-field">
        </div>
      </div>
    </div>
  </fieldset>
</form>
```

# Forms: Attachment fieldsets

```
<fieldset id="attachments" class="header_collapsible collapsible">
  <legend title="Show/Hide attachments" ,="" onclick="toggleFieldset(this);">
    <a href="javascript:">Files<span class="fieldset-toggle-state-label hidden-for-sighted">expanded</span></a>
  </legend>
  <div style="">
    <div id="attachments_fields">
      <div class="grid-block" id="attachment_template">
        <div class="form--field">
          <div class="attachment_field form--field-container -vertical -shrink">
            <div class="form--file-container">
              <input class="attachment_choose_file" name="attachments[1][file]" size="15" type="file">            </div>
          </div>
        </div>
        <div class="form--field">
          <label class="form-label">
            Description
          </label>
          <div class="form--text-field-container">
            <input name="attachments[1][description]" size="38" type="text" value="">
          </div>
        </div>
      </div>
    <div class="grid-block" id="">
        <div class="form--field">
          <div class="attachment_field form--field-container -vertical -shrink">
            <div class="form--file-container">
              <input class="attachment_choose_file" name="attachments[2][file]" size="15" type="file">            </div>
          </div>
        </div>
        <div class="form--field">
          <label class="form-label">
            Description
          </label>
          <div class="form--text-field-container">
            <input name="attachments[2][description]" size="38" type="text" value="">
          </div>
        </div>
      </div></div>
    <span class="add_another_file">
      <a href="#" onclick="addFileField(); return false;">Add another file</a>
      (Maximum size: 5 MB)
    </span>
  </div>
</fieldset>
```

# Forms: Text fields

## Default text fields

### Standalone

```
<label>Text:<input type="text" class="form--text-field"></label>
<label>Email:<input type="email" class="form--text-field" placeholder="a valid email"></label>
<label>Number:<input type="number" class="form--text-field"></label>
```

## Text field sizes

```
<label>Tiny:<input type="text" class="form--text-field -tiny" value="a tiny value"></label>

<label>Small:<input type="text" class="form--text-field -small" value="a small value"></label>

<label>Large:<input type="text" class="form--text-field -large" value="a large value"></label>
```

## Plain text fields

_with no classes applied (uses default Foundation form styling)_

```
<label>Text:<input type="text"></label>
<label>Email:<input type="email" placeholder="a valid email"></label>
<label>Number:<input type="number"></label>
```

# Forms: Text areas

## Default text areas

### Standalone

```
<textarea class="form--text-area">
Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
</textarea>
```

## Plain text areas

_with no classes applied (uses default Foundation form styling)_

```
<textarea>
Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
</textarea>
```

# Forms: Checkboxes

## Default checkboxes

### Standalone

```
<input type="checkbox" class="form--check-box" id="checkbox_example_choice1">
<label for="checkbox_example_choice1" class="form--label">Choice</label>
```

```
<label class="form--label-with-check-box">
  <div class="form--check-box-container">
    <input type="checkbox" class="form--check-box">
  </div>
  Choice
</label>
```

### Within a form

```
<form class="form">
  <div class="form--field">
    <label class="form--label" for="checkbox_example_choice2">Eat fruit:</label>
    <div class="form--field-container">
      <div class="form--check-box-container">
        <input type="checkbox" class="form--check-box" id="checkbox_example_choice2">
      </div>
    </div>
  </div>
</form>
```

### Multiple, within a form

```
<form class="form">
  <div class="form--field">
    <label class="form--label">Multiple choices:</label>
    <div class="form--field-container -vertical">
      <label class="form--label-with-check-box">
        <div class="form--check-box-container">
          <input type="checkbox" class="form--check-box">
        </div>
        Apple
      </label>
      <label class="form--label-with-check-box">
        <div class="form--check-box-container">
          <input type="checkbox" class="form--check-box">
        </div>
        Grapefruit
      </label>
      <label class="form--label-with-check-box">
        <div class="form--check-box-container">
          <input type="checkbox" class="form--check-box">
        </div>
        Banana
      </label>
    </div>
  </div>
</form>
```

## Styled checkboxes [TO BE REFACTORED]

```
<label class="checkbox-label">
  <input type="checkbox">
  <div class="styled-checkbox"></div>
</label>

<br>
<br>

<label class="checkbox-label">
  checkbox label
  <input type="checkbox">
  <div class="styled-checkbox"></div>
</label>

<br>
<br>

<label class="checkbox-label">
  <input type="checkbox">
  <div class="styled-checkbox"></div>
  checkbox label
</label>
```


# Forms: Select

## Default selects

### Standalone

```
<select class="form--select">
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>
```

```
<select class="form--select" multiple>
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>
```

```
<select class="form--select">
  <optgroup label="group one">
    <option>one dot one</option>
  </optgroup>
  <optgroup label="group two">
    <option>two dot one</option>
    <option>two dot two</option>
  </optgroup>
</select>
```

### Within a form

```
<form class="form">
  <div class="form--field">
    <label class="form--label">Oranges:</label>
    <div class="form--field-container">
      <div class="form--select-container">
        <select class="form--select">
          <option>one</option>
          <option>two</option>
          <option>three</option>
        </select>
      </div>
    </div>
    <div class="form--field-instructions">
      Oranges are rich in Vitamin C. Eat more than two!
    </div>
  </div>
  <div class="form--field">
    <label class="form--label">Apples:</label>
    <div class="form--field-container">
      <div class="form--select-container">
        <select class="form--select" multiple>
          <option>one</option>
          <option>two</option>
          <option>three</option>
        </select>
      </div>
    </div>
  </div>
</form>
```

## Select Sizes

```
<select class="form--select -tiny">
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>

<select class="form--select -small">
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>

<select class="form--select -large">
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>
```

## Narrow select

_By default, a `form--select` will take the full width of its container element.
In most cases it is recommended to apply a width to the container element, but
in certain circumstances the `-narrow` variant may be preferable._

```
<select class="form--select -narrow">
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>

<select class="form--select -small -narrow">
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>
```

## Plain selects

_with no classes applied (uses default Foundation form styling)_

```
<select>
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>
```
