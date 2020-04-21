#!/bin/bash

#Requirements
#https://github.domain.com/domain/aws-portal-cli/releases/tag/v1.0.0
#https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
#decrypt.sh script
  ## # # Decrypt using current storage_password
  ##storage_password="enter_password_here"
  ##test_pw=$(echo $1 | openssl enc -d -base64 -aes-128-ctr -nopad -nosalt -k $storage_password)
  ##echo $test_pw

#auth to aws
./aws-portal-cli --no-launch

#prompt to enter hostname
read -p "Enter Hostname: " hostname

#find escrow for hostname (case insensitive) and get most recent dated result -> $hostname-file
#this gets the name but includes too much text, including the timestamp...
hostname_file=`aws s3 ls sec-luks | grep -i $hostname | sort | tail -1`
hostname_file_cut=`echo $hostname_file | cut -d " " -f4`

#get decrypted key of escrowed file
hostname_escrow=`aws s3 cp s3://sec-luks/$hostname_file_cut -`

#decrypt encrypted key
echo "$hostname Decryption Key: "
~/./decrypt.sh $hostname_escrow
