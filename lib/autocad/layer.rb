module Autocad
  class Layer < Element
    # @rbs return String -- the name of the layer
    def name
      ole_obj.name
    end

    # set the name of the layer
    # @rbs name: String
    # @rbs return void
    def name=(name)
      ole_obj.name = name
    end

    def description
      ole_obj.description
    end

    #  is the layer the active layer
    # @rbs return bool
    def active?
      drawing.active_layer_name == name
    end

    # Activates the current layer by setting it as the active layer in the drawing.
    # This method assigns the current layer's OLE object to the ActiveLayer property of the drawing's OLE object.
    #
    # @rbs return void
    def activate
      drawing.ole_obj.ActiveLayer = ole_obj
    end

    # @rbs return bool
    def frozen?
      ole_obj.Freeze
    end

    #  freeze the layer - entities on layer are invisible and wont be
    #  regenerated
    def freeze
      ole_obj.Freeze = true
    end

    #  unfreeze the layer
    def unfreeze
      ole_obj.Freeze = false
    end

    # @rbs return bool
    def thawed?
      !frozen?
    end

    alias_method :thaw, :unfreeze

    # lock the layer - entities on layer can't be changed
    def lock
      ole_obj.Lock = true
    end

    # unlock the layer
    def unlock
      ole_obj.Lock = false
    end

    # @rbs return bool -- true if layer is locked
    def locked?
      ole_obj.Lock
    end

    def visible?
      ole_obj.Visible
    end

    def visible=(vis)
      ole_obj.Visible = vis
    end

    #  turn on the layer.
    #
    def turn_on
      ole_obj.LayerOn = true
    end

    def turn_off
      ole_obj.LayerOn = false
    end

    # @rbs return bool
    def on?
      ole_obj.LayerOn
    end

    def delete
      ole_obj.Delete
    rescue => e
      raise Autocad::Error.new("Error deleting layer #{name} #{e}")
    end

    def linetype=(ltname)
      found_lt = app.current_drawing.linetypes.find { |lt| lt.name == ltname }

      app.current_drawing.ole_obj.Linetypes.Load(ltname, ltname) unless found_lt

      ole_obj.Linetype = ltname
    rescue => e
      raise Autocad::Error.new("Error setting linetype of layer #{name} : #{e}")
    end
  end
end
