#!/usr/bin/env python
#
#Izoox.com
#David Scalf 
#Izoox Ansible nmap inventory script
#Based on ansible ssh_config discovrery script
#

#standard imports
import argparse
import os.path
import sys

#input imports
import nmap
from libnmap.process import NmapProcess
from libnmap.parser import NmapParser

#output imports
import json
from ansible.module_utils.common._collections_compat import MutableSequence
#import paramiko


nm = nmap.PortScanner()
nm.nmap.PortScanner()
nm.scan()



def get_config():
    if not os.path.isfile(os.path.expanduser(SSH_CONF)):
        return {}
    with open(os.path.expanduser(SSH_CONF)) as f:
        cfg = paramiko.SSHConfig()
        cfg.parse(f)
        ret_dict = {}
        for d in cfg._config:
            if isinstance(d['host'], MutableSequence):
                alias = d['host'][0]
            else:
                alias = d['host']
            if ('?' in alias) or ('*' in alias):
                continue
            _copy = dict(d)
            del _copy['host']
            if 'config' in _copy:
                ret_dict[alias] = _copy['config']
            else:
                ret_dict[alias] = _copy
        return ret_dict


def print_list():
    cfg = get_config()
    meta = {'hostvars': {}}
    for alias, attributes in cfg.items():
        tmp_dict = {}
        for ssh_opt, ans_opt in _ssh_to_ansible:
            if ssh_opt in attributes:
                # If the attribute is a list, just take the first element.
                # Private key is returned in a list for some reason.
                attr = attributes[ssh_opt]
                if isinstance(attr, MutableSequence):
                    attr = attr[0]
                tmp_dict[ans_opt] = attr
        if tmp_dict:
            meta['hostvars'][alias] = tmp_dict

    print(json.dumps({_key: list(set(meta['hostvars'].keys())), '_meta': meta}))


def print_host(host):
    cfg = get_config()
    print(json.dumps(cfg[host]))


def get_args(args_list):
    parser = argparse.ArgumentParser(
        description='ansible inventory script parsing .ssh/config')
    mutex_group = parser.add_mutually_exclusive_group(required=True)
    help_list = 'list all hosts from .ssh/config inventory'
    mutex_group.add_argument('--list', action='store_true', help=help_list)
    help_host = 'display variables for a host'
    mutex_group.add_argument('--host', help=help_host)
    return parser.parse_args(args_list)


def main(args_list):

    args = get_args(args_list)
    if args.list:
        print_list()
    if args.host:
        print_host(args.host)


if __name__ == '__main__':
    main(sys.argv[1:])