cd ..

export MIX_ENV=prod
mix deps.get --only prod
mix compile
npm install --prefix ./assets
npm run deploy --prefix ./assets
mix phx.digest
mix release

cd ./infra

cp chessmatch.service /etc/systemd/system/
mkdir /etc/systemd/system/chessmatch.service.d/
echo "[Service]" >> /etc/systemd/system/chessmatch.service.d/local.conf
echo "Environment=\"SECRET_KEY_BASE=$(cd .. && MIX_ENV=prod mix phx.gen.secret)"\" >> /etc/systemd/system/chessmatch.service.d/local.conf
systemctl enable chessmatch.service

cp Caddyfile /etc/caddy/
systemctl enable caddy.service
