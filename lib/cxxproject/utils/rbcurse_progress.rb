class Progress
  def initialize(form, size)
    @width = size[0]
    initialize_progress(form, size)
    initialize_title(form, size)
    max = 100
  end

  def initialize_progress(form, size)
    @progress = Label.new form do
      name 'progress'
      row size[1]-1
      col 0
      width size[0]
      height 1
    end
    @progress.display_length(@width)
    @progress.text = ' '*@width
  end

  def initialize_title(form, size)
    @title = Label.new form do
      name 'title'
      row size[1]-2
      col 0
      width size[0]
      height 1
    end
    @title.display_length(@widget)
    @title.text = 'Idle'
  end

  def title=(t)
    @title_text = t
    format_title
  end

  def inc(i)
    @current += i
    format_title
    format_progress
  end

  def percentage
    return @current.to_f / @max.to_f
  end

  def format_progress
    total = (percentage * @width.to_f).to_i
    text = "#" * total
    @progress.text = text
    @progress.repaint_all(true)
  end

  def format_title
    format = "%3d%% - worked on %s                                                                    "
    @title.text = sprintf(format, (percentage*100).to_i, @title_text)
    @title.repaint_all(true)
  end

  def max=(f)
    @max = f.to_f
    @current = 0.0
    format_progress
    format_title
  end
end
