# squab-client/mini.rb
#
# This is meant to be require'd by various scripts and one-offs to
# easily send a message to squab upon invocation.
#
# By including "require 'squab-client/auto'" in your script
# it will fork off a process that will update squab with a message
# like: "HOSTNAME$ path/to/script arg1 arg2 ... argN" that also
# includes the username running the script
#
# To test the formatting of the message sent to squab:
# Step 1 (optional) - start squab locally
#   cd ~/src/squab/squab && bundle exec bin/squab
# Step 2 - invoke this script directly
#   cd ~/src/squab/squab-client/lib/squab-client && ruby ./auto.rb

$:.unshift File.join(File.dirname(__FILE__), '..')

require 'squab-client'

RETRY_SLEEP = 2

def invocation_info_to_squab(sc = Squab::Client.new, debug = false, max_retries=3)
  hostname = Socket.gethostname

  script_name = $0
  user = nil
  shell = nil

  # do special things if we're sudo'ing
  if ENV["SUDO_USER"]
    user = ENV["SUDO_USER"]
    shell = "#"
  else
    user = Etc.getpwuid(Process.uid).name
    shell = "$"
  end

  message = "#{hostname}#{shell} #{script_name} #{ARGV.join(' ')}"

  sc.uid = user
  sc.source = File.basename($0)

  if debug
    puts "message: #{message}"
    puts "uid:     #{user}"
    puts "source:  #{sc.source}"
  end

  # Send with retry
  try_count = 0
  begin
    sc.send(message, nil)
  rescue SendEventFailed
    try_count += 1
    if try_count > max_retries
      return
    else
      sleep RETRY_SLEEP
      retry
    end
  end
end

if __FILE__ == $0
  # run with debug output and 0 retries
  invocation_info_to_squab(
    Squab::Client.new(:api => 'http://localhost:8082'), true,0)
else
  # background the sending
  if pid = fork
    Process.detach(pid)
  else
    STDERR.reopen('/dev/null', 'w')
    STDOUT.reopen('/dev/null', 'w')
    STDIN.close

    invocation_info_to_squab
  end
end
