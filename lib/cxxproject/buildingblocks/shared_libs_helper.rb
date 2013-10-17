module Cxxproject
  class SharedLibsHelper
    def symlink_lib_to(link, bb)
      file = File.basename(bb.executable_name)
      if file != link
        cd "#{bb.output_dir}/libs" do
          symlink(file, link)
        end
      end
    end
  end

  class OsxSharedLibs < SharedLibsHelper
    def calc(linker, bb)
      flags = ['-install_name', bb.get_output_name(linker)]
      if bb.compatibility != nil
        flags << '-compatibility_version'
        flags << bb.compatibility
      end
      if bb.minor != nil
        flags << '-current_version'
        flags << bb.minor
      end
      flags
    end

    # For :major=>A, minor=>1.0.1, compatibility=>1.0.0 basic is 'libfoo.A.so'
    def get_basic_name(linker, bb)
      prefix = bb.get_output_prefix(linker)
      name = bb.name
      dylib = bb.shared_suffix linker
      return "#{prefix}#{name}#{dylib}"
    end


    # Some symbolic links
    # ln -s foo.dylib foo.A.dylib
    def post_link_hook(linker, bb)
      basic_name = get_basic_name(linker, bb)
      symlink_lib_to(basic_name, bb)
    end

    def get_version_suffix(linker, bb)
      bb.major ? ".#{bb.major}" : ''
    end
  end

  class UnixSharedLibs < SharedLibsHelper

    def initialize()
    end

    # For :major=>1, minor=>2 fullname is '1.2.so'
    def get_version_suffix(linker, bb)
      "#{major_suffix bb}#{[bb.major, bb.minor].compact.join('.')}"
    end

    def major_suffix(bb)
      bb.major ? ".#{bb.major}" : ''
    end

    # For :major=>1, minor=>2 soname is 'libfoo.1.so'
    #def get_major(linker)
    # prefix = get_output_prefix(linker)
    # return "#{prefix}#{name}#{major_suffix}#{shared_suffix linker}"
    #end

    def get_soname(linker, bb)
      prefix = bb.get_output_prefix(linker)
      "#{prefix}#{bb.name}#{major_suffix bb}#{bb.shared_suffix linker}"
    end

    def calc(linker, bb)
      return ["-Wl,-soname,#{get_soname(linker, bb)}"]
    end

    # For :major=>1, minor=>2 fullname is 'libfoo.so'
    def get_basic_name(linker, bb)
      prefix = bb.get_output_prefix(linker)
      return "#{prefix}#{bb.name}#{bb.shared_suffix(linker)}"
    end

    # Some symbolic links
    # ln -s libfoo.so libfoo.1.2.so
    # ln -s libfoo.1.so libfoo.1.2.so
    def post_link_hook(linker, bb)
      basic_name = get_basic_name(linker, bb)
      soname = get_soname(linker, bb)
      symlink_lib_to(basic_name, bb)
      symlink_lib_to(soname, bb)
    end
  end
end
