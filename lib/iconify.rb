require 'gtk3'
require 'vte3'

require 'iconify/version'
require 'iconify/program'

module Iconify
  # メインウィンドウ
  class TerminalWindow < Gtk::Window
    include Gtk

    type_register
    signal_new('changed', GLib::Signal::ACTION, nil, nil)

    attr_reader :state

    # [String]
    def initialize(argv)
      super()

      @argv = argv
      @state = :stopped

      update_title

      @rerun_button = create_rerun_button
      @kill_button  = create_kill_button
      @quit_button  = create_quit_button
      @terminal     = create_vte_terminal

      layout
    end

    def layout
      vbox = Box.new(:vertical)
      hbox = ButtonBox.new(:horizontal)

      hbox.pack_start(@rerun_button)
      hbox.pack_start(@kill_button)
      hbox.pack_start(@quit_button)
      vbox.pack_start(hbox, expand: false)
      vbox.pack_start(@terminal, expand: true, fill: true)

      add vbox
    end

    def create_kill_button
      Button.new(label: 'Kill').tap do |kill_button|
        kill_button.signal_connect('clicked') do
          Process.kill('KILL', @pid) if @pid
        end
      end
    end

    def create_rerun_button
      Button.new(label: 'Rerun').tap do |rerun_button|
        rerun_button.signal_connect('clicked') do
          exec
        end
      end
    end

    def create_quit_button
      Button.new(label: 'Quit').tap do |quit_button|
        quit_button.signal_connect('clicked') do
          Gtk.main_quit
        end
      end
    end

    def update_title
      self.title = "iconify - #{@argv[0]}"
    end

    def changed
      @rerun_button.sensitive = (@state == :stopped)
      @kill_button.sensitive  = (@state == :running)

      signal_emit('changed')
    end

    def create_vte_terminal
      Vte::Terminal.new.tap do |t|
        t.font = Pango::FontDescription.new('monospace 14')
        t.set_size_request(t.char_width * 80, t.char_height * 24)
        t.cursor_blink_mode = Vte::CursorBlinkMode::OFF

        t.signal_connect('child-exited') do
          on_child_exited
        end
      end
    end

    def on_child_exited
      @state = :stopped
      @pid = nil
      @rerun_button.sensitive = true
      changed
    end

    def exec
      @pid = @terminal.spawn(argv: @argv)
      @state = :running
      changed
    end
  end

  # プログラム名を表示するステータスアイコン
  class CommandStatusIcon < Gtk::StatusIcon
    include Gtk
    include Cairo

    def initialize(name)
      super()

      @name = name
    end

    COLOR_SCHEME = {
      running: [[0.67, 1.0, 0.0], [0.1, 0.1, 0.1]],
      stopped: [[0.75, 0.0, 0.0], [0.9, 0.9, 0.9]]
    }.freeze

    def update(state)
      raise "unknown sate #{state}" unless COLOR_SCHEME.key?(state)

      @background_color, @foreground_color = COLOR_SCHEME[state]
      redraw
    end

    def using(destroyable)
      yield destroyable
      destroyable.destroy
    end

    def paint_background(cr)
      cr.save do
        cr.set_source_rgb(0.8, 0.8, 0.8)
        cr.set_operator(OPERATOR_SOURCE)
        cr.paint
      end
    end

    def fill_rounded_rectangle(cr)
      cr.save do
        cr.set_source_rgb(*@background_color)
        cr.rounded_rectangle(1, 1, 62, 62, 15)
        cr.fill
      end
    end

    def draw_name(cr)
      cr.save do
        cr.set_font_size(24)
        cr.move_to(3, 64 / 2 + cr.font_extents.ascent / 2)
        cr.set_source_rgba(*@foreground_color, 1)
        cr.show_text(@name)
      end
    end

    def redraw
      using ImageSurface.new(FORMAT_ARGB32, 64, 64) do |surface|
        using Context.new(surface) do |cr|
          paint_background(cr)
          fill_rounded_rectangle(cr)
          draw_name(cr)
        end

        self.pixbuf = surface.to_pixbuf(0, 0, 64, 64)
      end
    end
  end
end
