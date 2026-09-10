include_recipe 'osl-selinux'

# Create-and-remove in one run cannot be idempotent, so this gets its own
# suite rather than cost the osl_anubis suite its enforce_idempotency.

# Stays behind, so the removal below has to prove it is targeted: the package
# and the templated unit are shared, and a sibling instance must survive.
osl_anubis 'keeper' do
  target 'http://127.0.0.1:8080'
  bind '127.0.0.1:8933'
  metrics_bind ':9091'
end

osl_anubis 'doomed' do
  target 'http://127.0.0.1:8080'
  bind '127.0.0.1:8934'
  metrics_bind ':9092'
end

osl_anubis 'doomed' do
  action :remove
end
