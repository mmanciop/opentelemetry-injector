# Releasing the injector

An approver or maintainer can run the GitHub action to [prepare the release from the GitHub Actions page of the repository](https://github.com/open-telemetry/opentelemetry-injector/actions/workflows/prepare-release.yml).

The pattern for the version should be vX.Y.Z for a regular release, or vX.Y.Z-<additional-qualfier> for a release candidate.

The action will trigger the creation of a pull request for review by project approvers ([example](https://github.com/open-telemetry/opentelemetry-injector/pull/112)).

Approvers approve the changelog and merge the PR.

Merging the PR will trigger the workflow `.github/workflows/create-tag-for-release.yml` which will create a tag with the
version number.

Creating the tag will trigger the `build` GitHub action workflow, which will then create the GitHub release in the last
job (`publish-stable`).
(This can take a couple of minutes.)

## Package repositories

When the GitHub release is published, the [`.github/workflows/publish-repos.yml`](.github/workflows/publish-repos.yml) workflow automatically:

1. Downloads the `.deb` and `.rpm` packages from the release
2. Generates APT and YUM repository metadata
3. Deploys everything to GitHub Pages

The package repositories are available at:

- **Landing page**: https://open-telemetry.github.io/opentelemetry-injector/
- **APT repository**: https://open-telemetry.github.io/opentelemetry-injector/debian
- **YUM repository**: https://open-telemetry.github.io/opentelemetry-injector/rpm

Users can install packages with:

```bash
# Debian/Ubuntu
echo "deb [trusted=yes] https://open-telemetry.github.io/opentelemetry-injector/debian stable main" | sudo tee /etc/apt/sources.list.d/opentelemetry.list
sudo apt update && sudo apt install opentelemetry

# RHEL/Fedora/Amazon Linux
sudo curl -o /etc/yum.repos.d/opentelemetry.repo https://open-telemetry.github.io/opentelemetry-injector/rpm/opentelemetry-injector.repo
sudo dnf install opentelemetry
```

The workflow can also be [triggered manually](https://github.com/open-telemetry/opentelemetry-injector/actions/workflows/publish-repos.yml) to republish repositories for a specific release tag.

## Announce the release

Make sure to drop the good news of the release to the CNCF slack #otel-injector channel!

