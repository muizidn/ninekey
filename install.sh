echo_command_require() {
  echo "Command require: $1"
}

echo_command_found() {
  echo "Command found: $1"
}

find_gem_program() {
  if ! type $1  &> /dev/null; then
    echo_command_require $1
    echo "Please install 'gem install $1' !"
    exit 1
  else
    echo_command_found $1
  fi
}

find_gem_program xcodeproj
