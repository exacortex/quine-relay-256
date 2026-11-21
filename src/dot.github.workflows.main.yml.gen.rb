require "yaml"
require_relative "code-gen"

srcs = RunSteps.flat_map {|s| s.src }

cp_cmds = srcs.map do |s|
  "          sudo docker cp qr:/usr/local/share/quine-relay/#{ s } spoiler/"
end.join("\n")

File.binwrite(File.join(__dir__, "../.github/workflows/main.yml"), <<END)
name: CI
# A full 256-step from-scratch build + verification lap produces a ~35 GB Docker
# image (~45+ GB free disk required) and runs for ~1.5-2 hours, which exceeds
# standard GitHub-hosted ubuntu-latest runner disk quotas. Run manually on a
# self-hosted Linux x86_64 runner (Actions tab > CI > Run workflow).
on:
  workflow_dispatch:
jobs:
  build:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: docker build
        run: |
          sudo docker build --pull --no-cache -t quine-relay .
      - name: docker run
        run: |
          sudo docker run --name qr -e CI=true -t quine-relay
      - name: push spoiler
        run: |
          git clone https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git spoiler --branch spoiler || \\
            (git clone https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git spoiler && git -C spoiler checkout --orphan spoiler)
          git -C spoiler rm --quiet -r --ignore-unmatch '*'
#{ cp_cmds }
          cd spoiler
          git add .
          GIT_AUTHOR_NAME="$(git show -s --format=%an "$GITHUB_SHA")" \\
          GIT_AUTHOR_EMAIL="$(git show -s --format=%ae "$GITHUB_SHA")" \\
          GIT_AUTHOR_DATE="$(git show -s --format=%ad "$GITHUB_SHA")" \\
          GIT_COMMITTER_NAME='GitHub Actions' \\
          GIT_COMMITTER_EMAIL='actions@github.com' \\
          TZ=UTC \\
          git commit --allow-empty -m "spoiler: $(git show -s --format=%s "$GITHUB_SHA")"
          git push --quiet origin spoiler
          echo The intermediate sources are available: https://github.com/${GITHUB_REPOSITORY}/tree/spoiler
        if: github.ref == 'refs/heads/main'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
END
