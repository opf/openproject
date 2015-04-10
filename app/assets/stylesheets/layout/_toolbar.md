# Toolbar

A toolbar that can and should be used for actions on the current view. Initially designed for the Work package list, this can be reused throughout the application.

## Standard Button Bar

```
@full-width

<h2>Title of the page</h2>
<div class="toolbar-container">
  <div id="toolbar">
    <ul id="toolbar-items">
      <li class="toolbar-item">
        <a href="#" class="button -highlight">An important button</a>
      </li>
      <li class="toolbar-item">
        <button class="button">Normal button</button>
      </li>
      <li class="toolbar-item">
        <button class="button">
          <i class="icon icon-star1"></i> Favourite button
        </button>
      </li>
    </ul>
  </div>
</div>
```

## Toolbar with form elements

```
@full-width

<h2>Dragonball Z characters</h2>
<div class="toolbar-container">
  <div id="toolbar">
    <ul id="toolbar-items">
      <li class="toolbar-item">
        <select name="attribue">
          <option value="" selected></option>
          <option value="super">Super</option>
        </select>
      </li>
      <li class="toolbar-item">
        <input type="text" name="race" placeholder="Race">
      </li>
      <li class="toolbar-item">
        <input type="number" id="level" placeholder="Level">
      </li>
      <li class="toolbar-item">
        <select>
          <option value="" selected></option>
          <option value="vegeta">Vegeta</option>
          <option value="kakarotto">Kakarotto</option>
          <option value="gohan">Gohan</option>
          <option value="piccolo">Piccolo</option>
          <option value="oob">Boo</option>
        </select>
      </li>
      <li class="toolbar-item">
        <a href="#" class="button -highlight">
          <i class="icon-add icon4"></i>
        </a>
      </li>
    </ul>
  </div>
</div>
```
