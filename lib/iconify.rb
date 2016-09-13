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
      @copy_button  = create_copy_button
      @paste_button = create_paste_button

      layout

      set_geometry_hints
    end

    def set_geometry_hints
      @terminal.realize
      @terminal.set_geometry_hints_for_window(self)
    end

    def layout
      vbox = Box.new(:vertical)
      toolbar = Toolbar.new

      toolbar.add(@rerun_button)
      toolbar.add(@kill_button)
      toolbar.add(SeparatorToolItem.new)
      toolbar.add(@copy_button)
      toolbar.add(@paste_button)
      toolbar.add(SeparatorToolItem.new)
      toolbar.add(@quit_button)
      vbox.pack_start(toolbar, expand: false)

      padding_box = Box.new(:vertical)
      padding_box.pack_start(@terminal, expand: true, fill: true)
      padding_box.border_width = 18
      override_background_color(StateFlags::NORMAL, COLORS[15])
      vbox.pack_start(padding_box, expand: true, fill: true)

      add vbox
    end

    def create_copy_button
      ToolButton.new(stock_id: Stock::COPY).tap do |b|
        b.tooltip_text = 'Copy'
        b.signal_connect('clicked') do
          @terminal.copy_clipboard
        end
      end
    end

    def create_paste_button
      ToolButton.new(stock_id: Stock::PASTE).tap do |b|
        b.tooltip_text = 'Paste'
        b.signal_connect('clicked') do
          @terminal.paste_clipboard
        end
      end
    end

    def create_kill_button
      ToolButton.new(label: 'Kill').tap do |b|
        b.icon_name = Stock::STOP
        b.tooltip_text = 'Stop the child process by sending the QUIT signal.'
        b.signal_connect('clicked') do
          Process.kill('KILL', @pid) if @pid
        end
      end
    end

    def create_rerun_button
      ToolButton.new(label: 'Rerun').tap do |b|
        b.icon_name = Stock::REFRESH
        b.tooltip_text = 'Rerun the program.'
        b.signal_connect('clicked') do
          exec
        end
      end
    end

    def create_quit_button
      ToolButton.new(label: 'Quit').tap do |b|
        b.icon_name = Stock::QUIT
        b.tooltip_text = 'Stop the program and quit.'
        b.signal_connect('clicked') do
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

      @copy_button.sensitive = @terminal.has_selection?

      signal_emit('changed')
    end

    # the shimbun color scheme
    COLORS = [[0x30, 0x30, 0x30],
              [0xbe, 0x11, 0x37],
              [0x29, 0x73, 0x2c],
              [0xc9, 0x5c, 0x26],
              [0x2a, 0x5a, 0xa2],
              [0xcd, 0x3a, 0x93],
              [0x07, 0x86, 0x92],
              [0xd0, 0xd0, 0xd0],
              [0x50, 0x50, 0x50],
              [0xe6, 0x2b, 0x5d],
              [0x40, 0x9e, 0x01],
              [0xec, 0x75, 0x42],
              [0x17, 0x7f, 0xe0],
              [0xe9, 0x53, 0xba],
              [0x00, 0xa9, 0xb2],
              [0xf2, 0xf2, 0xf2]]
             .map { |rgb| Gdk::RGBA.new(*rgb.map { |n| n.fdiv(255) }, 1.0) }

    def create_vte_terminal
      Vte::Terminal.new.tap do |t|
        t.font = Pango::FontDescription.new('monospace 14')
        t.set_size_request(t.char_width * 40, t.char_height * 12)
        t.set_size(80, 24)
        t.cursor_blink_mode = Vte::CursorBlinkMode::OFF
        t.set_colors(COLORS[0], COLORS[15], COLORS)

        t.signal_connect('child-exited') do
          on_child_exited
        end
        t.signal_connect('selection-changed') do
          changed
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
