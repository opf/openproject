# Forms

```
<form class="form">
  <hr class="form--separator">
  <button class="button -highlight">Save</button>
  <button class="button">Cancel</button>
</form>
```

## Forms: Standard layout

```
<form class="form">
  <div class="form--field -required">
    <label class="form--label">Text:</label>
    <div class="form--field-container">
      <input type="text" class="form--text-field">
    </div>
    <div class="form--field-instructions">
      Write anything you like.
    </div>
  </div>
  <div class="form--field">
    <label class="form--label">Email:</label>
    <div class="form--field-container">
      <input type="email" class="form--text-field" placeholder="a valid email">
    </div>
  </div>
  <div class="form--field -required">
    <label class="form--label">Number:</label>
    <div class="form--field-container">
      <input type="number" class="form--text-field">
    </div>
    <div class="form--field-instructions">
      Any number from 1 to 10!
    </div>
  </div>
  <div class="form--field -required">
    <label class="form--label">Long text:</label>
    <div class="form--field-container">
      <textarea class="form--text-area">El resto della concluían sayo de velarte, calzas de velludo para las fiestas, con sus pantuflos de lo mesmo, y los días de entresemana se honraba con su vellorí de lo más fino.</textarea>
    </div>
    <div class="form--field-instructions">
      Write more about anything.
    </div>
  </div>
</form>
```

## Forms: Standard layout, wide labels

```
<form class="form -wide-labels">
  <div class="form--field -required">
    <label class="form--label">Text:</label>
    <div class="form--field-container">
      <input type="text" class="form--text-field">
    </div>
  </div>
  <div class="form--field">
    <label class="form--label">Email:</label>
    <div class="form--field-container">
      <input type="email" class="form--text-field" placeholder="a valid email">
    </div>
    <div class="form--field-instructions">
      Your personal email address.
    </div>
  </div>
  <div class="form--field -required">
    <label class="form--label">Number:</label>
    <div class="form--field-container">
      <input type="number" class="form--text-field">
    </div>
    <div class="form--field-instructions">
      Any number from 1 to 10!
    </div>
  </div>
  <div class="form--field -required">
    <label class="form--label">Long text:</label>
    <div class="form--field-container">
      <textarea class="form--text-area">El resto della concluían sayo de velarte, calzas de velludo para las fiestas, con sus pantuflos de lo mesmo, y los días de entresemana se honraba con su vellorí de lo más fino.</textarea>
    </div>
    <div class="form--field-instructions">
      Write more about anything.
    </div>
  </div>
</form>
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


# Forms: Checkboxes

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
      <select class="form--select">
        <option>one</option>
        <option>two</option>
        <option>three</option>
      </select>
    </div>
    <div class="form--field-instructions">
      Oranges are rich in Vitamin C. Eat more than two!
    </div>
  </div>
  <div class="form--field">
    <label class="form--label">Apples:</label>
    <div class="form--field-container">
      <select class="form--select" multiple>
        <option>one</option>
        <option>two</option>
        <option>three</option>
      </select>
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
