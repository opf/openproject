# Tooltips

Adds tooltips to arbitrary elements.

## Simple Tooltips

These can contain simple texts but are not suitable for HTML within the Tooltip.

### Right

```
<span class="tooltip-right" data-tooltip="The content of the tooltip">
  <i class="icon icon-help1"></i>
</span>
```

### Bottom

```
<span class="tooltip-bottom" data-tooltip="The content of the tooltip">
  <i class="icon icon-help1"></i>
</span>
```

### Left

```
<span class="tooltip-left" data-tooltip="The content of the tooltip">
  <i class="icon icon-help1"></i>
</span>
```

### Top

```
<span class="tooltip-top" data-tooltip="The content of the tooltip">
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
        <span class="tooltip-right" data-tooltip="First name of the father">
          <i class="icon icon-help"></i>
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
        <span class="tooltip-right" data-tooltip="First name of a captain">
          <i class="icon icon-help1"></i>
        </span>
      </div>
    </div>
  </div>
</form>
```

### Inline text

```
<h2>Title</h2>
<p>Lorem <span style="text-decoration: underline;" class="tooltip-top" data-tooltip="this is actully not a real latin text">ipsum</span> dolor sit amet, consectetur adipisicing elit. Facere quibusdam sit voluptas illo error reiciendis non nisi necessitatibus architecto beatae, ea quos <span style="text-decoration: underline;" class=" tooltip-top" data-tooltip="Sounds like an endboss in a JRPG, doesn't it?">sint</span> consectetur repellat aliquid. Ducimus provident totam pariatur.</p>
```
