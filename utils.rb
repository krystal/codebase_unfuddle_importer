def colourize msg, colour
  colour_codes = {
    :red    => "\033[31m",
    :green  => "\033[32m",
    :yellow => "\033[33m",
    :black  => "\033[0m"
  }
  "#{colour_codes[colour]}#{msg}#{colour_codes[:black]}"
end

def log msg, mode = :normal
  modes = {
    :success  => :green,
    :normal   => :black,
    :warning  => :yellow,
    :error    => :red
  }
  if mode == :print
    print msg
  else
    puts colourize(msg, modes[mode])
  end
end

def debug msg
  log msg, :warning if DEBUG
end

def bail msg = ''
  log msg, :error
  abort
end

def continue?
  log 'Are you ready to proceed? [y/n]', :warning
  bail 'Not ready to continue, aborting.' unless ['y', 'yes'].include?(gets.chomp.downcase)
  log ''
end

# Like `continue?`, but doesn't abort
def flow? msg
  log(msg + ' [y/n]', :warning)
  ['y', 'yes'].include?(gets.chomp.downcase)
end

# Prints `element` of each member of a 2D array/hash
def print_array_with_index arr, element
  arr.each_with_index { |el, i| puts "#{i+1}. #{el[element]}"}
  # Blank line
  puts ""
end

def new_connection url
  http              = Net::HTTP.new(url, (USE_SSL ? 443 : 80))
  http.use_ssl      = USE_SSL
  http.ssl_version  = "SSLv3"
  http.verify_mode  = OpenSSL::SSL::VERIFY_NONE
  return http
end

# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/object/try.rb
class Object
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      __send__(*a, &b)
    end
  end
end
class NilClass
  def try(*args)
    nil
  end
end