# Schematist

[![Gem Version](https://badge.fury.io/rb/schematist.svg)](https://rubygems.org/gems/schematist)
[![Gem Downloads](https://img.shields.io/gem/dt/schematist)](https://rubygems.org/gems/schematist)
[![codecov](https://codecov.io/gh/crmne/schematist/branch/main/graph/badge.svg)](https://codecov.io/gh/crmne/schematist)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

A Ruby DSL for creating JSON schemas with a clean, Rails-inspired API. Emits Draft 2020-12 documents and depends on nothing.

**Formerly `RubyLLM::Schema`.** The gem was renamed in 1.0 because it was never about LLMs. See [Migrating from ruby_llm-schema](#migrating-from-ruby_llm-schema).

Originally created by [Daniel Friis](https://github.com/danielfriis).

## Use Cases

JSON Schema is useful wherever Ruby code needs to describe structured data in a portable format.

Some ideal use cases:

- Defining API request and response shapes
- Describing configuration files or structured payloads
- Sharing validation contracts across systems
- Generating structured output schemas for LLM workflows
- Defining structured parameters for RubyLLM tools

### Simple Example

```ruby
class PersonSchema < Schematist::Schema
  string :name, description: "Person's full name"
  number :age, description: "Age in years", minimum: 0, maximum: 120
  boolean :active, required: false

  object :address do
    string :street
    string :city
    string :country, required: false
  end

  array :tags, of: :string, description: "User tags"

  array :contacts do
    object do
      string :email, format: "email"
      string :phone, required: false
    end
  end

  any_of :status do
    string enum: ["active", "pending", "inactive"]
    null
  end
end

# Usage
schema = PersonSchema.new
puts schema.to_json
```

### RubyLLM structured output

```ruby
class PersonSchema < Schematist::Schema
  string :name, description: "Person's full name"
  integer :age, description: "Person's age in years"
  string :city, required: false, description: "City where they live"
end

# Use it natively with RubyLLM
chat     = RubyLLM.chat
response = chat.with_schema(PersonSchema)
               .ask("Generate a person named Alice who is 30 years old and lives in New York")

# The response is automatically parsed from JSON
puts response.content # => {"name" => "Alice", "age" => 30}
puts response.content.class # => Hash
```

### RubyLLM tools

RubyLLM tools can use schema classes for structured parameters. This is useful when the same argument shape is shared across tools or elsewhere in your app.

```ruby
class SearchParams < Schematist::Schema
  string :query, description: "Search query"
  integer :limit, required: false, description: "Maximum results"
end

class SearchDocuments < RubyLLM::Tool
  desc "Searches internal documents"
  params SearchParams

  def execute(query:, limit: 10)
    DocumentSearch.call(query:, limit:)
  end
end
```

For tool-specific parameters, define the schema inline with `params do ... end`.

```ruby
class Weather < RubyLLM::Tool
  desc "Gets current weather"

  params do
    string :city, description: "City name"
    string :units, enum: %w[celsius fahrenheit], required: false
  end

  def execute(city:, units: "celsius")
    WeatherAPI.current(city:, units:)
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'schematist'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install schematist
```

## Usage

Three approaches for creating schemas:

### Class Inheritance

```ruby
class PersonSchema < Schematist::Schema
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false

  object :address do
    string :street
    string :city
  end

  array :tags, of: :string
end

schema = PersonSchema.new
puts schema.to_json
```

### Factory Method

```ruby
PersonSchema = Schematist::Schema.create do
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false

  object :address do
    string :street
    string :city
  end

  array :tags, of: :string
end

schema = PersonSchema.new
puts schema.to_json
```

### Global Helper

```ruby
require 'schematist'
include Schematist::Helpers

person_schema = schema "PersonData", description: "A person object" do
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false

  object :address do
    string :street
    string :city
  end

  array :tags, of: :string
end

puts person_schema.to_json
```

## Schema Property Types

A schema is a collection of properties, which can be of different types. Each type has its own set of properties you can set.

All property types can (along with the required `name` key) be set with a `description` and a `required` flag (default is `true`).

```ruby
string :name, description: "Person's full name"
number :age, description: "Person's age", required: false
boolean :is_active, description: "Whether the person is active"
null :placeholder, description: "A placeholder property"
```

### Annotations

Annotations describe a schema for humans and tools. They carry no validation weight.

Supported annotations are `title`, `description`, `default`, `examples`, `deprecated`, `read_only`, and `write_only`.

Short annotations read well as keyword arguments:

```ruby
string :email,
  title: "Email address",
  description: "Primary contact email",
  default: "user@example.com",
  examples: ["alice@example.com"],
  deprecated: false,
  read_only: false,
  write_only: false
```

Longer ones read better inside the block, where they annotate the enclosing schema:

```ruby
object :account do
  title "Account"
  description "Billing account metadata used for invoices."
  examples [{ id: "acct_123", status: "active" }]

  string :id
  string :status
end
```

They work at the root of a schema class and inside `define` too. When the same annotation is given both as a keyword and inside the block, the keyword wins.

⚠️ Please consult the LLM provider documentation for any limitations or restrictions. For example, as of now, OpenAI requires all properties to be required. In that case, you can use the `any_of` method to make a property optional.

```ruby
any_of :name, description: "Person's full name" do
  string
  null
end
```

### Strings

String types support the following properties:

- `enum`: an array of allowed values (e.g. `enum: ["on", "off"]`)
- `const`: the single allowed value (e.g. `const: "admin"`)
- `pattern`: a regex pattern (e.g. `pattern: "\\d+"`)
- `format`: a format string (e.g. `format: "email"`)
- `min_length`: the minimum length of the string (e.g. `min_length: 3`)
- `max_length`: the maximum length of the string (e.g. `max_length: 10`)

Please consult the LLM provider documentation for the available formats and patterns.

```ruby
string :name, description: "Person's full name"
string :email, format: "email"
string :phone, pattern: "\\d+"
string :status, enum: ["on", "off"]
string :role, const: "admin"
string :code, min_length: 3, max_length: 10
```

### Encoded String Content

Strings that carry encoded content can describe what is inside them.

- `content_encoding`: how the string is encoded (e.g. `content_encoding: "base64"`)
- `content_media_type`: the media type of the decoded content (e.g. `content_media_type: "application/json"`)
- `content_schema`: a block describing the schema of the decoded content

```ruby
string :payload, content_encoding: "base64", content_media_type: "application/json" do
  content_schema do
    object do
      string :name
      string :email
    end
  end
end
```

### Numbers

Number and integer types support the following properties:

- `enum`: an array of allowed numeric values (e.g. `enum: [0, 1, 2]`)
- `const`: the single allowed value (e.g. `const: 1`)
- `multiple_of`: a multiple of the number (e.g. `multiple_of: 0.01`)
- `minimum`: the minimum value of the number (e.g. `minimum: 0`)
- `maximum`: the maximum value of the number (e.g. `maximum: 100`)
- `greater_than`: an exclusive minimum (e.g. `greater_than: 0`)
- `less_than`: an exclusive maximum (e.g. `less_than: 100`)

```ruby
number :price, minimum: 0, maximum: 100
number :score, greater_than: 0, less_than: 100
number :amount, multiple_of: 0.01
integer :level, enum: [0, 1, 2]
```

### Booleans

```ruby
boolean :is_active
boolean :accepted_terms, const: true
```

Boolean types only support `const`, the single allowed value.

### Null

```ruby
null :placeholder
```

Null types doesn't support any additional properties.

### Arrays

An array is a list of items. You can set the type of the items in the array with the `of` option or by passing a block with the `object` method.

An array can have a `min_items` and `max_items` option to set the minimum and maximum number of items in the array.

```ruby
array :tags, of: :string              # Array of strings
array :scores, of: :number            # Array of numbers
array :items, min_items: 1, max_items: 10  # Array with size constraints

array :items do                       # Array of objects
  object do
    string :name
    number :price
  end
end

array :tags, of: :string, unique: true  # No duplicate items

array :scores do                      # At least one score of 10 or more
  integer

  contains min: 1 do
    integer minimum: 10
  end
end
```

### Tuples

A tuple is a fixed-length array where each position has its own schema. It emits `prefixItems` along with matching `minItems` and `maxItems`.

```ruby
tuple :coordinates do
  number description: "Latitude"
  number description: "Longitude"
end
```

### Objects

Objects types expect a block with the properties of the object.

```ruby
object :user do
  string :name
  number :age
end

object :settings, description: "User preferences" do
  boolean :notifications
  string :theme, enum: ["light", "dark"]
end
```

### Object Key Constraints

Objects can constrain how many properties they carry, and what their keys look like.

- `min_properties` / `max_properties`: how many properties the object may have
- `keys`: a schema every property name must match, as JSON Schema `propertyNames`
- `keys_matching`: a schema for the properties whose names match a pattern, as JSON Schema `patternProperties`

```ruby
object :metadata, min_properties: 1, max_properties: 10 do
  keys do
    string pattern: "^[a-z_]+$"
  end

  keys_matching(/^x-/) do
    string
  end

  keys_matching(/^count_/) do
    integer minimum: 0
  end
end
```

`keys` and `keys_matching` also work at the root of a schema class and inside `define`.

### Union Types (anyOf)

Union types are a way to specify that a property can be one of several types.

```ruby
any_of :value do
  string
  number
  null
end

any_of :identifier do
  string description: "Username"
  number description: "User ID"
end
```

### Composition (oneOf, allOf, not)

`one_of` matches exactly one of the given schemas, `all_of` matches all of them, and `none_of` matches none of them.

```ruby
one_of :payment do
  object do
    string :card_number
  end

  object do
    string :iban
  end
end

all_of :account do
  object do
    string :id
  end

  object do
    string :status
  end
end

none_of :status do
  string enum: ["deleted"]
end
```

`none_of` with a single schema emits `not: { ... }`. With several, it emits `not: { anyOf: [...] }`.

### Unevaluated Properties and Items

`unevaluated_properties` and `unevaluated_items` constrain what is left over after composition, references, and conditionals have had their say. They are most useful on `all_of`, where `additional_properties` cannot see across the branches.

```ruby
all_of :person, unevaluated_properties: false do
  object do
    string :name
  end

  object do
    integer :age
  end
end

object :profile, of: :person, unevaluated_properties: false
array :values, of: :integer, unevaluated_items: false
```

### Runtime Values

Any schema value can be a proc, resolved when the schema is rendered. That lets one schema class produce different documents per instance — useful when an enum comes from the database.

```ruby
class RoleSchema < Schematist::Schema
  description -> { "Roles available to #{@account.name}" }

  string :role, enum: -> { @account.roles.pluck(:name) }

  def initialize(account:)
    super()
    @account = account
  end
end

RoleSchema.new(account: account).to_json_schema
```

A proc with no arguments is evaluated in the instance's context, so it can read instance variables. A proc that takes one argument receives the schema instance instead.

### Boolean and Raw Schemas

JSON Schema allows `true` and `false` in place of a schema object: `true` accepts every value, `false` accepts none. Inside a block, `any_schema` and `no_schema` emit them.

```ruby
any_of :value do
  any_schema
  string
end
```

When you need a keyword this DSL doesn't cover, `raw` emits a fragment verbatim.

```ruby
raw :role, { type: "string", const: "admin" }

any_of :value do
  raw type: "string", const: "admin"
  integer
end
```

### Schema Definitions and References

You can define sub-schemas and reference them in other schemas, or reference the root schema to generate recursive schemas.

```ruby
class MySchema < Schematist::Schema
  define :location do
    string :latitude
    string :longitude
  end

  # Using a reference in an array
  array :coordinates, of: :location

  # Using a reference in an object via the `reference` option
  object :home_location, reference: :location

  # Using a reference in an object via block
  object :user do
    reference :location
  end

  # Using a reference to the root schema
  object :ui_schema do
    string :element, enum: ["input", "button"]
    string :label
    object :sub_schema, reference: :root
  end
end
```

### Core Keywords

Use core keywords when a schema or subschema needs an identifier, anchor, comment, dynamic reference, or vocabulary declaration.

```ruby
class Node < Schematist::Schema
  id "https://example.com/schemas/node"
  comment "Internal note"
  dynamic_anchor "node"
  vocabulary "https://json-schema.org/draft/2020-12/vocab/core" => true

  define :address do
    anchor "address"

    string :street
  end

  object :child do
    dynamic_ref "#node"
  end
end
```

`dynamic_ref` and `dynamic_anchor` are emitted verbatim. Their recursive resolution is the validator's job; this gem does not expand or interpret them.

### Nested Schemas

You can embed existing schema classes directly within objects or arrays for reusable schema composition.

```ruby
class PersonSchema < Schematist::Schema
  string :name
  integer :age
end

class CompanySchema < Schematist::Schema
  # Using 'of' parameter
  object :ceo, of: PersonSchema
  array :employees, of: PersonSchema

  # Using Schema.new in block
  object :founder do
    PersonSchema.new
  end
end

schema = CompanySchema.new
schema.to_json_schema
# =>
# {
#    "$schema":"https://json-schema.org/draft/2020-12/schema",
#    "title":"CompanySchema",
#    "type":"object",
#    "properties":{
#       "ceo":{
#          "type":"object",
#          "properties":{
#             "name":{"type":"string"},
#             "age":{"type":"integer"}
#          },
#          "required":["name","age"],
#          "additionalProperties":false
#       },
#       "employees":{
#          "type":"array",
#          "items":{
#             "type":"object",
#             "properties":{
#                "name":{"type":"string"},
#                "age":{"type":"integer"}
#             },
#             "required":["name","age"],
#             "additionalProperties":false
#          }
#       },
#       "founder":{
#          "type":"object",
#          "properties":{
#             "name":{"type":"string"},
#             "age":{"type":"integer"}
#          },
#          "required":["name","age"],
#          "additionalProperties":false
#       }
#    },
#    "required":["ceo","employees","founder"],
#    "additionalProperties":false
# }
```

### Dependencies

Use `requires:` inline or `dependent` block to express that the presence of one property requires others. Maps to [`dependentRequired`](https://json-schema.org/understanding-json-schema/reference/conditionals#dependentRequired) (Draft 2019-09) and [`dependentSchemas`](https://json-schema.org/understanding-json-schema/reference/conditionals#dependentSchemas) (Draft 2019-09). Check your provider's documentation for compatibility.

```ruby
class PaymentSchema < Schematist::Schema
  string :name
  number :credit_card, required: false, requires: %i[billing_address cvv]
  string :billing_address, required: false
  string :cvv, required: false
end
```

Use a `dependent` block when you also need validations — this upgrades the output to `dependentSchemas`:

```ruby
dependent :credit_card do
  requires :billing_address
  validates :billing_address, type: :string, min_length: 1
end
```

### Conditionals

Use `given` to add [JSON Schema `if`/`then`/`else`](https://json-schema.org/understanding-json-schema/reference/conditionals#ifthenelse) (Draft 7) rules. Condition values are automatically coerced: strings → `const`, arrays → `enum`, regexps → `pattern`, hashes → raw schema.

```ruby
class OrderSchema < Schematist::Schema
  string :status, enum: ["pending", "shipped", "cancelled"]
  string :tracking_number, required: false
  string :cancellation_reason, required: false

  given status: "shipped" do
    requires :tracking_number
  end

  given status: "cancelled" do
    requires :cancellation_reason
    validates :cancellation_reason, type: :string, min_length: 1
  end
end
```

`validates` supports: `type:`, `not_value:`, `min_length:`, `max_length:`, `pattern:` (string or regexp), `enum:`, `const:`, `minimum:`, `maximum:`.

Use `otherwise` for an `else` branch:

```ruby
given domestic: true do
  requires :state

  otherwise do
    requires :country
  end
end
```

Conditions propagate through nested schemas via `of:`.

## JSON Output

`to_json_schema` returns a Draft 2020-12 JSON Schema document with string keys, ready to hand to any JSON Schema validator.

```ruby
schema = PersonSchema.new
schema.to_json_schema
# => {
#   "$schema" => "https://json-schema.org/draft/2020-12/schema",
#   "title" => "PersonSchema",
#   "type" => "object",
#   "properties" => { ... },
#   "required" => [...],
#   "additionalProperties" => false
# }

puts schema.to_json  # Pretty JSON string of the same document
```

The schema name maps to `title`. Provider-only keys are not part of the document — `strict` was an OpenAI `response_format` flag, not a JSON Schema keyword, and has been removed. Set it where you build the request.

### Migrating from ruby_llm-schema

Schematist was called `ruby_llm-schema`. The old name put a general-purpose JSON Schema DSL inside another gem's namespace and implied it only made sense alongside an LLM client, which was never true.

Update the gem, then the constants:

```ruby
gem 'schematist'                      # was: gem 'ruby_llm-schema'

class PersonSchema < Schematist::Schema   # was: RubyLLM::Schema
end

include Schematist::Helpers               # was: RubyLLM::Helpers
```

Errors moved up a level with the rename — `Schematist::ValidationError`, not `RubyLLM::Schema::ValidationError`. `strict` is gone; see below.

### Migrating from the provider envelope

`to_json_schema` used to return a provider envelope — `{name:, description:, schema:, strict:}`, the shape OpenAI's `response_format` expects. That envelope is gone. Building it is the provider client's job, not this gem's.

If you were reaching into `[:schema]` to get at the document, drop the digging — `to_json_schema` now returns the document itself. Note its keys are strings, not symbols:

```ruby
schema.to_json_schema[:schema][:properties]   # before
schema.to_json_schema["properties"]           # now
```

If you need the envelope for a provider that expects it, build it where you send it:

```ruby
{
  name: "PersonSchema",
  schema: PersonSchema.new.to_json_schema,
  strict: true
}
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
