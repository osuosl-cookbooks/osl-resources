%w(hello goodbye).each do |f|
  osl_shell_function f do
    body "echo \"#{f.capitalize}, $@\""
  end
end

osl_shell_function 'goodbye' do
  action :remove
end
