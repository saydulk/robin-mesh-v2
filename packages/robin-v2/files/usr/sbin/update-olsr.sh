#!/bin/sh

<<COPYRIGHT

Copyright (C) 2010 Antonio Anselmi <tony.anselmi@gmail.com>

This program is free software; you can redistribute it and/or
modify it under the terms of version 2 of the GNU General Public
License as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this file.  If not, see <http://www.gnu.org/licenses/>.

COPYRIGHT

# /usr/sbin/update-olsr.sh 

CALLER=$1
CALLER="${CALLER:-1}"
CONF=olsr
WDIR=/etc/update
k_restart=0

echo "processing UCI file: $CONF"
while read riga ; do
        SECTION_OPTION=$(echo $riga | awk '{print $1}')
        option="${CONF}.${SECTION_OPTION}"
        VALUE=$(echo $riga | awk '{print $2}')
	
        old_value=$(uci get ${option})
        if [ "$old_value" != "$VALUE" ] ; then
               uci set $option="${VALUE}"
			uci commit olsr
               k_restart=1
        fi

done < $WDIR/olsr

[ 1 -eq "$CALLER" ] && {
	if [ "$k_restart" -eq 1 ] ; then 
		uci set flags.restart.system="1"
		uci commit flags	
	fi
}
#
