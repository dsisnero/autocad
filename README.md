# Autocad

Ruby gem for automating AutoCAD operations through the COM interface.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'autocad'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install autocad
```

## Requirements

- Windows operating system
- AutoCAD installed
- Ruby 3.0 or higher

## Usage

```ruby
require 'autocad'

# Open AutoCAD and work with a drawing
Autocad.run do |app|
  drawing = app.open_drawing('path/to/drawing.dwg')
  
  # Get user input for a point
  point = app.get_point(prompt: "Select a point")
  
  # Save as PDF
  drawing.save_as_pdf(dir: 'output')
end
```

### Batch Processing

```ruby
# Process all drawings in a directory
Autocad.with_drawings_in_dir("drawings") do |drawing|
  drawing.save_as_pdf
end
```

## Testing

The gem includes two types of tests:

```
# Run unit tests (no AutoCAD required)
bundle exec rake test

# Run UI tests (requires AutoCAD)
bundle exec rake test:ui
```

UI tests require a working AutoCAD installation and will be skipped in CI environments unless specifically configured.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dsisnero/autocad. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/dsisnero/autocad/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Autocad project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dsisnero/autocad/blob/main/CODE_OF_CONDUCT.md).
