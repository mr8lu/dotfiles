#!/bin/bash

echo "======================================================================"
echo "⚠️  WARNING: NETSKOPE KILL SCRIPT"
echo "Killing the Netskope Network Proxy will likely break your internet."
echo "Enterprise security tools 'fail-close', meaning if the proxy dies,"
echo "macOS will block ALL network traffic until it restarts."
echo "======================================================================"
echo ""
read -p "Are you sure you want to attempt this? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Requesting sudo privileges to kill the Netskope Proxy..."
    
    # Kill the core proxy system extension
    sudo pkill -9 -f "NetskopeClientMacAppProxy"
    
    # Kill the UI client and DLP daemon
    sudo pkill -9 -f "Netskope Client"
    sudo pkill -9 -f "Netskope Endpoint DLP"
    
    echo "✅ Kill signals sent."
    echo "If you lose network connectivity, please restart your computer."
else
    echo "Aborted."
fi
