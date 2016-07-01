require 'gtk2'
require 'vte'

require "iconify/version"
require "iconify/program"

module Iconify

include Gtk

class TerminalWindow < Gtk::Window
  def initialize(status_icon, argv)
    super()

    @argv = argv

    @status_icon = status_icon
    @terminal = Vte::Terminal.new

    signal_connect('delete-event') do
      hide
    end

    @terminal.signal_connect('child-exited') do
      @status_icon.set_state(:stopped)
      @rerun_button.sensitive = true
    end

    vbox = VBox.new
    hbox = HButtonBox.new
    @rerun_button = Button.new("Rerun")
    @rerun_button.signal_connect('clicked') do
      self.exec
    end

    button2 = Button.new("Quit")
    button2.signal_connect('clicked') do
      Gtk.main_quit
    end
    hbox.pack_start(@rerun_button)
    hbox.pack_start(button2)
    vbox.pack_start(hbox, false)
    vbox.pack_start(@terminal)

    add vbox
  end

  def exec
    @terminal.fork_command(argv: @argv)
    @status_icon.set_state(:running)
    @rerun_button.sensitive = false
  end

end

class CommandStatusIcon < Gtk::StatusIcon
  def initialize(name)
    super()

    @name = name
    set_state(:stopped)
  end

  def set_state(state)
    case state
    when :running
      @background_color = [0.67, 1.0, 0.0]
      @foreground_color = [0.1, 0.1, 0.1]
    when :stopped
      @background_color = [192/255.0, 0.0, 0.0]
      @foreground_color = [0.9, 0.9, 0.9]
    else
      raise "unknown sate #{state}"
    end
    redraw
  end

  def redraw
    pixmap = Gdk::Pixmap.new(nil, 64, 64, 24)

    cr = pixmap.create_cairo_context

    cr.set_source_rgba(*@background_color, 1.0)
    cr.set_operator(Cairo::OPERATOR_SOURCE)
    cr.paint

    cr.set_font_size(24)
    cr.move_to(3, 64 / 2 + cr.font_extents.ascent / 2)
    cr.set_source_rgba(*@foreground_color, 1)
    cr.show_text(@name)

    cr.destroy

    buf = Gdk::Pixbuf.from_drawable(nil, pixmap, 0, 0, 64, 64)
    self.pixbuf = buf
  end

end

end
