require 'autocad'

Autocad.run do |app|
  drawing = app.new_drawing('test_drawing.dwg')
  d = app.active_drawing

  template_path = app.template_dwg_path

  puts template_path

  support_paths = app.support_paths

  puts "support_paths\n#{support_paths}"

  printer_config_paths = app.printer_config_paths
  puts "printer_config_paths: #{printer_config_paths}"
  puts 'plot configs'
  app.plot_configs do |pl|
    puts pl
  end

  enum = app.plot_configs

  require 'debug'
  binding.break
end
