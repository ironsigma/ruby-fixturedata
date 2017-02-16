# Fixturedata

## Usage

Create fixture data for mongodb testing.

First setupt he db connection and create the fixture data object:

```ruby
$db = Mongo::Client.new('mongodb://127.0.0.1:27017/test').database
$fixture_data = HawkPrime::FixtureData.new($db)
```

In your tests, load the required data set:

```ruby
class SingleOrderTest < Test::Unit::TestCase
  def test_fetch_order
  	# fixture data
    $fixture_data.load('single_order')
    acme_order = $fixture_data['orders']['acme']

    # fetch order from db
    db_order = $db[:orders].find(_id: acme_order['_id'])

    # test fixture data against db fetch
    assert_equal(acme_order['total'], db_order['total'])
  end

  def test_fetch_order
  	# fixture data
    $fixture_data.load('multi_order')

    # ...

  end
end
```

### Data Sets

By default fixture data is stored in `test/fixtures` but can be changed by
using `directory` option.

Inside `test/fixtures` are directories containing the `.json` files to be
loaded into the db when the `load` function is called. The name of the
colleciton is taken from the file name. By default the collection is
dropped before loading a new one, this can be changed by using
the `drop_before` option.

```
	my-project
	|-- lib
	|   ...
	+-- test
	    |-- fixtures
	    |   |-- single_order
	    |   |   |-- 10-client.json
	    |   |   |-- 20-items.json
	    |   |   +-- 30-order.json
	    |   +-- multi_order
	    |       |-- 10-clients.json
	    |       |-- 20-items.json
	    |       +-- 30-orders.json
	    |-- ts_orders.rb
	    |-- test_single_order.rb
	    +-- test_multi_orders.rb
```

### Data Files

Each file should be an object with named records to be inserted, `10-clients.json` would look like this:

```json
{
	"acme_corp": {
		"name": "ACME Corp.",
		"address": "100 Main St."
	}
}
```

This way a record can be retreived from the FixtureData object by name:

```ruby
acme_corp = $fixture_data['clients']['acme_corp']
```

When data is loaded the `ObjectId`s are stored and can be queried:

```ruby
acme_id = acme_corp['_id']
```

You can check if a collection was loaded:

```ruby
$fixture_data.contains?('clients')
```

### ObjectID Tokens

The json files can contain special tokens, here's a sample order file:

```json
{
	"acme_order_101": {
		"client_order_id": "$oid.to_s",
		"package_id": "$oid<acme-package-400>.to_s"
		"client_ref": "$oid<clients.acme_corp>",
		"items": [ "$oid<items.sku_100>", "$oid<items.sku_200>"],
		"total": 301.24
	},
	"acme_order_102": {
		"client_order_id": "$oid.to_s",
		"package_id": "$oid<acme-package-400>.to_s"
		"client_ref": "$oid<clients.acme_corp>",
		"items": [ "$oid<items.sku_300>", "$oid<items.sku_400>"],
		"total": 301.24
	}
}
```

The token `$oid` can be use to reference or generate new `ObjectId`s. To reference an record id
from another collection use the `$oid<collection_name.record_name>`. If you add `.to_s` at the end
it will be stored as a string rather than an `ObjectId`. If no reference is given, then a new
ObjectID is generated, such as `$oid` or `$oid.to_s`, and if not found it's created and stored, in
the case of `$oid<acme-package-400>`.

The `ObjectID`s can also be fetched by name in ruby:

```ruby
acme_101 = $fixture_data.oid('orders.acme_order_101')
acme_package = $fixture_data.oid('acme-package-400')
```

**WARNING** IDs are stored in the order they are parsed, so if you reference an ID make sure it was
loaded before it's reference otherwise it will create a new one, and not match as expected. In our
example we load clients, then items, and finally orders. because order contain clients and items.

### Date Tokens

Date tokens are also useful to create an reference just like `ObjectId`s. Here's our items file:

```json
{
	"sku_100": {
		"name": "Scooter",
		"released": "$isodate('1999-12-30T13:24:44.252-08:00')",
		"available": "$isodate<toys-avail>.format('%a %b %e, %Y')",
		"created": "$isodate<scooter-add_date>",
		"updated": "$isodate<scooter-add_date>"
	}
}
```

Just like `$oid` the token `$isodate` will be replaced by a `Time` object with todays date.
This date can be referenced and formatted as string or a custom date used given iso8601 format.

### Options

To change the fixtures directory or prevent collections from being dropped use the following options:

```ruby
$fixture_data = HawkPrime::FixtureData.new($db, directory: 'test/data', drop_before: false)
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fixturedata', :git => "git://github.com/hawkprime/ruby-fixturedata.git"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fixturedata

## Release Notes

### 1.0.0

* Initial version
