require 'xcodeproj'

current_directory_name = File.basename(Dir.getwd)
project_path = "./#{current_directory_name}.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# Script Phase
def input_framework_files
  frameworks = Dir.glob('Carthage/Build/iOS/*.framework')
  frameworks.map do | fw |
    "$(SRCROOT)/" + fw
  end
end

def output_framework_files
  frameworks = Dir.glob('Carthage/Build/iOS/*.framework')
  frameworks.map do | fw |
    "$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/" + fw
  end
end

def add_carthage_build_phase(target)
  puts 'New shell script build phase: Carthage'

  phase = target.shell_script_build_phases.find { |e| e.name == "Carthage" }
  phase = target.new_shell_script_build_phase("Carthage") if phase.nil?

  script = "/usr/local/bin/carthage copy-frameworks"

  puts "  Script: #{script}"

  phase.shell_script = script

  phase.input_paths = []
  input_framework_files.each.with_index do | f, i |
    puts "\e[96m" + "  Input file #{i} : #{f}" + "\e[0m"
    phase.input_paths.push(f)
  end

  phase.output_paths = []
  output_framework_files.each.with_index do | f, i |
    puts "\e[32m" + "  Output file #{i} : #{f}" + "\e[0m"
    phase.output_paths.push(f)
  end
end

# Link Binary with Libraries
def link_binary_with_libraries
  
end

project.targets.each do | target |
  if target.name == current_directory_name
    puts "Use target #{target.name}"
    add_carthage_build_phase target
  end
end

project.save(project_path)
puts "\e[91m" + "Please close then reopen your project!\nOtherwise your new script will not be displayed in current project" + "\e[0m"
sleep(2)
system("open #{current_directory_name}.xcworkspace")