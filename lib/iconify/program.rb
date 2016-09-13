require 'optparse'

module Iconify
  class Program
    include Gtk

    def initialize(argv)
      @start_minimized = false

      parse_args!(argv)

      @argv = argv
      @status_icon = CommandStatusIcon.new(argv[0])
      @terminal_window = TerminalWindow.new(argv)
      @terminal_window.signal_connect('delete-event') do
        if @status_icon.embedded?
          @terminal_window.hide
        else
          run_dialog('The status icon is not embedded in a notification area. The window cannot be hidden.')
        end
        true # do not close
      end
      @terminal_window.signal_connect('changed') do
        @status_icon.update(@terminal_window.state)
        @terminal_window.icon = @status_icon.pixbuf
      end
      @terminal_window.show_all
      GLib::Timeout.add(500) do
        if @start_minimized
          if @status_icon.embedded?
            @terminal_window.hide
          else
            run_dialog('Iconify has detected its status icon is not embedded in a notification area. The window cannot be hidden.')
          end
        end
        false # one time
      end

      @status_icon.signal_connect('activate') do
        if @terminal_window.visible? && @status_icon.embedded?
          @terminal_window.hide
        else
          @terminal_window.show
        end
      end
    end

    def parse_args!(argv)
      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: iconify [OPTIONS] COMMAND [ARGUMENTS...]'

        opts.on('-m', '--minimized', 'Start minimized') do |m|
          @start_minimized = m
        end
      end
      parser.parse!(argv)

      if argv.empty?
        STDERR.puts parser.banner
        exit 1
      end
    rescue OptionParser::InvalidOption => e
      STDERR.puts e
      exit 1
    end

    def run_dialog(message)
      dialog = MessageDialog.new(parent:  @terminal_window,
                                 flags:   DialogFlags::DESTROY_WITH_PARENT,
                                 type:    MessageType::QUESTION,
                                 buttons: ButtonsType::CLOSE,
                                 message: message)
      dialog.run
      dialog.destroy
    end

    def run
      @terminal_window.exec
      Gtk.main
    end
  end
end
