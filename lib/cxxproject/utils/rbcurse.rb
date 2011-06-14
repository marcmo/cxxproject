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
      Cxxproject::ColorizingFormatter.enabled = false

      $log = Logger.new(File.join("./", "view.log"))
      $log.level = Logger::ERROR
      monkey_patch_syncio
      Rake::add_listener(self)
      @data_stack = []
    end

    def self.keycode(s)
      return s[0].to_i
    end

    def create_table
      rake_gui = self
      @col_names = ['name', 'desc']
      res = Table.new nil do
        name 'my table'
        title 'my table'
        cell_editing_allowed false
      end

      res.configure do
        bind_key(RakeGui.keycode('r')) do
          rake_gui.invoke(self)
        end
        bind_key(RakeGui.keycode('d')) do
          rake_gui.details(self)
        end
        bind_key(RakeGui.keycode('p')) do
          rake_gui.pop_data()
        end
      end

      return res
    end

    def invoke(table)
      t = table.get_value_at(table.focussed_row, 0)
      $log.error "invoking #{t}"

      begin
        t.invoke
      rescue => e
        $log.error e
      end
      $log.error "#{t.name} #{t.failure}"
    end

    def details(table)
      t = table.get_value_at(table.focussed_row, 0)
      $log.error "details for #{t}"

      pre = t.prerequisite_tasks
      if pre.size > 0
        push_table_data(pre)
        table.set_focus_on 0
      end
    end

    def process_input_events
      ch = @window.getchar
      while ch != RakeGui.keycode('q')
        case ch
          when RakeGui.keycode('a')
            $log.error("runter")
            @h_split.set_divider_location(@h_split.divider_location+1)
          when RakeGui.keycode('s')
            $log.error("rauf")
            @h_split.set_divider_location(@h_split.divider_location-1)
          else
            @form.handle_key(ch)
        end

        @form.repaint
        @window.wrefresh
        Ncurses::Panel.update_panels

        ch = @window.getchar
      end
    end

    def push_table_data(task_data)
      @data_stack.push(task_data)
      set_table_data(task_data)
    end
    def set_table_data(task_data)
      size = size()
      new_data = task_data.map{|t|[t, t.comment]}
      @table.set_data new_data, @col_names
      tcm = @table.table_column_model
      first_col_width = task_data.map{|t|t.name.size}.max
      tcm.column(0).width(first_col_width)
      tcm.column(1).width(size[0]-first_col_width-3)
    end

    def pop_data
      if @data_stack.size > 1
        popped = @data_stack.pop
        top= @data_stack.last
        $log.error "new top: #{top}"
        set_table_data(top)
      end
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
          push_table_data(Rake::Task.tasks.select {|t|t.comment})

          @output = TextView.new nil
          @output.set_content('')

          @table.bind(:TABLE_TRAVERSAL_EVENT) do |e|
            $log.error " event #{e}"
            table = e.source
            t = table.get_value_at(e.newrow, 0)
            if t.output_string
              $log.error "setting output_string #{t.output_string}"
              @output.set_content(t.output_string) if t.output_string
              @output.repaint_all(true)
            end
          end

          @h_split.first_component(@table)
          @h_split.second_component(@output)
          @h_split.set_resize_weight(0.50)

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
      @output.set_content(t.output_string.split('\n')) if t.output_string
    end

  end



  task :ui do
    RakeGui.new.run
  end

rescue LoadError => e
end
