#!/bin/bash
#test 1 by trung anh
# Forked from benkulbertis/cloudflare-update-record.sh
# CHANGE THESE

# API Token (Recommended)                                                                      #####
auth_token="zEk2I7QBDiB9OWFelx2WOm8uRZYlvZQD-7hGUTga"

# Domain and DNS record for synchronization
zone_identifier="e2989350da8e80db009ef442f7ef70d6" # Can be found in the "Overview" tab of your domain
record_name="homefast.online"                     # Which record you want to be synced

# DO NOT CHANGE LINES BELOW

# SCRIPT START
echo -e "bắt đầu kiểm tra"

# Check for current external network IP
ip=$(curl -s4 https://icanhazip.com/)
if [[ ! -z "${ip}" ]]; then
  echo -e "  > lấy địa chỉ IP public thành công: ${ip}"
else
  >&2 echo -e "lỗi, không thể lấy địa chỉ IP public."
fi

# The execution of update
if [[ ! -z "${auth_token}" ]]; then
  header_auth_paramheader=( -H '"Authorization: Bearer '${auth_token}'"' )
else
  header_auth_paramheader=( -H '"X-Auth-Email: '${auth_email}'"' -H '"X-Auth-Key: '${auth_key}'"' )
fi

# Seek for the record
seek_current_dns_value_cmd=( curl -s -X GET '"https://api.cloudflare.com/client/v4/zones/'${zone_identifier}'/dns_records?name='${record_name}'&type=A"' "${header_auth_paramheader[@]}" -H '"Content-Type: application/json"' )
record=`eval ${seek_current_dns_value_cmd[@]}`

# Can't do anything without the record
if [[ -z "${record}" ]]; then
  >&2 echo -e "Network error, cannot fetch DNS record."
  exit 1
elif [[ "${record}" == *'"count":0'* ]]; then
  >&2 echo -e "Record does not exist, perhaps create one first?"
  exit 1
fi

# Set the record identifier from result
record_identifier=`echo "${record}" | sed 's/.*"id":"//;s/".*//'`

# Set existing IP address from the fetched record
old_ip=`echo "${record}" | sed 's/.*"content":"//;s/".*//'`
echo -e "  > Fetched current DNS record value   : ${old_ip}"

# Compare if they're the same
if [ "${ip}" == "${old_ip}" ]; then
  echo -e "Cập nhật cho A record '${record_name} (${record_identifier})' đã hủy.\\n  Lí do: A record đã khớp với IP hiện tại."
  exit 0
else
  echo -e "  > Đã phát hiện IP mới, việc cập nhật đang được thực hiện"
fi

# The secret sause for executing the update
json_data_v4="'"'{"id":"'${zone_identifier}'","type":"A","proxied":false,"name":"'${record_name}'","content":"'${ip}'","ttl":120}'"'"
update_cmd=( curl -s -X PUT '"https://api.cloudflare.com/client/v4/zones/'${zone_identifier}'/dns_records/'${record_identifier}'"' "${header_auth_paramheader[@]}" -H '"Content-Type: application/json"' )

# Execution result
update=`eval ${update_cmd[@]} --data $json_data_v4`

# The moment of truth
case "$update" in
*'"success":true'*)
  echo -e "cập nhật cho A record '${record_name} (${record_identifier})' thành công.\\n  - IP cũ: ${old_ip}\\n  + IP mới: ${ip}";;
*)
  >&2 echo -e "cập nhật cho A record '${record_name} (${record_identifier})' thất bại.\\nDUMPING RESULTS:\\n${update}"
  exit 1;;
esac
