# Buttons

## Default buttons

```
<input type="submit" class="button" value="Submit me"/>
<a href="#" class="button">Click me</a>
<input type="submit" class="button" value="Do not submit" disabled />

```

## With symbols

```
<button class="button -highlight -yes">Yes</button>
<button class="button -yes-send">Yes (and notify others)</button>
<button class="button -no">No</button>
<button class="button -preview">Preview</button>
```

## Loading (Inflight request)

```
<button disabled class="button -loading">Loading...</button>
<button disabled class="button -highlight -saving">Saving...</button>
```

### Aliases

Save (also confirm):

```
<button class="button -save">Save</button>
<button class="button -highlight -confirm">Confirm</button>
```

Cancel (also abort):

```
<button class="button -cancel">Cancel</button>
```

Save and send:

```
<button class="button -confirm-send">Confirm and send</button>
<button class="button -save-send">Save and send</button>
```

## Active (depressed) buttons

```
<input type="submit" class="button -active" value="Submit me"/>
<a href="#" class="button -active -yes">Click me</a>
<input type="submit" class="button -active" value="Do not submit" disabled />
```

## Button sizes

```
<button class="button -tiny">Tiny</button>
<button class="button -small">Small</button>
<button class="button">Default</button>
<button class="button -large">Large</button>
```

## Expanded buttons

```
<button class="button -expand">Expanded button</button>
<a href="#" class="button -expand">Expanded button as link</a>
```
