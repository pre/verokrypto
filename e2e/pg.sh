#!/usr/bin/env bash
set -euo pipefail

BASE_DATA="../verokrypto-data"
KOINLY_DATA_PATH="${BASE_DATA}/koinly"

_debug() {
  >&2 echo -e "+ $*"
}

_out() {
  >&2 echo -e "👾 $*"
}

_tee() {
  local filename="$1"

  tee "${filename}" >/dev/null # &2 for debug
}

_verokrypto() {
  local args; args=("$@")

  exe/verokrypto "${args[@]}"
}

_verodata_status() {
  git -C "${BASE_DATA}" status
}

_process() {
  local source_name="$1"
  local wallet_name="$2"
  local source_file_paths=("${@:3}")
  local tempdir; tempdir="$(mktemp -d)"

  local csv_temp_file="${tempdir}/${source_name}-${wallet_name}.csv"
  local hmo_temp_file="${csv_temp_file}-hmo.csv"
  local koinly_csv_file="${KOINLY_DATA_PATH}/${wallet_name}.csv"

  _out "${koinly_csv_file}"

  _verokrypto process "${source_name}" "${source_file_paths[@]}" | _tee "${csv_temp_file}"

  local source_file_dir; source_file_dir="$(dirname ${source_file_paths[0]})"
  local hmo_path; hmo_path="${source_file_dir}/.hmo.csv"
  if [[ -f ${hmo_path} ]]; then
    _verokrypto hmo "${csv_temp_file}" "${hmo_path}" | _tee "${hmo_temp_file}"
    mv -v "${hmo_temp_file}" "${koinly_csv_file}-hmo"
  fi

  mv -v "${csv_temp_file}" "${koinly_csv_file}"
}


_southxchange() {
  local wallet_name="southxchange"
  local tempdir; tempdir="$(mktemp -d)"

  local btc_temp_path="${tempdir}/${wallet_name}-btc.csv"
  local rtm_temp_path="${tempdir}/${wallet_name}-rtm.csv"
  local merged_temp_path="${tempdir}/${wallet_name}.csv"
  local btc_path="${BASE_DATA}/southxchange/sxc-btc-transactions.csv"
  local rtm_path="${BASE_DATA}/southxchange/sxc-rtm-transactions.csv"

  _out "${wallet_name}"

  # btc -> rtm transactions
  _verokrypto process "${wallet_name}" "${btc_path}" "${rtm_path}" | _tee "${btc_temp_path}"

  # rtm -> btc transactions
  _verokrypto process "${wallet_name}" "${rtm_path}" "${btc_path}" | _tee "${rtm_temp_path}"

  # merged tranasctions by timestamp
  _verokrypto csv "${btc_temp_path}" "${rtm_temp_path}" | _tee "${merged_temp_path}"

  mv -v "${tempdir}"/*.csv "${KOINLY_DATA_PATH}"
}

_raptoreum_main() {
  _process raptoreum raptoreum-main \
    "${BASE_DATA}"/raptoreum-main/rtm-wallet-main.csv \
    "${BASE_DATA}"/raptoreum-main/labels-received.yaml \
    "${BASE_DATA}"/raptoreum-main/labels-sent.yaml \
    "${BASE_DATA}"/raptoreum-main/prices-missing.csv \
  ;
}

_raptoreum_mafianode() {
  _process raptoreum raptoreum-mafianode \
    "${BASE_DATA}"/raptoreum-mafianode/mafianode-export.csv \
    "${BASE_DATA}"/raptoreum-mafianode/labels-received.yaml \
    "${BASE_DATA}"/raptoreum-mafianode/labels-sent.yaml \
    "${BASE_DATA}"/raptoreum-mafianode/prices-missing.csv \
  ;
}

_raptoreum_inodez() {
  _process raptoreum raptoreum-inodez \
    "${BASE_DATA}"/raptoreum-inodez/inodez-constructed.csv \
    "${BASE_DATA}"/raptoreum-inodez/labels-received.yaml \
    "${BASE_DATA}"/raptoreum-inodez/labels-sent.yaml \
    "${BASE_DATA}"/raptoreum-inodez/prices-missing.csv \
  ;
}

_raptoreum_kika2() {
  _process raptoreum raptoreum-kika2 \
    "${BASE_DATA}"/raptoreum-kika2/rtm-wallet-kika2.csv \
    "${BASE_DATA}"/raptoreum-kika2/labels-received.yaml \
    "${BASE_DATA}"/raptoreum-kika2/labels-sent.yaml \
    "${BASE_DATA}"/raptoreum-kika2/prices-missing.csv \
  ;
}

_raptoreum_paulus() {
  _process raptoreum raptoreum-paulus \
    "${BASE_DATA}"/raptoreum-paulus/rtm-wallet-paulus.csv \
    "${BASE_DATA}"/raptoreum-paulus/labels-received.yaml \
    "${BASE_DATA}"/raptoreum-paulus/labels-sent.yaml \
    "${BASE_DATA}"/raptoreum-paulus/prices-missing.csv \
  ;
}

_coinex() {
  _process coinex-csv coinex "${BASE_DATA}"/coinex/coinex-mafianode-oma-kolmasosa.csv
}

_cryptocom() {
  _process cryptocom cryptocom "${BASE_DATA}"/cryptocom/petafox_crypto_transactions_20230106.csv
}

_kraken() {
  _process kraken kraken "${BASE_DATA}"/kraken/ledgers.csv
}
_tradeogre() {
  local wallet_name="tradeogre"
  local tempdir; tempdir="$(mktemp -d)"

  local deposits_temp_path="${tempdir}/${wallet_name}-deposits.csv"
  local trades_temp_path="${tempdir}/${wallet_name}-trades.csv"
  local withdrawals_temp_path="${tempdir}/${wallet_name}-withdrawals.csv"
  local merged_temp_path="${tempdir}/${wallet_name}.csv"

  local deposits_path="${BASE_DATA}/tradeogre/export_deposits.csv"
  local trades_path="${BASE_DATA}/tradeogre/export_trades.csv"
  local withdrawals_path="${BASE_DATA}/tradeogre/export_withdrawals.csv"

  _out "${wallet_name}"

  _verokrypto process "tradeogre:deposits" "${deposits_path}" | _tee "${deposits_temp_path}"
  _verokrypto process "tradeogre:trades" "${trades_path}" | _tee "${trades_temp_path}"
  _verokrypto process "tradeogre:withdrawals" "${withdrawals_path}" | _tee "${withdrawals_temp_path}"

  # merge
  _verokrypto csv "${deposits_temp_path}" "${trades_temp_path}" "${withdrawals_temp_path}" | _tee "${merged_temp_path}"

  mv -v "${tempdir}"/*.csv "${KOINLY_DATA_PATH}"
}

_raptoreum_main

_raptoreum_mafianode

_raptoreum_inodez

_raptoreum_kika2

_raptoreum_paulus

_process coinbase coinbase \
  ${BASE_DATA}/coinbase/"2023-01-06-coinbase.csv" \
;

_coinex

_tradeogre

_southxchange

_cryptocom

_kraken

_verodata_status

_out "Next: Commit changes to git in ${BASE_DATA}"
