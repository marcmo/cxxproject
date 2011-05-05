module HasLibraries

  def user_libs
    @user_libs ||= []
  end
  def set_user_libs(x)
    @user_libs = x
    self
  end

  def libs_to_search
    @libs_to_search ||= []
  end
  def set_libs_to_search(x)
    @libs_to_search = x
    self
  end

  def lib_searchpaths
    @lib_searchpaths ||= []
  end
  def set_lib_searchpaths(x)
    @lib_searchpaths = x
    self
  end

  def get_libs_with_path
    @libs_with_path ||= []
  end
  def set_libs_with_path(x)
    @libs_with_path = x
    self
  end

end
