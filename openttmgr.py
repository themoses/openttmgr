#!/usr/bin/env python3

import click
from furl import furl
from typing import List
import logging
import requests


class Gme:
    url: furl

class Tiptoi:
    """Basic class to manage TipToi state and files on it"""

    states = ("DISCONNECTED", "CONNECTED", "MOUNTED")
    local_files = List[Gme]

    def __init__(self):
        self.state = states[0]




@click.command()
@click.option("-t", "--title", type=str, help="The person to greet.")
def parse(title):
    if title:
        print(f"searching for { title }")

if __name__ == "__main__":
    parse()