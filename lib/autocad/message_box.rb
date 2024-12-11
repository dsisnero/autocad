require 'fiddle/import'
require 'fiddle/types'

module WinAPI
  extend Fiddle::Importer
  dlload 'user32.dll'
  include Fiddle::BasicTypes
  include Fiddle::Win32Types

  typealias 'LPCWSTR', 'wchar_t*'

  extern 'int MessageBoxA(HWND, LPCSTR, LPCSTR, DWORD)'
  extern 'int MessageBoxW(HWND, LPCWSTR, LPCWSTR, DWORD)'
  # window handling
  extern 'HWND GetForegroundWindow()'
  extern 'int GetWindowText(HWND, char*, int)'
  extern 'int GetWindowTextLength(HWND)'

  def get_foreground_window
    GetForegroundWindow()
  end

  def self.get_text_of_active_window
    hwnd = GetForegroundWindow()
    buf_size = GetWindowTextLength(hwnd)
    str = ' ' * (buf_size + 1)
    res = GetWindowText(hwnd, str, str.length)
    str.encode(Encoding.default_external)
  end

  module MB
    OK = 1
    CANCEL = 1
    ABORT = 3
    RETRY = 4
    IGNORE = 5
    YES = 6
    NO = 7

    module ICON
      ERROR = 16
      QUESTION = 32
      INFORMATION = 64
      WARNING = 128
    end

    module BTN
      OK = 0
      OKCANCEL = 1
      ABORTRETRYIGNORE = 2
      YESNO = 4
    end
  end
end

# msgbox_yesno('Do you want to continue?') do |y|
#   if y
#     puts 'proceeding with ...'
#   else
#     puts 'cancelled ...'
#   end
# end
#
# msgbox('We are finished here')
#
# loop do
#   puts WinAPI.get_text_of_active_window
#   sleep 1
# end
module Kernel
  module_function

  # @rbs str: String
  # @rbs return String
  def L(str)
    str.encode('UTF-16LE')
  end

  # @example
  # msg_box_yesno("Do you want to continue") do |y|
  #  if y
  #    puts "proceeding"
  # else
  #   puts "cancelled"
  # end
  # end
  def msgbox_yesno(content, title: 'Alert')
    result = WinAPI::MessageBoxW(0, L(content), L(title), WinAPI::MB::BTN::YESNO) == WinAPI::MB::YES
    yield(result)
  end

  def msgbox(content, title: 'Alert')
    WinAPI::MessageBoxW(0, L(content), L(title), WinAPI::MB::BTN::OK)
  end
end

