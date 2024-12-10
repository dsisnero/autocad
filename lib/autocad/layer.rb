module Autocad
  class Layer < Element
    def name
      ole_obj.name
    end

    def description
      ole_obj.description
    end

    def lock(lk = true)
      ole_obj.Lock = lk
    rescue StandardError
      raise Autocad::Error.new("Error locking layer #{name}")
    end

    def visible?
      ole_obj.Visible
    end

    def visible=(vis)
      ole_obj.Visible = vis
    end

    def delete
      ole_obj.Delete
    rescue StandardError => e
      raise Autocad::Error.new("Error deleting layer #{name} #{e}")
    end

    def linetype=(ltname)
      found_lt = app.current_drawing.linetypes.find { |lt| lt.name == ltname }

      app.current_drawing.ole_obj.Linetypes.Load(ltname, ltname) unless found_lt

      ole_obj.Linetype = ltname
    rescue StandardError => e
      raise Autocad::Error.new("Error setting linetype of layer #{name} : #{e}")
    end
  end
end
