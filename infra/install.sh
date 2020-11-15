cp Caddyfile /etc/caddy/
cp chessmatch.service /etc/systemd/system/
echo "[Service]" >> /etc/systemd/system/chessmatch.service.d/local.conf
echo "Environment=\"SECRET_KEY_BASE=$(MIX_ENV=prod mix phx.gen.secret)"\" >> /etc/systemd/system/chessmatch.service.d/local.conf
systemctl enable caddy.service
systemctl enable chessmatch.service
