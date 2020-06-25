require "option_parser"

#TODO Add command to cleanup / remove alias
#TODO Check if alias already exists
#TODO Fix .bash_profile alias creation
#TODO Ensure that ephemeral_dev is using the binary
#TODO Add warning when alias is in use
if ARGV.find { |x| x == "setup"}

  OptionParser.parse do |parser|
    parser.banner = "Usage: setup"
    parser.on("-h", "--help", "Show this help") { puts parser }
    parser.invalid_option do |flag|
      STDERR.puts "ERROR #{flag} is not valid"
      STDERR.puts parser
    end
  end
  system "docker build -t cnf-test:latest $(pwd)/tools/ephemeral_env/"
  # puts "Creating crystal alias under: ~/.bash_profile"
  # puts `echo "alias crystal='crystal $(pwd)/tools/ephemeral_env/ephemeral_env.cr command -- $@'" >> ~/.bash_profile`
  # puts "Crystal alias successfully created. You will need to restart your terminal session for it to apply or manually run: \n 'alias crystal='crystal $(pwd)/tools/ephemeral_env/ephemeral_env.cr command -- $@'"
  puts "Create a bash alias by running: \n alias crystal='$(pwd)/ephemeral_env command $@'"


elsif ARGV.find { |x| x == "create_env"}

  env_name = ""
  kubeconfig = ""
  OptionParser.parse do |parser|
    parser.banner = "Usage: create_env [arguments]"
    parser.on("-n NAME", "--name=NAME", "[Required] Specifies the name of the env to create") { |name| env_name = name }
    parser.on("-k FILE", "--kubeconfig=FILE", "[Required] Specifies the path to a kubeconfig") { |file| kubeconfig = file }
    parser.on("-h", "--help", "Show this help") { puts parser }
    parser.invalid_option do |flag|
      STDERR.puts "ERROR #{flag} is not valid"
      STDERR.puts parser
      exit 1
    end
  end
  if env_name.empty? && kubeconfig.empty?
    puts "Required arguments missing [-n, --name] [-k, --kubeconfig]"
  elsif kubeconfig.empty?
    puts "Required argument missing [-k, --kubeconfig]"
  elsif env_name.empty?
    puts "Required argument missing [-n, --name]"
  else
    puts "Creating ENV For: \n Name: #{env_name} \n Kubeconfig: #{kubeconfig}"
    `docker run --name #{env_name} -d -v $(pwd):/cnf-conformance -v #{kubeconfig}:/root/.kube/config -ti cnf-test /bin/sleep infinity`
    puts `docker ps -f name=#{env_name}`
  end


elsif ARGV.find { |x| x == "delete_env"}

  env_name = ""
  OptionParser.parse do |parser|
    parser.banner = "Usage: delete_env [arguments]"
    parser.on("-n NAME", "--name=NAME", "[Required] Specifies the name of the env to delete") { |name| env_name = name }
    parser.on("-h", "--help", "Show this help") { puts parser }
    parser.invalid_option do |flag|
      STDERR.puts "ERROR #{flag} is not valid"
      STDERR.puts parser
      exit 1
    end
  end

  if env_name.empty?
    puts "Required argument missing [-n, --name]"
  else
    puts "Deleteing ENV For: #{env_name}"
    `docker rm -f #{env_name}`
  end


elsif ARGV.find { |x| x == "list_envs"}
    OptionParser.parse do |parser|
      parser.banner = "Usage: list_envs"
      parser.on("-h", "--help", "Show this help") { puts parser }
      parser.invalid_option do |flag|
        STDERR.puts "ERROR #{flag} is not valid"
        STDERR.puts parser
        exit 1
      end
    end

    envs = `docker ps -f ancestor=cnf-test --format '{{.Names}}'`
    envs_list = envs.split("\n")
    envs_list.pop
    if envs_list.empty?
      puts "You currently don't have any active envs, to create one run 'create_env'"
    else
      envs_list.each do |env|
        puts "export CRYSTAL_DEV_ENV=#{env}"
      end
      puts "To Set an ENV run one of the export commands in your session e.g. 'export CRYSTAL_DEV_ENV=test44'"
    end

elsif ARGV.find { |x| x == "command"}

  usage = "Usage: command [execute_command]"
  if ARGV[1]? == "--help" || ARGV[1]? == "-h"
     puts "#{usage}"
     exit 0
  end
  execute_command = ARGV[1..-1].join(" ")
  if ENV["CRYSTAL_DEV_ENV"]
    puts "Using Environment: #{ENV["CRYSTAL_DEV_ENV"]}"
    system "docker exec -ti #{ENV["CRYSTAL_DEV_ENV"]} crystal #{execute_command}"
  else
    puts "CRYSTAL_DEV_ENV Not Set. Run list_envs and select one"
  end

else
  puts "Usage: [setup | create_env | delete_env | list_envs | command]"
  OptionParser.parse do |parser|
    parser.on("-h", "--help", "Show this help") { puts parser }
    parser.invalid_option do |flag|
      STDERR.puts "ERROR #{flag} is not valid"
      STDERR.puts parser
    end
  end
end
