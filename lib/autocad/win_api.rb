require 'fiddle'

module Autocad
  module WinAPI
    extend Fiddle::Importer
    dlload 'user32'

    extern 'int FindWindowA(void*, void*)'
    extern 'int GetWindowTextA(int, void*, int)'
    extern 'int SendMessageA(int, int, int, int)'

    # Find a window by class and title
    # @param window_class [String, nil] window class name
    # @param window_title [String, nil] window title
    # @return [Integer] window handle or 0 if not found
    def self.find_window(window_class, window_title)
      class_ptr = window_class ? Fiddle::Pointer[window_class.to_s] : 0
      title_ptr = window_title ? Fiddle::Pointer[window_title.to_s] : 0
      FindWindowA(class_ptr, title_ptr)
    end

    # Get window text
    # @param hwnd [Integer] window handle
    # @return [String] window text
    def self.get_window_text(hwnd)
      buffer = ' ' * 256
      buffer_ptr = Fiddle::Pointer[buffer]
      GetWindowTextA(hwnd, buffer_ptr, buffer.size)
      buffer.strip
    end

    # Send a key to a window
    # @param hwnd [Integer] window handle
    # @param key [Integer] virtual key code
    # @return [Integer] result
    def self.send_key_to_window(hwnd, key)
      # WM_KEYDOWN = 0x0100, WM_KEYUP = 0x0101
      SendMessageA(hwnd, 0x0100, key, 0) # Key down
      SendMessageA(hwnd, 0x0101, key, 0) # Key up
    end
  end
end
