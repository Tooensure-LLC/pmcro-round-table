# Skill layout

plugins/<plugin>/.claude-plugin/plugin.json
plugins/<plugin>/skills/<name>/SKILL.md      required, frontmatter name + description
plugins/<plugin>/skills/<name>/references/   long detail, loaded only when needed
plugins/<plugin>/skills/<name>/scripts/      manual-first, each runnable by hand
plugins/<plugin>/skills/<name>/assets/       templates and static files, tokens as {{Token}}

Progressive disclosure: the router reads only name and description; the body stays short; heavy steps live in references and scripts.
