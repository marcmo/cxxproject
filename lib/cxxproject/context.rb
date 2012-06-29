
module Cxxproject
  module Context
    
    def check_hash(hash,allowed)
      hash.keys.map do |k|
        error_string = ["error while evaluating \"#{@current_working_dir}/#{@current_project_file}\"",
                        "\"#{k}\" is not a valid specifier!",
                        "allowd specifiers: #{allowed}"].join($/)
        raise error_string unless allowed.include?(k)
      end
    end

    def get_as_array(hash, s)
      res = hash[s]
      if res.is_a?(Array)
        return res
      end
      return [res]
    end

  end
end
