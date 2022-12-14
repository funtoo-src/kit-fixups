#!/usr/bin/env python3

from bs4 import BeautifulSoup
from packaging import version
import re


async def generate(hub, **pkginfo):
    project_name="graphicsmagick"
    project_name = pkginfo.get("name")

    sourceforge_url = f"https://sourceforge.net/projects/{project_name}/files/{project_name}"
    sourceforge_soup = BeautifulSoup(
            await hub.pkgtools.fetch.get_page(sourceforge_url), "lxml"
            )

    files_list = sourceforge_soup.find(id="files_list")
    files = (
            version_row.get("title") for version_row in files_list.tbody.find_all("tr")
            )
    versions = { version.parse(re.search(r"\d+\.\d+(\.\d+)?", file).group()): file for file in files }


    target_version = max(versions.keys())
    target_file = f"GraphicsMagick-{target_version}.tar.xz"

    src_url = f"https://sourceforge.net/projects/{project_name}/files/{project_name}/{target_version}/{target_file}"


    ebuild = hub.pkgtools.ebuild.BreezyBuild(
            **pkginfo,
            version=target_version,
            artifacts=[hub.pkgtools.ebuild.Artifact(url=src_url)],
            )
    ebuild.push()
