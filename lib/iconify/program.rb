module Iconify

class Program
  def initialize(argv)
    if argv.size < 1
      STDERR.puts "arg"
      exit 1
    end
    @argv = argv
    @status_icon = CommandStatusIcon.new(argv[0])
    @terminal_window = TerminalWindow.new(argv)
    @terminal_window.signal_connect('changed') do
      @status_icon.set_state(@terminal_window.state)
      @terminal_window.icon = @status_icon.pixbuf
    end
    @terminal_window.show_all
    @terminal_window.hide

    @status_icon.signal_connect("activate") do
      if @terminal_window.visible?
        @terminal_window.hide
      else
        @terminal_window.show
      end
    end
  end

  def run
    @terminal_window.exec
    Gtk.main
  end
end

end
