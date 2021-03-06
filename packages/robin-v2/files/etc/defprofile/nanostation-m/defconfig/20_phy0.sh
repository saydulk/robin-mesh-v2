#!/bin/sh

dev="phy0"
mode_11n=""
mode_band="g"
channel="5"

ht_cap=0
for cap in $(iw phy "$dev" info | grep 'Capabilities:' | cut -d: -f2); do
	ht_cap="$(($ht_cap | $cap))"
done

ht_capab="";
[ "$ht_cap" -gt 0 ] && {
	mode_11n="n"
	append ht_capab "	option htmode	HT20" "$N"

	list="	list ht_capab"
	[ "$(($ht_cap & 1))" -eq 1 ] && append ht_capab "$list	LDPC" "$N"
	[ "$(($ht_cap & 32))" -eq 32 ] && append ht_capab "$list	SHORT-GI-20" "$N"
	[ "$(($ht_cap & 64))" -eq 64 ] && append ht_capab "$list	SHORT-GI-40" "$N"
	[ "$(($ht_cap & 128))" -eq 128 ] && append ht_capab "$list	TX-STBC" "$N"
	[ "$(($ht_cap & 768))" -eq 256 ] && append ht_capab "$list	RX-STBC1" "$N"
	[ "$(($ht_cap & 768))" -eq 512 ] && append ht_capab "$list	RX-STBC12" "$N"
	[ "$(($ht_cap & 768))" -eq 768 ] && append ht_capab "$list	RX-STBC123" "$N"
	[ "$(($ht_cap & 4096))" -eq 4096 ] && append ht_capab "$list	DSSS_CCK-40" "$N"
}
iw phy "$dev" info | grep -q '2412 MHz' || { mode_band="a"; channel="36"; }

#Robin
uci_channel=$(uci get radio.channel.current)
[ -n "$uci_channel" ] && {
	case $mode_band in
		'a') [ "$uci_channel" -gt 13 ] && channel=$uci_channel ;;
		'g') [ "$uci_channel" -le 13 ] && channel=$uci_channel ;;
	esac
}

public_encryption=$(uci get mesh.ap.encryption)
public_ssid="$(uci get mesh.ap.ssid |tr [*] [' '])"
public_key=$(uci get mesh.ap.key)
public_isolation=$(uci get iprules.filter.AP1_isolation)

cat > $WIRELESS_CONF << wireless
config wifi-device  radio0
	option type     mac80211
	option channel  ${channel}
	option macaddr	$(cat /sys/class/ieee80211/${dev}/macaddress)
	option hwmode	11${mode_11n}${mode_band}
$ht_capab

config wifi-iface mesh
	option device   radio0
	option network  mesh
	option mode     adhoc
	option bssid    02:ca:ff:ee:ba:be
	option ssid     robin.mesh.com
	option hidden   1
	option rts      250
	option frag     256
	option encryption none

config wifi-iface public
	option device   radio0
	option network  ap1
	option mode     ap
	option isolate  ${public_isolation}
	option hidden   0
	option ssid     ${public_ssid}
	option encryption ${public_encryption}
	option key      ${public_key}

wireless
