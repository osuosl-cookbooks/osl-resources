osl_shell_environment 'EDITOR' do
  value 'vim'
end

osl_shell_environment 'LESSER_EDITOR' do
  value 'nano'
  action [:add, :remove]
end
