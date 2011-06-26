module Cxxproject
  module Utils
    class TaskTable < Table
      def initialize(rake_gui, form=nil, config={}, &block)
        super(form, config, &block)
        @rake_gui = rake_gui
        activate_keybindings
      end
      def activate_keybindings
        configure do
          bind_key(RakeGui.keycode('r')) do
            @rake_gui.invoke(self)
          end
          bind_key(RakeGui.keycode('d')) do
            @rake_gui.details(self)
          end
          bind_key(RakeGui.keycode('e')) do
            task = get_value_at(focussed_row, 0)
            @rake_gui.start_editor_for_task(task)
          end
          [RakeGui.keycode('p'), KEY_BACKSPACE, 127].each do |code|
            bind_key(code) do
              @rake_gui.pop_data
            end
          end
        end
      end

      def get_cell_renderer(row, col)
        renderer = super(row, col)
        content = get_value_at(row, 0)
        if renderer.nil?
          renderer = get_default_cell_renderer_for_class(content.class.to_s) if renderer.nil?
          column = @table_column_model.column(col)
          renderer.display_length column.width if column
        end

        if content && content.failure
          renderer.color('red')
          renderer.bgcolor('black')
        else
          renderer.color('white')
          renderer.bgcolor('black')
        end
        return renderer
      end

    end

  end
end
