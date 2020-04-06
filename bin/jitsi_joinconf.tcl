#!/usr/bin/env tclsh
package require ygi
package require http
package require json
package require tls

set sounds [file join [file dirname [file normalize [info script]]] .. sounds]

::tls::init -autoservername true
::http::register https 443 [list ::tls::socket]

proc play_getdigits {soundfile {maxdigits 1} {wait 10000} } {
	set digits [::ygi::play_getdigit file $soundfile]
	if {$digits ne ""} {incr maxdigits -1}
		if {$maxdigits} {
			append digits [::ygi::getdigits maxdigits $maxdigits digittimeout $wait enddigit ""]
		}
	return $digits
}

::ygi::start_ivr
::ygi::idle_timeout
::ygi::set_dtmf_notify
set ::ygi::debug true

::ygi::play_wait "yintro"
::ygi::sleep 500
set conference_id [play_getdigits "$sounds/0_enter_id" 10]

::ygi::log "Conference id: $conference_id"

set http_token [::http::geturl "https://jitsi-api.jitsi.net/conferenceMapper?id=$conference_id"]

set data [::http::data $http_token]
set conference_data [::json::json2dict $data]
set conference_name [dict get $conference_data conference]

::ygi::log "conference: $conference_name"

if { $conference_name ne false } {
    ::ygi::play_wait "$sounds/1_connect"
	::ygi::msg call.route called jitsi_meet_sip
	set callto $::ygi::lastresult(retvalue)
	::ygi::msg chan.masquerade id $ygi::env(id) message call.execute callto $callto osip_X-Room-Name $conference_name osip_X-Domain-Base meet.jitsi
} else {
	::ygi::play_wait "$sounds/2_error"
}
