#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "autocad"

# You can add fixtures and/or initialization code here to make experimenting
# with your gem easier. You can also use a different console, if you like.

app = Autocad::App.new
drawing = app.current_drawing
pc = drawing.create_pdf_plot_configuration
binding.irb
pc.display_setup
