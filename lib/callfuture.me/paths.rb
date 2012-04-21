
# Borrowed from Tim Pease

module CallFutureMe
  PATH = File.expand_path('../../..', __FILE__)
  LIBPATH = "#{PATH}/lib"

  # Returns the path for the project. If any arguments are given, they will be
  # joined to the end of the path using `File.join`.
  #
  def self.path( *args )
    rv = args.empty? ? PATH : ::File.join(PATH, args.flatten)
    if block_given?
      begin
        $LOAD_PATH.unshift PATH
        rv = yield
      ensure
        $LOAD_PATH.shift
      end
    end
    return rv
  end

  # Returns the lib/ path for the project. If any arguments are given, they will
  # be joined to the end of the path using `File.join`.
  #
  def self.libpath( *args )
    rv =  args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
    if block_given?
      begin
        $LOAD_PATH.unshift LIBPATH
        rv = yield
      ensure
        $LOAD_PATH.shift
      end
    end
    return rv
  end
end
