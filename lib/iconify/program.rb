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
    @terminal_window.signal_connect('delete-event') do
      if @status_icon.embedded?
        @terminal_window.hide
      else
        run_dialog("The status icon is not embedded in a notification area. The window cannot be hidden.")
      end
      true # do not close
    end
    @terminal_window.signal_connect('changed') do
      @status_icon.set_state(@terminal_window.state)
      @terminal_window.icon = @status_icon.pixbuf
    end
    @terminal_window.show_all
    GLib::Timeout.add(500) do
      if @status_icon.embedded?
        @terminal_window.hide
      else
        run_dialog("Iconify has detected its status icon is not embedded in a notification area. The window cannot be hidden.")
      end
      false # one time
    end

    @status_icon.signal_connect("activate") do
      if @terminal_window.visible? && @status_icon.embedded?
        @terminal_window.hide
      else
        @terminal_window.show
      end
    end
  end

  def run_dialog(message)
    dialog = Gtk::MessageDialog.new(@terminal_window,
                                    Gtk::Dialog::DESTROY_WITH_PARENT,
                                    Gtk::MessageDialog::QUESTION,
                                    Gtk::MessageDialog::BUTTONS_CLOSE,
                                    message)
    dialog.run
    dialog.destroy
  end

  def run
    @terminal_window.exec
    Gtk.main
  end
end

end
