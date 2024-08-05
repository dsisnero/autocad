require "autocad"

Autocad.with_drawings_in_dir("drawings") do |drawing|
  drawing.save_as_pdf
end
