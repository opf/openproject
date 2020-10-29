# TypedDag

[<img src="https://travis-ci.org/opf/typed_dag.svg?branch=master" alt="Build Status" />](https://travis-ci.org/opf/typed_dag)
[![Maintainability](https://api.codeclimate.com/v1/badges/0ac421a0c2367f325b1e/maintainability)](https://codeclimate.com/github/opf/typed_dag/maintainability)

This gem supports [directed acyclic graphs](https://en.wikipedia.org/wiki/Directed_acyclic_graph) (DAG) on ActiveRecord models.  Trees, as a subset of a DAG, are also supported. The edges in the modeled DAG are typed, which allows having multiple DAGs over the same set of nodes. E.g. in a forum application, the Messages can be in a tree modeling the hierarchy, while at the same time having a DAG for Messages referencing each other. Queries for nodes/edges can either be limited to a single type (e.g. hierarchy) but can also span a set of types.

TypedDag can hence support use cases alternative implementations such as [awesome_nested_set](https://github.com/collectiveidea/awesome_nested_set), [closure_tree](https://github.com/ClosureTree/closure_tree) or [acts_as_dag](https://github.com/resgraph/acts-as-dag) can not, but can also be used as a drop in replacement.

The gem is written with performance in mind. It was developed to support the DAG in [OpenProject](https://www.openproject.org/) which in larger installations contains hundreds of thousands of nodes. Read queries will always require only one DB access.

## Usage

Again using the forum application as an example, one would have messages in a hierarchy with the additional ability of the message to reference each other. Querying could then e.g. look like this:


```
  # Fetch a root message with a specific subject.
  message = Message.hierarchy_roots.where(subject: 'Some bogus')

  # Fetch all the message's children.
  children = message.children

  # Fetch all the message's descendants and eager load the references.
  descendants = message.descendants.includes(:references)

  # Fetch all messages referencing the message.
  message = message.referenced

  # Fetch all messages having an edge starting from the message ignoring the type.
  # This will work transitively, so a message which is connected to the initial message
  # via two edges (regardless of their type) will also be returned
  Message.includes(:relations_from).where(from: message)
```

Please note that the name of the scopes (e.g. `children`, `hierarchy_roots` and `referenced`) and constants (`Message`) have to be configured.

## Requirements

* Rails >= 5.0
* MySQL or PostgreSQL (>= 9.5) as `UPSERT` statements are used

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'typed_dag'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install typed_dag
```

## Configuration

TypedDag needs two AR models to be configured as the nodes and edges of the DAG. The edges are basically a join_table. Edges in DAGs are directed. As circular edges are prevented by the gem, please choose the columns denoting where an edge starts (`from_column`) and where it ends (`to_column`) carefully. It will not make a difference when only one type is configured for the dag but it does when the dag is configured to have multiple types.

To avoid having to configure TypedDag twice, in the node and in the edge AR model, configuration is done in a rails initializer. In your rails app, add a file to `config/initializers`.

```
  # /config/initializers/typed_dag.rb
  # configuration for Relation/Message
  TypedDag::Configuration.set edge_class_name: 'Relation',
                              node_class_name: 'Message',
                              from_column: 'ancestor_id',
                              to_column: 'descendant_id',
                              count_column: 'amount',
                              types: { hierarchy: { from: { name: :parent, limit: 1 },
                                                    to: :children,
                                                    all_from: :ancestors,
                                                    all_to: :descendants },
                                       invalidate: { from: :invalidated_by,
                                                     to: :invalidates,
                                                     all_from: :all_invalidated_by,
                                                     all_to: :all_invalidates } }


  # unrelated configuration for Edge/Node
  TypedDag::Configuration.set edge_class_name: 'Edge'
                              node_class_name: 'Node',
                              types: { edge: { from: :edges_from,
                                               to: :edges_to,
                                               all_from: :all_ancestors_from,
                                               all_to: :all_ancestors_to },
                              ...
```

The above configures DAGs for two AR model class pairs: `Relation`/`Message` and `Edge`/`Node`.

A real life example is the [initializer in OpenProject](https://github.com/opf/openproject/blob/dev/config/initializers/typed_dag.rb)

The following options exist:
 * `edge_class_name`: The name of the AR model whose instances serve as the edges of the dag
 * `node_class_name`: The name of the AR model whose instances serve as the nodes of the dag
 * `from_column` (default `from_id`): The name of the column in the edges AR model that refer to the node the edge starts from
 * `to_column` (default `to_id`): The name of the column in the edges AR model that refer to the node the edge ends in
 * `count_column` (default `count`): The name of the column in the edges AR model that keeps track of the number of identical edges between from and to
 * `types`: The hash of type configurations. The key of each configuration will need to be present as a column in the edge's DB table.
  * `from`: The AR association's name for nodes having a relation which end in the current node, have the type specified by the key and are not transitive (have only one hop). Only for `from` can one specify a limit to the number of relations a node can have. Doing this turns the DAG into a tree which is usefull for hierarchies. If a limit needs to be specified, the configuration has to be provided as `{ name: [association's name], limit: 1 }`. If no limit is given, the association's name can be provided as a symbol.
  * `to`: The AR association's name for nodes having a relation which start from the current node, have the type specified by the key and are not transitive (have only one hop)
  * `all_from`: The AR association's name for nodes having a relation which ends in the current node and have the type specified by the key. Direct and transitive nodes are returned.
  * `all_to`: The AR association's name for nodes having a relation which start from the current node and have the type specified by the key. Direct and transitive nodes are returned.

## Methods

Based on the configuration, the AR models configured to be edges and nodes receive a set of class and instance methods.

### Node

On an instance:
 * `relations_from` (`has_many` association): All edges ending in the node.
 * `relations_to` (`has_many` association): All edges starting from the node.
 * `[from]_relation` (only when limit is 1) (`has_one` association): The non transitive edges of the type ending in the node.
 * `[from]_relations` (only when limit is not 1) (`has_many` association): The non transitive edges of the type ending in the node.
 * `[from]` (`has_many`/`has_one` association): The nodes, or the single node, having non transitive edges of the type ending in the node.
 * `[to]_relations` (`has_many` association): All non transitive edges of the type starting from the node.
 * `[to]` (`has_many` association): All nodes having non transitive edges of the type starting from the node.
 * `[all_from]_relations` (`has_many` association): All edges of the type ending in the node.
 * `[all_from]` (`has_many` association): All nodes having edges of the type ending in the node.
 * `[all_to]_relations` (`has_many` association): All edges of the type starting from the node.
 * `[all_to]` (`has_many` association): All nodes having edges of the type starting from the node.
 * `[all_from]_of_depth(depth)`: Scope to get all nodes having edges of the type ending in the node and that are connected via `depth` direct edges. A depth of 1 yields the same results as `[all_from]`.
 * `[all_to]_of_depth(depth)`: Scope to get all nodes having edges of the type starting from the node and that are connected via `depth` direct edges. A depth of 1 yields the same results as `[all_to]`.
 * `self_and_[all_from]`: Scope to get all nodes having edges of the type ending in the node and the node itself.
 * `self_and_[all_to]`: Scope to get all nodes having edges of the type starting from the node and the node itself.
 * `[key]_leaves`: Scope to get all nodes having edges of the type starting from the node that have no edges of the type starting from themselves.
 * `[key]_leaf?`: Checks whether the node has edges of the type starting from the node.
 * `[key]_roots`: Scope to get all nodes having edges of the type ending in the node that have no edges of the type ending in themselves.
 * `[key]_root?`: Checks whether the node has edges of the type ending in the node.
 * `[from.singularize]?: Checks whether the node has relations of the type starting from the node.
 * `[to.singularize]?: Checks whether the node has relations of the type ending in the node.

On the class:
 * `[key]_leaves`: All nodes having edges of the type ending in them.
 * `[key]_roots`: All nodes having edges of the type starting from them.
 * `rebuild_dag!`: Truncates all reflexive and transitive edges and rebuilds them based on the information represented in the direct edges.

### Edge

On an instance:
 * `from` (`belongs_to` association): The node the edge starts from.
 * `to` (`belongs_to` association): The node the edge ends in.
 * `direct?`: Checks whether the edge is the direct connection between two nodes, which is true if it has exactly one type column set to 1.

On the class:
 * `[key]`: Scope to get all edges of the type, direct or transitive. All other type columns need to be zero.
 * `non_[key]`: Scope to get all edges not having the type, direct or indirect. The type column needs to be zero.
 * `with_type_columns_0(columns)`: Scope to get all edges having zero for the type columns specified.
 * `with_type_columns(column_requirement)`: Scope to get all edges satisfying the condition specified (needs to be a hash, e.g. `hierarchy: 1'). All other type columns need to be zero.
 * `with_type_columns_not(column_requirement)`: Scope to get all edges not satisfying the condition specified (needs to be a hash, e.g. `hierarchy: 1'). All other type columns need to be zero.
 * `of_from_and_to(from, to)`: Scope to get all edges starting from `from` and ending in `to`.
 * `direct`: Scope to get all edges being the direct connection between two nodes, which is true if the node has exactly one type column set to 1.
 * `non_reflexive`: Scope to get only the non reflexive edges (not the ones where `to = from`) which are used internally for optimization.

## Migration

The edge's table needs to be created containing at least the following columns (names can be configured):

 * `from_id`: A reference to the node the edge starts from.
 * `to_id`: A reference to the node the edge ends in.
 * `count`: The counter column for the number of similar (transitive) edges between to and from.
 * `[key]`: A column of type integer for every type the dag is to support.

A migration to create such a table could look like this:

```
  def change
    create_table :edges do |t|
      t.references :from, null: false
      t.references :to, null: false

      t.column :count, :integer, null: false, default: 0

      t.column :hierarchy, :integer, null: false, default: 0
      t.column :reference, :integer, null: false, default: 0
    end

    add_foreign_key :edges, :nodes, column: :from_id
    add_foreign_key :edges, :nodes, column: :to_id

    # give the index a custom name to avoid running into length limitation when having a couple of columns
    # in the index
    add_index :edges, [:from_id, :to_id, :hierarchy, :reference], name: `index_on_type_columns`, unique: true
    add_index :edges, :count, where: 'count = 0'
  end
```

The table can also have additional columns. They will not interfere with TypedDag.

Which indices to use will depend on the data added but a unique index covering the foreign keys to the nodes as well as the columns counting the hops per type is required. A partial index on count speeds up deleting edges while also being very lightweight to maintain. Please note that [MySql does not support partial indices](https://dev.mysql.com/doc/refman/5.7/en/create-index.html).

There are no requirements on the node's table.

When migrating from a different library, the details of course depend on the library used. If it is one of the many having a `parent_id` column on the node table, one would first have to create the edge table as outlined above and then add a SQL statement like this:

```
  ActiveRecord::Base.connection.execute <<-SQL
    INSERT INTO edges
      (from_id, to_id, hierarchy)
    SELECT n1.id, n2.id, 1
    FROM nodes n1
    JOIN nodes n2
    ON n1.id = n2.parent_id
  SQL
```

This will create all direct edges. Using

```
  Node.rebuild_dag!
```

will then generate the transitive ones. Please note that it is required to first configure TypedDag in order to execute the statement.

## Contributing

Every bug report and pull request is appreciated. Simply open an issue or send a pull request in the [repository](https://github.com/opf/typed_dag).

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
