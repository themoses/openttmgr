#!/usr/bin/env python3

from bs4 import BeautifulSoup
import click
import questionary
from rich.console import Console
from rich.logging import RichHandler
from rich.progress import Progress
from furl import furl
from typing import List
from pathlib import Path
import subprocess
import logging
import requests
import re
import tempfile
import os

# Global stuff like logger and console
FORMAT = "%(message)s"
logging.basicConfig(
    level="DEBUG", format=FORMAT, datefmt="[%X]", handlers=[RichHandler()]
)
logger = logging.getLogger("rich")
console = Console()


class Gme:
    uri: furl
    title: str
    size: int

    def __init__(self, uri: furl, title: str, size: int):
        self.uri = uri
        self.title = title
        self.size = size
        self.image: furl = None

    def __str__(self):
        if self.uri is None:
            self.uri = ""

        if self.image is None:
            self.image = ""

        return f"""
        title: {self.title}
        uri: {self.uri}
        image: {self.image}
        size: {round(self.size / 1000 / 1000, 2)} MB
        """

    def download_file(self):
        pass


class Tiptoi:
    """Basic class to manage tiptoi state and files on it.

    The tiptoi itself has multiple GME files on its file system.
    """

    states = ("DISCONNECTED", "CONNECTED", "MOUNTED")
    state_message = (
        ":cross_mark: Tiptoi is [bold red]",
        ":warning: Tiptoi is [bold yellow]",
        ":thumbs_up: Tiptoi is [bold green]",
    )
    local_files: List[Gme] = list()
    # default in Ubuntu 24.04
    mount_dir = f"/media/{os.environ.get('USER')}/tiptoi"

    def __init__(self):
        self.update_state()

    def update_state(self):
        usb_devices_connected = subprocess.check_output("lsusb")

        with open("/proc/mounts", "r") as f:
            active_mounts = f.read()

        mount_match = re.compile("tiptoi").search(active_mounts)
        if mount_match:
            self.state = self.states[2]
            self.state_message = self.state_message[2]
        elif re.compile("Mentor Graphics").search(str(usb_devices_connected)):
            self.state = self.states[1]
            self.state_message = self.state_message[1]
        else:
            self.state = self.states[0]
            self.state_message = self.state_message[0]

    def get_local_gme_files(self) -> None:
        for file_name in os.listdir(self.mount_dir):
            if "gme" in file_name:
                x = Gme(
                    title=file_name,
                    size=os.path.getsize(f"{self.mount_dir}/{file_name}"),
                    uri=None,
                )
                self.local_files.append(x)


class TiptoiManager:
    """Manager class which handles tiptoi and GME downloads"""

    def __init__(self):
        self.tt = Tiptoi()

    api_url: furl = furl(
        "https://service.ravensburger.de/@api/deki/site/query?dream.out.format=json&sortBy=-rank&parser=bestguess"
    )

    def lookup_gme_metadata(self, gme: Gme):
        """
        Looks up metadata like author, description and product image uri in order to contain all information about a GME file in one object
        """

        gme_soup = BeautifulSoup(requests.get(gme.uri.url).text, "html.parser")
        logger.debug(gme_soup.find("a", {"class": "link-https"}))
        gme.image = furl(gme_soup.find("img", {"class": "internal"}).get("src"))
        logger.debug(gme.image)
        gme.uri = furl(gme_soup.find("a", {"class": "link-https"}).get("href"))
        logger.debug(gme.uri)

    def find_gme_files(self, search_term: str) -> List[Gme]:
        result_list: List[Gme] = []

        query_url = self.api_url.add({"q": search_term}).url
        logger.debug(query_url)
        gme_api_query = requests.get(query_url)
        query_result = gme_api_query.json()["result"]
        logger.debug(query_result)

        for res in query_result:
            if "content" in res:
                if "Audiodatei" in res["content"]:
                    logger.debug(res["content"])
                    result_list.append(Gme(furl(res["uri"]), res["title"], size=0))

        for gme in result_list:
            self.lookup_gme_metadata(gme)
            logger.debug(gme)
        return result_list
    
    def download_gme_file(self, to_download: Gme) -> Path:
        # Get size of the file to download
        request_size = requests.head(to_download.uri.url)
        to_download.size = int(request_size.headers['content-length'])
        logger.debug("Download size: %s", to_download.size)
        
        target_dir = Path(f"/home/{ os.environ.get('USER') }/.cache/tiptoi")
        Path.mkdir(target_dir, exist_ok=True)
        filename = Path(to_download.uri.url.split("/")[-1])
        complete_path = Path(f"{target_dir}/{filename}")

        logger.debug("Downloading to %s", complete_path)

        if not complete_path.exists():
            with Progress() as progress:
                task = progress.add_task("Downloading", total=to_download.size)
                while not progress.finished:
                    with requests.get(to_download.uri.url, stream=True) as download:
                        download.raise_for_status()
                        with open(complete_path, 'wb') as file:
                            for chunk in download.iter_content(chunk_size=4096):
                                file.write(chunk)
                                progress.update(task, advance=4096)
        
        return complete_path


@click.group()
def cli() -> None:
    pass


@click.command("status")
def status() -> None:
    click.echo("Showing status")
    ttmgr = TiptoiManager()
    click.echo(console.print(f"{ttmgr.tt.state_message}{ttmgr.tt.state}"))


@click.command
@click.argument("title", type=str)
def find(title) -> None:
    ttmgr = TiptoiManager()
    click.echo(f"Looking for {title} ")
    result = ttmgr.find_gme_files(title)

    selection_title = questionary.rawselect(
    "Select file to download:",
    choices=[x.title for x in result],
).ask()
    selection = [x for x in result if x.title == selection_title]
    logger.debug(selection)

    ttmgr.download_gme_file(selection[0])


@click.command("list")
def show() -> List[Gme]:
    ttmgr = TiptoiManager()
    if ttmgr.tt.state == "MOUNTED":
        click.echo("Listing all files on connected Tiptoi")
        ttmgr.tt.get_local_gme_files()
        for gme_file in ttmgr.tt.local_files:
            click.echo(gme_file)


cli.add_command(status)
cli.add_command(find)
cli.add_command(show)

if __name__ == "__main__":
    cli()
