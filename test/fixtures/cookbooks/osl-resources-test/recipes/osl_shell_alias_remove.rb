
%w(ll sl).each do |a|
  osl_shell_alias a do
    command 'ls -al'
  end
end

osl_shell_alias 'sl' do
  action :remove
end
