require 'gtk2'
require 'vte'

require "iconify/version"
require "iconify/program"

module Iconify

class TerminalWindow < Gtk::Window
  include Gtk

  type_register
  signal_new('changed', GLib::Signal::ACTION, nil, nil)

  attr_reader :state

  def initialize(argv)
    super()

    @argv = argv

    @terminal = Vte::Terminal.new

    self.title = "iconify - #{argv[0]}"

    @state = :stopped

    vbox = VBox.new
    hbox = HButtonBox.new
    rerun_button = Button.new("Rerun")
    rerun_button.signal_connect('clicked') do
      self.exec
    end
    signal_connect('changed') do
      rerun_button.sensitive = (@state == :stopped)
    end

    kill_button = Button.new("Kill")
    kill_button.signal_connect('clicked') do 
      Process.kill("KILL", @pid) if @pid
    end
    signal_connect('changed') do
      kill_button.sensitive = (@state == :running)
    end

    quit_button = Button.new("Quit")
    quit_button.signal_connect('clicked') do
      Gtk.main_quit
    end
    hbox.pack_start(rerun_button)
    hbox.pack_start(kill_button)
    hbox.pack_start(quit_button)
    vbox.pack_start(hbox, false)
    vbox.pack_start(@terminal)

    add vbox

    @terminal.signal_connect('child-exited') do
      @state = :stopped
      @pid = nil
      rerun_button.sensitive = true
      signal_emit('changed')
    end
  end

  def exec
    @pid = @terminal.fork_command(argv: @argv)
    @state = :running
    signal_emit('changed')
  end

end

class CommandStatusIcon < Gtk::StatusIcon
  include Gtk

  def initialize(name)
    super()

    @name = name
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

    cr.set_source_rgb(0.8, 0.8, 0.8)
    cr.set_operator(Cairo::OPERATOR_SOURCE)
    cr.paint

    cr.set_source_rgb(*@background_color)
    cr.rounded_rectangle(1, 1, 62, 62, 15)
    cr.fill

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
