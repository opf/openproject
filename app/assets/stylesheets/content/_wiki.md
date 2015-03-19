# Wiki

Wiki-syntax is used for most textarea-fields within OpenProject. The users have several options to style text.

## Container

```
<div class="wiki">
    
</div>
```

## Paragraph

```
<div class="wiki">
  <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit. Fugit sed cum quam obcaecati eius nisi tenetur tempora odio minus nulla rerum hic, itaque nam dolorum vel fuga quibusdam, praesentium unde!</p>
</div>
```

## Headings

```
<div class="wiki">
  <h1>Headline H1</h1>

  <h2>Headline H2</h2>

  <h3>Headline H3</h3>
</div>
```

Note: Only headings to level **three** are supported in the wiki toolbar at the moment.

## Font styles

```
<div class="wiki">
  <p>
    <span class="bold">Bold</span>
  </p>
  <p>
    <span class="strike">Strikethrough</span>
  </p>
  <p>
    <span class="underline">Underline</span>
  </p>
  <p>
    <span class="italic">Italic</span>
  </p>
  <p>
    <span class="bold italic underline">Bold italic underline</span>
  </p>
</div>
```

## Inline code

```
<div class="wiki">
  <code>
  function Y(f) {
    var p = function(h) {
      return function(x) {
        return f(h(h))(x);
      };
    };
    return p(p);
  }
  </code>
</div>
```

## Preformatted Text

```
<div class="wiki">
  <pre>
  This     is      very 

          formatted
              text
  </pre>
</div>
```

## Unordered List

```
<div class="wiki">
  <ul>
    <li>Item 1</li>
    <li>Item 2</li>
    <li>Item 3</li>
  </ul>
</div>
```

## Ordered List

```
<div class="wiki">
  <ol>
    <li>Item</li>
    <li>Item</li>
    <li>Item</li>
  </ol>
</div>
```

## Blockquote

```
<div class="wiki">
  <blockquote>The good news is that you're going to live. The bad news is that he is here to kill you.</blockquote>
</div>
```

## Link

```
<div class="wiki">
  <p><a href="https://google.com">External link</a></p>
  <p><a href="#">Internal link</a></p>
</div>
```
