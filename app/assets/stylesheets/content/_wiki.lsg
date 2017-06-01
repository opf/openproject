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

  <p>Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</p>

  <p>Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat.</p>

  <p style="text-align:right"> Right aligned
  Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat.</p>

  <p style="text-align:center"> Centered
  Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat.</p>
</div>
```

## Headings

```
<div class="wiki">
  <h1>
    Headline H1
    <a href="#Heading-H1" class="wiki-anchor">¶</a>
  </h1>

  <h2>
    Headline H2
    <a href="#Heading-H2" class="wiki-anchor">¶</a>
  </h2>

  <h3>
    Headline H3
    <a href="#Heading-H3" class="wiki-anchor">¶</a>
  </h3>

  <h4>
    Headline H4
    <a href="#Heading-H4" class="wiki-anchor">¶</a>
  </h4>

  <h5>
    Headline H5
  </h5>

  <h6>
    Headline H6
  </h6>
</div>
```

Note: Only headings to level ***three*** are supported in the wiki toolbar at the moment. Up to level ***four***, an anchor link is added.

## Table of contents

```
<div class="wiki">
  <fieldset class="form--fieldset -collapsible">
    <legend class="form--fieldset-legend" title="Show/Hide table of contents" onclick="toggleFieldset(this);">
      <a href="javascript:">Table of Contents</a>
    </legend>
    <div>
      <ul class="toc">
        <li>
          <a href="#Heading-H1">Heading H1</a>
          <ul>
            <li>
              <a href="#Heading-H2">Heading H2</a>
              <ul>
                <li>
                  <a href="#Heading-H3">Heading H3</a>
                  <ul>
                    <li>
                      <a href="#Heading-H4">Heading H4</a>
                    </li>
                  </ul>
                </li>
              </ul>
            </li>
          </ul>
        </li>

        <li>
          <a href="#Heading-H1">Heading H1</a>
          <ul>
            <li>
              <a href="#Heading-H2">Heading H2</a>
            </li>
            <li>
              <a href="#Heading-H2">Heading H2</a>
            </li>
              <ul>
                <li>
                  <a href="#Heading-H3">Heading H3</a>
                </li>
                <li>
                  <a href="#Heading-H3">Heading H3</a>
                </li>
              </ul>
            <li>
              <a href="#Heading-H2">Heading H2</a>
            </li>
          </ul>
        </li>
        <li>
          <a href="#Heading-H1">Heading H1</a>
        </li>
      </ul>
    </div>
  </fieldset>
</div>
```


Note: Only headings to level ***four*** are considered in the table of contents.


## Font styles

```
<div class="wiki">
  <p>
    <strong>Strong</strong>
  </p>
  <p>
    <em>Emphasis</em>
  </p>
  <p>
    <ins>Inserted</ins>
  </p>
  <p>
    <ins>Deleted</ins>
  </p>
  <p>
    <strong><em>StrongEmphasis</em></strong>
  </p>
  <p>
    <b>Bold</b>
  </p>
  <p>
    <i>Italic</i>
  </p>
  <p>
    <cite>Citation</cite>
  </p>
  <p>
    <sup>Superscript</sup>
  </p>
  <p>
    <sub>Subscript</sub>
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
    <li>Item 2
      <ul>
        <li> Subitem 1 </li>
        <li>
          Subitem 2

          <ul>
            <li> Subsubitem 1 </li>
            <li> Subsubitem 2 </li>
            <li> Subsubitem 3 </li>
          </ul>
        </li>
      </ul>
    </li>
    <li>Item 3</li>
  </ul>
</div>
```

## Ordered List

```
<div class="wiki">
  <ol>
    <li>Item</li>
    <li>Item
      <ol>
        <li>Subitem</li>
        <li>SubItem
          <ol>
            <li>Subsubitem</li>
            <li>SubsubItem</li>
            <li>SubsubItem</li>
          </ol>
        </li>
        <li>SubItem</li>
      </ol>
    </li>
    <li>Item</li>
  </ol>
</div>
```

## Blockquote

```
<div class="wiki">
  <blockquote>
    <p>
      The good news is that you're going to live. The bad news is that he is here to kill you.
    </p>
  </blockquote>
</div>
```

## Link

```
<div class="wiki">
  <p><a href="https://google.com">External link</a></p>
  <p><a href="#">Internal link</a></p>
  <p><a href="#" class="wiki-link">Wiki link</a></p>
  <p><a href="#" class="version">Version link</a></p>
  <p><a href="#" class="message">Message link</a></p>
  <p><a href="#" class="project">Project link</a></p>
  <p><a href="#" class="changeset">Changeset link</a></p>
  <p><a href="#" class="attachment">Attachment link</a></p>
  <p><a href="#" class="source download">Source download link</a></p>
  <p><a href="#" class="source">Source link</a></p>
</div>
```

Links to work packages come in various alternatives:

* only the ID

```
<div class="wiki">
  <p><a href="/work_packages/56" class="issue work_package status-8 priority-2" title="pariatur eveniet autem ea consequatur maiores fuga illo (on hold)">#56</a></p>
</div>
```

* ID with a description

```
<div class="wiki">
  <p><a href="/work_packages/56" class="issue" title="pariatur eveniet autem ea consequatur maiores fuga illo">Bug #56 on hold</a>: Work Package link without description 2015-03-27 – 2015-04-30</p>
</div>
```

* ID with description, assignee and responsible and additionally parts of the description

```
<div class="wiki">
  <p><a href="/work_packages/56" class="issue" title="pariatur eveniet autem ea consequatur maiores fuga illo">Bug #56 on hold</a>: Work Package link with description 2015-03-27 – 2015-04-30</p>
  <div class="indent quick_info attributes"><span class="label">Responsible:</span> Ulices Volkman<br><span class="label">Assignee:</span> Danika O'Keefe</div>
  <div class="indent quick_info description"><p>Accedo asporto cicuta cribro canto totam molestias quis. Speculum arma desolo nam volo. Vorago explicabo aut arx. Adficio voluptates qui voluptas. Crur annus consequatur cedo vestrum comminor. Demum sollers bis arcesso dolores agnitio defaeco curso. Copia adversus via appono damno ut territo sed.</p></div>
</div>
```

## Image

```


<div class="wiki">
  <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit. Fugit sed cum quam obcaecati eius nisi tenetur tempora odio minus nulla rerum hic, itaque nam dolorum vel fuga quibusdam, praesentium unde!</p>

  <div>
    <img src="http://photopostsblog.com/wp-content/uploads/2009/03/colorful-abstract-pictures30.jpg" alt="">
  </div>

  <p>Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</p>
</div>
```

## Table

```
<div class="wiki">
  <table>
      <tbody><tr>
        <td> Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor </td>
        <td> invidunt ut labore et  </td>
        <td> dolore magna aliquyam erat, sed diam </td>
        <td>  voluptua. At vero eos et accusam et justo duo dolores et ea rebum.  </td>
      </tr>
      <tr>
        <td> Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed  </td>
        <td> diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.    </td>
        <td>  Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse <br>molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, <br>consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.   </td>
        <td>  Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi.   </td>
      </tr>
      <tr>
        <td> Nam liber tempor cum  soluta nobis  </td>
        <td> eleifend option congue nihil imperdiet doming id </td>
        <td>  quod mazim placerat facer possim assum.  </td>
        <td> Lorem ipsum dolor sit amet, consectetuer </td>
      </tr>
      <tr>
        <td> adipiscing elit, sed diam nonummy nibh </td>
        <td> </td>
        <td> euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. </td>
        <td> Ut wisi enim ad minim veniam, quis nostrud exerci </td>
      </tr>
      <tr>
        <td> tation ullamcorper suscipit lobortis nisl ut aliquip ex ea </td>
        <td> commodo consequat.   </td>
        <td> Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse </td>
        <td> molestie consequat, vel illum dolore eu feugiat nulla facilisis.   </td>
      </tr>
    </tbody>
  </table>
</div>
```
