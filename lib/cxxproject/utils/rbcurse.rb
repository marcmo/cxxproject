begin

  require 'ncurses'
  require 'rbcurse'
  require 'rbcurse/rtable'
  require 'rbcurse/rsplitpane'
  require 'rbcurse/rtextview'
  include RubyCurses

  def monkey_patch_syncio
    require 'cxxproject/utils/monkey_patch_syncio'
    require 'cxxproject/extensions/rake_listener_ext'
  end

  class RakeGui
    def initialize
      monkey_patch_syncio
      $log = Logger.new(File.join("./", "view.log"))
      $log.level = Logger::ERROR
      Rake::add_listener(self)
    end

    def self.keycode(s)
      return s[0].to_i
    end

    def create_table
      rake_gui = self
      @col_names = ['name', 'desc']
      res = Table.new nil do |table|
        name 'my table'
        title 'my table'
#        row 1
#        col 1
#        width(rake_gui.size()[0]-2)
#        height(rake_gui.size()[1]-10)
        cell_editing_allowed false
      end

      res.configure do
        bind_key(RakeGui.keycode('r')) do
          t = get_value_at(focussed_row, 0)
          $log.error "invoking #{t}"

          t.invoke
        end
      end

      res.configure do
        bind_key(RakeGui.keycode('d')) do
          t = get_value_at(focussed_row, 0)
          $log.error "details for #{t}"

          pre = t.prerequisite_tasks
          if pre.size > 0
            rake_gui.set_table_data(pre)
            set_focus_on 0
          end
        end
      end
      return res
    end

    def process_input_events
      ch = @window.getchar
      while ch != RakeGui.keycode('q')
        @form.handle_key(ch)
        @window.wrefresh
        ch = @window.getchar
      end
    end

    def set_table_data(task_data)
      size = size()
      new_data = task_data.map{|t|[t, t.comment]}
      @table.set_data new_data, @col_names
      tcm = @table.table_column_model
      first_col_width = new_data.map{|pair|pair[0].name.size}.max
      tcm.column(0).width(first_col_width)
      tcm.column(1).width(size[0]-first_col_width-3)
    end

    def size
      return @window.default_for(:width), @window.default_for(:height)
    end

    def run
      begin
        VER::start_ncurses
        @window = VER::Window.root_window
        catch (:close) do
          @form = Form.new @window
          size = size()
          @h_split = SplitPane.new @form do
            name 'mainpane'
            row 0
            col 0
            width size[0]
            height size[1]
            orientation :HORIZONTAL_SPLIT
          end
          @table = create_table
          set_table_data(Rake::Task.tasks.select {|t|t.comment})


          @output = TextView.new nil do
#            title 'output'
          end

          @output.set_content('')

          @h_split.first_component(@table)
          @h_split.second_component(@output)

          @form.repaint
          @window.wrefresh
          Ncurses::Panel.update_panels

          process_input_events
        end
      ensure
        @window.destroy if @window
        VER::stop_ncurses
      end
    end

    def before_prerequisites(name)
    end

    def after_prerequisites(name)
    end

    def before_execute(name)
    end

    def after_execute(name)
      t = Rake::Task[name]
      $log.error "after_execute '#{name}' -> '#{t.output_string}'"
    end

  end



  task :ui do
    RakeGui.new.run
  end

rescue LoadError => e
end
