osl_shell_environment 'EDITOR' do
  value 'vim'
end

osl_shell_environment 'remove' do
  action :remove
end
