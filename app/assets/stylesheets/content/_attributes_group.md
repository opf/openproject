# Attributes Groups

## with Attribute Lists

```
<div class="attributes-group">
  <div class="attributes-group--header">
    <div class="attributes-group--header-container">
      <h3 class="attributes-group--header-text">Details</h3>
    </div>
    <div class="attributes-group--header-toggle">
      <a href="#" class="button -small -transparent">Show all</a>
    </div>
  </div>

  <dl class="attributes-key-value">
    <dt class="attributes-key-value--key">Status</dt>
    <dd class="attributes-key-value--value-container">
      <div class="attributes-key-value--value -text">
        <span title="New">New</span>
      </div>
    </dd>
    <dt class="attributes-key-value--key">Percentage done</dt>
    <dd class="attributes-key-value--value-container">
      <div class="attributes-key-value--value -text">
        <span title="0">0</span>
      </div>
    </dd>
    <dt class="attributes-key-value--key">Date</dt>
    <dd class="attributes-key-value--value-container">
      <div class="attributes-key-value--value -text">
        <span title="">-</span>
      </div>
    </dd>
    <dt class="attributes-key-value--key">Priority</dt>
    <dd class="attributes-key-value--value-container">
      <div class="attributes-key-value--value -text">
        <span title="Normal">Normal</span>
      </div>
    </dd>
  </dl>
</div>

<div class="attributes-group">
  <div class="attributes-group--header">
    <div class="attributes-group--header-container">
      <h3 class="attributes-group--header-text">People</h3>
    </div>
  </div>

  <dl class="attributes-key-value">
    <dt class="attributes-key-value--key">Assignee</dt>
    <dd class="attributes-key-value--value-container">
      <div class="attributes-key-value--value -user">
        <span class="user-avatar--container">
          <img class="user-avatar--avatar" alt="Avatar" title="testing.long.emails@openproject.org" src="http://gravatar.com/avatar/ae4878114ca94594589106efaad8890e?default=wavatar&amp;secure=false">
          <span class="user-avatar--user-with-role">
            <span class="user-avatar--user">
              <a class="user-avatar--user-link" href="#">testing.long.emails@openproject.org</a>
            </span>
          </span>
        </span>
      </div>
    </dd>
    <dt class="attributes-key-value--key">Responsible</dt>
    <dd class="attributes-key-value--value-container">
      <div class="attributes-key-value--value -user">
        <span class="user-avatar--container">
          <img class="user-avatar--avatar" alt="Avatar" title="testing.long.emails+filter-junk-away@openproject.org" src="http://gravatar.com/avatar/ae4878114ca94594589106efaad8890e?default=wavatar&amp;secure=false">
          <span class="user-avatar--user-with-role">
            <span class="user-avatar--user">
              <a class="user-avatar--link" href="#">Karl-Theodor zu Guttenberg (copy)</a>
            </span>
            <span class="user-avatar--role">
              Distinguished Statesman.
              Former Minister for Economics and Technology.
            </span>
          </span>
        </span>
      </div>
    </dd>
  </dl>
</div>
```

## with Single Attribute

```
<div class="attributes-group">
  <div class="attributes-group--header">
    <div class="attributes-group--header-container">
      <h3 class="attributes-group--header-text">Description</h3>
    </div>
  </div>

  <div class="single-attribute wiki-text">
    <h2>Capítulo uno</h2>
    <p>En un lugar <em>de la Mancha</em>, de cuyo nombre no quiero acordarme,
    no ha mucho tiempo que vivía un hidalgo de los de lanza en astillero,
    adarga antigua, rocín flaco y galgo corredor. Una olla de algo más vaca que
    carnero, salpicón las más noches, duelos y quebrantos los sábados, lantejas
    los viernes, algún palomino de añadidura los domingos, consumían las tres
    partes de su hacienda. El resto della concluían sayo de velarte, calzas de
    velludo para las fiestas, con sus pantuflos de lo mesmo, y los días de
    entresemana se honraba con su vellorí de lo <strong>más fino</strong>.</p>
  </div>
</div>
```
