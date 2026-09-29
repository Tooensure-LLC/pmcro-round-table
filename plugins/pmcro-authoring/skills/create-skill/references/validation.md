# Validation

validate-skill.ps1 fails when:
- SKILL.md is missing or has no frontmatter block
- name is not kebab-case, or does not match the folder name
- description is missing, empty, longer than 1024 characters, or lacks both "USE FOR" and "DO NOT USE"
- a references/, scripts/ or assets/ path named in the body does not exist

Prove the validator by running it on a deliberately bad sample first (must-fail), then on real skills.
