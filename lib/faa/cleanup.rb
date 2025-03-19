# frozen_string_literal: true

module Faa
  # returns the project_dir from Documents folder
  def self.project_dir #: Pathname
    Pathname.new("c:/Users/Dominic E Sisneros/OneDrive - Federal Aviation Administration/Documents/work/projects")
  end

  # returns the rtir project dir
  def self.rtr_dir #: Pathname
    project_dir / "rtir"
  end

  # returns the nexcom_dir project folder
  def self.nexcom_dir #: Pathname
    project_dir / "nexcom/dominic"
  end

  module Cleanup
    # Removes the text "TRANSLATION" and removes the border in model space
    # and deletes the title block

    def get_title_attributes

      block_refs = block_reference_selection_set
      title_block = block_refs.find do |br|
        br.name.casecmp?('faatitle')
      end

      return unless title_block

      title_block.attributes_hash

    end
    
    def cleanup_model
      to_model_space
      remove_translation_text
      title_block = model_block_references.find { it.name == 'TITLEB' }
      border = model_block_references.find { it.name == 'border' }
      border&.delete
      title_objs = title_block.explode if title_block
      if title_objs
        title_objs.each do |o|
          o.delete
        rescue StandardError
          nil
        end
      end
      title_block.delete if title_block
      regen
      app.zoom_extents
    end

    # Adds the faaborder to layout
    # @rbs return BlockReference -- add faaDborder
    def add_title_block(scale: 1.0) #: BlockReference
      path = app.support_path_files.find { |f| f.basename.to_s == 'faaDborder.dwg' }
      return unless path

      layout = paper_space_layout
      block = layout.add_block_reference(path, pt: [0, 0, 0], scale: scale)
      regen
      block
    end

    # after deleting title block in model space, asks you to select a region to
    # cleanup the rest of title block (attributes)
    def cleanup_title_block
      to_model_space
      prompt('Select the region of title block to delete')
      get_region
      ss = create_selection_set('_atts_')
      ss.select_on_screen
      ss.each { |o| o.delete(false) }
      ss.delete
      regen
      app.zoom_extents
    rescue StandardError
      nil
    end

    def fix_layout
      ps = paper_space
      ps.clear_pviewports
      layout = paper_space_layout
      layout.copy_plot_configuration pdf_plot_config
      pv = ps.add_pv_viewport([17.5, 11.0], width: 32.0, height: 21.0) # center of title block
      pv.on
      # layout.add_pviewport
      to_paper_space
      regen
      ole_obj.MSpace = true
      app.zoom_extents
      ole_obj.MSpace = false
      app.zoom_extents
      layout.update(plot_type: :layout)
      nil
      # to_paper_space
      # ole_obj.MSpace = true
      # app.zoom_extents
      # ole_obj.MSpace = false
      # app.zoom_extents
      # ole_obj.MSpace = false
      # ole_obj.MSpace = false
    end

    def faa_title_block
      block_references.find { |b| b.name == 'faatitle' }
    end

    def remove_translation_text
      objs = select_text_containing('*TRANSLATION*')
      objs.each { |o| o.delete }
      app.zoom_extents
    end
  end
end

module Autocad
  class Drawing
    include Faa::Cleanup
  end
end
