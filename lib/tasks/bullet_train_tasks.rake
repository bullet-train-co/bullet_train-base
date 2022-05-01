require "io/wait"

namespace :bt do
  desc "Symlink registered gems in `./tmp/gems` so their views, etc. can be inspected by Tailwind CSS."
  task link: :environment do
    if Dir.exist?("tmp/gems")
      puts "Removing previously linked gems."
      `rm -f tmp/gems/*`
    else
      if File.exist?("tmp/gems")
        raise "A file named `tmp/gems` already exists? It has to be removed before we can create the required directory."
      end

      puts "Creating 'tmp/gems' directory."
      `mkdir tmp/gems`
    end

    `touch tmp/gems/.keep`

    BulletTrain.linked_gems.each do |linked_gem|
      target = `bundle show #{linked_gem}`.chomp
      if target.present?
        puts "Linking '#{linked_gem}' to '#{target}'."
        `ln -s #{target} tmp/gems/#{linked_gem}`
      end
    end
  end
end

namespace :bullet_train do
  desc "Figure out where something is coming from."
  task :resolve, [:all_options] => :environment do |t, arguments|
    ARGV.pop while ARGV.any?

    arguments[:all_options]&.split&.each do |argument|
      ARGV.push(argument)
    end

    if ARGV.include?("--interactive")
      puts "\nOK, paste what you've got for us and hit <Return>!\n".blue

      input = $stdin.gets.strip
      $stdin.getc while $stdin.ready?

      # Extract absolute paths from annotated views.
      if input =~ /<!-- BEGIN (.*) -->/
        input = $1
      end

      ARGV.unshift input.strip
    end

    if ARGV.first.present?
      BulletTrain::Resolver.new(ARGV.first).run(eject: ARGV.include?("--eject"), open: ARGV.include?("--open"), force: ARGV.include?("--force"), interactive: ARGV.include?("--interactive"))
    else
      warn "\n🚅 Usage: `bin/resolve [path, partial, or URL] (--eject) (--open)`\n".blue
    end
  end

  task :develop, [:all_options] => :environment do |t, arguments|
    def stream(command, prefix = "  ")
      puts ""

      begin
        trap("SIGINT") { throw :ctrl_c }

        IO.popen(command) do |io|
          while (line = io.gets) do
            puts "#{prefix}#{line}"
          end
        end
      rescue UncaughtThrowError
        puts "Received a <Control + C>. Exiting the child process."
      end

      puts ""
    end

    # TODO Extract this into a YAML file.
    framework_packages = {
      "bullet_train" => {
        git: "https://github.com/bullet-train-co/bullet_train-base",
        npm: "@bullet-train/bullet-train"
      },
      "bullet_train-api" => {
        git: "https://github.com/bullet-train-co/bullet_train-api",
      },
      "bullet_train-fields" => {
        git: "https://github.com/bullet-train-co/bullet_train-fields",
        npm: "@bullet-train/fields"
      },
      "bullet_train-has_uuid" => {
        git: "https://github.com/bullet-train-co/bullet_train-has_uuid",
      },
      "bullet_train-incoming_webhooks" => {
        git: "https://github.com/bullet-train-co/bullet_train-incoming_webhooks",
      },
      "bullet_train-integrations" => {
        git: "https://github.com/bullet-train-co/bullet_train-integrations",
      },
      "bullet_train-integrations-stripe" => {
        git: "https://github.com/bullet-train-co/bullet_train-base-integrations-stripe",
      },
      "bullet_train-obfuscates_id" => {
        git: "https://github.com/bullet-train-co/bullet_train-obfuscates_id",
      },
      "bullet_train-outgoing_webhooks" => {
        git: "https://github.com/bullet-train-co/bullet_train-outgoing_webhooks",
      },
      "bullet_train-outgoing_webhooks-core" => {
        git: "https://github.com/bullet-train-co/bullet_train-outgoing_webhooks-core",
      },
      "bullet_train-scope_questions" => {
        git: "https://github.com/bullet-train-co/bullet_train-scope_questions",
      },
      "bullet_train-scope_validator" => {
        git: "https://github.com/bullet-train-co/bullet_train-scope_validator",
      },
      "bullet_train-sortable" => {
        git: "https://github.com/bullet-train-co/bullet_train-sortable",
        npm: "@bullet-train/bullet-train-sortable"
      },
      "bullet_train-super_scaffolding" => {
        git: "https://github.com/bullet-train-co/bullet_train-super_scaffolding",
      },
      "bullet_train-super_load_and_authorize_resource" => {
        git: "https://github.com/bullet-train-co/bullet_train-super_load_and_authorize_resource",
      },
      "bullet_train-themes" => {
        git: "https://github.com/bullet-train-co/bullet_train-themes",
      },
      "bullet_train-themes-base" => {
        git: "https://github.com/bullet-train-co/bullet_train-themes-base",
      },
      "bullet_train-themes-light" => {
        git: "https://github.com/bullet-train-co/bullet_train-themes-light",
      },
      "bullet_train-themes-tailwind_css" => {
        git: "https://github.com/bullet-train-co/bullet_train-themes-tailwind_css",
      },
    }

    puts "Which framework package do you want to work on?"
    puts ""
    framework_packages.each do |gem, details|
      puts "  #{framework_packages.keys.find_index(gem) + 1}. #{gem}"
    end
    puts ""
    puts "Enter a number below and hit <Enter>:"
    number = $stdin.gets.chomp

    gem = framework_packages.keys[number.to_i - 1]

    if gem
      details = framework_packages[gem]

      puts "OK! Let's work on `#{gem}` together!"
      puts ""
      puts "First, we're going to clone a copy of the package repository."

      # TODO Prompt whether they want to check out their own forked version of the repository.

      if File.exist?("local/#{gem}")
        puts "Can't clone into `local/#{gem}` because it already exists."
        puts "However, we will try to use what's already there."

        # TODO We should check whether the local copy is in a clean state, and if it is, check out `main`.
        # TODO We should also pull `origin/main` to make sure we're on the most up-to-date version of the package.
      else
        stream "git clone #{details[:git]} local/#{gem}"
      end

      # TODO Ask them whether they want to check out a specific branch to work on. (List available remote branches.)

      puts "Now we'll try to link up that repository in the `Gemfile`."
      if `cat Gemfile | grep "gem \\\"#{gem}\\\","`.chomp.present?
        puts "This gem already has some sort of alternative source configured in the `Gemfile`."
        puts "We can't do anything with this. Sorry!"
      elsif `cat Gemfile | grep "gem \\\"#{gem}\\\""`.chomp.present?
        puts "This gem is directly present in the `Gemfile`, so we'll update that line."

        text = File.read("Gemfile")
        new_contents = text.gsub(/gem \"#{gem}\"/, "gem \"#{gem}\", path: \"local/#{gem}\"")
        File.open("Gemfile", "w") { |file| file.puts new_contents }
      else
        puts "This gem isn't directly present in the `Gemfile`, so we'll add it temporarily."
        File.open("Gemfile", "a+") { |file| file.puts; file.puts "gem \"#{gem}\", path: \"local/#{gem}\" # Added by \`bin/develop\`." }
      end

      puts "Now we'll run `bundle install`."
      stream "bundle install"

      puts "We'll restart any running Rails server now."
      stream "rails restart"

      puts "OK, we're opening that package in your IDE, `#{ENV['IDE'] || 'code'}`. (You can configure this with `export IDE=whatever`.)"
      `#{ENV['IDE'] || 'code'} local/#{gem}`

      if details[:npm]
        puts "This package also has an npm package, so we'll link that up as well."
        stream "cd local/#{gem} && yarn install && yarn link && cd ../.. && yarn link \"#{details[:npm]}\""

        puts "And now we're going to watch for any changes you make to the JavaScript and recompile as we go."
        puts "When you're done, you can hit <Control + C> and we'll clean all off this up."
        stream "cd local/#{gem} && yarn build --watch"
      else
        puts "This package has no npm package, so we'll just hang out here and do nothing. However, when you hit <Enter> here, we'll start the process of cleaning all of this up."
        $stdin.gets
      end

      puts "OK, here's a list of things this script still doesn't do you for you:"
      puts "1. It doesn't clean up the repository that was cloned into `local`."
      puts "2. Unless you remove it, it won't update that repository the next time you link to it."
    else
      puts "Invalid option, \"#{number}\". Try again."
    end
  end
end
