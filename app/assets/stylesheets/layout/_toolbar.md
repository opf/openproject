# Toolbar

A toolbar that can and should be used for actions on the current view. Initially designed for the Work package list, this can be reused throughout the application.

## Standard Button Bar

```
@full-width
<div class="toolbar-container">
  <div class="toolbar">
    <div class="title-container">
      <h2>Title of the page</h2>
    </div>
    <ul class="toolbar-items">
      <li class="toolbar-item">
        <a href="#" class="button -highlight">An important button</a>
      </li>
      <li class="toolbar-item">
        <button class="button">Normal button</button>
      </li>
      <li class="toolbar-item">
        <button class="button">
          <i class="button--icon icon-star1"></i>
          <span class="button--text">Favourite button</span>
        </button>
      </li>
    </ul>
  </div>
</div>
```

## Toolbar with form elements

```
@full-width

<div class="toolbar-container">
  <div class="toolbar">
    <div class="title-container">
      <h2>Dragonball Z characters</h2>
    </div>
    <ul class="toolbar-items">
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
          <i class="button--icon icon-add"></i>
        </a>
      </li>
    </ul>
  </div>
  <p class="subtitle">now with extremeley long subtitle: Lorem ipsum dolor sit amet, consectetur adipisicing elit. Iste consequatur doloribus suscipit nemo temporibus deserunt alias incidunt doloremque officia rerum, nobis fuga, recusandae voluptatibus voluptatem tenetur repellendus itaque et. Eum.</p>
</div>
```

## Toolbar with Dropdowns

```
@full-width

<div class="toolbar-container">
  <div class="toolbar" role="navigation" aria-label="Toolbar for Lautrec of Carim">
    <div class="title-container">
      <h2>Lautrec of Carim</h2>
    </div>
    <ul class="toolbar-items" role="menubar" aria-hidden="false">
      <li class="toolbar-item -with-submenu" role="menuitem" aria-haspopup="true" tabindex="0">
        <a href="#" class="button -alt-highlight">
          <i class="button--icon icon-time"></i>
          <span class="button--text">Prolong existence</span>
          <i class="button--dropdown-indicator"></i>
        </a>
        <ul class="toolbar-submenu show" role="menu" aria-hidden="true">
          <li class="toolbar-item" role="menuitem">
            <a href="#">
              <i class="icon icon-search"></i>
              Find Anastacia of Astora
            </a>
          </li>
          <li class="toolbar-item no-icon" role="menuitem">
            <a href="#">Pray to Fina</a>
          </li>
          <li class="toolbar-submenu-divider"></li>
          <li class="toolbar-item" role="menuitem">
            <a href="#">
              <i class="icon icon-delete"></i>
              Go hollow
            </a>
          </li>
        </ul>
      </li>
      <li class="toolbar-item" role="menuitem">
        <a class="button">
          <i class="button--icon icon-edit"></i>
          <span class="button--text">Edit character</span>
        </a>
      </li>
      <li class="toolbar-item" role="menuitem">
        <a class="button">
          <i class="button--icon icon-profile"></i>
          <span class="button--text">Profile</span>
        </a>
      </li>
    </ul>
  </div>
  <p class="subtitle">Lautrec can be found within the prison of the church in the Undead Parish after either clearing the bridge of the red drake or going below the bridge through the sewers. Besure to clear the summoner first. Also, this toolbar should be accessible.</p>
</div>
```
