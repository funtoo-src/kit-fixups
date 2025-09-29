#!/usr/bin/env python3

from bs4 import BeautifulSoup
from packaging.version import Version
import json
import re
import os


MINIMUM_STABLE_NODEJS = 12

def portage_arch(arch):
	arches = { # map upstream arch string to portage arch string
		'x86_64': 'amd64',
		'aarch64': 'arm64'
	}
	return arches.get(arch) or 'amd64'


async def generate_artifacts(hub, pkginfo, urls):
	return [(
			portage_arch(url.split('-')[-1].split('.')[0]), # portage arch string
			hub.pkgtools.ebuild.Artifact(url=url)
		) for url in urls if 'sha' not in url # filter out the sha
	]


async def get_minimum_node_version(artifact):
	# extract the contents of package.json in the src tarball
	await artifact.fetch()
	artifact.extract()
	try:
		# Be robust across Kibana versions by locating package.json via glob.
		# Expected structure: <extract_path>/<dir>/package.json
		import glob
		candidates = glob.glob(os.path.join(artifact.extract_path, "*", "package.json"))
		if not candidates:
			raise FileNotFoundError("package.json not found in extracted Kibana artifact")
		package = candidates[0]
		with open(package) as f:
			package_info = json.load(f)
	finally:
		artifact.cleanup()
	version = Version(package_info["engines"]["node"])
	return { 'minimum': version.public, 'series': max(version.major, MINIMUM_STABLE_NODEJS) }


async def generate(hub, **pkginfo):
	download_url = "https://www.elastic.co/downloads/past-releases"
	github_user = pkginfo["github_user"]
	github_repo = pkginfo["name"].strip("-bin")

	# Get a list of release versions from the github repo
	releases = await hub.pkgtools.fetch.get_page(
		f"https://api.github.com/repos/{github_user}/{github_repo}/releases",
		is_json=True
	)

	versions = [Version(a["tag_name"].lstrip("v")) for a in releases]
	stable_versions = [v for v in versions if not v.is_prerelease]
	latest = max(stable_versions) if stable_versions else None

	# Create an ebuild for the most recent 2 major versions
	for major in [latest.major, latest.major - 1]:
		version = max([v for v in versions if v.major == major])
		# find available architecture tarballs on the elastic site
		download_page = f"{download_url}/{github_repo}-{version.public.replace('.', '-')}"
		html = await hub.pkgtools.fetch.get_page(download_page)
		tarballs = []

		# The most reliable way to extract version information from these pages is to look for a special <script> tag
		# which contains Javascript (JSON). We can parse this, and extract the necessary information.

		soup = BeautifulSoup(html, "lxml")
		tarballs = []
		script_tag = soup.find('script', id="__NEXT_DATA__")

		# First, try the JSON payload approach if available:
		if script_tag is not None and script_tag.text:
			try:
				json_data = json.loads(str(script_tag.text))
				if "entry" in json_data.get("props", {}).get("pageProps", {}):
					package_data = json_data["props"]["pageProps"]["entry"][0][0]["package"]
					for package in package_data:
						# Keep only Linux tarballs
						if not package["title"].startswith("Linux"):
							continue
						if not package["url"].endswith(".tar.gz"):
							continue
						tarballs.append(package["url"])
			except (json.JSONDecodeError, KeyError, TypeError):
				# Fall back to link scraping if JSON format has changed
				pass

		# Fallback: scrape links to .tar.gz directly from the page when JSON is missing or unusable.
		# Restrict to Linux archives only.
		if not tarballs:
			for a in soup.find_all('a', href=True):
				href = a['href']
				if not href.endswith(".tar.gz"):
					continue
				# Normalize to absolute URL
				if href.startswith("/"):
					full = f"https://www.elastic.co{href}"
				elif href.startswith("http://") or href.startswith("https://"):
					full = href
				else:
					continue
				# Filter to Linux tarballs only
				# Accept patterns containing "-linux-" in the filename or URL path.
				if "-linux-" not in full:
					continue
				tarballs.append(full)

		if not tarballs:
			raise hub.pkgtools.ebuild.BreezyError(
				f"No tarballs found for {pkginfo['name']} when looking at {download_page}. "
				f"Checked both __NEXT_DATA__ JSON and direct link scraping."
			)

		artifacts = await generate_artifacts(hub, pkginfo, tarballs)

		# find the compatible node version for kibana-bin
		if 'nodejs' in pkginfo:
			# Prefer a Linux amd64 artifact for determining Node.js version; fall back to any available.
			linux_preferred = None
			for arch, art in artifacts:
				if arch in ('amd64', 'arm64'):
					linux_preferred = art
					break
			if linux_preferred is None:
				linux_preferred = artifacts[0][1]
			pkginfo['nodejs'] = await get_minimum_node_version(linux_preferred)

		ebuild = hub.pkgtools.ebuild.BreezyBuild(
			**pkginfo,
			github_repo=github_repo,
			version=version.public.replace('-', '_'),
			major=major,
			artifacts=dict(artifacts),
		)
		ebuild.push()

# vim: ts=4 sw=4 noet
