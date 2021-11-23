#!/bin/bash

echo "This scripts setup a resource group on the bredvid kompetanseprogram subscription"

RESOURCE_GROUP_ID=kp2021s4-$USER-rg

az login

az account set --subscription "Bredvid-kompetanse-pay-as-you-go"

az group create -l norwayeast -n $RESOURCE_GROUP_ID

filename="./.github/workflows/provision.yml"

# Take the search string
search='#REPLACE'

sed -i '' "s/$search/$RESOURCE_GROUP_ID/" $filename



