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

## Default Select

_with no class (uses default Foundation form styling)_

```
<select>
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>
```

_with class applied_

```
<select class="form--select">
  <option>one</option>
  <option>two</option>
  <option>three</option>
</select>
```

## Default Select with Option Groups

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

# Forms: Text fields

## Default text field

_with no class (uses default Foundation form styling)_

```
<label>Text:<input type="text"></label>
<label>Email:<input type="email" placeholder="a valid email"></label>
<label>Number:<input type="number"></label>
```

_with class applied_


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
