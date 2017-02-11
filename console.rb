require 'ffi-ncurses'
include FFI::NCurses


class Console
  def initialize
    ENV['TERM'] ||= 'ansi'
    begin
      initscr
      curs_set 0
      #keypad(FFI::NCurses.stdscr, true)
    ensure
      endwin
    end
    at_exit { endwin }
  end

  def self.printf(string)
    addstr(string)
    refresh
  end

  def self.puts(string = '')
    addstr("#{string}\n")
    refresh
  end

end