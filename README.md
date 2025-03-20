# Autocad

A Ruby library for automating AutoCAD operations through the COM interface (version 0.5).

## Features

- Create, open, and manipulate AutoCAD drawings
- Work with layers, blocks, text, and other drawing elements
- Support for symbolic color names through ACAD::COLOR constants
- Selection sets for filtering and manipulating objects
- PDF export capabilities
- Event handling for AutoCAD events

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'autocad', '~> 0.5'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install autocad
```

## Usage

### Basic Operations

```ruby
# Start AutoCAD and create a new drawing
Autocad.run do |app|
  drawing = app.new_drawing("test.dwg")
  
  # Create a new layer with a color
  layer = drawing.create_layer("MyLayer", ACAD::COLOR::RED)
  
  # Switch to model space
  drawing.to_model_space
  
  # Add a line to the drawing
  model = drawing.model_space
  pt1 = Point3d(0, 0, 0)
  pt2 = Point3d(10, 10, 0)
  line = model.add_line(pt1, pt2)
  
  # Save and close the drawing
  drawing.save
  drawing.close
end
```

### Working with Colors

```ruby
# Colors can be specified in multiple ways:
layer.color = ACAD::COLOR::BLUE       # Using constants
layer.color = :green                  # Using symbols
layer.color = "RED"                   # Using strings
layer.color = 1                       # Using AutoCAD color indices
```

### Working with Layers

```ruby
# Create a layer
layer = drawing.create_layer("NewLayer", :blue)

# Set the active layer
drawing.active_layer = layer

# Iterate through all layers
drawing.layers.each do |layer|
  puts "Layer: #{layer.name}, Color: #{layer.color_name}"
end
```

### Working with Selection Sets

```ruby
# Create a selection set
ss = drawing.create_selection_set("MySelection")

# Filter for specific objects
ss.filter do |f|
  f.and(f.model_space, f.block_reference)
end

# Select objects
ss.select

# Process selected objects
ss.each do |obj|
  puts obj.inspect
end
```

### Exporting to PDF

```ruby
# Export the current drawing to PDF
drawing.save_as_pdf(dir: "output")

# Batch convert multiple drawings
Autocad.with_drawings(["drawing1.dwg", "drawing2.dwg"], read_only: true) do |drawing|
  drawing.save_as_pdf(dir: "output")
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dsisnero/autocad. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/dsisnero/autocad/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Autocad project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dsisnero/autocad/blob/main/CODE_OF_CONDUCT.md).
