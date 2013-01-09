class ::ProgressBar
  attr_writer :title

  def title_width=(w)
    @title_width = w
    @format = "%-#{@title_width}s #{'%3d%%'.red} #{'%s'.green} #{'%s'.blue}"
  end

  show_original = self.instance_method(:show)
  define_method(:show) do
    if @unblocked && !(RakeFileUtils.verbose == true)
      show_original.bind(self).call
    end
  end

  def unblock
    @unblocked = true
    show
  end
end
