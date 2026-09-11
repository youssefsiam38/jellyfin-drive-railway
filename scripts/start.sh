#!/usr/bin/env bash
set -Eeuo pipefail

data_root="${DATA_ROOT:-/data}"
mkdir -p \
  "${data_root}/jellyfin/config" \
  "${data_root}/jellyfin/log" \
  "${data_root}/jellyfin-cache" \
  "${data_root}/media" \
  "${data_root}/openlist" \
  "${data_root}/ostrm/config" \
  "${data_root}/ostrm/db" \
  "${data_root}/ostrm/log/frontend"

secret_file="${data_root}/ostrm/jwt-secret"
if [[ -z "${JWT_SECRET:-}" ]]; then
  if [[ ! -s "${secret_file}" ]]; then
    umask 077
    od -An -N32 -tx1 /dev/urandom | tr -d ' \n' > "${secret_file}"
  fi
  JWT_SECRET="$(<"${secret_file}")"
  export JWT_SECRET
fi

network_config="${JELLYFIN_CONFIG_DIR}/network.xml"
if [[ ! -f "${network_config}" ]]; then
  umask 077
  printf '%s\n' \
    '<?xml version="1.0" encoding="utf-8"?>' \
    '<NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' \
    '  <BaseUrl>/jellyfin</BaseUrl>' \
    '  <EnableHttps>false</EnableHttps>' \
    '  <RequireHttps>false</RequireHttps>' \
    '  <CertificatePath />' \
    '  <CertificatePassword />' \
    '  <InternalHttpPort>8096</InternalHttpPort>' \
    '  <InternalHttpsPort>8920</InternalHttpsPort>' \
    '  <PublicHttpPort>80</PublicHttpPort>' \
    '  <PublicHttpsPort>443</PublicHttpsPort>' \
    '  <AutoDiscovery>false</AutoDiscovery>' \
    '  <EnableUPnP>false</EnableUPnP>' \
    '  <EnableIPv4>true</EnableIPv4>' \
    '  <EnableIPv6>false</EnableIPv6>' \
    '  <EnableRemoteAccess>true</EnableRemoteAccess>' \
    '  <LocalNetworkSubnets />' \
    '  <LocalNetworkAddresses />' \
    '  <KnownProxies><string>127.0.0.1</string></KnownProxies>' \
    '  <IgnoreVirtualInterfaces>true</IgnoreVirtualInterfaces>' \
    '  <VirtualInterfaceNames><string>veth</string></VirtualInterfaceNames>' \
    '  <EnablePublishedServerUriByRequest>true</EnablePublishedServerUriByRequest>' \
    '  <PublishedServerUriBySubnet />' \
    '  <RemoteIPFilter />' \
    '  <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>' \
    '</NetworkConfiguration>' > "${network_config}"
fi

pids=()
names=()

start_service() {
  local name="$1"
  shift
  echo "Starting ${name}"
  "$@" &
  pids+=("$!")
  names+=("${name}")
}

shutdown() {
  trap - TERM INT
  if ((${#pids[@]})); then
    kill -TERM "${pids[@]}" 2>/dev/null || true
    wait "${pids[@]}" 2>/dev/null || true
  fi
  exit 0
}
trap shutdown TERM INT

start_service "OpenList" \
  /opt/openlist/openlist server --data "${data_root}/openlist"

start_service "OStrm" \
  java \
    --add-opens java.base/java.lang=ALL-UNNAMED \
    --add-opens java.base/java.nio=ALL-UNNAMED \
    --add-opens java.base/java.nio.file=ALL-UNNAMED \
    -Xms64m -Xmx256m \
    -XX:+UseG1GC \
    -Dfile.encoding=UTF-8 \
    -jar /opt/ostrm/openlisttostrm.jar

start_service "Jellyfin" \
  /jellyfin/jellyfin \
    --datadir "${JELLYFIN_DATA_DIR}" \
    --cachedir "${JELLYFIN_CACHE_DIR}" \
    --configdir "${JELLYFIN_CONFIG_DIR}" \
    --logdir "${JELLYFIN_LOG_DIR}" \
    --webdir "${JELLYFIN_WEB_DIR}" \
    --ffmpeg "${JELLYFIN_FFMPEG}"

start_service "gateway" caddy run --config /etc/caddy/Caddyfile --adapter caddyfile

set +e
wait -n -p stopped_pid "${pids[@]}"
status=$?
set -e

stopped_name="a service"
for index in "${!pids[@]}"; do
  if [[ "${pids[$index]}" == "${stopped_pid:-}" ]]; then
    stopped_name="${names[$index]}"
    break
  fi
done

echo "${stopped_name} stopped unexpectedly (status ${status}); restarting container" >&2
kill -TERM "${pids[@]}" 2>/dev/null || true
wait "${pids[@]}" 2>/dev/null || true
exit 1
