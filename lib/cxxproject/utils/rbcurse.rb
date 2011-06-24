define_rbcurse_ui = lambda do
  require 'rake'
  require 'ncurses'
  require 'rbcurse'

  require 'rbcurse/rtable'
  require 'rbcurse/table/tablecellrenderer'
  require 'rbcurse/rsplitpane'
  require 'rbcurse/rtextview'
  require 'cxxproject/extensions/rake_listener_ext'
  require 'cxxproject/utils/rbcurse_progress'
  require 'cxxproject/utils/rbcurse_tasktable'

  include RubyCurses

  Rake::TaskManager.record_task_metadata = true

  class RakeGui
    def initialize
      require 'cxxproject/utils/rbcurse_executable_ext'
      Cxxproject::ColorizingFormatter.enabled = false
      Rake::Task.output_disabled = true

      $log = Logger.new(File.join("./", "view.log"))
      $log.level = Logger::ERROR
      @data_stack = []
      @path_stack = []
    end

    def self.keycode(s)
      return s[0].to_i
    end

    def create_table
      @col_names = ['name', 'desc']
      return TaskTable.new(self) do
        name 'my table'
        title 'my table'
        cell_editing_allowed false
      end
    end

    def reenable_including_prerequisites(task)
      task.visit() do |t|
        t.reenable
        true
      end
    end

    def invoke(table)
      t = table.get_value_at(table.focussed_row, 0)
      @progress_helper = ProgressHelper.new
      complete_task_name = t.name
      args = []
      if @progress_helper.is_filter(t.name)
        args = [get_string('please input filterpattern', 20, '.*')]
        complete_task_name = "#{t.name}[#{args[0]}]"
      end
      @progress_helper.count_with_filter(complete_task_name)

      @progress.max = @progress_helper.todo
      Rake::add_listener(self)
      reenable_including_prerequisites(t)
      t.invoke(args)
      Rake::remove_listener(self)
      show_details_for(table.focussed_row)
      table.repaint_all(true)
    end

    def after_execute(name)
      needed_tasks = @progress_helper.needed_tasks
      if needed_tasks[name]
        task = Rake::Task[name]
        @progress.title = task.name
        @progress.inc(task.progress_count)
        @form.repaint
      end
    end

    def details(table)
      t = table.get_value_at(table.focussed_row, 0)
      pre = t.prerequisite_tasks
      if pre.size > 0
        push_table_data(pre, t.name)
        table.set_focus_on 0

        show_details_for(0)
      end
    end

    def repaint_and_next_char
      @form.repaint
      @window.wrefresh
      return @window.getchar
    end

    def process_input_events
      ch = repaint_and_next_char
      while ch != RakeGui.keycode('q')
        $log.error "entered key: #{ch}"
        case ch
        when RakeGui.keycode('a')
          @h_split.set_divider_location(@h_split.divider_location+1)
        when RakeGui.keycode('s')
          @h_split.set_divider_location(@h_split.divider_location-1)
        else
          @form.handle_key(ch)
        end
        ch = repaint_and_next_char
      end
    end

    def push_table_data(task_data, new_path=nil)
      @path_stack.push(new_path) if new_path
      set_breadcrumbs

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
    def set_breadcrumbs
      crumbs = File.join(@path_stack.map{|i|"(#{i})"}.join('/'))
      @breadcrumbs.text = crumbs
      @breadcrumbs.repaint_all(true)
    end
    def pop_data
      if @data_stack.size > 1
        @path_stack.pop
        set_breadcrumbs

        popped = @data_stack.pop
        top= @data_stack.last
        set_table_data(top)
      end
    end

    def size
      return @window.default_for(:width), @window.default_for(:height)
    end

    def show_details_for(row)
      buffer = StringIO.new
      t = @table.get_value_at(row, 0)
      t.visit do |t|
        if t.output_string && t.output_string.length > 0
          buffer.puts(t.output_string)
        end
        if t.failure
          true
        else
          false
        end
      end
      @output.set_content(buffer.string)
      @output.set_focus_on(0)
      @output.repaint_all(true)
    end

    def start_editor_for_task(t)
      file_name = t.name
      return unless File.exists?(file_name)

      start_editor(file_name, 0, 0)
    end

    def start_editor(file, line, column)
      $log.error "starting editor for #{file}:#{line}"
      editor = ENV['EDITOR']
      editor = 'vi' unless editor
      cmd = "#{editor} +#{line} #{file}"
      shell_out(cmd)
    end

    def shell_out(cmd)
      @window.hide
      Ncurses.endwin
      system(cmd)
      Ncurses.refresh
      @window.show
    end

    def create_breadcrumbs(size)
      @breadcrumbs = Label.new @form do
        name 'breadcrumbs'
        row 0
        col 0
        width size[0]
        height 1
      end
      @breadcrumbs.display_length(size[0])
      @breadcrumbs.text = ''
    end

    def create_splitpane(size)
      @h_split = SplitPane.new @form do
        name 'mainpane'
        row 1
        col 0
        width size[0]
        height size[1]-3
        orientation :HORIZONTAL_SPLIT
      end
    end

    def create_output_view(size)
      @output = TextView.new nil
      @output.set_content('')
      @output.configure do
        bind_key(RakeGui.keycode('e')) do |code|
          line = selected_item
          file_pattern = '(.*?):(\d+):(\d*):? '
          error_pattern = Regexp.new("#{file_pattern}(error: .*)")
          warning_pattern = Regexp.new("#{file_pattern}(warning: .*)")
          md = error_pattern.match(line)
          md = warning_pattern.match(line) unless md
          if md
            file_name = md[1]
            line = md[2]
            col = md[3]
            rake_gui.start_editor(file_name, line, col)
          end
        end
      end
    end

    def create_components(size)
      create_breadcrumbs(size)
      @progress = Progress.new(@form, size)
      create_splitpane(size)
      @table = create_table
      push_table_data(Rake::Task.tasks.select {|t|t.comment})

      create_output_view(size)
    end

    def wire_components
      @h_split.first_component(@table)
      @h_split.second_component(@output)
      @h_split.set_resize_weight(0.50)
    end

    def run
      rake_gui = self
      begin
        VER::start_ncurses

        @window = VER::Window.root_window
        @form = Form.new @window

        create_components(size())
        wire_components

        @table.bind(:TABLE_TRAVERSAL_EVENT) do |e|
          rake_gui.show_details_for(e.newrow)
        end

        process_input_events
      rescue => e
        puts e
      end
      @window.destroy if @window
      VER::stop_ncurses
    end
  end

  task :ui do
    RakeGui.new.run
  end

end

optional_package(define_rbcurse_ui, nil)
