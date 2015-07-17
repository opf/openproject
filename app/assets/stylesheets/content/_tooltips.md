# Tooltips

Adds tooltips to arbitrary elements.

## Simple Tooltips

These can contain simple texts but are not suitable for HTML within the Tooltip.

### Right

```
<span class="tooltip--right" data-tooltip="The content of the tooltip">
  <i class="icon icon-help1"></i>
</span>
```

### Bottom

```
<span class="tooltip--bottom" data-tooltip="The content of the tooltip">
  <i class="icon icon-help1"></i>
</span>
```

### Left

```
<span class="tooltip--left" data-tooltip="The content of the tooltip">
  <i class="icon icon-help1"></i>
</span>
```

### Top

```
<span class="tooltip--top" data-tooltip="The content of the tooltip">
  <i class="icon icon-help1"></i>
</span>
```

## Examples

### Form elements

```
<form class="form">
  <div class="form--field">
    <label for="kurosaki" class="form--label">Kurosaki</label>
    <div class="form--field-container">
      <div class="form--text-field-container">
        <input type="text" placeholder="First name" class="form--text-field" id="kurosaki" >
      </div>
      <div class="form--tooltip-container">
        <span class="tooltip--right" tabindex="0" data-tooltip="First name of the son">
          <i class="icon icon-help"></i>
        </span>
      </div>
    </div>
  </div>
  <div class="form--field">
    <label for="bankai" class="form--label">Bankai</label>
    <div class="form--field-container">
      <div class="form--select-container">
        <select name="bankai" id="bankai" class="form--select">
          <option value="hakka">Hakka no togame</option>
          <option value="tensa">Tensa zangetsu</option>
          <option value="zanka">Zanka no tachi</option>
          <option value="kokujo">Kokujō Tengen Myō'ō</option>
          <option value="tekken">Tekken tachikaze</option>
        </select>
      </div>
      <div class="form--tooltip-container">
        <span class="tooltip--bottom" tabindex="0" data-tooltip="Ice-type maybe?">
          <i class="icon icon-heart"></i>
        </span>
      </div>
    </div>
  </div>
  <div class="form--field">
    <label for="kuchiki" class="form--label">Kuchiki</label>
    <div class="form--field-container">
      <div class="form--text-field-container">
        <input type="text" class="form--text-field" placeholder="First name" id="kuchiki">
      </div>
      <div class="form--tooltip-container">
        <span class="tooltip--right" tabindex="0" data-tooltip="First name of a captain">
          <i class="icon icon-help1"></i>
        </span>
      </div>
    </div>
  </div>
  <div class="form--field">
    <label for="traitor" class="form--label">Traitor</label>
    <div class="form--field-container">
      <div class="form--text-field-container">
        <input type="password" placeholder="Traitor" id="traitor">
      </div>
      <div class="form--tooltip-container">
        <span class="tooltip--right -multiline" tabindex="0" data-tooltip="Well, major spoiler, so we better hide the output, right? Then again, wouldn't this be according to Keikaku anyway?">
          <i class="icon icon-warning"></i>
        </span>
      </div>
    </div>
  </div>
</form>
```

Note that the tabindex has to be set manually on the `<span>` and not the containing element. `tabindex="0"` makes the item tabbable at all.

### HTML tooltips

```
<div class="form--field">
  <label class="form--label" for="new_password" title="New password">New password</label>
  <div class="form--field-container tooltip-visible">
    <span class="form--text-field-container">
      <input class="form--text-field -password" id="new_password" name="new_password" size="25" type="password">
    </span>
    <span class="advanced-tooltip">
      <em>Must be at least 10 characters long.</em><br>
      <em>
        Must contain characters of the following classes (at least 2 of 4):
        <ul>
          <li>lowercase (e.g. 'a')</li>
          <li>uppercase (e.g. 'A')</li>
        </ul>
      </em>
    </span>
  </div>
</div>
```

### Inline text

```
<h2>Title</h2>
<p>Lorem <span style="text-decoration: underline;" class="tooltip--top" data-tooltip="this is actully not a real latin text">ipsum</span> dolor sit amet, consectetur adipisicing elit. Facere quibusdam sit voluptas illo error reiciendis non nisi necessitatibus architecto beatae, ea quos <span style="text-decoration: underline;" class=" tooltip--top" data-tooltip="Sounds like an endboss in a JRPG, doesn't it?">sint</span> consectetur repellat aliquid. Ducimus provident totam pariatur.</p>
```
