#!/usr/bin/python
from scapy.all import *
from random import randint
import random
import string
import sys
import os
import binascii
from struct import *
import socket

def datafield( len_datafield ):
    l = 0
    data_field = ''
    while l < len_datafield:
        data_field = data_field + random.choice(string.ascii_letters)
        l=l+1
    return data_field

ipv4 = []

def common_header ( ):
    proto_ec_msg   = binascii.unhexlify("10") # ecpri indentifier
    type_ec_msg   = binascii.unhexlify("04") # remote memory access 
    sz_ec_msg   = pack('!H',0x64)  # size of the eCPRI packet 
    return proto_ec_msg, type_ec_msg, sz_ec_msg


def read_req (mac_src, mac_dst, src_ip_v4, dst_ip_v4, src_port, dst_port):
    # add ecpri common header
    proto_ec_msg, type_ec_msg, sz_ec_msg = common_header() 

    # add ecpri read req header
    id_ec_msg   = binascii.unhexlify("01")
    rw_rr_ec_msg    = binascii.unhexlify("00")
    ele_id_ec_msg  = binascii.unhexlify("0001")
    addr_ec_msg  = binascii.unhexlify("000000000001") # do not know the address has to be big endian format or little endian format
    len_ec_msg  = binascii.unhexlify("64")
    data_f_ip   = datafield(0) # zero payload

    ipv4.append(Ether(src = mac_src,dst = mac_dst)/
            IP(src=src_ip_v4,dst=dst_ip_v4)/
            UDP(sport=src_port,dport=dst_port)/
            Raw(load=proto_ec_msg)/
            Raw(load=type_ec_msg)/
            Raw(load=sz_ec_msg)/
            Raw(load=id_ec_msg)/
            Raw(load=rw_rr_ec_msg)/
            Raw(load=ele_id_ec_msg)/
            Raw(load=addr_ec_msg)/
            Raw(load=len_ec_msg)/
            data_f_ip
            )
    wrpcap("gen_ecpri.pcap",ipv4)

def read_resp (mac_src, mac_dst,  src_ip_v4, dst_ip_v4, src_port, dst_port):
    # add ecpri common header
    proto_ec_msg, type_ec_msg, sz_ec_msg = common_header() 

    # add ecpri read req header
    id_ec_msg   = binascii.unhexlify("01")
    rw_rr_ec_msg    = binascii.unhexlify("01")
    ele_id_ec_msg  = binascii.unhexlify("0001")
    addr_ec_msg  = binascii.unhexlify("000000000001") # do not know the address has to be big endian format or little endian format
    len_ec_msg  = binascii.unhexlify("64")
    data_f_ip   = datafield(64)

    ipv4.append(Ether(src = mac_src,dst = mac_dst)/
            IP(src=src_ip_v4,dst=dst_ip_v4)/
            UDP(sport=src_port,dport=dst_port)/
            Raw(load=proto_ec_msg)/
            Raw(load=type_ec_msg)/
            Raw(load=sz_ec_msg)/
            Raw(load=id_ec_msg)/
            Raw(load=rw_rr_ec_msg)/
            Raw(load=ele_id_ec_msg)/
            Raw(load=addr_ec_msg)/
            Raw(load=len_ec_msg)/
            data_f_ip
            )
    wrpcap("gen_ecpri.pcap",ipv4)

def write_req ( mac_src, mac_dst, src_ip_v4, dst_ip_v4, src_port, dst_port):
    # add ecpri common header
    proto_ec_msg, type_ec_msg, sz_ec_msg = common_header() 

    # add ecpri read req header
    id_ec_msg   = binascii.unhexlify("01")
    rw_rr_ec_msg    = binascii.unhexlify("10")
    ele_id_ec_msg  = binascii.unhexlify("0001")
    addr_ec_msg  = binascii.unhexlify("000000000001") # do not know the address has to be big endian format or little endian format
    len_ec_msg  = binascii.unhexlify("64")
    data_f_ip   = datafield(64)

    ipv4.append(Ether(src = mac_src,dst = mac_dst)/
            IP(src=src_ip_v4,dst=dst_ip_v4)/
            UDP(sport=src_port,dport=dst_port)/
            Raw(load=proto_ec_msg)/
            Raw(load=type_ec_msg)/
            Raw(load=sz_ec_msg)/
            Raw(load=id_ec_msg)/
            Raw(load=rw_rr_ec_msg)/
            Raw(load=ele_id_ec_msg)/
            Raw(load=addr_ec_msg)/
            Raw(load=len_ec_msg)/
            data_f_ip
            )
    wrpcap("gen_ecpri.pcap",ipv4)

def write_resp (mac_src, mac_dst, src_ip_v4, dst_ip_v4, src_port, dst_port):
    # add ecpri common header
    proto_ec_msg, type_ec_msg, sz_ec_msg = common_header() 

    # add ecpri read req header
    id_ec_msg   = binascii.unhexlify("01")
    rw_rr_ec_msg    = binascii.unhexlify("11")
    ele_id_ec_msg  = binascii.unhexlify("0001")
    addr_ec_msg  = binascii.unhexlify("000000000001") # do not know the address has to be big endian format or little endian format
    len_ec_msg  = binascii.unhexlify("64")
    data_f_ip   = datafield(0) # zero payload

    ipv4.append(Ether(src = mac_src,dst = mac_dst)/
            IP(src=src_ip_v4,dst=dst_ip_v4)/
            UDP(sport=src_port,dport=dst_port)/
            Raw(load=proto_ec_msg)/
            Raw(load=type_ec_msg)/
            Raw(load=sz_ec_msg)/
            Raw(load=id_ec_msg)/
            Raw(load=rw_rr_ec_msg)/
            Raw(load=ele_id_ec_msg)/
            Raw(load=addr_ec_msg)/
            Raw(load=len_ec_msg)/
            data_f_ip
            )
    wrpcap("gen_ecpri.pcap",ipv4)

l_mac_src = '11:22:33:44:55:66'
l_mac_dst = '77:88:99:AA:BB:CC'

i = 1

l_src_ip_v4   = "192.168."+str(i/256)   +"."+str(i%256)
l_dst_ip_v4   = "192.168."+str(10+i/256)+"."+str(i%256)
l_src_port    = i%256
l_dst_port    = 256+i%256

read_req (l_mac_src, l_mac_dst, l_src_ip_v4, l_dst_ip_v4, l_src_port, l_dst_port)
read_resp (l_mac_dst, l_mac_src, l_dst_ip_v4, l_src_ip_v4, l_dst_port, l_src_port) 

write_req (l_mac_src, l_mac_dst, l_src_ip_v4, l_dst_ip_v4, l_src_port, l_dst_port)
write_resp (l_mac_dst, l_mac_src, l_dst_ip_v4, l_src_ip_v4, l_dst_port, l_src_port)
